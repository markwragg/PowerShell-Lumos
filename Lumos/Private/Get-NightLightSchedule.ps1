Function Get-NightLightSchedule {
    <#
        .SYNOPSIS
            Returns today's Sunrise/Sunset as configured in Windows' own Night Light schedule.

        .DESCRIPTION
            Reads the schedule Windows Night Light is currently configured with (Settings > System > Display >
            Night light) directly from the registry, so Register-LumosScheduledTask can reuse it instead of
            looking up sunrise/sunset for your location independently.

            Night Light stores its settings as a Microsoft Bond CompactBinary v1 document, nested inside an
            outer "CloudStore" envelope of the same format, under:
            HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\
            default$windows.data.bluelightreduction.settings\windows.data.bluelightreduction.settings ("Data").
            This isn't a documented or supported format - it's reverse-engineered (field IDs/purposes below are
            cross-referenced against https://github.com/kvnxiao/win-nightlight-cli's docs and verified against
            real registry data) and could change in a future Windows release. Rather than parse the outer
            envelope's own (undocumented) schema, the inner document is located by its own magic header
            (0x43 0x42 0x01 0x00, "CB" + version 1), which empirically always reappears a little way into it.

            The inner document's fields that matter here:
              0  (bool)      schedule_enabled  - a schedule is active
              10 (bool)      set_hours_mode    - PRESENT (any value) when using a fixed "Set hours" schedule
              20 (TimeBlock) schedule_start_time - fixed schedule's dark/Night-Light-on time
              30 (TimeBlock) schedule_end_time   - fixed schedule's light/Night-Light-off time
              50 (TimeBlock) sunset_time  - "Sunset to sunrise" mode's computed dark/Night-Light-on time
              60 (TimeBlock) sunrise_time - "Sunset to sunrise" mode's computed light/Night-Light-off time
            A TimeBlock is itself a struct of two optional int8 fields (0 = hour, 1 = minute); Bond omits
            fields left at their default value, so an empty TimeBlock means midnight - indistinguishable from
            that field being genuinely unset. Field 10's presence (not its actual bool value) is what indicates
            "Set hours" mode is selected; without it, fields 50/60 are used instead, if a schedule is enabled.

        .EXAMPLE
            Get-NightLightSchedule

            Result
            -----------
            Sunrise : 06/08/2019 07:00:00
            Sunset  : 06/08/2019 21:00:00
    #>
    [CmdletBinding()]
    Param()

    $RegistryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\' +
    'default$windows.data.bluelightreduction.settings\windows.data.bluelightreduction.settings'

    $Bytes = (Get-ItemProperty -Path $RegistryPath -Name 'Data' -ErrorAction SilentlyContinue).Data

    if (-not $Bytes) {
        throw 'Could not read the Windows Night Light schedule from the registry. Make sure Night Light has ' +
        'been configured at least once under Settings > System > Display > Night light.'
    }

    $InnerStart = -1

    for ($i = 4; $i -le $Bytes.Length - 4; $i++) {
        if ($Bytes[$i] -eq 0x43 -and $Bytes[$i + 1] -eq 0x42 -and $Bytes[$i + 2] -eq 0x01 -and $Bytes[$i + 3] -eq 0x00) {
            $InnerStart = $i + 4
            break
        }
    }

    if ($InnerStart -lt 0) {
        throw 'Could not parse the Windows Night Light schedule - the registry data was not in the expected format.'
    }

    $Position = $InnerStart
    $ScheduleEnabled = $false
    $SetHoursMode = $false
    $Times = @{}

    while ($Position -lt $Bytes.Length) {
        $Header = $Bytes[$Position]
        $Position++

        # Low 5 bits are the Bond wire type; high 3 bits are either the field ID directly (0-5), or a
        # sentinel saying the ID follows as its own byte (6) or 16-bit value (7).
        $Type = $Header -band 0x1F
        $IdBits = ($Header -shr 5) -band 0x07

        if ($Type -eq 0) { break } # BT_STOP: end of this struct
        if ($Type -eq 1) { continue } # BT_STOP_BASE: end of base class fields, more fields follow

        # Cast to [int] in every branch - $Times.ContainsKey(20) below relies on the key's boxed type matching
        # an int literal, which a bare [byte] (from $IdBits or $Bytes[$Position]) would silently fail to match.
        $FieldId = if ($IdBits -le 5) {
            [int]$IdBits
        }
        elseif ($IdBits -eq 6) {
            $Id = [int]$Bytes[$Position]; $Position++; $Id
        }
        else {
            $Id = [int][BitConverter]::ToUInt16($Bytes, $Position); $Position += 2; $Id
        }

        switch ($Type) {
            2 {
                # BT_BOOL
                $Value = $Bytes[$Position] -ne 0
                $Position++

                if ($FieldId -eq 0) { $ScheduleEnabled = $Value }
                elseif ($FieldId -eq 10) { $SetHoursMode = $true }
            }
            { $_ -in 3, 14 } {
                # BT_UINT8 / BT_INT8 - 1 byte
                $Position++
            }
            { $_ -in 4, 5, 6, 15, 16, 17 } {
                # BT_UINT16/32/64, BT_INT16/32/64 - varint, e.g. the color_temperature field
                do { $VarIntByte = $Bytes[$Position]; $Position++ } while ($VarIntByte -band 0x80)
            }
            10 {
                # BT_STRUCT
                if ($FieldId -in 20, 30, 50, 60) {
                    # A TimeBlock: hour (field 0) and minute (field 1), each an optional BT_INT8.
                    $Hour = 0
                    $Minute = 0

                    while ($true) {
                        $SubHeader = $Bytes[$Position]; $Position++
                        $SubType = $SubHeader -band 0x1F
                        $SubIdBits = ($SubHeader -shr 5) -band 0x07

                        if ($SubType -eq 0) { break }
                        if ($SubType -eq 1) { continue }
                        if ($SubType -ne 14) {
                            throw "Could not parse the Windows Night Light schedule - unexpected field type ($SubType) in a TimeBlock."
                        }

                        $SubId = if ($SubIdBits -le 5) { $SubIdBits } else { $Id = $Bytes[$Position]; $Position++; $Id }
                        $Value = $Bytes[$Position]; $Position++

                        if ($SubId -eq 0) { $Hour = $Value }
                        elseif ($SubId -eq 1) { $Minute = $Value }
                    }

                    $Times[$FieldId] = [pscustomobject]@{ Hour = $Hour; Minute = $Minute }
                }
                else {
                    # An unrecognized struct field - skip it, as long as it's flat (no further nested structs).
                    while ($true) {
                        $SubHeader = $Bytes[$Position]; $Position++
                        $SubType = $SubHeader -band 0x1F

                        if ($SubType -eq 0) { break }
                        if ($SubType -eq 1) { continue }
                        throw "Could not parse the Windows Night Light schedule - encountered an unsupported nested field ($SubType)."
                    }
                }
            }
            default {
                throw "Could not parse the Windows Night Light schedule - encountered an unsupported field type ($Type)."
            }
        }
    }

    if ($SetHoursMode -and $Times.ContainsKey(20) -and $Times.ContainsKey(30)) {
        $SunsetTime = $Times[20]
        $SunriseTime = $Times[30]
    }
    elseif ($ScheduleEnabled -and $Times.ContainsKey(50) -and $Times.ContainsKey(60) -and
        -not ($Times[50].Hour -eq 0 -and $Times[50].Minute -eq 0 -and $Times[60].Hour -eq 0 -and $Times[60].Minute -eq 0)) {
        $SunsetTime = $Times[50]
        $SunriseTime = $Times[60]
    }
    else {
        throw 'Windows Night Light does not currently have a schedule configured. Enable a schedule under ' +
        'Settings > System > Display > Night light, or use -Sunrise/-Sunset instead.'
    }

    $Today = Get-Date

    [pscustomobject]@{
        Sunrise = Get-Date -Year $Today.Year -Month $Today.Month -Day $Today.Day -Hour $SunriseTime.Hour -Minute $SunriseTime.Minute -Second 0
        Sunset  = Get-Date -Year $Today.Year -Month $Today.Month -Day $Today.Day -Hour $SunsetTime.Hour -Minute $SunsetTime.Minute -Second 0
    }
}

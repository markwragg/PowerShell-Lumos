if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

Describe "Get-NightLightSchedule PS$PSVersion" {

    InModuleScope Lumos {

        BeforeAll {
            # Builds a minimal, spec-accurate Bond CompactBinary v1 "TimeBlock" struct: an optional int8 hour
            # (field 0) and minute (field 1), each omitted when 0 (matching Bond's default-value omission),
            # terminated by BT_STOP. Defined in BeforeAll (rather than loose in this InModuleScope block) so
            # it's actually available during the Run phase, not just Pester's separate Discovery pass.
            Function New-TimeBlockFieldBytes {
                Param([int]$Id, [int]$Hour, [int]$Minute)

                $Bytes = [System.Collections.Generic.List[byte]]::new()
                $Bytes.Add([byte](((6 -shl 5) -bor 10))) # BT_STRUCT, field id follows as its own byte
                $Bytes.Add([byte]$Id)

                if ($Hour -ne 0) {
                    $Bytes.Add([byte]((0 -shl 5) -bor 14)) # BT_INT8, field id 0 (direct)
                    $Bytes.Add([byte]$Hour)
                }
                if ($Minute -ne 0) {
                    $Bytes.Add([byte]((1 -shl 5) -bor 14)) # BT_INT8, field id 1 (direct)
                    $Bytes.Add([byte]$Minute)
                }

                $Bytes.Add(0x00) # BT_STOP
                return , $Bytes.ToArray()
            }

            Function New-BoolFieldBytes {
                Param([int]$Id, [bool]$Value)

                $Bytes = [System.Collections.Generic.List[byte]]::new()

                if ($Id -le 5) {
                    $Bytes.Add([byte](($Id -shl 5) -bor 2))
                }
                else {
                    $Bytes.Add([byte](( 6 -shl 5) -bor 2))
                    $Bytes.Add([byte]$Id)
                }

                $Bytes.Add([byte]$(if ($Value) { 1 } else { 0 }))
                return , $Bytes.ToArray()
            }

            # Wraps the given inner-payload field bytes in a minimal envelope: an (unparsed, ignored) outer
            # "CB" v1 magic header, immediately followed by the inner document's own "CB" v1 magic header
            # and fields.
            Function New-NightLightRegistryBytes {
                Param([byte[][]]$Field)

                $Bytes = [System.Collections.Generic.List[byte]]::new()
                $Bytes.AddRange([byte[]](0x43, 0x42, 0x01, 0x00))
                $Bytes.AddRange([byte[]](0x43, 0x42, 0x01, 0x00))

                foreach ($F in $Field) {
                    $Bytes.AddRange($F)
                }

                $Bytes.Add(0x00) # BT_STOP for the inner document
                return , $Bytes.ToArray()
            }
        }

        Context 'Get-NightLightSchedule ignoring interleaved unknown/base-class/varint fields' {

            BeforeEach {
                # Exercises the parser's "skip anything I don't recognise" paths that the other contexts
                # never touch: a BT_STOP_BASE marker (more base-class fields follow), a plain fixed-width
                # field, a multi-byte varint field, and a field whose id is big enough to need the 16-bit
                # id encoding - interleaved with a normal schedule, to confirm they're all skipped cleanly
                # rather than corrupting the fields that matter.
                $Script:TestData = New-NightLightRegistryBytes -Field @(
                    [byte[]](0x01), # BT_STOP_BASE - no field data follows
                    [byte[]](((2 -shl 5) -bor 3), 0x07), # unknown BT_UINT8 field, direct id 2
                    [byte[]](((3 -shl 5) -bor 4), 0x85, 0x02), # unknown varint field, direct id 3, 2-byte varint
                    [byte[]](@(((7 -shl 5) -bor 3)) + [BitConverter]::GetBytes([uint16]1000) + @(0x05)), # unknown BT_UINT8 field, 16-bit id
                    (New-BoolFieldBytes -Id 10 -Value $false),
                    (New-TimeBlockFieldBytes -Id 20 -Hour 21 -Minute 0),
                    (New-TimeBlockFieldBytes -Id 30 -Hour 7 -Minute 0)
                )

                Mock Get-ItemProperty { [pscustomobject]@{ Data = $Script:TestData } }

                $GetNightLightSchedule = Get-NightLightSchedule
            }

            It 'Should skip the unknown fields and still return the correct schedule' {
                $GetNightLightSchedule.Sunset.Hour | Should -Be 21
                $GetNightLightSchedule.Sunset.Minute | Should -Be 0
                $GetNightLightSchedule.Sunrise.Hour | Should -Be 7
                $GetNightLightSchedule.Sunrise.Minute | Should -Be 0
            }
        }

        Context 'Get-NightLightSchedule with a TimeBlock containing a base-class stop marker and an oversized subfield id' {

            BeforeEach {
                # Hand-built rather than via New-TimeBlockFieldBytes, to insert a BT_STOP_BASE marker and an
                # unrecognised subfield (id 6, requiring the "id follows as its own byte" encoding since it's
                # above 5) ahead of the real Hour/Minute subfields.
                $CustomSunsetTimeBlock = [byte[]](
                    ((6 -shl 5) -bor 10), 20, # BT_STRUCT header, field id 20 (sunset_time) as a following byte
                    ((0 -shl 5) -bor 1), # BT_STOP_BASE - more subfields follow
                    ((6 -shl 5) -bor 14), 6, 42, # unrecognised subfield, id 6 as a following byte - ignored
                    ((0 -shl 5) -bor 14), 21, # Hour = 21 (direct sub-id 0)
                    ((1 -shl 5) -bor 14), 30, # Minute = 30 (direct sub-id 1)
                    0x00 # BT_STOP
                )

                $Script:TestData = New-NightLightRegistryBytes -Field @(
                    (New-BoolFieldBytes -Id 10 -Value $false),
                    $CustomSunsetTimeBlock,
                    (New-TimeBlockFieldBytes -Id 30 -Hour 7 -Minute 0)
                )

                Mock Get-ItemProperty { [pscustomobject]@{ Data = $Script:TestData } }

                $GetNightLightSchedule = Get-NightLightSchedule
            }

            It 'Should ignore the base-class marker and unrecognised subfield, and still parse Hour/Minute correctly' {
                $GetNightLightSchedule.Sunset.Hour | Should -Be 21
                $GetNightLightSchedule.Sunset.Minute | Should -Be 30
            }
        }

        Context 'Get-NightLightSchedule when a TimeBlock contains an unsupported field type' {

            BeforeEach {
                $BadTimeBlock = [byte[]](
                    ((6 -shl 5) -bor 10), 20, # BT_STRUCT header, field id 20 (sunset_time)
                    ((0 -shl 5) -bor 2), 1, # invalid subfield type (2 = BT_BOOL) inside a TimeBlock
                    0x00
                )

                $Script:TestData = New-NightLightRegistryBytes -Field @($BadTimeBlock)

                Mock Get-ItemProperty { [pscustomobject]@{ Data = $Script:TestData } }
            }

            It 'Should throw' {
                { Get-NightLightSchedule } | Should -Throw '*unexpected field type (2) in a TimeBlock*'
            }
        }

        Context 'Get-NightLightSchedule ignoring an unrecognized flat struct field' {

            BeforeEach {
                $UnknownStruct = [byte[]](
                    ((5 -shl 5) -bor 10), # BT_STRUCT header, direct field id 5 (not a known TimeBlock field)
                    ((0 -shl 5) -bor 1), # BT_STOP_BASE within the unrecognized struct - more fields follow
                    0x00 # BT_STOP - end of the unrecognized struct
                )

                $Script:TestData = New-NightLightRegistryBytes -Field @(
                    $UnknownStruct,
                    (New-BoolFieldBytes -Id 10 -Value $false),
                    (New-TimeBlockFieldBytes -Id 20 -Hour 21 -Minute 0),
                    (New-TimeBlockFieldBytes -Id 30 -Hour 7 -Minute 0)
                )

                Mock Get-ItemProperty { [pscustomobject]@{ Data = $Script:TestData } }

                $GetNightLightSchedule = Get-NightLightSchedule
            }

            It 'Should skip the unrecognized struct field and still return the correct schedule' {
                $GetNightLightSchedule.Sunset.Hour | Should -Be 21
                $GetNightLightSchedule.Sunrise.Hour | Should -Be 7
            }
        }

        Context 'Get-NightLightSchedule when an unrecognized struct field contains an unsupported nested field type' {

            BeforeEach {
                $BadStruct = [byte[]](
                    ((5 -shl 5) -bor 10), # BT_STRUCT header, direct field id 5 (not a known TimeBlock field)
                    ((0 -shl 5) -bor 2) # unsupported nested field type (2 = BT_BOOL) - not flat
                )

                $Script:TestData = New-NightLightRegistryBytes -Field @($BadStruct)

                Mock Get-ItemProperty { [pscustomobject]@{ Data = $Script:TestData } }
            }

            It 'Should throw' {
                { Get-NightLightSchedule } | Should -Throw '*unsupported nested field (2)*'
            }
        }

        Context 'Get-NightLightSchedule when the registry data contains an unsupported field type' {

            BeforeEach {
                $Script:TestData = New-NightLightRegistryBytes -Field @(
                    [byte[]](((0 -shl 5) -bor 9)) # unsupported wire type (9) - not handled by any case
                )

                Mock Get-ItemProperty { [pscustomobject]@{ Data = $Script:TestData } }
            }

            It 'Should throw' {
                { Get-NightLightSchedule } | Should -Throw '*unsupported field type (9)*'
            }
        }

        Context 'Get-NightLightSchedule with a "Set Hours" manual schedule' {

            BeforeEach {
                # Built here, rather than inline in the Mock body below - Mock scriptblocks run inside the
                # mocked module's own session state, which can't see functions from InModuleScope's caller.
                $Script:TestData = New-NightLightRegistryBytes -Field @(
                    (New-BoolFieldBytes -Id 10 -Value $false),
                    (New-TimeBlockFieldBytes -Id 20 -Hour 21 -Minute 0),
                    (New-TimeBlockFieldBytes -Id 30 -Hour 7 -Minute 0)
                )

                Mock Get-ItemProperty { [pscustomobject]@{ Data = $Script:TestData } }

                $GetNightLightSchedule = Get-NightLightSchedule
            }

            It 'Should return the schedule start time as Sunset' {
                $GetNightLightSchedule.Sunset.Hour | Should -Be 21
                $GetNightLightSchedule.Sunset.Minute | Should -Be 0
            }

            It 'Should return the schedule end time as Sunrise' {
                $GetNightLightSchedule.Sunrise.Hour | Should -Be 7
                $GetNightLightSchedule.Sunrise.Minute | Should -Be 0
            }
        }

        Context 'Get-NightLightSchedule with a "Sunset to sunrise" automatic schedule' {

            BeforeEach {
                $Script:TestData = New-NightLightRegistryBytes -Field @(
                    (New-BoolFieldBytes -Id 0 -Value $true),
                    (New-TimeBlockFieldBytes -Id 50 -Hour 20 -Minute 15),
                    (New-TimeBlockFieldBytes -Id 60 -Hour 6 -Minute 45)
                )

                Mock Get-ItemProperty { [pscustomobject]@{ Data = $Script:TestData } }

                $GetNightLightSchedule = Get-NightLightSchedule
            }

            It 'Should return the computed sunset time as Sunset' {
                $GetNightLightSchedule.Sunset.Hour | Should -Be 20
                $GetNightLightSchedule.Sunset.Minute | Should -Be 15
            }

            It 'Should return the computed sunrise time as Sunrise' {
                $GetNightLightSchedule.Sunrise.Hour | Should -Be 6
                $GetNightLightSchedule.Sunrise.Minute | Should -Be 45
            }
        }

        Context 'Get-NightLightSchedule when Night Light has no schedule configured' {

            BeforeEach {
                $Script:TestData = New-NightLightRegistryBytes -Field @(
                    (New-BoolFieldBytes -Id 0 -Value $false)
                )

                Mock Get-ItemProperty { [pscustomobject]@{ Data = $Script:TestData } }
            }

            It 'Should throw' {
                { Get-NightLightSchedule } | Should -Throw '*does not currently have a schedule configured*'
            }
        }

        Context 'Get-NightLightSchedule when no registry data is found' {

            BeforeEach {
                Mock Get-ItemProperty {}
            }

            It 'Should throw' {
                { Get-NightLightSchedule } | Should -Throw '*Could not read the Windows Night Light schedule from the registry*'
            }
        }

        Context 'Get-NightLightSchedule when the registry data is not in the expected format' {

            BeforeEach {
                Mock Get-ItemProperty {
                    [pscustomobject]@{ Data = [byte[]](1, 2, 3, 4, 5, 6, 7, 8) }
                }
            }

            It 'Should throw' {
                { Get-NightLightSchedule } | Should -Throw '*was not in the expected format*'
            }
        }
    }
}

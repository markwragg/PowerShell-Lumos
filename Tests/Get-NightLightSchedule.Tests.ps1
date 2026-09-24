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

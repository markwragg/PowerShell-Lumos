if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

# Updating a scheduled task depends on the Windows-only ScheduledTasks module, so these tests only run on Windows.
$IsWindowsPlatform = $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows

Describe "Update-LumosScheduledTask PS$PSVersion" -Skip:(-not $IsWindowsPlatform) {

    InModuleScope Lumos {

        BeforeEach {

            Mock Get-UserLocation {
                [pscustomobject]@{
                    Latitude  = '51.5074'
                    Longitude = '-0.1278'
                }
            }

            Mock Get-LocalDaylight {
                [pscustomobject]@{
                    Sunrise = Get-Date '06:00'
                    Sunset  = Get-Date '20:00'
                }
            }

            # Set-ScheduledTask and Stop-Process have real side effects (they'd modify the live scheduled
            # task and kill the running Explorer process), so those are the only two cmdlets mocked here.
            Mock Set-ScheduledTask {}
            Mock Stop-Process {}
        }

        Context 'Update-LumosScheduledTask -Confirm:$false' {

            BeforeEach {
                $UpdateLumosScheduledTask = Update-LumosScheduledTask -Confirm:$false
            }

            It 'Should return null' {
                $UpdateLumosScheduledTask | Should -Be $null
            }

            It 'Should get the current user location' {
                Should -Invoke Get-UserLocation -Times 1 -Exactly
            }

            It 'Should get the local daylight for that location' {
                Should -Invoke Get-LocalDaylight -Times 1 -Exactly -ParameterFilter {
                    $Latitude -eq '51.5074' -and $Longitude -eq '-0.1278'
                }
            }

            It 'Should update the Lumos scheduled task with three triggers (logon, sunrise, sunset)' {
                Should -Invoke Set-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and $Trigger.Count -eq 3
                }
            }

            It 'Should restart Explorer to apply the change' {
                Should -Invoke Stop-Process -Times 1 -Exactly -ParameterFilter {
                    $ProcessName -eq 'explorer'
                }
            }
        }

        Context 'Update-LumosScheduledTask -WhatIf' {

            BeforeEach {
                $UpdateLumosScheduledTask = Update-LumosScheduledTask -WhatIf
            }

            It 'Should return null' {
                $UpdateLumosScheduledTask | Should -Be $null
            }

            It 'Should not update the scheduled task' {
                Should -Invoke Set-ScheduledTask -Times 0 -Exactly
            }

            It 'Should not restart Explorer' {
                Should -Invoke Stop-Process -Times 0 -Exactly
            }
        }

        Context 'Update-LumosScheduledTask with Get-UserLocation returning null' {

            BeforeEach {
                Mock Get-UserLocation {}
            }

            It 'Should throw and not update the scheduled task' {
                { Update-LumosScheduledTask -Confirm:$false } | Should -Throw 'Could not get sunrise/sunset data for the current user.'

                Should -Invoke Set-ScheduledTask -Times 0 -Exactly
            }
        }
    }
}

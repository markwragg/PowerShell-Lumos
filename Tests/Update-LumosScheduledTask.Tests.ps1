if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

# Depends on the Windows-only ScheduledTasks module, so these tests only run on Windows.
$IsWindowsPlatform = $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows

Describe "Update-LumosScheduledTask PS$PSVersion" -Skip:(-not $IsWindowsPlatform) {

    InModuleScope Lumos {

        BeforeEach {

            # Actions/Principal/Settings are left as real CIM objects (built via the real New-ScheduledTask*
            # cmdlets) rather than plain stand-ins, since Update-LumosScheduledTask passes them straight into
            # New-ScheduledTask's CimInstance-typed parameters, which reject plain PSCustomObjects.
            Mock Get-ScheduledTask {
                [pscustomobject]@{
                    TaskName  = 'Lumos'
                    Actions   = New-ScheduledTaskAction -Execute 'pwsh.exe' -Argument '-Command Invoke-Lumos'
                    Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
                    Settings  = New-ScheduledTaskSettingsSet -StartWhenAvailable
                }
            }

            Mock Unregister-ScheduledTask {}
            Mock Register-ScheduledTask {}

            $Script:MockSunrise = Get-Date -Hour 7 -Minute 0 -Second 0 -Millisecond 0
            $Script:MockSunset = Get-Date -Hour 19 -Minute 0 -Second 0 -Millisecond 0

            Mock Get-UserLocation {
                [pscustomobject]@{
                    Latitude  = 51.5074
                    Longitude = -0.1278
                }
            }

            Mock Get-LocalDaylight {
                [pscustomobject]@{
                    Sunrise = $Script:MockSunrise
                    Sunset  = $Script:MockSunset
                }
            }
        }

        Context 'Update-LumosScheduledTask' {

            BeforeEach {
                $UpdateLumosScheduledTask = Update-LumosScheduledTask -Confirm:$false
            }

            It 'Should return null' {
                $UpdateLumosScheduledTask | Should -Be $null
            }

            It 'Should check that the Lumos scheduled task exists' {
                Should -Invoke Get-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos'
                }
            }

            It 'Should look up the current location and daylight times' {
                Should -Invoke Get-UserLocation -Times 1 -Exactly

                Should -Invoke Get-LocalDaylight -Times 1 -Exactly -ParameterFilter {
                    $Latitude -eq 51.5074 -and $Longitude -eq -0.1278
                }
            }

            It 'Should recreate the Lumos scheduled task with sunrise and sunset triggers' {
                Should -Invoke Unregister-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos'
                }

                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and
                    $InputObject.Triggers.Count -eq 2 -and
                    ([datetime]$InputObject.Triggers[0].StartBoundary) -eq $Script:MockSunrise -and
                    ([datetime]$InputObject.Triggers[1].StartBoundary) -eq $Script:MockSunset
                }
            }

            It 'Should preserve the existing action and principal when recreating the task' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $InputObject.Actions[0].Execute -eq 'pwsh.exe' -and
                    $InputObject.Actions[0].Arguments -eq '-Command Invoke-Lumos' -and
                    $InputObject.Principal.UserId -eq $env:USERNAME
                }
            }
        }

        Context 'Update-LumosScheduledTask with -WhatIf' {

            BeforeEach {
                Update-LumosScheduledTask -WhatIf
            }

            It 'Should not recreate the scheduled task' {
                Should -Invoke Unregister-ScheduledTask -Times 0 -Exactly
                Should -Invoke Register-ScheduledTask -Times 0 -Exactly
            }
        }

        Context 'Update-LumosScheduledTask when no Lumos scheduled task exists' {

            BeforeEach {
                Mock Get-ScheduledTask {}
                Mock Write-Warning {}

                $UpdateLumosScheduledTask = Update-LumosScheduledTask -Confirm:$false
            }

            It 'Should return null without updating anything' {
                $UpdateLumosScheduledTask | Should -Be $null

                Should -Invoke Register-ScheduledTask -Times 0 -Exactly
            }

            It 'Should warn that no Lumos scheduled task was found' {
                Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter {
                    $Message -eq "No 'Lumos' scheduled task was found. Run Register-LumosScheduledTask first."
                }
            }
        }

        Context 'Update-LumosScheduledTask when the current location cannot be determined' {

            BeforeEach {
                Mock Get-UserLocation {}
                Mock Write-Error {}

                $UpdateLumosScheduledTask = Update-LumosScheduledTask -Confirm:$false
            }

            It 'Should return null without updating anything' {
                $UpdateLumosScheduledTask | Should -Be $null

                Should -Invoke Register-ScheduledTask -Times 0 -Exactly
            }

            It 'Should write an error that the current location could not be determined' {
                Should -Invoke Write-Error -Times 1 -Exactly -ParameterFilter {
                    $Message -eq 'Could not get sunrise/sunset data for the current user.'
                }
            }
        }

        Context 'Update-LumosScheduledTask on a non-Windows OS' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {

            BeforeEach {
                Set-Variable -Name 'IsWindows' -Value $false -Force -Scope Global

                Mock Write-Warning {}

                $UpdateLumosScheduledTask = Update-LumosScheduledTask -Confirm:$false
            }

            AfterEach {
                Set-Variable -Name 'IsWindows' -Value $true -Force -Scope Global
            }

            It 'Should return null without updating anything' {
                $UpdateLumosScheduledTask | Should -Be $null

                Should -Invoke Register-ScheduledTask -Times 0 -Exactly
            }

            It 'Should warn that the cmdlet is Windows only' {
                Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter {
                    $Message -eq 'Update-LumosScheduledTask is only supported on Windows.'
                }
            }
        }
    }
}

if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

# Registering a scheduled task depends on the Windows-only ScheduledTasks module, so these tests only run on Windows.
$IsWindowsPlatform = $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows

Describe "Register-LumosScheduledTask PS$PSVersion" -Skip:(-not $IsWindowsPlatform) {

    InModuleScope Lumos {

        BeforeEach {

            # New-ScheduledTask* cmdlets only build in-memory CIM objects, so they're left real rather than
            # mocked - the CimInstance-typed parameters they bind to reject plain PSCustomObject stand-ins.
            # Register-ScheduledTask and Update-LumosScheduledTask are the calls with real side effects, so
            # only those are mocked.
            Mock Register-ScheduledTask {}
            Mock Update-LumosScheduledTask {}
        }

        Context 'Register-LumosScheduledTask' {

            BeforeEach {
                $RegisterLumosScheduledTask = Register-LumosScheduledTask
            }

            It 'Should return null' {
                $RegisterLumosScheduledTask | Should -Be $null
            }

            It 'Should register a scheduled task named Lumos with two actions' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and $Force -and $InputObject.Actions.Count -eq 2
                }
            }

            It 'Should call Update-LumosScheduledTask to set the triggers' {
                Should -Invoke Update-LumosScheduledTask -Times 1 -Exactly
            }
        }

        Context 'Register-LumosScheduledTask with all switches and wallpapers' {

            BeforeEach {
                Register-LumosScheduledTask -ExcludeSystem -ExcludeApps -IncludeOfficeProPlus `
                    -DarkWallpaper 'c:\dark.png' -LightWallpaper 'c:\light.png'
            }

            It 'Should include all specified arguments in the Lumos scheduled task action' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $LumosArgument = ($InputObject.Actions | Where-Object Execute -EQ 'powershell.exe' |
                        Where-Object { $_.Arguments -like '*Invoke-Lumos*' }).Arguments

                    $LumosArgument -like '*-ExcludeSystem*' -and
                    $LumosArgument -like '*-ExcludeApps*' -and
                    $LumosArgument -like '*-IncludeOfficeProPlus*' -and
                    $LumosArgument -like "*-LightWallpaper 'c:\light.png'*" -and
                    $LumosArgument -like "*-DarkWallpaper 'c:\dark.png'*"
                }
            }
        }

        Context 'Register-LumosScheduledTask with no switches' {

            BeforeEach {
                Register-LumosScheduledTask
            }

            It 'Should not include any optional arguments in the Lumos scheduled task action' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $LumosArgument = ($InputObject.Actions | Where-Object Execute -EQ 'powershell.exe' |
                        Where-Object { $_.Arguments -like '*Invoke-Lumos*' }).Arguments

                    $LumosArgument -eq '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command Invoke-Lumos'
                }
            }
        }
    }
}

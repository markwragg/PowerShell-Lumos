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
            # Register-ScheduledTask is the call with a real side effect, so it's the only one mocked.
            Mock Register-ScheduledTask {}

            # Mirrors Register-LumosScheduledTask's own executable-selection logic, so tests assert against
            # whichever edition (PS Core vs Windows PowerShell) is actually running them, rather than a
            # hardcoded 'powershell.exe' that would only match on one of the two editions CI runs this in.
            $Script:ExpectedPowerShellExe = if ($PSVersionTable.PSEdition -eq 'Core') {
                Join-Path -Path $PSHOME -ChildPath 'pwsh.exe'
            }
            else {
                Join-Path -Path $PSHOME -ChildPath 'powershell.exe'
            }
        }

        Context 'Register-LumosScheduledTask' {

            BeforeEach {
                $RegisterLumosScheduledTask = Register-LumosScheduledTask
            }

            It 'Should return null' {
                $RegisterLumosScheduledTask | Should -Be $null
            }

            It 'Should register a scheduled task named Lumos with one action' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and $Force -and $InputObject.Actions.Count -eq 1
                }
            }

            It 'Should register the task with a single repeating 15 minute trigger and no "at logon" trigger' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $InputObject.Triggers.Count -eq 1 -and
                    $InputObject.Triggers[0].Repetition.Interval -eq 'PT15M' -and
                    $InputObject.Triggers[0].CimClass.CimClassName -ne 'MSFT_TaskLogonTrigger'
                }
            }

            It 'Should register the task to run as the current user without requiring elevation' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $InputObject.Principal.UserId -eq $env:USERNAME -and
                    $InputObject.Principal.RunLevel -eq 'Limited'
                }
            }
        }

        Context 'Register-LumosScheduledTask with all switches and wallpapers' {

            BeforeEach {
                Register-LumosScheduledTask -ExcludeSystem -ExcludeApps -IncludeOfficeProPlus `
                    -DarkWallpaper 'c:\dark.png' -LightWallpaper 'c:\light.png'
            }

            It 'Should include all specified arguments in the Lumos scheduled task action' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $LumosArgument = ($InputObject.Actions | Where-Object Execute -EQ $Script:ExpectedPowerShellExe |
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
                    $LumosArgument = ($InputObject.Actions | Where-Object Execute -EQ $Script:ExpectedPowerShellExe |
                        Where-Object { $_.Arguments -like '*Invoke-Lumos*' }).Arguments

                    $LumosArgument -eq '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command Invoke-Lumos'
                }
            }
        }

        Context 'Register-LumosScheduledTask when running under PowerShell Core' {

            BeforeEach {
                # Shadows the real $PSVersionTable (Script scope, inside InModuleScope, so this only
                # affects code resolving the variable through the Lumos module - see the equivalent trick
                # in Invoke-Lumos.Tests.ps1 for why Global scope would be the wrong choice here) to
                # simulate running under PS Core regardless of which edition is actually running this test.
                Set-Variable -Name 'PSVersionTable' -Value ([pscustomobject]@{ PSEdition = 'Core' }) -Force -Scope Script

                Register-LumosScheduledTask
            }

            AfterEach {
                # Without this, the shadow leaks into later contexts in this file - in particular the
                # "non-Windows OS" context below relies on the real $PSVersionTable.PSEdition to correctly
                # take its early-return path.
                Remove-Variable -Name 'PSVersionTable' -Scope Script -Force -ErrorAction SilentlyContinue
            }

            It 'Should target pwsh.exe rather than Windows PowerShell' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $InputObject.Actions[0].Execute -eq (Join-Path -Path $PSHOME -ChildPath 'pwsh.exe')
                }
            }
        }

        Context 'Register-LumosScheduledTask when running under Windows PowerShell' {

            BeforeEach {
                Set-Variable -Name 'PSVersionTable' -Value ([pscustomobject]@{ PSEdition = 'Desktop' }) -Force -Scope Script

                Register-LumosScheduledTask
            }

            AfterEach {
                Remove-Variable -Name 'PSVersionTable' -Scope Script -Force -ErrorAction SilentlyContinue
            }

            It 'Should target powershell.exe rather than PS Core' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $InputObject.Actions[0].Execute -eq (Join-Path -Path $PSHOME -ChildPath 'powershell.exe')
                }
            }
        }

        Context 'Register-LumosScheduledTask on a non-Windows OS' -Skip:($PSVersionTable.PSEdition -eq 'Desktop') {

            BeforeEach {
                Set-Variable -Name 'IsWindows' -Value $false -Force -Scope Global

                Mock Write-Warning {}

                $RegisterLumosScheduledTask = Register-LumosScheduledTask
            }

            AfterEach {
                Set-Variable -Name 'IsWindows' -Value $true -Force -Scope Global
            }

            It 'Should return null without registering a scheduled task' {
                $RegisterLumosScheduledTask | Should -Be $null

                Should -Invoke Register-ScheduledTask -Times 0 -Exactly
            }

            It 'Should warn that the cmdlet is Windows only' {
                Should -Invoke Write-Warning -Times 1 -Exactly -ParameterFilter {
                    $Message -eq 'Register-LumosScheduledTask is only supported on Windows.'
                }
            }
        }
    }
}

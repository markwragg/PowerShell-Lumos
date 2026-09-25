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
            # Register-ScheduledTask is the call with a real side effect, so it's the only one mocked - its
            # stand-in mirrors the TaskName/Triggers a real registered task would have, since
            # Register-LumosScheduledTask now returns whatever this call returns.
            Mock Register-ScheduledTask { [pscustomobject]@{ TaskName = $TaskName; Triggers = $InputObject.Triggers } }

            # Default: no pre-existing "Lumos-Maintenance" task, so the -Sunrise/-Sunset and -FromNightLight
            # cleanup logic has nothing to remove. Individual contexts below override this to verify removal.
            Mock Get-ScheduledTask {}
            Mock Unregister-ScheduledTask {}

            # Get-UserLocation/Get-LocalDaylight call live external APIs - mocking them keeps these tests
            # deterministic and network-free, and lets the exact trigger times below be asserted precisely.
            # Millisecond is zeroed so the mocked value round-trips exactly through the CIM trigger's
            # StartBoundary string (which only has second precision) for equality comparisons below.
            $Script:MockSunrise = Get-Date -Hour 7 -Minute 0 -Second 0 -Millisecond 0
            $Script:MockSunset = Get-Date -Hour 19 -Minute 0 -Second 0 -Millisecond 0
            $Script:MockSolarNoon = Get-Date -Hour 13 -Minute 0 -Second 0 -Millisecond 0

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

            # Mirrors Register-LumosScheduledTask's own executable-selection logic (including the
            # WindowsApps-alias substitution below), so tests assert against whichever edition/install this
            # is actually running under, rather than assuming a hardcoded path that would only be correct
            # for one specific combination of edition and install method.
            $Script:ExpectedPowerShellExe = if ($PSVersionTable.PSEdition -eq 'Core') {
                $PSHomeExe = Join-Path -Path $PSHOME -ChildPath 'pwsh.exe'
                $StableAliasExe = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\WindowsApps\pwsh.exe'

                if ($PSHomeExe -like '*\WindowsApps\*' -and (Test-Path -Path $StableAliasExe)) {
                    $StableAliasExe
                }
                else {
                    $PSHomeExe
                }
            }
            else {
                Join-Path -Path $PSHOME -ChildPath 'powershell.exe'
            }
        }

        Context 'Register-LumosScheduledTask' {

            BeforeEach {
                $RegisterLumosScheduledTask = Register-LumosScheduledTask
            }

            It 'Should return both the Lumos and Lumos-Maintenance registered tasks' {
                $RegisterLumosScheduledTask.Count | Should -Be 2
                $RegisterLumosScheduledTask[0].TaskName | Should -Be 'Lumos'
                $RegisterLumosScheduledTask[1].TaskName | Should -Be 'Lumos-Maintenance'
            }

            It 'Should decorate both tasks with a custom type and a Source/Schedule summary for display' {
                $RegisterLumosScheduledTask[0].PSObject.TypeNames | Should -Contain 'Lumos.ScheduledTask'
                $RegisterLumosScheduledTask[0].ScheduleSource | Should -Be 'Location'
                $RegisterLumosScheduledTask[0].Schedule | Should -Be 'Light 07:00, Dark 19:00'

                $RegisterLumosScheduledTask[1].PSObject.TypeNames | Should -Contain 'Lumos.ScheduledTask'
                $RegisterLumosScheduledTask[1].ScheduleSource | Should -Be 'Location'
                $RegisterLumosScheduledTask[1].Schedule | Should -Be "Weekly $($Script:MockSolarNoon.DayOfWeek) 13:00"
            }

            It 'Should look up the current location and daylight times to compute the trigger times' {
                Should -Invoke Get-UserLocation -Times 1 -Exactly

                Should -Invoke Get-LocalDaylight -Times 1 -Exactly -ParameterFilter {
                    $Latitude -eq 51.5074 -and $Longitude -eq -0.1278
                }
            }

            It 'Should register a scheduled task named Lumos with one action' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and $Force -and $InputObject.Actions.Count -eq 1
                }
            }

            It 'Should register the Lumos task with daily sunrise/sunset triggers and no "at logon" trigger' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and
                    $InputObject.Triggers.Count -eq 2 -and
                    ($InputObject.Triggers | Where-Object { $_.CimClass.CimClassName -eq 'MSFT_TaskLogonTrigger' }).Count -eq 0 -and
                    ([datetime]$InputObject.Triggers[0].StartBoundary) -eq $Script:MockSunrise -and
                    ([datetime]$InputObject.Triggers[1].StartBoundary) -eq $Script:MockSunset
                }
            }

            It 'Should register the task to run as the current user without requiring elevation' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and
                    $InputObject.Principal.UserId -eq $env:USERNAME -and
                    $InputObject.Principal.RunLevel -eq 'Limited'
                }
            }

            It 'Should also register a Lumos-Maintenance task with a single weekly trigger at solar noon' {
                # Mirrors Register-LumosScheduledTask's own DaysOfWeek computation, rather than hand-deriving
                # the CIM bitmask (Sunday=1, Monday=2, Tuesday=4, ...) separately here.
                $Script:ExpectedDaysOfWeek = (New-ScheduledTaskTrigger -Weekly -DaysOfWeek (Get-Date).DayOfWeek -At $Script:MockSolarNoon).DaysOfWeek

                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos-Maintenance' -and
                    $Force -and
                    $InputObject.Triggers.Count -eq 1 -and
                    $InputObject.Triggers[0].CimClass.CimClassName -eq 'MSFT_TaskWeeklyTrigger' -and
                    $InputObject.Triggers[0].DaysOfWeek -eq $Script:ExpectedDaysOfWeek -and
                    ([datetime]$InputObject.Triggers[0].StartBoundary) -eq $Script:MockSolarNoon -and
                    $InputObject.Actions[0].Arguments -like '*Update-LumosScheduledTask*'
                }
            }

            It 'Should have both tasks explicitly import Lumos from its own module path, rather than relying on auto-loading' {
                $Script:ExpectedModulePath = (Get-Module -Name 'Lumos').Path

                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and
                    $InputObject.Actions[0].Arguments -like "*Import-Module '$Script:ExpectedModulePath' -Force;*"
                }

                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos-Maintenance' -and
                    $InputObject.Actions[0].Arguments -like "*Import-Module '$Script:ExpectedModulePath' -Force;*"
                }
            }

            It 'Should not check for or remove any existing Lumos-Maintenance task, since one is being registered anyway' {
                Should -Invoke Get-ScheduledTask -Times 0 -Exactly
                Should -Invoke Unregister-ScheduledTask -Times 0 -Exactly
            }
        }

        Context 'Register-LumosScheduledTask when the current location cannot be determined' {

            BeforeEach {
                Mock Get-UserLocation {}
            }

            It 'Should throw and not register any scheduled task' {
                { Register-LumosScheduledTask } | Should -Throw 'Could not get sunrise/sunset data for the current user.'

                Should -Invoke Register-ScheduledTask -Times 0 -Exactly
            }
        }

        Context 'Register-LumosScheduledTask -Sunrise -Sunset' {

            BeforeEach {
                $RegisterLumosScheduledTask = Register-LumosScheduledTask -Sunrise $Script:MockSunrise -Sunset $Script:MockSunset
            }

            It 'Should return just the registered Lumos task' {
                $RegisterLumosScheduledTask.TaskName | Should -Be 'Lumos'
            }

            It 'Should decorate the task with a custom type and a Source/Schedule summary for display' {
                $RegisterLumosScheduledTask.PSObject.TypeNames | Should -Contain 'Lumos.ScheduledTask'
                $RegisterLumosScheduledTask.ScheduleSource | Should -Be 'Custom'
                $RegisterLumosScheduledTask.Schedule | Should -Be 'Light 07:00, Dark 19:00'
            }

            It 'Should not look up the current location or daylight times' {
                Should -Invoke Get-UserLocation -Times 0 -Exactly
                Should -Invoke Get-LocalDaylight -Times 0 -Exactly
            }

            It 'Should register the Lumos task using the specified sunrise/sunset trigger times' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and
                    $InputObject.Triggers.Count -eq 2 -and
                    ([datetime]$InputObject.Triggers[0].StartBoundary) -eq $Script:MockSunrise -and
                    ([datetime]$InputObject.Triggers[1].StartBoundary) -eq $Script:MockSunset
                }
            }

            It 'Should not register a Lumos-Maintenance task, since fixed times do not need updating' {
                Should -Invoke Register-ScheduledTask -Times 0 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos-Maintenance'
                }
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly
            }

            It 'Should check for an existing Lumos-Maintenance task, but not remove one since none exists' {
                Should -Invoke Get-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos-Maintenance'
                }
                Should -Invoke Unregister-ScheduledTask -Times 0 -Exactly
            }
        }

        Context 'Register-LumosScheduledTask -Sunrise -Sunset when a Lumos-Maintenance task already exists' {

            BeforeEach {
                Mock Get-ScheduledTask {
                    [pscustomobject]@{ TaskName = 'Lumos-Maintenance' }
                } -ParameterFilter { $TaskName -eq 'Lumos-Maintenance' }

                Register-LumosScheduledTask -Sunrise $Script:MockSunrise -Sunset $Script:MockSunset
            }

            It 'Should remove the existing Lumos-Maintenance task, since it is not needed for a fixed schedule' {
                Should -Invoke Unregister-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos-Maintenance'
                }
            }
        }

        Context 'Register-LumosScheduledTask -FromNightLight' {

            BeforeEach {
                Mock Get-NightLightSchedule {
                    [pscustomobject]@{
                        Sunrise = $Script:MockSunrise
                        Sunset  = $Script:MockSunset
                    }
                }

                $RegisterLumosScheduledTask = Register-LumosScheduledTask -FromNightLight
            }

            It 'Should return just the registered Lumos task' {
                $RegisterLumosScheduledTask.TaskName | Should -Be 'Lumos'
            }

            It 'Should decorate the task with a custom type and a Source/Schedule summary for display' {
                $RegisterLumosScheduledTask.PSObject.TypeNames | Should -Contain 'Lumos.ScheduledTask'
                $RegisterLumosScheduledTask.ScheduleSource | Should -Be 'Night Light'
                $RegisterLumosScheduledTask.Schedule | Should -Be 'Light 07:00, Dark 19:00'
            }

            It 'Should not look up the current location or daylight times' {
                Should -Invoke Get-UserLocation -Times 0 -Exactly
                Should -Invoke Get-LocalDaylight -Times 0 -Exactly
            }

            It 'Should read the Night Light schedule' {
                Should -Invoke Get-NightLightSchedule -Times 1 -Exactly
            }

            It 'Should register the Lumos task using the Night Light schedule trigger times' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and
                    $InputObject.Triggers.Count -eq 2 -and
                    ([datetime]$InputObject.Triggers[0].StartBoundary) -eq $Script:MockSunrise -and
                    ([datetime]$InputObject.Triggers[1].StartBoundary) -eq $Script:MockSunset
                }
            }

            It 'Should not register a Lumos-Maintenance task, since the schedule is only read once' {
                Should -Invoke Register-ScheduledTask -Times 0 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos-Maintenance'
                }
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly
            }

            It 'Should check for an existing Lumos-Maintenance task, but not remove one since none exists' {
                Should -Invoke Get-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos-Maintenance'
                }
                Should -Invoke Unregister-ScheduledTask -Times 0 -Exactly
            }
        }

        Context 'Register-LumosScheduledTask -FromNightLight when a Lumos-Maintenance task already exists' {

            BeforeEach {
                Mock Get-NightLightSchedule {
                    [pscustomobject]@{
                        Sunrise = $Script:MockSunrise
                        Sunset  = $Script:MockSunset
                    }
                }

                Mock Get-ScheduledTask {
                    [pscustomobject]@{ TaskName = 'Lumos-Maintenance' }
                } -ParameterFilter { $TaskName -eq 'Lumos-Maintenance' }

                Register-LumosScheduledTask -FromNightLight
            }

            It 'Should remove the existing Lumos-Maintenance task, since it is not needed for a fixed schedule' {
                Should -Invoke Unregister-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos-Maintenance'
                }
            }
        }

        Context 'Register-LumosScheduledTask -FromNightLight combined with -Sunrise/-Sunset' {

            It 'Should throw and not register any scheduled task' {
                { Register-LumosScheduledTask -FromNightLight -Sunrise $Script:MockSunrise -Sunset $Script:MockSunset } |
                    Should -Throw '-FromNightLight cannot be combined with -Sunrise/-Sunset.'

                Should -Invoke Register-ScheduledTask -Times 0 -Exactly
            }
        }

        Context 'Register-LumosScheduledTask with only -Sunrise or only -Sunset specified' {

            It 'Should throw and not register any scheduled task when only -Sunrise is specified' {
                { Register-LumosScheduledTask -Sunrise $Script:MockSunrise } |
                    Should -Throw '-Sunrise and -Sunset must both be specified together.'

                Should -Invoke Register-ScheduledTask -Times 0 -Exactly
            }

            It 'Should throw and not register any scheduled task when only -Sunset is specified' {
                { Register-LumosScheduledTask -Sunset $Script:MockSunset } |
                    Should -Throw '-Sunrise and -Sunset must both be specified together.'

                Should -Invoke Register-ScheduledTask -Times 0 -Exactly
            }
        }

        Context 'Register-LumosScheduledTask with all switches and wallpapers' {

            BeforeEach {
                Register-LumosScheduledTask -ExcludeSystem -RestartExplorer -ExcludeApps -IncludeOfficeProPlus `
                    -DarkWallpaper 'c:\dark.png' -LightWallpaper 'c:\light.png'
            }

            It 'Should include all specified arguments in the Lumos scheduled task action' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $LumosArgument = ($InputObject.Actions | Where-Object Execute -EQ $Script:ExpectedPowerShellExe |
                        Where-Object { $_.Arguments -like '*Invoke-Lumos*' }).Arguments

                    $TaskName -eq 'Lumos' -and
                    $LumosArgument -like '*-ExcludeSystem*' -and
                    $LumosArgument -like '*-RestartExplorer*' -and
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
                $Script:ExpectedModulePath = (Get-Module -Name 'Lumos').Path

                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $LumosArgument = ($InputObject.Actions | Where-Object Execute -EQ $Script:ExpectedPowerShellExe |
                        Where-Object { $_.Arguments -like '*Invoke-Lumos*' }).Arguments

                    $TaskName -eq 'Lumos' -and
                    $LumosArgument -eq "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -Command Import-Module '$Script:ExpectedModulePath' -Force; Invoke-Lumos -Auto"
                }
            }

        }

        Context 'Register-LumosScheduledTask under PowerShell Core installed via the Microsoft Store (MSIX)' {

            BeforeEach {
                # Shadows both variables at the module's own script scope - see the Desktop edition context
                # below for why this reaches Register-LumosScheduledTask's own lexical scope without
                # touching the real, global $PSVersionTable/$PSHOME the rest of this session relies on.
                Set-Variable -Name 'PSVersionTable' -Value @{ PSEdition = 'Core'; PSVersion = $PSVersionTable.PSVersion } -Force -Scope Script
                Set-Variable -Name 'PSHOME' -Value 'C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.6.0_arm64__8wekyb3d8bbwe' -Force -Scope Script

                Mock Test-Path { $true } -ParameterFilter {
                    $Path -eq (Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\WindowsApps\pwsh.exe')
                }

                Register-LumosScheduledTask
            }

            AfterEach {
                Remove-Variable -Name 'PSVersionTable' -Force -Scope Script -ErrorAction SilentlyContinue
                Remove-Variable -Name 'PSHOME' -Force -Scope Script -ErrorAction SilentlyContinue
            }

            It 'Should use the stable WindowsApps alias path instead of the versioned $PSHOME path' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and
                    ($InputObject.Actions.Execute -contains (Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\WindowsApps\pwsh.exe'))
                }
            }
        }

        Context 'Register-LumosScheduledTask under the Microsoft Store (MSIX), without the stable alias available' {

            BeforeEach {
                Set-Variable -Name 'PSVersionTable' -Value @{ PSEdition = 'Core'; PSVersion = $PSVersionTable.PSVersion } -Force -Scope Script
                Set-Variable -Name 'PSHOME' -Value 'C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.6.0_arm64__8wekyb3d8bbwe' -Force -Scope Script

                # e.g. the user has disabled this specific app-execution-alias under Settings > Apps >
                # Advanced app settings > App execution aliases.
                Mock Test-Path { $false } -ParameterFilter {
                    $Path -eq (Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Microsoft\WindowsApps\pwsh.exe')
                }

                Register-LumosScheduledTask
            }

            AfterEach {
                Remove-Variable -Name 'PSVersionTable' -Force -Scope Script -ErrorAction SilentlyContinue
                Remove-Variable -Name 'PSHOME' -Force -Scope Script -ErrorAction SilentlyContinue
            }

            It 'Should fall back to the versioned $PSHOME path' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and
                    ($InputObject.Actions.Execute -contains (Join-Path -Path 'C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.6.0_arm64__8wekyb3d8bbwe' -ChildPath 'pwsh.exe'))
                }
            }
        }

        Context 'Register-LumosScheduledTask under PowerShell Core installed via a traditional installer' {

            BeforeEach {
                Set-Variable -Name 'PSVersionTable' -Value @{ PSEdition = 'Core'; PSVersion = $PSVersionTable.PSVersion } -Force -Scope Script
                Set-Variable -Name 'PSHOME' -Value 'C:\Program Files\PowerShell\7' -Force -Scope Script

                Register-LumosScheduledTask
            }

            AfterEach {
                Remove-Variable -Name 'PSVersionTable' -Force -Scope Script -ErrorAction SilentlyContinue
                Remove-Variable -Name 'PSHOME' -Force -Scope Script -ErrorAction SilentlyContinue
            }

            It 'Should use pwsh.exe from $PSHOME directly, without substituting the WindowsApps alias' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and
                    ($InputObject.Actions.Execute -contains (Join-Path -Path 'C:\Program Files\PowerShell\7' -ChildPath 'pwsh.exe'))
                }
            }
        }

        Context 'Register-LumosScheduledTask under Windows PowerShell (Desktop edition)' {

            BeforeEach {
                # Shadows the automatic $PSVersionTable variable at the module's own script scope, so
                # Register-LumosScheduledTask's edition check (which reads $PSVersionTable from its
                # lexical parent - the module, not this test file) sees 'Desktop' without touching the
                # real, global $PSVersionTable that Pester and everything else in this session relies on.
                Set-Variable -Name 'PSVersionTable' -Value @{ PSEdition = 'Desktop'; PSVersion = $PSVersionTable.PSVersion } -Force -Scope Script

                Register-LumosScheduledTask
            }

            AfterEach {
                Remove-Variable -Name 'PSVersionTable' -Force -Scope Script -ErrorAction SilentlyContinue
            }

            It 'Should use powershell.exe rather than pwsh.exe' {
                Should -Invoke Register-ScheduledTask -Times 1 -Exactly -ParameterFilter {
                    $TaskName -eq 'Lumos' -and
                    ($InputObject.Actions.Execute -contains (Join-Path -Path $PSHOME -ChildPath 'powershell.exe'))
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

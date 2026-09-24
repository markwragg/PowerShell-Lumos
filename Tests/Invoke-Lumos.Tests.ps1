if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

Describe "Invoke-Lumos PS$PSVersion" {

    InModuleScope Lumos {

        BeforeAll {

            Mock Get-UserLocation {
                [pscustomobject]@{
                    Latitude  = '123.456'
                    Longitude = '-24.567'
                }
            }

            Mock Set-ItemProperty {}

            # Default fallback for calls that don't match the more specific filter below (e.g. the Office
            # identity 'Data' lookup), so real registry state on the machine running the tests can't leak in.
            Mock Get-ItemProperty {}

            # Returns a value that never matches the computed theme (0 or 1), so existing tests exercise the
            # "theme needs to change" path by default. Tests for the "already applied" skip path override this.
            Mock Get-ItemProperty {
                [pscustomobject]@{
                    SystemUsesLightTheme = 99
                    AppsUseLightTheme    = 99
                }
            } -ParameterFilter { $Name -eq 'SystemUsesLightTheme' -or $Name -eq 'AppsUseLightTheme' }

            Mock Set-Wallpaper {}

            Mock Stop-Process {}

            Mock Invoke-AppleScript {}

            Mock Write-Error {}
        }

        # Pins the simulated platform to Windows before every test in this file, so the "default"
        # contexts below exercise the Windows branch regardless of which real OS the CI runner is -
        # without this, they only passed by coincidence of running on a Windows agent. The "on MacOS"
        # / "on Linux" contexts override these in their own (later-running) BeforeEach as needed.
        #
        # Scoped to Script (the Lumos module's own top-level scope, since we're inside InModuleScope),
        # not Global - Invoke-Lumos resolves $IsMacOS/$IsLinux through its module's scope chain, so a
        # Script-scoped shadow is enough to fool it. Overwriting the real Global automatic variables
        # instead would also fool Pester's own internal OS detection (used to build failure reports),
        # so any test throwing while that override was active would crash Pester's own error handling
        # instead of reporting the test's real failure.
        BeforeEach {
            Set-Variable -Name 'IsMacOS' -Value $false -Force -Scope Script
            Set-Variable -Name 'IsLinux' -Value $false -Force -Scope Script
        }

        AfterAll {
            Remove-Variable -Name 'IsMacOS' -Scope Script -Force -ErrorAction SilentlyContinue
            Remove-Variable -Name 'IsLinux' -Scope Script -Force -ErrorAction SilentlyContinue
        }

        Context 'Invoke-Lumos -Light' {

            BeforeEach {
                $InvokeLumos = Invoke-Lumos -Light
            }

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should call Get-Userlocation 0 times' {
                Should -Invoke Get-UserLocation -Times 0 -Exactly
            }

            It 'Should call Set-ItemProperty 2 times' {
                Should -Invoke Set-ItemProperty -Times 2 -Exactly
            }

            It 'Should call Set-Wallpaper 0 times' {
                Should -Invoke Set-Wallpaper -Times 0 -Exactly
            }

            It 'Should restart Explorer so the taskbar picks up the theme change' {
                Should -Invoke Stop-Process -Times 1 -Exactly -ParameterFilter {
                    $ProcessName -eq 'explorer'
                }
            }
        }

        Context 'Invoke-Lumos -Dark' {

            BeforeEach {
                $InvokeLumos = Invoke-Lumos -Dark
            }

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should call Get-Userlocation 1 time' {
                Should -Invoke Get-UserLocation -Times 0 -Exactly
            }

            It 'Should call Set-ItemProperty 2 times' {
                Should -Invoke Set-ItemProperty -Times 2 -Exactly
            }

            It 'Should call Set-Wallpaper 0 times' {
                Should -Invoke Set-Wallpaper -Times 0 -Exactly
            }

            It 'Should restart Explorer so the taskbar picks up the theme change' {
                Should -Invoke Stop-Process -Times 1 -Exactly -ParameterFilter {
                    $ProcessName -eq 'explorer'
                }
            }
        }

        Context 'Invoke-Lumos -Light -ExcludeApps' {

            BeforeEach {
                $InvokeLumos = Invoke-Lumos -Light -ExcludeApps
            }

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should call Get-Userlocation 0 times' {
                Should -Invoke Get-UserLocation -Times 0 -Exactly
            }

            It 'Should call Set-ItemProperty 1 time' {
                Should -Invoke Set-ItemProperty -Times 1 -Exactly
            }

            It 'Should call Set-Wallpaper 0 times' {
                Should -Invoke Set-Wallpaper -Times 0 -Exactly
            }

            It 'Should still restart Explorer, since the System theme was still set' {
                Should -Invoke Stop-Process -Times 1 -Exactly
            }
        }

        Context 'Invoke-Lumos -Dark -DarkWallpaper c:\some\wallpaper.png' {

            BeforeEach {
                $InvokeLumos = Invoke-Lumos -Dark -DarkWallpaper 'c:\some\wallpaper.png'
            }

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should call Get-Userlocation 0 times' {
                Should -Invoke Get-UserLocation -Times 0 -Exactly
            }

            It 'Should call Set-ItemProperty 2 times' {
                Should -Invoke Set-ItemProperty -Times 2 -Exactly
            }

            It 'Should call Set-Wallpaper 1 times' {
                Should -Invoke Set-Wallpaper -Times 1 -Exactly
            }

            It 'Should restart Explorer so the taskbar picks up the theme change' {
                Should -Invoke Stop-Process -Times 1 -Exactly
            }
        }

        Context 'Invoke-Lumos -Light -LightWallpaper c:\some\wallpaper.png' {

            BeforeEach {
                $InvokeLumos = Invoke-Lumos -Light -LightWallpaper 'c:\some\wallpaper.png'
            }

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should call Get-Userlocation 0 times' {
                Should -Invoke Get-UserLocation -Times 0 -Exactly
            }

            It 'Should call Set-ItemProperty 2 times' {
                Should -Invoke Set-ItemProperty -Times 2 -Exactly
            }

            It 'Should call Set-Wallpaper 1 times' {
                Should -Invoke Set-Wallpaper -Times 1 -Exactly
            }

            It 'Should restart Explorer so the taskbar picks up the theme change' {
                Should -Invoke Stop-Process -Times 1 -Exactly
            }
        }


        Context 'Invoke-Lumos when it is currently daytime' {

            BeforeEach {
                # Get-LocalDaylight calls a live external API (sunrise-sunset.org) - mocking it here avoids
                # that network dependency in tests and makes which theme gets applied deterministic, rather
                # than depending on the real time of day wherever/whenever these tests happen to run.
                Mock Get-LocalDaylight {
                    [pscustomobject]@{
                        Sunrise = (Get-Date).AddHours(-1)
                        Sunset  = (Get-Date).AddHours(1)
                    }
                }

                $InvokeLumos = Invoke-Lumos
            }

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should call Get-Userlocation 1 time' {
                Should -Invoke Get-UserLocation -Times 1 -Exactly
            }

            It 'Should set the Light theme, since it is currently between sunrise and sunset' {
                Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'SystemUsesLightTheme' -and $Value -eq 1
                }
            }

            It 'Should call Set-ItemProperty 2 times' {
                Should -Invoke Set-ItemProperty -Times 2 -Exactly
            }

            It 'Should call Set-Wallpaper 0 times' {
                Should -Invoke Set-Wallpaper -Times 0 -Exactly
            }

            It 'Should restart Explorer so the taskbar picks up the theme change' {
                Should -Invoke Stop-Process -Times 1 -Exactly
            }
        }

        Context 'Invoke-Lumos when it is currently night' {

            BeforeEach {
                Mock Get-LocalDaylight {
                    [pscustomobject]@{
                        Sunrise = (Get-Date).AddHours(1)
                        Sunset  = (Get-Date).AddHours(2)
                    }
                }

                $InvokeLumos = Invoke-Lumos
            }

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should set the Dark theme, since it is not currently between sunrise and sunset' {
                Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'SystemUsesLightTheme' -and $Value -eq 0
                }
            }
        }

        Context 'Invoke-Lumos with Get-UserLocation returning null' {

            BeforeAll {
                Mock Get-UserLocation {}
            }

            It 'Should throw "Could not get sunrise/sunset data for the current user and call Get-UserLocation 1 time"' {
                { Invoke-Lumos } | Should -Throw 'Could not get sunrise/sunset data for the current user.'

                Should -Invoke Get-UserLocation -Times 1 -Exactly
            }
        }

        Context 'Invoke-Lumos -Dark -ExcludeSystem' {

            BeforeEach {
                $InvokeLumos = Invoke-Lumos -Dark -ExcludeSystem
            }

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should only set the Apps theme, not the System theme' {
                Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'AppsUseLightTheme'
                }
                Should -Invoke Set-ItemProperty -Times 0 -Exactly -ParameterFilter {
                    $Name -eq 'SystemUsesLightTheme'
                }
            }

            It 'Should not restart Explorer, since the taskbar follows the System theme, which was excluded' {
                Should -Invoke Stop-Process -Times 0 -Exactly
            }
        }

        Context 'Invoke-Lumos -Dark when the System and Apps theme are already Dark' {

            BeforeEach {
                Mock Get-ItemProperty {
                    [pscustomobject]@{
                        SystemUsesLightTheme = 0
                        AppsUseLightTheme    = 0
                    }
                } -ParameterFilter { $Name -eq 'SystemUsesLightTheme' -or $Name -eq 'AppsUseLightTheme' }

                $InvokeLumos = Invoke-Lumos -Dark
            }

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should not set either theme value, since both already match' {
                Should -Invoke Set-ItemProperty -Times 0 -Exactly
            }

            It 'Should not restart Explorer, since the System theme did not change' {
                Should -Invoke Stop-Process -Times 0 -Exactly
            }
        }

        Context 'Invoke-Lumos -Dark when only the System theme is already Dark' {

            BeforeEach {
                Mock Get-ItemProperty {
                    [pscustomobject]@{
                        SystemUsesLightTheme = 0
                        AppsUseLightTheme    = 99
                    }
                } -ParameterFilter { $Name -eq 'SystemUsesLightTheme' -or $Name -eq 'AppsUseLightTheme' }

                $InvokeLumos = Invoke-Lumos -Dark
            }

            It 'Should only set the Apps theme' {
                Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'AppsUseLightTheme'
                }
            }

            It 'Should not restart Explorer, since the System theme did not change' {
                Should -Invoke Stop-Process -Times 0 -Exactly
            }
        }

        Context 'Invoke-Lumos -Dark -ExcludeSystem -ExcludeApps' {

            BeforeEach {
                $InvokeLumos = Invoke-Lumos -Dark -ExcludeSystem -ExcludeApps
            }

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should not set either theme value' {
                Should -Invoke Set-ItemProperty -Times 0 -Exactly
            }

            It 'Should not restart Explorer, since nothing changed' {
                Should -Invoke Stop-Process -Times 0 -Exactly
            }
        }

        # -IncludeOfficeProPlus exercises Set-ItemProperty's registry-provider-only "-Type" dynamic
        # parameter, which only exists once a real Windows registry provider is loaded - Pester's mock
        # proxy is built by reflecting on the real cmdlet, so on non-Windows it has no "-Type" to accept.
        # Invoke-Lumos.ps1 itself already documents -IncludeOfficeProPlus as Windows-only (it writes an
        # error for it on MacOS), so this and the next two contexts only run on Windows - same guard
        # Register-LumosScheduledTask.Tests.ps1 uses, checked inline rather than via an outer-scope
        # variable, since this Context lives inside InModuleScope, which runs in the module's own session
        # state and can't see variables set in the test script's scope above.
        Context 'Invoke-Lumos -Dark -IncludeOfficeProPlus' -Skip:(-not ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows)) {

            BeforeEach {
                # Default for the Office Identities registry key, so a real Office installation on the
                # machine running these tests can't leak in and make Get-ChildItem/Get-ItemProperty below
                # run for real instead of against the mocks.
                Mock Test-Path { $false }

                $InvokeLumos = Invoke-Lumos -Dark -IncludeOfficeProPlus
            }

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should set the Office theme to the dark value' {
                Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'UI Theme' -and $Value -eq 4
                }
            }
        }

        Context 'Invoke-Lumos -Dark -IncludeOfficeProPlus with a signed-in Office identity' -Skip:(-not ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows)) {

            BeforeEach {
                Mock Test-Path { $false }

                Mock Test-Path { $true } -ParameterFilter {
                    $Path -like '*\Roaming\Identities\'
                }

                Mock Get-ChildItem {
                    [pscustomobject]@{ Name = 'HKEY_CURRENT_USER\Software\Microsoft\Office\16.0\Common\Roaming\Identities\{Some-Guid}' }
                } -ParameterFilter { $Path -like '*\Roaming\Identities\' }

                Mock Get-ItemProperty {
                    [pscustomobject]@{ Data = [byte[]](0, 0, 0, 0) }
                } -ParameterFilter { $Name -eq 'Data' }

                $InvokeLumos = Invoke-Lumos -Dark -IncludeOfficeProPlus
            }

            It 'Should update the signed-in identity to match the Office theme value' {
                Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'Data' -and $Path -like '*Identities*'
                }
            }
        }

        Context 'Invoke-Lumos -Light -IncludeOfficeProPlus with O365ProPlus installed' -Skip:(-not ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows)) {

            BeforeEach {
                # Default for every other Test-Path call (e.g. the Office Identities registry key), so it behaves
                # as if no Office identity is signed in, same as a machine with no Office installed.
                Mock Test-Path { $false }

                Mock Test-Path { $true } -ParameterFilter {
                    $Path -like '*O365ProPlusRetail*'
                }

                $InvokeLumos = Invoke-Lumos -Light -IncludeOfficeProPlus
            }

            It 'Should set the Office theme to the O365ProPlus light value' {
                Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'UI Theme' -and $Value -eq 5
                }
            }
        }

        Context 'Invoke-Lumos -Light -IncludeOfficeProPlus without O365ProPlus installed' -Skip:(-not ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows)) {

            BeforeEach {
                # Default for every Test-Path call, including the Office Identities registry key check.
                Mock Test-Path { $false }

                $InvokeLumos = Invoke-Lumos -Light -IncludeOfficeProPlus
            }

            It 'Should set the Office theme to the default light value' {
                Should -Invoke Set-ItemProperty -Times 1 -Exactly -ParameterFilter {
                    $Name -eq 'UI Theme' -and $Value -eq 0
                }
            }
        }

        Context 'Invoke-Lumos -Dark on MacOS' {

            BeforeEach {
                Set-Variable -Name 'IsMacOS' -Value $true -Force -Scope Script

                $InvokeLumos = Invoke-Lumos -Dark
            }

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should not look up the user location' {
                Should -Invoke Get-UserLocation -Times 0 -Exactly
            }

            It 'Should switch to dark mode via AppleScript' {
                Should -Invoke Invoke-AppleScript -Times 1 -Exactly -ParameterFilter {
                    $Command -eq 'tell application \"System Events\" to tell appearance preferences to set dark mode to true'
                }
            }

            It 'Should not touch the Windows registry' {
                Should -Invoke Set-ItemProperty -Times 0 -Exactly
            }

            It 'Should not restart Explorer, since MacOS has no such concept' {
                Should -Invoke Stop-Process -Times 0 -Exactly
            }
        }

        Context 'Invoke-Lumos -Light on MacOS' {

            BeforeEach {
                Set-Variable -Name 'IsMacOS' -Value $true -Force -Scope Script

                $InvokeLumos = Invoke-Lumos -Light
            }

            It 'Should switch to light mode via AppleScript' {
                Should -Invoke Invoke-AppleScript -Times 1 -Exactly -ParameterFilter {
                    $Command -eq 'tell application \"System Events\" to tell appearance preferences to set dark mode to false'
                }
            }
        }

        Context 'Invoke-Lumos on MacOS with no -Dark or -Light switch' {

            BeforeEach {
                Set-Variable -Name 'IsMacOS' -Value $true -Force -Scope Script

                $InvokeLumos = Invoke-Lumos
            }

            It 'Should not look up the user location' {
                Should -Invoke Get-UserLocation -Times 0 -Exactly
            }

            It 'Should toggle whichever mode is not currently active' {
                Should -Invoke Invoke-AppleScript -Times 1 -Exactly -ParameterFilter {
                    $Command -eq 'tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode'
                }
            }
        }

        Context 'Invoke-Lumos -Dark -DarkWallpaper on MacOS' {

            BeforeEach {
                Set-Variable -Name 'IsMacOS' -Value $true -Force -Scope Script

                $InvokeLumos = Invoke-Lumos -Dark -DarkWallpaper 'c:\some\wallpaper.png'
            }

            It 'Should call AppleScript twice: once for the theme, once for the wallpaper' {
                Should -Invoke Invoke-AppleScript -Times 2 -Exactly
            }

            It 'Should set the wallpaper via AppleScript' {
                Should -Invoke Invoke-AppleScript -Times 1 -Exactly -ParameterFilter {
                    $Command -eq 'tell application \"System Events\" to tell current desktop to set picture to \"c:\some\wallpaper.png\"'
                }
            }

            It 'Should not call the Windows-only Set-Wallpaper function' {
                Should -Invoke Set-Wallpaper -Times 0 -Exactly
            }
        }

        Context 'Invoke-Lumos -Dark -ExcludeSystem -ExcludeApps -IncludeOfficeProPlus on MacOS' {

            BeforeEach {
                Set-Variable -Name 'IsMacOS' -Value $true -Force -Scope Script

                $InvokeLumos = Invoke-Lumos -Dark -ExcludeSystem -ExcludeApps -IncludeOfficeProPlus
            }

            It 'Should warn that each Windows-only switch is unsupported on MacOS' {
                Should -Invoke Write-Error -Times 3 -Exactly
            }
        }

        Context 'Invoke-Lumos on Linux' {

            BeforeEach {
                Set-Variable -Name 'IsLinux' -Value $true -Force -Scope Script
            }

            It 'Should throw as Linux is not supported' {
                { Invoke-Lumos -Dark } | Should -Throw 'Linux is not currently supported by this module.'
            }
        }
    }
}
Function Invoke-Lumos {
    <#
        .SYNOPSIS
            Sets the Windows, Mac or Linux (GNOME) Theme to light or dark mode.

        .DESCRIPTION
            Use this cmdlet to change the theme on Windows 10/11, macOS or Linux (GNOME desktop only) to the
            light or dark theme, either as specified by parameters, automatically based on your location and
            whether it is currently before or after sunrise/sunset (-Auto), or (if none of those are
            specified) by toggling to whichever theme isn't currently active.

        .PARAMETER Dark
            Switch to the Dark OS theme.

        .PARAMETER Light
            Switch to the Light OS theme.

        .PARAMETER Auto
            Switch to the Dark or Light OS theme automatically, based on your current location (determined
            via your public IP address) and whether it is currently before or after sunrise/sunset there.
            Defaults to the value saved with Set-LumosDefault -Auto, if any.

        .PARAMETER ExcludeSystem
            Exclude changing the System theme when switching to Dark/Light (Windows only). Defaults to the
            value saved with Set-LumosDefault -ExcludeSystem, if any.

        .PARAMETER RestartExplorer
            Restart Explorer to apply the System theme change (Windows only), instead of the default of
            broadcasting a WM_SETTINGCHANGE/WM_THEMECHANGED message. Use this if the taskbar still doesn't
            update without it on your system, or if you want any File Explorer windows you already had open
            to pick up the change too - the broadcast alone reliably updates the taskbar, but not existing
            Explorer windows' own chrome. Defaults to the value saved with Set-LumosDefault -RestartExplorer,
            if any.

        .PARAMETER IncludeOfficeProPlus
            Include changing the theme of Microsoft Office to Dark/Light (Windows only). Defaults to the
            value saved with Set-LumosDefault -IncludeOfficeProPlus, if any.

        .PARAMETER ExcludeApps
            Exclude changing the Applications (where supported) theme when switching to Dark/Light (Windows
            only). Defaults to the value saved with Set-LumosDefault -ExcludeApps, if any.

        .PARAMETER DarkWallpaper
            Specify a path to use to modify the Desktop Wallpaper to when switching to the Dark theme.
            Defaults to the value saved with Set-LumosDefault -DarkWallpaper, if any.

        .PARAMETER LightWallpaper
            Specify a path to use to modify the Desktop Wallpaper to when switching to the Light theme.
            Defaults to the value saved with Set-LumosDefault -LightWallpaper, if any.

        .EXAMPLE
            Invoke-Lumos -Dark -DarkWallpaper ./dark-wallpaper.png

            Switches the OS theme to the Dark theme and specified Wallpaper.

        .EXAMPLE
            Invoke-Lumos -Light -LightWallpaper ./light-wallpaper.png

            Swithches the OS theme to the Light theme and specified Wallpaper.

        .EXAMPLE
            Invoke-Lumos -Dark -ExcludeApps

            Switches the OS theme to Dark, but (on Windows only) does not change the theme of apps that support
            Dark/Light theme.

        .EXAMPLE
            Invoke-Lumos -Dark -RestartExplorer

            Switches the OS theme to Dark and restarts Explorer (Windows only) to apply the change to the
            taskbar, instead of the default of broadcasting a WM_SETTINGCHANGE message.

        .Example
            Invoke-Lumos -Auto

            Switches to either the Dark or Light theme, dependent on your current location and time of day.

        .Example
            Invoke-Lumos

            Switches the current theme to its alternate, i.e. if it's Light it will switch to Dark and if
            Dark switch to Light.
    #>
    [cmdletbinding(DefaultParameterSetName = 'Dark')]
    Param(
        [Parameter(ParameterSetName = 'Dark')]
        [switch]
        $Dark,

        [Parameter(ParameterSetName = 'Light')]
        [switch]
        $Light,

        [Parameter(ParameterSetName = 'Auto')]
        [switch]
        $Auto = (Get-LumosDefaultValue -Name 'Auto' -Value $false),

        [switch]
        $ExcludeSystem = (Get-LumosDefaultValue -Name 'ExcludeSystem' -Value $false),

        [switch]
        $RestartExplorer = (Get-LumosDefaultValue -Name 'RestartExplorer' -Value $false),

        [switch]
        $IncludeOfficeProPlus = (Get-LumosDefaultValue -Name 'IncludeOfficeProPlus' -Value $false),

        [switch]
        $ExcludeApps = (Get-LumosDefaultValue -Name 'ExcludeApps' -Value $false),

        [string]
        $DarkWallpaper = (Get-LumosDefaultValue -Name 'DarkWallpaper' -Value $null),

        [string]
        $LightWallpaper = (Get-LumosDefaultValue -Name 'LightWallpaper' -Value $null)
    )

    if ($Dark) {
        $Lumos = 0
    }
    elseif ($Light) {
        $Lumos = 1
    }
    elseif ($Auto) {
        $CurrentTime = Get-Date
        $UserLocation = Get-UserLocation

        if ($UserLocation) {
            $DayLight = Get-LocalDaylight -Latitude $UserLocation.Latitude -Longitude $UserLocation.Longitude
        }
        else {
            Throw 'Could not get sunrise/sunset data for the current user.'
        }

        if ($CurrentTime -ge $DayLight.Sunrise -and $CurrentTime -lt $DayLight.Sunset) {
            $Lumos = 1
        }
        else {
            $Lumos = 0
        }
    }
    else {
        # Leaving Lumos as undefined will make it just alternate to whatever mode it currently is not
        $Lumos = 'Undefined'
    }

    Switch ($Lumos) {
        0 {
            $Status = 'Dark'
            if ($DarkWallpaper) { $Wallpaper = $DarkWallpaper }
        }
        1 {
            $Status = 'Light'
            if ($LightWallpaper) { $Wallpaper = $LightWallpaper }
        }
        default {
            $Status = 'Undefined'
        }
    }

    if ($IsMacOS) {
        ### MacOS ###
        if ($PSVersionTable.PSVersion -lt [Version]'7.3') {
            Throw 'Lumos requires PowerShell 7.3 or later on MacOS, since older versions pass the AppleScript commands used to change the theme/wallpaper through incorrectly.'
        }

        $MacCommand = if ($Lumos -eq 0) {
            'tell application "System Events" to tell appearance preferences to set dark mode to true'
        }
        elseif ($Lumos -eq 1) {
            'tell application "System Events" to tell appearance preferences to set dark mode to false'
        }
        else {
            'tell application "System Events" to tell appearance preferences to set dark mode to not dark mode'
        }

        Invoke-AppleScript -Command $MacCommand

        if ($ExcludeSystem) {
            Write-Error '-ExcludeSystem is not currently supported on MacOS.'
        }

        if ($ExcludeApps) {
            Write-Error '-ExcludeApps is not currently supported on MacOS.'
        }

        if ($IncludeOfficeProPlus) {
            Write-Error '-OfficeProPlus is not currently supported on MacOS.'
        }

        if ($Wallpaper) {
            $MacCommand = "tell application `"System Events`" to tell current desktop to set picture to `"$Wallpaper`""
            Invoke-AppleScript -Command $MacCommand
        }
    }
    elseif ($IsLinux) {
        ### Linux (GNOME) ###
        if (-not (Get-Command -Name 'gsettings' -ErrorAction SilentlyContinue)) {
            Throw 'Lumos only currently supports Linux via GNOME (using gsettings), which was not found on this system.'
        }

        if ($Lumos -eq 'Undefined') {
            # No -Dark/-Light/-Auto specified: toggle to whichever theme isn't currently active
            $CurrentColorScheme = (Invoke-GSettings -Arguments @('get', 'org.gnome.desktop.interface', 'color-scheme')) -replace "['\r\n]"
            $Lumos = if ($CurrentColorScheme -eq 'prefer-dark') { 1 } else { 0 }
            $Status = if ($Lumos -eq 1) { 'Light' } else { 'Dark' }
        }

        $ColorScheme = if ($Lumos -eq 0) { 'prefer-dark' } else { 'prefer-light' }

        Write-Verbose "Setting GNOME color-scheme to $ColorScheme.."
        Invoke-GSettings -Arguments @('set', 'org.gnome.desktop.interface', 'color-scheme', $ColorScheme)

        if ($ExcludeSystem) {
            Write-Error '-ExcludeSystem is not currently supported on Linux.'
        }

        if ($ExcludeApps) {
            Write-Error '-ExcludeApps is not currently supported on Linux.'
        }

        if ($IncludeOfficeProPlus) {
            Write-Error '-IncludeOfficeProPlus is not currently supported on Linux.'
        }

        if ($Wallpaper) {
            $WallpaperPath = if ([System.IO.Path]::IsPathRooted($Wallpaper)) { $Wallpaper } else { Join-Path -Path (Get-Location) -ChildPath $Wallpaper }
            $WallpaperSegments = $WallpaperPath.TrimStart('/') -split '/' | ForEach-Object { [uri]::EscapeDataString($_) }
            $WallpaperUri = 'file:///' + ($WallpaperSegments -join '/')
            $PictureUriKey = if ($Lumos -eq 0) { 'picture-uri-dark' } else { 'picture-uri' }
            Invoke-GSettings -Arguments @('set', 'org.gnome.desktop.background', $PictureUriKey, $WallpaperUri)
        }
    }
    else {
        ### Windows ###
        $ThemeRegKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        $OfficeThemeRegKey = 'HKCU:\Software\Microsoft\Office\16.0\Common'

        $CurrentSystemTheme = (Get-ItemProperty -Path $ThemeRegKey -Name 'SystemUsesLightTheme' -ErrorAction SilentlyContinue).SystemUsesLightTheme

        if ($Lumos -eq 'Undefined') {
            # No -Dark/-Light/-Auto specified: toggle to whichever theme isn't currently active
            $Lumos = [int](-not [bool]$CurrentSystemTheme)
            $Status = if ($Lumos -eq 1) { 'Light' } else { 'Dark' }
        }

        if (-not $ExcludeSystem) {
            if ($CurrentSystemTheme -ne $Lumos) {
                Write-Verbose "Setting System to $Status Theme.."
                Set-ItemProperty -Path $ThemeRegKey -Name 'SystemUsesLightTheme' -Value $Lumos
            }

            # Restart Explorer to apply the theme change to the taskbar, or broadcast a WM_SETTINGCHANGE message if not restarting Explorer.
            if ($RestartExplorer) {
                Write-Verbose 'Restarting Explorer to apply the theme change to the taskbar..'
                Stop-Process -ProcessName explorer
            }
            elseif ($CurrentSystemTheme -ne $Lumos) {
                Write-Verbose 'Broadcasting a WM_SETTINGCHANGE message to apply the theme change to the taskbar..'
                Send-SettingChangeMessage
            }
        }
        if (-not $ExcludeApps) {
            $CurrentAppsTheme = (Get-ItemProperty -Path $ThemeRegKey -Name 'AppsUseLightTheme' -ErrorAction SilentlyContinue).AppsUseLightTheme

            if ($CurrentAppsTheme -ne $Lumos) {
                Write-Verbose "Setting Apps to $Status Theme.."
                Set-ItemProperty -Path $ThemeRegKey -Name 'AppsUseLightTheme' -Value $Lumos
            }
        }

        if ($IncludeOfficeProPlus) {
            $proPlusThemeValue = if ($Lumos -eq 0) {
                4
            } else {
                if (Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\O365ProPlusRetail*") {
                    5
                } else {
                    0
                }
            }

            Write-Verbose "Setting OfficeProPlus to $Status with value: $proPlusThemeValue .."

            Set-ItemProperty -Path $OfficeThemeRegKey -Name 'UI Theme' -Value $proPlusThemeValue -Type DWORD

            $IdentitiesRegKey = $OfficeThemeRegKey + "\Roaming\Identities\"

            if (Test-Path $IdentitiesRegKey) {
                Get-ChildItem -Path $IdentitiesRegKey | ForEach-Object {
                    $identityPath = ($_.Name.Replace('HKEY_CURRENT_USER', 'HKCU:') + "\Settings\1186\{00000000-0000-0000-0000-000000000000}");

                    if (Get-ItemProperty -Path $identityPath -Name 'Data' -ErrorAction Ignore) {
                        Write-Verbose "Active identity path for ProPlus installation: $identityPath"

                        Set-ItemProperty -Path $identityPath -Name 'Data' -Value ([byte[]]($proPlusThemeValue, 0, 0, 0)) -Type Binary
                    }
                    Break
                }
            }
        }

        if ($Wallpaper) {
            Set-Wallpaper $Wallpaper
        }
    }
}

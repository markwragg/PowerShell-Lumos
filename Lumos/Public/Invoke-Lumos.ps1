Function Invoke-Lumos {
    <#
        .SYNOPSIS
            Sets the Windows or Mac Theme to light or dark mode dependent on time of day.

        .DESCRIPTION
            Use this cmdlet to change the theme on Windows 10 or MacOS Mojave to the light of dark themes,
            either as specified by parameters or (for Windows only), automatically based on the local time
            of day and whether it is before or after sunrise/sunset.
        
        .PARAMETER Dark
            Switch to the Dark OS theme.

        .PARAMETER Light
            Switch to the Light OS theme.

        .PARAMETER ExcludeSystem
            Exclude changing the System theme when switching to Dark/Light (Windows only).

        .PARAMETER IncludeOfficeProPlus
            Include changing the theme of Microsoft Office to Dark/Light (Windows only).

        .PARAMETER ExcludeApps
            Exclude changing the Applications (where supported) theme when switching to Dark/Light (Windows only).

        .PARAMETER DarkWallpaper
            Specify a path to use to modify the Desktop Wallpaper to when switching to the Dark theme.

        .PARAMETER LightWallpaper
            Specify a path to use to modify the Desktop Wallpaper to when switching to the Light theme.

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

        .Example
            Invoke-Lumos

            On Windows: Switches to either Dark or Light theme dependent on your current location/time of day.
            On MacOS: Switches current theme from either Light to Dark or Dark to Light.
    #>
    [cmdletbinding(DefaultParameterSetName = 'Dark')]
    Param(
        [Parameter(ParameterSetName = 'Dark')]
        [switch]
        $Dark,

        [Parameter(ParameterSetName = 'Light')]
        [switch]
        $Light,

        [switch]
        $ExcludeSystem,

        [switch]
        $IncludeOfficeProPlus,

        [switch]
        $ExcludeApps,

        [string]
        $DarkWallpaper,

        [string]
        $LightWallpaper
    )

    if ($Dark) {
        $Lumos = 0
    }
    elseif ($Light) {
        $Lumos = 1
    }
    elseif ($IsMacOS) {
        ### MacOS ###

        # Leaving Lumos as undefined on MacOS will make it just alternate to whatever mode it currently is not
        $Lumos = 'Undefined'
    }
    else {
        ### Windows ###
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
        $MacCommand = if ($Lumos -eq 0) {
            'tell application \"System Events\" to tell appearance preferences to set dark mode to true'
        }
        elseif ($Lumos -eq 1) {
            'tell application \"System Events\" to tell appearance preferences to set dark mode to false'
        }
        else {
            'tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode'
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
            $MacCommand = "tell application \`"System Events\`" to tell current desktop to set picture to \`"$Wallpaper\`""
            Invoke-AppleScript -Command $MacCommand
        }
    }
    elseif ($IsLinux) {
        ### Linux ###
        Throw 'Linux is not currently supported by this module.'
    }
    else {
        ### Windows ###
        $ThemeRegKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'
        $OfficeThemeRegKey = 'HKCU:\Software\Microsoft\Office\16.0\Common'

        if (-not $ExcludeSystem) {
            Write-Verbose "Setting System to $Status Theme.."
            Set-ItemProperty -Path $ThemeRegKey -Name 'SystemUsesLightTheme' -Value $Lumos
        }
        if (-not $ExcludeApps) {
            Write-Verbose "Setting Apps to $Status Theme.."
            Set-ItemProperty -Path $ThemeRegKey -Name 'AppsUseLightTheme' -Value $Lumos
        }

        if ($IncludeOfficeProPlus) {
            $proPlusThemeValue = if ($Lumos -eq 0) { 4 } else { 0 }

            Write-Verbose "Setting OfficeProPlus to $Status with value: $proPlusThemeValue .."

            Set-ItemProperty -Path $OfficeThemeRegKey -Name 'UI Theme' -Value $proPlusThemeValue -Type DWORD

            Get-ChildItem -Path ($OfficeThemeRegKey + "\Roaming\Identities\") | ForEach-Object {
                $identityPath = ($_.Name.Replace('HKEY_CURRENT_USER', 'HKCU:') + "\Settings\1186\{00000000-0000-0000-0000-000000000000}");

                if (Get-ItemProperty -Path $identityPath -Name 'Data' -ErrorAction Ignore) {
                    Write-Verbose 'Active identity path for ProPlus installation: ' $identityPath

                    Set-ItemProperty -Path $identityPath -Name 'Data' -Value ([byte[]]($proPlusThemeValue, 0, 0, 0)) -Type Binary
                }
            }
        }

        if ($Wallpaper) {
            Set-Wallpaper $Wallpaper
        }
    }
}

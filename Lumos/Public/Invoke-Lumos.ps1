Function Invoke-Lumos {
    <#
        .SYNOPSIS
            Sets the Windows Theme to light or dark mode dependent on time of day.
    #>      
    [cmdletbinding(DefaultParameterSetName='Dark')]
    Param(
        [Parameter(ParameterSetName='Dark')]    
        [switch]
        $Dark,

        [Parameter(ParameterSetName='Light')]
        [switch]
        $Light,

        [switch]
        $ExcludeSystem,

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
    else {
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

    # Set theme
    $ThemeRegKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'

    if (-not $ExcludeSystem) {
        Write-Verbose "Setting System to $Status Theme.."
        Set-ItemProperty -Path $ThemeRegKey -Name 'SystemUsesLightTheme' -Value $Lumos
        
    }
    if (-not $ExcludeApps) {
        Write-Verbose "Setting Apps to $Status Theme.."
        Set-ItemProperty -Path $ThemeRegKey -Name 'AppsUseLightTheme' -Value $Lumos
    }

    if ($Wallpaper) {
        Set-Wallpaper $Wallpaper
    }
}
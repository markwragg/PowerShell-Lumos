Function Invoke-Lumos {
    <#
        .SYNOPSIS
            Sets the Windows Theme to light or dark mode dependent on time of day.
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

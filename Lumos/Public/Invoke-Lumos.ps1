Function Invoke-Lumos {
    <#
        .SYNOPSIS
            Sets the Windows Theme to light or dark mode dependent on time of day.
    #>      
    [cmdletbinding()]
    Param()

    $CurrentTime = Get-Date
    $UserLocation = Get-UserLocation

    if ($UserLocation) {
        $DayLight = Get-LocalDaylight -Latitude $UserLocation.Latitude -Longitude $UserLocation.Longitude
    }
    else {
        Throw 'Could not get sunrise/sunset data for the current user.'
    }
    
    # Set theme
    $ThemeRegKey = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize'

    if ($CurrentTime -gt $DayLight.Sunrise -and $CurrentTime -lt $DayLight.Sunset) {
        Set-ItemProperty -Path $ThemeRegKey -Name 'SystemUsesLightTheme' -Value 1
        Set-ItemProperty -Path $ThemeRegKey -Name 'AppsUseLightTheme' -Value 1
        Write-Verbose 'Theme set to light.'
    }
    else {
        Set-ItemProperty -Path $ThemeRegKey -Name 'SystemUsesLightTheme' -Value 0
        Set-ItemProperty -Path $ThemeRegKey -Name 'AppsUseLightTheme' -Value 0
        Write-Verbose 'Theme set to dark.'
    }
}
[cmdletbinding()]
Param()

$VerbosePreference = 'Continue'

# Get location of user
Add-Type -AssemblyName System.Device 

$GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
$GeoWatcher.Start()

while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
    Start-Sleep -Milliseconds 100 
}  

if ($GeoWatcher.Permission -eq 'Denied') {
    Write-Error 'Access Denied for Location Information'
}
else {    
    $Lat = $GeoWatcher.Position.Location.Latitude
    $Lng = $GeoWatcher.Position.Location.Longitude
}

# Return sunrise/sunset
$Daytime = (invoke-restmethod "https://api.sunrise-sunset.org/json?lat=$Lat&lng=$Lng").results

# Convert to local time
$Sunrise = ($Daytime.Sunrise | Get-Date).ToLocalTime()
$Sunset = ($Daytime.Sunset | Get-Date).ToLocalTime()

$CurrentTime = Get-Date

# Set theme
if ($CurrentTime -gt $Sunrise -and $CurrentTime -lt $Sunset) {
    Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name 'SystemUsesLightTheme' -Value 1
    Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name 'AppsUseLightTheme' -Value 1
    Write-Verbose 'Theme set to light.'
}
else {
    Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name 'SystemUsesLightTheme' -Value 0
    Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name 'AppsUseLightTheme' -Value 0
    Write-Verbose 'Theme set to dark.'
}



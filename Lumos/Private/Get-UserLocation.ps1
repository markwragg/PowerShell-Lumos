Function Get-UserLocation {
    <#
        .SYNOPSIS
            Returns the approximate location of the local user, based on their public IP address.

        .DESCRIPTION
            Looks up the city-level location of the current public IP address via the ipinfo.io API. This is used
            instead of the Windows Location Service because that requires location permission to be granted
            interactively and is typically unavailable when this module is run from a Scheduled Task.

        .EXAMPLE
            Get-UserLocation

            Result
            -----------
            Latitude  : 51.5074
            Longitude : -0.1278
    #>
    [cmdletbinding()]
    Param()

    $IPInfo = Invoke-RestMethod -Uri 'https://ipinfo.io/json'

    if ($IPInfo.loc) {
        $Latitude, $Longitude = $IPInfo.loc -split ','

        [pscustomobject]@{
            Latitude  = [double]$Latitude
            Longitude = [double]$Longitude
        }
    }
}
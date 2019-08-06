Function Get-UserLocation {
    <#
        .SYNOPSIS
            Returns the location information for the local user.

        .EXAMPLE
            Get-UserLocation

            Result
            -----------
            Latitude           : 123.281781267745  
            Longitude          : 456.05927473888778
            Altitude           : 0
            HorizontalAccuracy : 82
            VerticalAccuracy   : NaN
            Speed              : NaN
            Course             : NaN
            IsUnknown          : False
    #>      
    [cmdletbinding()]
    Param()

    Add-Type -AssemblyName System.Device 

    $GeoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
    $GeoWatcher.Start()

    while (($GeoWatcher.Status -ne 'Ready') -and ($GeoWatcher.Permission -ne 'Denied')) {
        Start-Sleep -Milliseconds 100 
    }  

    if ($GeoWatcher.Permission -eq 'Denied') {
        Throw 'Access was denied to user location information'
    }
    else {
        $GeoWatcher.Position.Location
    }
}
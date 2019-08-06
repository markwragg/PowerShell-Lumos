Function Get-LocalDaylight {
    <#
        .SYNOPSIS
            Returns the current sunrise and sunset times for the local user in localtime.

        .EXAMPLE
            Get-LocalDaylight

            Result
            -----------            
            Sunrise : 06/08/2019 06:04:57
            Sunset  : 06/08/2019 20:22:17
            
    #>      
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory)]
        [double]
        $Latitude,

        [Parameter(Mandatory)]
        [double]
        $Longitude
    )

    # Return sunrise/sunset
    $Daylight = (invoke-restmethod "https://api.sunrise-sunset.org/json?lat=$Latitude&lng=$Longitude").results

    # Convert to local time datetime objects
    [pscustomobject]@{
        Sunrise = ($Daylight.Sunrise | Get-Date).ToLocalTime()
        Sunset  = ($Daylight.Sunset | Get-Date).ToLocalTime()
    }
}
Function Update-LumosScheduledTask {
    <#
        .SYNOPSIS
            Updates the run times for the Lumus Scheduled Task with the current sunrise/sunset values.
    #>      
    [cmdletbinding(DefaultParameterSetName='Dark')]
    Param()

    $UserLocation = Get-UserLocation

    if ($UserLocation) {
        $DayLight = Get-LocalDaylight -Latitude $UserLocation.Latitude -Longitude $UserLocation.Longitude
    }
    else {
        Throw 'Could not get sunrise/sunset data for the current user.'
    }

    $SunriseTrigger = New-ScheduledTaskTrigger -At $DayLight.Sunrise -Daily
    $SunsetTrigger = New-ScheduledTaskTrigger -At $DayLight.Sunset -Daily
    $LogonTrigger = New-ScheduledTaskTrigger -AtLogOn

    Set-ScheduledTask -TaskName 'Lumos' -Trigger  $LogonTrigger,$SunriseTrigger,$SunsetTrigger
}
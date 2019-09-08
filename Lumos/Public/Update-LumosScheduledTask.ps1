Function Update-LumosScheduledTask {
    <#
        .SYNOPSIS
            Updates the run times for the Lumus Scheduled Task with the current sunrise/sunset values.

        .DESCRIPTION
            This cmdlet is called by Register-LumosScheduledTask to add the appropriate triggers to the task for sunrise
            and sunset. Register-LumosScheduled task also schedules it to run as an additional action of the Lumos task
            so that the trigger times for the task are updated as the sunrise and sunset times change through the year.

        .EXAMPLE
            Update-LumosScheduledTask

            Windows Only: Retrieves the current logged on users geolocation from the OS then retrieves the local sunrise
            and sunset times for the user via an API call. It then modifies the Scheduled Task named 'Lumos' with these triggers
            as well as adds a trigger to run it on logon.
    #>      
    [cmdletbinding(SupportsShouldProcess)]
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

    if ($PSCmdlet.ShouldProcess('Update Lumos Scheduled Task')){
        Set-ScheduledTask -TaskName 'Lumos' -Trigger  $LogonTrigger,$SunriseTrigger,$SunsetTrigger
        Stop-Process -ProcessName explorer
    }
}
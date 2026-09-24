Function Update-LumosScheduledTask {
    <#
        .SYNOPSIS
            Updates the "Lumos" scheduled task's sunrise/sunset trigger times to match today.

        .DESCRIPTION
            Recomputes the current sunrise/sunset for the local user and updates the "Lumos" scheduled task's
            two daily triggers to match, so they stay aligned with sunrise/sunset as they drift through the
            year. The task's existing action, principal and settings are read back and reused as-is, so only
            the triggers actually change - but rather than modifying the task in place, it's unregistered and
            re-registered with those same values plus the new triggers.

            This is intended to be run automatically, once weekly, by the "Lumos-Maintenance" scheduled task
            that Register-LumosScheduledTask creates alongside the "Lumos" task itself - not normally called
            directly. It's registered as a separate task, run at a time unlikely to overlap with "Lumos"
            actually running, because Windows Task Scheduler won't let a task modify its own definition while
            it's the active running instance.

        .EXAMPLE
            Update-LumosScheduledTask

            Updates the "Lumos" scheduled task's triggers to today's sunrise/sunset for the current location.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    Param()

    if (-not ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows)) {
        Write-Warning 'Update-LumosScheduledTask is only supported on Windows.'
        return
    }

    $LumosTask = Get-ScheduledTask -TaskName 'Lumos' -ErrorAction SilentlyContinue

    if (-not $LumosTask) {
        Write-Warning "No 'Lumos' scheduled task was found. Run Register-LumosScheduledTask first."
        return
    }

    $UserLocation = Get-UserLocation

    if (-not $UserLocation) {
        Write-Error 'Could not get sunrise/sunset data for the current user.'
        return
    }

    $DayLight = Get-LocalDaylight -Latitude $UserLocation.Latitude -Longitude $UserLocation.Longitude

    $SunriseTrigger = New-ScheduledTaskTrigger -Daily -At $DayLight.Sunrise
    $SunsetTrigger = New-ScheduledTaskTrigger -Daily -At $DayLight.Sunset

    # Rebuilds the task from its own existing Action/Principal/Settings (reused as-is) plus the new
    # triggers, then unregisters and re-registers it, rather than modifying it in place with
    # Set-ScheduledTask - delete-and-recreate uses the same Register-ScheduledTask call already proven to
    # work in Register-LumosScheduledTask, in case Set-ScheduledTask specifically is what's unreliable here.
    $NewTaskDefinition = New-ScheduledTask -Action $LumosTask.Actions -Principal $LumosTask.Principal `
        -Settings $LumosTask.Settings -Trigger @($SunriseTrigger, $SunsetTrigger)

    if ($PSCmdlet.ShouldProcess('Lumos scheduled task', 'Recreate with updated sunrise/sunset triggers')) {
        Unregister-ScheduledTask -TaskName 'Lumos' -Confirm:$false
        Register-ScheduledTask -TaskName 'Lumos' -InputObject $NewTaskDefinition | Out-Null
    }
}

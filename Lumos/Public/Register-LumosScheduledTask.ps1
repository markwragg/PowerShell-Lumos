Function Register-LumosScheduledTask {
    <#
        .SYNOPSIS
            Registers Scheduled Tasks to run Lumos automatically on Windows.

         .DESCRIPTION
            Use this cmdlet to register a "Lumos" scheduled task on Windows that runs Invoke-Lumos (with your
            specified parameters) twice daily, at the current sunrise and sunset for your location.

            Since sunrise/sunset drift through the year, this also registers a second "Lumos-Maintenance" task
            that runs once weekly, at solar noon (the point furthest from both sunrise and sunset) on whichever
            day of the week this cmdlet was run, and whose only job is to recompute the current sunrise/sunset
            and update the "Lumos" task's trigger times to match via Update-LumosScheduledTask - weekly is
            frequent enough to keep the triggers close to sunrise/sunset without needing daily API calls to
            determine location and daylight times. Keeping this in a separate task - rather than as a second
            action of the "Lumos" task itself, as an earlier version of this module did - matters: Windows
            Task Scheduler won't let a task modify its own definition while it's the active running instance,
            which is what made that earlier approach throw "Access is denied" and lose its triggers entirely.
            Running the update from a genuinely different task, at a time unlikely to overlap with "Lumos"
            actually running, avoids that.

            If you'd rather not rely on the automatic sunrise/sunset lookup (or don't want Lumos calling out to
            it at all), specify -Sunrise and -Sunset yourself to use fixed daily trigger times instead, or use
            -FromNightLight to reuse whichever schedule Windows' own Night Light feature is currently
            configured with. Since neither of those need to be kept current with the season the way an
            automatic lookup does, the "Lumos-Maintenance" task isn't registered in either case - re-run this
            cmdlet if the Night Light schedule you're reusing later changes.

            Both tasks run as the current user at standard (non-elevated) privilege - Lumos only ever changes
            current-user settings, so no administrator rights are required. Neither task has an "at logon"
            trigger, since some endpoint security software blocks non-admin users from registering one (likely
            because it's a common persistence technique).

            Returns the registered scheduled task(s), displayed with their schedule source and a summary of
            the times that were registered (e.g. to verify -FromNightLight or the automatic sunrise/sunset
            lookup picked up what you expected) - the full underlying task, including its Triggers, is still
            there to inspect if you need more detail.

        .PARAMETER Sunrise
            Specify a fixed daily time to switch to the Light theme, instead of automatically looking up the
            current sunrise for your location. Must be specified together with -Sunset. Since this time won't
            need to stay current with the season, the "Lumos-Maintenance" task is not registered.

        .PARAMETER Sunset
            Specify a fixed daily time to switch to the Dark theme, instead of automatically looking up the
            current sunset for your location. Must be specified together with -Sunrise. Since this time won't
            need to stay current with the season, the "Lumos-Maintenance" task is not registered.

        .PARAMETER FromNightLight
            Use whichever schedule Windows' own Night Light feature (Settings > System > Display > Night light)
            is currently configured with, instead of automatically looking up sunrise/sunset for your location.
            Cannot be combined with -Sunrise/-Sunset. Since this is read once at registration time (not kept in
            sync with Night Light afterwards), the "Lumos-Maintenance" task is not registered - re-run this
            cmdlet if you later change your Night Light schedule.

        .PARAMETER ExcludeSystem
            Exclude changing the System theme when switching to Dark/Light (Windows only) when the task runs.

        .PARAMETER RestartExplorer
            Restart Explorer to apply the System theme change to the taskbar when the task runs, instead of the
            default of broadcasting a WM_SETTINGCHANGE message.

        .PARAMETER IncludeOfficeProPlus
            Include changing the theme of Microsoft Office to Dark/Light (Windows only) when the task runs.

        .PARAMETER ExcludeApps
            Exclude changing the Applications (where supported) theme when switching to Dark/Light (Windows only) when the task runs.

        .PARAMETER DarkWallpaper
            Specify a path to use to modify the Desktop Wallpaper to when the task runs and switches to the Dark theme.

        .PARAMETER LightWallpaper
            Specify a path to use to modify the Desktop Wallpaper to when the task runs and switches to the Light theme.

        .EXAMPLE
            Register-LumosScheduledTask -ExcludeApps -DarkWallpaper C:\Temp\dark.png -LightWallpaper C:\Temp\light.png

            Creates scheduled tasks that switch just the OS theme to dark or light at the current local sunrise
            and sunset, along with the specified light or dark wallpaper, keeping the trigger times themselves
            up to date with sunrise/sunset as they change through the year.

        .EXAMPLE
            Register-LumosScheduledTask -Sunrise '07:00' -Sunset '19:00'

            Creates a "Lumos" scheduled task that switches to the Light theme at 07:00 and the Dark theme at
            19:00 every day, without looking up your location or registering a "Lumos-Maintenance" task.

        .EXAMPLE
            Register-LumosScheduledTask -FromNightLight

            Creates a "Lumos" scheduled task using whichever schedule Windows' own Night Light feature is
            currently configured with, without looking up your location or registering a "Lumos-Maintenance"
            task.
    #>
    [cmdletbinding()]
    [OutputType([Microsoft.Management.Infrastructure.CimInstance])]
    Param(
        [datetime]
        $Sunrise,

        [datetime]
        $Sunset,

        [switch]
        $FromNightLight,

        [switch]
        $ExcludeSystem,

        [switch]
        $RestartExplorer,

        [switch]
        $ExcludeApps,

        [switch]
        $IncludeOfficeProPlus,

        [string]
        $DarkWallpaper,

        [string]
        $LightWallpaper
    )

    if (-not ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows)) {
        Write-Warning 'Register-LumosScheduledTask is only supported on Windows.'
        return
    }

    if (($Sunrise -and -not $Sunset) -or ($Sunset -and -not $Sunrise)) {
        throw '-Sunrise and -Sunset must both be specified together.'
    }

    if ($FromNightLight -and ($Sunrise -or $Sunset)) {
        throw '-FromNightLight cannot be combined with -Sunrise/-Sunset.'
    }

    # Runs the task using whichever PowerShell edition is currently running this cmdlet, since that's the
    # edition Lumos is guaranteed to be installed under - PS Core and Windows PowerShell have separate
    # module paths, so hardcoding the other edition's executable would fail to find Invoke-Lumos. $PSHOME
    # is the home directory of the CURRENT session, so this resolves to an exact, unambiguous full path
    # rather than relying on whatever "powershell.exe"/"pwsh.exe" happens to resolve to on PATH.
    $PowerShellExe = if ($PSVersionTable.PSEdition -eq 'Core') {
        Join-Path -Path $PSHOME -ChildPath 'pwsh.exe'
    }
    else {
        Join-Path -Path $PSHOME -ChildPath 'powershell.exe'
    }

    # -WindowStyle Hidden keeps the task running silently in the background with no visible console window.
    $ArgumentDefaults = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden'

    # -NoProfile means the task's fresh PowerShell process has to discover Lumos via module auto-loading,
    # which depends on $env:PSModulePath being set up the same way in that process as it is interactively -
    # not guaranteed for a process spawned by Task Scheduler rather than typed at a prompt. Importing from
    # this exact, already-loaded module's own path sidesteps auto-loading entirely.
    $ModulePath = (Get-Module -Name 'Lumos').Path
    $ImportModuleCommand = "Import-Module '$ModulePath' -Force; "

    $LumosArgument = "$ArgumentDefaults -Command ${ImportModuleCommand}Invoke-Lumos"

    If ($ExcludeSystem) {
        $LumosArgument = $LumosArgument + " -ExcludeSystem"
    }
    If ($RestartExplorer) {
        $LumosArgument = $LumosArgument + " -RestartExplorer"
    }
    If ($ExcludeApps) {
        $LumosArgument = $LumosArgument + " -ExcludeApps"
    }
    If ($IncludeOfficeProPlus) {
        $LumosArgument = $LumosArgument + " -IncludeOfficeProPlus"
    }
    If ($LightWallpaper) {
        $LumosArgument = $LumosArgument + " -LightWallpaper '$LightWallpaper'"
    }
    If ($DarkWallpaper) {
        $LumosArgument = $LumosArgument + " -DarkWallpaper '$DarkWallpaper'"
    }

    # A user-specified -Sunrise/-Sunset pair, or -FromNightLight, is used as-is, skipping the location/daylight
    # lookup entirely - since neither of those drift with the season the way an automatic lookup's result
    # does, the "Lumos-Maintenance" task isn't needed either.
    $UseCustomDaylight = ($Sunrise -and $Sunset) -or $FromNightLight

    if ($FromNightLight) {
        $DayLight = Get-NightLightSchedule
        $ScheduleSource = 'Night Light'
    }
    elseif ($UseCustomDaylight) {
        $DayLight = [pscustomobject]@{ Sunrise = $Sunrise; Sunset = $Sunset }
        $ScheduleSource = 'Custom'
    }
    else {
        $UserLocation = Get-UserLocation

        if (-not $UserLocation) {
            throw 'Could not get sunrise/sunset data for the current user.'
        }

        $DayLight = Get-LocalDaylight -Latitude $UserLocation.Latitude -Longitude $UserLocation.Longitude
        $ScheduleSource = 'Location'
    }

    $LumosAction = New-ScheduledTaskAction -Execute $PowerShellExe -Argument $LumosArgument
    $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    $TaskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable

    $SunriseTrigger = New-ScheduledTaskTrigger -Daily -At $DayLight.Sunrise
    $SunsetTrigger = New-ScheduledTaskTrigger -Daily -At $DayLight.Sunset

    $LumosTask = New-ScheduledTask -Action $LumosAction -Principal $Principal -Settings $TaskSettings -Trigger @($SunriseTrigger, $SunsetTrigger) |
        Register-ScheduledTask -TaskName 'Lumos' -Force

    # Inserting a custom type name (rather than replacing it) lets the Lumos.Format.ps1xml view below add a
    # Source/Schedule summary to how this displays, without losing anything Register-ScheduledTask's own
    # MSFT_ScheduledTask type gives it (e.g. so Unregister-ScheduledTask -InputObject $task still works).
    $LumosTask.PSObject.TypeNames.Insert(0, 'Lumos.ScheduledTask')
    Add-Member -InputObject $LumosTask -NotePropertyName 'ScheduleSource' -NotePropertyValue $ScheduleSource
    Add-Member -InputObject $LumosTask -NotePropertyName 'Schedule' -NotePropertyValue (
        "Light $($DayLight.Sunrise.ToString('HH:mm')), Dark $($DayLight.Sunset.ToString('HH:mm'))"
    )

    if ($UseCustomDaylight) {
        return $LumosTask
    }

    $MaintenanceArgument = "$ArgumentDefaults -Command ${ImportModuleCommand}Update-LumosScheduledTask"
    $MaintenanceAction = New-ScheduledTaskAction -Execute $PowerShellExe -Argument $MaintenanceArgument
    $MaintenancePrincipal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    $MaintenanceSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable

    # Runs weekly (on whichever day this cmdlet happens to be run) at solar noon: the point in the day
    # furthest from both the sunrise and sunset triggers above, to minimize any chance of
    # Update-LumosScheduledTask trying to modify the "Lumos" task while it's running. Weekly is frequent
    # enough to keep the sunrise/sunset triggers reasonably current without a daily API call.
    $SolarNoon = $DayLight.Sunrise.AddSeconds(($DayLight.Sunset - $DayLight.Sunrise).TotalSeconds / 2)
    $MaintenanceTrigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek (Get-Date).DayOfWeek -At $SolarNoon

    $MaintenanceTask = New-ScheduledTask -Action $MaintenanceAction -Principal $MaintenancePrincipal -Settings $MaintenanceSettings -Trigger $MaintenanceTrigger |
        Register-ScheduledTask -TaskName 'Lumos-Maintenance' -Force

    $MaintenanceTask.PSObject.TypeNames.Insert(0, 'Lumos.ScheduledTask')
    Add-Member -InputObject $MaintenanceTask -NotePropertyName 'ScheduleSource' -NotePropertyValue $ScheduleSource
    Add-Member -InputObject $MaintenanceTask -NotePropertyName 'Schedule' -NotePropertyValue (
        "Weekly $((Get-Date).DayOfWeek) $($SolarNoon.ToString('HH:mm'))"
    )

    $LumosTask, $MaintenanceTask
}

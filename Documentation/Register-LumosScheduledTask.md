# Register-LumosScheduledTask

## SYNOPSIS
Registers Scheduled Tasks to run Lumos automatically on Windows.

## SYNTAX

```
Register-LumosScheduledTask [[-Sunrise] <DateTime>] [[-Sunset] <DateTime>] [-FromNightLight] [-ExcludeSystem]
 [-RestartExplorer] [-ExcludeApps] [-IncludeOfficeProPlus] [[-DarkWallpaper] <String>]
 [[-LightWallpaper] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Use this cmdlet to register a "Lumos" scheduled task on Windows that runs Invoke-Lumos (with your
specified parameters) twice daily, at the current sunrise and sunset for your location.

Since sunrise/sunset drift through the year, this also registers a second "Lumos-Maintenance" task
that runs once weekly, at solar noon (the point furthest from both sunrise and sunset) on whichever
day of the week this cmdlet was run, and whose only job is to recompute the current sunrise/sunset
and update the "Lumos" task's trigger times to match via Update-LumosScheduledTask - weekly is
frequent enough to keep the triggers close to sunrise/sunset without needing daily API calls to
determine location and daylight times.
Keeping this in a separate task - rather than as a second
action of the "Lumos" task itself, as an earlier version of this module did - matters: Windows
Task Scheduler won't let a task modify its own definition while it's the active running instance,
which is what made that earlier approach throw "Access is denied" and lose its triggers entirely.
Running the update from a genuinely different task, at a time unlikely to overlap with "Lumos"
actually running, avoids that.

If you'd rather not rely on the automatic sunrise/sunset lookup (or don't want Lumos calling out to
it at all), specify -Sunrise and -Sunset yourself to use fixed daily trigger times instead, or use
-FromNightLight to reuse whichever schedule Windows' own Night Light feature is currently
configured with.
Since neither of those need to be kept current with the season the way an
automatic lookup does, the "Lumos-Maintenance" task isn't registered in either case - re-run this
cmdlet if the Night Light schedule you're reusing later changes.
If a "Lumos-Maintenance" task was
already registered from a previous run (e.g.
you're switching from the automatic lookup to a fixed
schedule), it's removed, since it would otherwise keep overwriting your fixed times weekly.

Both tasks run as the current user at standard (non-elevated) privilege - Lumos only ever changes
current-user settings, so no administrator rights are required.
Neither task has an "at logon"
trigger, since some endpoint security software blocks non-admin users from registering one (likely
because it's a common persistence technique).

Returns the registered scheduled task(s), displayed with their schedule source and a summary of
the times that were registered (e.g.
to verify -FromNightLight or the automatic sunrise/sunset
lookup picked up what you expected) - the full underlying task, including its Triggers, is still
there to inspect if you need more detail.

If PowerShell 7 is installed from the Microsoft Store, its exact path changes with every update
(it lives in a version-specific folder under WindowsApps), which would otherwise leave the
registered task pointing at a pwsh.exe that no longer exists after the next update.
In that case
this instead points the task at Windows' own stable app-execution-alias for pwsh.exe, which
Windows keeps up to date across Store updates - so re-running this cmdlet after updating
PowerShell shouldn't be necessary.
This doesn't apply to Windows PowerShell or a traditionally
installed PowerShell 7, both of which already have a stable path.

## EXAMPLES

### EXAMPLE 1
```
Register-LumosScheduledTask -ExcludeApps -DarkWallpaper C:\Temp\dark.png -LightWallpaper C:\Temp\light.png
```

Creates scheduled tasks that switch just the OS theme to dark or light at the current local sunrise
and sunset, along with the specified light or dark wallpaper, keeping the trigger times themselves
up to date with sunrise/sunset as they change through the year.

### EXAMPLE 2
```
Register-LumosScheduledTask -Sunrise '07:00' -Sunset '19:00'
```

Creates a "Lumos" scheduled task that switches to the Light theme at 07:00 and the Dark theme at
19:00 every day, without looking up your location or registering a "Lumos-Maintenance" task.

### EXAMPLE 3
```
Register-LumosScheduledTask -FromNightLight
```

Creates a "Lumos" scheduled task using whichever schedule Windows' own Night Light feature is
currently configured with, without looking up your location or registering a "Lumos-Maintenance"
task.

## PARAMETERS

### -Sunrise
Specify a fixed daily time to switch to the Light theme, instead of automatically looking up the
current sunrise for your location.
Must be specified together with -Sunset.
Since this time won't
need to stay current with the season, the "Lumos-Maintenance" task is not registered.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Sunset
Specify a fixed daily time to switch to the Dark theme, instead of automatically looking up the
current sunset for your location.
Must be specified together with -Sunrise.
Since this time won't
need to stay current with the season, the "Lumos-Maintenance" task is not registered.

```yaml
Type: DateTime
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -FromNightLight
Use whichever schedule Windows' own Night Light feature (Settings \> System \> Display \> Night light)
is currently configured with, instead of automatically looking up sunrise/sunset for your location.
Cannot be combined with -Sunrise/-Sunset.
Since this is read once at registration time (not kept in
sync with Night Light afterwards), the "Lumos-Maintenance" task is not registered - re-run this
cmdlet if you later change your Night Light schedule.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeSystem
Exclude changing the System theme when switching to Dark/Light (Windows only) when the task runs.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -RestartExplorer
Restart Explorer to apply the System theme change to the taskbar when the task runs, instead of the
default of broadcasting a WM_SETTINGCHANGE message.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeApps
Exclude changing the Applications (where supported) theme when switching to Dark/Light (Windows only) when the task runs.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeOfficeProPlus
Include changing the theme of Microsoft Office to Dark/Light (Windows only) when the task runs.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -DarkWallpaper
Specify a path to use to modify the Desktop Wallpaper to when the task runs and switches to the Dark theme.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LightWallpaper
Specify a path to use to modify the Desktop Wallpaper to when the task runs and switches to the Light theme.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
{{Fill ProgressAction Description}}

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Microsoft.Management.Infrastructure.CimInstance
## NOTES

## RELATED LINKS

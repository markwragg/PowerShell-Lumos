# Register-LumosScheduledTask

## SYNOPSIS
Registers a Scheduled Task to run Lumos automatically on Windows.

## SYNTAX

```
Register-LumosScheduledTask [-ExcludeSystem] [-ExcludeApps] [-IncludeOfficeProPlus] [[-DarkWallpaper] <String>]
 [[-LightWallpaper] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Use this cmdlet to register a scheduled task on Windows so that Invoke-Lumos is executed using
your specified parameters repeatedly every 15 minutes.
Invoke-Lumos looks up the current
sunrise/sunset for your location on every run and only changes anything when the theme needs to
change, so this keeps the Dark/Light switch closely aligned with sunrise and sunset without the
scheduled task itself ever needing its trigger times updated.

The task runs as the current user at standard (non-elevated) privilege - Lumos only ever changes
current-user settings, so no administrator rights are required.
Its trigger is fixed at registration
time rather than being refreshed later, since repeatedly re-registering the task to update trigger
times proved unreliable in practice.
The task deliberately has no "at logon" trigger, since some
endpoint security software blocks non-admin users from registering one (likely because it's a common
persistence technique) - the repeating trigger fires immediately on registration and again within 15
minutes of any logon, so this has little practical effect.

## EXAMPLES

### EXAMPLE 1
```
Register-LumosScheduledTask -ExcludeApps -DarkWallpaper C:\Temp\dark.png -LightWallpaper C:\Temp\light.png
```

Creates a scheduled task that runs every 15 minutes, switching just the OS theme to either dark or light
based on the current local sunrise/sunset, along with the specified light or dark wallpaper.

## PARAMETERS

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
Position: 1
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
Position: 2
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

## NOTES

## RELATED LINKS

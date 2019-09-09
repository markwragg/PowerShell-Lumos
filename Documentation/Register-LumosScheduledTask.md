# Register-LumosScheduledTask

## SYNOPSIS
Registers a Scheduled Task to run Lumos automatically on Windows.

## SYNTAX

```
Register-LumosScheduledTask [-ExcludeSystem] [-ExcludeApps] [-IncludeOfficeProPlus] [[-DarkWallpaper] <String>]
 [[-LightWallpaper] <String>] [<CommonParameters>]
```

## DESCRIPTION
Use this cmdlet to register a scheduled task on Windows so that Invoke-Lumos is executed using
your specified parameters at sunrise and sunset, or when the task is next available to run having
missed one of those scheduled times (e.g after system resumes).

## EXAMPLES

### EXAMPLE 1
```
Register-LumosScheduledTask -ExcludeApps -DarkWallpaper C:\Temp\dark.png -LightWallpaper C:\Temp\light.png
```

Creates a scheduled task that will run at the current local sunrise/sunset times and switch just the OS theme
to either dark or light, along with the specified light or dark wallpaper.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

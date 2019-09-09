# Invoke-Lumos

## SYNOPSIS
Sets the Windows or Mac Theme to light or dark mode dependent on time of day.

## SYNTAX

### Dark (Default)
```
Invoke-Lumos [-Dark] [-ExcludeSystem] [-IncludeOfficeProPlus] [-ExcludeApps] [-DarkWallpaper <String>]
 [-LightWallpaper <String>] [<CommonParameters>]
```

### Light
```
Invoke-Lumos [-Light] [-ExcludeSystem] [-IncludeOfficeProPlus] [-ExcludeApps] [-DarkWallpaper <String>]
 [-LightWallpaper <String>] [<CommonParameters>]
```

## DESCRIPTION
Use this cmdlet to change the theme on Windows 10 or MacOS Mojave to the light of dark themes,
either as specified by parameters or (for Windows only), automatically based on the local time
of day and whether it is before or after sunrise/sunset.

## EXAMPLES

### EXAMPLE 1
```
Invoke-Lumos -Dark -DarkWallpaper ./dark-wallpaper.png
```

Switches the OS theme to the Dark theme and specified Wallpaper.

### EXAMPLE 2
```
Invoke-Lumos -Light -LightWallpaper ./light-wallpaper.png
```

Swithches the OS theme to the Light theme and specified Wallpaper.

### EXAMPLE 3
```
Invoke-Lumos -Dark -ExcludeApps
```

Switches the OS theme to Dark, but (on Windows only) does not change the theme of apps that support
Dark/Light theme.

### EXAMPLE 4
```
Invoke-Lumos
```

On Windows: Switches to either Dark or Light theme dependent on your current location/time of day.
On MacOS: Switches current theme from either Light to Dark or Dark to Light.

## PARAMETERS

### -Dark
Switch to the Dark OS theme.

```yaml
Type: SwitchParameter
Parameter Sets: Dark
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Light
Switch to the Light OS theme.

```yaml
Type: SwitchParameter
Parameter Sets: Light
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeSystem
Exclude changing the System theme when switching to Dark/Light (Windows only).

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
Include changing the theme of Microsoft Office to Dark/Light (Windows only).

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
Exclude changing the Applications (where supported) theme when switching to Dark/Light (Windows only).

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
Specify a path to use to modify the Desktop Wallpaper to when switching to the Dark theme.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LightWallpaper
Specify a path to use to modify the Desktop Wallpaper to when switching to the Light theme.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

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

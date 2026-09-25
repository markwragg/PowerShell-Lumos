# Invoke-Lumos

## SYNOPSIS
Sets the Windows or Mac Theme to light or dark mode.

## SYNTAX

### Dark (Default)
```
Invoke-Lumos [-Dark] [-ExcludeSystem] [-RestartExplorer] [-IncludeOfficeProPlus] [-ExcludeApps]
 [-DarkWallpaper <String>] [-LightWallpaper <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Light
```
Invoke-Lumos [-Light] [-ExcludeSystem] [-RestartExplorer] [-IncludeOfficeProPlus] [-ExcludeApps]
 [-DarkWallpaper <String>] [-LightWallpaper <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Auto
```
Invoke-Lumos [-Auto] [-ExcludeSystem] [-RestartExplorer] [-IncludeOfficeProPlus] [-ExcludeApps]
 [-DarkWallpaper <String>] [-LightWallpaper <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Use this cmdlet to change the theme on Windows 10/11 or macOS to the light or dark theme,
either as specified by parameters, automatically based on your location and whether it is
currently before or after sunrise/sunset (-Auto), or (if none of those are specified) by
toggling to whichever theme isn't currently active.

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
Invoke-Lumos -Dark -RestartExplorer
```

Switches the OS theme to Dark and restarts Explorer (Windows only) to apply the change to the
taskbar, instead of the default of broadcasting a WM_SETTINGCHANGE message.

### EXAMPLE 5
```
Invoke-Lumos -Auto
```

Switches to either the Dark or Light theme, dependent on your current location and time of day.

### EXAMPLE 6
```
Invoke-Lumos
```

Switches the current theme to its alternate, i.e.
if it's Light it will switch to Dark and if
Dark switch to Light.

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

### -Auto
Switch to the Dark or Light OS theme automatically, based on your current location (determined
via your public IP address) and whether it is currently before or after sunrise/sunset there.

```yaml
Type: SwitchParameter
Parameter Sets: Auto
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

### -RestartExplorer
Restart Explorer to apply the System theme change (Windows only), instead of the default of
broadcasting a WM_SETTINGCHANGE/WM_THEMECHANGED message.
Use this if the taskbar still doesn't
update without it on your system, or if you want any File Explorer windows you already had open
to pick up the change too - the broadcast alone reliably updates the taskbar, but not existing
Explorer windows' own chrome.

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

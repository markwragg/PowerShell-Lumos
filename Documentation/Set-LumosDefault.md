# Set-LumosDefault

## SYNOPSIS
Sets default preferences used automatically by Invoke-Lumos, such as whether to switch the theme
automatically by default.

## SYNTAX

```
Set-LumosDefault [-Auto] [-ExcludeSystem] [-RestartExplorer] [-IncludeOfficeProPlus] [-ExcludeApps]
 [[-DarkWallpaper] <String>] [[-LightWallpaper] <String>] [-Reset] [[-DefaultsPath] <String>]
 [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
The Set-LumosDefault cmdlet saves default preferences that are then used automatically by
Invoke-Lumos, so you don't need to specify the same parameters every time.
Explicitly specifying
a parameter on Invoke-Lumos (e.g.
Invoke-Lumos -ExcludeSystem:$false) always overrides the saved
default.

Only the preferences you specify are changed -- any others already saved are left as they are.
Use -Reset to remove all saved preferences and restore the module's built-in behavior.

Supported preferences:

-Auto                 Default for -Auto on Invoke-Lumos.
-ExcludeSystem        Default for -ExcludeSystem on Invoke-Lumos.
-RestartExplorer      Default for -RestartExplorer on Invoke-Lumos.
-IncludeOfficeProPlus Default for -IncludeOfficeProPlus on Invoke-Lumos.
-ExcludeApps          Default for -ExcludeApps on Invoke-Lumos.
-DarkWallpaper        Default for -DarkWallpaper on Invoke-Lumos.
-LightWallpaper       Default for -LightWallpaper on Invoke-Lumos.

## EXAMPLES

### EXAMPLE 1
```
Set-LumosDefault -Auto
```

Makes Invoke-Lumos use -Auto by default when run with no -Dark/-Light/-Auto switch.

### EXAMPLE 2
```
Set-LumosDefault -DarkWallpaper C:\wallpaper\dark.png -LightWallpaper C:\wallpaper\light.png
```

Makes Invoke-Lumos use the specified wallpapers by default when switching to the Dark/Light theme.

### EXAMPLE 3
```
Set-LumosDefault -RestartExplorer
```

Makes Invoke-Lumos restart Explorer by default to apply the System theme change, instead of
broadcasting a WM_SETTINGCHANGE message.

### EXAMPLE 4
```
Set-LumosDefault -ExcludeSystem:$false
```

Explicitly saves -ExcludeSystem as disabled by default, overriding a previously saved value.

### EXAMPLE 5
```
Set-LumosDefault -Reset
```

Removes all saved default preferences.

## PARAMETERS

### -Auto
Sets the default for -Auto, used by Invoke-Lumos.

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
Sets the default for -ExcludeSystem, used by Invoke-Lumos.

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
Sets the default for -RestartExplorer, used by Invoke-Lumos.

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
Sets the default for -IncludeOfficeProPlus, used by Invoke-Lumos.

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
Sets the default for -ExcludeApps, used by Invoke-Lumos.

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
Sets the default Desktop Wallpaper path used by Invoke-Lumos when switching to the Dark theme.

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
Sets the default Desktop Wallpaper path used by Invoke-Lumos when switching to the Light theme.

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

### -Reset
Removes all saved default preferences, restoring the module's built-in behavior.

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

### -DefaultsPath
Path to the file used to store default preferences.
By default this is in the user's per-user
data directory (~/.lumos).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: (Get-LumosUserDataPath -FileName 'Lumos.defaults.json')
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

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

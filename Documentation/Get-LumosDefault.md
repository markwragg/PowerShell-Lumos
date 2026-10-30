# Get-LumosDefault

## SYNOPSIS
Gets the default preferences saved by Set-LumosDefault.

## SYNTAX

```
Get-LumosDefault [[-DefaultsPath] <String>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
The Get-LumosDefault cmdlet returns the default preferences currently saved by Set-LumosDefault,
such as whether -Auto is used by default on Invoke-Lumos.
Preferences that haven't been saved are
omitted - Invoke-Lumos falls back to its own built-in behavior for any preference that isn't
saved here.

## EXAMPLES

### EXAMPLE 1
```
Get-LumosDefault
```

Returns the currently saved default preferences.

## PARAMETERS

### -DefaultsPath
Path to the file used to store default preferences.
By default this is in the user's per-user
data directory (~/.lumos).

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: (Get-LumosUserDataPath -FileName 'Lumos.defaults.json')
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

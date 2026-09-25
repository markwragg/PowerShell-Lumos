# Update-LumosScheduledTask

## SYNOPSIS
Updates the "Lumos" scheduled task's sunrise/sunset trigger times to match today.

## SYNTAX

```
Update-LumosScheduledTask [-ProgressAction <ActionPreference>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Recomputes the current sunrise/sunset for the local user and updates the "Lumos" scheduled task's
two daily triggers to match, so they stay aligned with sunrise/sunset as they drift through the
year.
The task's existing action, principal and settings are read back and reused as-is, so only
the triggers actually change - but rather than modifying the task in place, it's unregistered and
re-registered with those same values plus the new triggers.

This is intended to be run automatically, once weekly, by the "Lumos-Maintenance" scheduled task
that Register-LumosScheduledTask creates alongside the "Lumos" task itself - not normally called
directly.
It's registered as a separate task, run at a time unlikely to overlap with "Lumos"
actually running, because Windows Task Scheduler won't let a task modify its own definition while
it's the active running instance.

## EXAMPLES

### EXAMPLE 1
```
Update-LumosScheduledTask
```

Updates the "Lumos" scheduled task's triggers to today's sunrise/sunset for the current location.

## PARAMETERS

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

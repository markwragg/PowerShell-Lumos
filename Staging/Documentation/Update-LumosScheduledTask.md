# Update-LumosScheduledTask

## SYNOPSIS
Updates the run times for the Lumus Scheduled Task with the current sunrise/sunset values.

## SYNTAX

```
Update-LumosScheduledTask [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
This cmdlet is called by Register-LumosScheduledTask to add the appropriate triggers to the task for sunrise
and sunset.
Register-LumosScheduled task also schedules it to run as an additional action of the Lumos task
so that the trigger times for the task are updated as the sunrise and sunset times change through the year.

## EXAMPLES

### EXAMPLE 1
```
Update-LumosScheduledTask
```

Windows Only: Retrieves the current logged on users geolocation from the OS then retrieves the local sunrise
and sunset times for the user via an API call.
It then modifies the Scheduled Task named 'Lumos' with these triggers
as well as adds a trigger to run it on logon.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

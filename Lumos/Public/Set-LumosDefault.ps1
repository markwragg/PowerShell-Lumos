Function Set-LumosDefault {
    <#
        .SYNOPSIS
            Sets default preferences used automatically by Invoke-Lumos, such as whether to switch the theme
            automatically by default.

        .DESCRIPTION
            The Set-LumosDefault cmdlet saves default preferences that are then used automatically by
            Invoke-Lumos, so you don't need to specify the same parameters every time. Explicitly specifying
            a parameter on Invoke-Lumos (e.g. Invoke-Lumos -ExcludeSystem:$false) always overrides the saved
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

        .PARAMETER Auto
            Sets the default for -Auto, used by Invoke-Lumos.

        .PARAMETER ExcludeSystem
            Sets the default for -ExcludeSystem, used by Invoke-Lumos.

        .PARAMETER RestartExplorer
            Sets the default for -RestartExplorer, used by Invoke-Lumos.

        .PARAMETER IncludeOfficeProPlus
            Sets the default for -IncludeOfficeProPlus, used by Invoke-Lumos.

        .PARAMETER ExcludeApps
            Sets the default for -ExcludeApps, used by Invoke-Lumos.

        .PARAMETER DarkWallpaper
            Sets the default Desktop Wallpaper path used by Invoke-Lumos when switching to the Dark theme.

        .PARAMETER LightWallpaper
            Sets the default Desktop Wallpaper path used by Invoke-Lumos when switching to the Light theme.

        .PARAMETER Reset
            Removes all saved default preferences, restoring the module's built-in behavior.

        .PARAMETER DefaultsPath
            Path to the file used to store default preferences. By default this is in the user's per-user
            data directory (~/.lumos).

        .EXAMPLE
            Set-LumosDefault -Auto

            Makes Invoke-Lumos use -Auto by default when run with no -Dark/-Light/-Auto switch.

        .EXAMPLE
            Set-LumosDefault -DarkWallpaper C:\wallpaper\dark.png -LightWallpaper C:\wallpaper\light.png

            Makes Invoke-Lumos use the specified wallpapers by default when switching to the Dark/Light theme.

        .EXAMPLE
            Set-LumosDefault -RestartExplorer

            Makes Invoke-Lumos restart Explorer by default to apply the System theme change, instead of
            broadcasting a WM_SETTINGCHANGE message.

        .EXAMPLE
            Set-LumosDefault -ExcludeSystem:$false

            Explicitly saves -ExcludeSystem as disabled by default, overriding a previously saved value.

        .EXAMPLE
            Set-LumosDefault -Reset

            Removes all saved default preferences.
    #>
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        # Sets the default for -Auto, used by Invoke-Lumos.
        [switch]
        $Auto,

        # Sets the default for -ExcludeSystem, used by Invoke-Lumos.
        [switch]
        $ExcludeSystem,

        # Sets the default for -RestartExplorer, used by Invoke-Lumos.
        [switch]
        $RestartExplorer,

        # Sets the default for -IncludeOfficeProPlus, used by Invoke-Lumos.
        [switch]
        $IncludeOfficeProPlus,

        # Sets the default for -ExcludeApps, used by Invoke-Lumos.
        [switch]
        $ExcludeApps,

        # Sets the default Desktop Wallpaper path used by Invoke-Lumos when switching to the Dark theme.
        [string]
        $DarkWallpaper,

        # Sets the default Desktop Wallpaper path used by Invoke-Lumos when switching to the Light theme.
        [string]
        $LightWallpaper,

        # Removes all saved default preferences, restoring the module's built-in behavior.
        [switch]
        $Reset,

        # Path to the file used to store default preferences. By default this is in the user's per-user
        # data directory (~/.lumos).
        [string]
        $DefaultsPath = (Get-LumosUserDataPath -FileName 'Lumos.defaults.json')
    )

    if ($Reset) {
        if ((Test-Path $DefaultsPath) -and $PSCmdlet.ShouldProcess($DefaultsPath, 'Remove all saved default preferences')) {
            Remove-Item $DefaultsPath -Force
        }
        return [pscustomobject]@{}
    }

    $Current = Get-LumosDefault -DefaultsPath $DefaultsPath

    if ($PSBoundParameters.ContainsKey('Auto')) { $Current | Add-Member -NotePropertyName Auto -NotePropertyValue ([bool]$Auto) -Force }
    if ($PSBoundParameters.ContainsKey('ExcludeSystem')) { $Current | Add-Member -NotePropertyName ExcludeSystem -NotePropertyValue ([bool]$ExcludeSystem) -Force }
    if ($PSBoundParameters.ContainsKey('RestartExplorer')) { $Current | Add-Member -NotePropertyName RestartExplorer -NotePropertyValue ([bool]$RestartExplorer) -Force }
    if ($PSBoundParameters.ContainsKey('IncludeOfficeProPlus')) { $Current | Add-Member -NotePropertyName IncludeOfficeProPlus -NotePropertyValue ([bool]$IncludeOfficeProPlus) -Force }
    if ($PSBoundParameters.ContainsKey('ExcludeApps')) { $Current | Add-Member -NotePropertyName ExcludeApps -NotePropertyValue ([bool]$ExcludeApps) -Force }
    if ($PSBoundParameters.ContainsKey('DarkWallpaper')) { $Current | Add-Member -NotePropertyName DarkWallpaper -NotePropertyValue $DarkWallpaper -Force }
    if ($PSBoundParameters.ContainsKey('LightWallpaper')) { $Current | Add-Member -NotePropertyName LightWallpaper -NotePropertyValue $LightWallpaper -Force }

    $AnyPreferenceSpecified = 'Auto', 'ExcludeSystem', 'RestartExplorer', 'IncludeOfficeProPlus', 'ExcludeApps', 'DarkWallpaper', 'LightWallpaper' |
        Where-Object { $PSBoundParameters.ContainsKey($_) }

    if ($AnyPreferenceSpecified -and $PSCmdlet.ShouldProcess($DefaultsPath, 'Save default preferences')) {
        $Current | ConvertTo-Json | Out-File $DefaultsPath -Force
    }

    $Current
}

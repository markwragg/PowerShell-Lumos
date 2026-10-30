Function Get-LumosDefault {
    <#
        .SYNOPSIS
            Gets the default preferences saved by Set-LumosDefault.

        .DESCRIPTION
            The Get-LumosDefault cmdlet returns the default preferences currently saved by Set-LumosDefault,
            such as whether -Auto is used by default on Invoke-Lumos. Preferences that haven't been saved are
            omitted - Invoke-Lumos falls back to its own built-in behavior for any preference that isn't
            saved here.

        .PARAMETER DefaultsPath
            Path to the file used to store default preferences. By default this is in the user's per-user
            data directory (~/.lumos).

        .EXAMPLE
            Get-LumosDefault

            Returns the currently saved default preferences.
    #>
    [cmdletbinding()]
    Param(
        # Path to the file used to store default preferences. By default this is in the user's per-user
        # data directory (~/.lumos).
        [string]
        $DefaultsPath = (Get-LumosUserDataPath -FileName 'Lumos.defaults.json')
    )

    if (Test-Path $DefaultsPath) {
        Get-Content $DefaultsPath | ConvertFrom-Json
    }
    else {
        [pscustomobject]@{}
    }
}

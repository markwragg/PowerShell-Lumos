Function Get-LumosDefaultValue {
    <#
        .SYNOPSIS
            Returns the saved default for the named preference (set via Set-LumosDefault), or the given
            fallback value if no default has been saved for it.

        .PARAMETER Name
            The name of the preference to look up, e.g. 'Auto' or 'DarkWallpaper'.

        .PARAMETER Value
            The value to use if no default has been saved for this preference.

        .EXAMPLE
            Get-LumosDefaultValue -Name 'Auto' -Value $false
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Name,

        $Value
    )

    $Stored = (Get-LumosDefault).$Name

    if ($null -ne $Stored) { $Stored } else { $Value }
}

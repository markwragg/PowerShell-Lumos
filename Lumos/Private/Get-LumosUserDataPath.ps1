Function Get-LumosUserDataPath {
    <#
        .SYNOPSIS
            Returns the full path to a file in the module's per-user data directory, creating the directory
            if it doesn't already exist.

        .DESCRIPTION
            Used to store default preferences (Set-LumosDefault) in a location that survives a module upgrade
            - PowerShell Gallery installs each version into its own version-numbered folder, so anything
            stored under $PSScriptRoot would be orphaned the moment the module updates.

            Resolves to a '.lumos' folder directly under the user's home directory (e.g. ~/.lumos), the same
            convention used by many other cross-platform CLI tools (.ssh, .aws, .docker, .npm, etc.). $HOME is
            a built-in PowerShell variable that's reliably set on every version (including Windows PowerShell
            5.1) and platform.

            This path is also resolved as the default value of Get-LumosDefault's -DefaultsPath parameter,
            which Invoke-Lumos's own parameter defaults read from on every call (via Get-LumosDefaultValue) -
            including for users who have never used Set-LumosDefault. So directory creation failing here
            (e.g. $HOME pointing at a read-only or unreachable location) is swallowed rather than thrown, to
            avoid breaking Invoke-Lumos for everyone else - the caller's own Test-Path check against the
            returned path will simply come back false, same as if no defaults had ever been saved.

        .PARAMETER FileName
            The file name to resolve within the per-user data directory, e.g. 'Lumos.defaults.json'.

        .EXAMPLE
            Get-LumosUserDataPath -FileName 'Lumos.defaults.json'
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $FileName
    )

    $Directory = Join-Path $HOME '.lumos'

    if (-not (Test-Path $Directory)) {
        try {
            New-Item -ItemType Directory -Path $Directory -Force -ErrorAction 'Stop' | Out-Null
        }
        catch {
            Write-Verbose "Could not create default preferences directory [$Directory]: $_"
        }
    }

    Join-Path $Directory $FileName
}

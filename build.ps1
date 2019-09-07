<#
.SYNOPSIS
    PowerShell module build, test, and deployment entry script.
#>

# Check / install required modules 

$RequiredModules = 'Psake','PSScriptAnalyzer','Pester','BuildHelpers'

ForEach ($RequiredModule in $RequiredModules) {

    if (-not (Get-Module $RequiredModule -ListAvailable)) {
        Install-Module $RequiredModule -Scope CurrentUser
    }
}

# Execute PSake

Invoke-Psake ./psake.ps1

# Exit script with build outcome return value

exit ( [int]( -not $psake.build_success ) )
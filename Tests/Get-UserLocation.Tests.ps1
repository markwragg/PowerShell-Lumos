if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

If (-not (Get-Module $Module)) { Import-Module "$Root\$Module" -Force }

Describe "Get-UserLocation PS$PSVersion" {
    
    InModuleScope Lumos {
        # Pending -- Cannot run the cmdlet directly in CI without causing it to hang.
    }
}
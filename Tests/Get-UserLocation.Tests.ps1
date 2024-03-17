if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

If (Get-Module $Module) {
    Remove-Module $Module -Force
}

Import-Module "$Root\$Module" -Force

Describe "Get-UserLocation PS$PSVersion" {

    InModuleScope Lumos {


    }
}
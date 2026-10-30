if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

Describe "Get-LumosDefaultValue PS$PSVersion" {

    InModuleScope Lumos {

        It 'Returns the fallback value when no default has been saved' {
            Mock Get-LumosDefault { [pscustomobject]@{} }

            $Result = Get-LumosDefaultValue -Name 'Auto' -Value 'FALLBACK'

            $Result | Should -Be 'FALLBACK'
        }

        It 'Returns the saved default value when one exists' {
            Mock Get-LumosDefault { [pscustomobject]@{ Auto = $true } }

            $Result = Get-LumosDefaultValue -Name 'Auto' -Value $false

            $Result | Should -Be $true
        }

        It 'Returns a saved default of $false rather than the fallback' {
            Mock Get-LumosDefault { [pscustomobject]@{ Auto = $false } }

            $Result = Get-LumosDefaultValue -Name 'Auto' -Value $true

            $Result | Should -Be $false
        }
    }
}

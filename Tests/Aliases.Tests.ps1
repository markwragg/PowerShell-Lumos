if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

Describe "Aliases PS$PSVersion" {

    BeforeAll {
        $Root = "$PSScriptRoot\..\"
        $Module = 'Lumos'
    }

    It "Should create a 'lumos' alias for Invoke-Lumos" {
        (Get-Alias -Name 'lumos').ResolvedCommand.Name | Should -Be 'Invoke-Lumos'
    }

    It "Should export the 'lumos' alias from the module" {
        (Get-Module -Name $Module).ExportedAliases.Keys | Should -Contain 'lumos'
    }

    It 'Should not error when the module is re-imported and the alias already exists' {
        { Import-Module "$Root\$Module" -Force } | Should -Not -Throw
    }
}

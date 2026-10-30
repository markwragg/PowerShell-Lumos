if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

Describe "Get-LumosDefault PS$PSVersion" {

    InModuleScope Lumos {

        Context 'When no defaults have been saved' {

            It 'Returns an object rather than $null' {
                $DefaultsPath = Join-Path $TestDrive 'missing-defaults.json'

                $Result = Get-LumosDefault -DefaultsPath $DefaultsPath

                $Result | Should -Not -Be $null
                $Result.Auto | Should -BeNullOrEmpty
            }
        }

        Context 'When defaults have been saved' {

            It 'Returns the saved preferences' {
                $DefaultsPath = Join-Path $TestDrive 'existing-defaults.json'
                [pscustomobject]@{ Auto = $true; DarkWallpaper = 'C:\dark.png' } | ConvertTo-Json | Out-File $DefaultsPath

                $Result = Get-LumosDefault -DefaultsPath $DefaultsPath

                $Result.Auto | Should -Be $true
                $Result.DarkWallpaper | Should -Be 'C:\dark.png'
            }
        }
    }
}

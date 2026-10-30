if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

Describe "Set-LumosDefault PS$PSVersion" {

    InModuleScope Lumos {

        Context 'Saving Preferences' {

            It 'Creates the defaults file and saves the specified preference' {
                $DefaultsPath = Join-Path $TestDrive 'new-defaults.json'

                Set-LumosDefault -Auto -DefaultsPath $DefaultsPath | Out-Null

                $DefaultsPath | Should -Exist
                (Get-Content $DefaultsPath | ConvertFrom-Json).Auto | Should -Be $true
            }

            It 'Returns the resulting default preferences' {
                $DefaultsPath = Join-Path $TestDrive 'returned-defaults.json'

                $Result = Set-LumosDefault -DarkWallpaper 'C:\dark.png' -DefaultsPath $DefaultsPath

                $Result.DarkWallpaper | Should -Be 'C:\dark.png'
            }

            It 'Only updates the specified preference, leaving others untouched' {
                $DefaultsPath = Join-Path $TestDrive 'merge-defaults.json'

                Set-LumosDefault -Auto -DefaultsPath $DefaultsPath | Out-Null
                Set-LumosDefault -DarkWallpaper 'C:\dark.png' -DefaultsPath $DefaultsPath | Out-Null

                $Saved = Get-Content $DefaultsPath | ConvertFrom-Json
                $Saved.Auto | Should -Be $true
                $Saved.DarkWallpaper | Should -Be 'C:\dark.png'
            }

            It 'Overwrites a previously saved preference when specified again' {
                $DefaultsPath = Join-Path $TestDrive 'overwrite-defaults.json'

                Set-LumosDefault -LightWallpaper 'C:\old.png' -DefaultsPath $DefaultsPath | Out-Null
                Set-LumosDefault -LightWallpaper 'C:\new.png' -DefaultsPath $DefaultsPath | Out-Null

                (Get-Content $DefaultsPath | ConvertFrom-Json).LightWallpaper | Should -Be 'C:\new.png'
            }

            It 'Explicitly saves -Auto:$false, overriding a previously saved true value' {
                $DefaultsPath = Join-Path $TestDrive 'false-default.json'

                Set-LumosDefault -Auto -DefaultsPath $DefaultsPath | Out-Null
                Set-LumosDefault -Auto:$false -DefaultsPath $DefaultsPath | Out-Null

                (Get-Content $DefaultsPath | ConvertFrom-Json).Auto | Should -Be $false
            }

            It 'Does not create a defaults file when no preference is specified' {
                $DefaultsPath = Join-Path $TestDrive 'untouched-defaults.json'

                Set-LumosDefault -DefaultsPath $DefaultsPath | Out-Null

                $DefaultsPath | Should -Not -Exist
            }

            It 'Saves the ExcludeSystem, RestartExplorer, IncludeOfficeProPlus and ExcludeApps preferences used by Invoke-Lumos' {
                $DefaultsPath = Join-Path $TestDrive 'switches-defaults.json'

                Set-LumosDefault -ExcludeSystem -RestartExplorer -IncludeOfficeProPlus -ExcludeApps -DefaultsPath $DefaultsPath | Out-Null

                $Saved = Get-Content $DefaultsPath | ConvertFrom-Json
                $Saved.ExcludeSystem | Should -Be $true
                $Saved.RestartExplorer | Should -Be $true
                $Saved.IncludeOfficeProPlus | Should -Be $true
                $Saved.ExcludeApps | Should -Be $true
            }
        }

        Context 'Reset' {

            It 'Removes the defaults file when -Reset is specified' {
                $DefaultsPath = Join-Path $TestDrive 'reset-defaults.json'
                Set-LumosDefault -Auto -DefaultsPath $DefaultsPath | Out-Null

                Set-LumosDefault -Reset -DefaultsPath $DefaultsPath | Out-Null

                $DefaultsPath | Should -Not -Exist
            }

            It 'Returns an empty object after resetting' {
                $DefaultsPath = Join-Path $TestDrive 'reset-return-defaults.json'
                Set-LumosDefault -Auto -DefaultsPath $DefaultsPath | Out-Null

                $Result = Set-LumosDefault -Reset -DefaultsPath $DefaultsPath

                $Result.Auto | Should -BeNullOrEmpty
            }

            It 'Does not throw when -Reset is specified and no defaults file exists' {
                $DefaultsPath = Join-Path $TestDrive 'reset-missing-defaults.json'

                { Set-LumosDefault -Reset -DefaultsPath $DefaultsPath } | Should -Not -Throw
            }
        }

        Context 'WhatIf' {

            It 'Does not save the preference when -WhatIf is specified' {
                $DefaultsPath = Join-Path $TestDrive 'whatif-defaults.json'

                Set-LumosDefault -Auto -DefaultsPath $DefaultsPath -WhatIf | Out-Null

                $DefaultsPath | Should -Not -Exist
            }
        }
    }
}

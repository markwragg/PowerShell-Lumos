if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

If (Get-Module $Module) {
    Remove-Module $Module -Force
}
    
Import-Module "$Root\$Module" -Force

Describe "Invoke-Lumos PS$PSVersion" {

    InModuleScope Lumos {

        Mock Get-UserLocation {
            [pscustomobject]@{
                Latitude = '123.456'
                Longitude = '-24.567'
            }
        }

        Mock Set-ItemProperty {}

        Mock Set-Wallpaper {}
        
        Context 'Invoke-Lumos -Light' {

            $InvokeLumos = Invoke-Lumos -Light

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should call Get-Userlocation 0 times' {
                Assert-MockCalled Get-UserLocation -Times 0 -Exactly
            }

            It 'Should call Set-ItemProperty 2 times' {
                Assert-MockCalled Set-ItemProperty -Times 2 -Exactly
            }

            It 'Should call Set-Wallpaper 0 times' {
                Assert-MockCalled Set-Wallpaper -Times 0 -Exactly
            }
        }

        Context 'Invoke-Lumos -Dark' {

            $InvokeLumos = Invoke-Lumos -Dark

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should call Get-Userlocation 1 time' {
                Assert-MockCalled Get-UserLocation -Times 0 -Exactly
            }

            It 'Should call Set-ItemProperty 2 times' {
                Assert-MockCalled Set-ItemProperty -Times 2 -Exactly
            }

            It 'Should call Set-Wallpaper 0 times' {
                Assert-MockCalled Set-Wallpaper -Times 0 -Exactly
            }
        }

        Context 'Invoke-Lumos -Light -ExcludeApps' {

            $InvokeLumos = Invoke-Lumos -Light -ExcludeApps

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should call Get-Userlocation 0 times' {
                Assert-MockCalled Get-UserLocation -Times 0 -Exactly
            }

            It 'Should call Set-ItemProperty 1 time' {
                Assert-MockCalled Set-ItemProperty -Times 1 -Exactly
            }

            It 'Should call Set-Wallpaper 0 times' {
                Assert-MockCalled Set-Wallpaper -Times 0 -Exactly
            }
        }

        Context 'Invoke-Lumos -Dark -DarkWallpaper c:\some\wallpaper.png' {

            $InvokeLumos = Invoke-Lumos -Dark -DarkWallpaper 'c:\some\wallpaper.png'

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should call Get-Userlocation 0 times' {
                Assert-MockCalled Get-UserLocation -Times 0 -Exactly
            }

            It 'Should call Set-ItemProperty 2 times' {
                Assert-MockCalled Set-ItemProperty -Times 2 -Exactly
            }

            It 'Should call Set-Wallpaper 1 times' {
                Assert-MockCalled Set-Wallpaper -Times 1 -Exactly
            }
        }

        Context 'Invoke-Lumos -Light -LightWallpaper c:\some\wallpaper.png' {

            $InvokeLumos = Invoke-Lumos -Light -LightWallpaper 'c:\some\wallpaper.png'

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should call Get-Userlocation 0 times' {
                Assert-MockCalled Get-UserLocation -Times 0 -Exactly
            }

            It 'Should call Set-ItemProperty 2 times' {
                Assert-MockCalled Set-ItemProperty -Times 2 -Exactly
            }

            It 'Should call Set-Wallpaper 1 times' {
                Assert-MockCalled Set-Wallpaper -Times 1 -Exactly
            }
        }


        Context 'Invoke-Lumos' {

            $InvokeLumos = Invoke-Lumos

            It 'Should return null' {
                $InvokeLumos | Should -Be $null
            }

            It 'Should call Get-Userlocation 1 time' {
                Assert-MockCalled Get-UserLocation -Times 1 -Exactly
            }

            It 'Should call Set-ItemProperty 2 times' {
                Assert-MockCalled Set-ItemProperty -Times 2 -Exactly
            }

            It 'Should call Set-Wallpaper 0 times' {
                Assert-MockCalled Set-Wallpaper -Times 0 -Exactly
            }
        }

        Context 'Invoke-Lumos with Get-UserLocation returning null' {
            
            Mock Get-UserLocation {}

            It 'Should throw "Could not get sunrise/sunset data for the current user."' {
                { Invoke-Lumos } | Should -Throw 'Could not get sunrise/sunset data for the current user.'
            }

            It 'Should call Get-Userlocation 1 time' {
                Assert-MockCalled Get-UserLocation -Times 1 -Exactly
            }

            It 'Should call Set-ItemProperty 0 times' {
                Assert-MockCalled Set-ItemProperty -Times 0 -Exactly
            }

            It 'Should call Set-Wallpaper 0 times' {
                Assert-MockCalled Set-Wallpaper -Times 0 -Exactly
            }
        }
    }
}
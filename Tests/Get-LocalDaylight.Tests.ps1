if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

If (-not (Get-Module $Module)) { Import-Module "$Root\$Module" -Force }

Describe "Get-LocalDaylight PS$PSVersion" {
    
    InModuleScope Lumos {

        Mock Invoke-RestMethod {
            [pscustomobject]@{
                results = @{
                    sunrise    = '5:52:27 AM'
                    sunset     = '6:01:34 PM'
                    solar_noon = '11:57:00 AM'
                    day_length = '12:09:07'
                }
            }
        }

        $GetDate = Get-Command Get-Date

        Mock Get-Date {
            & $GetDate -Date $Date
        }

        $GetLocalDaylight = Get-LocalDaylight -Latitude 1 -Longitude 2

        It 'Should return a PSCustomObject' {
            $GetLocalDaylight | Should -BeOfType [PSCustomObject]
        }

        It 'Should return a time for Sunrise' {
            $GetLocalDaylight.Sunrise | Should -BeOfType [datetime]
            $GetLocalDaylight.Sunrise | Should -Not -Be $null
        }

        It 'Should return a time for Sunset' {
            $GetLocalDaylight.Sunset | Should -BeOfType [datetime]
            $GetLocalDaylight.Sunset | Should -Not -Be $null
        }

        It 'Should call Invoke-ResetMethod 1 time' {
            Assert-MockCalled 'Invoke-RestMethod' -Times 1 -Exactly
        }

        It 'Should call Get-Date 2 times' {
            Assert-MockCalled 'Get-Date' -Times 2 -Exactly
        }
    }
}
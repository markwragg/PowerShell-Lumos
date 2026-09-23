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

        Context 'When location is available' {

            BeforeEach {

                Mock Invoke-RestMethod {
                    [pscustomobject]@{
                        ip   = '1.2.3.4'
                        city = 'London'
                        loc  = '51.5074,-0.1278'
                    }
                } -ParameterFilter {
                    $Uri -eq 'https://ipinfo.io/json'
                }

                $GetUserLocation = Get-UserLocation
            }

            It 'Should return the location' {
                $GetUserLocation.Latitude | Should -Be 51.5074
                $GetUserLocation.Longitude | Should -Be -0.1278
            }

            It 'Should call the ipinfo.io API' {
                Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                    $Uri -eq 'https://ipinfo.io/json'
                }
            }
        }

        Context 'When location data is not returned' {

            BeforeEach {

                Mock Invoke-RestMethod {
                    [pscustomobject]@{
                        ip = '1.2.3.4'
                    }
                }

                $GetUserLocation = Get-UserLocation
            }

            It 'Should return null' {
                $GetUserLocation | Should -Be $null
            }
        }
    }
}

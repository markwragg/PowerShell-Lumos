if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

If (-not (Get-Module $Module)) { Import-Module "$Root\$Module" -Force }

Describe "Get-UserLocation PS$PSVersion" {
    
    InModuleScope Lumos {

        $GetUserLocation = Get-UserLocation

        It 'Should return a GeoCoordinate object' {
            $GetUserLocation | Should -BeOfType [System.Device.Location.GeoCoordinate]
        }

        It 'Should return a double for Latitude' {
            $GetUserLocation.Latitude | Should -BeOfType [Double]
        }

        It 'Should return a double for Longitude' {
            $GetUserLocation.Longitude | Should -BeOfType [Double]
        }
    }
}
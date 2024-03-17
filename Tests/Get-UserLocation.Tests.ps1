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

        Mock Add-Type {}

        Mock New-Object {
            New-MockObject -Type 'System.Device.Location.GeoCoordinateWatcher' -Methods @{ Start = {} } -Properties @{ Status = 'Ready'; Permission = 'Denied' }
        }

        Mock Start-Sleep {}

        It 'Should not invoke Start-Sleep' {
            Get-UserLocation
            Assert-MockCalled Start-Sleep -Times 0
        }
    }
}
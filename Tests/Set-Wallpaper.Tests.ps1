if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

# Set-Wallpaper's real effect is a P/Invoke call that changes the running machine's desktop wallpaper, and
# that call can't be mocked since it targets a static method on a type defined at runtime via Add-Type.
# Every test here therefore goes through -WhatIf so the call is gated off by ShouldProcess and never fires.
Describe "Set-Wallpaper PS$PSVersion" {

    InModuleScope Lumos {

        It 'Should support ShouldProcess' {
            (Get-Command Set-Wallpaper).Parameters.Keys | Should -Contain 'WhatIf'
        }

        It 'Should not throw when called with -WhatIf' {
            { Set-Wallpaper -Image 'C:\Wallpaper\Default.jpg' -WhatIf } | Should -Not -Throw
        }

        It 'Should return null when called with -WhatIf' {
            Set-Wallpaper -Image 'C:\Wallpaper\Default.jpg' -WhatIf | Should -Be $null
        }
    }
}

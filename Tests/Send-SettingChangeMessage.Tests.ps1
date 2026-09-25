if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

# Send-SettingChangeMessage's real effect is a P/Invoke broadcast of WM_SETTINGCHANGE via user32.dll, which
# only exists on Windows - unlike Set-Wallpaper's P/Invoke call, it's a harmless, non-persistent notification
# (the same one Windows itself sends on a theme change), so it's safe to let it actually run here.
$IsWindowsPlatform = $PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows

Describe "Send-SettingChangeMessage PS$PSVersion" -Skip:(-not $IsWindowsPlatform) {

    InModuleScope Lumos {

        It 'Should not throw when broadcasting the setting-change message' {
            { Send-SettingChangeMessage } | Should -Not -Throw
        }

        It 'Should not throw on a second call, when the Win32SettingChange type already exists' {
            Send-SettingChangeMessage
            { Send-SettingChangeMessage } | Should -Not -Throw
        }

        It 'Should return null' {
            Send-SettingChangeMessage | Should -Be $null
        }
    }
}

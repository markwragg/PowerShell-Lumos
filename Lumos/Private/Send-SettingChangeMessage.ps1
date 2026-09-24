Function Send-SettingChangeMessage {
    <#
        .SYNOPSIS
            Broadcasts a WM_SETTINGCHANGE message so running apps and the shell pick up a theme change.

        .DESCRIPTION
            Sends the same "ImmersiveColorSet" WM_SETTINGCHANGE broadcast Windows itself sends when a theme
            setting is changed via Settings, so apps and the shell refresh live - without restarting Explorer.

        .EXAMPLE
            Send-SettingChangeMessage
    #>
    [CmdletBinding()]
    Param()

    # Guarded so a second call within the same session (e.g. toggling the theme more than once interactively)
    # doesn't hit Add-Type's "type already exists" error.
    if (-not ('Win32SettingChange' -as [type])) {
        Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;

        public class Win32SettingChange
        {
            [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
            public static extern IntPtr SendMessageTimeout(IntPtr hWnd, uint Msg, UIntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out UIntPtr lpdwResult);
        }
"@
    }

    $HWND_BROADCAST = [IntPtr]0xffff
    $WM_SETTINGCHANGE = 0x1A
    $SMTO_ABORTIFHUNG = 0x0002
    $Result = [UIntPtr]::Zero

    [void][Win32SettingChange]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, 'ImmersiveColorSet', $SMTO_ABORTIFHUNG, 5000, [ref]$Result)
}

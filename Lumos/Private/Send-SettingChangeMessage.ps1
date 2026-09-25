Function Send-SettingChangeMessage {
    <#
        .SYNOPSIS
            Broadcasts the messages Windows itself sends when a theme setting changes, so running apps and
            the shell pick up the change immediately.

        .DESCRIPTION
            Sends the same WM_SETTINGCHANGE("ImmersiveColorSet") + WM_THEMECHANGED broadcast pair Windows'
            own Settings app sends when you change theme there - the taskbar, Start and Action Center all
            pick this up live, without restarting Explorer.

            This does NOT reliably repaint the chrome of an already-open File Explorer window on Windows 11
            - confirmed by testing every documented/undocumented trick short of reapplying a full .theme
            file through the private IThemeManager2 COM interface (SendMessageTimeout broadcasts,
            Shell.Application's Windows().Refresh(), and a targeted WM_COMMAND to the window). This appears
            to be a genuine Windows 11 limitation rather than something missing here - Microsoft's own
            PowerToys "Light Switch" module does the exact same two-message broadcast and has the same
            unresolved gap (see https://github.com/microsoft/PowerToys/issues/42463). -RestartExplorer on
            Invoke-Lumos/Register-LumosScheduledTask is the only reliable fix for that specific symptom.

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
    $WM_THEMECHANGED = 0x031A
    $SMTO_ABORTIFHUNG = 0x0002
    $Result = [UIntPtr]::Zero

    [void][Win32SettingChange]::SendMessageTimeout($HWND_BROADCAST, $WM_SETTINGCHANGE, [UIntPtr]::Zero, 'ImmersiveColorSet', $SMTO_ABORTIFHUNG, 5000, [ref]$Result)

    # WM_THEMECHANGED takes no meaningful wParam/lParam - $null marshals to a null pointer here, matching
    # the message's documented NULL/NULL contract.
    [void][Win32SettingChange]::SendMessageTimeout($HWND_BROADCAST, $WM_THEMECHANGED, [UIntPtr]::Zero, $null, $SMTO_ABORTIFHUNG, 5000, [ref]$Result)
}

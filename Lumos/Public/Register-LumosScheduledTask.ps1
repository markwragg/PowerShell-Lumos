Function Register-LumosScheduledTask {
    <#
        .SYNOPSIS
            Registers a Scheduled Task to run Lumos automatically on Windows.

         .DESCRIPTION
            Use this cmdlet to register a scheduled task on Windows so that Invoke-Lumos is executed using
            your specified parameters repeatedly every 15 minutes. Invoke-Lumos looks up the current
            sunrise/sunset for your location on every run and only changes anything when the theme needs to
            change, so this keeps the Dark/Light switch closely aligned with sunrise and sunset without the
            scheduled task itself ever needing its trigger times updated.

            The task runs as the current user at standard (non-elevated) privilege - Lumos only ever changes
            current-user settings, so no administrator rights are required. Its trigger is fixed at registration
            time rather than being refreshed later, since repeatedly re-registering the task to update trigger
            times proved unreliable in practice. The task deliberately has no "at logon" trigger, since some
            endpoint security software blocks non-admin users from registering one (likely because it's a common
            persistence technique) - the repeating trigger fires immediately on registration and again within 15
            minutes of any logon, so this has little practical effect.

        .PARAMETER ExcludeSystem
            Exclude changing the System theme when switching to Dark/Light (Windows only) when the task runs.

        .PARAMETER IncludeOfficeProPlus
            Include changing the theme of Microsoft Office to Dark/Light (Windows only) when the task runs.

        .PARAMETER ExcludeApps
            Exclude changing the Applications (where supported) theme when switching to Dark/Light (Windows only) when the task runs.

        .PARAMETER DarkWallpaper
            Specify a path to use to modify the Desktop Wallpaper to when the task runs and switches to the Dark theme.

        .PARAMETER LightWallpaper
            Specify a path to use to modify the Desktop Wallpaper to when the task runs and switches to the Light theme.

        .EXAMPLE
            Register-LumosScheduledTask -ExcludeApps -DarkWallpaper C:\Temp\dark.png -LightWallpaper C:\Temp\light.png

            Creates a scheduled task that runs every 15 minutes, switching just the OS theme to either dark or light
            based on the current local sunrise/sunset, along with the specified light or dark wallpaper.
    #>
    [cmdletbinding()]
    Param(
        [switch]
        $ExcludeSystem,

        [switch]
        $ExcludeApps,

        [switch]
        $IncludeOfficeProPlus,

        [string]
        $DarkWallpaper,

        [string]
        $LightWallpaper
    )

    if (-not ($PSVersionTable.PSEdition -eq 'Desktop' -or $IsWindows)) {
        Write-Warning 'Register-LumosScheduledTask is only supported on Windows.'
        return
    }

    $ArgumentDefaults = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden'

    $LumosArgument = "$ArgumentDefaults -Command Invoke-Lumos"

    If ($ExcludeSystem) {
        $LumosArgument = $LumosArgument + " -ExcludeSystem"
    }
    If ($ExcludeApps) {
        $LumosArgument = $LumosArgument + " -ExcludeApps"
    }
    If ($IncludeOfficeProPlus) {
        $LumosArgument = $LumosArgument + " -IncludeOfficeProPlus"
    }
    If ($LightWallpaper) {
        $LumosArgument = $LumosArgument + " -LightWallpaper '$LightWallpaper'"
    }
    If ($DarkWallpaper) {
        $LumosArgument = $LumosArgument + " -DarkWallpaper '$DarkWallpaper'"
    }

    $LumosAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $LumosArgument
    $Principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive
    $TaskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable

    # Repeats indefinitely every 15 minutes so Invoke-Lumos re-checks sunrise/sunset regularly, without ever
    # needing the task's own triggers to be updated later. Deliberately not an "at logon" trigger - some
    # endpoint security software denies non-admin users permission to register one.
    $IntervalTrigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 15)

    New-ScheduledTask -Action $LumosAction -Principal $Principal -Settings $TaskSettings -Trigger $IntervalTrigger |
        Register-ScheduledTask -TaskName 'Lumos' -Force | Out-Null
}

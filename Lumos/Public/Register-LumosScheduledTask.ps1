Function Register-LumosScheduledTask {
    <#
        .SYNOPSIS
            Registers a Scheduled Task to run Lumos automatically on Windows.

         .DESCRIPTION
            Use this cmdlet to register a scheduled task on Windows so that Invoke-Lumos is executed using
            your specified parameters at sunrise and sunset, or when the task is next available to run having
            missed one of those scheduled times (e.g after system resumes).

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

            Creates a scheduled task that will run at the current local sunrise/sunset times and switch just the OS theme
            to either dark or light, along with the specified light or dark wallpaper.
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

    # Get localized value for local administrator group
    $adminSid = [System.Security.Principal.WellKnownSidType]::BuiltinAdministratorsSid
    $adminSecId = New-Object System.Security.Principal.SecurityIdentifier($adminSid, $null)
    $localizedAdminGroup = $adminSecId.Translate([System.Security.Principal.NTAccount]).Value

    $LumosAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $LumosArgument
    $UpdateAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "$ArgumentDefaults -Command Update-LumosScheduledTask"
    $Principal = New-ScheduledTaskPrincipal -GroupId $localizedAdminGroup -RunLevel Highest
    $TaskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable

    New-ScheduledTask -Action $LumosAction,$UpdateAction -Principal $Principal -Settings $TaskSettings | Register-ScheduledTask -TaskName 'Lumos' -Force

    # Run Update-LumosScheduledTask to add triggers
    Update-LumosScheduledTask
}

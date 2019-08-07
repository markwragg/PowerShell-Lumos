Function Register-LumosScheduledTask {
    <#
        .SYNOPSIS
            Registers a Scheduled Task to run Lumos automatically.
    #>      
    [cmdletbinding(DefaultParameterSetName='Dark')]
    Param(
        [switch]
        $ExcludeSystem,

        [switch]
        $ExcludeApps,

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
    If ($LightWallpaper) { 
        $LumosArgument = $LumosArgument + " -LightWallpaper '$LightWallpaper'" 
    }
    If ($DarkWallpaper) {
        $LumosArgument = $LumosArgument + " -DarkWallpaper '$DarkWallpaper'"
    }
    
    $LumosAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $LumosArgument
    $UpdateAction = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "$ArgumentDefaults -Command Update-LumosScheduledTask"
    $Principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest

    New-ScheduledTask -Action $LumosAction,$UpdateAction -Principal $Principal | Register-ScheduledTask -TaskName 'Lumos' -Force

    Update-LumosScheduledTask
}
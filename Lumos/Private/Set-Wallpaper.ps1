Function Set-Wallpaper {
    <#
        .SYNOPSIS
            Applies a specified wallpaper to the current user's desktop
        
        .PARAMETER Image
            Provide the full path to the image
        
        .EXAMPLE
            Set-WallPaper -Image "C:\Wallpaper\Default.jpg"     
    #>
    [cmdletbinding(SupportsShouldProcess)]
    Param(
        [string]
        $Image
    )
     
    Add-Type -TypeDefinition @" 
    using System; 
    using System.Runtime.InteropServices;
     
    public class Params
    { 
        [DllImport("User32.dll",CharSet=CharSet.Unicode)] 
        public static extern int SystemParametersInfo (Int32 uAction, 
                                                       Int32 uParam, 
                                                       String lpvParam, 
                                                       Int32 fuWinIni);
    }
"@ 
     
    $SPI_SETDESKWALLPAPER = 0x0014
    $UpdateIniFile = 0x01
    $SendChangeEvent = 0x02
     
    $fWinIni = $UpdateIniFile -bor $SendChangeEvent
    
    if ($PSCmdlet.ShouldProcess($Image)) {
        [void][Params]::SystemParametersInfo($SPI_SETDESKWALLPAPER, 0, $Image, $fWinIni)
    }
}
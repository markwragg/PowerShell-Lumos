Function Invoke-GSettings {
    <#
        .SYNOPSIS
            Executes a command via the GNOME gsettings CLI.
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [String[]]
        $Arguments
    )
    Begin {
    }
    Process {
        If ($PSCmdlet.ShouldProcess('gsettings', ($Arguments -join ' '))) {
            & gsettings @Arguments
        }
    }
}

Function Invoke-AppleScript {
    <#
        .SYNOPSIS
            Executes a command string via Apple Script.
    #>
    [cmdletbinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [String]
        $Command
    )
    Begin {
    }
    Process {
        If ($PSCmdlet.ShouldProcess('/usr/bin/osascript -e',$Command)){
            /usr/bin/osascript -e $Command
        }
    }
}
if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

Describe "Invoke-AppleScript PS$PSVersion" {

    InModuleScope Lumos {

        BeforeEach {

            # osascript is a fixed external path rather than a cmdlet, so a stub function has to exist
            # under that literal name before Pester can shim it with Mock. The alias Mock leaves behind
            # from the previous test's mock function is removed first so it doesn't dangle.
            Remove-Item -Path 'Alias:\/usr/bin/osascript' -Force -ErrorAction SilentlyContinue
            New-Item -Path Function:\ -Name '/usr/bin/osascript' -Value {} -Force | Out-Null
            Mock '/usr/bin/osascript' {}
        }

        It 'Should call osascript with the -e switch and the given command' {
            Invoke-AppleScript -Command 'tell application "Finder" to activate' -Confirm:$false

            Should -Invoke '/usr/bin/osascript' -Times 1 -Exactly -ParameterFilter {
                $args[0] -eq '-e' -and $args[1] -eq 'tell application "Finder" to activate'
            }
        }

        It 'Should accept the command from the pipeline' {
            'tell application "Finder" to activate' | Invoke-AppleScript -Confirm:$false

            Should -Invoke '/usr/bin/osascript' -Times 1 -Exactly
        }

        It 'Should not call osascript when -WhatIf is specified' {
            Invoke-AppleScript -Command 'tell application "Finder" to activate' -WhatIf

            Should -Invoke '/usr/bin/osascript' -Times 0 -Exactly
        }

        It 'Should return null' {
            $Result = Invoke-AppleScript -Command 'tell application "Finder" to activate' -Confirm:$false
            $Result | Should -Be $null
        }
    }
}

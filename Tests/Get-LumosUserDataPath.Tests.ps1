if (-not $PSScriptRoot) { $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent }

$PSVersion = $PSVersionTable.PSVersion.Major
$Root = "$PSScriptRoot\..\"
$Module = 'Lumos'

if (Get-Module -Name $Module) {
    Remove-Module -Name $Module -Force
}
Import-Module "$Root\$Module" -Force

Describe "Get-LumosUserDataPath PS$PSVersion" {

    InModuleScope Lumos {

        BeforeAll {
            # A random file name per test run, so these tests never collide with a real file a user might
            # already have in their actual per-user data directory, and cleanup only ever removes files
            # these tests created.
            $Script:TestFileName = "Lumos.test.$([guid]::NewGuid()).json"
            $Script:ExpectedDirectory = Join-Path $HOME '.lumos'
            $Script:ExpectedPath = Join-Path $Script:ExpectedDirectory $Script:TestFileName
        }

        AfterAll {
            Remove-Item $Script:ExpectedPath -Force -ErrorAction SilentlyContinue
        }

        It "Returns a path for the given file name under a '.lumos' folder in the user's home directory" {
            $Result = Get-LumosUserDataPath -FileName $Script:TestFileName

            $Result | Should -Be $Script:ExpectedPath
        }

        It "Creates the '.lumos' directory if it does not already exist" {
            Get-LumosUserDataPath -FileName $Script:TestFileName | Out-Null

            $Script:ExpectedDirectory | Should -Exist
        }

        It 'Does not create the file itself, only the directory' {
            Get-LumosUserDataPath -FileName $Script:TestFileName | Out-Null

            $Script:ExpectedPath | Should -Not -Exist
        }

        Context 'When the per-user data directory cannot be created' {

            BeforeEach {
                Mock Test-Path { $false }
                Mock New-Item { throw 'Access to the path is denied.' }
            }

            It 'Does not throw, so a single user with an unwritable $HOME cannot break every Invoke-Lumos call' {
                { Get-LumosUserDataPath -FileName $Script:TestFileName } | Should -Not -Throw
            }

            It 'Still returns a path for the given file name' {
                $Result = Get-LumosUserDataPath -FileName $Script:TestFileName

                $Result | Should -Be $Script:ExpectedPath
            }
        }
    }
}

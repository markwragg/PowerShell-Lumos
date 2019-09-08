# PSake makes variables declared here available in other scriptblocks
Properties {
    $ProjectRoot = $ENV:BHProjectPath
    if (-not $ProjectRoot) {
        $ProjectRoot = $PSScriptRoot
    }

    $Timestamp = Get-Date -UFormat '%Y%m%d-%H%M%S'
    $PSVersion = $PSVersionTable.PSVersion.Major
    $lines = '----------------------------------------------------------------------'

    # Pester
    $TestScripts = Get-ChildItem "$ProjectRoot\Tests\*\*Tests.ps1"
    $TestFile = "Test-Unit_$($TimeStamp).xml"

    # Script Analyzer
    [ValidateSet('Error', 'Warning', 'Any', 'None')]
    $ScriptAnalysisFailBuildOnSeverityLevel = 'Error'
    $ScriptAnalyzerSettingsPath = "$ProjectRoot\PSScriptAnalyzerSettings.psd1"

    # Build
    $ArtifactFolder = Join-Path -Path $ProjectRoot -ChildPath 'Artifacts'

    # Staging
    $StagingFolder = Join-Path -Path $ProjectRoot -ChildPath 'Staging'
    $StagingModulePath = Join-Path -Path $StagingFolder -ChildPath $env:BHProjectName
    $StagingModuleManifestPath = Join-Path -Path $StagingModulePath -ChildPath "$($env:BHProjectName).psd1"

    # Documentation
    $DocumentationPath = Join-Path -Path $StagingFolder -ChildPath 'Documentation'
}


# Define top-level tasks
Task 'Default' -Depends 'Test'


# Show build variables
Task 'Init' {
    $lines

    Set-Location $ProjectRoot
    "Build System Details:"
    Get-Item ENV:BH*
    "`n"
}


# Clean the Artifact and Staging folders
Task 'Clean' -Depends 'Init' {
    $lines

    $foldersToClean = @(
        $ArtifactFolder
        $StagingFolder
    )

    # Remove folders
    foreach ($folderPath in $foldersToClean) {
        Remove-Item -Path $folderPath -Recurse -Force -ErrorAction 'SilentlyContinue'
        New-Item -Path $folderPath -ItemType 'Directory' -Force | Out-String | Write-Verbose
    }
}


# Create a single .psm1 module file containing all functions
# Copy new module and other supporting files (Documentation / Examples) to Staging folder
Task 'CombineFunctionsAndStage' -Depends 'Clean' {
    $lines

    # Create folders
    New-Item -Path $StagingFolder -ItemType 'Directory' -Force | Out-String | Write-Verbose
    New-Item -Path $StagingModulePath -ItemType 'Directory' -Force | Out-String | Write-Verbose

    # Get public and private function files
    $publicFunctions = @( Get-ChildItem -Path "$env:BHModulePath\Public\*.ps1" -Recurse -ErrorAction 'SilentlyContinue' )
    $privateFunctions = @( Get-ChildItem -Path "$env:BHModulePath\Private\*.ps1" -Recurse -ErrorAction 'SilentlyContinue' )

    # Combine functions into a single .psm1 module
    $combinedModulePath = Join-Path -Path $StagingModulePath -ChildPath "$($env:BHProjectName).psm1"
    @($publicFunctions + $privateFunctions) | Get-Content | Add-Content -Path $combinedModulePath

    # Copy other required folders and files
    $pathsToCopy = @(
        Join-Path -Path $ProjectRoot -ChildPath 'Documentation'
        Join-Path -Path $ProjectRoot -ChildPath 'Examples'
        # Join-Path -Path $ProjectRoot -ChildPath 'CHANGELOG.md'
        Join-Path -Path $ProjectRoot -ChildPath 'README.md'
    )
    Copy-Item -Path $pathsToCopy -Destination $StagingFolder -Recurse

    # Copy existing manifest
    Copy-Item -Path $env:BHPSModuleManifest -Destination $StagingModulePath -Recurse
}


# Import new module
Task 'ImportStagingModule' -Depends 'Init' {
    $lines
    Write-Output "Reloading staged module from path: [$StagingModulePath]`n"

    # Reload module
    if (Get-Module -Name $env:BHProjectName) {
        Remove-Module -Name $env:BHProjectName
    }
    # Global scope used for UpdateDocumentation (PlatyPS)
    Import-Module -Name $StagingModulePath -ErrorAction 'Stop' -Force -Global
}


# Run PSScriptAnalyzer against code to ensure quality and best practices are used
Task 'Analyze' -Depends 'ImportStagingModule' {
    $lines
    Write-Output "Running PSScriptAnalyzer on path: [$StagingModulePath]`n"

    $Results = Invoke-ScriptAnalyzer -Path $StagingModulePath -Recurse -Settings $ScriptAnalyzerSettingsPath -Verbose:$VerbosePreference
    $Results | Select-Object 'RuleName', 'Severity', 'ScriptName', 'Line', 'Message' | Format-List

    switch ($ScriptAnalysisFailBuildOnSeverityLevel) {
        'None' {
            return
        }
        'Error' {
            Assert -conditionToCheck (
                ($Results | Where-Object 'Severity' -eq 'Error').Count -eq 0
            ) -failureMessage 'One or more ScriptAnalyzer errors were found. Build cannot continue!'
        }
        'Warning' {
            Assert -conditionToCheck (
                ($Results | Where-Object {
                        $_.Severity -eq 'Warning' -or $_.Severity -eq 'Error'
                    }).Count -eq 0) -failureMessage 'One or more ScriptAnalyzer warnings were found. Build cannot continue!'
        }
        default {
            Assert -conditionToCheck ($analysisResult.Count -eq 0) -failureMessage 'One or more ScriptAnalyzer issues were found. Build cannot continue!'
        }
    }
}


# Run Pester tests
# Unit tests: verify inputs / outputs / expected execution path
# Misc tests: verify manifest data, check comment-based help exists
Task 'Test' -Depends 'ImportStagingModule' {
    $lines

    # Gather test results. Store them in a variable and file
    $TestFilePath = Join-Path -Path $ArtifactFolder -ChildPath $TestFile
    $TestResults = Invoke-Pester -Script $TestScripts -PassThru -OutputFormat 'NUnitXml' -OutputFile $TestFilePath -PesterOption @{IncludeVSCodeMarker = $true}

    # Fail build if any tests fail
    if ($TestResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
}


# Create new Documentation markdown files from comment-based help
Task 'UpdateDocumentation' -Depends 'ImportStagingModule' {
    $lines
    Write-Output "Updating Markdown help in Staging folder: [$DocumentationPath]`n"

    # $null = Import-Module -Name $env:BHPSModuleManifest -Global -Force -PassThru -Verbose

    # Cleanup
    Remove-Item -Path $DocumentationPath -Recurse -Force -ErrorAction 'SilentlyContinue'
    Start-Sleep -Seconds 5
    New-Item -Path $DocumentationPath -ItemType 'Directory' | Out-Null

    # Create new Documentation markdown files
    $platyPSParams = @{
        Module       = $env:BHProjectName
        OutputFolder = $DocumentationPath
        NoMetadata   = $true
    }
    New-MarkdownHelp @platyPSParams -ErrorAction 'SilentlyContinue' -Verbose | Out-Null

    # Update index.md
    Write-Output "Copying index.md...`n"
    Copy-Item -Path "$env:BHProjectPath\README.md" -Destination "$($DocumentationPath)\index.md" -Force -Verbose | Out-Null
}


# Create a versioned zip file of all staged files
# NOTE: Admin Rights are needed if you run this locally
Task 'CreateBuildArtifact' -Depends 'Init' {
    $lines

    # Create /Release folder
    New-Item -Path $ArtifactFolder -ItemType 'Directory' -Force | Out-String | Write-Verbose

    # Get current manifest version
    try {
        $manifest = Test-ModuleManifest -Path $StagingModuleManifestPath -ErrorAction 'Stop'
        [Version]$manifestVersion = $manifest.Version

    } catch {
        throw "Could not get manifest version from [$StagingModuleManifestPath]"
    }

    # Create zip file
    try {
        $releaseFilename = "$($env:BHProjectName)-v$($manifestVersion.ToString()).zip"
        $releasePath = Join-Path -Path $ArtifactFolder -ChildPath $releaseFilename
        Write-Host "Creating release artifact [$releasePath] using manifest version [$manifestVersion]" -ForegroundColor 'Yellow'
        Compress-Archive -Path "$StagingFolder/*" -DestinationPath $releasePath -Force -Verbose -ErrorAction 'Stop'
    } catch {
        throw "Could not create release artifact [$releasePath] using manifest version [$manifestVersion]"
    }

    Write-Output "`nFINISHED: Release artifact creation."
}


#region NOT USED FOR THIS DEMO
# Task 'Release' -Depends 'Clean', 'Test', 'UpdateDocumentation', 'CombineFunctionsAndStage', 'CreateBuildArtifact' #'UpdateManifest', 'UpdateTag'
Task 'Build' -Depends 'Init' {
    $lines

    # Load the module, read the exported functions, update the psd1 FunctionsToExport
    Set-ModuleFunctions -Name $env:BHPSModuleManifest

    # Bump the module version
    try {
        $Version = Get-NextPSGalleryVersion -Name $env:BHProjectName -ErrorAction 'Stop'
        Update-Metadata -Path $env:BHPSModuleManifest -PropertyName 'ModuleVersion' -Value $Version -ErrorAction 'Stop'
    } catch {
        "Failed to update version for '$env:BHProjectName': $_.`nContinuing with existing version"
    }
}


Task 'Deploy' -Depends 'Init' {
    $lines

    $Params = @{
        Path    = "$ProjectRoot"
        Force   = $true
        Recurse = $false
    }
    Invoke-PSDeploy @Verbose @Params
}
#endregion NOT USED FOR THIS DEMO

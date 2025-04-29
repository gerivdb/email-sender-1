<#
.SYNOPSIS
    Tests pour vÃ©rifier l'intÃ©gration entre le gestionnaire intÃ©grÃ© et les modes adaptÃ©s.

.DESCRIPTION
    Ce script contient des tests pour vÃ©rifier que le gestionnaire intÃ©grÃ© fonctionne correctement
    avec les modes adaptÃ©s pour utiliser la configuration unifiÃ©e.
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# DÃ©finir les chemins
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))
$integratedManagerPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\integrated-manager.ps1"
$configPath = Join-Path -Path $projectRoot -ChildPath "development\config\unified-config.json"
$checkModePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\check.ps1"
$granModePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\gran-mode.ps1"

# CrÃ©er un rÃ©pertoire de test temporaire
$testDir = Join-Path -Path $scriptPath -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
@"
# Test Roadmap

## TÃ¢che 1.2.3

### Description
Cette tÃ¢che est utilisÃ©e pour les tests du gestionnaire intÃ©grÃ©.

### Sous-tÃ¢ches
- [ ] **1.2.3.1** Sous-tÃ¢che 1
- [ ] **1.2.3.2** Sous-tÃ¢che 2
- [ ] **1.2.3.3** Sous-tÃ¢che 3
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# CrÃ©er un fichier de sous-tÃ¢ches de test
$testSubTasksPath = Join-Path -Path $testDir -ChildPath "test-subtasks.txt"
@"
Analyser les besoins
Concevoir la solution
ImplÃ©menter le code
Tester la solution
Documenter l'implÃ©mentation
"@ | Set-Content -Path $testSubTasksPath -Encoding UTF8

# CrÃ©er un fichier de configuration de test
$testConfigPath = Join-Path -Path $testDir -ChildPath "test-config.json"
@{
    General = @{
        RoadmapPath = $testRoadmapPath
        ActiveDocumentPath = $testRoadmapPath
        ReportPath = $testDir
        LogPath = $testDir
        DefaultLanguage = "fr-FR"
        DefaultEncoding = "UTF8-BOM"
        ProjectRoot = $projectRoot
    }
    Modes = @{
        Check = @{
            Enabled = $true
            ScriptPath = $checkModePath
            DefaultRoadmapFile = $testRoadmapPath
            DefaultActiveDocumentPath = $testRoadmapPath
            AutoUpdateRoadmap = $true
            GenerateReport = $true
            ReportPath = $testDir
            AutoUpdateCheckboxes = $true
            RequireFullTestCoverage = $true
            SimulationModeDefault = $true
        }
        Gran = @{
            Enabled = $true
            ScriptPath = $granModePath
            DefaultRoadmapFile = $testRoadmapPath
            MaxTaskSize = 5
            MaxComplexity = 7
            AutoIndent = $true
            GenerateSubtasks = $true
            UpdateInPlace = $true
            SubTasksFile = $testSubTasksPath
            IndentationStyle = "Spaces2"
            CheckboxStyle = "GitHub"
        }
        Manager = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $projectRoot -ChildPath "development\\scripts\\mode-manager\mode-manager.ps1"
        }
    }
    Roadmaps = @{
        Test = @{
            Path = $testRoadmapPath
            Description = "Roadmap de test"
            Format = "Markdown"
            AutoUpdate = $true
            GitIntegration = $false
            ReportPath = $testDir
        }
    }
    roadmap-manager = @{
        DefaultRoadmapPath = $testRoadmapPath
        ReportsFolder = $testDir
        GitRepo = "."
        DaysToAnalyze = 7
        AutoUpdate = $true
        GenerateReport = $true
        JournalPath = Join-Path -Path $testDir -ChildPath "journal"
        LogFile = Join-Path -Path $testDir -ChildPath "roadmap-manager.log"
        BackupFolder = Join-Path -Path $testDir -ChildPath "backup"
        Scripts = @{
            Manager = Join-Path -Path $scriptPath -ChildPath "mock-roadmap-manager.ps1"
            Analyzer = Join-Path -Path $scriptPath -ChildPath "mock-roadmap-analyzer.ps1"
            GitUpdater = Join-Path -Path $scriptPath -ChildPath "mock-roadmap-git-updater.ps1"
            Cleanup = Join-Path -Path $scriptPath -ChildPath "mock-roadmap-cleanup.ps1"
            Organize = Join-Path -Path $scriptPath -ChildPath "mock-roadmap-organize.ps1"
            Execute = Join-Path -Path $scriptPath -ChildPath "mock-roadmap-execute.ps1"
            Sync = Join-Path -Path $scriptPath -ChildPath "mock-roadmap-sync.ps1"
        }
    }
    Workflows = @{
        Test = @{
            Description = "Workflow de test"
            Modes = @("CHECK", "GRAN")
            AutoContinue = $true
            StopOnError = $true
        }
    }
    Integration = @{
        EnabledByDefault = $true
        DefaultWorkflow = "Test"
        DefaultRoadmap = "Test"
        AutoSaveResults = $true
        ResultsPath = $testDir
        LogLevel = "Info"
        NotifyOnCompletion = $true
        MaxConcurrentTasks = 4
    }
    Paths = @{
        OutputDirectory = $testDir
        TestsDirectory = $testDir
        ScriptsDirectory = Join-Path -Path $projectRoot -ChildPath "development\scripts"
        ModulePath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module"
        FunctionsPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions"
        TemplatesPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Templates"
        BackupPath = Join-Path -Path $testDir -ChildPath "backup"
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $testConfigPath -Encoding UTF8

# CrÃ©er des scripts mock pour les tests
$mockRoadmapParserModulePath = Join-Path -Path $testDir -ChildPath "RoadmapParser.psm1"
@"
function Invoke-RoadmapCheck {
    [CmdletBinding(SupportsShouldProcess = `$true)]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$FilePath,

        [Parameter(Mandatory = `$false)]
        [string]`$TaskIdentifier,

        [Parameter(Mandatory = `$false)]
        [string]`$ImplementationPath,

        [Parameter(Mandatory = `$false)]
        [string]`$TestsPath,

        [Parameter(Mandatory = `$false)]
        [bool]`$UpdateRoadmap = `$true,

        [Parameter(Mandatory = `$false)]
        [bool]`$GenerateReport = `$true
    )

    # CrÃ©er un fichier de sortie pour vÃ©rifier que la fonction a Ã©tÃ© appelÃ©e
    `$outputPath = Join-Path -Path "$testDir" -ChildPath "invoke-roadmap-check-output.txt"
    @"
FilePath: `$FilePath
TaskIdentifier: `$TaskIdentifier
ImplementationPath: `$ImplementationPath
TestsPath: `$TestsPath
UpdateRoadmap: `$UpdateRoadmap
GenerateReport: `$GenerateReport
"@ | Set-Content -Path `$outputPath -Encoding UTF8

    # Retourner un rÃ©sultat simulÃ©
    return @{
        Tasks = @(
            @{
                Id = "1.2.3.1"
                Title = "Sous-tÃ¢che 1"
                IsChecked = `$false
                Implementation = @{
                    ImplementationComplete = `$true
                    ImplementationPercentage = 100
                    ImplementationPath = `$ImplementationPath
                    ImplementationFiles = @("file1.ps1", "file2.ps1")
                }
                Tests = @{
                    TestsComplete = `$true
                    TestsPercentage = 100
                    TestsSuccessful = `$true
                    SuccessPercentage = 100
                    TestsPath = `$TestsPath
                    TestFiles = @("test1.ps1", "test2.ps1")
                }
            },
            @{
                Id = "1.2.3.2"
                Title = "Sous-tÃ¢che 2"
                IsChecked = `$false
                Implementation = @{
                    ImplementationComplete = `$true
                    ImplementationPercentage = 100
                    ImplementationPath = `$ImplementationPath
                    ImplementationFiles = @("file3.ps1")
                }
                Tests = @{
                    TestsComplete = `$true
                    TestsPercentage = 100
                    TestsSuccessful = `$true
                    SuccessPercentage = 100
                    TestsPath = `$TestsPath
                    TestFiles = @("test3.ps1")
                }
            },
            @{
                Id = "1.2.3.3"
                Title = "Sous-tÃ¢che 3"
                IsChecked = `$false
                Implementation = @{
                    ImplementationComplete = `$false
                    ImplementationPercentage = 50
                    ImplementationPath = `$ImplementationPath
                    ImplementationFiles = @()
                }
                Tests = @{
                    TestsComplete = `$false
                    TestsPercentage = 0
                    TestsSuccessful = `$false
                    SuccessPercentage = 0
                    TestsPath = `$TestsPath
                    TestFiles = @()
                }
            }
        )
        TasksUpdated = @("1.2.3.1", "1.2.3.2")
        ReportPath = Join-Path -Path "$testDir" -ChildPath "report.html"
    }
}

function Update-ActiveDocumentCheckboxes {
    [CmdletBinding(SupportsShouldProcess = `$true)]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$FilePath,

        [Parameter(Mandatory = `$true)]
        [hashtable]`$ImplementationResults,

        [Parameter(Mandatory = `$true)]
        [hashtable]`$TestResults,

        [Parameter(Mandatory = `$false)]
        [switch]`$Force
    )

    # CrÃ©er un fichier de sortie pour vÃ©rifier que la fonction a Ã©tÃ© appelÃ©e
    `$outputPath = Join-Path -Path "$testDir" -ChildPath "update-active-document-checkboxes-output.txt"
    @"
FilePath: `$FilePath
ImplementationResults: `$(`$ImplementationResults.Keys -join ", ")
TestResults: `$(`$TestResults.Keys -join ", ")
Force: `$Force
"@ | Set-Content -Path `$outputPath -Encoding UTF8

    # Retourner un rÃ©sultat simulÃ©
    return @{
        FilePath = `$FilePath
        CheckboxesUpdated = 2
        CheckboxesTotal = 3
    }
}

function Invoke-RoadmapGranularization {
    [CmdletBinding(SupportsShouldProcess = `$true)]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$FilePath,

        [Parameter(Mandatory = `$false)]
        [string]`$TaskIdentifier,

        [Parameter(Mandatory = `$false)]
        [string]`$SubTasksInput,

        [Parameter(Mandatory = `$false)]
        [ValidateSet("Spaces2", "Spaces4", "Tab", "Auto")]
        [string]`$IndentationStyle = "Auto",

        [Parameter(Mandatory = `$false)]
        [ValidateSet("GitHub", "Custom", "Auto")]
        [string]`$CheckboxStyle = "Auto"
    )

    # CrÃ©er un fichier de sortie pour vÃ©rifier que la fonction a Ã©tÃ© appelÃ©e
    `$outputPath = Join-Path -Path "$testDir" -ChildPath "invoke-roadmap-granularization-output.txt"
    @"
FilePath: `$FilePath
TaskIdentifier: `$TaskIdentifier
SubTasksInput: `$SubTasksInput
IndentationStyle: `$IndentationStyle
CheckboxStyle: `$CheckboxStyle
"@ | Set-Content -Path `$outputPath -Encoding UTF8

    # Simuler la modification du fichier de roadmap
    if (`$TaskIdentifier -and `$SubTasksInput) {
        `$content = Get-Content -Path `$FilePath -Encoding UTF8
        `$taskPattern = "- \[ \] \*\*`$TaskIdentifier\*\*"
        `$taskIndex = -1
        
        for (`$i = 0; `$i -lt `$content.Count; `$i++) {
            if (`$content[`$i] -match `$taskPattern) {
                `$taskIndex = `$i
                break
            }
        }
        
        if (`$taskIndex -ge 0) {
            `$subTasks = `$SubTasksInput -split "`n" | Where-Object { `$_ -match '\S' }
            `$indent = ""
            
            if (`$content[`$taskIndex] -match '^(\s+)') {
                `$indent = `$matches[1]
            }
            
            `$newContent = @()
            `$newContent += `$content[0..`$taskIndex]
            
            foreach (`$subTask in `$subTasks) {
                `$newContent += "`$indent  - [ ] `$subTask"
            }
            
            `$newContent += `$content[(`$taskIndex + 1)..(`$content.Count - 1)]
            
            `$newContent | Set-Content -Path `$FilePath -Encoding UTF8
        }
    }

    # Retourner un rÃ©sultat simulÃ©
    return @{
        FilePath = `$FilePath
        TaskIdentifier = `$TaskIdentifier
        SubTasksAdded = if (`$SubTasksInput) { (`$SubTasksInput -split "`n" | Where-Object { `$_ -match '\S' }).Count } else { 0 }
    }
}

function Split-RoadmapTask {
    [CmdletBinding(SupportsShouldProcess = `$true)]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$FilePath,

        [Parameter(Mandatory = `$true)]
        [string]`$TaskIdentifier,

        [Parameter(Mandatory = `$true)]
        [string[]]`$SubTasks,

        [Parameter(Mandatory = `$false)]
        [ValidateSet("Spaces2", "Spaces4", "Tab", "Auto")]
        [string]`$IndentationStyle = "Auto",

        [Parameter(Mandatory = `$false)]
        [ValidateSet("GitHub", "Custom", "Auto")]
        [string]`$CheckboxStyle = "Auto"
    )

    # CrÃ©er un fichier de sortie pour vÃ©rifier que la fonction a Ã©tÃ© appelÃ©e
    `$outputPath = Join-Path -Path "$testDir" -ChildPath "split-roadmap-task-output.txt"
    @"
FilePath: `$FilePath
TaskIdentifier: `$TaskIdentifier
SubTasks: `$(`$SubTasks -join ", ")
IndentationStyle: `$IndentationStyle
CheckboxStyle: `$CheckboxStyle
"@ | Set-Content -Path `$outputPath -Encoding UTF8

    # Simuler la modification du fichier de roadmap
    if (`$TaskIdentifier -and `$SubTasks) {
        `$content = Get-Content -Path `$FilePath -Encoding UTF8
        `$taskPattern = "- \[ \] \*\*`$TaskIdentifier\*\*"
        `$taskIndex = -1
        
        for (`$i = 0; `$i -lt `$content.Count; `$i++) {
            if (`$content[`$i] -match `$taskPattern) {
                `$taskIndex = `$i
                break
            }
        }
        
        if (`$taskIndex -ge 0) {
            `$indent = ""
            
            if (`$content[`$taskIndex] -match '^(\s+)') {
                `$indent = `$matches[1]
            }
            
            `$newContent = @()
            `$newContent += `$content[0..`$taskIndex]
            
            foreach (`$subTask in `$SubTasks) {
                `$newContent += "`$indent  - [ ] `$subTask"
            }
            
            `$newContent += `$content[(`$taskIndex + 1)..(`$content.Count - 1)]
            
            `$newContent | Set-Content -Path `$FilePath -Encoding UTF8
        }
    }

    # Retourner un rÃ©sultat simulÃ©
    return @{
        FilePath = `$FilePath
        TaskIdentifier = `$TaskIdentifier
        SubTasksAdded = `$SubTasks.Count
    }
}

Export-ModuleMember -Function Invoke-RoadmapCheck, Update-ActiveDocumentCheckboxes, Invoke-RoadmapGranularization, Split-RoadmapTask
"@ | Set-Content -Path $mockRoadmapParserModulePath -Encoding UTF8

# DÃ©finir les tests
Describe "Gestionnaire IntÃ©grÃ© avec Modes AdaptÃ©s" {
    BeforeAll {
        # CrÃ©er un mock pour Import-Module
        Mock Import-Module {
            # Ne rien faire, juste simuler l'importation
        } -ModuleName "Test-IntegratedManagerModes"
        
        # CrÃ©er un mock pour le module RoadmapParser
        Mock Import-Module {
            Import-Module $mockRoadmapParserModulePath -Force
        } -ParameterFilter { $Name -eq $modulePath }
    }
    
    Context "Mode CHECK via Gestionnaire IntÃ©grÃ©" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $outputPaths = @(
                (Join-Path -Path $testDir -ChildPath "invoke-roadmap-check-output.txt"),
                (Join-Path -Path $testDir -ChildPath "update-active-document-checkboxes-output.txt")
            )
            
            foreach ($path in $outputPaths) {
                if (Test-Path -Path $path) {
                    Remove-Item -Path $path -Force
                }
            }
        }
        
        It "Devrait exÃ©cuter le mode CHECK via le gestionnaire intÃ©grÃ©" {
            # ExÃ©cuter le gestionnaire intÃ©grÃ© avec le mode CHECK
            & $integratedManagerPath -Mode "CHECK" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath
            
            # VÃ©rifier que la fonction Invoke-RoadmapCheck a Ã©tÃ© appelÃ©e
            $outputPath = Join-Path -Path $testDir -ChildPath "invoke-roadmap-check-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "FilePath: $([regex]::Escape($testRoadmapPath))"
            $output | Should -Match "TaskIdentifier: 1.2.3"
        }
    }
    
    Context "Mode GRAN via Gestionnaire IntÃ©grÃ©" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $outputPaths = @(
                (Join-Path -Path $testDir -ChildPath "invoke-roadmap-granularization-output.txt"),
                (Join-Path -Path $testDir -ChildPath "split-roadmap-task-output.txt")
            )
            
            foreach ($path in $outputPaths) {
                if (Test-Path -Path $path) {
                    Remove-Item -Path $path -Force
                }
            }
            
            # RÃ©initialiser le fichier de roadmap de test
            @"
# Test Roadmap

## TÃ¢che 1.2.3

### Description
Cette tÃ¢che est utilisÃ©e pour les tests du gestionnaire intÃ©grÃ©.

### Sous-tÃ¢ches
- [ ] **1.2.3.1** Sous-tÃ¢che 1
- [ ] **1.2.3.2** Sous-tÃ¢che 2
- [ ] **1.2.3.3** Sous-tÃ¢che 3
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8
        }
        
        It "Devrait exÃ©cuter le mode GRAN via le gestionnaire intÃ©grÃ©" {
            # ExÃ©cuter le gestionnaire intÃ©grÃ© avec le mode GRAN
            & $integratedManagerPath -Mode "GRAN" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath
            
            # VÃ©rifier que la fonction Invoke-RoadmapGranularization a Ã©tÃ© appelÃ©e
            $outputPath = Join-Path -Path $testDir -ChildPath "invoke-roadmap-granularization-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "FilePath: $([regex]::Escape($testRoadmapPath))"
            $output | Should -Match "TaskIdentifier: 1.2.3"
        }
        
        It "Devrait exÃ©cuter le mode GRAN avec un fichier de sous-tÃ¢ches via le gestionnaire intÃ©grÃ©" {
            # ExÃ©cuter le gestionnaire intÃ©grÃ© avec le mode GRAN et un fichier de sous-tÃ¢ches
            & $integratedManagerPath -Mode "GRAN" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath -SubTasksFile $testSubTasksPath
            
            # VÃ©rifier que la fonction Invoke-RoadmapGranularization a Ã©tÃ© appelÃ©e
            $outputPath = Join-Path -Path $testDir -ChildPath "invoke-roadmap-granularization-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "FilePath: $([regex]::Escape($testRoadmapPath))"
            $output | Should -Match "TaskIdentifier: 1.2.3"
            $output | Should -Match "SubTasksInput:"
        }
    }
    
    Context "Workflow via Gestionnaire IntÃ©grÃ©" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $outputPaths = @(
                (Join-Path -Path $testDir -ChildPath "invoke-roadmap-check-output.txt"),
                (Join-Path -Path $testDir -ChildPath "update-active-document-checkboxes-output.txt"),
                (Join-Path -Path $testDir -ChildPath "invoke-roadmap-granularization-output.txt"),
                (Join-Path -Path $testDir -ChildPath "split-roadmap-task-output.txt")
            )
            
            foreach ($path in $outputPaths) {
                if (Test-Path -Path $path) {
                    Remove-Item -Path $path -Force
                }
            }
            
            # RÃ©initialiser le fichier de roadmap de test
            @"
# Test Roadmap

## TÃ¢che 1.2.3

### Description
Cette tÃ¢che est utilisÃ©e pour les tests du gestionnaire intÃ©grÃ©.

### Sous-tÃ¢ches
- [ ] **1.2.3.1** Sous-tÃ¢che 1
- [ ] **1.2.3.2** Sous-tÃ¢che 2
- [ ] **1.2.3.3** Sous-tÃ¢che 3
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8
        }
        
        It "Devrait exÃ©cuter le workflow Test via le gestionnaire intÃ©grÃ©" {
            # ExÃ©cuter le gestionnaire intÃ©grÃ© avec le workflow Test
            & $integratedManagerPath -Workflow "Test" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath
            
            # VÃ©rifier que les fonctions ont Ã©tÃ© appelÃ©es
            $checkOutputPath = Join-Path -Path $testDir -ChildPath "invoke-roadmap-check-output.txt"
            $granOutputPath = Join-Path -Path $testDir -ChildPath "invoke-roadmap-granularization-output.txt"
            
            Test-Path -Path $checkOutputPath | Should -Be $true
            Test-Path -Path $granOutputPath | Should -Be $true
            
            # VÃ©rifier le contenu des fichiers de sortie
            $checkOutput = Get-Content -Path $checkOutputPath -Raw
            $checkOutput | Should -Match "FilePath: $([regex]::Escape($testRoadmapPath))"
            $checkOutput | Should -Match "TaskIdentifier: 1.2.3"
            
            $granOutput = Get-Content -Path $granOutputPath -Raw
            $granOutput | Should -Match "FilePath: $([regex]::Escape($testRoadmapPath))"
            $granOutput | Should -Match "TaskIdentifier: 1.2.3"
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed



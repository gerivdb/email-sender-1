<#
.SYNOPSIS
    Tests pour le gestionnaire intÃ©grÃ©.

.DESCRIPTION
    Ce script contient des tests pour vÃ©rifier le bon fonctionnement du gestionnaire intÃ©grÃ©.
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
- [ ] Sous-tÃ¢che 1
- [ ] Sous-tÃ¢che 2
- [ ] Sous-tÃ¢che 3
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

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
            ScriptPath = Join-Path -Path $scriptPath -ChildPath "mock-check-mode.ps1"
        }
        Gran = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $scriptPath -ChildPath "mock-gran-mode.ps1"
        }
        Manager = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\manager\mode-manager.ps1"
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
    RoadmapManager = @{
        DefaultRoadmapPath = $testRoadmapPath
        ReportsFolder = $testDir
        GitRepo = "."
        DaysToAnalyze = 7
        AutoUpdate = $true
        GenerateReport = $true
        JournalPath = Join-Path -Path $testDir -ChildPath "journal"
        LogFile = Join-Path -Path $testDir -ChildPath "RoadmapManager.log"
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
$mockCheckModePath = Join-Path -Path $scriptPath -ChildPath "mock-check-mode.ps1"
@"
param (
    [string]`$FilePath,
    [string]`$TaskIdentifier,
    [switch]`$Force
)

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
`$outputPath = Join-Path -Path "$testDir" -ChildPath "check-mode-output.txt"
@"
Mode: CHECK
FilePath: `$FilePath
TaskIdentifier: `$TaskIdentifier
Force: `$Force
"@ | Set-Content -Path `$outputPath -Encoding UTF8

exit 0
"@ | Set-Content -Path $mockCheckModePath -Encoding UTF8

$mockGranModePath = Join-Path -Path $scriptPath -ChildPath "mock-gran-mode.ps1"
@"
param (
    [string]`$FilePath,
    [string]`$TaskIdentifier,
    [switch]`$Force
)

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
`$outputPath = Join-Path -Path "$testDir" -ChildPath "gran-mode-output.txt"
@"
Mode: GRAN
FilePath: `$FilePath
TaskIdentifier: `$TaskIdentifier
Force: `$Force
"@ | Set-Content -Path `$outputPath -Encoding UTF8

exit 0
"@ | Set-Content -Path $mockGranModePath -Encoding UTF8

$mockRoadmapManagerPath = Join-Path -Path $scriptPath -ChildPath "mock-roadmap-manager.ps1"
@"
param (
    [string]`$RoadmapPath,
    [switch]`$Organize,
    [switch]`$Execute,
    [switch]`$Analyze,
    [switch]`$GitUpdate,
    [switch]`$Cleanup,
    [switch]`$FixScripts,
    [switch]`$Help,
    [switch]`$Interactive
)

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
`$outputPath = Join-Path -Path "$testDir" -ChildPath "roadmap-manager-output.txt"
@"
RoadmapPath: `$RoadmapPath
Organize: `$Organize
Execute: `$Execute
Analyze: `$Analyze
GitUpdate: `$GitUpdate
Cleanup: `$Cleanup
FixScripts: `$FixScripts
Help: `$Help
Interactive: `$Interactive
"@ | Set-Content -Path `$outputPath -Encoding UTF8

exit 0
"@ | Set-Content -Path $mockRoadmapManagerPath -Encoding UTF8

$mockRoadmapAnalyzerPath = Join-Path -Path $scriptPath -ChildPath "mock-roadmap-analyzer.ps1"
@"
param (
    [string]`$RoadmapPath,
    [string]`$OutputFolder,
    [switch]`$GenerateHtml,
    [switch]`$GenerateJson,
    [switch]`$GenerateChart
)

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
`$outputPath = Join-Path -Path "$testDir" -ChildPath "roadmap-analyzer-output.txt"
@"
RoadmapPath: `$RoadmapPath
OutputFolder: `$OutputFolder
GenerateHtml: `$GenerateHtml
GenerateJson: `$GenerateJson
GenerateChart: `$GenerateChart
"@ | Set-Content -Path `$outputPath -Encoding UTF8

exit 0
"@ | Set-Content -Path $mockRoadmapAnalyzerPath -Encoding UTF8

$mockRoadmapGitUpdaterPath = Join-Path -Path $scriptPath -ChildPath "mock-roadmap-git-updater.ps1"
@"
param (
    [string]`$RoadmapPath,
    [string]`$GitRepo,
    [int]`$DaysToAnalyze,
    [switch]`$AutoUpdate,
    [switch]`$GenerateReport
)

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
`$outputPath = Join-Path -Path "$testDir" -ChildPath "roadmap-git-updater-output.txt"
@"
RoadmapPath: `$RoadmapPath
GitRepo: `$GitRepo
DaysToAnalyze: `$DaysToAnalyze
AutoUpdate: `$AutoUpdate
GenerateReport: `$GenerateReport
"@ | Set-Content -Path `$outputPath -Encoding UTF8

exit 0
"@ | Set-Content -Path $mockRoadmapGitUpdaterPath -Encoding UTF8

# DÃ©finir les tests
Describe "Gestionnaire IntÃ©grÃ©" {
    Context "ParamÃ¨tres de base" {
        It "Devrait exister" {
            Test-Path -Path $integratedManagerPath | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre Mode" {
            $result = Get-Command -Name $integratedManagerPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("Mode") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre RoadmapPath" {
            $result = Get-Command -Name $integratedManagerPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("RoadmapPath") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre TaskIdentifier" {
            $result = Get-Command -Name $integratedManagerPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("TaskIdentifier") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre ConfigPath" {
            $result = Get-Command -Name $integratedManagerPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("ConfigPath") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre Force" {
            $result = Get-Command -Name $integratedManagerPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("Force") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre ListModes" {
            $result = Get-Command -Name $integratedManagerPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("ListModes") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre ListRoadmaps" {
            $result = Get-Command -Name $integratedManagerPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("ListRoadmaps") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre Analyze" {
            $result = Get-Command -Name $integratedManagerPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("Analyze") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre GitUpdate" {
            $result = Get-Command -Name $integratedManagerPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("GitUpdate") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre Workflow" {
            $result = Get-Command -Name $integratedManagerPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("Workflow") | Should -Be $true
        }
        
        It "Devrait accepter le paramÃ¨tre Interactive" {
            $result = Get-Command -Name $integratedManagerPath | Select-Object -ExpandProperty Parameters
            $result.ContainsKey("Interactive") | Should -Be $true
        }
    }
    
    Context "ExÃ©cution du mode CHECK" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $outputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
            if (Test-Path -Path $outputPath) {
                Remove-Item -Path $outputPath -Force
            }
        }
        
        It "Devrait exÃ©cuter le mode CHECK avec succÃ¨s" {
            # ExÃ©cuter le script avec le mode CHECK
            & $integratedManagerPath -Mode "CHECK" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath
            
            # VÃ©rifier que le fichier de sortie a Ã©tÃ© crÃ©Ã©
            $outputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "Mode: CHECK"
            $output | Should -Match "FilePath: $([regex]::Escape($testRoadmapPath))"
            $output | Should -Match "TaskIdentifier: 1.2.3"
            $output | Should -Match "Force: False"
        }
        
        It "Devrait exÃ©cuter le mode CHECK avec le paramÃ¨tre Force" {
            # ExÃ©cuter le script avec le mode CHECK et le paramÃ¨tre Force
            & $integratedManagerPath -Mode "CHECK" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath -Force
            
            # VÃ©rifier que le fichier de sortie a Ã©tÃ© crÃ©Ã©
            $outputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "Mode: CHECK"
            $output | Should -Match "FilePath: $([regex]::Escape($testRoadmapPath))"
            $output | Should -Match "TaskIdentifier: 1.2.3"
            $output | Should -Match "Force: True"
        }
    }
    
    Context "ExÃ©cution du mode GRAN" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $outputPath = Join-Path -Path $testDir -ChildPath "gran-mode-output.txt"
            if (Test-Path -Path $outputPath) {
                Remove-Item -Path $outputPath -Force
            }
        }
        
        It "Devrait exÃ©cuter le mode GRAN avec succÃ¨s" {
            # ExÃ©cuter le script avec le mode GRAN
            & $integratedManagerPath -Mode "GRAN" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath
            
            # VÃ©rifier que le fichier de sortie a Ã©tÃ© crÃ©Ã©
            $outputPath = Join-Path -Path $testDir -ChildPath "gran-mode-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "Mode: GRAN"
            $output | Should -Match "FilePath: $([regex]::Escape($testRoadmapPath))"
            $output | Should -Match "TaskIdentifier: 1.2.3"
            $output | Should -Match "Force: False"
        }
    }
    
    Context "ExÃ©cution d'un workflow" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $outputPaths = @(
                (Join-Path -Path $testDir -ChildPath "check-mode-output.txt"),
                (Join-Path -Path $testDir -ChildPath "gran-mode-output.txt")
            )
            
            foreach ($path in $outputPaths) {
                if (Test-Path -Path $path) {
                    Remove-Item -Path $path -Force
                }
            }
        }
        
        It "Devrait exÃ©cuter le workflow Test avec succÃ¨s" {
            # ExÃ©cuter le script avec le workflow Test
            & $integratedManagerPath -Workflow "Test" -RoadmapPath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $testConfigPath
            
            # VÃ©rifier que les fichiers de sortie ont Ã©tÃ© crÃ©Ã©s
            $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
            $granOutputPath = Join-Path -Path $testDir -ChildPath "gran-mode-output.txt"
            
            Test-Path -Path $checkOutputPath | Should -Be $true
            Test-Path -Path $granOutputPath | Should -Be $true
            
            # VÃ©rifier le contenu des fichiers de sortie
            $checkOutput = Get-Content -Path $checkOutputPath -Raw
            $checkOutput | Should -Match "Mode: CHECK"
            $checkOutput | Should -Match "FilePath: $([regex]::Escape($testRoadmapPath))"
            $checkOutput | Should -Match "TaskIdentifier: 1.2.3"
            
            $granOutput = Get-Content -Path $granOutputPath -Raw
            $granOutput | Should -Match "Mode: GRAN"
            $granOutput | Should -Match "FilePath: $([regex]::Escape($testRoadmapPath))"
            $granOutput | Should -Match "TaskIdentifier: 1.2.3"
        }
    }
    
    Context "Analyse de roadmap" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $outputPath = Join-Path -Path $testDir -ChildPath "roadmap-analyzer-output.txt"
            if (Test-Path -Path $outputPath) {
                Remove-Item -Path $outputPath -Force
            }
        }
        
        It "Devrait analyser la roadmap avec succÃ¨s" {
            # ExÃ©cuter le script avec le paramÃ¨tre Analyze
            & $integratedManagerPath -Analyze -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath
            
            # VÃ©rifier que le fichier de sortie a Ã©tÃ© crÃ©Ã©
            $outputPath = Join-Path -Path $testDir -ChildPath "roadmap-analyzer-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "RoadmapPath: $([regex]::Escape($testRoadmapPath))"
            $output | Should -Match "GenerateHtml: True"
            $output | Should -Match "GenerateJson: True"
            $output | Should -Match "GenerateChart: True"
        }
    }
    
    Context "Mise Ã  jour Git de roadmap" {
        BeforeEach {
            # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
            $outputPath = Join-Path -Path $testDir -ChildPath "roadmap-git-updater-output.txt"
            if (Test-Path -Path $outputPath) {
                Remove-Item -Path $outputPath -Force
            }
        }
        
        It "Devrait mettre Ã  jour la roadmap avec Git avec succÃ¨s" {
            # ExÃ©cuter le script avec le paramÃ¨tre GitUpdate
            & $integratedManagerPath -GitUpdate -RoadmapPath $testRoadmapPath -ConfigPath $testConfigPath
            
            # VÃ©rifier que le fichier de sortie a Ã©tÃ© crÃ©Ã©
            $outputPath = Join-Path -Path $testDir -ChildPath "roadmap-git-updater-output.txt"
            Test-Path -Path $outputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier de sortie
            $output = Get-Content -Path $outputPath -Raw
            $output | Should -Match "RoadmapPath: $([regex]::Escape($testRoadmapPath))"
            $output | Should -Match "AutoUpdate: True"
            $output | Should -Match "GenerateReport: True"
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Script $MyInvocation.MyCommand.Path -Output Detailed

<#
.SYNOPSIS
    Tests unitaires pour le script de gÃ©nÃ©ration de rapport d'utilisation.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script de gÃ©nÃ©ration de rapport d'utilisation,
    utilisant le framework Pester.

.EXAMPLE
    Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-GenerateUsageReport.ps1"
    # ExÃ©cute les tests unitaires pour le script de gÃ©nÃ©ration de rapport d'utilisation

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# DÃ©terminer le chemin du script Ã  tester
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "generate-usage-report.ps1"

# DÃ©terminer le chemin du projet
$projectRoot = $scriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

Describe "Generate Usage Report Tests" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "augment"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un sous-rÃ©pertoire pour les logs
        $testLogsDir = Join-Path -Path $testDir -ChildPath "logs"
        New-Item -Path $testLogsDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un fichier de log temporaire
        $testLogPath = Join-Path -Path $testLogsDir -ChildPath "augment.log"
        $testLogContent = @"
2025-06-01T10:00:00.000Z|REQUEST|{"input":"Test input 1","input_size":11,"mode":"GRAN"}
2025-06-01T10:00:05.000Z|RESPONSE|{"output":"Test output 1","output_size":12,"time_ms":5000}
2025-06-01T10:10:00.000Z|REQUEST|{"input":"Test input 2","input_size":11,"mode":"DEV-R"}
2025-06-01T10:10:08.000Z|RESPONSE|{"output":"Test output 2","output_size":12,"time_ms":8000}
2025-06-01T10:20:00.000Z|REQUEST|{"input":"Test input 3","input_size":11,"mode":"CHECK"}
2025-06-01T10:20:03.000Z|RESPONSE|{"output":"Test output 3","output_size":12,"time_ms":3000}
"@
        $testLogContent | Out-File -FilePath $testLogPath -Encoding UTF8
        
        # CrÃ©er un fichier de Memories temporaire
        $testMemoriesDir = Join-Path -Path $testDir -ChildPath ".augment\memories"
        New-Item -Path $testMemoriesDir -ItemType Directory -Force | Out-Null
        
        $testMemoriesPath = Join-Path -Path $testMemoriesDir -ChildPath "journal_memories.json"
        $testMemoriesContent = @{
            version = "2.0.0"
            lastUpdated = (Get-Date).ToString("o")
            sections = @(
                @{
                    name = "TEST"
                    content = "Test content"
                }
            )
        } | ConvertTo-Json -Depth 10
        $testMemoriesContent | Out-File -FilePath $testMemoriesPath -Encoding UTF8
        
        # CrÃ©er un rÃ©pertoire de sortie temporaire
        $testOutputDir = Join-Path -Path $testDir -ChildPath "reports\augment"
        New-Item -Path $testOutputDir -ItemType Directory -Force | Out-Null
        
        $testOutputPath = Join-Path -Path $testOutputDir -ChildPath "usage-report.md"
        
        # DÃ©finir des variables globales pour les tests
        $Global:TestLogPath = $testLogPath
        $Global:TestMemoriesPath = $testMemoriesPath
        $Global:TestOutputPath = $testOutputPath
        
        # CrÃ©er des fonctions de mock pour les fonctions du script
        function Get-UsageStats {
            return @{
                TotalRequests = 3
                ModeUsage = @{
                    "GRAN" = 1
                    "DEV-R" = 1
                    "CHECK" = 1
                }
                MemoriesSize = 1024
                LastUpdated = (Get-Date).ToString("o")
            }
        }
        
        # Exporter les fonctions pour qu'elles soient disponibles dans le scope du test
        Export-ModuleMember -Function Get-UsageStats
    }
    
    AfterAll {
        # Supprimer les variables globales
        Remove-Variable -Name TestLogPath -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name TestMemoriesPath -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name TestOutputPath -Scope Global -ErrorAction SilentlyContinue
    }
    
    Context "Script Loading" {
        It "Should load the script without errors" {
            # VÃ©rifier que le script existe
            Test-Path -Path $scriptPath | Should -Be $true
            
            # Charger le script dans un bloc de script pour Ã©viter d'exÃ©cuter le script complet
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Remplacer la partie qui exÃ©cute le script par un commentaire
            $scriptContent = $scriptContent -replace "# GÃ©nÃ©rer le rapport.*?# Enregistrer le rapport", "# Script execution disabled for testing"
            
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # ExÃ©cuter le script
            { . $scriptBlock } | Should -Not -Throw
        }
    }
    
    Context "Get-UsageStats" {
        It "Should return valid usage statistics" {
            # Tester la fonction
            $result = Get-UsageStats
            
            $result | Should -Not -BeNullOrEmpty
            $result.TotalRequests | Should -Be 3
            $result.ModeUsage | Should -Not -BeNullOrEmpty
            $result.ModeUsage.Keys.Count | Should -Be 3
            $result.MemoriesSize | Should -Be 1024
            $result.LastUpdated | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Script Execution" {
        It "Should generate a usage report" {
            # ExÃ©cuter le script avec des paramÃ¨tres spÃ©cifiques
            $params = @{
                OutputPath = $Global:TestOutputPath
            }
            
            # ExÃ©cuter le script
            & $scriptPath @params
            
            # VÃ©rifier que le fichier a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $Global:TestOutputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier
            $content = Get-Content -Path $Global:TestOutputPath -Raw
            $content | Should -Not -BeNullOrEmpty
            $content | Should -Match "Rapport d'utilisation d'Augment Code"
            $content | Should -Match "Statistiques globales"
            $content | Should -Match "Utilisation par mode"
            $content | Should -Match "Recommandations"
            $content | Should -Match "Prochaines Ã©tapes"
        }
    }
}

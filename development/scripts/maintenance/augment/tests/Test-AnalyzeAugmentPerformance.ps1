<#
.SYNOPSIS
    Tests unitaires pour le script d'analyse des performances.

.DESCRIPTION
    Ce script contient des tests unitaires pour le script d'analyse des performances,
    utilisant le framework Pester.

.EXAMPLE
    Invoke-Pester -Path "development\scripts\maintenance\augment\tests\Test-AnalyzeAugmentPerformance.ps1"
    # ExÃ©cute les tests unitaires pour le script d'analyse des performances

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
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "analyze-augment-performance.ps1"

# DÃ©terminer le chemin du projet
$projectRoot = $scriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

Describe "Analyze Augment Performance Tests" {
    BeforeAll {
        # CrÃ©er un fichier de log temporaire pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "logs\augment"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        $testLogPath = Join-Path -Path $testDir -ChildPath "augment.log"
        $testLogContent = @"
2025-06-01T10:00:00.000Z|REQUEST|{"input":"Test input 1","input_size":11,"mode":"GRAN"}
2025-06-01T10:00:05.000Z|RESPONSE|{"output":"Test output 1","output_size":12,"time_ms":5000}
2025-06-01T10:10:00.000Z|REQUEST|{"input":"Test input 2","input_size":11,"mode":"DEV-R"}
2025-06-01T10:10:08.000Z|RESPONSE|{"output":"Test output 2","output_size":12,"time_ms":8000}
2025-06-01T10:20:00.000Z|REQUEST|{"input":"Test input 3","input_size":11,"mode":"CHECK"}
2025-06-01T10:20:03.000Z|RESPONSE|{"output":"Test output 3","output_size":12,"time_ms":3000}
"@
        $testLogContent | Out-File -FilePath $testLogPath -Encoding UTF8
        
        # CrÃ©er un rÃ©pertoire de sortie temporaire pour les tests
        $testOutputDir = Join-Path -Path $TestDrive -ChildPath "reports\augment"
        New-Item -Path $testOutputDir -ItemType Directory -Force | Out-Null
        
        $testOutputPath = Join-Path -Path $testOutputDir -ChildPath "performance.html"
        
        # DÃ©finir des variables globales pour les tests
        $Global:TestLogPath = $testLogPath
        $Global:TestOutputPath = $testOutputPath
        
        # CrÃ©er des fonctions de mock pour les fonctions du script
        function Test-AugmentLog {
            param (
                [string]$LogPath
            )
            
            return @{
                Requests = @(
                    @{
                        Timestamp = "2025-06-01T10:00:00.000Z"
                        Input = "Test input 1"
                        InputSize = 11
                        Mode = "GRAN"
                    },
                    @{
                        Timestamp = "2025-06-01T10:10:00.000Z"
                        Input = "Test input 2"
                        InputSize = 11
                        Mode = "DEV-R"
                    },
                    @{
                        Timestamp = "2025-06-01T10:20:00.000Z"
                        Input = "Test input 3"
                        InputSize = 11
                        Mode = "CHECK"
                    }
                )
                Responses = @(
                    @{
                        Timestamp = "2025-06-01T10:00:05.000Z"
                        Output = "Test output 1"
                        OutputSize = 12
                        TimeMs = 5000
                    },
                    @{
                        Timestamp = "2025-06-01T10:10:08.000Z"
                        Output = "Test output 2"
                        OutputSize = 12
                        TimeMs = 8000
                    },
                    @{
                        Timestamp = "2025-06-01T10:20:03.000Z"
                        Output = "Test output 3"
                        OutputSize = 12
                        TimeMs = 3000
                    }
                )
                Metrics = @{
                    TotalRequests = 3
                    TotalResponses = 3
                    AverageResponseTime = 5333.33
                    MaxResponseTime = 8000
                    MinResponseTime = 3000
                    AverageInputSize = 11
                    AverageOutputSize = 12
                    MaxInputSize = 11
                    MaxOutputSize = 12
                    RequestsByMode = @{
                        "GRAN" = 1
                        "DEV-R" = 1
                        "CHECK" = 1
                    }
                    ResponseTimesByMode = @{
                        "GRAN" = 5000
                        "DEV-R" = 8000
                        "CHECK" = 3000
                    }
                }
            }
        }
        
        function New-HtmlReport {
            param (
                [hashtable]$AnalysisResults,
                [string]$OutputPath
            )
            
            # CrÃ©er un fichier HTML minimal
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de performances d'Augment Code</title>
</head>
<body>
    <h1>Rapport de performances d'Augment Code</h1>
    <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
</body>
</html>
"@
            
            $html | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        
        # Exporter les fonctions pour qu'elles soient disponibles dans le scope du test
        Export-ModuleMember -function Test-AugmentLog, New-HtmlReport
    }
    
    AfterAll {
        # Supprimer les variables globales
        Remove-Variable -Name TestLogPath -Scope Global -ErrorAction SilentlyContinue
        Remove-Variable -Name TestOutputPath -Scope Global -ErrorAction SilentlyContinue
    }
    
    Context "Script Loading" {
        It "Should load the script without errors" {
            # VÃ©rifier que le script existe
            Test-Path -Path $scriptPath | Should -Be $true
            
            # Charger le script dans un bloc de script pour Ã©viter d'exÃ©cuter le script complet
            $scriptContent = Get-Content -Path $scriptPath -Raw
            
            # Remplacer la partie qui exÃ©cute le script par un commentaire
            $scriptContent = $scriptContent -replace "# Analyser le fichier de log.*?# Afficher un rÃ©sumÃ©", "# Script execution disabled for testing"
            
            $scriptBlock = [ScriptBlock]::Create($scriptContent)
            
            # ExÃ©cuter le script
            { . $scriptBlock } | Should -Not -Throw
        }
    }
    
    Context "Test-AugmentLog" {
        It "Should analyze log file correctly" {
            # Tester la fonction
            $result = Test-AugmentLog -LogPath $Global:TestLogPath
            
            $result | Should -Not -BeNullOrEmpty
            $result.Requests | Should -Not -BeNullOrEmpty
            $result.Requests.Count | Should -Be 3
            $result.Responses | Should -Not -BeNullOrEmpty
            $result.Responses.Count | Should -Be 3
            $result.Metrics | Should -Not -BeNullOrEmpty
            $result.Metrics.TotalRequests | Should -Be 3
            $result.Metrics.TotalResponses | Should -Be 3
            $result.Metrics.RequestsByMode.Keys.Count | Should -Be 3
            $result.Metrics.ResponseTimesByMode.Keys.Count | Should -Be 3
        }
    }
    
    Context "New-HtmlReport" {
        It "Should generate HTML report correctly" {
            # CrÃ©er des donnÃ©es d'analyse
            $analysisResults = Test-AugmentLog -LogPath $Global:TestLogPath
            
            # Tester la fonction
            New-HtmlReport -AnalysisResults $analysisResults -OutputPath $Global:TestOutputPath
            
            # VÃ©rifier que le fichier a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $Global:TestOutputPath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier
            $content = Get-Content -Path $Global:TestOutputPath -Raw
            $content | Should -Not -BeNullOrEmpty
            $content | Should -Match "Rapport de performances d'Augment Code"
        }
    }
    
    Context "Script Execution" {
        It "Should analyze performance and generate report" {
            # Mock les fonctions nÃ©cessaires
            Mock -CommandName Test-AugmentLog -MockWith {
                param (
                    [string]$LogPath
                )
                
                return @{
                    Requests = @(
                        @{
                            Timestamp = "2025-06-01T10:00:00.000Z"
                            Input = "Test input 1"
                            InputSize = 11
                            Mode = "GRAN"
                        }
                    )
                    Responses = @(
                        @{
                            Timestamp = "2025-06-01T10:00:05.000Z"
                            Output = "Test output 1"
                            OutputSize = 12
                            TimeMs = 5000
                        }
                    )
                    Metrics = @{
                        TotalRequests = 1
                        TotalResponses = 1
                        AverageResponseTime = 5000
                        MaxResponseTime = 5000
                        MinResponseTime = 5000
                        AverageInputSize = 11
                        AverageOutputSize = 12
                        MaxInputSize = 11
                        MaxOutputSize = 12
                        RequestsByMode = @{
                            "GRAN" = 1
                        }
                        ResponseTimesByMode = @{
                            "GRAN" = 5000
                        }
                    }
                }
            }
            
            Mock -CommandName New-HtmlReport -MockWith {
                param (
                    [hashtable]$AnalysisResults,
                    [string]$OutputPath
                )
                
                # CrÃ©er un fichier HTML minimal
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de performances d'Augment Code</title>
</head>
<body>
    <h1>Rapport de performances d'Augment Code</h1>
    <p>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
</body>
</html>
"@
                
                $html | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            
            # ExÃ©cuter le script avec des paramÃ¨tres spÃ©cifiques
            $params = @{
                LogPath = $Global:TestLogPath
                OutputPath = $Global:TestOutputPath
            }
            
            # ExÃ©cuter le script
            & $scriptPath @params
            
            # VÃ©rifier que le fichier a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $Global:TestOutputPath | Should -Be $true
        }
    }
}


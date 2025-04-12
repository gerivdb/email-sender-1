<#
.SYNOPSIS
    Version améliorée de TestOmnibus avec analyse de tendances, détection de tests flaky et optimisation avancée.
.DESCRIPTION
    Ce script exécute TestOmnibus avec des fonctionnalités améliorées, comme l'analyse
    des tendances, la détection des tests flaky, l'intégration avec SonarQube et
    l'optimisation avancée des tests.
.PARAMETER TestPath
    Chemin vers les tests à exécuter.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats des tests.
.PARAMETER HistoryPath
    Chemin vers l'historique des exécutions précédentes.
.PARAMETER DetectFlakyTests
    Active la détection des tests flaky.
.PARAMETER AnalyzeTrends
    Active l'analyse des tendances.
.PARAMETER UseSonarQube
    Active l'intégration avec SonarQube.
.PARAMETER SonarQubeUrl
    L'URL du serveur SonarQube.
.PARAMETER SonarQubeToken
    Le token d'authentification SonarQube.
.PARAMETER SonarQubeProjectKey
    La clé du projet SonarQube.
.PARAMETER UseAdvancedOptimization
    Active l'optimisation avancée des tests.
.EXAMPLE
    .\Invoke-EnhancedTestOmnibus.ps1 -TestPath "D:\Tests" -DetectFlakyTests -AnalyzeTrends
.EXAMPLE
    .\Invoke-EnhancedTestOmnibus.ps1 -TestPath "D:\Tests" -UseSonarQube -SonarQubeUrl "http://sonarqube.example.com" -SonarQubeToken "token" -SonarQubeProjectKey "testomnibus"
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TestPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results"),
    
    [Parameter(Mandatory = $false)]
    [string]$HistoryPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\History"),
    
    [Parameter(Mandatory = $false)]
    [switch]$DetectFlakyTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeTrends,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseSonarQube,
    
    [Parameter(Mandatory = $false)]
    [string]$SonarQubeUrl,
    
    [Parameter(Mandatory = $false)]
    [string]$SonarQubeToken,
    
    [Parameter(Mandatory = $false)]
    [string]$SonarQubeProjectKey,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseAdvancedOptimization
)

# Vérifier les chemins
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

# Créer les répertoires s'ils n'existent pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $HistoryPath)) {
    New-Item -Path $HistoryPath -ItemType Directory -Force | Out-Null
}

# Vérifier les paramètres SonarQube
if ($UseSonarQube) {
    if (-not $SonarQubeUrl -or -not $SonarQubeToken -or -not $SonarQubeProjectKey) {
        Write-Error "Pour utiliser SonarQube, vous devez spécifier SonarQubeUrl, SonarQubeToken et SonarQubeProjectKey."
        return 1
    }
}

# Fonction pour exécuter TestOmnibus
function Invoke-TestOmnibusWithConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestPath,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath
    )
    
    try {
        # Chemin vers TestOmnibus
        $testOmnibusPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"
        
        if (-not (Test-Path -Path $testOmnibusPath)) {
            Write-Error "TestOmnibus n'existe pas: $testOmnibusPath"
            return $null
        }
        
        # Exécuter TestOmnibus
        Write-Host "Exécution de TestOmnibus..." -ForegroundColor Cyan
        
        $testOmnibusParams = @{
            Path = $TestPath
        }
        
        if ($ConfigPath -and (Test-Path -Path $ConfigPath)) {
            $testOmnibusParams.Add("ConfigPath", $ConfigPath)
        }
        
        $result = & $testOmnibusPath @testOmnibusParams
        
        # Vérifier si des résultats ont été générés
        $resultsPath = Join-Path -Path $OutputPath -ChildPath "results.xml"
        if (-not (Test-Path -Path $resultsPath)) {
            Write-Error "Aucun résultat n'a été généré par TestOmnibus."
            return $null
        }
        
        return $resultsPath
    }
    catch {
        Write-Error "Erreur lors de l'exécution de TestOmnibus: $_"
        return $null
    }
}

# Fonction pour sauvegarder les résultats dans l'historique
function Save-ResultsToHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResultsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$HistoryPath
    )
    
    try {
        # Créer un nom de fichier unique
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $historyFile = Join-Path -Path $HistoryPath -ChildPath "results_$timestamp.xml"
        
        # Copier les résultats
        Copy-Item -Path $ResultsPath -Destination $historyFile -Force
        
        return $historyFile
    }
    catch {
        Write-Error "Erreur lors de la sauvegarde des résultats dans l'historique: $_"
        return $null
    }
}

# Point d'entrée principal
try {
    # Utiliser l'optimisation avancée si demandé
    $configPath = $null
    
    if ($UseAdvancedOptimization) {
        Write-Host "Utilisation de l'optimisation avancée..." -ForegroundColor Cyan
        $optimizerPath = Join-Path -Path $PSScriptRoot -ChildPath "Optimizers\Advanced-Optimizer.ps1"
        
        if (Test-Path -Path $optimizerPath) {
            $optimizationResult = & $optimizerPath -TestPath $TestPath -HistoryPath $HistoryPath -OutputPath $OutputPath
            
            if ($optimizationResult -and $optimizationResult.ConfigPath) {
                $configPath = $optimizationResult.ConfigPath
                Write-Host "Configuration optimisée générée: $configPath" -ForegroundColor Green
                Write-Host "Nombre de threads: $($optimizationResult.ThreadCount)" -ForegroundColor Green
                Write-Host "Nombre de tests: $($optimizationResult.TestCount)" -ForegroundColor Green
            }
            else {
                Write-Warning "L'optimisation avancée a échoué. Utilisation de la configuration par défaut."
            }
        }
        else {
            Write-Warning "Le script d'optimisation avancée n'existe pas: $optimizerPath"
        }
    }
    
    # Détecter les tests flaky si demandé
    if ($DetectFlakyTests) {
        Write-Host "Détection des tests flaky..." -ForegroundColor Cyan
        $flakyTestsPath = Join-Path -Path $PSScriptRoot -ChildPath "Manage-FlakyTests.ps1"
        
        if (Test-Path -Path $flakyTestsPath) {
            $flakyTestsResult = & $flakyTestsPath -TestPath $TestPath -OutputPath $OutputPath -Iterations 3 -GenerateReport -FixMode Retry -MaxRetries 3
            
            if ($flakyTestsResult -and $flakyTestsResult.FlakyTests) {
                Write-Host "Tests flaky détectés: $($flakyTestsResult.FlakyTests.Count)" -ForegroundColor Yellow
                
                if ($flakyTestsResult.ReportPath) {
                    Write-Host "Rapport des tests flaky généré: $($flakyTestsResult.ReportPath)" -ForegroundColor Green
                }
                
                if ($flakyTestsResult.ConfigPath) {
                    Write-Host "Configuration des tests flaky générée: $($flakyTestsResult.ConfigPath)" -ForegroundColor Green
                }
            }
            else {
                Write-Host "Aucun test flaky détecté." -ForegroundColor Green
            }
        }
        else {
            Write-Warning "Le script de détection des tests flaky n'existe pas: $flakyTestsPath"
        }
    }
    else {
        # Exécuter TestOmnibus normalement
        $resultsPath = Invoke-TestOmnibusWithConfig -TestPath $TestPath -ConfigPath $configPath
        
        if ($resultsPath) {
            Write-Host "Tests exécutés avec succès. Résultats enregistrés: $resultsPath" -ForegroundColor Green
            
            # Sauvegarder les résultats dans l'historique
            $historyFile = Save-ResultsToHistory -ResultsPath $resultsPath -HistoryPath $HistoryPath
            
            if ($historyFile) {
                Write-Host "Résultats sauvegardés dans l'historique: $historyFile" -ForegroundColor Green
            }
        }
    }
    
    # Analyser les tendances si demandé
    if ($AnalyzeTrends) {
        Write-Host "Analyse des tendances..." -ForegroundColor Cyan
        $trendsPath = Join-Path -Path $PSScriptRoot -ChildPath "Analyzers\Analyze-TestTrends.ps1"
        
        if (Test-Path -Path $trendsPath) {
            $trendsResult = & $trendsPath -HistoryPath $HistoryPath -OutputPath $OutputPath -DaysToAnalyze 30 -GenerateReport
            
            if ($trendsResult -and $trendsResult.ReportPath) {
                Write-Host "Rapport des tendances généré: $($trendsResult.ReportPath)" -ForegroundColor Green
                
                if ($trendsResult.FlakyTests) {
                    Write-Host "Tests instables détectés par l'analyse des tendances: $($trendsResult.FlakyTests.Count)" -ForegroundColor Yellow
                }
            }
        }
        else {
            Write-Warning "Le script d'analyse des tendances n'existe pas: $trendsPath"
        }
    }
    
    # Intégrer avec SonarQube si demandé
    if ($UseSonarQube) {
        Write-Host "Intégration avec SonarQube..." -ForegroundColor Cyan
        $sonarQubePath = Join-Path -Path $PSScriptRoot -ChildPath "Integrate-SonarQube.ps1"
        
        if (Test-Path -Path $sonarQubePath) {
            $sonarQubeResult = & $sonarQubePath -TestPath $TestPath -SourcePath (Split-Path -Path $TestPath -Parent) -SonarQubeUrl $SonarQubeUrl -SonarQubeToken $SonarQubeToken -ProjectKey $SonarQubeProjectKey -ProjectName $SonarQubeProjectKey -SimulationMode
            
            if ($sonarQubeResult -eq 0) {
                Write-Host "Intégration avec SonarQube réussie." -ForegroundColor Green
            }
            else {
                Write-Warning "L'intégration avec SonarQube a échoué."
            }
        }
        else {
            Write-Warning "Le script d'intégration avec SonarQube n'existe pas: $sonarQubePath"
        }
    }
    
    return 0
}
catch {
    Write-Error "Erreur lors de l'exécution de TestOmnibus amélioré: $_"
    return 1
}

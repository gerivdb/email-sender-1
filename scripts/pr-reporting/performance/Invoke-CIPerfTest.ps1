#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute des tests de performance dans un environnement CI/CD.
.DESCRIPTION
    Ce script est conçu pour être exécuté dans un pipeline CI/CD. Il exécute des tests
    de performance, compare les résultats avec une référence, et fait échouer le build
    si des régressions de performance sont détectées.
.PARAMETER BaselinePath
    Chemin vers le fichier JSON de résultats de référence. Si non spécifié, le script
    cherchera un fichier baseline.json dans le répertoire de sortie.
.PARAMETER OutputDir
    Répertoire où enregistrer les résultats des tests. Par défaut: "./perf-results".
.PARAMETER ThresholdPercent
    Pourcentage d'augmentation du temps de réponse considéré comme une régression.
    Par défaut: 10%.
.PARAMETER RpsThresholdPercent
    Pourcentage de diminution des requêtes par seconde considéré comme une régression.
    Par défaut: 10%.
.PARAMETER TestDuration
    Durée des tests en secondes. Par défaut: 30.
.PARAMETER Concurrency
    Nombre d'exécutions concurrentes. Par défaut: 3.
.PARAMETER UpdateBaseline
    Si spécifié, met à jour le fichier de référence avec les résultats actuels.
.PARAMETER GenerateReport
    Si spécifié, génère un rapport HTML des résultats.
.PARAMETER FailOnRegression
    Si spécifié, fait échouer le script si des régressions sont détectées.
.PARAMETER GitHubActions
    Si spécifié, génère des annotations pour GitHub Actions.
.PARAMETER AzureDevOps
    Si spécifié, génère des annotations pour Azure DevOps.
.EXAMPLE
    .\Invoke-CIPerfTest.ps1 -BaselinePath "baseline.json" -ThresholdPercent 5 -FailOnRegression
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$BaselinePath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = "./perf-results",
    
    [Parameter(Mandatory = $false)]
    [double]$ThresholdPercent = 10.0,
    
    [Parameter(Mandatory = $false)]
    [double]$RpsThresholdPercent = 10.0,
    
    [Parameter(Mandatory = $false)]
    [int]$TestDuration = 30,
    
    [Parameter(Mandatory = $false)]
    [int]$Concurrency = 3,
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateBaseline,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [switch]$FailOnRegression,
    
    [Parameter(Mandatory = $false)]
    [switch]$GitHubActions,
    
    [Parameter(Mandatory = $false)]
    [switch]$AzureDevOps
)

# Fonction pour créer une annotation GitHub Actions
function Write-GitHubAnnotation {
    param (
        [string]$Type,
        [string]$Message,
        [string]$File = "",
        [int]$Line = 0,
        [int]$Column = 0
    )
    
    if (-not $GitHubActions) {
        return
    }
    
    $annotation = "::$Type"
    
    if ($File -ne "") {
        $annotation += " file=$File"
        
        if ($Line -gt 0) {
            $annotation += ",line=$Line"
            
            if ($Column -gt 0) {
                $annotation += ",col=$Column"
            }
        }
    }
    
    $annotation += "::$Message"
    Write-Host $annotation
}

# Fonction pour créer une annotation Azure DevOps
function Write-AzureDevOpsAnnotation {
    param (
        [string]$Type,
        [string]$Message,
        [string]$File = "",
        [int]$Line = 0,
        [int]$Column = 0
    )
    
    if (-not $AzureDevOps) {
        return
    }
    
    $severity = switch ($Type) {
        "warning" { "warning" }
        "error" { "error" }
        default { "warning" }
    }
    
    $location = ""
    if ($File -ne "") {
        $location = "$File"
        
        if ($Line -gt 0) {
            $location += "($Line"
            
            if ($Column -gt 0) {
                $location += ",$Column"
            }
            
            $location += ")"
        }
    }
    
    if ($location -ne "") {
        Write-Host "##vso[task.logissue type=$severity;sourcepath=$File;linenumber=$Line;columnnumber=$Column]$Message"
    } else {
        Write-Host "##vso[task.logissue type=$severity]$Message"
    }
}

# Fonction pour écrire un message de log avec annotations CI/CD
function Write-CILog {
    param (
        [string]$Message,
        [string]$Type = "info",
        [string]$File = "",
        [int]$Line = 0,
        [int]$Column = 0
    )
    
    switch ($Type) {
        "info" {
            Write-Host $Message -ForegroundColor Cyan
        }
        "warning" {
            Write-Host $Message -ForegroundColor Yellow
            Write-GitHubAnnotation -Type "warning" -Message $Message -File $File -Line $Line -Column $Column
            Write-AzureDevOpsAnnotation -Type "warning" -Message $Message -File $File -Line $Line -Column $Column
        }
        "error" {
            Write-Host $Message -ForegroundColor Red
            Write-GitHubAnnotation -Type "error" -Message $Message -File $File -Line $Line -Column $Column
            Write-AzureDevOpsAnnotation -Type "error" -Message $Message -File $File -Line $Line -Column $Column
        }
        "success" {
            Write-Host $Message -ForegroundColor Green
        }
    }
}

# Fonction pour définir une variable de sortie GitHub Actions
function Set-GitHubOutput {
    param (
        [string]$Name,
        [string]$Value
    )
    
    if (-not $GitHubActions) {
        return
    }
    
    $githubOutput = $env:GITHUB_OUTPUT
    if ($githubOutput) {
        "$Name=$Value" | Out-File -FilePath $githubOutput -Encoding utf8 -Append
    } else {
        Write-Host "::set-output name=$Name::$Value"
    }
}

# Fonction pour définir une variable de sortie Azure DevOps
function Set-AzureDevOpsVariable {
    param (
        [string]$Name,
        [string]$Value
    )
    
    if (-not $AzureDevOps) {
        return
    }
    
    Write-Host "##vso[task.setvariable variable=$Name;isOutput=true]$Value"
}

# Fonction pour définir une variable de sortie CI
function Set-CIVariable {
    param (
        [string]$Name,
        [string]$Value
    )
    
    Set-GitHubOutput -Name $Name -Value $Value
    Set-AzureDevOpsVariable -Name $Name -Value $Value
}

# Fonction principale
function Main {
    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputDir)) {
        if ($PSCmdlet.ShouldProcess($OutputDir, "Créer le répertoire")) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
            Write-CILog "Répertoire de sortie créé: $OutputDir"
        }
    }
    
    # Définir les chemins des fichiers
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $currentResultsPath = Join-Path -Path $OutputDir -ChildPath "results_$timestamp.json"
    $summaryPath = Join-Path -Path $OutputDir -ChildPath "summary_$timestamp.md"
    $reportPath = Join-Path -Path $OutputDir -ChildPath "report_$timestamp.html"
    
    if (-not $BaselinePath) {
        $BaselinePath = Join-Path -Path $OutputDir -ChildPath "baseline.json"
        Write-CILog "Aucun fichier de référence spécifié, utilisation de: $BaselinePath"
    }
    
    # Exécuter les tests de performance
    Write-CILog "Exécution des tests de performance..."
    Write-CILog "  Durée: $TestDuration secondes"
    Write-CILog "  Concurrence: $Concurrency"
    
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Simple-PRLoadTest.ps1"
    
    if (-not (Test-Path -Path $scriptPath)) {
        Write-CILog "Script de test de performance non trouvé: $scriptPath" -Type "error"
        exit 1
    }
    
    try {
        & $scriptPath -Duration $TestDuration -Concurrency $Concurrency -OutputPath $currentResultsPath -Verbose
        
        if (-not (Test-Path -Path $currentResultsPath)) {
            Write-CILog "Les tests de performance n'ont pas généré de résultats." -Type "error"
            exit 1
        }
        
        Write-CILog "Tests de performance terminés. Résultats enregistrés: $currentResultsPath" -Type "success"
    }
    catch {
        Write-CILog "Erreur lors de l'exécution des tests de performance: $_" -Type "error"
        exit 1
    }
    
    # Charger les résultats actuels
    $currentResults = Get-Content -Path $currentResultsPath -Raw | ConvertFrom-Json
    
    # Vérifier si un fichier de référence existe
    $hasBaseline = Test-Path -Path $BaselinePath
    $comparisonResults = $null
    
    if ($hasBaseline) {
        Write-CILog "Comparaison avec le fichier de référence: $BaselinePath"
        
        try {
            $baselineResults = Get-Content -Path $BaselinePath -Raw | ConvertFrom-Json
            
            # Comparer les résultats
            $avgResponseTimeDiff = ($currentResults.AvgResponseMs - $baselineResults.AvgResponseMs) / $baselineResults.AvgResponseMs * 100
            $p95ResponseTimeDiff = ($currentResults.P95ResponseMs - $baselineResults.P95ResponseMs) / $baselineResults.P95ResponseMs * 100
            $rpsCurrentValue = if ($currentResults.PSObject.Properties.Name -contains "RequestsPerSecond") { $currentResults.RequestsPerSecond } else { $currentResults.TotalRequests / $currentResults.TotalExecTime }
            $rpsBaselineValue = if ($baselineResults.PSObject.Properties.Name -contains "RequestsPerSecond") { $baselineResults.RequestsPerSecond } else { $baselineResults.TotalRequests / $baselineResults.TotalExecTime }
            $rpsDiff = ($rpsCurrentValue - $rpsBaselineValue) / $rpsBaselineValue * 100
            
            $comparisonResults = [PSCustomObject]@{
                AvgResponseTimeDiff = $avgResponseTimeDiff
                P95ResponseTimeDiff = $p95ResponseTimeDiff
                RpsDiff = $rpsDiff
                HasRegression = $false
                Regressions = @()
            }
            
            # Vérifier les régressions
            if ($avgResponseTimeDiff -gt $ThresholdPercent) {
                $message = "Régression détectée: Temps de réponse moyen augmenté de $([Math]::Round($avgResponseTimeDiff, 2))% (seuil: $ThresholdPercent%)"
                Write-CILog $message -Type "warning"
                $comparisonResults.Regressions += $message
                $comparisonResults.HasRegression = $true
            }
            
            if ($p95ResponseTimeDiff -gt $ThresholdPercent) {
                $message = "Régression détectée: P95 augmenté de $([Math]::Round($p95ResponseTimeDiff, 2))% (seuil: $ThresholdPercent%)"
                Write-CILog $message -Type "warning"
                $comparisonResults.Regressions += $message
                $comparisonResults.HasRegression = $true
            }
            
            if ($rpsDiff -lt -$RpsThresholdPercent) {
                $message = "Régression détectée: Requêtes par seconde diminuées de $([Math]::Round(-$rpsDiff, 2))% (seuil: $RpsThresholdPercent%)"
                Write-CILog $message -Type "warning"
                $comparisonResults.Regressions += $message
                $comparisonResults.HasRegression = $true
            }
            
            if (-not $comparisonResults.HasRegression) {
                Write-CILog "Aucune régression détectée." -Type "success"
            }
        }
        catch {
            Write-CILog "Erreur lors de la comparaison des résultats: $_" -Type "error"
        }
    }
    else {
        Write-CILog "Aucun fichier de référence trouvé. Impossible de détecter les régressions."
    }
    
    # Mettre à jour le fichier de référence si demandé
    if ($UpdateBaseline -or (-not $hasBaseline)) {
        if ($PSCmdlet.ShouldProcess($BaselinePath, "Mettre à jour le fichier de référence")) {
            Copy-Item -Path $currentResultsPath -Destination $BaselinePath -Force
            Write-CILog "Fichier de référence mis à jour: $BaselinePath" -Type "success"
        }
    }
    
    # Générer un rapport HTML si demandé
    if ($GenerateReport) {
        Write-CILog "Génération du rapport HTML..."
        
        $reportScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "New-PerformanceReport.ps1"
        
        if (Test-Path -Path $reportScriptPath) {
            try {
                if ($hasBaseline) {
                    & $reportScriptPath -ResultsPath @($BaselinePath, $currentResultsPath) -OutputPath $reportPath -Title "Rapport de performance CI/CD" -CompareMode
                }
                else {
                    & $reportScriptPath -ResultsPath $currentResultsPath -OutputPath $reportPath -Title "Rapport de performance CI/CD"
                }
                
                Write-CILog "Rapport HTML généré: $reportPath" -Type "success"
            }
            catch {
                Write-CILog "Erreur lors de la génération du rapport HTML: $_" -Type "error"
            }
        }
        else {
            Write-CILog "Script de génération de rapport non trouvé: $reportScriptPath" -Type "warning"
        }
    }
    
    # Générer un résumé Markdown
    $summary = @"
# Résumé des tests de performance

Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Configuration

- Durée: $TestDuration secondes
- Concurrence: $Concurrency
- Seuil de régression (temps de réponse): $ThresholdPercent%
- Seuil de régression (RPS): $RpsThresholdPercent%

## Résultats actuels

- Requêtes totales: $($currentResults.TotalRequests)
- Requêtes par seconde: $([Math]::Round($currentResults.RequestsPerSecond, 2))
- Temps de réponse moyen: $([Math]::Round($currentResults.AvgResponseMs, 2)) ms
- P95: $([Math]::Round($currentResults.P95ResponseMs, 2)) ms

"@

    if ($comparisonResults) {
        $summary += @"
## Comparaison avec la référence

- Différence de temps de réponse moyen: $([Math]::Round($comparisonResults.AvgResponseTimeDiff, 2))%
- Différence de P95: $([Math]::Round($comparisonResults.P95ResponseTimeDiff, 2))%
- Différence de requêtes par seconde: $([Math]::Round($comparisonResults.RpsDiff, 2))%

"@

        if ($comparisonResults.HasRegression) {
            $summary += "## Régressions détectées\n\n"
            
            foreach ($regression in $comparisonResults.Regressions) {
                $summary += "- $regression\n"
            }
        }
        else {
            $summary += "## Aucune régression détectée\n"
        }
    }
    
    $summary += @"

## Fichiers générés

- Résultats: $currentResultsPath
"@

    if ($GenerateReport) {
        $summary += @"
- Rapport HTML: $reportPath
"@
    }
    
    $summary | Set-Content -Path $summaryPath -Encoding UTF8
    Write-CILog "Résumé généré: $summaryPath"
    
    # Définir les variables de sortie CI
    Set-CIVariable -Name "perf_test_results_path" -Value $currentResultsPath
    Set-CIVariable -Name "perf_test_summary_path" -Value $summaryPath
    
    if ($GenerateReport) {
        Set-CIVariable -Name "perf_test_report_path" -Value $reportPath
    }
    
    if ($comparisonResults -and $comparisonResults.HasRegression) {
        Set-CIVariable -Name "perf_test_has_regression" -Value "true"
        
        if ($FailOnRegression) {
            Write-CILog "Des régressions de performance ont été détectées. Le pipeline a échoué." -Type "error"
            exit 1
        }
    }
    else {
        Set-CIVariable -Name "perf_test_has_regression" -Value "false"
    }
    
    Write-CILog "Tests de performance CI/CD terminés avec succès." -Type "success"
}

# Exécuter le script
Main

<#
.SYNOPSIS
    Suggère des refactorisations intelligentes basées sur l'analyse d'usage.
.DESCRIPTION
    Ce script analyse les données d'utilisation et la structure du code pour
    suggérer des refactorisations qui amélioreraient les performances et la maintenabilité.
.PARAMETER DatabasePath
    Chemin vers le fichier de base de données d'utilisation.
.PARAMETER OutputPath
    Chemin où les suggestions seront enregistrées.
.EXAMPLE
    .\Suggest-Refactoring.ps1 -OutputPath "C:\Refactoring"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$DatabasePath = (Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\usage_data.xml"),
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\Refactoring")
)

# Importer le module UsageMonitor
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "UsageMonitor.psm1"
Import-Module $modulePath -Force

# Fonction pour écrire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
}

# Fonction pour analyser la complexité du code
function Analyze-CodeComplexity {
    param (
        [string]$ScriptPath
    )
    
    try {
        $content = Get-Content -Path $ScriptPath -Raw -ErrorAction Stop
        
        # Analyser avec PSScriptAnalyzer si disponible
        $psaResults = $null
        if (Get-Module -Name PSScriptAnalyzer -ListAvailable) {
            Import-Module PSScriptAnalyzer -Force
            $psaResults = Invoke-ScriptAnalyzer -Path $ScriptPath -Severity Error, Warning, Information
        }
        
        # Métriques de base
        $metrics = @{
            LineCount = ($content -split "`r`n|\r|\n").Count
            FunctionCount = ([regex]::Matches($content, "function\s+\w+")).Count
            ParameterCount = ([regex]::Matches($content, "param\s*\(")).Count
            IfStatementCount = ([regex]::Matches($content, "\sif\s*\(")).Count
            ForEachCount = ([regex]::Matches($content, "foreach|ForEach-Object")).Count
            TryCatchCount = ([regex]::Matches($content, "try\s*\{")).Count
            CommentCount = ([regex]::Matches($content, "^\s*#|<#|##")).Count
            PSAIssues = if ($psaResults) { $psaResults.Count } else { 0 }
            PSADetails = $psaResults
        }
        
        # Calculer la complexité cyclomatique approximative
        $metrics.CyclomaticComplexity = $metrics.IfStatementCount + $metrics.ForEachCount + $metrics.TryCatchCount + 1
        
        return $metrics
    }
    catch {
        Write-Log "Erreur lors de l'analyse de la complexité du code pour $ScriptPath : $_" -Level "ERROR"
        return $null
    }
}

# Fonction pour générer des suggestions de refactorisation
function Generate-RefactoringSuggestions {
    param (
        [PSCustomObject]$UsageStats,
        [hashtable]$ComplexityData
    )
    
    $suggestions = @()
    
    # Analyser les scripts lents
    foreach ($scriptPath in $UsageStats.SlowestScripts.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $avgDuration = $UsageStats.SlowestScripts[$scriptPath]
        $complexity = $ComplexityData[$scriptPath]
        
        if ($complexity) {
            $suggestion = [PSCustomObject]@{
                ScriptPath = $scriptPath
                ScriptName = $scriptName
                Type = "Performance"
                Priority = "High"
                Issue = "Script lent avec durée moyenne d'exécution de $([math]::Round($avgDuration, 2)) ms"
                Suggestions = @()
                Metrics = $complexity
                Justification = "Ce script est parmi les plus lents du système"
            }
            
            # Ajouter des suggestions spécifiques basées sur la complexité
            if ($complexity.CyclomaticComplexity -gt 15) {
                $suggestion.Suggestions += "Réduire la complexité cyclomatique ($($complexity.CyclomaticComplexity)) en divisant les fonctions complexes"
            }
            
            if ($complexity.ForEachCount -gt 5) {
                $suggestion.Suggestions += "Optimiser les boucles foreach ($($complexity.ForEachCount)) en utilisant des techniques de traitement par lots"
            }
            
            if ($complexity.LineCount -gt 300) {
                $suggestion.Suggestions += "Diviser le script en modules plus petits (actuellement $($complexity.LineCount) lignes)"
            }
            
            if ($complexity.PSAIssues -gt 0) {
                $suggestion.Suggestions += "Corriger les $($complexity.PSAIssues) problèmes identifiés par PSScriptAnalyzer"
            }
            
            $suggestions += $suggestion
        }
    }
    
    # Analyser les scripts avec beaucoup d'échecs
    foreach ($scriptPath in $UsageStats.MostFailingScripts.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $failureRate = $UsageStats.MostFailingScripts[$scriptPath]
        $complexity = $ComplexityData[$scriptPath]
        
        if ($complexity -and $failureRate -gt 10) {  # Plus de 10% d'échecs
            $suggestion = [PSCustomObject]@{
                ScriptPath = $scriptPath
                ScriptName = $scriptName
                Type = "Reliability"
                Priority = "High"
                Issue = "Taux d'échec élevé de $([math]::Round($failureRate, 2))%"
                Suggestions = @()
                Metrics = $complexity
                Justification = "Ce script échoue fréquemment, ce qui affecte la fiabilité du système"
            }
            
            # Ajouter des suggestions spécifiques
            if ($complexity.TryCatchCount -lt 3) {
                $suggestion.Suggestions += "Améliorer la gestion des erreurs (seulement $($complexity.TryCatchCount) blocs try-catch)"
            }
            
            $suggestion.Suggestions += "Ajouter des validations d'entrée plus strictes"
            $suggestion.Suggestions += "Implémenter des mécanismes de reprise après échec"
            
            $suggestions += $suggestion
        }
    }
    
    # Analyser les scripts intensifs en ressources
    foreach ($scriptPath in $UsageStats.ResourceIntensiveScripts.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $memoryUsage = $UsageStats.ResourceIntensiveScripts[$scriptPath]
        $complexity = $ComplexityData[$scriptPath]
        
        if ($complexity -and $memoryUsage -gt 50 * 1024 * 1024) {  # Plus de 50 Mo
            $suggestion = [PSCustomObject]@{
                ScriptPath = $scriptPath
                ScriptName = $scriptName
                Type = "ResourceOptimization"
                Priority = "Medium"
                Issue = "Utilisation élevée de mémoire: $([math]::Round($memoryUsage / 1MB, 2)) Mo"
                Suggestions = @()
                Metrics = $complexity
                Justification = "Ce script consomme beaucoup de ressources mémoire"
            }
            
            # Ajouter des suggestions spécifiques
            $suggestion.Suggestions += "Optimiser l'utilisation de la mémoire en traitant les données par lots"
            $suggestion.Suggestions += "Libérer explicitement les ressources avec [System.GC]::Collect()"
            $suggestion.Suggestions += "Utiliser des structures de données plus efficaces"
            
            $suggestions += $suggestion
        }
    }
    
    # Analyser les scripts complexes mais peu utilisés (candidats pour la simplification)
    foreach ($scriptPath in $ComplexityData.Keys) {
        $complexity = $ComplexityData[$scriptPath]
        $scriptName = Split-Path -Path $scriptPath -Leaf
        
        # Vérifier si le script est peu utilisé
        $isRarelyUsed = -not $UsageStats.TopUsedScripts.ContainsKey($scriptPath)
        
        if ($isRarelyUsed -and $complexity.CyclomaticComplexity -gt 20) {
            $suggestion = [PSCustomObject]@{
                ScriptPath = $scriptPath
                ScriptName = $scriptName
                Type = "Simplification"
                Priority = "Low"
                Issue = "Script complexe ($($complexity.CyclomaticComplexity) complexité) mais rarement utilisé"
                Suggestions = @()
                Metrics = $complexity
                Justification = "Ce script est complexe mais peu utilisé, ce qui suggère un potentiel de simplification"
            }
            
            $suggestion.Suggestions += "Évaluer si toutes les fonctionnalités sont nécessaires"
            $suggestion.Suggestions += "Simplifier la logique ou diviser en composants plus petits"
            
            $suggestions += $suggestion
        }
    }
    
    return $suggestions
}

# Fonction pour générer un rapport HTML
function Generate-HtmlReport {
    param (
        [PSCustomObject[]]$Suggestions,
        [string]$OutputPath
    )
    
    $reportPath = Join-Path -Path $OutputPath -ChildPath "refactoring_suggestions.html"
    
    $htmlHeader = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Suggestions de Refactorisation</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
            border-radius: 5px;
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            text-align: center;
            padding-bottom: 10px;
            border-bottom: 2px solid #eee;
        }
        h2 {
            margin-top: 30px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        .suggestion {
            margin-bottom: 30px;
            padding: 15px;
            border-left: 4px solid #3498db;
            background-color: #f8f9fa;
        }
        .high {
            border-left-color: #e74c3c;
        }
        .medium {
            border-left-color: #f39c12;
        }
        .low {
            border-left-color: #2ecc71;
        }
        .suggestion-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        .suggestion-title {
            font-weight: bold;
            font-size: 1.1em;
        }
        .suggestion-priority {
            padding: 3px 8px;
            border-radius: 3px;
            color: white;
            font-size: 0.8em;
        }
        .priority-high {
            background-color: #e74c3c;
        }
        .priority-medium {
            background-color: #f39c12;
        }
        .priority-low {
            background-color: #2ecc71;
        }
        .suggestion-details {
            margin-top: 10px;
        }
        .suggestion-list {
            margin-top: 10px;
            padding-left: 20px;
        }
        .metrics {
            margin-top: 15px;
            font-size: 0.9em;
            color: #7f8c8d;
        }
        .metrics-title {
            font-weight: bold;
            margin-bottom: 5px;
        }
        .metrics-list {
            display: flex;
            flex-wrap: wrap;
        }
        .metric {
            margin-right: 15px;
            margin-bottom: 5px;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 10px;
            border-top: 1px solid #eee;
            color: #7f8c8d;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Suggestions de Refactorisation</h1>
        <p>Généré le $(Get-Date -Format "dd/MM/yyyy à HH:mm:ss")</p>
"@
    
    $htmlFooter = @"
        <div class="footer">
            <p>Généré par le module UsageMonitor</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Générer le contenu HTML
    $htmlContent = $htmlHeader
    
    # Regrouper les suggestions par priorité
    $highPriority = $Suggestions | Where-Object { $_.Priority -eq "High" }
    $mediumPriority = $Suggestions | Where-Object { $_.Priority -eq "Medium" }
    $lowPriority = $Suggestions | Where-Object { $_.Priority -eq "Low" }
    
    # Section des suggestions de haute priorité
    if ($highPriority.Count -gt 0) {
        $htmlContent += "<h2>Suggestions de Haute Priorité</h2>"
        
        foreach ($suggestion in $highPriority) {
            $htmlContent += @"
<div class="suggestion high">
    <div class="suggestion-header">
        <div class="suggestion-title">$($suggestion.ScriptName): $($suggestion.Issue)</div>
        <div class="suggestion-priority priority-high">$($suggestion.Priority)</div>
    </div>
    <div class="suggestion-details">
        <p><strong>Type:</strong> $($suggestion.Type)</p>
        <p><strong>Justification:</strong> $($suggestion.Justification)</p>
        <p><strong>Suggestions:</strong></p>
        <ul class="suggestion-list">
"@
            
            foreach ($item in $suggestion.Suggestions) {
                $htmlContent += "<li>$item</li>"
            }
            
            $htmlContent += @"
        </ul>
        <div class="metrics">
            <div class="metrics-title">Métriques:</div>
            <div class="metrics-list">
                <div class="metric"><strong>Lignes:</strong> $($suggestion.Metrics.LineCount)</div>
                <div class="metric"><strong>Fonctions:</strong> $($suggestion.Metrics.FunctionCount)</div>
                <div class="metric"><strong>Complexité:</strong> $($suggestion.Metrics.CyclomaticComplexity)</div>
                <div class="metric"><strong>Issues PSA:</strong> $($suggestion.Metrics.PSAIssues)</div>
            </div>
        </div>
    </div>
</div>
"@
        }
    }
    
    # Section des suggestions de priorité moyenne
    if ($mediumPriority.Count -gt 0) {
        $htmlContent += "<h2>Suggestions de Priorité Moyenne</h2>"
        
        foreach ($suggestion in $mediumPriority) {
            $htmlContent += @"
<div class="suggestion medium">
    <div class="suggestion-header">
        <div class="suggestion-title">$($suggestion.ScriptName): $($suggestion.Issue)</div>
        <div class="suggestion-priority priority-medium">$($suggestion.Priority)</div>
    </div>
    <div class="suggestion-details">
        <p><strong>Type:</strong> $($suggestion.Type)</p>
        <p><strong>Justification:</strong> $($suggestion.Justification)</p>
        <p><strong>Suggestions:</strong></p>
        <ul class="suggestion-list">
"@
            
            foreach ($item in $suggestion.Suggestions) {
                $htmlContent += "<li>$item</li>"
            }
            
            $htmlContent += @"
        </ul>
        <div class="metrics">
            <div class="metrics-title">Métriques:</div>
            <div class="metrics-list">
                <div class="metric"><strong>Lignes:</strong> $($suggestion.Metrics.LineCount)</div>
                <div class="metric"><strong>Fonctions:</strong> $($suggestion.Metrics.FunctionCount)</div>
                <div class="metric"><strong>Complexité:</strong> $($suggestion.Metrics.CyclomaticComplexity)</div>
                <div class="metric"><strong>Issues PSA:</strong> $($suggestion.Metrics.PSAIssues)</div>
            </div>
        </div>
    </div>
</div>
"@
        }
    }
    
    # Section des suggestions de basse priorité
    if ($lowPriority.Count -gt 0) {
        $htmlContent += "<h2>Suggestions de Basse Priorité</h2>"
        
        foreach ($suggestion in $lowPriority) {
            $htmlContent += @"
<div class="suggestion low">
    <div class="suggestion-header">
        <div class="suggestion-title">$($suggestion.ScriptName): $($suggestion.Issue)</div>
        <div class="suggestion-priority priority-low">$($suggestion.Priority)</div>
    </div>
    <div class="suggestion-details">
        <p><strong>Type:</strong> $($suggestion.Type)</p>
        <p><strong>Justification:</strong> $($suggestion.Justification)</p>
        <p><strong>Suggestions:</strong></p>
        <ul class="suggestion-list">
"@
            
            foreach ($item in $suggestion.Suggestions) {
                $htmlContent += "<li>$item</li>"
            }
            
            $htmlContent += @"
        </ul>
        <div class="metrics">
            <div class="metrics-title">Métriques:</div>
            <div class="metrics-list">
                <div class="metric"><strong>Lignes:</strong> $($suggestion.Metrics.LineCount)</div>
                <div class="metric"><strong>Fonctions:</strong> $($suggestion.Metrics.FunctionCount)</div>
                <div class="metric"><strong>Complexité:</strong> $($suggestion.Metrics.CyclomaticComplexity)</div>
                <div class="metric"><strong>Issues PSA:</strong> $($suggestion.Metrics.PSAIssues)</div>
            </div>
        </div>
    </div>
</div>
"@
        }
    }
    
    $htmlContent += $htmlFooter
    
    # Écrire le rapport HTML
    $htmlContent | Out-File -FilePath $reportPath -Encoding utf8 -Force
    
    return $reportPath
}

# Point d'entrée principal
Write-Log "Démarrage de l'analyse pour les suggestions de refactorisation..." -Level "TITLE"

# Vérifier si le fichier de base de données existe
if (-not (Test-Path -Path $DatabasePath)) {
    Write-Log "Le fichier de base de données spécifié n'existe pas: $DatabasePath" -Level "ERROR"
    exit 1
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Log "Répertoire de sortie créé: $OutputPath" -Level "INFO"
}

# Initialiser le moniteur d'utilisation avec la base de données spécifiée
Initialize-UsageMonitor -DatabasePath $DatabasePath
Write-Log "Base de données d'utilisation chargée: $DatabasePath" -Level "INFO"

# Récupérer les statistiques d'utilisation
$usageStats = Get-ScriptUsageStatistics
Write-Log "Statistiques d'utilisation récupérées" -Level "INFO"

# Collecter les scripts à analyser
$scriptsToAnalyze = @()
$scriptsToAnalyze += $usageStats.TopUsedScripts.Keys
$scriptsToAnalyze += $usageStats.SlowestScripts.Keys
$scriptsToAnalyze += $usageStats.MostFailingScripts.Keys
$scriptsToAnalyze += $usageStats.ResourceIntensiveScripts.Keys

# Éliminer les doublons
$scriptsToAnalyze = $scriptsToAnalyze | Select-Object -Unique

Write-Log "Nombre de scripts à analyser: $($scriptsToAnalyze.Count)" -Level "INFO"

# Analyser la complexité du code
$complexityData = @{}

foreach ($scriptPath in $scriptsToAnalyze) {
    Write-Log "Analyse de la complexité du code pour: $(Split-Path -Path $scriptPath -Leaf)" -Level "INFO"
    $complexity = Analyze-CodeComplexity -ScriptPath $scriptPath
    
    if ($complexity) {
        $complexityData[$scriptPath] = $complexity
    }
}

Write-Log "Analyse de la complexité terminée pour $($complexityData.Count) scripts" -Level "INFO"

# Générer des suggestions de refactorisation
$suggestions = Generate-RefactoringSuggestions -UsageStats $usageStats -ComplexityData $complexityData
Write-Log "Suggestions de refactorisation générées: $($suggestions.Count) suggestions" -Level "INFO"

# Générer un rapport HTML
$reportPath = Generate-HtmlReport -Suggestions $suggestions -OutputPath $OutputPath
Write-Log "Rapport de suggestions généré: $reportPath" -Level "SUCCESS"

# Générer un rapport JSON
$jsonPath = Join-Path -Path $OutputPath -ChildPath "refactoring_suggestions.json"
$suggestions | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding utf8 -Force
Write-Log "Rapport JSON généré: $jsonPath" -Level "SUCCESS"

Write-Log "Analyse pour les suggestions de refactorisation terminée." -Level "TITLE"

# Ouvrir le rapport HTML
Start-Process $reportPath

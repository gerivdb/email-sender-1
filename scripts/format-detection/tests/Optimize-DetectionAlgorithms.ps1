#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise les algorithmes de détection de format en fonction des résultats de test.

.DESCRIPTION
    Ce script analyse les résultats des tests de détection de format et propose des
    optimisations pour améliorer la précision de la détection. Il identifie les cas
    problématiques, ajuste les critères de détection et améliore les algorithmes
    de résolution des cas ambigus.

.PARAMETER AccuracyReportPath
    Le chemin vers le rapport JSON de précision de détection.
    Par défaut, utilise 'reports\DetectionAccuracy.json' dans le répertoire du script.

.PARAMETER CriteriaPath
    Le chemin vers le fichier JSON contenant les critères de détection.
    Par défaut, utilise '..\analysis\FormatDetectionCriteria.json'.

.PARAMETER OutputCriteriaPath
    Le chemin où enregistrer les critères optimisés.
    Par défaut, utilise '..\analysis\OptimizedFormatDetectionCriteria.json'.

.PARAMETER GenerateReport
    Indique si un rapport d'optimisation doit être généré.

.PARAMETER ReportPath
    Le chemin où enregistrer le rapport d'optimisation.
    Par défaut, utilise 'reports\OptimizationReport.html'.

.EXAMPLE
    .\Optimize-DetectionAlgorithms.ps1 -GenerateReport

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$AccuracyReportPath = (Join-Path -Path $PSScriptRoot -ChildPath "reports\DetectionAccuracy.json"),
    
    [Parameter()]
    [string]$CriteriaPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\analysis\FormatDetectionCriteria.json"),
    
    [Parameter()]
    [string]$OutputCriteriaPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\analysis\OptimizedFormatDetectionCriteria.json"),
    
    [Parameter()]
    [switch]$GenerateReport,
    
    [Parameter()]
    [string]$ReportPath = (Join-Path -Path $PSScriptRoot -ChildPath "reports\OptimizationReport.html")
)

# Fonction pour créer un répertoire s'il n'existe pas
function New-DirectoryIfNotExists {
    param (
        [string]$Path
    )
    
    $directory = [System.IO.Path]::GetDirectoryName($Path)
    
    if (-not (Test-Path -Path $directory -PathType Container)) {
        New-Item -Path $directory -ItemType Directory -Force | Out-Null
        Write-Verbose "Répertoire créé : $directory"
    }
}

# Fonction pour charger le rapport de précision
function Get-AccuracyReport {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le rapport de précision '$Path' n'existe pas."
        return $null
    }
    
    try {
        $report = Get-Content -Path $Path -Raw | ConvertFrom-Json
        return $report
    }
    catch {
        Write-Error "Erreur lors du chargement du rapport de précision : $_"
        return $null
    }
}

# Fonction pour charger les critères de détection
function Get-DetectionCriteria {
    param (
        [string]$Path
    )
    
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier des critères de détection '$Path' n'existe pas."
        return $null
    }
    
    try {
        $criteria = Get-Content -Path $Path -Raw | ConvertFrom-Json
        return $criteria
    }
    catch {
        Write-Error "Erreur lors du chargement des critères de détection : $_"
        return $null
    }
}

# Fonction pour identifier les cas problématiques
function Get-ProblematicCases {
    param (
        [PSCustomObject]$Report
    )
    
    $problematicCases = @()
    
    foreach ($result in $Report.DetailedResults) {
        if (-not $result.IsCorrect) {
            $problematicCases += $result
        }
    }
    
    return $problematicCases
}

# Fonction pour analyser les cas problématiques
function Get-CaseAnalysis {
    param (
        [array]$ProblematicCases,
        [PSCustomObject]$Criteria
    )
    
    $analysis = @{}
    
    foreach ($case in $ProblematicCases) {
        $expectedFormat = $case.ExpectedFormat
        $detectedFormat = $case.DetectedFormat
        
        if (-not $analysis.ContainsKey($expectedFormat)) {
            $analysis[$expectedFormat] = @{
                MisclassifiedAs = @{}
                TotalMisclassifications = 0
                CommonPatterns = @{}
            }
        }
        
        if (-not $analysis[$expectedFormat].MisclassifiedAs.ContainsKey($detectedFormat)) {
            $analysis[$expectedFormat].MisclassifiedAs[$detectedFormat] = 0
        }
        
        $analysis[$expectedFormat].MisclassifiedAs[$detectedFormat]++
        $analysis[$expectedFormat].TotalMisclassifications++
        
        # Analyser les motifs communs dans les noms de fichiers
        $fileName = $case.FilePath
        
        if ($fileName -match "_truncated_") {
            $pattern = "truncated"
        }
        elseif ($fileName -match "_corrupted_") {
            $pattern = "corrupted"
        }
        elseif ($fileName -match "_incorrect_header") {
            $pattern = "incorrect_header"
        }
        elseif ($fileName -match "_incorrect_extension") {
            $pattern = "incorrect_extension"
        }
        elseif ($fileName -match "_hybrid") {
            $pattern = "hybrid"
        }
        else {
            $pattern = "other"
        }
        
        if (-not $analysis[$expectedFormat].CommonPatterns.ContainsKey($pattern)) {
            $analysis[$expectedFormat].CommonPatterns[$pattern] = 0
        }
        
        $analysis[$expectedFormat].CommonPatterns[$pattern]++
    }
    
    return $analysis
}

# Fonction pour optimiser les critères de détection
function Optimize-Criteria {
    param (
        [PSCustomObject]$Criteria,
        [hashtable]$Analysis
    )
    
    $optimizedCriteria = $Criteria | ConvertTo-Json -Depth 10 | ConvertFrom-Json
    $optimizationLog = @()
    
    foreach ($format in $Analysis.Keys) {
        $formatAnalysis = $Analysis[$format]
        $formatCriteria = $optimizedCriteria.PSObject.Properties | Where-Object { $_.Name -eq $format } | Select-Object -First 1
        
        if ($null -eq $formatCriteria) {
            Write-Warning "Aucun critère trouvé pour le format '$format'."
            continue
        }
        
        $formatCriteriaValue = $formatCriteria.Value
        
        # Analyser les cas de mauvaise classification
        $mostCommonMisclassification = $formatAnalysis.MisclassifiedAs.GetEnumerator() | 
            Sort-Object -Property Value -Descending | 
            Select-Object -First 1
        
        if ($null -ne $mostCommonMisclassification) {
            $misclassifiedAs = $mostCommonMisclassification.Key
            $misclassificationCount = $mostCommonMisclassification.Value
            
            # Optimiser les critères en fonction du type de problème le plus courant
            $mostCommonPattern = $formatAnalysis.CommonPatterns.GetEnumerator() | 
                Sort-Object -Property Value -Descending | 
                Select-Object -First 1
            
            if ($null -ne $mostCommonPattern) {
                $pattern = $mostCommonPattern.Key
                $patternCount = $mostCommonPattern.Value
                
                switch ($pattern) {
                    "truncated" {
                        # Améliorer la détection des fichiers tronqués
                        if ($formatCriteriaValue.MinimumSize -lt 50) {
                            $oldValue = $formatCriteriaValue.MinimumSize
                            $formatCriteriaValue.MinimumSize = 10
                            $optimizationLog += "Réduit la taille minimale pour le format '$format' de $oldValue à 10 octets pour mieux détecter les fichiers tronqués."
                        }
                        
                        if ($formatCriteriaValue.ContentPatterns -and $formatCriteriaValue.ContentPatterns.Count -gt 0) {
                            $oldCount = $formatCriteriaValue.ContentPatterns.Count
                            
                            # Réduire le nombre de motifs requis
                            $formatCriteriaValue.RequiredPatternCount = [Math]::Max(1, [Math]::Floor($formatCriteriaValue.RequiredPatternCount * 0.7))
                            
                            $optimizationLog += "Réduit le nombre de motifs requis pour le format '$format' à $($formatCriteriaValue.RequiredPatternCount) pour mieux détecter les fichiers tronqués."
                        }
                    }
                    "corrupted" {
                        # Améliorer la détection des fichiers corrompus
                        if ($formatCriteriaValue.ContentPatterns -and $formatCriteriaValue.ContentPatterns.Count -gt 0) {
                            $oldCount = $formatCriteriaValue.ContentPatterns.Count
                            
                            # Ajouter des motifs plus robustes
                            $formatCriteriaValue.RequiredPatternCount = [Math]::Max(1, [Math]::Floor($formatCriteriaValue.RequiredPatternCount * 0.6))
                            
                            $optimizationLog += "Réduit le nombre de motifs requis pour le format '$format' à $($formatCriteriaValue.RequiredPatternCount) pour mieux détecter les fichiers corrompus."
                        }
                        
                        # Augmenter la priorité pour les cas ambigus
                        $oldPriority = $formatCriteriaValue.Priority
                        $formatCriteriaValue.Priority += 5
                        
                        $optimizationLog += "Augmenté la priorité pour le format '$format' de $oldPriority à $($formatCriteriaValue.Priority) pour mieux résoudre les cas ambigus."
                    }
                    "incorrect_header" {
                        # Améliorer la détection des fichiers avec en-tête incorrect
                        if ($formatCriteriaValue.HeaderPatterns -and $formatCriteriaValue.HeaderPatterns.Count -gt 0) {
                            $oldRequired = $formatCriteriaValue.RequireHeader
                            $formatCriteriaValue.RequireHeader = $false
                            
                            $optimizationLog += "Désactivé l'exigence d'en-tête pour le format '$format' pour mieux détecter les fichiers avec en-tête incorrect."
                        }
                        
                        # Augmenter l'importance des motifs de contenu
                        if ($formatCriteriaValue.ContentPatterns -and $formatCriteriaValue.ContentPatterns.Count -gt 0) {
                            $oldWeight = $formatCriteriaValue.ContentWeight
                            $formatCriteriaValue.ContentWeight = [Math]::Min(100, $oldWeight * 1.5)
                            
                            $optimizationLog += "Augmenté le poids du contenu pour le format '$format' de $oldWeight à $($formatCriteriaValue.ContentWeight) pour mieux détecter les fichiers avec en-tête incorrect."
                        }
                    }
                    "incorrect_extension" {
                        # Améliorer la détection des fichiers avec extension incorrecte
                        $oldWeight = $formatCriteriaValue.ExtensionWeight
                        $formatCriteriaValue.ExtensionWeight = [Math]::Max(10, $oldWeight * 0.5)
                        
                        $optimizationLog += "Réduit le poids de l'extension pour le format '$format' de $oldWeight à $($formatCriteriaValue.ExtensionWeight) pour mieux détecter les fichiers avec extension incorrecte."
                        
                        # Augmenter l'importance des motifs de contenu
                        if ($formatCriteriaValue.ContentPatterns -and $formatCriteriaValue.ContentPatterns.Count -gt 0) {
                            $oldWeight = $formatCriteriaValue.ContentWeight
                            $formatCriteriaValue.ContentWeight = [Math]::Min(100, $oldWeight * 1.5)
                            
                            $optimizationLog += "Augmenté le poids du contenu pour le format '$format' de $oldWeight à $($formatCriteriaValue.ContentWeight) pour mieux détecter les fichiers avec extension incorrecte."
                        }
                    }
                    "hybrid" {
                        # Améliorer la détection des fichiers hybrides
                        $oldWeight = $formatCriteriaValue.StructureWeight
                        $formatCriteriaValue.StructureWeight = [Math]::Min(100, $oldWeight * 1.5)
                        
                        $optimizationLog += "Augmenté le poids de la structure pour le format '$format' de $oldWeight à $($formatCriteriaValue.StructureWeight) pour mieux détecter les fichiers hybrides."
                        
                        # Ajuster la priorité pour les cas ambigus
                        if ($misclassifiedAs -eq "TEXT" -or $misclassifiedAs -eq "BINARY") {
                            $oldPriority = $formatCriteriaValue.Priority
                            $formatCriteriaValue.Priority += 10
                            
                            $optimizationLog += "Augmenté la priorité pour le format '$format' de $oldPriority à $($formatCriteriaValue.Priority) pour mieux le distinguer des formats génériques."
                        }
                    }
                    default {
                        # Optimisations générales
                        $oldPriority = $formatCriteriaValue.Priority
                        $formatCriteriaValue.Priority += 2
                        
                        $optimizationLog += "Augmenté la priorité pour le format '$format' de $oldPriority à $($formatCriteriaValue.Priority) pour améliorer la détection."
                    }
                }
                
                # Ajuster les poids relatifs entre les formats souvent confondus
                $conflictingFormatCriteria = $optimizedCriteria.PSObject.Properties | Where-Object { $_.Name -eq $misclassifiedAs } | Select-Object -First 1
                
                if ($null -ne $conflictingFormatCriteria) {
                    $conflictingFormatCriteriaValue = $conflictingFormatCriteria.Value
                    
                    # Réduire légèrement la priorité du format conflictuel
                    $oldPriority = $conflictingFormatCriteriaValue.Priority
                    $conflictingFormatCriteriaValue.Priority = [Math]::Max(1, $oldPriority - 1)
                    
                    $optimizationLog += "Réduit la priorité pour le format '$misclassifiedAs' de $oldPriority à $($conflictingFormatCriteriaValue.Priority) pour réduire les confusions avec '$format'."
                }
            }
        }
    }
    
    return @{
        OptimizedCriteria = $optimizedCriteria
        OptimizationLog = $optimizationLog
    }
}

# Fonction pour générer un rapport HTML
function Export-OptimizationReport {
    param (
        [hashtable]$Analysis,
        [array]$OptimizationLog,
        [array]$ProblematicCases,
        [string]$OutputPath
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'optimisation des algorithmes de détection</title>
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
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        h1 {
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .summary {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .optimization-log {
            background-color: #e8f4f8;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border-left: 4px solid #3498db;
        }
        .optimization-log ul {
            margin: 0;
            padding-left: 20px;
        }
        .optimization-log li {
            margin-bottom: 5px;
        }
        .analysis-section {
            margin-bottom: 30px;
        }
        .format-analysis {
            background-color: #fff;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 15px;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .format-analysis h3 {
            margin-top: 0;
            color: #3498db;
        }
        .misclassification-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        .misclassification-table th, .misclassification-table td {
            padding: 8px 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .misclassification-table th {
            background-color: #3498db;
            color: white;
        }
        .misclassification-table tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .pattern-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        .pattern-table th, .pattern-table td {
            padding: 8px 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .pattern-table th {
            background-color: #3498db;
            color: white;
        }
        .pattern-table tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .problematic-cases {
            margin-top: 20px;
        }
        .case-table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        .case-table th, .case-table td {
            padding: 8px 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .case-table th {
            background-color: #3498db;
            color: white;
        }
        .case-table tr:nth-child(even) {
            background-color: #f2f2f2;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport d'optimisation des algorithmes de détection</h1>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p><strong>Nombre de cas problématiques analysés:</strong> $($ProblematicCases.Count)</p>
            <p><strong>Nombre de formats optimisés:</strong> $($Analysis.Count)</p>
            <p><strong>Nombre d'optimisations effectuées:</strong> $($OptimizationLog.Count)</p>
            <p><strong>Date de l'optimisation:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
        
        <div class="optimization-log">
            <h2>Journal d'optimisation</h2>
            <ul>
"@

    foreach ($log in $OptimizationLog) {
        $html += @"
                <li>$log</li>
"@
    }

    $html += @"
            </ul>
        </div>
        
        <h2>Analyse des cas problématiques</h2>
        <div class="analysis-section">
"@

    foreach ($format in $Analysis.Keys | Sort-Object) {
        $formatAnalysis = $Analysis[$format]
        
        $html += @"
            <div class="format-analysis">
                <h3>Format: $format</h3>
                <p><strong>Nombre total de mauvaises classifications:</strong> $($formatAnalysis.TotalMisclassifications)</p>
                
                <h4>Classifications erronées</h4>
                <table class="misclassification-table">
                    <thead>
                        <tr>
                            <th>Détecté comme</th>
                            <th>Nombre</th>
                            <th>Pourcentage</th>
                        </tr>
                    </thead>
                    <tbody>
"@

        foreach ($misclassification in $formatAnalysis.MisclassifiedAs.GetEnumerator() | Sort-Object -Property Value -Descending) {
            $percentage = [Math]::Round(($misclassification.Value / $formatAnalysis.TotalMisclassifications) * 100, 2)
            
            $html += @"
                        <tr>
                            <td>$($misclassification.Key)</td>
                            <td>$($misclassification.Value)</td>
                            <td>$percentage%</td>
                        </tr>
"@
        }

        $html += @"
                    </tbody>
                </table>
                
                <h4>Motifs communs</h4>
                <table class="pattern-table">
                    <thead>
                        <tr>
                            <th>Motif</th>
                            <th>Nombre</th>
                            <th>Pourcentage</th>
                        </tr>
                    </thead>
                    <tbody>
"@

        foreach ($pattern in $formatAnalysis.CommonPatterns.GetEnumerator() | Sort-Object -Property Value -Descending) {
            $percentage = [Math]::Round(($pattern.Value / $formatAnalysis.TotalMisclassifications) * 100, 2)
            $patternName = switch ($pattern.Key) {
                "truncated" { "Fichier tronqué" }
                "corrupted" { "Fichier corrompu" }
                "incorrect_header" { "En-tête incorrect" }
                "incorrect_extension" { "Extension incorrecte" }
                "hybrid" { "Fichier hybride" }
                default { "Autre" }
            }
            
            $html += @"
                        <tr>
                            <td>$patternName</td>
                            <td>$($pattern.Value)</td>
                            <td>$percentage%</td>
                        </tr>
"@
        }

        $html += @"
                    </tbody>
                </table>
            </div>
"@
    }

    $html += @"
        </div>
        
        <h2>Cas problématiques</h2>
        <div class="problematic-cases">
            <table class="case-table">
                <thead>
                    <tr>
                        <th>Fichier</th>
                        <th>Format attendu</th>
                        <th>Format détecté</th>
                        <th>Score de confiance</th>
                    </tr>
                </thead>
                <tbody>
"@

    foreach ($case in $ProblematicCases | Sort-Object -Property FilePath) {
        $html += @"
                    <tr>
                        <td>$($case.FilePath)</td>
                        <td>$($case.ExpectedFormat)</td>
                        <td>$($case.DetectedFormat)</td>
                        <td>$($case.ConfidenceScore)%</td>
                    </tr>
"@
    }

    $html += @"
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
"@

    $html | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Rapport d'optimisation exporté vers '$OutputPath'" -ForegroundColor Green
}

# Fonction principale
function Main {
    # Vérifier si le rapport de précision existe
    if (-not (Test-Path -Path $AccuracyReportPath)) {
        Write-Error "Le rapport de précision '$AccuracyReportPath' n'existe pas."
        exit 1
    }
    
    # Vérifier si le fichier des critères de détection existe
    if (-not (Test-Path -Path $CriteriaPath)) {
        Write-Error "Le fichier des critères de détection '$CriteriaPath' n'existe pas."
        exit 1
    }
    
    # Charger le rapport de précision
    $accuracyReport = Get-AccuracyReport -Path $AccuracyReportPath
    
    if ($null -eq $accuracyReport) {
        exit 1
    }
    
    # Charger les critères de détection
    $criteria = Get-DetectionCriteria -Path $CriteriaPath
    
    if ($null -eq $criteria) {
        exit 1
    }
    
    Write-Host "Analyse des résultats de détection et optimisation des algorithmes..." -ForegroundColor Yellow
    
    # Identifier les cas problématiques
    $problematicCases = Get-ProblematicCases -Report $accuracyReport
    
    if ($problematicCases.Count -eq 0) {
        Write-Host "Aucun cas problématique trouvé. Les algorithmes de détection fonctionnent parfaitement !" -ForegroundColor Green
        return
    }
    
    Write-Host "Nombre de cas problématiques identifiés : $($problematicCases.Count)" -ForegroundColor Cyan
    
    # Analyser les cas problématiques
    $analysis = Get-CaseAnalysis -ProblematicCases $problematicCases -Criteria $criteria
    
    # Optimiser les critères de détection
    $optimizationResult = Optimize-Criteria -Criteria $criteria -Analysis $analysis
    $optimizedCriteria = $optimizationResult.OptimizedCriteria
    $optimizationLog = $optimizationResult.OptimizationLog
    
    # Enregistrer les critères optimisés
    New-DirectoryIfNotExists -Path $OutputCriteriaPath
    $optimizedCriteria | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputCriteriaPath -Encoding UTF8
    
    Write-Host "Critères de détection optimisés enregistrés dans '$OutputCriteriaPath'" -ForegroundColor Green
    
    # Afficher le journal d'optimisation
    Write-Host "`nJournal d'optimisation :" -ForegroundColor Yellow
    
    foreach ($log in $optimizationLog) {
        Write-Host "- $log" -ForegroundColor White
    }
    
    # Générer un rapport d'optimisation
    if ($GenerateReport) {
        New-DirectoryIfNotExists -Path $ReportPath
        Export-OptimizationReport -Analysis $analysis -OptimizationLog $optimizationLog -ProblematicCases $problematicCases -OutputPath $ReportPath
    }
    
    return @{
        Analysis = $analysis
        OptimizationLog = $optimizationLog
        OptimizedCriteria = $optimizedCriteria
    }
}

# Exécuter la fonction principale
$result = Main
return $result

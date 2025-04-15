#Requires -Version 5.1
<#
.SYNOPSIS
    Fusionne les résultats d'analyses parallèles.

.DESCRIPTION
    Ce script fusionne les résultats d'analyses parallèles de pull requests
    en un seul rapport consolidé, en éliminant les doublons et en résolvant
    les conflits.

.PARAMETER InputPaths
    Les chemins des fichiers de résultats à fusionner.

.PARAMETER OutputPath
    Le chemin où enregistrer le résultat fusionné.
    Par défaut: "reports\pr-analysis\merged_results.json"

.PARAMETER ConflictResolution
    La stratégie de résolution des conflits.
    Valeurs possibles: "First", "Last", "Newest", "MostIssues", "LeastIssues"
    Par défaut: "Newest"

.PARAMETER GenerateHtmlReport
    Indique s'il faut générer un rapport HTML.
    Par défaut: $true

.EXAMPLE
    .\Merge-ParallelResults.ps1 -InputPaths "results1.json", "results2.json"
    Fusionne les résultats des deux fichiers spécifiés.

.EXAMPLE
    .\Merge-ParallelResults.ps1 -InputPaths "results*.json" -ConflictResolution "MostIssues"
    Fusionne tous les fichiers correspondant au modèle, en privilégiant les résultats avec le plus de problèmes en cas de conflit.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string[]]$InputPaths,

    [Parameter()]
    [string]$OutputPath = "reports\pr-analysis\merged_results.json",

    [Parameter()]
    [ValidateSet("First", "Last", "Newest", "MostIssues", "LeastIssues")]
    [string]$ConflictResolution = "Newest",

    [Parameter()]
    [bool]$GenerateHtmlReport = $true
)

# Importer le module de parallélisation
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\ParallelPRAnalysis.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module ParallelPRAnalysis non trouvé à l'emplacement: $modulePath"
    exit 1
}

# Fonction pour résoudre les chemins de fichiers
function Resolve-FilePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    try {
        $resolvedPaths = @()
        
        foreach ($path in $Paths) {
            # Vérifier si le chemin contient des caractères génériques
            if ($path -match '\*|\?') {
                # Résoudre les chemins avec des caractères génériques
                $matchingPaths = Get-ChildItem -Path $path -File | Select-Object -ExpandProperty FullName
                $resolvedPaths += $matchingPaths
            } else {
                # Vérifier si le fichier existe
                if (Test-Path -Path $path -PathType Leaf) {
                    $resolvedPaths += (Get-Item -Path $path).FullName
                } else {
                    Write-Warning "Le fichier n'existe pas: $path"
                }
            }
        }
        
        return $resolvedPaths
    } catch {
        Write-Error "Erreur lors de la résolution des chemins de fichiers: $_"
        return @()
    }
}

# Fonction pour charger les résultats
function Get-ResultsFromFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        # Charger le fichier JSON
        $content = Get-Content -Path $Path -Raw -Encoding UTF8
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Warning "Le fichier est vide: $Path"
            return $null
        }
        
        # Convertir le contenu JSON
        $results = $content | ConvertFrom-Json
        if ($null -eq $results) {
            Write-Warning "Impossible de convertir le contenu JSON: $Path"
            return $null
        }
        
        # Ajouter des informations sur la source
        $results | Add-Member -MemberType NoteProperty -Name "SourceFile" -Value $Path -Force
        $results | Add-Member -MemberType NoteProperty -Name "LoadTime" -Value (Get-Date) -Force
        
        return $results
    } catch {
        Write-Error "Erreur lors du chargement des résultats à partir du fichier: $Path`n$_"
        return $null
    }
}

# Fonction pour fusionner les résultats
function Merge-Results {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$ResultsArray,
        
        [Parameter(Mandatory = $true)]
        [string]$Strategy
    )

    try {
        # Vérifier s'il y a des résultats à fusionner
        if ($ResultsArray.Count -eq 0) {
            Write-Warning "Aucun résultat à fusionner."
            return $null
        }
        
        if ($ResultsArray.Count -eq 1) {
            Write-Host "Un seul résultat à traiter, aucune fusion nécessaire." -ForegroundColor Yellow
            return $ResultsArray[0]
        }
        
        # Créer un objet pour stocker les résultats fusionnés
        $mergedResults = [PSCustomObject]@{
            PullRequest = $ResultsArray[0].PullRequest
            Timestamp = Get-Date
            TotalFiles = 0
            TotalIssues = 0
            TotalDurationMs = 0
            AverageDurationMs = 0
            MaxDurationMs = 0
            MinDurationMs = 0
            SuccessCount = 0
            FailureCount = 0
            IssuesByType = @()
            Results = @()
            Stats = [PSCustomObject]@{
                SourceFiles = $ResultsArray.Count
                MergeStrategy = $Strategy
                MergeTime = Get-Date
                Conflicts = 0
                ResolvedConflicts = 0
            }
        }
        
        # Créer un dictionnaire pour stocker les résultats par chemin de fichier
        $resultsByPath = @{}
        
        # Parcourir tous les résultats
        foreach ($resultSet in $ResultsArray) {
            # Parcourir les résultats de chaque fichier
            foreach ($fileResult in $resultSet.Results) {
                $filePath = $fileResult.FilePath
                
                # Vérifier s'il y a déjà un résultat pour ce fichier
                if ($resultsByPath.ContainsKey($filePath)) {
                    # Conflit détecté
                    $mergedResults.Stats.Conflicts++
                    
                    # Résoudre le conflit selon la stratégie spécifiée
                    $existingResult = $resultsByPath[$filePath]
                    $newResult = $null
                    
                    switch ($Strategy) {
                        "First" {
                            # Conserver le premier résultat
                            $newResult = $existingResult
                        }
                        "Last" {
                            # Utiliser le dernier résultat
                            $newResult = $fileResult
                        }
                        "Newest" {
                            # Utiliser le résultat le plus récent
                            if ($fileResult.EndTime -gt $existingResult.EndTime) {
                                $newResult = $fileResult
                            } else {
                                $newResult = $existingResult
                            }
                        }
                        "MostIssues" {
                            # Utiliser le résultat avec le plus de problèmes
                            if ($fileResult.Issues.Count -gt $existingResult.Issues.Count) {
                                $newResult = $fileResult
                            } else {
                                $newResult = $existingResult
                            }
                        }
                        "LeastIssues" {
                            # Utiliser le résultat avec le moins de problèmes
                            if ($fileResult.Issues.Count -lt $existingResult.Issues.Count) {
                                $newResult = $fileResult
                            } else {
                                $newResult = $existingResult
                            }
                        }
                        default {
                            # Par défaut, utiliser le résultat le plus récent
                            if ($fileResult.EndTime -gt $existingResult.EndTime) {
                                $newResult = $fileResult
                            } else {
                                $newResult = $existingResult
                            }
                        }
                    }
                    
                    # Mettre à jour le résultat
                    $resultsByPath[$filePath] = $newResult
                    $mergedResults.Stats.ResolvedConflicts++
                } else {
                    # Pas de conflit, ajouter le résultat
                    $resultsByPath[$filePath] = $fileResult
                }
            }
        }
        
        # Convertir le dictionnaire en tableau
        $mergedResults.Results = $resultsByPath.Values
        
        # Mettre à jour les statistiques
        $mergedResults.TotalFiles = $mergedResults.Results.Count
        $mergedResults.TotalIssues = ($mergedResults.Results | Where-Object { $_.Success } | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum).Sum
        $mergedResults.TotalDurationMs = ($mergedResults.Results | ForEach-Object { $_.Duration.TotalMilliseconds } | Measure-Object -Sum).Sum
        $mergedResults.AverageDurationMs = ($mergedResults.Results | ForEach-Object { $_.Duration.TotalMilliseconds } | Measure-Object -Average).Average
        $mergedResults.MaxDurationMs = ($mergedResults.Results | ForEach-Object { $_.Duration.TotalMilliseconds } | Measure-Object -Maximum).Maximum
        $mergedResults.MinDurationMs = ($mergedResults.Results | ForEach-Object { $_.Duration.TotalMilliseconds } | Measure-Object -Minimum).Minimum
        $mergedResults.SuccessCount = ($mergedResults.Results | Where-Object { $_.Success } | Measure-Object).Count
        $mergedResults.FailureCount = $mergedResults.TotalFiles - $mergedResults.SuccessCount
        $mergedResults.IssuesByType = $mergedResults.Results | Where-Object { $_.Success } | ForEach-Object { $_.Issues } | Group-Object -Property Type
        
        return $mergedResults
    } catch {
        Write-Error "Erreur lors de la fusion des résultats: $_"
        return $null
    }
}

# Fonction pour générer un rapport HTML
function New-HtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    try {
        # Créer le répertoire de sortie s'il n'existe pas
        $outputDir = Split-Path -Path $OutputPath -Parent
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # Générer le HTML
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'Analyse Fusionné - PR #$($Results.PullRequest.Number)</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
            color: #333;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1, h2, h3 {
            color: #2c3e50;
        }
        .summary {
            background-color: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 8px 12px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f2f2f2;
        }
        tr:hover {
            background-color: #f5f5f5;
        }
        .error {
            color: #e74c3c;
        }
        .warning {
            color: #f39c12;
        }
        .success {
            color: #27ae60;
        }
        .info {
            color: #3498db;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport d'Analyse Fusionné - Pull Request #$($Results.PullRequest.Number)</h1>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p><strong>Titre:</strong> $($Results.PullRequest.Title)</p>
            <p><strong>Branche source:</strong> $($Results.PullRequest.HeadBranch)</p>
            <p><strong>Branche cible:</strong> $($Results.PullRequest.BaseBranch)</p>
            <p><strong>Fichiers analysés:</strong> $($Results.TotalFiles)</p>
            <p><strong>Problèmes détectés:</strong> $($Results.TotalIssues)</p>
            <p><strong>Durée totale:</strong> $([Math]::Round($Results.TotalDurationMs / 1000, 2)) secondes</p>
            <p><strong>Durée moyenne par fichier:</strong> $([Math]::Round($Results.AverageDurationMs, 2)) ms</p>
        </div>
        
        <div class="summary">
            <h2>Informations sur la Fusion</h2>
            <p><strong>Stratégie de fusion:</strong> $($Results.Stats.MergeStrategy)</p>
            <p><strong>Fichiers sources:</strong> $($Results.Stats.SourceFiles)</p>
            <p><strong>Conflits détectés:</strong> $($Results.Stats.Conflicts)</p>
            <p><strong>Conflits résolus:</strong> $($Results.Stats.ResolvedConflicts)</p>
            <p><strong>Date de fusion:</strong> $($Results.Stats.MergeTime)</p>
        </div>
        
        <h2>Problèmes par Type</h2>
        <table>
            <tr>
                <th>Type</th>
                <th>Nombre</th>
            </tr>
"@

        foreach ($issueType in $Results.IssuesByType) {
            $html += @"
            <tr>
                <td>$($issueType.Name)</td>
                <td>$($issueType.Count)</td>
            </tr>
"@
        }

        $html += @"
        </table>
        
        <h2>Fichiers avec Problèmes</h2>
        <table>
            <tr>
                <th>Fichier</th>
                <th>Problèmes</th>
                <th>Durée (ms)</th>
            </tr>
"@

        foreach ($result in ($Results.Results | Where-Object { $_.Success -and $_.Issues.Count -gt 0 } | Sort-Object -Property { $_.Issues.Count } -Descending)) {
            $html += @"
            <tr>
                <td>$($result.FilePath)</td>
                <td>$($result.Issues.Count)</td>
                <td>$([Math]::Round($result.Duration.TotalMilliseconds, 2))</td>
            </tr>
"@
        }

        $html += @"
        </table>
        
        <h2>Détails des Problèmes</h2>
"@

        foreach ($result in ($Results.Results | Where-Object { $_.Success -and $_.Issues.Count -gt 0 } | Sort-Object -Property { $_.Issues.Count } -Descending)) {
            $html += @"
        <h3>$($result.FilePath)</h3>
        <table>
            <tr>
                <th>Type</th>
                <th>Ligne</th>
                <th>Message</th>
                <th>Sévérité</th>
            </tr>
"@

            foreach ($issue in ($result.Issues | Sort-Object -Property LineNumber)) {
                $severityClass = switch ($issue.Severity) {
                    "Error" { "error" }
                    "Critical" { "error" }
                    "Warning" { "warning" }
                    default { "" }
                }
                
                $html += @"
            <tr>
                <td>$($issue.Type)</td>
                <td>$($issue.LineNumber)</td>
                <td>$($issue.Message)</td>
                <td class="$severityClass">$($issue.Severity)</td>
            </tr>
"@
            }

            $html += @"
        </table>
"@
        }

        $html += @"
    </div>
</body>
</html>
"@

        # Enregistrer le fichier HTML
        Set-Content -Path $OutputPath -Value $html -Encoding UTF8
        
        return $OutputPath
    } catch {
        Write-Error "Erreur lors de la génération du rapport HTML: $_"
        return $null
    }
}

# Point d'entrée principal
try {
    # Résoudre les chemins de fichiers
    $resolvedPaths = Resolve-FilePaths -Paths $InputPaths
    if ($resolvedPaths.Count -eq 0) {
        Write-Error "Aucun fichier trouvé."
        exit 1
    }
    
    Write-Host "Fichiers trouvés: $($resolvedPaths.Count)" -ForegroundColor Cyan
    foreach ($path in $resolvedPaths) {
        Write-Host "  $path" -ForegroundColor White
    }

    # Charger les résultats
    $resultsArray = @()
    foreach ($path in $resolvedPaths) {
        $results = Get-ResultsFromFile -Path $path
        if ($null -ne $results) {
            $resultsArray += $results
            Write-Host "Résultats chargés: $path" -ForegroundColor Green
        }
    }
    
    if ($resultsArray.Count -eq 0) {
        Write-Error "Aucun résultat chargé."
        exit 1
    }
    
    Write-Host "Résultats chargés: $($resultsArray.Count)" -ForegroundColor Cyan

    # Fusionner les résultats
    Write-Host "Fusion des résultats avec la stratégie: $ConflictResolution" -ForegroundColor Cyan
    $mergedResults = Merge-Results -ResultsArray $resultsArray -Strategy $ConflictResolution
    if ($null -eq $mergedResults) {
        Write-Error "Échec de la fusion des résultats."
        exit 1
    }
    
    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer les résultats fusionnés
    $mergedResults | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Résultats fusionnés enregistrés: $OutputPath" -ForegroundColor Green

    # Générer un rapport HTML si demandé
    $htmlPath = $null
    if ($GenerateHtmlReport) {
        $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
        $htmlPath = New-HtmlReport -Results $mergedResults -OutputPath $htmlPath
        if ($null -ne $htmlPath) {
            Write-Host "Rapport HTML généré: $htmlPath" -ForegroundColor Green
        }
    }

    # Afficher un résumé
    Write-Host "`nRésumé de la fusion:" -ForegroundColor Cyan
    Write-Host "  Fichiers sources: $($mergedResults.Stats.SourceFiles)" -ForegroundColor White
    Write-Host "  Stratégie de fusion: $($mergedResults.Stats.MergeStrategy)" -ForegroundColor White
    Write-Host "  Conflits détectés: $($mergedResults.Stats.Conflicts)" -ForegroundColor White
    Write-Host "  Conflits résolus: $($mergedResults.Stats.ResolvedConflicts)" -ForegroundColor White
    Write-Host "  Fichiers analysés: $($mergedResults.TotalFiles)" -ForegroundColor White
    Write-Host "  Problèmes détectés: $($mergedResults.TotalIssues)" -ForegroundColor White
    Write-Host "  Durée totale: $([Math]::Round($mergedResults.TotalDurationMs / 1000, 2)) secondes" -ForegroundColor White
    
    # Ouvrir le rapport HTML dans le navigateur par défaut
    if ($null -ne $htmlPath -and (Test-Path -Path $htmlPath)) {
        Start-Process $htmlPath
    }

    # Retourner les résultats
    return $mergedResults
} catch {
    Write-Error "Erreur lors de la fusion des résultats: $_"
    exit 1
}

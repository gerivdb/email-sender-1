#Requires -Version 5.1
<#
.SYNOPSIS
    Démarre une analyse incrémentale des pull requests.

.DESCRIPTION
    Ce script exécute une analyse incrémentale des pull requests, en se concentrant
    uniquement sur les fichiers qui ont été modifiés de manière significative.

.PARAMETER RepositoryPath
    Le chemin du dépôt à analyser.
    Par défaut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER PullRequestNumber
    Le numéro de la pull request à analyser.
    Si non spécifié, la dernière pull request sera utilisée.

.PARAMETER OutputPath
    Le chemin où enregistrer les résultats de l'analyse.
    Par défaut: "reports\pr-analysis"

.PARAMETER UseCache
    Indique s'il faut utiliser le cache pour améliorer les performances.
    Par défaut: $true

.PARAMETER ThresholdRatio
    Le ratio de changement à partir duquel une modification est considérée comme significative.
    Par défaut: 0.1 (10%)

.PARAMETER MinimumChanges
    Le nombre minimum de lignes modifiées pour qu'un fichier soit considéré comme significativement modifié.
    Par défaut: 5

.PARAMETER ForceFullAnalysis
    Indique s'il faut forcer une analyse complète, même pour les fichiers non significativement modifiés.
    Par défaut: $false

.EXAMPLE
    .\Start-IncrementalPRAnalysis.ps1
    Analyse de manière incrémentale la dernière pull request.

.EXAMPLE
    .\Start-IncrementalPRAnalysis.ps1 -PullRequestNumber 42 -ThresholdRatio 0.05 -ForceFullAnalysis $true
    Analyse de manière incrémentale la pull request #42 avec un seuil de 5% et force une analyse complète.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepositoryPath = "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo",

    [Parameter()]
    [int]$PullRequestNumber = 0,

    [Parameter()]
    [string]$OutputPath = "reports\pr-analysis",

    [Parameter()]
    [bool]$UseCache = $true,

    [Parameter()]
    [double]$ThresholdRatio = 0.1,

    [Parameter()]
    [int]$MinimumChanges = 5,

    [Parameter()]
    [bool]$ForceFullAnalysis = $false
)

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$modulesToImport = @(
    "FileContentIndexer.psm1",
    "SyntaxAnalyzer.psm1",
    "PRAnalysisCache.psm1"
)

foreach ($module in $modulesToImport) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath $module
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        Write-Error "Module $module non trouvé à l'emplacement: $modulePath"
        exit 1
    }
}

# Fonction pour obtenir les informations sur la pull request
function Get-PullRequestInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,
        
        [Parameter()]
        [int]$PRNumber = 0
    )

    try {
        # Vérifier si le dépôt existe
        if (-not (Test-Path -Path $RepoPath)) {
            throw "Le dépôt n'existe pas à l'emplacement spécifié: $RepoPath"
        }

        # Changer de répertoire vers le dépôt
        Push-Location -Path $RepoPath

        try {
            # Si aucun numéro de PR n'est spécifié, utiliser la dernière PR
            if ($PRNumber -eq 0) {
                $prs = gh pr list --json number,title,headRefName,baseRefName,createdAt --limit 1 | ConvertFrom-Json
                if ($prs.Count -eq 0) {
                    throw "Aucune pull request trouvée dans le dépôt."
                }
                $pr = $prs[0]
            } else {
                $pr = gh pr view $PRNumber --json number,title,headRefName,baseRefName,createdAt | ConvertFrom-Json
                if ($null -eq $pr) {
                    throw "Pull request #$PRNumber non trouvée."
                }
            }

            # Obtenir les fichiers modifiés
            $files = gh pr view $pr.number --json files | ConvertFrom-Json

            # Créer l'objet d'informations sur la PR
            $prInfo = [PSCustomObject]@{
                Number     = $pr.number
                Title      = $pr.title
                HeadBranch = $pr.headRefName
                BaseBranch = $pr.baseRefName
                CreatedAt  = $pr.createdAt
                Files      = $files.files
                FileCount  = $files.files.Count
                Additions  = ($files.files | Measure-Object additions -Sum).Sum
                Deletions  = ($files.files | Measure-Object deletions -Sum).Sum
                Changes    = ($files.files | Measure-Object additions, deletions -Sum).Sum
            }

            return $prInfo
        } finally {
            # Revenir au répertoire précédent
            Pop-Location
        }
    } catch {
        Write-Error "Erreur lors de la récupération des informations sur la pull request: $_"
        return $null
    }
}

# Fonction pour analyser un fichier
function Invoke-FileAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$File,
        
        [Parameter(Mandatory = $true)]
        [object]$Analyzer,
        
        [Parameter(Mandatory = $true)]
        [object]$Cache,
        
        [Parameter(Mandatory = $true)]
        [bool]$UseFileCache,
        
        [Parameter(Mandatory = $true)]
        [string]$RepoPath
    )

    try {
        # Créer un objet pour stocker les résultats
        $result = [PSCustomObject]@{
            FilePath = $File.path
            Issues = @()
            StartTime = Get-Date
            EndTime = $null
            Duration = $null
            Success = $false
            FromCache = $false
        }

        # Générer une clé de cache unique
        $cacheKey = "IncrementalAnalysis:$($File.path):$($File.sha)"

        # Essayer d'obtenir les résultats du cache
        if ($UseFileCache) {
            $cachedResult = $Cache.Get($cacheKey)
            if ($null -ne $cachedResult) {
                # Ajouter des informations sur l'utilisation du cache
                $cachedResult | Add-Member -MemberType NoteProperty -Name "FromCache" -Value $true -Force
                
                return $cachedResult
            }
        }

        # Construire le chemin complet du fichier
        $filePath = Join-Path -Path $RepoPath -ChildPath $File.path
        
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $filePath)) {
            $result.EndTime = Get-Date
            $result.Duration = $result.EndTime - $result.StartTime
            $result.Success = $false
            return $result
        }

        # Analyser le fichier
        $issues = $Analyzer.AnalyzeFile($filePath)
        
        # Mettre à jour les résultats
        $result.Issues = $issues
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
        $result.Success = $true

        # Stocker les résultats dans le cache
        if ($UseFileCache) {
            $Cache.Set($cacheKey, $result)
        }

        return $result
    } catch {
        # Gérer les erreurs
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
        $result.Success = $false
        
        Write-Error "Erreur lors de l'analyse du fichier $($File.path) : $_"
        
        return $result
    }
}

# Fonction pour générer un rapport d'analyse
function New-AnalysisReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Results,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$PullRequestInfo,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputDir,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$SignificantChanges
    )

    try {
        # Créer le répertoire de sortie s'il n'existe pas
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }

        # Calculer les statistiques
        $totalFiles = $Results.Count
        $totalIssues = ($Results | Where-Object { $_.Success } | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum).Sum
        $totalDuration = ($Results | ForEach-Object { $_.Duration.TotalMilliseconds } | Measure-Object -Sum).Sum
        $averageDuration = ($Results | ForEach-Object { $_.Duration.TotalMilliseconds } | Measure-Object -Average).Average
        $maxDuration = ($Results | ForEach-Object { $_.Duration.TotalMilliseconds } | Measure-Object -Maximum).Maximum
        $minDuration = ($Results | ForEach-Object { $_.Duration.TotalMilliseconds } | Measure-Object -Minimum).Minimum
        $successCount = ($Results | Where-Object { $_.Success } | Measure-Object).Count
        $failureCount = $totalFiles - $successCount
        $issuesByType = $Results | Where-Object { $_.Success } | ForEach-Object { $_.Issues } | Group-Object -Property Type
        $cachedCount = ($Results | Where-Object { $_.FromCache } | Measure-Object).Count

        # Créer le rapport
        $reportData = [PSCustomObject]@{
            PullRequest = $PullRequestInfo
            Timestamp = Get-Date
            TotalFiles = $totalFiles
            TotalIssues = $totalIssues
            TotalDurationMs = $totalDuration
            AverageDurationMs = $averageDuration
            MaxDurationMs = $maxDuration
            MinDurationMs = $minDuration
            SuccessCount = $successCount
            FailureCount = $failureCount
            CachedCount = $cachedCount
            IssuesByType = $issuesByType
            Results = $Results
            SignificantChanges = $SignificantChanges
            AnalysisType = "Incremental"
        }

        # Enregistrer le rapport au format JSON
        $reportPath = Join-Path -Path $OutputDir -ChildPath "incremental_analysis_$($PullRequestInfo.Number).json"
        $reportData | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding UTF8

        # Générer un rapport HTML
        $htmlReportPath = Join-Path -Path $OutputDir -ChildPath "incremental_analysis_$($PullRequestInfo.Number).html"
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'Analyse Incrémentale - PR #$($PullRequestInfo.Number)</title>
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
        <h1>Rapport d'Analyse Incrémentale - Pull Request #$($PullRequestInfo.Number)</h1>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p><strong>Titre:</strong> $($PullRequestInfo.Title)</p>
            <p><strong>Branche source:</strong> $($PullRequestInfo.HeadBranch)</p>
            <p><strong>Branche cible:</strong> $($PullRequestInfo.BaseBranch)</p>
            <p><strong>Fichiers analysés:</strong> $totalFiles</p>
            <p><strong>Problèmes détectés:</strong> $totalIssues</p>
            <p><strong>Durée totale:</strong> $([Math]::Round($totalDuration / 1000, 2)) secondes</p>
            <p><strong>Durée moyenne par fichier:</strong> $([Math]::Round($averageDuration, 2)) ms</p>
            <p><strong>Fichiers mis en cache:</strong> $cachedCount</p>
            <p><strong>Fichiers avec changements significatifs:</strong> $($SignificantChanges.SignificantFiles) sur $($SignificantChanges.TotalFiles) ($($SignificantChanges.SignificantRatio)%)</p>
        </div>
        
        <h2>Problèmes par Type</h2>
        <table>
            <tr>
                <th>Type</th>
                <th>Nombre</th>
            </tr>
"@

        foreach ($issueType in $issuesByType) {
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
                <th>Mis en cache</th>
                <th>Changement significatif</th>
            </tr>
"@

        foreach ($result in ($Results | Where-Object { $_.Success -and $_.Issues.Count -gt 0 } | Sort-Object -Property { $_.Issues.Count } -Descending)) {
            $isSignificant = ($SignificantChanges.Results | Where-Object { $_.FilePath -eq $result.FilePath -and $_.IsSignificant }).Count -gt 0
            $significantClass = if ($isSignificant) { "info" } else { "" }
            
            $html += @"
            <tr>
                <td>$($result.FilePath)</td>
                <td>$($result.Issues.Count)</td>
                <td>$([Math]::Round($result.Duration.TotalMilliseconds, 2))</td>
                <td>$($result.FromCache)</td>
                <td class="$significantClass">$isSignificant</td>
            </tr>
"@
        }

        $html += @"
        </table>
        
        <h2>Détails des Problèmes</h2>
"@

        foreach ($result in ($Results | Where-Object { $_.Success -and $_.Issues.Count -gt 0 } | Sort-Object -Property { $_.Issues.Count } -Descending)) {
            $html += @"
        <h3>$($result.FilePath)</h3>
        <table>
            <tr>
                <th>Type</th>
                <th>Ligne</th>
                <th>Colonne</th>
                <th>Message</th>
                <th>Sévérité</th>
                <th>Règle</th>
            </tr>
"@

            foreach ($issue in ($result.Issues | Sort-Object -Property Line)) {
                $severityClass = switch ($issue.Severity) {
                    "Error" { "error" }
                    "Critical" { "error" }
                    "Warning" { "warning" }
                    "Information" { "info" }
                    default { "" }
                }
                
                $html += @"
            <tr>
                <td>$($issue.Type)</td>
                <td>$($issue.Line)</td>
                <td>$($issue.Column)</td>
                <td>$($issue.Message)</td>
                <td class="$severityClass">$($issue.Severity)</td>
                <td>$($issue.Rule)</td>
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

        Set-Content -Path $htmlReportPath -Value $html -Encoding UTF8

        return [PSCustomObject]@{
            JsonPath = $reportPath
            HtmlPath = $htmlReportPath
        }
    } catch {
        Write-Error "Erreur lors de la génération du rapport: $_"
        return $null
    }
}

# Point d'entrée principal
try {
    # Mesurer le temps d'exécution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Obtenir les informations sur la pull request
    $prInfo = Get-PullRequestInfo -RepoPath $RepositoryPath -PRNumber $PullRequestNumber
    if ($null -eq $prInfo) {
        Write-Error "Impossible d'obtenir les informations sur la pull request."
        exit 1
    }

    # Afficher les informations sur la pull request
    Write-Host "Informations sur la pull request:" -ForegroundColor Cyan
    Write-Host "  Numéro: #$($prInfo.Number)" -ForegroundColor White
    Write-Host "  Titre: $($prInfo.Title)" -ForegroundColor White
    Write-Host "  Branche source: $($prInfo.HeadBranch)" -ForegroundColor White
    Write-Host "  Branche cible: $($prInfo.BaseBranch)" -ForegroundColor White
    Write-Host "  Fichiers modifiés: $($prInfo.FileCount)" -ForegroundColor White
    Write-Host "  Ajouts: $($prInfo.Additions)" -ForegroundColor White
    Write-Host "  Suppressions: $($prInfo.Deletions)" -ForegroundColor White
    Write-Host "  Modifications totales: $($prInfo.Changes)" -ForegroundColor White

    # Initialiser le cache
    $cache = $null
    if ($UseCache) {
        $cachePath = Join-Path -Path $PSScriptRoot -ChildPath "cache\pr-analysis"
        $cache = New-PRAnalysisCache -Name "PRAnalysisCache" -CachePath $cachePath
        if ($null -eq $cache) {
            Write-Warning "Impossible d'initialiser le cache. L'analyse sera effectuée sans cache."
            $UseCache = $false
        }
    }

    # Détecter les changements significatifs
    Write-Host "`nDétection des changements significatifs..." -ForegroundColor Cyan
    
    $significantChangesPath = Join-Path -Path $OutputPath -ChildPath "significant_changes_$($prInfo.Number).json"
    $significantChangesScript = Join-Path -Path $PSScriptRoot -ChildPath "Test-SignificantChanges.ps1"
    
    if (Test-Path -Path $significantChangesScript) {
        & $significantChangesScript -RepositoryPath $RepositoryPath -PullRequestNumber $prInfo.Number -OutputPath $significantChangesPath -ThresholdRatio $ThresholdRatio -MinimumChanges $MinimumChanges -DetailLevel "Detailed"
    } else {
        Write-Error "Script de détection des changements significatifs non trouvé: $significantChangesScript"
        exit 1
    }
    
    # Charger les résultats de l'analyse des changements significatifs
    if (-not (Test-Path -Path $significantChangesPath)) {
        Write-Error "Résultats de l'analyse des changements significatifs non trouvés: $significantChangesPath"
        exit 1
    }
    
    $significantChanges = Get-Content -Path $significantChangesPath -Raw | ConvertFrom-Json
    
    # Créer l'analyseur syntaxique
    $analyzer = New-SyntaxAnalyzer -UseCache $UseCache -Cache $cache
    if ($null -eq $analyzer) {
        Write-Error "Impossible de créer l'analyseur syntaxique."
        exit 1
    }

    # Analyser les fichiers
    $results = [System.Collections.Generic.List[object]]::new()
    $totalFiles = $prInfo.Files.Count
    $analyzedFiles = 0
    $skippedFiles = 0
    $significantFiles = $significantChanges.SignificantFiles

    Write-Host "`nDémarrage de l'analyse incrémentale..." -ForegroundColor Cyan
    Write-Host "  Fichiers modifiés: $totalFiles" -ForegroundColor White
    Write-Host "  Fichiers avec changements significatifs: $significantFiles" -ForegroundColor White
    Write-Host "  Utilisation du cache: $UseCache" -ForegroundColor White
    Write-Host "  Forcer l'analyse complète: $ForceFullAnalysis" -ForegroundColor White

    $i = 0
    foreach ($file in $prInfo.Files) {
        $i++
        $filePath = $file.path
        
        # Vérifier si le fichier a des changements significatifs
        $fileChanges = $significantChanges.Results | Where-Object { $_.FilePath -eq $filePath }
        $isSignificant = $null -ne $fileChanges -and $fileChanges.IsSignificant
        
        # Décider si le fichier doit être analysé
        $shouldAnalyze = $isSignificant -or $ForceFullAnalysis
        
        # Afficher la progression
        Write-Progress -Activity "Analyse incrémentale" -Status "Fichier $i/$totalFiles" -PercentComplete (($i / $totalFiles) * 100)
        
        if ($shouldAnalyze) {
            # Analyser le fichier
            $fileResult = Invoke-FileAnalysis -File $file -Analyzer $analyzer -Cache $cache -UseFileCache $UseCache -RepoPath $RepositoryPath
            
            # Ajouter le résultat à la liste
            $results.Add($fileResult)
            
            # Mettre à jour le compteur
            $analyzedFiles++
        } else {
            # Créer un résultat vide pour le fichier ignoré
            $emptyResult = [PSCustomObject]@{
                FilePath = $filePath
                Issues = @()
                StartTime = Get-Date
                EndTime = Get-Date
                Duration = [TimeSpan]::Zero
                Success = $true
                FromCache = $false
                Skipped = $true
            }
            
            # Ajouter le résultat à la liste
            $results.Add($emptyResult)
            
            # Mettre à jour le compteur
            $skippedFiles++
        }
    }

    Write-Progress -Activity "Analyse incrémentale" -Completed

    # Générer le rapport
    $reportPaths = New-AnalysisReport -Results $results -PullRequestInfo $prInfo -OutputDir $OutputPath -SignificantChanges $significantChanges
    if ($null -eq $reportPaths) {
        Write-Error "Impossible de générer le rapport d'analyse."
        exit 1
    }

    # Arrêter le chronomètre
    $stopwatch.Stop()

    # Afficher un résumé
    Write-Host "`nAnalyse terminée en $($stopwatch.Elapsed.TotalSeconds) secondes." -ForegroundColor Green
    Write-Host "  Fichiers analysés: $analyzedFiles" -ForegroundColor White
    Write-Host "  Fichiers ignorés: $skippedFiles" -ForegroundColor White
    Write-Host "  Problèmes détectés: $(($results | Where-Object { $_.Success } | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum).Sum)" -ForegroundColor White
    
    if ($UseCache) {
        $cacheHits = ($results | Where-Object { $_.FromCache } | Measure-Object).Count
        Write-Host "  Fichiers mis en cache: $cacheHits" -ForegroundColor White
    }
    
    Write-Host "  Rapport JSON: $($reportPaths.JsonPath)" -ForegroundColor White
    Write-Host "  Rapport HTML: $($reportPaths.HtmlPath)" -ForegroundColor White

    # Ouvrir le rapport HTML dans le navigateur par défaut
    if (Test-Path -Path $reportPaths.HtmlPath) {
        Start-Process $reportPaths.HtmlPath
    }

    # Retourner les résultats
    return $results
} catch {
    Write-Error "Erreur lors de l'analyse incrémentale: $_"
    exit 1
}

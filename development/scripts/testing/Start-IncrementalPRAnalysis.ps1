﻿#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©marre une analyse incrÃ©mentale des pull requests.

.DESCRIPTION
    Ce script exÃ©cute une analyse incrÃ©mentale des pull requests, en se concentrant
    uniquement sur les fichiers qui ont Ã©tÃ© modifiÃ©s de maniÃ¨re significative.

.PARAMETER RepositoryPath
    Le chemin du dÃ©pÃ´t Ã  analyser.
    Par dÃ©faut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER PullRequestNumber
    Le numÃ©ro de la pull request Ã  analyser.
    Si non spÃ©cifiÃ©, la derniÃ¨re pull request sera utilisÃ©e.

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer les rÃ©sultats de l'analyse.
    Par dÃ©faut: "reports\pr-analysis"

.PARAMETER UseCache
    Indique s'il faut utiliser le cache pour amÃ©liorer les performances.
    Par dÃ©faut: $true

.PARAMETER ThresholdRatio
    Le ratio de changement Ã  partir duquel une modification est considÃ©rÃ©e comme significative.
    Par dÃ©faut: 0.1 (10%)

.PARAMETER MinimumChanges
    Le nombre minimum de lignes modifiÃ©es pour qu'un fichier soit considÃ©rÃ© comme significativement modifiÃ©.
    Par dÃ©faut: 5

.PARAMETER ForceFullAnalysis
    Indique s'il faut forcer une analyse complÃ¨te, mÃªme pour les fichiers non significativement modifiÃ©s.
    Par dÃ©faut: $false

.EXAMPLE
    .\Start-IncrementalPRAnalysis.ps1
    Analyse de maniÃ¨re incrÃ©mentale la derniÃ¨re pull request.

.EXAMPLE
    .\Start-IncrementalPRAnalysis.ps1 -PullRequestNumber 42 -ThresholdRatio 0.05 -ForceFullAnalysis $true
    Analyse de maniÃ¨re incrÃ©mentale la pull request #42 avec un seuil de 5% et force une analyse complÃ¨te.

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

# Importer les modules nÃ©cessaires
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
        Write-Error "Module $module non trouvÃ© Ã  l'emplacement: $modulePath"
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
        # VÃ©rifier si le dÃ©pÃ´t existe
        if (-not (Test-Path -Path $RepoPath)) {
            throw "Le dÃ©pÃ´t n'existe pas Ã  l'emplacement spÃ©cifiÃ©: $RepoPath"
        }

        # Changer de rÃ©pertoire vers le dÃ©pÃ´t
        Push-Location -Path $RepoPath

        try {
            # Si aucun numÃ©ro de PR n'est spÃ©cifiÃ©, utiliser la derniÃ¨re PR
            if ($PRNumber -eq 0) {
                $prs = gh pr list --json number, title, headRefName, baseRefName, createdAt --limit 1 | ConvertFrom-Json
                if ($prs.Count -eq 0) {
                    throw "Aucune pull request trouvÃ©e dans le dÃ©pÃ´t."
                }
                $pr = $prs[0]
            } else {
                $pr = gh pr view $PRNumber --json number, title, headRefName, baseRefName, createdAt | ConvertFrom-Json
                if ($null -eq $pr) {
                    throw "Pull request #$PRNumber non trouvÃ©e."
                }
            }

            # Obtenir les fichiers modifiÃ©s
            $files = gh pr view $pr.number --json files | ConvertFrom-Json

            # CrÃ©er l'objet d'informations sur la PR
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
            # Revenir au rÃ©pertoire prÃ©cÃ©dent
            Pop-Location
        }
    } catch {
        Write-Error "Erreur lors de la rÃ©cupÃ©ration des informations sur la pull request: $_"
        return $null
    }
}

# Fonction pour analyser un fichier avec optimisation des performances
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
        [string]$RepoPath,

        [Parameter()]
        [bool]$CollectPerformanceMetrics = $true,

        [Parameter()]
        [bool]$UseParallelAnalysis = $false,

        [Parameter()]
        [int]$SignificanceScore = 0
    )

    try {
        # DÃ©marrer le chronomÃ¨tre pour mesurer les performances
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # CrÃ©er un objet pour stocker les rÃ©sultats
        $result = [PSCustomObject]@{
            FilePath          = $File.path
            Issues            = @()
            StartTime         = Get-Date
            EndTime           = $null
            Duration          = $null
            Success           = $false
            FromCache         = $false
            FileSize          = 0
            AnalysisTimeMs    = 0
            TotalTimeMs       = 0
            SignificanceScore = $SignificanceScore
            FileExtension     = [System.IO.Path]::GetExtension($File.path)
            IssuesByType      = @{}
            IssuesBySeverity  = @{}
        }

        # GÃ©nÃ©rer une clÃ© de cache unique
        $cacheKey = "IncrementalAnalysis:${File.path}:${File.sha}:$CollectPerformanceMetrics"

        # Essayer d'obtenir les rÃ©sultats du cache
        if ($UseFileCache) {
            $cachedResult = $Cache.Get($cacheKey)
            if ($null -ne $cachedResult) {
                # Ajouter des informations sur l'utilisation du cache
                $cachedResult | Add-Member -MemberType NoteProperty -Name "FromCache" -Value $true -Force
                $stopwatch.Stop()
                $cachedResult.TotalTimeMs = $stopwatch.ElapsedMilliseconds

                return $cachedResult
            }
        }

        # Construire le chemin complet du fichier
        $filePath = Join-Path -Path $RepoPath -ChildPath $File.path

        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $filePath)) {
            $result.EndTime = Get-Date
            $result.Duration = $result.EndTime - $result.StartTime
            $result.Success = $false
            $stopwatch.Stop()
            $result.TotalTimeMs = $stopwatch.ElapsedMilliseconds
            return $result
        }

        # Obtenir la taille du fichier
        $fileInfo = Get-Item -Path $filePath
        $result.FileSize = $fileInfo.Length

        # ChronomÃ©trer l'analyse
        $analysisStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Analyser le fichier
        if ($UseParallelAnalysis -and $result.FileSize -gt 100KB) {
            # Pour les gros fichiers, utiliser l'analyse parallÃ¨le
            $issues = $Analyzer.AnalyzeFiles(@($filePath))[$filePath]
        } else {
            # Pour les petits fichiers, utiliser l'analyse sÃ©quentielle
            $issues = $Analyzer.AnalyzeFile($filePath)
        }

        $analysisStopwatch.Stop()
        $result.AnalysisTimeMs = $analysisStopwatch.ElapsedMilliseconds

        # Mettre Ã  jour les rÃ©sultats
        $result.Issues = $issues
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
        $result.Success = $true

        # Collecter des mÃ©triques supplÃ©mentaires si demandÃ©
        if ($CollectPerformanceMetrics) {
            # Grouper les problÃ¨mes par type
            $result.IssuesByType = $issues | Group-Object -Property Type -AsHashTable -AsString

            # Grouper les problÃ¨mes par sÃ©vÃ©ritÃ©
            $result.IssuesBySeverity = $issues | Group-Object -Property Severity -AsHashTable -AsString
        }

        # Stocker les rÃ©sultats dans le cache
        if ($UseFileCache) {
            $Cache.Set($cacheKey, $result)
        }

        $stopwatch.Stop()
        $result.TotalTimeMs = $stopwatch.ElapsedMilliseconds

        return $result
    } catch {
        # GÃ©rer les erreurs
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
        $result.Success = $false

        Write-Error "Erreur lors de l'analyse du fichier $($File.path) : $_"

        $stopwatch.Stop()
        $result.TotalTimeMs = $stopwatch.ElapsedMilliseconds

        return $result
    }
}

# Fonction pour gÃ©nÃ©rer un rapport d'analyse
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
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
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

        # CrÃ©er le rapport
        $reportData = [PSCustomObject]@{
            PullRequest        = $PullRequestInfo
            Timestamp          = Get-Date
            TotalFiles         = $totalFiles
            TotalIssues        = $totalIssues
            TotalDurationMs    = $totalDuration
            AverageDurationMs  = $averageDuration
            MaxDurationMs      = $maxDuration
            MinDurationMs      = $minDuration
            SuccessCount       = $successCount
            FailureCount       = $failureCount
            CachedCount        = $cachedCount
            IssuesByType       = $issuesByType
            Results            = $Results
            SignificantChanges = $SignificantChanges
            AnalysisType       = "Incremental"
        }

        # Enregistrer le rapport au format JSON
        $reportPath = Join-Path -Path $OutputDir -ChildPath "incremental_analysis_$($PullRequestInfo.Number).json"
        $reportData | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding UTF8

        # GÃ©nÃ©rer un rapport HTML
        $htmlReportPath = Join-Path -Path $OutputDir -ChildPath "incremental_analysis_$($PullRequestInfo.Number).html"
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'Analyse IncrÃ©mentale - PR #$($PullRequestInfo.Number)</title>
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
        <h1>Rapport d'Analyse IncrÃ©mentale - Pull Request #$($PullRequestInfo.Number)</h1>

        <div class="summary">
            <h2>RÃ©sumÃ©</h2>
            <p><strong>Titre:</strong> $($PullRequestInfo.Title)</p>
            <p><strong>Branche source:</strong> $($PullRequestInfo.HeadBranch)</p>
            <p><strong>Branche cible:</strong> $($PullRequestInfo.BaseBranch)</p>
            <p><strong>Fichiers analysÃ©s:</strong> $totalFiles</p>
            <p><strong>ProblÃ¨mes dÃ©tectÃ©s:</strong> $totalIssues</p>
            <p><strong>DurÃ©e totale:</strong> $([Math]::Round($totalDuration / 1000, 2)) secondes</p>
            <p><strong>DurÃ©e moyenne par fichier:</strong> $([Math]::Round($averageDuration, 2)) ms</p>
            <p><strong>Fichiers mis en cache:</strong> $cachedCount</p>
            <p><strong>Fichiers avec changements significatifs:</strong> $($SignificantChanges.SignificantFiles) sur $($SignificantChanges.TotalFiles) ($($SignificantChanges.SignificantRatio)%)</p>
        </div>

        <h2>ProblÃ¨mes par Type</h2>
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

        <h2>Fichiers avec ProblÃ¨mes</h2>
        <table>
            <tr>
                <th>Fichier</th>
                <th>ProblÃ¨mes</th>
                <th>Taille (KB)</th>
                <th>Extension</th>
                <th>DurÃ©e totale (ms)</th>
                <th>Analyse (ms)</th>
                <th>Score</th>
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
                <td>$([Math]::Round($result.FileSize / 1KB, 2))</td>
                <td>$($result.FileExtension)</td>
                <td>$($result.TotalTimeMs)</td>
                <td>$($result.AnalysisTimeMs)</td>
                <td>$($result.SignificanceScore)</td>
                <td>$($result.FromCache)</td>
                <td class="$significantClass">$isSignificant</td>
            </tr>
"@
        }

        $html += @"
        </table>

        <h2>DÃ©tails des ProblÃ¨mes</h2>
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
                <th>SÃ©vÃ©ritÃ©</th>
                <th>RÃ¨gle</th>
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
        Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport: $_"
        return $null
    }
}

# Point d'entrÃ©e principal
try {
    # Mesurer le temps d'exÃ©cution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Obtenir les informations sur la pull request
    $prInfo = Get-PullRequestInfo -RepoPath $RepositoryPath -PRNumber $PullRequestNumber
    if ($null -eq $prInfo) {
        Write-Error "Impossible d'obtenir les informations sur la pull request."
        exit 1
    }

    # Afficher les informations sur la pull request
    Write-Host "Informations sur la pull request:" -ForegroundColor Cyan
    Write-Host "  NumÃ©ro: #$($prInfo.Number)" -ForegroundColor White
    Write-Host "  Titre: $($prInfo.Title)" -ForegroundColor White
    Write-Host "  Branche source: $($prInfo.HeadBranch)" -ForegroundColor White
    Write-Host "  Branche cible: $($prInfo.BaseBranch)" -ForegroundColor White
    Write-Host "  Fichiers modifiÃ©s: $($prInfo.FileCount)" -ForegroundColor White
    Write-Host "  Ajouts: $($prInfo.Additions)" -ForegroundColor White
    Write-Host "  Suppressions: $($prInfo.Deletions)" -ForegroundColor White
    Write-Host "  Modifications totales: $($prInfo.Changes)" -ForegroundColor White

    # Initialiser le cache
    $cache = $null
    if ($UseCache) {
        $cachePath = Join-Path -Path $PSScriptRoot -ChildPath "cache\pr-analysis"
        $cache = New-PRAnalysisCache -Name "PRAnalysisCache" -CachePath $cachePath
        if ($null -eq $cache) {
            Write-Warning "Impossible d'initialiser le cache. L'analyse sera effectuÃ©e sans cache."
            $UseCache = $false
        }
    }

    # DÃ©tecter les changements significatifs
    Write-Host "`nDÃ©tection des changements significatifs..." -ForegroundColor Cyan

    $significantChangesPath = Join-Path -Path $OutputPath -ChildPath "significant_changes_$($prInfo.Number).json"
    $significantChangesScript = Join-Path -Path $PSScriptRoot -ChildPath "Test-SignificantChanges.ps1"

    if (Test-Path -Path $significantChangesScript) {
        & $significantChangesScript -RepositoryPath $RepositoryPath -PullRequestNumber $prInfo.Number -OutputPath $significantChangesPath -ThresholdRatio $ThresholdRatio -MinimumChanges $MinimumChanges -DetailLevel "Detailed"
    } else {
        Write-Error "Script de dÃ©tection des changements significatifs non trouvÃ©: $significantChangesScript"
        exit 1
    }

    # Charger les rÃ©sultats de l'analyse des changements significatifs
    if (-not (Test-Path -Path $significantChangesPath)) {
        Write-Error "RÃ©sultats de l'analyse des changements significatifs non trouvÃ©s: $significantChangesPath"
        exit 1
    }

    $significantChanges = Get-Content -Path $significantChangesPath -Raw | ConvertFrom-Json

    # CrÃ©er l'analyseur syntaxique
    $analyzer = New-SyntaxAnalyzer -UseCache $UseCache -Cache $cache
    if ($null -eq $analyzer) {
        Write-Error "Impossible de crÃ©er l'analyseur syntaxique."
        exit 1
    }

    # Analyser les fichiers
    $results = [System.Collections.Generic.List[object]]::new()
    $totalFiles = $prInfo.Files.Count
    $analyzedFiles = 0
    $skippedFiles = 0
    $significantFiles = $significantChanges.SignificantFiles

    Write-Host "`nDÃ©marrage de l'analyse incrÃ©mentale..." -ForegroundColor Cyan
    Write-Host "  Fichiers modifiÃ©s: $totalFiles" -ForegroundColor White
    Write-Host "  Fichiers avec changements significatifs: $significantFiles" -ForegroundColor White
    Write-Host "  Utilisation du cache: $UseCache" -ForegroundColor White
    Write-Host "  Forcer l'analyse complÃ¨te: $ForceFullAnalysis" -ForegroundColor White

    $i = 0
    foreach ($file in $prInfo.Files) {
        $i++
        $filePath = $file.path

        # VÃ©rifier si le fichier a des changements significatifs
        $fileChanges = $significantChanges.Results | Where-Object { $_.FilePath -eq $filePath }
        $isSignificant = $null -ne $fileChanges -and $fileChanges.IsSignificant

        # DÃ©cider si le fichier doit Ãªtre analysÃ©
        $shouldAnalyze = $isSignificant -or $ForceFullAnalysis

        # Afficher la progression
        Write-Progress -Activity "Analyse incrÃ©mentale" -Status "Fichier $i/$totalFiles" -PercentComplete (($i / $totalFiles) * 100)

        if ($shouldAnalyze) {
            # Obtenir le score de significativitÃ© si disponible
            $significanceScore = 0
            $fileChanges = $significantChanges.Results | Where-Object { $_.FilePath -eq $filePath }
            if ($null -ne $fileChanges -and $null -ne $fileChanges.Score) {
                $significanceScore = $fileChanges.Score
            }

            # DÃ©terminer si l'analyse parallÃ¨le doit Ãªtre utilisÃ©e
            $useParallel = $false
            if ($file.additions + $file.deletions -gt 100) {
                # Pour les fichiers avec beaucoup de changements, utiliser l'analyse parallÃ¨le
                $useParallel = $true
            }

            # Analyser le fichier
            $fileResult = Invoke-FileAnalysis -File $file -Analyzer $analyzer -Cache $cache -UseFileCache $UseCache -RepoPath $RepositoryPath -SignificanceScore $significanceScore -UseParallelAnalysis $useParallel

            # Ajouter le rÃ©sultat Ã  la liste
            $results.Add($fileResult)

            # Mettre Ã  jour le compteur
            $analyzedFiles++

            # Afficher des informations sur l'analyse
            Write-Verbose "Analyse de ${filePath}: $($fileResult.Issues.Count) problÃ¨mes, $($fileResult.TotalTimeMs) ms, $([Math]::Round($fileResult.FileSize / 1KB, 2)) KB"
        } else {
            # CrÃ©er un rÃ©sultat vide pour le fichier ignorÃ©
            $emptyResult = [PSCustomObject]@{
                FilePath          = $filePath
                Issues            = @()
                StartTime         = Get-Date
                EndTime           = Get-Date
                Duration          = [TimeSpan]::Zero
                Success           = $true
                FromCache         = $false
                Skipped           = $true
                FileSize          = 0
                AnalysisTimeMs    = 0
                TotalTimeMs       = 0
                SignificanceScore = 0
                FileExtension     = [System.IO.Path]::GetExtension($filePath)
                IssuesByType      = @{}
                IssuesBySeverity  = @{}
            }

            # Ajouter le rÃ©sultat Ã  la liste
            $results.Add($emptyResult)

            # Mettre Ã  jour le compteur
            $skippedFiles++

            # Afficher des informations sur le fichier ignorÃ©
            Write-Verbose "Fichier ignorÃ©: ${filePath} (pas de changements significatifs)"
        }
    }

    Write-Progress -Activity "Analyse incrÃ©mentale" -Completed

    # GÃ©nÃ©rer le rapport
    $reportPaths = New-AnalysisReport -Results $results -PullRequestInfo $prInfo -OutputDir $OutputPath -SignificantChanges $significantChanges
    if ($null -eq $reportPaths) {
        Write-Error "Impossible de gÃ©nÃ©rer le rapport d'analyse."
        exit 1
    }

    # ArrÃªter le chronomÃ¨tre
    $stopwatch.Stop()

    # Afficher un rÃ©sumÃ©
    Write-Host "`nAnalyse terminÃ©e en $($stopwatch.Elapsed.TotalSeconds) secondes." -ForegroundColor Green
    Write-Host "  Fichiers analysÃ©s: $analyzedFiles" -ForegroundColor White
    Write-Host "  Fichiers ignorÃ©s: $skippedFiles" -ForegroundColor White
    Write-Host "  ProblÃ¨mes dÃ©tectÃ©s: $(($results | Where-Object { $_.Success } | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum).Sum)" -ForegroundColor White

    if ($UseCache) {
        $cacheHits = ($results | Where-Object { $_.FromCache } | Measure-Object).Count
        Write-Host "  Fichiers mis en cache: $cacheHits" -ForegroundColor White
    }

    Write-Host "  Rapport JSON: $($reportPaths.JsonPath)" -ForegroundColor White
    Write-Host "  Rapport HTML: $($reportPaths.HtmlPath)" -ForegroundColor White

    # Ouvrir le rapport HTML dans le navigateur par dÃ©faut
    if (Test-Path -Path $reportPaths.HtmlPath) {
        Start-Process $reportPaths.HtmlPath
    }

    # Retourner les rÃ©sultats
    return $results
} catch {
    Write-Error "Erreur lors de l'analyse incrÃ©mentale: $_"
    exit 1
}

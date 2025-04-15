#Requires -Version 5.1
<#
.SYNOPSIS
    Démarre une analyse partielle intelligente des pull requests.

.DESCRIPTION
    Ce script exécute une analyse partielle intelligente des pull requests,
    en se concentrant sur les parties spécifiques des fichiers qui ont été modifiées.

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

.PARAMETER ContextLines
    Le nombre de lignes de contexte à inclure autour des modifications.
    Par défaut: 3

.EXAMPLE
    .\Start-SmartPartialAnalysis.ps1
    Analyse de manière partielle intelligente la dernière pull request.

.EXAMPLE
    .\Start-SmartPartialAnalysis.ps1 -PullRequestNumber 42 -ContextLines 5
    Analyse de manière partielle intelligente la pull request #42 avec 5 lignes de contexte.

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
    [int]$ContextLines = 3
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
                $prs = gh pr list --json number, title, headRefName, baseRefName, createdAt --limit 1 | ConvertFrom-Json
                if ($prs.Count -eq 0) {
                    throw "Aucune pull request trouvée dans le dépôt."
                }
                $pr = $prs[0]
            } else {
                $pr = gh pr view $PRNumber --json number, title, headRefName, baseRefName, createdAt | ConvertFrom-Json
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

# Fonction pour obtenir les différences entre deux versions d'un fichier
function Get-FileDiff {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$BaseBranch,

        [Parameter(Mandatory = $true)]
        [string]$HeadBranch
    )

    try {
        # Changer de répertoire vers le dépôt
        Push-Location -Path $RepoPath

        try {
            # Obtenir les différences
            $diff = git diff "$BaseBranch..$HeadBranch" -- "$FilePath"

            # Analyser les différences pour obtenir les lignes modifiées
            $changedLines = [System.Collections.Generic.List[PSCustomObject]]::new()
            $currentLine = 0
            $inHunk = $false

            foreach ($line in ($diff -split "`n")) {
                if ($line -match '^@@\s+-(\d+),(\d+)\s+\+(\d+),(\d+)\s+@@') {
                    $inHunk = $true
                    # Variables utilisées uniquement pour le débogage, commentées pour éviter les avertissements
                    # $oldStart = [int]$Matches[1]
                    # $oldCount = [int]$Matches[2]
                    $newStart = [int]$Matches[3]
                    # $newCount = [int]$Matches[4]
                    $currentLine = $newStart
                } elseif ($inHunk) {
                    if ($line.StartsWith('+') -and -not $line.StartsWith('++')) {
                        # Ligne ajoutée
                        $changedLines.Add([PSCustomObject]@{
                                LineNumber = $currentLine
                                Type       = "Addition"
                                Content    = $line.Substring(1)
                            })
                        $currentLine++
                    } elseif ($line.StartsWith('-') -and -not $line.StartsWith('--')) {
                        # Ligne supprimée (ne pas incrémenter le numéro de ligne)
                        # Nous ne l'ajoutons pas car elle n'existe plus dans la version actuelle
                    } elseif (-not $line.StartsWith('\\')) {
                        # Ligne inchangée
                        $currentLine++
                    }
                }
            }

            return $changedLines
        } finally {
            # Revenir au répertoire précédent
            Pop-Location
        }
    } catch {
        Write-Error "Erreur lors de la récupération des différences du fichier $FilePath : $_"
        return $null
    }
}

# Fonction pour analyser partiellement un fichier avec optimisation des performances
function Invoke-PartialFileAnalysis {
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

        [Parameter(Mandatory = $true)]
        [string]$BaseBranch,

        [Parameter(Mandatory = $true)]
        [string]$HeadBranch,

        [Parameter(Mandatory = $true)]
        [int]$Context,

        [Parameter()]
        [bool]$UseIntelligentContext = $true,

        [Parameter()]
        [bool]$IncludeSymbolContext = $true
    )

    try {
        # Démarrer le chronomètre pour mesurer les performances
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Créer un objet pour stocker les résultats
        $result = [PSCustomObject]@{
            FilePath        = $File.path
            Issues          = @()
            StartTime       = Get-Date
            EndTime         = $null
            Duration        = $null
            Success         = $false
            FromCache       = $false
            ChangedLines    = 0
            AnalyzedLines   = 0
            AnalysisTimeMs  = 0
            DiffTimeMs      = 0
            ContextTimeMs   = 0
            FilterTimeMs    = 0
            TotalTimeMs     = 0
            FileSize        = 0
            SymbolsAnalyzed = 0
            ContextStrategy = "Standard"
        }

        # Générer une clé de cache unique
        $cacheKey = "PartialAnalysis:$($File.path):$($File.sha):${Context}:${UseIntelligentContext}:${IncludeSymbolContext}"

        # Essayer d'obtenir les résultats du cache
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

        # Vérifier si le fichier existe
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

        # Chronométrer l'obtention des différences
        $diffStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Obtenir les lignes modifiées
        $changedLines = Get-FileDiff -RepoPath $RepoPath -FilePath $File.path -BaseBranch $BaseBranch -HeadBranch $HeadBranch

        $diffStopwatch.Stop()
        $result.DiffTimeMs = $diffStopwatch.ElapsedMilliseconds

        if ($null -eq $changedLines -or $changedLines.Count -eq 0) {
            # Analyser le fichier complet si nous ne pouvons pas obtenir les différences
            $analysisStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $issues = $Analyzer.AnalyzeFile($filePath)
            $analysisStopwatch.Stop()
            $result.AnalysisTimeMs = $analysisStopwatch.ElapsedMilliseconds

            # Mettre à jour les résultats
            $result.Issues = $issues
            $result.EndTime = Get-Date
            $result.Duration = $result.EndTime - $result.StartTime
            $result.Success = $true
            $result.ChangedLines = 0
            $result.AnalyzedLines = (Get-Content -Path $filePath).Count
            $result.ContextStrategy = "FullFile"

            $stopwatch.Stop()
            $result.TotalTimeMs = $stopwatch.ElapsedMilliseconds

            return $result
        }

        # Chronométrer la détermination du contexte
        $contextStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Déterminer les plages de lignes à analyser
        $linesToAnalyze = [System.Collections.Generic.HashSet[int]]::new()

        # Ajouter les lignes modifiées et leur contexte
        foreach ($line in $changedLines) {
            # Ajouter la ligne modifiée
            $linesToAnalyze.Add($line.LineNumber) | Out-Null

            # Ajouter les lignes de contexte standard
            for ($i = [Math]::Max(1, $line.LineNumber - $Context); $i -le $line.LineNumber + $Context; $i++) {
                $linesToAnalyze.Add($i) | Out-Null
            }
        }

        # Utiliser un contexte intelligent si demandé
        if ($UseIntelligentContext) {
            $result.ContextStrategy = "Intelligent"

            # Lire le contenu du fichier
            $content = Get-Content -Path $filePath -Raw

            # Trouver les blocs logiques (fonctions, classes, etc.)
            $extension = [System.IO.Path]::GetExtension($filePath).ToLower()

            # Utiliser des expressions régulières spécifiques au langage pour trouver les blocs
            $blockPatterns = @{
                ".ps1"  = '(?i)function\s+([a-z0-9_-]+)\s*\{|\s*class\s+([a-z0-9_-]+)\s*\{'
                ".psm1" = '(?i)function\s+([a-z0-9_-]+)\s*\{|\s*class\s+([a-z0-9_-]+)\s*\{'
                ".py"   = '(?i)def\s+([a-z0-9_]+)|\s*class\s+([a-z0-9_]+)'
                ".js"   = '(?i)function\s+([a-z0-9_$]+)|\s*class\s+([a-z0-9_$]+)|([a-z0-9_$]+)\s*=\s*function'
                ".html" = '<([a-z][a-z0-9]*)\b[^>]*>|</([a-z][a-z0-9]*)>'
                ".css"  = '([.#][a-z0-9_-]+)\s*\{'
            }

            if ($blockPatterns.ContainsKey($extension)) {
                $pattern = $blockPatterns[$extension]
                $blockMatches = [regex]::Matches($content, $pattern)

                # Pour chaque bloc trouvé, vérifier s'il contient des lignes modifiées
                foreach ($match in $blockMatches) {
                    $blockStartLine = $content.Substring(0, $match.Index).Split("`n").Count

                    # Trouver la fin du bloc (accolade fermante ou indentation)
                    $blockEndLine = $blockStartLine

                    # Vérifier si une ligne modifiée est dans ce bloc
                    $blockContainsChanges = $changedLines | Where-Object { $_.LineNumber -ge $blockStartLine -and $_.LineNumber -le $blockEndLine }

                    if ($blockContainsChanges.Count -gt 0) {
                        # Ajouter toutes les lignes du bloc au contexte
                        for ($i = $blockStartLine; $i -le $blockEndLine; $i++) {
                            $linesToAnalyze.Add($i) | Out-Null
                        }
                    }
                }
            }
        }

        # Ajouter le contexte des symboles si demandé
        if ($IncludeSymbolContext) {
            # Utiliser l'indexeur pour trouver les symboles (fonctions, variables, etc.)
            $indexer = New-FileContentIndexer
            $index = $indexer.IndexFile($filePath)

            if ($null -ne $index) {
                $result.SymbolsAnalyzed = $index.Symbols.Count

                # Pour chaque ligne modifiée, trouver les symboles utilisés
                foreach ($line in $changedLines) {
                    $lineNumber = $line.LineNumber

                    # Trouver les symboles utilisés dans cette ligne
                    $lineSymbols = $index.Symbols.GetEnumerator() | Where-Object { $_.Value -eq $lineNumber }

                    # Ajouter les lignes où ces symboles sont définis ou utilisés
                    foreach ($symbol in $lineSymbols) {
                        $symbolName = $symbol.Key

                        # Trouver toutes les occurrences de ce symbole
                        $symbolOccurrences = $index.Symbols.GetEnumerator() | Where-Object { $_.Key -eq $symbolName }

                        foreach ($occurrence in $symbolOccurrences) {
                            $linesToAnalyze.Add($occurrence.Value) | Out-Null
                        }
                    }
                }
            }
        }

        $contextStopwatch.Stop()
        $result.ContextTimeMs = $contextStopwatch.ElapsedMilliseconds

        # Vérifier que le fichier existe et est lisible
        if (-not (Test-Path -Path $filePath -PathType Leaf)) {
            Write-Warning "Le fichier $filePath n'existe pas ou n'est pas accessible."
            $stopwatch.Stop()
            $result.TotalTimeMs = $stopwatch.ElapsedMilliseconds
            return $result
        }

        # Chronométrer l'analyse
        $analysisStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Analyser le fichier complet
        $allIssues = $Analyzer.AnalyzeFile($filePath)

        $analysisStopwatch.Stop()
        $result.AnalysisTimeMs = $analysisStopwatch.ElapsedMilliseconds

        # Chronométrer le filtrage
        $filterStopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Filtrer les problèmes pour ne garder que ceux dans les lignes à analyser
        $filteredIssues = $allIssues | Where-Object { $linesToAnalyze.Contains($_.Line) }

        $filterStopwatch.Stop()
        $result.FilterTimeMs = $filterStopwatch.ElapsedMilliseconds

        # Mettre à jour les résultats
        $result.Issues = $filteredIssues
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
        $result.Success = $true
        $result.ChangedLines = $changedLines.Count
        $result.AnalyzedLines = $linesToAnalyze.Count

        # Stocker les résultats dans le cache
        if ($UseFileCache) {
            $Cache.Set($cacheKey, $result)
        }

        $stopwatch.Stop()
        $result.TotalTimeMs = $stopwatch.ElapsedMilliseconds

        return $result
    } catch {
        # Gérer les erreurs
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
        $result.Success = $false

        Write-Error "Erreur lors de l'analyse partielle du fichier $($File.path) : $_"

        $stopwatch.Stop()
        $result.TotalTimeMs = $stopwatch.ElapsedMilliseconds

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
        [int]$ContextLines
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
        $totalChangedLines = ($Results | ForEach-Object { $_.ChangedLines } | Measure-Object -Sum).Sum
        $totalAnalyzedLines = ($Results | ForEach-Object { $_.AnalyzedLines } | Measure-Object -Sum).Sum

        # Créer le rapport
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
            TotalChangedLines  = $totalChangedLines
            TotalAnalyzedLines = $totalAnalyzedLines
            ContextLines       = $ContextLines
            IssuesByType       = $issuesByType
            Results            = $Results
            AnalysisType       = "SmartPartial"
        }

        # Enregistrer le rapport au format JSON
        $reportPath = Join-Path -Path $OutputDir -ChildPath "smart_partial_analysis_$($PullRequestInfo.Number).json"
        $reportData | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding UTF8

        # Générer un rapport HTML
        $htmlReportPath = Join-Path -Path $OutputDir -ChildPath "smart_partial_analysis_$($PullRequestInfo.Number).html"
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'Analyse Partielle Intelligente - PR #$($PullRequestInfo.Number)</title>
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
        <h1>Rapport d'Analyse Partielle Intelligente - Pull Request #$($PullRequestInfo.Number)</h1>

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
            <p><strong>Lignes modifiées:</strong> $totalChangedLines</p>
            <p><strong>Lignes analysées:</strong> $totalAnalyzedLines</p>
            <p><strong>Lignes de contexte:</strong> $ContextLines</p>
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
                <th>Lignes modifiées</th>
                <th>Lignes analysées</th>
                <th>Taille (KB)</th>
                <th>Stratégie</th>
                <th>Durée totale (ms)</th>
                <th>Analyse (ms)</th>
                <th>Contexte (ms)</th>
                <th>Diff (ms)</th>
                <th>Mis en cache</th>
            </tr>
"@

        foreach ($result in ($Results | Where-Object { $_.Success -and $_.Issues.Count -gt 0 } | Sort-Object -Property { $_.Issues.Count } -Descending)) {
            $html += @"
            <tr>
                <td>$($result.FilePath)</td>
                <td>$($result.Issues.Count)</td>
                <td>$($result.ChangedLines)</td>
                <td>$($result.AnalyzedLines)</td>
                <td>$([Math]::Round($result.FileSize / 1KB, 2))</td>
                <td>$($result.ContextStrategy)</td>
                <td>$($result.TotalTimeMs)</td>
                <td>$($result.AnalysisTimeMs)</td>
                <td>$($result.ContextTimeMs)</td>
                <td>$($result.DiffTimeMs)</td>
                <td>$($result.FromCache)</td>
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

    # Créer l'analyseur syntaxique
    $analyzer = New-SyntaxAnalyzer -UseCache $UseCache -Cache $cache
    if ($null -eq $analyzer) {
        Write-Error "Impossible de créer l'analyseur syntaxique."
        exit 1
    }

    # Analyser les fichiers
    $results = [System.Collections.Generic.List[object]]::new()
    $totalFiles = $prInfo.Files.Count

    Write-Host "`nDémarrage de l'analyse partielle intelligente..." -ForegroundColor Cyan
    Write-Host "  Fichiers modifiés: $totalFiles" -ForegroundColor White
    Write-Host "  Lignes de contexte: $ContextLines" -ForegroundColor White
    Write-Host "  Utilisation du cache: $UseCache" -ForegroundColor White

    $i = 0
    foreach ($file in $prInfo.Files) {
        $i++
        $filePath = $file.path

        # Afficher la progression
        Write-Progress -Activity "Analyse partielle intelligente" -Status "Fichier $i/$totalFiles" -PercentComplete (($i / $totalFiles) * 100)

        # Analyser le fichier
        $fileResult = Invoke-PartialFileAnalysis -File $file -Analyzer $analyzer -Cache $cache -UseFileCache $UseCache -RepoPath $RepositoryPath -BaseBranch $prInfo.BaseBranch -HeadBranch $prInfo.HeadBranch -Context $ContextLines

        # Ajouter le résultat à la liste
        $results.Add($fileResult)
    }

    Write-Progress -Activity "Analyse partielle intelligente" -Completed

    # Générer le rapport
    $reportPaths = New-AnalysisReport -Results $results -PullRequestInfo $prInfo -OutputDir $OutputPath -ContextLines $ContextLines
    if ($null -eq $reportPaths) {
        Write-Error "Impossible de générer le rapport d'analyse."
        exit 1
    }

    # Arrêter le chronomètre
    $stopwatch.Stop()

    # Afficher un résumé
    Write-Host "`nAnalyse terminée en $($stopwatch.Elapsed.TotalSeconds) secondes." -ForegroundColor Green
    Write-Host "  Fichiers analysés: $totalFiles" -ForegroundColor White
    Write-Host "  Problèmes détectés: $(($results | Where-Object { $_.Success } | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum).Sum)" -ForegroundColor White
    Write-Host "  Lignes modifiées: $(($results | ForEach-Object { $_.ChangedLines } | Measure-Object -Sum).Sum)" -ForegroundColor White
    Write-Host "  Lignes analysées: $(($results | ForEach-Object { $_.AnalyzedLines } | Measure-Object -Sum).Sum)" -ForegroundColor White

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
    Write-Error "Erreur lors de l'analyse partielle intelligente: $_"
    exit 1
}

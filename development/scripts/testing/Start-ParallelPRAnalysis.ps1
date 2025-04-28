#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©marre une analyse parallÃ¨le des pull requests.

.DESCRIPTION
    Ce script exÃ©cute l'analyse des pull requests en parallÃ¨le pour amÃ©liorer
    les performances, en utilisant des runspace pools et une rÃ©partition intelligente
    de la charge de travail.

.PARAMETER RepositoryPath
    Le chemin du dÃ©pÃ´t Ã  analyser.
    Par dÃ©faut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER PullRequestNumber
    Le numÃ©ro de la pull request Ã  analyser.
    Si non spÃ©cifiÃ©, la derniÃ¨re pull request sera utilisÃ©e.

.PARAMETER MaxThreads
    Le nombre maximum de threads Ã  utiliser.
    Par dÃ©faut: nombre de processeurs logiques

.PARAMETER ThrottleLimit
    La limite de rÃ©gulation pour les opÃ©rations parallÃ¨les.
    Par dÃ©faut: Ã©gal Ã  MaxThreads

.PARAMETER UseCache
    Indique s'il faut utiliser le cache pour amÃ©liorer les performances.
    Par dÃ©faut: $true

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer les rÃ©sultats de l'analyse.
    Par dÃ©faut: "reports\pr-analysis"

.EXAMPLE
    .\Start-ParallelPRAnalysis.ps1
    Analyse la derniÃ¨re pull request en utilisant le nombre de threads par dÃ©faut.

.EXAMPLE
    .\Start-ParallelPRAnalysis.ps1 -PullRequestNumber 42 -MaxThreads 8 -UseCache $false
    Analyse la pull request #42 en utilisant 8 threads sans cache.

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
    [int]$MaxThreads = 0,

    [Parameter()]
    [int]$ThrottleLimit = 0,

    [Parameter()]
    [bool]$UseCache = $true,

    [Parameter()]
    [string]$OutputPath = "reports\pr-analysis"
)

# Importer les modules nÃ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$modulesToImport = @(
    "ParallelPRAnalysis.psm1",
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
                $prs = gh pr list --json number,title,headRefName,baseRefName,createdAt --limit 1 | ConvertFrom-Json
                if ($prs.Count -eq 0) {
                    throw "Aucune pull request trouvÃ©e dans le dÃ©pÃ´t."
                }
                $pr = $prs[0]
            } else {
                $pr = gh pr view $PRNumber --json number,title,headRefName,baseRefName,createdAt | ConvertFrom-Json
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

# Fonction pour analyser un fichier
function Invoke-FileAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$File,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$SharedState,
        
        [Parameter()]
        [bool]$UseFileCache = $true
    )

    try {
        # CrÃ©er un objet pour stocker les rÃ©sultats
        $result = [PSCustomObject]@{
            FilePath = $File.path
            Issues = @()
            StartTime = Get-Date
            EndTime = $null
            Duration = $null
            Success = $false
        }

        # VÃ©rifier si le fichier est un script PowerShell
        $isPowerShellScript = $File.path -like "*.ps1" -or $File.path -like "*.psm1" -or $File.path -like "*.psd1"
        $isPythonScript = $File.path -like "*.py"

        if (-not ($isPowerShellScript -or $isPythonScript)) {
            # Ignorer les fichiers qui ne sont pas des scripts
            $result.EndTime = Get-Date
            $result.Duration = $result.EndTime - $result.StartTime
            $result.Success = $true
            return $result
        }

        # GÃ©nÃ©rer une clÃ© de cache unique
        $cacheKey = "PR:$($SharedState.PullRequestInfo.Number):File:$($File.path):$($File.sha)"

        # Essayer d'obtenir les rÃ©sultats du cache
        if ($UseFileCache -and $SharedState.UseCache -and $null -ne $SharedState.Cache) {
            $cachedResult = $SharedState.Cache.Get($cacheKey)
            if ($null -ne $cachedResult) {
                # Ajouter des informations sur l'utilisation du cache
                $cachedResult | Add-Member -MemberType NoteProperty -Name "FromCache" -Value $true -Force
                $cachedResult | Add-Member -MemberType NoteProperty -Name "CacheKey" -Value $cacheKey -Force
                
                # Mettre Ã  jour les statistiques
                $SharedState.Stats.CacheHits++
                
                return $cachedResult
            }
            
            # Mettre Ã  jour les statistiques
            $SharedState.Stats.CacheMisses++
        }

        # Simuler l'analyse du fichier
        if ($isPowerShellScript) {
            # Simuler l'analyse d'un script PowerShell
            $analysisDelay = [Math]::Max(100, ($File.additions + $File.deletions) * 5)
            Start-Sleep -Milliseconds $analysisDelay

            # Simuler la dÃ©tection d'erreurs
            $errorTypes = @("Syntax", "Style", "Performance", "Security")
            $errorCount = Get-Random -Minimum 0 -Maximum 10

            for ($i = 0; $i -lt $errorCount; $i++) {
                $errorType = Get-Random -InputObject $errorTypes
                $lineNumber = Get-Random -Minimum 1 -Maximum 100
                
                $issue = [PSCustomObject]@{
                    Type = $errorType
                    LineNumber = $lineNumber
                    Message = "ProblÃ¨me de type $errorType Ã  la ligne $lineNumber"
                    Severity = switch ($errorType) {
                        "Syntax" { "Error" }
                        "Security" { "Critical" }
                        default { "Warning" }
                    }
                }
                
                $result.Issues += $issue
            }
        } elseif ($isPythonScript) {
            # Simuler l'analyse d'un script Python
            $analysisDelay = [Math]::Max(100, ($File.additions + $File.deletions) * 3)
            Start-Sleep -Milliseconds $analysisDelay

            # Simuler la dÃ©tection d'erreurs
            $errorTypes = @("Syntax", "Style", "Performance", "Security")
            $errorCount = Get-Random -Minimum 0 -Maximum 8

            for ($i = 0; $i -lt $errorCount; $i++) {
                $errorType = Get-Random -InputObject $errorTypes
                $lineNumber = Get-Random -Minimum 1 -Maximum 100
                
                $issue = [PSCustomObject]@{
                    Type = $errorType
                    LineNumber = $lineNumber
                    Message = "ProblÃ¨me de type $errorType Ã  la ligne $lineNumber"
                    Severity = switch ($errorType) {
                        "Syntax" { "Error" }
                        "Security" { "Critical" }
                        default { "Warning" }
                    }
                }
                
                $result.Issues += $issue
            }
        }

        # Finaliser les rÃ©sultats
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
        $result.Success = $true

        # Stocker les rÃ©sultats dans le cache
        if ($UseFileCache -and $SharedState.UseCache -and $null -ne $SharedState.Cache) {
            $SharedState.Cache.Set($cacheKey, $result)
        }

        # Ajouter le rÃ©sultat Ã  la liste des rÃ©sultats
        $SharedState.Results.Add($result)

        return $result
    } catch {
        # GÃ©rer les erreurs
        $errorInfo = [PSCustomObject]@{
            FilePath = $File.path
            Error = $_
            Time = Get-Date
        }
        
        $SharedState.Errors.Add($errorInfo)
        
        # Finaliser les rÃ©sultats en cas d'erreur
        $result.EndTime = Get-Date
        $result.Duration = $result.EndTime - $result.StartTime
        $result.Success = $false
        
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
        
        [Parameter()]
        [hashtable]$Stats = @{}
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

        # CrÃ©er le rapport
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
            IssuesByType = $issuesByType
            Results = $Results
            Stats = $Stats
        }

        # Enregistrer le rapport au format JSON
        $reportPath = Join-Path -Path $OutputDir -ChildPath "pr_analysis_$($PullRequestInfo.Number).json"
        $reportData | ConvertTo-Json -Depth 10 | Set-Content -Path $reportPath -Encoding UTF8

        # GÃ©nÃ©rer un rapport HTML
        $htmlReportPath = Join-Path -Path $OutputDir -ChildPath "pr_analysis_$($PullRequestInfo.Number).html"
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'Analyse - PR #$($PullRequestInfo.Number)</title>
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
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport d'Analyse - Pull Request #$($PullRequestInfo.Number)</h1>
        
        <div class="summary">
            <h2>RÃ©sumÃ©</h2>
            <p><strong>Titre:</strong> $($PullRequestInfo.Title)</p>
            <p><strong>Branche source:</strong> $($PullRequestInfo.HeadBranch)</p>
            <p><strong>Branche cible:</strong> $($PullRequestInfo.BaseBranch)</p>
            <p><strong>Fichiers analysÃ©s:</strong> $totalFiles</p>
            <p><strong>ProblÃ¨mes dÃ©tectÃ©s:</strong> $totalIssues</p>
            <p><strong>DurÃ©e totale:</strong> $([Math]::Round($totalDuration / 1000, 2)) secondes</p>
            <p><strong>DurÃ©e moyenne par fichier:</strong> $([Math]::Round($averageDuration, 2)) ms</p>
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
                <th>DurÃ©e (ms)</th>
            </tr>
"@

        foreach ($result in ($Results | Where-Object { $_.Success -and $_.Issues.Count -gt 0 } | Sort-Object -Property { $_.Issues.Count } -Descending)) {
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
        
        <h2>DÃ©tails des ProblÃ¨mes</h2>
"@

        foreach ($result in ($Results | Where-Object { $_.Success -and $_.Issues.Count -gt 0 } | Sort-Object -Property { $_.Issues.Count } -Descending)) {
            $html += @"
        <h3>$($result.FilePath)</h3>
        <table>
            <tr>
                <th>Type</th>
                <th>Ligne</th>
                <th>Message</th>
                <th>SÃ©vÃ©ritÃ©</th>
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

    # Initialiser le cache si nÃ©cessaire
    $cache = $null
    if ($UseCache) {
        $cachePath = Join-Path -Path $PSScriptRoot -ChildPath "cache\pr-analysis"
        $cache = New-PRAnalysisCache -Name "PRAnalysisCache" -CachePath $cachePath
        if ($null -eq $cache) {
            Write-Warning "Impossible d'initialiser le cache. L'analyse sera effectuÃ©e sans cache."
            $UseCache = $false
        }
    }

    # CrÃ©er l'Ã©tat partagÃ©
    $sharedState = [hashtable]::Synchronized(@{
        PullRequestInfo = $prInfo
        Results = [System.Collections.Generic.List[object]]::new()
        Errors = [System.Collections.Generic.List[object]]::new()
        UseCache = $UseCache
        Cache = $cache
        Stats = @{
            CacheHits = 0
            CacheMisses = 0
            StartTime = Get-Date
            EndTime = $null
            TotalDuration = $null
        }
    })

    # DÃ©terminer le nombre de threads Ã  utiliser
    $effectiveMaxThreads = if ($MaxThreads -gt 0) { $MaxThreads } else { [System.Environment]::ProcessorCount }
    $effectiveThrottleLimit = if ($ThrottleLimit -gt 0) { $ThrottleLimit } else { $effectiveMaxThreads }

    Write-Host "`nDÃ©marrage de l'analyse parallÃ¨le avec $effectiveMaxThreads threads..." -ForegroundColor Cyan
    Write-Host "  Utilisation du cache: $UseCache" -ForegroundColor White
    Write-Host "  Fichiers Ã  analyser: $($prInfo.FileCount)" -ForegroundColor White

    # Diviser les fichiers en groupes pour une meilleure rÃ©partition de la charge
    $fileGroups = Split-AnalysisWorkload -Items $prInfo.Files -WeightFunction {
        param($file)
        # Utiliser le nombre de modifications comme poids
        return $file.additions + $file.deletions
    }

    Write-Host "  Fichiers rÃ©partis en $($fileGroups.Count) groupes" -ForegroundColor White

    # CrÃ©er le gestionnaire d'analyse parallÃ¨le
    $manager = New-ParallelAnalysisManager -MaxThreads $effectiveMaxThreads -ThrottleLimit $effectiveThrottleLimit
    if ($null -eq $manager) {
        Write-Error "Impossible de crÃ©er le gestionnaire d'analyse parallÃ¨le."
        exit 1
    }

    # Initialiser le gestionnaire
    $manager.Initialize()

    # Ajouter les tÃ¢ches
    foreach ($fileGroup in $fileGroups) {
        foreach ($file in $fileGroup) {
            $manager.AddJob({
                param($file, $sharedState)
                Invoke-FileAnalysis -File $file -SharedState $sharedState -UseFileCache $true
            }, $file, @{})
        }
    }

    # Attendre la fin de toutes les tÃ¢ches
    $results = $manager.WaitForAll()

    # Nettoyer les ressources
    $manager.Dispose()

    # Finaliser les statistiques
    $sharedState.Stats.EndTime = Get-Date
    $sharedState.Stats.TotalDuration = $sharedState.Stats.EndTime - $sharedState.Stats.StartTime

    # GÃ©nÃ©rer le rapport
    $reportPaths = New-AnalysisReport -Results $sharedState.Results -PullRequestInfo $prInfo -OutputDir $OutputPath -Stats $sharedState.Stats
    if ($null -eq $reportPaths) {
        Write-Error "Impossible de gÃ©nÃ©rer le rapport d'analyse."
        exit 1
    }

    # ArrÃªter le chronomÃ¨tre
    $stopwatch.Stop()

    # Afficher un rÃ©sumÃ©
    Write-Host "`nAnalyse terminÃ©e en $($stopwatch.Elapsed.TotalSeconds) secondes." -ForegroundColor Green
    Write-Host "  Fichiers analysÃ©s: $($sharedState.Results.Count)" -ForegroundColor White
    Write-Host "  ProblÃ¨mes dÃ©tectÃ©s: $(($sharedState.Results | Where-Object { $_.Success } | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum).Sum)" -ForegroundColor White
    
    if ($UseCache) {
        Write-Host "  Cache hits: $($sharedState.Stats.CacheHits)" -ForegroundColor White
        Write-Host "  Cache misses: $($sharedState.Stats.CacheMisses)" -ForegroundColor White
        $hitRatio = if (($sharedState.Stats.CacheHits + $sharedState.Stats.CacheMisses) -gt 0) {
            [Math]::Round(($sharedState.Stats.CacheHits / ($sharedState.Stats.CacheHits + $sharedState.Stats.CacheMisses)) * 100, 2)
        } else { 0 }
        Write-Host "  Cache hit ratio: $hitRatio%" -ForegroundColor White
    }
    
    Write-Host "  Rapport JSON: $($reportPaths.JsonPath)" -ForegroundColor White
    Write-Host "  Rapport HTML: $($reportPaths.HtmlPath)" -ForegroundColor White

    # Ouvrir le rapport HTML dans le navigateur par dÃ©faut
    if (Test-Path -Path $reportPaths.HtmlPath) {
        Start-Process $reportPaths.HtmlPath
    }

    # Retourner les rÃ©sultats
    return $sharedState.Results
} catch {
    Write-Error "Erreur lors de l'analyse parallÃ¨le: $_"
    exit 1
}

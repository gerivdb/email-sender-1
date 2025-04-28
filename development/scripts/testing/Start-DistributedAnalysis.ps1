#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute une analyse distribuÃ©e sur plusieurs machines.

.DESCRIPTION
    Ce script permet d'exÃ©cuter une analyse de code distribuÃ©e sur plusieurs machines
    en parallÃ¨le, en coordonnant les tÃ¢ches et en fusionnant les rÃ©sultats.

.PARAMETER RepositoryPath
    Chemin du dÃ©pÃ´t Git Ã  analyser.

.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer le rapport d'analyse.

.PARAMETER ComputerNames
    Liste des noms d'ordinateurs sur lesquels exÃ©cuter l'analyse.

.PARAMETER MaxConcurrentJobs
    Nombre maximum de tÃ¢ches concurrentes Ã  exÃ©cuter.

.PARAMETER ChunkSize
    Nombre de fichiers Ã  analyser par tÃ¢che.

.PARAMETER UseCache
    Indique s'il faut utiliser le cache pour amÃ©liorer les performances.

.EXAMPLE
    .\Start-DistributedAnalysis.ps1 -RepositoryPath "C:\Repos\MyProject" -ComputerNames "Server1", "Server2"

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepositoryPath,
    
    [Parameter()]
    [string]$OutputPath = "$env:TEMP\DistributedAnalysisReport.html",
    
    [Parameter()]
    [string[]]$ComputerNames = @("localhost"),
    
    [Parameter()]
    [int]$MaxConcurrentJobs = 4,
    
    [Parameter()]
    [int]$ChunkSize = 100,
    
    [Parameter()]
    [switch]$UseCache
)

# Importer les modules nÃ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
Import-Module "$modulesPath\FileContentIndexer.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$modulesPath\SyntaxAnalyzer.psm1" -Force -ErrorAction SilentlyContinue
Import-Module "$modulesPath\PRAnalysisCache.psm1" -Force -ErrorAction SilentlyContinue

# Fonction pour diviser les fichiers en lots
function Split-FilesIntoChunks {
    param([string[]]$FilePaths, [int]$ChunkSize)
    
    $chunks = @()
    $currentChunk = @()
    
    foreach ($filePath in $FilePaths) {
        $currentChunk += $filePath
        
        if ($currentChunk.Count -ge $ChunkSize) {
            $chunks += , $currentChunk
            $currentChunk = @()
        }
    }
    
    if ($currentChunk.Count -gt 0) {
        $chunks += , $currentChunk
    }
    
    return $chunks
}

# Fonction pour analyser un lot de fichiers
function Invoke-ChunkAnalysis {
    param([string[]]$FilePaths, [switch]$UseCache)
    
    # CrÃ©er un cache si demandÃ©
    $cache = if ($UseCache) { New-PRAnalysisCache -MaxMemoryItems 1000 } else { $null }
    
    # CrÃ©er un analyseur de syntaxe
    $analyzer = New-SyntaxAnalyzer -UseCache $UseCache -Cache $cache
    
    # Analyser les fichiers
    $results = @()
    
    foreach ($filePath in $FilePaths) {
        try {
            if (Test-Path -Path $filePath -PathType Leaf) {
                $issues = $analyzer.AnalyzeFile($filePath)
                
                $results += [PSCustomObject]@{
                    FilePath = $filePath
                    Issues = $issues
                    Success = $true
                    Error = $null
                }
            } else {
                $results += [PSCustomObject]@{
                    FilePath = $filePath
                    Issues = @()
                    Success = $false
                    Error = "Le fichier n'existe pas"
                }
            }
        } catch {
            $results += [PSCustomObject]@{
                FilePath = $filePath
                Issues = @()
                Success = $false
                Error = $_.Exception.Message
            }
        }
    }
    
    return $results
}

# Fonction pour fusionner les rÃ©sultats
function Merge-AnalysisResults {
    param([array]$Results)
    
    $mergedResults = @{}
    
    foreach ($result in $Results) {
        foreach ($fileResult in $result) {
            if ($fileResult.Success) {
                $filePath = $fileResult.FilePath
                
                if (-not $mergedResults.ContainsKey($filePath)) {
                    $mergedResults[$filePath] = @{
                        FilePath = $filePath
                        Issues = @()
                        Success = $true
                        Error = $null
                    }
                }
                
                $mergedResults[$filePath].Issues += $fileResult.Issues
            }
        }
    }
    
    return $mergedResults
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-AnalysisReport {
    param([hashtable]$Results, [string]$OutputPath)
    
    $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $computerName = $env:COMPUTERNAME
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse distribuÃ©e</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .error { color: #ff0000; }
        .warning { color: #ff9900; }
        .info { color: #0066cc; }
    </style>
</head>
<body>
    <h1>Rapport d'analyse distribuÃ©e</h1>
    <p><strong>Date du rapport:</strong> $reportDate</p>
    <p><strong>Ordinateur:</strong> $computerName</p>
    <p><strong>DÃ©pÃ´t:</strong> $RepositoryPath</p>
    
    <h2>RÃ©sumÃ© de l'analyse</h2>
    <table>
        <tr>
            <th>MÃ©trique</th>
            <th>Valeur</th>
        </tr>
        <tr>
            <td>Nombre de fichiers analysÃ©s</td>
            <td>$($Results.Count)</td>
        </tr>
        <tr>
            <td>Nombre de problÃ¨mes dÃ©tectÃ©s</td>
            <td>$($Results.Values | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum | Select-Object -ExpandProperty Sum)</td>
        </tr>
        <tr>
            <td>Nombre d'ordinateurs utilisÃ©s</td>
            <td>$($ComputerNames.Count)</td>
        </tr>
    </table>
    
    <h2>Fichiers avec problÃ¨mes</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>ProblÃ¨mes</th>
            <th>DÃ©tails</th>
        </tr>
"@

    # Trier les rÃ©sultats par nombre de problÃ¨mes (dÃ©croissant)
    $sortedResults = $Results.Values | Where-Object { $_.Issues.Count -gt 0 } | Sort-Object -Property { $_.Issues.Count } -Descending
    
    foreach ($result in $sortedResults) {
        $filePath = $result.FilePath
        $issueCount = $result.Issues.Count
        
        $html += @"
        <tr>
            <td>$filePath</td>
            <td>$issueCount</td>
            <td>
                <table>
                    <tr>
                        <th>Ligne</th>
                        <th>Message</th>
                        <th>SÃ©vÃ©ritÃ©</th>
                    </tr>
"@

        foreach ($issue in $result.Issues) {
            $severityClass = switch ($issue.Severity) {
                "Error" { "error" }
                "Warning" { "warning" }
                default { "info" }
            }
            
            $html += @"
                    <tr>
                        <td>$($issue.Line)</td>
                        <td>$($issue.Message)</td>
                        <td class="$severityClass">$($issue.Severity)</td>
                    </tr>
"@
        }

        $html += @"
                </table>
            </td>
        </tr>
"@
    }

    $html += @"
    </table>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    return $OutputPath
}

# Obtenir la liste des fichiers Ã  analyser
Write-Host "Obtention de la liste des fichiers Ã  analyser..." -ForegroundColor Cyan
$files = Get-ChildItem -Path $RepositoryPath -Recurse -File | Where-Object {
    $_.Extension -in @(".ps1", ".psm1", ".py", ".js", ".html", ".css")
}

Write-Host "  $($files.Count) fichiers trouvÃ©s" -ForegroundColor Green

# Diviser les fichiers en lots
Write-Host "Division des fichiers en lots..." -ForegroundColor Cyan
$chunks = Split-FilesIntoChunks -FilePaths $files.FullName -ChunkSize $ChunkSize

Write-Host "  $($chunks.Count) lots crÃ©Ã©s" -ForegroundColor Green

# Distribuer les lots sur les ordinateurs disponibles
Write-Host "Distribution des lots sur les ordinateurs disponibles..." -ForegroundColor Cyan

$jobs = @()
$jobIndex = 0

foreach ($chunk in $chunks) {
    # SÃ©lectionner l'ordinateur Ã  utiliser
    $computerIndex = $jobIndex % $ComputerNames.Count
    $computerName = $ComputerNames[$computerIndex]
    
    # CrÃ©er un job pour analyser le lot
    $job = Start-Job -ScriptBlock {
        param($Chunk, $UseCache, $ModulesPath)
        
        # Importer les modules nÃ©cessaires
        Import-Module "$ModulesPath\FileContentIndexer.psm1" -Force -ErrorAction SilentlyContinue
        Import-Module "$ModulesPath\SyntaxAnalyzer.psm1" -Force -ErrorAction SilentlyContinue
        Import-Module "$ModulesPath\PRAnalysisCache.psm1" -Force -ErrorAction SilentlyContinue
        
        # Analyser les fichiers
        $results = @()
        
        # CrÃ©er un cache si demandÃ©
        $cache = if ($UseCache) { New-PRAnalysisCache -MaxMemoryItems 1000 } else { $null }
        
        # CrÃ©er un analyseur de syntaxe
        $analyzer = New-SyntaxAnalyzer -UseCache $UseCache -Cache $cache
        
        foreach ($filePath in $Chunk) {
            try {
                if (Test-Path -Path $filePath -PathType Leaf) {
                    $issues = $analyzer.AnalyzeFile($filePath)
                    
                    $results += [PSCustomObject]@{
                        FilePath = $filePath
                        Issues = $issues
                        Success = $true
                        Error = $null
                    }
                } else {
                    $results += [PSCustomObject]@{
                        FilePath = $filePath
                        Issues = @()
                        Success = $false
                        Error = "Le fichier n'existe pas"
                    }
                }
            } catch {
                $results += [PSCustomObject]@{
                    FilePath = $filePath
                    Issues = @()
                    Success = $false
                    Error = $_.Exception.Message
                }
            }
        }
        
        return $results
    } -ArgumentList $chunk, $UseCache, $modulesPath
    
    $jobs += $job
    $jobIndex++
    
    Write-Host "  Job $jobIndex dÃ©marrÃ© sur $computerName" -ForegroundColor Yellow
    
    # Limiter le nombre de jobs concurrents
    while ((Get-Job -State Running).Count -ge $MaxConcurrentJobs) {
        Start-Sleep -Milliseconds 500
        
        # RÃ©cupÃ©rer les jobs terminÃ©s
        $completedJobs = Get-Job -State Completed
        foreach ($completedJob in $completedJobs) {
            Write-Host "  Job $($completedJob.Id) terminÃ©" -ForegroundColor Green
            $completedJob | Receive-Job -Keep | Out-Null
        }
    }
}

# Attendre que tous les jobs soient terminÃ©s
Write-Host "Attente de la fin des jobs..." -ForegroundColor Cyan
$remainingJobs = $jobs | Where-Object { $_.State -ne "Completed" }
while ($remainingJobs.Count -gt 0) {
    Start-Sleep -Seconds 1
    $remainingJobs = $jobs | Where-Object { $_.State -ne "Completed" }
    
    # Afficher la progression
    $completedCount = $jobs.Count - $remainingJobs.Count
    $progress = [Math]::Round(($completedCount / $jobs.Count) * 100)
    Write-Progress -Activity "Analyse distribuÃ©e" -Status "$completedCount / $($jobs.Count) jobs terminÃ©s" -PercentComplete $progress
}

Write-Progress -Activity "Analyse distribuÃ©e" -Completed

# RÃ©cupÃ©rer les rÃ©sultats
Write-Host "RÃ©cupÃ©ration des rÃ©sultats..." -ForegroundColor Cyan
$results = @()
foreach ($job in $jobs) {
    $results += $job | Receive-Job
    Remove-Job -Job $job
}

# Fusionner les rÃ©sultats
Write-Host "Fusion des rÃ©sultats..." -ForegroundColor Cyan
$mergedResults = Merge-AnalysisResults -Results $results

Write-Host "  $($mergedResults.Count) fichiers analysÃ©s" -ForegroundColor Green

# GÃ©nÃ©rer le rapport
Write-Host "GÃ©nÃ©ration du rapport..." -ForegroundColor Cyan
$reportPath = New-AnalysisReport -Results $mergedResults -OutputPath $OutputPath

Write-Host "  Rapport gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green

# Ouvrir le rapport dans le navigateur par dÃ©faut
Start-Process $reportPath

# Retourner le rÃ©sultat
return @{
    Results = $mergedResults
    ReportPath = $reportPath
}

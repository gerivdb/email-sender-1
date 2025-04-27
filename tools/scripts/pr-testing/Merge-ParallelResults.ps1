#Requires -Version 5.1
<#
.SYNOPSIS
    Fusionne les rÃ©sultats d'analyses parallÃ¨les.

.DESCRIPTION
    Ce script fusionne les rÃ©sultats d'analyses parallÃ¨les de pull requests
    en un seul rapport consolidÃ©, en Ã©liminant les doublons et en rÃ©solvant
    les conflits.

.PARAMETER InputPaths
    Les chemins des fichiers de rÃ©sultats Ã  fusionner.

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer le rÃ©sultat fusionnÃ©.
    Par dÃ©faut: "reports\pr-analysis\merged_results.json"

.PARAMETER ConflictResolution
    La stratÃ©gie de rÃ©solution des conflits.
    Valeurs possibles: "First", "Last", "Newest", "MostIssues", "LeastIssues"
    Par dÃ©faut: "Newest"

.PARAMETER GenerateHtmlReport
    Indique s'il faut gÃ©nÃ©rer un rapport HTML.
    Par dÃ©faut: $true

.EXAMPLE
    .\Merge-ParallelResults.ps1 -InputPaths "results1.json", "results2.json"
    Fusionne les rÃ©sultats des deux fichiers spÃ©cifiÃ©s.

.EXAMPLE
    .\Merge-ParallelResults.ps1 -InputPaths "results*.json" -ConflictResolution "MostIssues"
    Fusionne tous les fichiers correspondant au modÃ¨le, en privilÃ©giant les rÃ©sultats avec le plus de problÃ¨mes en cas de conflit.

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

# Importer le module de parallÃ©lisation
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\ParallelPRAnalysis.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module ParallelPRAnalysis non trouvÃ© Ã  l'emplacement: $modulePath"
    exit 1
}

# Fonction pour rÃ©soudre les chemins de fichiers
function Resolve-FilePaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Paths
    )

    try {
        $resolvedPaths = @()
        
        foreach ($path in $Paths) {
            # VÃ©rifier si le chemin contient des caractÃ¨res gÃ©nÃ©riques
            if ($path -match '\*|\?') {
                # RÃ©soudre les chemins avec des caractÃ¨res gÃ©nÃ©riques
                $matchingPaths = Get-ChildItem -Path $path -File | Select-Object -ExpandProperty FullName
                $resolvedPaths += $matchingPaths
            } else {
                # VÃ©rifier si le fichier existe
                if (Test-Path -Path $path -PathType Leaf) {
                    $resolvedPaths += (Get-Item -Path $path).FullName
                } else {
                    Write-Warning "Le fichier n'existe pas: $path"
                }
            }
        }
        
        return $resolvedPaths
    } catch {
        Write-Error "Erreur lors de la rÃ©solution des chemins de fichiers: $_"
        return @()
    }
}

# Fonction pour charger les rÃ©sultats
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
        Write-Error "Erreur lors du chargement des rÃ©sultats Ã  partir du fichier: $Path`n$_"
        return $null
    }
}

# Fonction pour fusionner les rÃ©sultats
function Merge-Results {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$ResultsArray,
        
        [Parameter(Mandatory = $true)]
        [string]$Strategy
    )

    try {
        # VÃ©rifier s'il y a des rÃ©sultats Ã  fusionner
        if ($ResultsArray.Count -eq 0) {
            Write-Warning "Aucun rÃ©sultat Ã  fusionner."
            return $null
        }
        
        if ($ResultsArray.Count -eq 1) {
            Write-Host "Un seul rÃ©sultat Ã  traiter, aucune fusion nÃ©cessaire." -ForegroundColor Yellow
            return $ResultsArray[0]
        }
        
        # CrÃ©er un objet pour stocker les rÃ©sultats fusionnÃ©s
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
        
        # CrÃ©er un dictionnaire pour stocker les rÃ©sultats par chemin de fichier
        $resultsByPath = @{}
        
        # Parcourir tous les rÃ©sultats
        foreach ($resultSet in $ResultsArray) {
            # Parcourir les rÃ©sultats de chaque fichier
            foreach ($fileResult in $resultSet.Results) {
                $filePath = $fileResult.FilePath
                
                # VÃ©rifier s'il y a dÃ©jÃ  un rÃ©sultat pour ce fichier
                if ($resultsByPath.ContainsKey($filePath)) {
                    # Conflit dÃ©tectÃ©
                    $mergedResults.Stats.Conflicts++
                    
                    # RÃ©soudre le conflit selon la stratÃ©gie spÃ©cifiÃ©e
                    $existingResult = $resultsByPath[$filePath]
                    $newResult = $null
                    
                    switch ($Strategy) {
                        "First" {
                            # Conserver le premier rÃ©sultat
                            $newResult = $existingResult
                        }
                        "Last" {
                            # Utiliser le dernier rÃ©sultat
                            $newResult = $fileResult
                        }
                        "Newest" {
                            # Utiliser le rÃ©sultat le plus rÃ©cent
                            if ($fileResult.EndTime -gt $existingResult.EndTime) {
                                $newResult = $fileResult
                            } else {
                                $newResult = $existingResult
                            }
                        }
                        "MostIssues" {
                            # Utiliser le rÃ©sultat avec le plus de problÃ¨mes
                            if ($fileResult.Issues.Count -gt $existingResult.Issues.Count) {
                                $newResult = $fileResult
                            } else {
                                $newResult = $existingResult
                            }
                        }
                        "LeastIssues" {
                            # Utiliser le rÃ©sultat avec le moins de problÃ¨mes
                            if ($fileResult.Issues.Count -lt $existingResult.Issues.Count) {
                                $newResult = $fileResult
                            } else {
                                $newResult = $existingResult
                            }
                        }
                        default {
                            # Par dÃ©faut, utiliser le rÃ©sultat le plus rÃ©cent
                            if ($fileResult.EndTime -gt $existingResult.EndTime) {
                                $newResult = $fileResult
                            } else {
                                $newResult = $existingResult
                            }
                        }
                    }
                    
                    # Mettre Ã  jour le rÃ©sultat
                    $resultsByPath[$filePath] = $newResult
                    $mergedResults.Stats.ResolvedConflicts++
                } else {
                    # Pas de conflit, ajouter le rÃ©sultat
                    $resultsByPath[$filePath] = $fileResult
                }
            }
        }
        
        # Convertir le dictionnaire en tableau
        $mergedResults.Results = $resultsByPath.Values
        
        # Mettre Ã  jour les statistiques
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
        Write-Error "Erreur lors de la fusion des rÃ©sultats: $_"
        return $null
    }
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-HtmlReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    try {
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        $outputDir = Split-Path -Path $OutputPath -Parent
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }

        # GÃ©nÃ©rer le HTML
        $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport d'Analyse FusionnÃ© - PR #$($Results.PullRequest.Number)</title>
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
        <h1>Rapport d'Analyse FusionnÃ© - Pull Request #$($Results.PullRequest.Number)</h1>
        
        <div class="summary">
            <h2>RÃ©sumÃ©</h2>
            <p><strong>Titre:</strong> $($Results.PullRequest.Title)</p>
            <p><strong>Branche source:</strong> $($Results.PullRequest.HeadBranch)</p>
            <p><strong>Branche cible:</strong> $($Results.PullRequest.BaseBranch)</p>
            <p><strong>Fichiers analysÃ©s:</strong> $($Results.TotalFiles)</p>
            <p><strong>ProblÃ¨mes dÃ©tectÃ©s:</strong> $($Results.TotalIssues)</p>
            <p><strong>DurÃ©e totale:</strong> $([Math]::Round($Results.TotalDurationMs / 1000, 2)) secondes</p>
            <p><strong>DurÃ©e moyenne par fichier:</strong> $([Math]::Round($Results.AverageDurationMs, 2)) ms</p>
        </div>
        
        <div class="summary">
            <h2>Informations sur la Fusion</h2>
            <p><strong>StratÃ©gie de fusion:</strong> $($Results.Stats.MergeStrategy)</p>
            <p><strong>Fichiers sources:</strong> $($Results.Stats.SourceFiles)</p>
            <p><strong>Conflits dÃ©tectÃ©s:</strong> $($Results.Stats.Conflicts)</p>
            <p><strong>Conflits rÃ©solus:</strong> $($Results.Stats.ResolvedConflicts)</p>
            <p><strong>Date de fusion:</strong> $($Results.Stats.MergeTime)</p>
        </div>
        
        <h2>ProblÃ¨mes par Type</h2>
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
        
        <h2>Fichiers avec ProblÃ¨mes</h2>
        <table>
            <tr>
                <th>Fichier</th>
                <th>ProblÃ¨mes</th>
                <th>DurÃ©e (ms)</th>
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
        
        <h2>DÃ©tails des ProblÃ¨mes</h2>
"@

        foreach ($result in ($Results.Results | Where-Object { $_.Success -and $_.Issues.Count -gt 0 } | Sort-Object -Property { $_.Issues.Count } -Descending)) {
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

        # Enregistrer le fichier HTML
        Set-Content -Path $OutputPath -Value $html -Encoding UTF8
        
        return $OutputPath
    } catch {
        Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport HTML: $_"
        return $null
    }
}

# Point d'entrÃ©e principal
try {
    # RÃ©soudre les chemins de fichiers
    $resolvedPaths = Resolve-FilePaths -Paths $InputPaths
    if ($resolvedPaths.Count -eq 0) {
        Write-Error "Aucun fichier trouvÃ©."
        exit 1
    }
    
    Write-Host "Fichiers trouvÃ©s: $($resolvedPaths.Count)" -ForegroundColor Cyan
    foreach ($path in $resolvedPaths) {
        Write-Host "  $path" -ForegroundColor White
    }

    # Charger les rÃ©sultats
    $resultsArray = @()
    foreach ($path in $resolvedPaths) {
        $results = Get-ResultsFromFile -Path $path
        if ($null -ne $results) {
            $resultsArray += $results
            Write-Host "RÃ©sultats chargÃ©s: $path" -ForegroundColor Green
        }
    }
    
    if ($resultsArray.Count -eq 0) {
        Write-Error "Aucun rÃ©sultat chargÃ©."
        exit 1
    }
    
    Write-Host "RÃ©sultats chargÃ©s: $($resultsArray.Count)" -ForegroundColor Cyan

    # Fusionner les rÃ©sultats
    Write-Host "Fusion des rÃ©sultats avec la stratÃ©gie: $ConflictResolution" -ForegroundColor Cyan
    $mergedResults = Merge-Results -ResultsArray $resultsArray -Strategy $ConflictResolution
    if ($null -eq $mergedResults) {
        Write-Error "Ã‰chec de la fusion des rÃ©sultats."
        exit 1
    }
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer les rÃ©sultats fusionnÃ©s
    $mergedResults | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "RÃ©sultats fusionnÃ©s enregistrÃ©s: $OutputPath" -ForegroundColor Green

    # GÃ©nÃ©rer un rapport HTML si demandÃ©
    $htmlPath = $null
    if ($GenerateHtmlReport) {
        $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
        $htmlPath = New-HtmlReport -Results $mergedResults -OutputPath $htmlPath
        if ($null -ne $htmlPath) {
            Write-Host "Rapport HTML gÃ©nÃ©rÃ©: $htmlPath" -ForegroundColor Green
        }
    }

    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© de la fusion:" -ForegroundColor Cyan
    Write-Host "  Fichiers sources: $($mergedResults.Stats.SourceFiles)" -ForegroundColor White
    Write-Host "  StratÃ©gie de fusion: $($mergedResults.Stats.MergeStrategy)" -ForegroundColor White
    Write-Host "  Conflits dÃ©tectÃ©s: $($mergedResults.Stats.Conflicts)" -ForegroundColor White
    Write-Host "  Conflits rÃ©solus: $($mergedResults.Stats.ResolvedConflicts)" -ForegroundColor White
    Write-Host "  Fichiers analysÃ©s: $($mergedResults.TotalFiles)" -ForegroundColor White
    Write-Host "  ProblÃ¨mes dÃ©tectÃ©s: $($mergedResults.TotalIssues)" -ForegroundColor White
    Write-Host "  DurÃ©e totale: $([Math]::Round($mergedResults.TotalDurationMs / 1000, 2)) secondes" -ForegroundColor White
    
    # Ouvrir le rapport HTML dans le navigateur par dÃ©faut
    if ($null -ne $htmlPath -and (Test-Path -Path $htmlPath)) {
        Start-Process $htmlPath
    }

    # Retourner les rÃ©sultats
    return $mergedResults
} catch {
    Write-Error "Erreur lors de la fusion des rÃ©sultats: $_"
    exit 1
}

#Requires -Version 5.1
<#
.SYNOPSIS
    Analyse prÃ©dictive des fichiers pour anticiper les problÃ¨mes potentiels.
.DESCRIPTION
    Ce script utilise des heuristiques avancÃ©es et l'historique des erreurs pour
    prÃ©dire les zones Ã  risque dans le code et anticiper les problÃ¨mes potentiels.
.PARAMETER RepositoryPath
    Chemin du dÃ©pÃ´t Git Ã  analyser.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer le rapport d'analyse prÃ©dictive.
.PARAMETER ErrorHistoryPath
    Chemin du fichier contenant l'historique des erreurs.
.PARAMETER UseCache
    Indique s'il faut utiliser le cache pour amÃ©liorer les performances.
.EXAMPLE
    .\Start-PredictiveFileAnalysis.ps1 -RepositoryPath "C:\Repos\MyProject"
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
    [string]$OutputPath = "$env:TEMP\PredictiveAnalysisReport.html",

    [Parameter()]
    [string]$ErrorHistoryPath = "$PSScriptRoot\data\error_history.json",

    [Parameter()]
    [switch]$UseCache
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
        Write-Warning "Module non trouvÃ©: $modulePath"
    }
}

# CrÃ©er le rÃ©pertoire de donnÃ©es s'il n'existe pas
$dataDir = Join-Path -Path $PSScriptRoot -ChildPath "data"
if (-not (Test-Path -Path $dataDir)) {
    New-Item -Path $dataDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er le fichier d'historique des erreurs s'il n'existe pas
if (-not (Test-Path -Path $ErrorHistoryPath)) {
    @{
        Files       = @{}
        Patterns    = @{}
        LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    } | ConvertTo-Json -Depth 10 | Out-File -FilePath $ErrorHistoryPath -Encoding UTF8
}

# Fonction pour charger l'historique des erreurs
function Get-ErrorHistory {
    param(
        [string]$Path
    )

    if (Test-Path -Path $Path) {
        $content = Get-Content -Path $Path -Raw -Encoding UTF8
        return ConvertFrom-Json -InputObject $content -AsHashtable
    }

    return @{
        Files       = @{}
        Patterns    = @{}
        LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

# Fonction pour mettre Ã  jour l'historique des erreurs
function Update-ErrorHistory {
    param(
        [hashtable]$History,
        [string]$FilePath,
        [array]$Issues,
        [string]$OutputPath
    )

    # Mettre Ã  jour l'historique des fichiers
    $relativeFilePath = $FilePath -replace [regex]::Escape($RepositoryPath), ""
    $relativeFilePath = $relativeFilePath.TrimStart("\", "/")

    if (-not $History.Files.ContainsKey($relativeFilePath)) {
        $History.Files[$relativeFilePath] = @{
            IssueCount   = 0
            LastIssues   = @()
            IssueHistory = @()
        }
    }

    # Ajouter les problÃ¨mes actuels Ã  l'historique
    $History.Files[$relativeFilePath].IssueCount += $Issues.Count
    $History.Files[$relativeFilePath].LastIssues = $Issues | ForEach-Object {
        @{
            Line     = $_.Line
            Column   = $_.Column
            Message  = $_.Message
            Severity = $_.Severity
            Type     = $_.Type
            Date     = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }

    # Limiter l'historique Ã  100 entrÃ©es par fichier
    if ($History.Files[$relativeFilePath].IssueHistory.Count -gt 100) {
        $History.Files[$relativeFilePath].IssueHistory = $History.Files[$relativeFilePath].IssueHistory | Select-Object -Last 100
    }

    # Mettre Ã  jour l'historique des patterns
    foreach ($issue in $Issues) {
        $pattern = $issue.Message -replace "\d+", "N" -replace "'.+'", "'X'" -replace '".*"', '"X"'

        if (-not $History.Patterns.ContainsKey($pattern)) {
            $History.Patterns[$pattern] = @{
                Count          = 0
                Files          = @{}
                LastOccurrence = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }

        $History.Patterns[$pattern].Count++
        $History.Patterns[$pattern].LastOccurrence = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        if (-not $History.Patterns[$pattern].Files.ContainsKey($relativeFilePath)) {
            $History.Patterns[$pattern].Files[$relativeFilePath] = 0
        }

        $History.Patterns[$pattern].Files[$relativeFilePath]++
    }

    # Mettre Ã  jour la date de derniÃ¨re mise Ã  jour
    $History.LastUpdated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Enregistrer l'historique
    $History | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8

    return $History
}

# Fonction pour calculer le score de risque d'un fichier
function Get-FileRiskScore {
    param(
        [hashtable]$History,
        [string]$FilePath,
        [object]$FileIndex
    )

    $relativeFilePath = $FilePath -replace [regex]::Escape($RepositoryPath), ""
    $relativeFilePath = $relativeFilePath.TrimStart("\", "/")

    $score = 0
    $reasons = @()

    # Facteur 1: Historique des problÃ¨mes
    if ($History.Files.ContainsKey($relativeFilePath)) {
        $fileHistory = $History.Files[$relativeFilePath]
        $issueCount = $fileHistory.IssueCount

        if ($issueCount -gt 0) {
            $historyScore = [Math]::Min(50, $issueCount * 5)
            $score += $historyScore
            $reasons += "Historique des problÃ¨mes: $issueCount problÃ¨mes dÃ©tectÃ©s prÃ©cÃ©demment (+$historyScore)"
        }
    }

    # Facteur 2: ComplexitÃ© du fichier
    $complexity = 0

    if ($FileIndex) {
        # Nombre de fonctions
        $functionCount = $FileIndex.Functions.Count
        $complexity += $functionCount * 2

        # Nombre de classes
        $classCount = $FileIndex.Classes.Count
        $complexity += $classCount * 3

        # Taille du fichier
        $fileSize = $FileIndex.FileSize
        $complexity += [Math]::Min(20, $fileSize / 1KB)
    } else {
        # Si l'index n'est pas disponible, utiliser la taille du fichier
        $fileInfo = Get-Item -Path $FilePath
        $complexity += [Math]::Min(20, $fileInfo.Length / 1KB)
    }

    $complexityScore = [Math]::Min(30, $complexity)
    $score += $complexityScore
    $reasons += "ComplexitÃ© du fichier: Score de complexitÃ© $complexity (+$complexityScore)"

    # Facteur 3: Patterns Ã  risque
    $riskPatterns = @{}

    # PowerShell patterns
    $riskPatterns["\.ps1$"] = @(
        @{ Pattern = "Remove-Item.*-Recurse"; Score = 10; Reason = "Suppression rÃ©cursive de fichiers" },
        @{ Pattern = "Invoke-Expression"; Score = 8; Reason = "Utilisation de Invoke-Expression (risque d'injection)" },
        @{ Pattern = "ConvertTo-SecureString.*-AsPlainText"; Score = 7; Reason = "Conversion de texte en clair en SecureString" },
        @{ Pattern = "\$null\s*=="; Score = 5; Reason = "Comparaison incorrecte avec null" }
    )

    # Python patterns
    $riskPatterns["\.py$"] = @(
        @{ Pattern = "eval\("; Score = 10; Reason = "Utilisation de eval() (risque d'injection)" },
        @{ Pattern = "exec\("; Score = 9; Reason = "Utilisation de exec() (risque d'injection)" },
        @{ Pattern = "os\.system\("; Score = 8; Reason = "Appel systÃ¨me direct (risque d'injection)" },
        @{ Pattern = "except:"; Score = 6; Reason = "Exception gÃ©nÃ©rique sans type spÃ©cifiÃ©" }
    )

    # JavaScript patterns
    $riskPatterns["\.js$"] = @(
        @{ Pattern = "eval\("; Score = 10; Reason = "Utilisation de eval() (risque d'injection)" },
        @{ Pattern = "document\.write\("; Score = 7; Reason = "Utilisation de document.write()" },
        @{ Pattern = "localStorage\."; Score = 5; Reason = "Utilisation du stockage local" },
        @{ Pattern = "console\.log\("; Score = 3; Reason = "Utilisation de console.log() en production" }
    )

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    # VÃ©rifier les patterns Ã  risque pour cette extension
    foreach ($key in $riskPatterns.Keys) {
        if ($extension -match $key) {
            $patterns = $riskPatterns[$key]
            $content = Get-Content -Path $FilePath -Raw

            foreach ($pattern in $patterns) {
                if ($content -match $pattern.Pattern) {
                    $score += $pattern.Score
                    $reasons += "Pattern Ã  risque: $($pattern.Reason) (+$($pattern.Score))"
                }
            }
            break
        }
    }

    # Facteur 4: FrÃ©quence des modifications
    # TODO: ImplÃ©menter la dÃ©tection de la frÃ©quence des modifications

    # Normaliser le score entre 0 et 100
    $score = [Math]::Min(100, $score)

    return @{
        Score     = $score
        Reasons   = $reasons
        RiskLevel = if ($score -ge 75) { "Ã‰levÃ©" } elseif ($score -ge 50) { "Moyen" } elseif ($score -ge 25) { "Faible" } else { "TrÃ¨s faible" }
    }
}

# Fonction pour analyser un fichier
function Invoke-PredictiveFileAnalysis {
    param(
        [string]$FilePath,
        [object]$Analyzer,
        [hashtable]$ErrorHistory,
        [object]$Indexer
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) {
        Write-Warning "Le fichier n'existe pas: $FilePath"
        return $null
    }

    # Indexer le fichier
    $fileIndex = $null

    # Analyser le fichier
    $issues = @()

    # Analyse simplifiÃ©e
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue

    # Analyser le contenu en fonction de l'extension
    switch ($extension) {
        ".ps1" {
            # VÃ©rifier les alias
            if ($content -like "*gci*" -or $content -like "*dir*" -or $content -like "*ls*") {
                $issues += [PSCustomObject]@{
                    Line     = 1
                    Column   = 1
                    Message  = "Utilisation d'alias de cmdlet"
                    Severity = "Warning"
                    Type     = "Style"
                    Category = "Style"
                }
            }

            # VÃ©rifier Invoke-Expression
            if ($content -like "*Invoke-Expression*") {
                $issues += [PSCustomObject]@{
                    Line     = 1
                    Column   = 1
                    Message  = "Utilisation de Invoke-Expression (risque d'injection)"
                    Severity = "Error"
                    Type     = "Security"
                    Category = "Security"
                }
            }
        }
        ".py" {
            # VÃ©rifier eval
            if ($content -like "*eval(*") {
                $issues += [PSCustomObject]@{
                    Line     = 1
                    Column   = 1
                    Message  = "Utilisation de eval() (risque d'injection)"
                    Severity = "Error"
                    Type     = "Security"
                    Category = "Security"
                }
            }
        }
        ".js" {
            # VÃ©rifier eval
            if ($content -like "*eval(*") {
                $issues += [PSCustomObject]@{
                    Line     = 1
                    Column   = 1
                    Message  = "Utilisation de eval() (risque d'injection)"
                    Severity = "Error"
                    Type     = "Security"
                    Category = "Security"
                }
            }
        }
    }

    # Calculer le score de risque
    $riskScore = Get-FileRiskScore -History $ErrorHistory -FilePath $FilePath -FileIndex $fileIndex

    # Mettre Ã  jour l'historique des erreurs
    $errorHistory = Update-ErrorHistory -History $ErrorHistory -FilePath $FilePath -Issues $issues -OutputPath $ErrorHistoryPath

    # CrÃ©er un objet rÃ©sultat
    $result = [PSCustomObject]@{
        FilePath    = $FilePath
        Issues      = $issues
        RiskScore   = $riskScore.Score
        RiskLevel   = $riskScore.RiskLevel
        RiskReasons = $riskScore.Reasons
        FileIndex   = $fileIndex
    }

    return $result
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-PredictiveAnalysisReport {
    param(
        [array]$Results,
        [hashtable]$ErrorHistory,
        [string]$OutputPath
    )

    $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $computerName = $env:COMPUTERNAME

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'analyse prÃ©dictive</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #0066cc; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .high-risk { background-color: #ffcccc; }
        .medium-risk { background-color: #ffffcc; }
        .low-risk { background-color: #e6ffcc; }
        .very-low-risk { background-color: #ccffcc; }
        .risk-reasons { margin-top: 5px; font-size: 0.9em; color: #666; }
        .issues-container { margin-top: 10px; }
        .issue { margin-bottom: 5px; padding: 5px; border: 1px solid #ddd; border-radius: 3px; }
        .issue-severity-error { border-left: 5px solid #ff0000; }
        .issue-severity-warning { border-left: 5px solid #ffcc00; }
        .issue-severity-information { border-left: 5px solid #0066cc; }
        .collapsible { cursor: pointer; padding: 10px; width: 100%; border: none; text-align: left; outline: none; }
        .active, .collapsible:hover { background-color: #f1f1f1; }
        .content { padding: 0 18px; display: none; overflow: hidden; background-color: #f9f9f9; }
        .chart-container { width: 100%; height: 400px; margin-bottom: 20px; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>Rapport d'analyse prÃ©dictive</h1>
    <p><strong>Date du rapport:</strong> $reportDate</p>
    <p><strong>Ordinateur:</strong> $computerName</p>
    <p><strong>DÃ©pÃ´t:</strong> $RepositoryPath</p>

    <h2>RÃ©sumÃ© des risques</h2>
    <div class="chart-container">
        <canvas id="riskChart"></canvas>
    </div>

    <h2>Fichiers analysÃ©s</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>Score de risque</th>
            <th>Niveau de risque</th>
            <th>ProblÃ¨mes</th>
            <th>Actions</th>
        </tr>
"@

    # Trier les rÃ©sultats par score de risque (dÃ©croissant)
    $sortedResults = $Results | Sort-Object -Property RiskScore -Descending

    foreach ($result in $sortedResults) {
        $riskClass = switch ($result.RiskLevel) {
            "Ã‰levÃ©" { "high-risk" }
            "Moyen" { "medium-risk" }
            "Faible" { "low-risk" }
            default { "very-low-risk" }
        }

        $relativeFilePath = $result.FilePath -replace [regex]::Escape($RepositoryPath), ""
        $relativeFilePath = $relativeFilePath.TrimStart("\", "/")

        $html += @"
        <tr class="$riskClass">
            <td>$relativeFilePath</td>
            <td>$($result.RiskScore)</td>
            <td>$($result.RiskLevel)</td>
            <td>$($result.Issues.Count)</td>
            <td><button class="collapsible">DÃ©tails</button></td>
        </tr>
        <tr>
            <td colspan="5" class="content">
                <h3>Raisons du score de risque</h3>
                <ul class="risk-reasons">
"@

        foreach ($reason in $result.RiskReasons) {
            $html += @"
                    <li>$reason</li>
"@
        }

        $html += @"
                </ul>

                <h3>ProblÃ¨mes dÃ©tectÃ©s</h3>
                <div class="issues-container">
"@

        if ($result.Issues.Count -eq 0) {
            $html += @"
                    <p>Aucun problÃ¨me dÃ©tectÃ©.</p>
"@
        } else {
            foreach ($issue in $result.Issues) {
                $severityClass = switch ($issue.Severity) {
                    "Error" { "issue-severity-error" }
                    "Warning" { "issue-severity-warning" }
                    default { "issue-severity-information" }
                }

                $html += @"
                    <div class="issue $severityClass">
                        <strong>Ligne $($issue.Line), Colonne $($issue.Column):</strong> $($issue.Message)
                    </div>
"@
            }
        }

        $html += @"
                </div>
            </td>
        </tr>
"@
    }

    $html += @"
    </table>

    <h2>Patterns d'erreurs frÃ©quents</h2>
    <table>
        <tr>
            <th>Pattern</th>
            <th>Occurrences</th>
            <th>Fichiers affectÃ©s</th>
            <th>DerniÃ¨re occurrence</th>
        </tr>
"@

    # Trier les patterns par nombre d'occurrences (dÃ©croissant)
    $sortedPatterns = $ErrorHistory.Patterns.GetEnumerator() | Sort-Object -Property { $_.Value.Count } -Descending

    foreach ($pattern in $sortedPatterns) {
        $html += @"
        <tr>
            <td>$($pattern.Key)</td>
            <td>$($pattern.Value.Count)</td>
            <td>$($pattern.Value.Files.Count)</td>
            <td>$($pattern.Value.LastOccurrence)</td>
        </tr>
"@
    }

    $html += @"
    </table>

    <script>
        // CrÃ©er le graphique de risque
        const ctx = document.getElementById('riskChart').getContext('2d');
        const chart = new Chart(ctx, {
            type: 'bar',
            data: {
                labels: ['TrÃ¨s faible', 'Faible', 'Moyen', 'Ã‰levÃ©'],
                datasets: [{
                    label: 'Nombre de fichiers',
                    data: [
                        $($Results | Where-Object { $_.RiskLevel -eq "TrÃ¨s faible" } | Measure-Object | Select-Object -ExpandProperty Count),
                        $($Results | Where-Object { $_.RiskLevel -eq "Faible" } | Measure-Object | Select-Object -ExpandProperty Count),
                        $($Results | Where-Object { $_.RiskLevel -eq "Moyen" } | Measure-Object | Select-Object -ExpandProperty Count),
                        $($Results | Where-Object { $_.RiskLevel -eq "Ã‰levÃ©" } | Measure-Object | Select-Object -ExpandProperty Count)
                    ],
                    backgroundColor: [
                        'rgba(75, 192, 75, 0.5)',
                        'rgba(75, 192, 192, 0.5)',
                        'rgba(255, 206, 86, 0.5)',
                        'rgba(255, 99, 132, 0.5)'
                    ],
                    borderColor: [
                        'rgba(75, 192, 75, 1)',
                        'rgba(75, 192, 192, 1)',
                        'rgba(255, 206, 86, 1)',
                        'rgba(255, 99, 132, 1)'
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                scales: {
                    y: {
                        beginAtZero: true,
                        title: {
                            display: true,
                            text: 'Nombre de fichiers'
                        }
                    },
                    x: {
                        title: {
                            display: true,
                            text: 'Niveau de risque'
                        }
                    }
                }
            }
        });

        // GÃ©rer les sections collapsibles
        var coll = document.getElementsByClassName("collapsible");
        for (var i = 0; i < coll.length; i++) {
            coll[i].addEventListener("click", function() {
                this.classList.toggle("active");
                var content = this.parentElement.parentElement.nextElementSibling.getElementsByClassName("content")[0];
                if (content.style.display === "block") {
                    content.style.display = "none";
                } else {
                    content.style.display = "block";
                }
            });
        }
    </script>
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    return $OutputPath
}

# Fonction principale
function Start-PredictiveAnalysis {
    param(
        [string]$RepoPath,
        [string]$OutputPath,
        [string]$ErrorHistoryPath,
        [bool]$UseCache
    )

    # CrÃ©er un cache simple
    $cache = @{
        Items   = @{}
        GetItem = {
            param($key)
            if ($this.Items.ContainsKey($key)) {
                return $this.Items[$key]
            }
            return $null
        }
        SetItem = {
            param($key, $value)
            $this.Items[$key] = $value
        }
    }

    # CrÃ©er un analyseur de syntaxe simple
    $analyzer = [PSCustomObject]@{
        AnalyzeFile = {
            param($filePath)

            # VÃ©rifier si le fichier existe
            if (-not (Test-Path -Path $filePath -PathType Leaf)) {
                Write-Warning "Le fichier n'existe pas: $filePath"
                return @()
            }

            # Analyser le fichier en fonction de son extension
            $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
            $issues = @()

            try {
                # Lire le contenu du fichier
                $content = Get-Content -Path $filePath -Raw -ErrorAction Stop
                $lines = $content -split "`n"

                # Analyser le contenu en fonction de l'extension
                switch ($extension) {
                    ".ps1" {
                        # VÃ©rifier les alias
                        if ($content -match "gci|dir|ls|cd|cp|ft|fl|fw|gc|gm|gp|gps|gsv|gu|gv|iex") {
                            $issues += [PSCustomObject]@{
                                Line     = 1
                                Column   = 1
                                Message  = "Utilisation d'alias de cmdlet"
                                Severity = "Warning"
                                Type     = "Style"
                                Category = "Style"
                            }
                        }

                        # VÃ©rifier Invoke-Expression
                        if ($content -match "Invoke-Expression") {
                            $issues += [PSCustomObject]@{
                                Line     = 1
                                Column   = 1
                                Message  = "Utilisation de Invoke-Expression (risque d'injection)"
                                Severity = "Error"
                                Type     = "Security"
                                Category = "Security"
                            }
                        }
                    }
                    ".py" {
                        # VÃ©rifier eval
                        if ($content -match "eval\\(") {
                            $issues += [PSCustomObject]@{
                                Line     = 1
                                Column   = 1
                                Message  = "Utilisation de eval() (risque d'injection)"
                                Severity = "Error"
                                Type     = "Security"
                                Category = "Security"
                            }
                        }

                        # VÃ©rifier os.system
                        if ($content -match "os\\.system") {
                            $issues += [PSCustomObject]@{
                                Line     = 1
                                Column   = 1
                                Message  = "Appel systÃ¨me direct (risque d'injection)"
                                Severity = "Warning"
                                Type     = "Security"
                                Category = "Security"
                            }
                        }
                    }
                    ".js" {
                        # VÃ©rifier eval
                        if ($content -match "eval\\(") {
                            $issues += [PSCustomObject]@{
                                Line     = 1
                                Column   = 1
                                Message  = "Utilisation de eval() (risque d'injection)"
                                Severity = "Error"
                                Type     = "Security"
                                Category = "Security"
                            }
                        }

                        # VÃ©rifier document.write
                        if ($content -match "document\\.write") {
                            $issues += [PSCustomObject]@{
                                Line     = 1
                                Column   = 1
                                Message  = "Utilisation de document.write()"
                                Severity = "Warning"
                                Type     = "Performance"
                                Category = "Performance"
                            }
                        }
                    }
                }
            } catch {
                Write-Error "Erreur lors de l'analyse du fichier $filePath : $_"
            }

            return $issues
        }
    }

    # CrÃ©er un indexeur de contenu de fichier simple
    $indexer = [PSCustomObject]@{
        GetFileIndices = { @{} }
        GetSymbolMap   = { @{} }
        ClearIndices   = { }
    }

    # Charger l'historique des erreurs
    $errorHistory = Get-ErrorHistory -Path $ErrorHistoryPath

    # Obtenir la liste des fichiers Ã  analyser
    $files = Get-ChildItem -Path $RepoPath -Recurse -File | Where-Object {
        $_.Extension -in @(".ps1", ".psm1", ".py", ".js", ".html", ".css")
    }

    Write-Host "Analyse prÃ©dictive de $($files.Count) fichiers..." -ForegroundColor Cyan

    # Analyser chaque fichier
    $results = @()
    $progress = 0
    $totalFiles = $files.Count

    foreach ($file in $files) {
        $progress++
        $percent = [Math]::Round(($progress / $totalFiles) * 100)
        Write-Progress -Activity "Analyse prÃ©dictive" -Status "Analyse de $($file.FullName)" -PercentComplete $percent

        $result = Invoke-PredictiveFileAnalysis -FilePath $file.FullName -Analyzer $analyzer -ErrorHistory $errorHistory -Indexer $indexer
        if ($result) {
            $results += $result
        }
    }

    Write-Progress -Activity "Analyse prÃ©dictive" -Completed

    # GÃ©nÃ©rer le rapport
    $reportPath = New-PredictiveAnalysisReport -Results $results -ErrorHistory $errorHistory -OutputPath $OutputPath

    Write-Host "Analyse terminÃ©e. $($results.Count) fichiers analysÃ©s." -ForegroundColor Green
    Write-Host "Rapport gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green

    return @{
        Results      = $results
        ReportPath   = $reportPath
        ErrorHistory = $errorHistory
    }
}

# ExÃ©cuter l'analyse prÃ©dictive
$result = Start-PredictiveAnalysis -RepoPath $RepositoryPath -OutputPath $OutputPath -ErrorHistoryPath $ErrorHistoryPath -UseCache $UseCache

# Ouvrir le rapport dans le navigateur par dÃ©faut
Start-Process $result.ReportPath

# Retourner le rÃ©sultat
return $result

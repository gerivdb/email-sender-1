# Script pour comparer les erreurs entre diffÃ©rentes versions

# Configuration
$ComparisonConfig = @{
    # Dossier de sortie des rapports
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorComparison"
    
    # Dossier des donnÃ©es d'erreurs
    DataFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorData"
    
    # Seuil de diffÃ©rence significative (en pourcentage)
    DifferenceThreshold = 20
}

# Fonction pour initialiser l'analyse comparative

# Script pour comparer les erreurs entre diffÃ©rentes versions

# Configuration
$ComparisonConfig = @{
    # Dossier de sortie des rapports
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorComparison"
    
    # Dossier des donnÃ©es d'erreurs
    DataFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorData"
    
    # Seuil de diffÃ©rence significative (en pourcentage)
    DifferenceThreshold = 20
}

# Fonction pour initialiser l'analyse comparative
function Initialize-ErrorComparison {
    param (
        [Parameter(Mandatory = $false)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
        [string]$OutputFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$DataFolder = "",
        
        [Parameter(Mandatory = $false)]
        [int]$DifferenceThreshold = 0
    )
    
    # Mettre Ã  jour la configuration
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $ComparisonConfig.OutputFolder = $OutputFolder
    }
    
    if (-not [string]::IsNullOrEmpty($DataFolder)) {
        $ComparisonConfig.DataFolder = $DataFolder
    }
    
    if ($DifferenceThreshold -gt 0) {
        $ComparisonConfig.DifferenceThreshold = $DifferenceThreshold
    }
    
    # CrÃ©er les dossiers s'ils n'existent pas
    foreach ($folder in @($ComparisonConfig.OutputFolder, $ComparisonConfig.DataFolder)) {
        if (-not (Test-Path -Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
    }
    
    return $ComparisonConfig
}

# Fonction pour capturer les donnÃ©es d'erreurs d'une version
function Save-VersionErrorData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Version,
        
        [Parameter(Mandatory = $true)]
        [object[]]$Errors,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # CrÃ©er le dossier de version s'il n'existe pas
    $versionFolder = Join-Path -Path $ComparisonConfig.DataFolder -ChildPath $Version
    if (-not (Test-Path -Path $versionFolder)) {
        New-Item -Path $versionFolder -ItemType Directory -Force | Out-Null
    }
    
    # PrÃ©parer les donnÃ©es
    $data = @{
        Version = $Version
        Description = $Description
        Timestamp = Get-Date -Format "o"
        Metadata = $Metadata
        ErrorCount = $Errors.Count
        Errors = $Errors
        
        # Statistiques
        ErrorsBySeverity = @{}
        ErrorsByCategory = @{}
        ErrorsBySource = @{}
    }
    
    # Calculer les statistiques
    $severities = $Errors | Group-Object -Property Severity | Select-Object Name, Count
    foreach ($severity in $severities) {
        $data.ErrorsBySeverity[$severity.Name] = $severity.Count
    }
    
    $categories = $Errors | Group-Object -Property Category | Select-Object Name, Count
    foreach ($category in $categories) {
        $data.ErrorsByCategory[$category.Name] = $category.Count
    }
    
    $sources = $Errors | Group-Object -Property Source | Select-Object Name, Count
    foreach ($source in $sources) {
        $data.ErrorsBySource[$source.Name] = $source.Count
    }
    
    # Enregistrer les donnÃ©es
    $dataPath = Join-Path -Path $versionFolder -ChildPath "error-data.json"
    $data | ConvertTo-Json -Depth 5 | Set-Content -Path $dataPath
    
    return $data
}

# Fonction pour charger les donnÃ©es d'erreurs d'une version
function Get-VersionErrorData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    
    # VÃ©rifier si les donnÃ©es existent
    $dataPath = Join-Path -Path $ComparisonConfig.DataFolder -ChildPath "$Version\error-data.json"
    if (-not (Test-Path -Path $dataPath)) {
        Write-Error "Les donnÃ©es d'erreurs pour la version '$Version' n'existent pas."
        return $null
    }
    
    # Charger les donnÃ©es
    $data = Get-Content -Path $dataPath -Raw | ConvertFrom-Json
    
    return $data
}

# Fonction pour comparer les erreurs entre deux versions
function Compare-VersionErrors {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Version1,
        
        [Parameter(Mandatory = $true)]
        [string]$Version2,
        
        [Parameter(Mandatory = $false)]
        [int]$DifferenceThreshold = 0
    )
    
    # Utiliser le seuil par dÃ©faut si non spÃ©cifiÃ©
    if ($DifferenceThreshold -le 0) {
        $DifferenceThreshold = $ComparisonConfig.DifferenceThreshold
    }
    
    # Charger les donnÃ©es des deux versions
    $data1 = Get-VersionErrorData -Version $Version1
    $data2 = Get-VersionErrorData -Version $Version2
    
    if (-not $data1 -or -not $data2) {
        return $null
    }
    
    # Calculer les diffÃ©rences
    $comparison = @{
        Version1 = $Version1
        Version2 = $Version2
        Timestamp = Get-Date -Format "o"
        
        # Statistiques gÃ©nÃ©rales
        ErrorCount1 = $data1.ErrorCount
        ErrorCount2 = $data2.ErrorCount
        ErrorCountDifference = $data2.ErrorCount - $data1.ErrorCount
        
        # DiffÃ©rences par sÃ©vÃ©ritÃ©
        SeverityDifferences = @{}
        
        # DiffÃ©rences par catÃ©gorie
        CategoryDifferences = @{}
        
        # DiffÃ©rences par source
        SourceDifferences = @{}
        
        # Erreurs nouvelles et rÃ©solues
        NewErrors = @()
        ResolvedErrors = @()
        
        # DiffÃ©rences significatives
        SignificantDifferences = @()
    }
    
    # Calculer le pourcentage de diffÃ©rence
    if ($data1.ErrorCount -gt 0) {
        $comparison.ErrorCountPercentage = [Math]::Round(($data2.ErrorCount - $data1.ErrorCount) / $data1.ErrorCount * 100, 2)
    }
    else {
        $comparison.ErrorCountPercentage = if ($data2.ErrorCount -gt 0) { 100 } else { 0 }
    }
    
    # Calculer les diffÃ©rences par sÃ©vÃ©ritÃ©
    $allSeverities = @($data1.ErrorsBySeverity.PSObject.Properties.Name) + @($data2.ErrorsBySeverity.PSObject.Properties.Name) | Select-Object -Unique
    
    foreach ($severity in $allSeverities) {
        $count1 = if ($data1.ErrorsBySeverity.PSObject.Properties[$severity]) { $data1.ErrorsBySeverity.$severity } else { 0 }
        $count2 = if ($data2.ErrorsBySeverity.PSObject.Properties[$severity]) { $data2.ErrorsBySeverity.$severity } else { 0 }
        $difference = $count2 - $count1
        
        $percentageDifference = if ($count1 -gt 0) {
            [Math]::Round(($count2 - $count1) / $count1 * 100, 2)
        }
        else {
            if ($count2 -gt 0) { 100 } else { 0 }
        }
        
        $comparison.SeverityDifferences[$severity] = @{
            Count1 = $count1
            Count2 = $count2
            Difference = $difference
            Percentage = $percentageDifference
        }
        
        # VÃ©rifier si la diffÃ©rence est significative
        if ([Math]::Abs($percentageDifference) -ge $DifferenceThreshold) {
            $comparison.SignificantDifferences += [PSCustomObject]@{
                Type = "Severity"
                Name = $severity
                Count1 = $count1
                Count2 = $count2
                Difference = $difference
                Percentage = $percentageDifference
            }
        }
    }
    
    # Calculer les diffÃ©rences par catÃ©gorie
    $allCategories = @($data1.ErrorsByCategory.PSObject.Properties.Name) + @($data2.ErrorsByCategory.PSObject.Properties.Name) | Select-Object -Unique
    
    foreach ($category in $allCategories) {
        $count1 = if ($data1.ErrorsByCategory.PSObject.Properties[$category]) { $data1.ErrorsByCategory.$category } else { 0 }
        $count2 = if ($data2.ErrorsByCategory.PSObject.Properties[$category]) { $data2.ErrorsByCategory.$category } else { 0 }
        $difference = $count2 - $count1
        
        $percentageDifference = if ($count1 -gt 0) {
            [Math]::Round(($count2 - $count1) / $count1 * 100, 2)
        }
        else {
            if ($count2 -gt 0) { 100 } else { 0 }
        }
        
        $comparison.CategoryDifferences[$category] = @{
            Count1 = $count1
            Count2 = $count2
            Difference = $difference
            Percentage = $percentageDifference
        }
        
        # VÃ©rifier si la diffÃ©rence est significative
        if ([Math]::Abs($percentageDifference) -ge $DifferenceThreshold) {
            $comparison.SignificantDifferences += [PSCustomObject]@{
                Type = "Category"
                Name = $category
                Count1 = $count1
                Count2 = $count2
                Difference = $difference
                Percentage = $percentageDifference
            }
        }
    }
    
    # Identifier les erreurs nouvelles et rÃ©solues
    # Note: Cette partie est simplifiÃ©e car nous ne pouvons pas comparer directement les erreurs individuelles
    # sans un identifiant unique. Dans une implÃ©mentation rÃ©elle, il faudrait un moyen de comparer les erreurs.
    
    return $comparison
}

# Fonction pour gÃ©nÃ©rer un rapport de comparaison
function New-ErrorComparisonReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Version1,
        
        [Parameter(Mandatory = $true)]
        [string]$Version2,
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport de comparaison d'erreurs",
        
        [Parameter(Mandatory = $false)]
        [int]$DifferenceThreshold = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Comparer les versions
    $comparison = Compare-VersionErrors -Version1 $Version1 -Version2 $Version2 -DifferenceThreshold $DifferenceThreshold
    
    if (-not $comparison) {
        return $null
    }
    
    # DÃ©terminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "ErrorComparison-$Version1-$Version2-$timestamp.html"
        $OutputPath = Join-Path -Path $ComparisonConfig.OutputFolder -ChildPath $fileName
    }
    
    # GÃ©nÃ©rer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .summary {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .summary-card {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            flex: 1;
            min-width: 200px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .summary-card h3 {
            margin-top: 0;
            margin-bottom: 10px;
            font-size: 16px;
        }
        
        .summary-value {
            font-size: 24px;
            font-weight: bold;
        }
        
        .charts-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(500px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .chart-card {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .chart-card h3 {
            margin-top: 0;
            margin-bottom: 15px;
            font-size: 18px;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background-color: #4caf50;
            color: white;
        }
        
        tr:hover {
            background-color: #f5f5f5;
        }
        
        .positive {
            color: #4caf50;
        }
        
        .negative {
            color: #f44336;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <div>
                <span>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <h3>Version 1</h3>
                <div class="summary-value">$Version1</div>
                <div>Erreurs: $($comparison.ErrorCount1)</div>
            </div>
            
            <div class="summary-card">
                <h3>Version 2</h3>
                <div class="summary-value">$Version2</div>
                <div>Erreurs: $($comparison.ErrorCount2)</div>
            </div>
            
            <div class="summary-card">
                <h3>DiffÃ©rence</h3>
                <div class="summary-value $($comparison.ErrorCountDifference -lt 0 ? 'positive' : ($comparison.ErrorCountDifference -gt 0 ? 'negative' : ''))">
                    $($comparison.ErrorCountDifference -ge 0 ? '+' : '')$($comparison.ErrorCountDifference) ($($comparison.ErrorCountPercentage)%)
                </div>
            </div>
        </div>
        
        <div class="charts-container">
            <div class="chart-card">
                <h3>Comparaison par sÃ©vÃ©ritÃ©</h3>
                <canvas id="severity-chart"></canvas>
            </div>
            
            <div class="chart-card">
                <h3>Comparaison par catÃ©gorie</h3>
                <canvas id="category-chart"></canvas>
            </div>
        </div>
        
        <h2>DiffÃ©rences significatives</h2>
        
        <table>
            <thead>
                <tr>
                    <th>Type</th>
                    <th>Nom</th>
                    <th>Version 1</th>
                    <th>Version 2</th>
                    <th>DiffÃ©rence</th>
                    <th>Pourcentage</th>
                </tr>
            </thead>
            <tbody>
                $(foreach ($diff in $comparison.SignificantDifferences) {
                    $diffClass = if ($diff.Difference -lt 0) { 'positive' } elseif ($diff.Difference -gt 0) { 'negative' } else { '' }
                    $diffSign = if ($diff.Difference -ge 0) { '+' } else { '' }
                    
                    "<tr>
                        <td>$($diff.Type)</td>
                        <td>$($diff.Name)</td>
                        <td>$($diff.Count1)</td>
                        <td>$($diff.Count2)</td>
                        <td class='$diffClass'>$diffSign$($diff.Difference)</td>
                        <td class='$diffClass'>$diffSign$($diff.Percentage)%</td>
                    </tr>"
                })
            </tbody>
        </table>
        
        <div class="footer">
            <p>Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Seuil de diffÃ©rence significative: $($DifferenceThreshold)%</p>
        </div>
    </div>
    
    <script>
        // DonnÃ©es pour les graphiques
        const severityData = {
            labels: [$(foreach ($key in $comparison.SeverityDifferences.Keys) { "'$key', " })],
            datasets: [
                {
                    label: 'Version 1',
                    data: [$(foreach ($key in $comparison.SeverityDifferences.Keys) { "$($comparison.SeverityDifferences[$key].Count1), " })],
                    backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    borderColor: 'rgb(54, 162, 235)',
                    borderWidth: 1
                },
                {
                    label: 'Version 2',
                    data: [$(foreach ($key in $comparison.SeverityDifferences.Keys) { "$($comparison.SeverityDifferences[$key].Count2), " })],
                    backgroundColor: 'rgba(255, 99, 132, 0.5)',
                    borderColor: 'rgb(255, 99, 132)',
                    borderWidth: 1
                }
            ]
        };
        
        const categoryData = {
            labels: [$(foreach ($key in $comparison.CategoryDifferences.Keys) { "'$key', " })],
            datasets: [
                {
                    label: 'Version 1',
                    data: [$(foreach ($key in $comparison.CategoryDifferences.Keys) { "$($comparison.CategoryDifferences[$key].Count1), " })],
                    backgroundColor: 'rgba(54, 162, 235, 0.5)',
                    borderColor: 'rgb(54, 162, 235)',
                    borderWidth: 1
                },
                {
                    label: 'Version 2',
                    data: [$(foreach ($key in $comparison.CategoryDifferences.Keys) { "$($comparison.CategoryDifferences[$key].Count2), " })],
                    backgroundColor: 'rgba(255, 99, 132, 0.5)',
                    borderColor: 'rgb(255, 99, 132)',
                    borderWidth: 1
                }
            ]
        };
        
        // Graphique par sÃ©vÃ©ritÃ©
        const severityCtx = document.getElementById('severity-chart').getContext('2d');
        new Chart(severityCtx, {
            type: 'bar',
            data: severityData,
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
        
        // Graphique par catÃ©gorie
        const categoryCtx = document.getElementById('category-chart').getContext('2d');
        new Chart(categoryCtx, {
            type: 'bar',
            data: categoryData,
            options: {
                responsive: true,
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });
    </script>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le rapport si demandÃ©
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorComparison, Save-VersionErrorData, Get-VersionErrorData, Compare-VersionErrors, New-ErrorComparisonReport

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}

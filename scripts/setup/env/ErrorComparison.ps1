# Script pour comparer les erreurs entre différentes versions

# Configuration
$ComparisonConfig = @{
    # Dossier de sortie des rapports
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorComparison"
    
    # Dossier des données d'erreurs
    DataFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorData"
    
    # Seuil de différence significative (en pourcentage)
    DifferenceThreshold = 20
}

# Fonction pour initialiser l'analyse comparative
function Initialize-ErrorComparison {
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string]$DataFolder = "",
        
        [Parameter(Mandatory = $false)]
        [int]$DifferenceThreshold = 0
    )
    
    # Mettre à jour la configuration
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $ComparisonConfig.OutputFolder = $OutputFolder
    }
    
    if (-not [string]::IsNullOrEmpty($DataFolder)) {
        $ComparisonConfig.DataFolder = $DataFolder
    }
    
    if ($DifferenceThreshold -gt 0) {
        $ComparisonConfig.DifferenceThreshold = $DifferenceThreshold
    }
    
    # Créer les dossiers s'ils n'existent pas
    foreach ($folder in @($ComparisonConfig.OutputFolder, $ComparisonConfig.DataFolder)) {
        if (-not (Test-Path -Path $folder)) {
            New-Item -Path $folder -ItemType Directory -Force | Out-Null
        }
    }
    
    return $ComparisonConfig
}

# Fonction pour capturer les données d'erreurs d'une version
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
    
    # Créer le dossier de version s'il n'existe pas
    $versionFolder = Join-Path -Path $ComparisonConfig.DataFolder -ChildPath $Version
    if (-not (Test-Path -Path $versionFolder)) {
        New-Item -Path $versionFolder -ItemType Directory -Force | Out-Null
    }
    
    # Préparer les données
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
    
    # Enregistrer les données
    $dataPath = Join-Path -Path $versionFolder -ChildPath "error-data.json"
    $data | ConvertTo-Json -Depth 5 | Set-Content -Path $dataPath
    
    return $data
}

# Fonction pour charger les données d'erreurs d'une version
function Get-VersionErrorData {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Version
    )
    
    # Vérifier si les données existent
    $dataPath = Join-Path -Path $ComparisonConfig.DataFolder -ChildPath "$Version\error-data.json"
    if (-not (Test-Path -Path $dataPath)) {
        Write-Error "Les données d'erreurs pour la version '$Version' n'existent pas."
        return $null
    }
    
    # Charger les données
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
    
    # Utiliser le seuil par défaut si non spécifié
    if ($DifferenceThreshold -le 0) {
        $DifferenceThreshold = $ComparisonConfig.DifferenceThreshold
    }
    
    # Charger les données des deux versions
    $data1 = Get-VersionErrorData -Version $Version1
    $data2 = Get-VersionErrorData -Version $Version2
    
    if (-not $data1 -or -not $data2) {
        return $null
    }
    
    # Calculer les différences
    $comparison = @{
        Version1 = $Version1
        Version2 = $Version2
        Timestamp = Get-Date -Format "o"
        
        # Statistiques générales
        ErrorCount1 = $data1.ErrorCount
        ErrorCount2 = $data2.ErrorCount
        ErrorCountDifference = $data2.ErrorCount - $data1.ErrorCount
        
        # Différences par sévérité
        SeverityDifferences = @{}
        
        # Différences par catégorie
        CategoryDifferences = @{}
        
        # Différences par source
        SourceDifferences = @{}
        
        # Erreurs nouvelles et résolues
        NewErrors = @()
        ResolvedErrors = @()
        
        # Différences significatives
        SignificantDifferences = @()
    }
    
    # Calculer le pourcentage de différence
    if ($data1.ErrorCount -gt 0) {
        $comparison.ErrorCountPercentage = [Math]::Round(($data2.ErrorCount - $data1.ErrorCount) / $data1.ErrorCount * 100, 2)
    }
    else {
        $comparison.ErrorCountPercentage = if ($data2.ErrorCount -gt 0) { 100 } else { 0 }
    }
    
    # Calculer les différences par sévérité
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
        
        # Vérifier si la différence est significative
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
    
    # Calculer les différences par catégorie
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
        
        # Vérifier si la différence est significative
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
    
    # Identifier les erreurs nouvelles et résolues
    # Note: Cette partie est simplifiée car nous ne pouvons pas comparer directement les erreurs individuelles
    # sans un identifiant unique. Dans une implémentation réelle, il faudrait un moyen de comparer les erreurs.
    
    return $comparison
}

# Fonction pour générer un rapport de comparaison
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
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "ErrorComparison-$Version1-$Version2-$timestamp.html"
        $OutputPath = Join-Path -Path $ComparisonConfig.OutputFolder -ChildPath $fileName
    }
    
    # Générer le HTML
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
                <span>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
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
                <h3>Différence</h3>
                <div class="summary-value $($comparison.ErrorCountDifference -lt 0 ? 'positive' : ($comparison.ErrorCountDifference -gt 0 ? 'negative' : ''))">
                    $($comparison.ErrorCountDifference -ge 0 ? '+' : '')$($comparison.ErrorCountDifference) ($($comparison.ErrorCountPercentage)%)
                </div>
            </div>
        </div>
        
        <div class="charts-container">
            <div class="chart-card">
                <h3>Comparaison par sévérité</h3>
                <canvas id="severity-chart"></canvas>
            </div>
            
            <div class="chart-card">
                <h3>Comparaison par catégorie</h3>
                <canvas id="category-chart"></canvas>
            </div>
        </div>
        
        <h2>Différences significatives</h2>
        
        <table>
            <thead>
                <tr>
                    <th>Type</th>
                    <th>Nom</th>
                    <th>Version 1</th>
                    <th>Version 2</th>
                    <th>Différence</th>
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
            <p>Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Seuil de différence significative: $($DifferenceThreshold)%</p>
        </div>
    </div>
    
    <script>
        // Données pour les graphiques
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
        
        // Graphique par sévérité
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
        
        // Graphique par catégorie
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
    
    # Ouvrir le rapport si demandé
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorComparison, Save-VersionErrorData, Get-VersionErrorData, Compare-VersionErrors, New-ErrorComparisonReport

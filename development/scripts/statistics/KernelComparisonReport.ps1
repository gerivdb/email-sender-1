<#
.SYNOPSIS
    Génère un rapport de comparaison des différents noyaux pour l'estimation de densité par noyau.

.DESCRIPTION
    Ce script génère un rapport de comparaison des différents noyaux pour l'estimation de densité par noyau.
    Il compare les performances et la précision des noyaux pour différentes distributions et tailles de données.

.PARAMETER OutputFormat
    Le format de sortie du rapport. Options: Text, HTML, JSON, CSV.

.PARAMETER IncludePerformanceTests
    Indique si les tests de performance doivent être inclus dans le rapport.

.PARAMETER IncludePrecisionTests
    Indique si les tests de précision doivent être inclus dans le rapport.

.PARAMETER DataSizes
    Les tailles de données à utiliser pour les tests de performance.

.PARAMETER KernelTypes
    Les types de noyaux à comparer.

.EXAMPLE
    .\KernelComparisonReport.ps1 -OutputFormat HTML -IncludePerformanceTests -IncludePrecisionTests
    Génère un rapport HTML complet avec les tests de performance et de précision.

.EXAMPLE
    .\KernelComparisonReport.ps1 -OutputFormat Text -IncludePerformanceTests -DataSizes @(100, 1000)
    Génère un rapport texte avec les tests de performance pour des tailles de données de 100 et 1000 points.

.NOTES
    Auteur: Augment AI
    Version: 1.0
    Date de création: 2023-05-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Text", "HTML", "JSON", "CSV")]
    [string]$OutputFormat = "Text",

    [Parameter(Mandatory = $false)]
    [switch]$IncludePerformanceTests = $true,

    [Parameter(Mandatory = $false)]
    [switch]$IncludePrecisionTests = $true,

    [Parameter(Mandatory = $false)]
    [int[]]$DataSizes = @(100, 1000, 10000),

    [Parameter(Mandatory = $false)]
    [string[]]$KernelTypes = @("Gaussian", "Epanechnikov", "Triangular", "Uniform", "Biweight", "Triweight", "Cosine")
)

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$scriptPath\GaussianKernel.ps1"
. "$scriptPath\EpanechnikovKernel.ps1"
. "$scriptPath\TriangularKernel.ps1"
. "$scriptPath\UniformKernel.ps1"
. "$scriptPath\BiweightKernel.ps1"
. "$scriptPath\TriweightKernel.ps1"
. "$scriptPath\CosineKernel.ps1"

# Fonction utilitaire pour générer des échantillons de distribution normale
function Get-NormalSample {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$NumPoints,

        [Parameter(Mandatory = $false)]
        [double]$Mean = 0,

        [Parameter(Mandatory = $false)]
        [double]$StdDev = 1
    )

    $sample = @()
    for ($i = 0; $i -lt $NumPoints; $i++) {
        # Méthode Box-Muller pour générer des nombres aléatoires suivant une distribution normale
        $u1 = [Math]::Max(0.0001, Get-Random -Minimum 0 -Maximum 1)
        $u2 = Get-Random -Minimum 0 -Maximum 1
        $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
        $sample += $Mean + $StdDev * $z
    }

    return $sample
}

# Fonction utilitaire pour calculer la densité théorique d'une distribution normale
function Get-NormalDensity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double]$X,

        [Parameter(Mandatory = $false)]
        [double]$Mean = 0,

        [Parameter(Mandatory = $false)]
        [double]$StdDev = 1
    )

    $z = ($X - $Mean) / $StdDev
    $density = (1 / ($StdDev * [Math]::Sqrt(2 * [Math]::PI))) * [Math]::Exp(-0.5 * $z * $z)

    return $density
}

# Fonction utilitaire pour calculer l'erreur quadratique moyenne entre deux densités
function Get-MeanSquaredError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Density1,

        [Parameter(Mandatory = $true)]
        [double[]]$Density2
    )

    if ($Density1.Count -ne $Density2.Count) {
        throw "Les densités doivent avoir le même nombre de points."
    }

    $mse = 0
    for ($i = 0; $i -lt $Density1.Count; $i++) {
        $mse += [Math]::Pow($Density1[$i] - $Density2[$i], 2)
    }

    return $mse / $Density1.Count
}

# Fonction pour exécuter les tests de performance
function Test-KernelPerformance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int[]]$DataSizes,

        [Parameter(Mandatory = $true)]
        [string[]]$KernelTypes
    )

    $results = @{}

    foreach ($dataSize in $DataSizes) {
        $results[$dataSize] = @{}

        # Générer des données
        $data = Get-NormalSample -NumPoints $dataSize -Mean 0 -StdDev 1

        foreach ($kernelType in $KernelTypes) {
            # Mesurer le temps d'exécution
            $startTime = Get-Date

            # Calculer la densité en un point
            switch ($kernelType) {
                "Gaussian" {
                    $density = Get-GaussianKernelDensity -X 0 -Data $data
                }
                "Epanechnikov" {
                    $density = Get-EpanechnikovKernelDensity -X 0 -Data $data
                }
                "Triangular" {
                    $density = Get-TriangularKernelDensity -X 0 -Data $data
                }
                "Uniform" {
                    $density = Get-UniformKernelDensity -X 0 -Data $data
                }
                "Biweight" {
                    $density = Get-BiweightKernelDensity -X 0 -Data $data
                }
                "Triweight" {
                    $density = Get-TriweightKernelDensity -X 0 -Data $data
                }
                "Cosine" {
                    $density = Get-CosineKernelDensity -X 0 -Data $data
                }
            }

            $endTime = Get-Date
            $executionTime = ($endTime - $startTime).TotalMilliseconds

            $results[$dataSize][$kernelType] = @{
                ExecutionTime = $executionTime
                Density       = $density
            }
        }
    }

    return $results
}

# Fonction pour exécuter les tests de précision
function Test-KernelPrecision {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$KernelTypes
    )

    $results = @{}

    # Générer des données
    $data = Get-NormalSample -NumPoints 1000 -Mean 0 -StdDev 1

    # Définir les points d'évaluation
    $evaluationPoints = -3..3 | ForEach-Object { $_ / 2 }

    foreach ($kernelType in $KernelTypes) {
        $densities = @()

        foreach ($x in $evaluationPoints) {
            $density = 0

            switch ($kernelType) {
                "Gaussian" {
                    $density = Get-GaussianKernelDensity -X $x -Data $data
                }
                "Epanechnikov" {
                    $density = Get-EpanechnikovKernelDensity -X $x -Data $data
                }
                "Triangular" {
                    $density = Get-TriangularKernelDensity -X $x -Data $data
                }
                "Uniform" {
                    $density = Get-UniformKernelDensity -X $x -Data $data
                }
                "Biweight" {
                    $density = Get-BiweightKernelDensity -X $x -Data $data
                }
                "Triweight" {
                    $density = Get-TriweightKernelDensity -X $x -Data $data
                }
                "Cosine" {
                    $density = Get-CosineKernelDensity -X $x -Data $data
                }
            }

            $densities += $density
        }

        # Calculer les densités théoriques
        $theoreticalDensities = @()
        foreach ($x in $evaluationPoints) {
            $density = Get-NormalDensity -X $x -Mean 0 -StdDev 1
            $theoreticalDensities += $density
        }

        # Calculer l'erreur quadratique moyenne
        $mse = Get-MeanSquaredError -Density1 $densities -Density2 $theoreticalDensities

        $results[$kernelType] = @{
            MSE              = $mse
            Densities        = $densities
            EvaluationPoints = $evaluationPoints
        }
    }

    return $results
}

# Fonction pour générer le rapport au format texte
function Get-TextReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$PerformanceResults,

        [Parameter(Mandatory = $true)]
        [hashtable]$PrecisionResults
    )

    $report = "=== Rapport de comparaison des noyaux pour l'estimation de densité par noyau ===`n`n"

    # Ajouter les résultats de performance
    $report += "== Tests de performance ==`n`n"

    foreach ($dataSize in $PerformanceResults.Keys | Sort-Object) {
        $report += "= Taille des données: $dataSize points =`n"
        $sortedKernels = $PerformanceResults[$dataSize].GetEnumerator() | Sort-Object -Property { $_.Value.ExecutionTime }

        foreach ($kernel in $sortedKernels) {
            $report += "  $($kernel.Name): $([Math]::Round($kernel.Value.ExecutionTime, 2)) ms`n"
        }

        $report += "`n"
    }

    # Ajouter les résultats de précision
    $report += "== Tests de précision ==`n`n"

    $sortedKernels = $PrecisionResults.GetEnumerator() | Sort-Object -Property { $_.Value.MSE }

    foreach ($kernel in $sortedKernels) {
        $report += "  $($kernel.Name): MSE = $([Math]::Round($kernel.Value.MSE, 6))`n"
    }

    return $report
}

# Fonction pour générer le rapport au format HTML
function Get-HtmlReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$PerformanceResults,

        [Parameter(Mandatory = $true)]
        [hashtable]$PrecisionResults
    )

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de comparaison des noyaux pour l'estimation de densité par noyau</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        h2 { color: #666; margin-top: 30px; }
        h3 { color: #999; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .best { font-weight: bold; color: green; }
    </style>
</head>
<body>
    <h1>Rapport de comparaison des noyaux pour l'estimation de densité par noyau</h1>

    <h2>Tests de performance</h2>
"@

    foreach ($dataSize in $PerformanceResults.Keys | Sort-Object) {
        $html += @"
    <h3>Taille des données: $dataSize points</h3>
    <table>
        <tr>
            <th>Noyau</th>
            <th>Temps d'exécution (ms)</th>
        </tr>
"@

        $sortedKernels = $PerformanceResults[$dataSize].GetEnumerator() | Sort-Object -Property { $_.Value.ExecutionTime }
        $bestTime = $sortedKernels[0].Value.ExecutionTime

        foreach ($kernel in $sortedKernels) {
            $class = if ($kernel.Value.ExecutionTime -eq $bestTime) { ' class="best"' } else { '' }
            $html += @"
        <tr$class>
            <td>$($kernel.Name)</td>
            <td>$([Math]::Round($kernel.Value.ExecutionTime, 2))</td>
        </tr>
"@
        }

        $html += @"
    </table>
"@
    }

    $html += @"

    <h2>Tests de précision</h2>
    <table>
        <tr>
            <th>Noyau</th>
            <th>Erreur quadratique moyenne (MSE)</th>
        </tr>
"@

    $sortedKernels = $PrecisionResults.GetEnumerator() | Sort-Object -Property { $_.Value.MSE }
    $bestMSE = $sortedKernels[0].Value.MSE

    foreach ($kernel in $sortedKernels) {
        $class = if ($kernel.Value.MSE -eq $bestMSE) { ' class="best"' } else { '' }
        $html += @"
        <tr$class>
            <td>$($kernel.Name)</td>
            <td>$([Math]::Round($kernel.Value.MSE, 6))</td>
        </tr>
"@
    }

    $html += @"
    </table>
</body>
</html>
"@

    return $html
}

# Fonction pour générer le rapport au format JSON
function Get-JsonReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$PerformanceResults,

        [Parameter(Mandatory = $true)]
        [hashtable]$PrecisionResults
    )

    $report = @{
        Performance = $PerformanceResults
        Precision   = $PrecisionResults
    }

    return ConvertTo-Json -InputObject $report -Depth 10
}

# Fonction pour générer le rapport au format CSV
function Get-CsvReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$PerformanceResults,

        [Parameter(Mandatory = $true)]
        [hashtable]$PrecisionResults
    )

    $csv = "DataSize,KernelType,ExecutionTime,MSE`n"

    foreach ($dataSize in $PerformanceResults.Keys | Sort-Object) {
        foreach ($kernelType in $PerformanceResults[$dataSize].Keys | Sort-Object) {
            $executionTime = $PerformanceResults[$dataSize][$kernelType].ExecutionTime
            $mse = if ($PrecisionResults.ContainsKey($kernelType)) { $PrecisionResults[$kernelType].MSE } else { "N/A" }

            $csv += "$dataSize,$kernelType,$executionTime,$mse`n"
        }
    }

    return $csv
}

# Exécuter les tests
$performanceResults = @{}
$precisionResults = @{}

if ($IncludePerformanceTests) {
    Write-Host "Exécution des tests de performance..."
    $performanceResults = Test-KernelPerformance -DataSizes $DataSizes -KernelTypes $KernelTypes
}

if ($IncludePrecisionTests) {
    Write-Host "Exécution des tests de précision..."
    $precisionResults = Test-KernelPrecision -KernelTypes $KernelTypes
}

# Générer le rapport
$report = ""

switch ($OutputFormat) {
    "Text" {
        $report = Get-TextReport -PerformanceResults $performanceResults -PrecisionResults $precisionResults
    }
    "HTML" {
        $report = Get-HtmlReport -PerformanceResults $performanceResults -PrecisionResults $precisionResults
    }
    "JSON" {
        $report = Get-JsonReport -PerformanceResults $performanceResults -PrecisionResults $precisionResults
    }
    "CSV" {
        $report = Get-CsvReport -PerformanceResults $performanceResults -PrecisionResults $precisionResults
    }
}

# Fonction pour générer des graphiques
function New-PerformanceChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$PerformanceResults,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # Vérifier si le module PSChart est disponible
    if (-not (Get-Module -ListAvailable -Name PSChart)) {
        Write-Warning "Le module PSChart n'est pas disponible. Les graphiques ne seront pas générés."
        return
    }

    # Importer le module PSChart
    Import-Module PSChart

    # Préparer les données pour le graphique
    $chartData = @()

    foreach ($dataSize in $PerformanceResults.Keys | Sort-Object) {
        foreach ($kernelType in $PerformanceResults[$dataSize].Keys) {
            $chartData += [PSCustomObject]@{
                DataSize      = $dataSize
                KernelType    = $kernelType
                ExecutionTime = $PerformanceResults[$dataSize][$kernelType].ExecutionTime
            }
        }
    }

    # Créer le graphique
    $chart = New-Chart -Title "Comparaison des performances des noyaux" -Width 800 -Height 600

    # Ajouter les séries pour chaque type de noyau
    foreach ($kernelType in ($chartData | Select-Object -ExpandProperty KernelType -Unique)) {
        $kernelData = $chartData | Where-Object { $_.KernelType -eq $kernelType }
        $dataSizes = $kernelData | Select-Object -ExpandProperty DataSize
        $executionTimes = $kernelData | Select-Object -ExpandProperty ExecutionTime

        Add-Series -Chart $chart -Name $kernelType -XValues $dataSizes -YValues $executionTimes -ChartType Line
    }

    # Configurer les axes
    Set-ChartAxis -Chart $chart -Axis X -Title "Taille des données" -TitleFont (New-ChartFont -Size 12 -Bold)
    Set-ChartAxis -Chart $chart -Axis Y -Title "Temps d'exécution (ms)" -TitleFont (New-ChartFont -Size 12 -Bold)

    # Ajouter une légende
    Add-ChartLegend -Chart $chart -Alignment BottomCenter

    # Enregistrer le graphique
    Export-Chart -Chart $chart -Path $OutputPath -Width 800 -Height 600
}

function New-PrecisionChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$PrecisionResults,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # Vérifier si le module PSChart est disponible
    if (-not (Get-Module -ListAvailable -Name PSChart)) {
        Write-Warning "Le module PSChart n'est pas disponible. Les graphiques ne seront pas générés."
        return
    }

    # Importer le module PSChart
    Import-Module PSChart

    # Préparer les données pour le graphique
    $chartData = @()

    foreach ($kernelType in $PrecisionResults.Keys) {
        $chartData += [PSCustomObject]@{
            KernelType = $kernelType
            MSE        = $PrecisionResults[$kernelType].MSE
        }
    }

    # Trier les données par MSE
    $chartData = $chartData | Sort-Object -Property MSE

    # Créer le graphique
    $chart = New-Chart -Title "Comparaison de la précision des noyaux" -Width 800 -Height 600

    # Ajouter les données
    $kernelTypes = $chartData | Select-Object -ExpandProperty KernelType
    $mseValues = $chartData | Select-Object -ExpandProperty MSE

    Add-Series -Chart $chart -Name "MSE" -XValues $kernelTypes -YValues $mseValues -ChartType Column

    # Configurer les axes
    Set-ChartAxis -Chart $chart -Axis X -Title "Type de noyau" -TitleFont (New-ChartFont -Size 12 -Bold)
    Set-ChartAxis -Chart $chart -Axis Y -Title "Erreur quadratique moyenne (MSE)" -TitleFont (New-ChartFont -Size 12 -Bold)

    # Enregistrer le graphique
    Export-Chart -Chart $chart -Path $OutputPath -Width 800 -Height 600
}

function New-DensityComparisonChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$PrecisionResults,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    # Vérifier si le module PSChart est disponible
    if (-not (Get-Module -ListAvailable -Name PSChart)) {
        Write-Warning "Le module PSChart n'est pas disponible. Les graphiques ne seront pas générés."
        return
    }

    # Importer le module PSChart
    Import-Module PSChart

    # Créer le graphique
    $chart = New-Chart -Title "Comparaison des densités estimées" -Width 800 -Height 600

    # Ajouter les séries pour chaque type de noyau
    foreach ($kernelType in $PrecisionResults.Keys) {
        $evaluationPoints = $PrecisionResults[$kernelType].EvaluationPoints
        $densities = $PrecisionResults[$kernelType].Densities

        Add-Series -Chart $chart -Name $kernelType -XValues $evaluationPoints -YValues $densities -ChartType Line
    }

    # Ajouter la densité théorique
    $theoreticalDensities = @()
    foreach ($x in $PrecisionResults[$PrecisionResults.Keys[0]].EvaluationPoints) {
        $density = Get-NormalDensity -X $x -Mean 0 -StdDev 1
        $theoreticalDensities += $density
    }

    Add-Series -Chart $chart -Name "Théorique" -XValues $PrecisionResults[$PrecisionResults.Keys[0]].EvaluationPoints -YValues $theoreticalDensities -ChartType Line

    # Configurer les axes
    Set-ChartAxis -Chart $chart -Axis X -Title "x" -TitleFont (New-ChartFont -Size 12 -Bold)
    Set-ChartAxis -Chart $chart -Axis Y -Title "Densité" -TitleFont (New-ChartFont -Size 12 -Bold)

    # Ajouter une légende
    Add-ChartLegend -Chart $chart -Alignment BottomCenter

    # Enregistrer le graphique
    Export-Chart -Chart $chart -Path $OutputPath -Width 800 -Height 600
}

# Générer des graphiques si le module PSChart est disponible
if (Get-Module -ListAvailable -Name PSChart) {
    $outputDir = Join-Path -Path $scriptPath -ChildPath "reports"

    # Créer le répertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory | Out-Null
    }

    # Générer les graphiques
    if ($IncludePerformanceTests) {
        $performanceChartPath = Join-Path -Path $outputDir -ChildPath "performance_chart.png"
        New-PerformanceChart -PerformanceResults $performanceResults -OutputPath $performanceChartPath
        Write-Host "Graphique de performance généré: $performanceChartPath"
    }

    if ($IncludePrecisionTests) {
        $precisionChartPath = Join-Path -Path $outputDir -ChildPath "precision_chart.png"
        New-PrecisionChart -PrecisionResults $precisionResults -OutputPath $precisionChartPath
        Write-Host "Graphique de précision généré: $precisionChartPath"

        $densityChartPath = Join-Path -Path $outputDir -ChildPath "density_chart.png"
        New-DensityComparisonChart -PrecisionResults $precisionResults -OutputPath $densityChartPath
        Write-Host "Graphique de comparaison des densités généré: $densityChartPath"
    }
}

# Enregistrer le rapport dans un fichier
$outputDir = Join-Path -Path $scriptPath -ChildPath "reports"

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

$reportPath = Join-Path -Path $outputDir -ChildPath "kernel_comparison_report.$($OutputFormat.ToLower())"
$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host "Rapport généré: $reportPath"

# Afficher le rapport
Write-Host $report

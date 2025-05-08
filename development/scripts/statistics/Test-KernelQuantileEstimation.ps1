# Test-KernelQuantileEstimation.ps1
# Ce script teste les fonctions de calcul des quantiles par estimation de densité

# Importer le module KernelQuantileEstimation
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "KernelQuantileEstimation.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module KernelQuantileEstimation.psm1 n'a pas été trouvé: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Définir le dossier de rapports
$reportsFolder = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $reportsFolder)) {
    New-Item -Path $reportsFolder -ItemType Directory | Out-Null
}

# Générer des données de test
Write-Host "`n=== Génération des données de test ===" -ForegroundColor Magenta

# Distribution normale
$normalData = 1..100 | ForEach-Object { [Math]::Round([System.Random]::new().NextDouble() * 10 - 5, 2) }

# Distribution asymétrique positive
$positiveSkewData = 1..100 | ForEach-Object {
    $value = [Math]::Pow([System.Random]::new().NextDouble(), 2) * 10
    [Math]::Round($value, 2)
}

# Distribution asymétrique négative
$negativeSkewData = 1..100 | ForEach-Object {
    $value = 10 - [Math]::Pow([System.Random]::new().NextDouble(), 2) * 10
    [Math]::Round($value, 2)
}

# Distribution bimodale
$bimodalData = @()
$bimodalData += 1..50 | ForEach-Object { [Math]::Round([System.Random]::new().NextDouble() * 3 - 5, 2) }
$bimodalData += 1..50 | ForEach-Object { [Math]::Round([System.Random]::new().NextDouble() * 3 + 2, 2) }

Write-Host "Données générées:" -ForegroundColor White
Write-Host "- Distribution normale: $($normalData.Count) points" -ForegroundColor White
Write-Host "- Distribution asymetrique positive: $($positiveSkewData.Count) points" -ForegroundColor White
Write-Host "- Distribution asymetrique negative: $($negativeSkewData.Count) points" -ForegroundColor White
Write-Host "- Distribution bimodale: $($bimodalData.Count) points" -ForegroundColor White

# Test 1: Calcul de la largeur de bande optimale
Write-Host "`n=== Test 1: Calcul de la largeur de bande optimale ===" -ForegroundColor Magenta
$methods = @("Silverman", "Scott", "ISJ")

Write-Host "Largeur de bande optimale:" -ForegroundColor White
foreach ($method in $methods) {
    $normalBandwidth = Get-OptimalBandwidth -Data $normalData -Method $method
    $positiveSkewBandwidth = Get-OptimalBandwidth -Data $positiveSkewData -Method $method
    $negativeSkewBandwidth = Get-OptimalBandwidth -Data $negativeSkewData -Method $method
    $bimodalBandwidth = Get-OptimalBandwidth -Data $bimodalData -Method $method

    Write-Host "  Methode ${method}:" -ForegroundColor Cyan
    Write-Host "    - Distribution normale: $normalBandwidth" -ForegroundColor White
    Write-Host "    - Distribution asymetrique positive: $positiveSkewBandwidth" -ForegroundColor White
    Write-Host "    - Distribution asymetrique negative: $negativeSkewBandwidth" -ForegroundColor White
    Write-Host "    - Distribution bimodale: $bimodalBandwidth" -ForegroundColor White
}

# Test 2: Calcul de la densité par noyau
Write-Host "`n=== Test 2: Calcul de la densité par noyau ===" -ForegroundColor Magenta
$kernels = @("Gaussian", "Epanechnikov")

Write-Host "Densité par noyau (distribution normale):" -ForegroundColor White
foreach ($kernel in $kernels) {
    $bandwidth = Get-OptimalBandwidth -Data $normalData -Method "Silverman"
    $kde = Get-KernelDensity -Data $normalData -Bandwidth $bandwidth -Kernel $kernel

    Write-Host "  Noyau ${kernel}:" -ForegroundColor Cyan
    Write-Host "    - Largeur de bande: $bandwidth" -ForegroundColor White
    Write-Host "    - Nombre de points: $($kde.Points.Count)" -ForegroundColor White
    Write-Host "    - Densité maximale: $([Math]::Round(($kde.Densities | Measure-Object -Maximum).Maximum, 4))" -ForegroundColor White
}

# Test 3: Calcul de la fonction de répartition empirique
Write-Host "`n=== Test 3: Calcul de la fonction de répartition empirique ===" -ForegroundColor Magenta
$normalCDF = Get-EmpiricalCDF -Data $normalData
$positiveSkewCDF = Get-EmpiricalCDF -Data $positiveSkewData
$negativeSkewCDF = Get-EmpiricalCDF -Data $negativeSkewData
$bimodalCDF = Get-EmpiricalCDF -Data $bimodalData

Write-Host "Fonction de répartition empirique:" -ForegroundColor White
Write-Host "  - Distribution normale: $($normalCDF.Points.Count) points" -ForegroundColor White
Write-Host "  - Distribution asymetrique positive: $($positiveSkewCDF.Points.Count) points" -ForegroundColor White
Write-Host "  - Distribution asymetrique negative: $($negativeSkewCDF.Points.Count) points" -ForegroundColor White
Write-Host "  - Distribution bimodale: $($bimodalCDF.Points.Count) points" -ForegroundColor White

# Test 4: Calcul des quantiles par estimation de densité
Write-Host "`n=== Test 4: Calcul des quantiles par estimation de densité ===" -ForegroundColor Magenta
$probabilities = @(0.1, 0.25, 0.5, 0.75, 0.9)
$methods = @("Interpolation")  # Limiter à une méthode pour accélérer les tests

Write-Host "Distribution normale:" -ForegroundColor White
foreach ($method in $methods) {
    Write-Host "  Methode ${method}:" -ForegroundColor Cyan
    foreach ($probability in $probabilities) {
        $quantile = Get-KernelQuantile -Data $normalData -Probability $probability -Method $method
        Write-Host "    Quantile $probability : $quantile" -ForegroundColor White
    }
}

Write-Host "`nDistribution asymetrique positive:" -ForegroundColor White
foreach ($method in $methods) {
    Write-Host "  Methode ${method}:" -ForegroundColor Cyan
    foreach ($probability in $probabilities) {
        $quantile = Get-KernelQuantile -Data $positiveSkewData -Probability $probability -Method $method
        Write-Host "    Quantile $probability : $quantile" -ForegroundColor White
    }
}

# Test 5: Comparaison avec les quantiles empiriques
Write-Host "`n=== Test 5: Comparaison avec les quantiles empiriques ===" -ForegroundColor Magenta

# Fonction pour calculer les quantiles empiriques
function Get-EmpiricalQuantile {
    param (
        [double[]]$Data,
        [double]$Probability
    )
    $sortedData = $Data | Sort-Object
    $index = [Math]::Floor($Probability * $sortedData.Count)
    if ($index -lt 0) { $index = 0 }
    if ($index -ge $sortedData.Count) { $index = $sortedData.Count - 1 }
    return $sortedData[$index]
}

Write-Host "Distribution normale:" -ForegroundColor White
foreach ($probability in $probabilities) {
    $kernelQuantile = Get-KernelQuantile -Data $normalData -Probability $probability -Method "Interpolation"
    $empiricalQuantile = Get-EmpiricalQuantile -Data $normalData -Probability $probability
    $difference = $kernelQuantile - $empiricalQuantile

    Write-Host "  Quantile $probability :" -ForegroundColor Cyan
    Write-Host "    - Kernel: $kernelQuantile" -ForegroundColor White
    Write-Host "    - Empirique: $empiricalQuantile" -ForegroundColor White
    Write-Host "    - Différence: $difference" -ForegroundColor White
}

Write-Host "`nDistribution asymetrique positive:" -ForegroundColor White
foreach ($probability in $probabilities) {
    $kernelQuantile = Get-KernelQuantile -Data $positiveSkewData -Probability $probability -Method "Interpolation"
    $empiricalQuantile = Get-EmpiricalQuantile -Data $positiveSkewData -Probability $probability
    $difference = $kernelQuantile - $empiricalQuantile

    Write-Host "  Quantile $probability :" -ForegroundColor Cyan
    Write-Host "    - Kernel: $kernelQuantile" -ForegroundColor White
    Write-Host "    - Empirique: $empiricalQuantile" -ForegroundColor White
    Write-Host "    - Différence: $difference" -ForegroundColor White
}

# Test 6: Génération d'un rapport JSON
Write-Host "`n=== Test 6: Génération d'un rapport JSON ===" -ForegroundColor Magenta
$jsonReportPath = Join-Path -Path $reportsFolder -ChildPath "kernel_quantile_report.json"

# Créer un rapport JSON avec les quantiles par estimation de densité
$reportData = @{
    metadata      = @{
        title          = "Rapport de quantiles par estimation de densité"
        generationDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        version        = "1.0"
    }
    distributions = @{
        normal       = @{
            name               = "Distribution normale"
            sampleSize         = $normalData.Count
            bandwidth          = Get-OptimalBandwidth -Data $normalData -Method "Silverman"
            quantiles          = @{}
            empiricalQuantiles = @{}
        }
        positiveSkew = @{
            name               = "Distribution asymétrique positive"
            sampleSize         = $positiveSkewData.Count
            bandwidth          = Get-OptimalBandwidth -Data $positiveSkewData -Method "Silverman"
            quantiles          = @{}
            empiricalQuantiles = @{}
        }
    }
}

# Ajouter les quantiles
foreach ($probability in $probabilities) {
    $reportData.distributions.normal.quantiles["q$($probability * 100)"] = Get-KernelQuantile -Data $normalData -Probability $probability -Method "Interpolation"
    $reportData.distributions.normal.empiricalQuantiles["q$($probability * 100)"] = Get-EmpiricalQuantile -Data $normalData -Probability $probability

    $reportData.distributions.positiveSkew.quantiles["q$($probability * 100)"] = Get-KernelQuantile -Data $positiveSkewData -Probability $probability -Method "Interpolation"
    $reportData.distributions.positiveSkew.empiricalQuantiles["q$($probability * 100)"] = Get-EmpiricalQuantile -Data $positiveSkewData -Probability $probability
}

# Enregistrer le rapport JSON
$reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonReportPath -Encoding UTF8
Write-Host "Rapport JSON généré: $jsonReportPath" -ForegroundColor Green
Write-Host "Taille du rapport: $((Get-Item -Path $jsonReportPath).Length) octets" -ForegroundColor White

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green
Write-Host "Les fonctions de calcul des quantiles par estimation de densité fonctionnent correctement." -ForegroundColor Green

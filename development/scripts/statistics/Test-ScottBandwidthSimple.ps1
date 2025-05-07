# Importer le module
Import-Module .\development\scripts\statistics\KernelDensityEstimation.psm1 -Force

# Générer des données de test simples
$normalData = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

# Test simple
Write-Host "Test simple de la fonction Get-ScottBandwidth" -ForegroundColor Cyan
$bandwidth = Get-ScottBandwidth -Data $normalData -KernelType "Gaussian" -DistributionType "Normal"
Write-Host "Largeur de bande avec type de distribution spécifié: $bandwidth" -ForegroundColor Green

$autoBandwidth = Get-ScottBandwidth -Data $normalData -KernelType "Gaussian"
Write-Host "Largeur de bande avec détection automatique: $autoBandwidth" -ForegroundColor Green

# Afficher les valeurs des variables
Write-Host "`nDébogage des variables:" -ForegroundColor Magenta
$mean = ($normalData | Measure-Object -Average).Average
$stdDev = [Math]::Sqrt(($normalData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)
$expectedBandwidth = 1.06 * $stdDev * [Math]::Pow($normalData.Count, -0.2)

Write-Host "Moyenne: $mean" -ForegroundColor White
Write-Host "Écart-type: $stdDev" -ForegroundColor White
Write-Host "Largeur de bande attendue: $expectedBandwidth" -ForegroundColor White

# Comparer avec la règle de Silverman
$silvermanBandwidth = Get-SilvermanBandwidth -Data $normalData -KernelType "Gaussian" -DistributionType "Normal"
Write-Host "`nComparaison avec la règle de Silverman:" -ForegroundColor Magenta
Write-Host "Largeur de bande selon la méthode de Scott: $bandwidth" -ForegroundColor Green
Write-Host "Largeur de bande selon la règle de Silverman: $silvermanBandwidth" -ForegroundColor Green
Write-Host "Ratio Scott/Silverman: $([Math]::Round($bandwidth / $silvermanBandwidth, 4))" -ForegroundColor White

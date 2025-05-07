# Importer le module
Import-Module .\development\scripts\statistics\KernelDensityEstimation.psm1 -Force

# Générer des données de test très simples
$simpleData = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

# Test simple
Write-Host "Test simple de la fonction Get-KFoldCVBandwidth" -ForegroundColor Cyan
$bandwidth = Get-KFoldCVBandwidth -Data $simpleData -KernelType "Gaussian" -BandwidthRange @(0.5, 5, 0.5) -K 2 -MaxIterations 10 -Verbose
Write-Host "Largeur de bande optimale par validation croisée k-fold: $bandwidth" -ForegroundColor Green

# Comparaison avec les autres méthodes
$loocvBandwidth = Get-LeaveOneOutCVBandwidth -Data $simpleData -KernelType "Gaussian" -BandwidthRange @(0.5, 5, 0.5) -MaxIterations 10
$silvermanBandwidth = Get-SilvermanBandwidth -Data $simpleData -KernelType "Gaussian" -DistributionType "Normal"
$scottBandwidth = Get-ScottBandwidth -Data $simpleData -KernelType "Gaussian" -DistributionType "Normal"

Write-Host "`nComparaison avec les autres méthodes:" -ForegroundColor Magenta
Write-Host "Largeur de bande par validation croisée k-fold: $bandwidth" -ForegroundColor Green
Write-Host "Largeur de bande par validation croisée leave-one-out: $loocvBandwidth" -ForegroundColor Green
Write-Host "Largeur de bande par la règle de Silverman: $silvermanBandwidth" -ForegroundColor Green
Write-Host "Largeur de bande par la méthode de Scott: $scottBandwidth" -ForegroundColor Green

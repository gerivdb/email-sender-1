# Importer le module
Import-Module .\development\scripts\statistics\KernelDensityEstimation.psm1 -Force

# Générer des données de test simples
$normalData = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

# Test simple
Write-Host "Test simple de la fonction Get-SilvermanBandwidth" -ForegroundColor Cyan
$bandwidth = Get-SilvermanBandwidth -Data $normalData -KernelType "Gaussian" -DistributionType "Normal"
Write-Host "Largeur de bande avec type de distribution spécifié: $bandwidth" -ForegroundColor Green

# Afficher le code de la fonction
$functionCode = (Get-Command Get-SilvermanBandwidth).ScriptBlock.ToString()
Write-Host "`nCode de la fonction:" -ForegroundColor Magenta
Write-Host $functionCode -ForegroundColor Gray

# Exécuter la fonction avec détection automatique
Write-Host "`nExécution de la fonction avec détection automatique:" -ForegroundColor Magenta
$autoBandwidth = Get-SilvermanBandwidth -Data $normalData -KernelType "Gaussian" -Verbose
Write-Host "Largeur de bande avec détection automatique: $autoBandwidth" -ForegroundColor Green

# Afficher les valeurs des variables
Write-Host "`nDébogage des variables:" -ForegroundColor Magenta
$mean = ($normalData | Measure-Object -Average).Average
$stdDev = [Math]::Sqrt(($normalData | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)
$sortedData = $normalData | Sort-Object
$q1Index = [Math]::Floor($sortedData.Count * 0.25)
$q3Index = [Math]::Floor($sortedData.Count * 0.75)
$q1 = $sortedData[$q1Index]
$q3 = $sortedData[$q3Index]
$iqr = $q3 - $q1
$minValue = [Math]::Min($stdDev, $iqr / 1.34)
$expectedBandwidth = 0.9 * $minValue * [Math]::Pow($normalData.Count, -0.2)

Write-Host "Moyenne: $mean" -ForegroundColor White
Write-Host "Écart-type: $stdDev" -ForegroundColor White
Write-Host "Q1 (index $q1Index): $q1" -ForegroundColor White
Write-Host "Q3 (index $q3Index): $q3" -ForegroundColor White
Write-Host "IQR: $iqr" -ForegroundColor White
Write-Host "min(stdDev, IQR/1.34): $minValue" -ForegroundColor White
Write-Host "Largeur de bande attendue: $expectedBandwidth" -ForegroundColor White

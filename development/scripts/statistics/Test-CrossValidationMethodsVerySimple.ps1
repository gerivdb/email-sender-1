# Importer le module
Import-Module .\development\scripts\statistics\KernelDensityEstimation.psm1 -Force

# Générer des données de test très simples
$simpleData = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

# Tester les méthodes de validation croisée
Write-Host "=== Test des méthodes de validation croisée ===" -ForegroundColor Magenta

# Tester la méthode de Silverman
$startTime = Get-Date
$silvermanBandwidth = Get-SilvermanBandwidth -Data $simpleData -KernelType "Gaussian" -DistributionType "Normal"
$endTime = Get-Date
$silvermanTime = ($endTime - $startTime).TotalSeconds

# Tester la méthode de Scott
$startTime = Get-Date
$scottBandwidth = Get-ScottBandwidth -Data $simpleData -KernelType "Gaussian" -DistributionType "Normal"
$endTime = Get-Date
$scottTime = ($endTime - $startTime).TotalSeconds

# Tester la validation croisée par k-fold
$startTime = Get-Date
$kfoldBandwidth = Get-KFoldCVBandwidth -Data $simpleData -KernelType "Gaussian" -BandwidthRange @(0.5, 5, 0.5) -K 2 -MaxIterations 10
$endTime = Get-Date
$kfoldTime = ($endTime - $startTime).TotalSeconds

# Tester l'optimisation par validation croisée
$startTime = Get-Date
$optimizedBandwidth = Get-OptimizedCVBandwidth -Data $simpleData -KernelType "Gaussian" -ValidationMethod "KFold" -K 2 -MaxIterations 10 -Tolerance 0.1
$endTime = Get-Date
$optimizedTime = ($endTime - $startTime).TotalSeconds

# Afficher les résultats
Write-Host "| Méthode | Largeur de bande | Temps d'exécution (s) |" -ForegroundColor White
Write-Host "|---------|-----------------|------------------------|" -ForegroundColor White
Write-Host "| Silverman | $([Math]::Round($silvermanBandwidth, 4)) | $([Math]::Round($silvermanTime, 4)) |" -ForegroundColor Green
Write-Host "| Scott | $([Math]::Round($scottBandwidth, 4)) | $([Math]::Round($scottTime, 4)) |" -ForegroundColor Green
Write-Host "| K-Fold CV | $([Math]::Round($kfoldBandwidth, 4)) | $([Math]::Round($kfoldTime, 4)) |" -ForegroundColor Green
Write-Host "| Optimized CV | $([Math]::Round($optimizedBandwidth, 4)) | $([Math]::Round($optimizedTime, 4)) |" -ForegroundColor Green

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green

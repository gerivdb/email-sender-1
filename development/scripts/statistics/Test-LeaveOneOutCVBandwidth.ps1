# Importer le module
Import-Module .\development\scripts\statistics\KernelDensityEstimation.psm1 -Force

# Générer des données de test simples
$normalData = @()
for ($i = 0; $i -lt 20; $i++) {
    # Méthode Box-Muller pour générer des nombres aléatoires suivant une loi normale
    $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
    if ($u1 -eq 0) { $u1 = 0.0001 }
    
    $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
    $normalData += 100 + 15 * $z  # Moyenne 100, écart-type 15
}

# Test 1: Calcul de la largeur de bande optimale par validation croisée
Write-Host "`n=== Test 1: Calcul de la largeur de bande optimale par validation croisée ===" -ForegroundColor Magenta
$cvBandwidth = Get-LeaveOneOutCVBandwidth -Data $normalData -KernelType "Gaussian" -Verbose
Write-Host "Largeur de bande optimale par validation croisée: $([Math]::Round($cvBandwidth, 4))" -ForegroundColor Green

# Test 2: Comparaison avec les méthodes de Silverman et Scott
Write-Host "`n=== Test 2: Comparaison avec les méthodes de Silverman et Scott ===" -ForegroundColor Magenta
$silvermanBandwidth = Get-SilvermanBandwidth -Data $normalData -KernelType "Gaussian"
$scottBandwidth = Get-ScottBandwidth -Data $normalData -KernelType "Gaussian"

Write-Host "Largeur de bande par validation croisée: $([Math]::Round($cvBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande par la règle de Silverman: $([Math]::Round($silvermanBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande par la méthode de Scott: $([Math]::Round($scottBandwidth, 4))" -ForegroundColor Green

Write-Host "`nRatio CV/Silverman: $([Math]::Round($cvBandwidth / $silvermanBandwidth, 4))" -ForegroundColor White
Write-Host "Ratio CV/Scott: $([Math]::Round($cvBandwidth / $scottBandwidth, 4))" -ForegroundColor White

# Test 3: Calcul de la largeur de bande optimale pour différents types de noyaux
Write-Host "`n=== Test 3: Calcul de la largeur de bande optimale pour différents types de noyaux ===" -ForegroundColor Magenta
$gaussianBandwidth = Get-LeaveOneOutCVBandwidth -Data $normalData -KernelType "Gaussian" -Verbose
$epanechnikovBandwidth = Get-LeaveOneOutCVBandwidth -Data $normalData -KernelType "Epanechnikov" -Verbose
$triangularBandwidth = Get-LeaveOneOutCVBandwidth -Data $normalData -KernelType "Triangular" -Verbose

Write-Host "Largeur de bande pour le noyau gaussien: $([Math]::Round($gaussianBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande pour le noyau d'Epanechnikov: $([Math]::Round($epanechnikovBandwidth, 4))" -ForegroundColor Green
Write-Host "Largeur de bande pour le noyau triangulaire: $([Math]::Round($triangularBandwidth, 4))" -ForegroundColor Green

# Test 4: Calcul de la largeur de bande optimale avec une plage de largeurs de bande spécifiée
Write-Host "`n=== Test 4: Calcul de la largeur de bande optimale avec une plage de largeurs de bande spécifiée ===" -ForegroundColor Magenta
$customBandwidth = Get-LeaveOneOutCVBandwidth -Data $normalData -KernelType "Gaussian" -BandwidthRange @(5, 25, 1) -Verbose
Write-Host "Largeur de bande optimale avec une plage spécifiée: $([Math]::Round($customBandwidth, 4))" -ForegroundColor Green

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
$allTestsPassed = ($cvBandwidth -gt 0) -and ($gaussianBandwidth -gt 0) -and ($epanechnikovBandwidth -gt 0) -and ($triangularBandwidth -gt 0) -and ($customBandwidth -gt 0)
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Résultat global: $(if ($allTestsPassed) { "Tous les tests ont réussi" } else { "Certains tests ont échoué" })" -ForegroundColor $(if ($allTestsPassed) { "Green" } else { "Red" })

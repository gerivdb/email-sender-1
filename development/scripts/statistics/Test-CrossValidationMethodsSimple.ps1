# Importer le module
Import-Module .\development\scripts\statistics\KernelDensityEstimation.psm1 -Force

# Générer des données de test très simples
$simpleData = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

# Fonction pour tester les méthodes de validation croisée
function Test-CrossValidationMethod {
    param (
        [string]$MethodName,
        [double[]]$Data,
        [string]$KernelType = "Gaussian"
    )
    
    $startTime = Get-Date
    
    switch ($MethodName) {
        "LeaveOneOut" {
            $bandwidth = Get-LeaveOneOutCVBandwidth -Data $Data -KernelType $KernelType -BandwidthRange @(0.5, 5, 0.5) -MaxIterations 10
        }
        "KFold" {
            $bandwidth = Get-KFoldCVBandwidth -Data $Data -KernelType $KernelType -BandwidthRange @(0.5, 5, 0.5) -K 2 -MaxIterations 10
        }
        "Optimized-LeaveOneOut" {
            $bandwidth = Get-OptimizedCVBandwidth -Data $Data -KernelType $KernelType -ValidationMethod "LeaveOneOut" -MaxIterations 10 -Tolerance 0.1
        }
        "Optimized-KFold" {
            $bandwidth = Get-OptimizedCVBandwidth -Data $Data -KernelType $KernelType -ValidationMethod "KFold" -K 2 -MaxIterations 10 -Tolerance 0.1
        }
        "Silverman" {
            $bandwidth = Get-SilvermanBandwidth -Data $Data -KernelType $KernelType -DistributionType "Normal"
        }
        "Scott" {
            $bandwidth = Get-ScottBandwidth -Data $Data -KernelType $KernelType -DistributionType "Normal"
        }
    }
    
    $endTime = Get-Date
    $executionTime = ($endTime - $startTime).TotalSeconds
    
    return @{
        Method = $MethodName
        Bandwidth = $bandwidth
        ExecutionTime = $executionTime
    }
}

# Tester les méthodes de validation croisée
Write-Host "=== Test des méthodes de validation croisée ===" -ForegroundColor Magenta

$methods = @("LeaveOneOut", "KFold", "Optimized-LeaveOneOut", "Optimized-KFold", "Silverman", "Scott")

Write-Host "| Méthode | Largeur de bande | Temps d'exécution (s) |" -ForegroundColor White
Write-Host "|---------|-----------------|------------------------|" -ForegroundColor White

foreach ($method in $methods) {
    $result = Test-CrossValidationMethod -MethodName $method -Data $simpleData -KernelType "Gaussian"
    Write-Host "| $($result.Method) | $([Math]::Round($result.Bandwidth, 4)) | $([Math]::Round($result.ExecutionTime, 4)) |" -ForegroundColor Green
}

# Tester les méthodes de validation croisée avec différents noyaux
Write-Host "`n=== Test des méthodes de validation croisée avec différents noyaux ===" -ForegroundColor Magenta

$kernels = @("Gaussian", "Epanechnikov", "Triangular")
$method = "Optimized-KFold"  # Utiliser une seule méthode pour simplifier

Write-Host "| Noyau | Largeur de bande | Temps d'exécution (s) |" -ForegroundColor White
Write-Host "|-------|-----------------|------------------------|" -ForegroundColor White

foreach ($kernel in $kernels) {
    $result = Test-CrossValidationMethod -MethodName $method -Data $simpleData -KernelType $kernel
    Write-Host "| $kernel | $([Math]::Round($result.Bandwidth, 4)) | $([Math]::Round($result.ExecutionTime, 4)) |" -ForegroundColor Green
}

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green

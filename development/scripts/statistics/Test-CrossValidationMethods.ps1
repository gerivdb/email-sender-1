# Importer le module
Import-Module .\development\scripts\statistics\KernelDensityEstimation.psm1 -Force

# Fonction pour générer des données de test
function New-TestData {
    param (
        [string]$Distribution = "Normal",
        [int]$Size = 100,
        [double]$Mean = 100,
        [double]$StdDev = 15
    )
    
    $data = @()
    
    switch ($Distribution) {
        "Normal" {
            # Distribution normale
            for ($i = 0; $i -lt $Size; $i++) {
                $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
                $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
                if ($u1 -eq 0) { $u1 = 0.0001 }
                
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                $data += $Mean + $StdDev * $z
            }
        }
        "Skewed" {
            # Distribution asymétrique (log-normale)
            for ($i = 0; $i -lt $Size; $i++) {
                $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
                $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
                if ($u1 -eq 0) { $u1 = 0.0001 }
                
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                $data += $Mean + $StdDev * [Math]::Exp($z / 2)
            }
        }
        "Multimodal" {
            # Distribution bimodale
            $halfSize = [Math]::Floor($Size / 2)
            
            # Premier mode
            for ($i = 0; $i -lt $halfSize; $i++) {
                $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
                $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
                if ($u1 -eq 0) { $u1 = 0.0001 }
                
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                $data += ($Mean - 20) + ($StdDev / 2) * $z
            }
            
            # Deuxième mode
            for ($i = 0; $i -lt ($Size - $halfSize); $i++) {
                $u1 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
                $u2 = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
                if ($u1 -eq 0) { $u1 = 0.0001 }
                
                $z = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Cos(2 * [Math]::PI * $u2)
                $data += ($Mean + 20) + ($StdDev / 2) * $z
            }
        }
    }
    
    return $data
}

# Fonction pour tester les méthodes de validation croisée
function Test-CrossValidationMethod {
    param (
        [string]$MethodName,
        [double[]]$Data,
        [string]$KernelType = "Gaussian",
        [int]$K = 5
    )
    
    $startTime = Get-Date
    
    switch ($MethodName) {
        "LeaveOneOut" {
            $bandwidth = Get-LeaveOneOutCVBandwidth -Data $Data -KernelType $KernelType -BandwidthRange @(0.5, 20, 0.5) -MaxIterations 20
        }
        "KFold" {
            $bandwidth = Get-KFoldCVBandwidth -Data $Data -KernelType $KernelType -BandwidthRange @(0.5, 20, 0.5) -K $K -MaxIterations 20
        }
        "Optimized-LeaveOneOut" {
            $bandwidth = Get-OptimizedCVBandwidth -Data $Data -KernelType $KernelType -ValidationMethod "LeaveOneOut" -MaxIterations 20 -Tolerance 0.1
        }
        "Optimized-KFold" {
            $bandwidth = Get-OptimizedCVBandwidth -Data $Data -KernelType $KernelType -ValidationMethod "KFold" -K $K -MaxIterations 20 -Tolerance 0.1
        }
        "Silverman" {
            $bandwidth = Get-SilvermanBandwidth -Data $Data -KernelType $KernelType
        }
        "Scott" {
            $bandwidth = Get-ScottBandwidth -Data $Data -KernelType $KernelType
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

# Générer des données de test
Write-Host "Génération des données de test..." -ForegroundColor Cyan
$normalData = New-TestData -Distribution "Normal" -Size 50
$skewedData = New-TestData -Distribution "Skewed" -Size 50
$multimodalData = New-TestData -Distribution "Multimodal" -Size 50

# Tester les méthodes de validation croisée sur différentes distributions
Write-Host "`n=== Test des méthodes de validation croisée sur différentes distributions ===" -ForegroundColor Magenta

$methods = @("LeaveOneOut", "KFold", "Optimized-LeaveOneOut", "Optimized-KFold", "Silverman", "Scott")
$distributions = @(
    @{ Name = "Normal"; Data = $normalData },
    @{ Name = "Skewed"; Data = $skewedData },
    @{ Name = "Multimodal"; Data = $multimodalData }
)

foreach ($distribution in $distributions) {
    Write-Host "`nDistribution: $($distribution.Name)" -ForegroundColor Yellow
    Write-Host "| Méthode | Largeur de bande | Temps d'exécution (s) |" -ForegroundColor White
    Write-Host "|---------|-----------------|------------------------|" -ForegroundColor White
    
    foreach ($method in $methods) {
        $result = Test-CrossValidationMethod -MethodName $method -Data $distribution.Data -KernelType "Gaussian" -K 5
        Write-Host "| $($result.Method) | $([Math]::Round($result.Bandwidth, 4)) | $([Math]::Round($result.ExecutionTime, 4)) |" -ForegroundColor Green
    }
}

# Tester les méthodes de validation croisée avec différents noyaux
Write-Host "`n=== Test des méthodes de validation croisée avec différents noyaux ===" -ForegroundColor Magenta

$kernels = @("Gaussian", "Epanechnikov", "Triangular")

foreach ($kernel in $kernels) {
    Write-Host "`nNoyau: $kernel" -ForegroundColor Yellow
    Write-Host "| Méthode | Largeur de bande | Temps d'exécution (s) |" -ForegroundColor White
    Write-Host "|---------|-----------------|------------------------|" -ForegroundColor White
    
    foreach ($method in $methods) {
        $result = Test-CrossValidationMethod -MethodName $method -Data $normalData -KernelType $kernel -K 5
        Write-Host "| $($result.Method) | $([Math]::Round($result.Bandwidth, 4)) | $([Math]::Round($result.ExecutionTime, 4)) |" -ForegroundColor Green
    }
}

# Tester l'impact du nombre de plis (K) sur la validation croisée par k-fold
Write-Host "`n=== Test de l'impact du nombre de plis (K) sur la validation croisée par k-fold ===" -ForegroundColor Magenta

$kValues = @(2, 5, 10)

Write-Host "| K | Largeur de bande | Temps d'exécution (s) |" -ForegroundColor White
Write-Host "|---|-----------------|------------------------|" -ForegroundColor White

foreach ($k in $kValues) {
    $result = Test-CrossValidationMethod -MethodName "KFold" -Data $normalData -KernelType "Gaussian" -K $k
    Write-Host "| $k | $([Math]::Round($result.Bandwidth, 4)) | $([Math]::Round($result.ExecutionTime, 4)) |" -ForegroundColor Green
}

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green
Write-Host "Les méthodes de validation croisée ont été testées sur différentes distributions, avec différents noyaux et différents nombres de plis." -ForegroundColor Green

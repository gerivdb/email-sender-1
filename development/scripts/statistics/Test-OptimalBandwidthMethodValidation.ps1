# Importer le module
Import-Module .\development\scripts\statistics\KernelDensityEstimation.psm1 -Force

# Fonction pour générer des données de test
function New-TestData {
    param (
        [string]$Distribution = "Normal",
        [int]$Size = 100,
        [double]$Mean = 100,
        [double]$StdDev = 15,
        [double]$OutlierPercentage = 0
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
        "Uniform" {
            # Distribution uniforme
            for ($i = 0; $i -lt $Size; $i++) {
                $data += $Mean - $StdDev + 2 * $StdDev * (Get-Random -Minimum 0 -Maximum 1000) / 1000
            }
        }
        "Exponential" {
            # Distribution exponentielle
            for ($i = 0; $i -lt $Size; $i++) {
                $u = [double](Get-Random -Minimum 0 -Maximum 1000) / 1000
                if ($u -eq 0) { $u = 0.0001 }
                if ($u -eq 1) { $u = 0.9999 }
                
                $data += $Mean - $StdDev * [Math]::Log(1 - $u)
            }
        }
    }
    
    # Ajouter des valeurs aberrantes si demandé
    if ($OutlierPercentage -gt 0) {
        $numOutliers = [Math]::Max(1, [Math]::Floor($Size * $OutlierPercentage / 100))
        for ($i = 0; $i -lt $numOutliers; $i++) {
            $data[$i] = $Mean + $StdDev * 5 * (Get-Random -Minimum -1 -Maximum 2)
        }
    }
    
    return $data
}

# Fonction pour calculer l'erreur quadratique moyenne entre la densité estimée et la densité théorique
function Get-MeanSquaredError {
    param (
        [double[]]$Data,
        [double]$Bandwidth,
        [string]$KernelType = "Gaussian",
        [string]$Distribution = "Normal",
        [double]$Mean = 100,
        [double]$StdDev = 15
    )
    
    # Générer des points d'évaluation
    $evalPoints = @()
    $min = ($Data | Measure-Object -Minimum).Minimum
    $max = ($Data | Measure-Object -Maximum).Maximum
    $range = $max - $min
    $min = $min - 0.1 * $range
    $max = $max + 0.1 * $range
    $step = $range / 100
    
    for ($x = $min; $x -le $max; $x += $step) {
        $evalPoints += $x
    }
    
    # Calculer la densité estimée et la densité théorique pour chaque point d'évaluation
    $mse = 0
    
    foreach ($x in $evalPoints) {
        # Calculer la densité estimée
        $estimatedDensity = 0
        
        switch ($KernelType) {
            "Gaussian" {
                $estimatedDensity = Get-GaussianKernelDensity -X $x -Data $Data -Bandwidth $Bandwidth
            }
            "Epanechnikov" {
                $estimatedDensity = Get-EpanechnikovKernelDensity -X $x -Data $Data -Bandwidth $Bandwidth
            }
            "Triangular" {
                $estimatedDensity = Get-TriangularKernelDensity -X $x -Data $Data -Bandwidth $Bandwidth
            }
        }
        
        # Calculer la densité théorique
        $theoreticalDensity = 0
        
        switch ($Distribution) {
            "Normal" {
                $theoreticalDensity = (1 / ($StdDev * [Math]::Sqrt(2 * [Math]::PI))) * [Math]::Exp(-[Math]::Pow(($x - $Mean) / $StdDev, 2) / 2)
            }
            "Uniform" {
                if ($x -ge ($Mean - $StdDev) -and $x -le ($Mean + $StdDev)) {
                    $theoreticalDensity = 1 / (2 * $StdDev)
                } else {
                    $theoreticalDensity = 0
                }
            }
            "Exponential" {
                if ($x -ge $Mean) {
                    $theoreticalDensity = (1 / $StdDev) * [Math]::Exp(-($x - $Mean) / $StdDev)
                } else {
                    $theoreticalDensity = 0
                }
            }
            default {
                # Pour les autres distributions, utiliser la densité estimée comme référence
                $theoreticalDensity = $estimatedDensity
            }
        }
        
        # Calculer l'erreur quadratique
        $mse += [Math]::Pow($estimatedDensity - $theoreticalDensity, 2)
    }
    
    $mse = $mse / $evalPoints.Count
    return $mse
}

# Générer différents types de données de test
Write-Host "Génération des données de test..." -ForegroundColor Cyan
$normalData = New-TestData -Distribution "Normal" -Size 100
$skewedData = New-TestData -Distribution "Skewed" -Size 100
$multimodalData = New-TestData -Distribution "Multimodal" -Size 100
$uniformData = New-TestData -Distribution "Uniform" -Size 100
$exponentialData = New-TestData -Distribution "Exponential" -Size 100
$outlierData = New-TestData -Distribution "Normal" -Size 100 -OutlierPercentage 10

# Test 1: Validation de la sélection automatique sur différentes distributions
Write-Host "`n=== Test 1: Validation de la sélection automatique sur différentes distributions ===" -ForegroundColor Magenta

$distributions = @(
    @{ Name = "Normal"; Data = $normalData; TheoreticalDist = "Normal" },
    @{ Name = "Skewed"; Data = $skewedData; TheoreticalDist = "Skewed" },
    @{ Name = "Multimodal"; Data = $multimodalData; TheoreticalDist = "Multimodal" },
    @{ Name = "Uniform"; Data = $uniformData; TheoreticalDist = "Uniform" },
    @{ Name = "Exponential"; Data = $exponentialData; TheoreticalDist = "Exponential" },
    @{ Name = "Normal with Outliers"; Data = $outlierData; TheoreticalDist = "Normal" }
)

Write-Host "| Distribution | Méthode sélectionnée | Largeur de bande | Erreur quadratique moyenne |" -ForegroundColor White
Write-Host "|--------------|---------------------|------------------|----------------------------|" -ForegroundColor White

foreach ($distribution in $distributions) {
    $result = Get-OptimalBandwidthMethod -Data $distribution.Data -KernelType "Gaussian" -Objective "Balanced" -AutoDetect $true
    $mse = Get-MeanSquaredError -Data $distribution.Data -Bandwidth $result.Bandwidth -KernelType "Gaussian" -Distribution $distribution.TheoreticalDist
    
    Write-Host "| $($distribution.Name) | $($result.SelectedMethod) | $([Math]::Round($result.Bandwidth, 4)) | $([Math]::Round($mse, 8)) |" -ForegroundColor Green
}

# Test 2: Validation de la sélection automatique avec différents objectifs
Write-Host "`n=== Test 2: Validation de la sélection automatique avec différents objectifs ===" -ForegroundColor Magenta

$objectives = @("Accuracy", "Speed", "Robustness", "Adaptability", "Balanced")

Write-Host "| Objectif | Méthode sélectionnée | Largeur de bande | Temps d'exécution (s) | Erreur quadratique moyenne |" -ForegroundColor White
Write-Host "|----------|---------------------|------------------|----------------------|----------------------------|" -ForegroundColor White

foreach ($objective in $objectives) {
    $result = Get-OptimalBandwidthMethod -Data $normalData -KernelType "Gaussian" -Objective $objective -AutoDetect $true
    $mse = Get-MeanSquaredError -Data $normalData -Bandwidth $result.Bandwidth -KernelType "Gaussian" -Distribution "Normal"
    
    Write-Host "| $objective | $($result.SelectedMethod) | $([Math]::Round($result.Bandwidth, 4)) | $([Math]::Round($result.ExecutionTime, 4)) | $([Math]::Round($mse, 8)) |" -ForegroundColor Green
}

# Test 3: Validation de la sélection automatique avec différents noyaux
Write-Host "`n=== Test 3: Validation de la sélection automatique avec différents noyaux ===" -ForegroundColor Magenta

$kernels = @("Gaussian", "Epanechnikov", "Triangular")

Write-Host "| Noyau | Méthode sélectionnée | Largeur de bande | Erreur quadratique moyenne |" -ForegroundColor White
Write-Host "|-------|---------------------|------------------|----------------------------|" -ForegroundColor White

foreach ($kernel in $kernels) {
    $result = Get-OptimalBandwidthMethod -Data $normalData -KernelType $kernel -Objective "Balanced" -AutoDetect $true
    $mse = Get-MeanSquaredError -Data $normalData -Bandwidth $result.Bandwidth -KernelType $kernel -Distribution "Normal"
    
    Write-Host "| $kernel | $($result.SelectedMethod) | $([Math]::Round($result.Bandwidth, 4)) | $([Math]::Round($mse, 8)) |" -ForegroundColor Green
}

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green

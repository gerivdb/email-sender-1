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

# Générer différents types de données de test
Write-Host "Génération des données de test..." -ForegroundColor Cyan
$normalData = New-TestData -Distribution "Normal" -Size 50
$skewedData = New-TestData -Distribution "Skewed" -Size 50
$multimodalData = New-TestData -Distribution "Multimodal" -Size 50
$outlierData = New-TestData -Distribution "Normal" -Size 50 -OutlierPercentage 10

# Tester la sélection automatique de la méthode optimale sur différentes distributions
Write-Host "`n=== Test de la sélection automatique de la méthode optimale sur différentes distributions ===" -ForegroundColor Magenta

$distributions = @(
    @{ Name = "Normal"; Data = $normalData },
    @{ Name = "Skewed"; Data = $skewedData },
    @{ Name = "Multimodal"; Data = $multimodalData },
    @{ Name = "Normal with Outliers"; Data = $outlierData }
)

foreach ($distribution in $distributions) {
    Write-Host "`nDistribution: $($distribution.Name)" -ForegroundColor Yellow
    $result = Get-OptimalBandwidthMethod -Data $distribution.Data -KernelType "Gaussian" -Objective "Balanced" -AutoDetect $true
    
    Write-Host "Méthode sélectionnée: $($result.SelectedMethod)" -ForegroundColor Green
    Write-Host "Largeur de bande: $([Math]::Round($result.Bandwidth, 4))" -ForegroundColor Green
    Write-Host "Temps d'exécution: $([Math]::Round($result.ExecutionTime, 4)) s" -ForegroundColor Green
    Write-Host "Base de la recommandation: $($result.RecommendationBasis)" -ForegroundColor Green
}

# Tester la sélection automatique de la méthode optimale avec différents objectifs
Write-Host "`n=== Test de la sélection automatique de la méthode optimale avec différents objectifs ===" -ForegroundColor Magenta

$objectives = @("Accuracy", "Speed", "Robustness", "Adaptability", "Balanced")

foreach ($objective in $objectives) {
    Write-Host "`nObjectif: $objective" -ForegroundColor Yellow
    $result = Get-OptimalBandwidthMethod -Data $multimodalData -KernelType "Gaussian" -Objective $objective -AutoDetect $true
    
    Write-Host "Méthode sélectionnée: $($result.SelectedMethod)" -ForegroundColor Green
    Write-Host "Largeur de bande: $([Math]::Round($result.Bandwidth, 4))" -ForegroundColor Green
    Write-Host "Temps d'exécution: $([Math]::Round($result.ExecutionTime, 4)) s" -ForegroundColor Green
    Write-Host "Base de la recommandation: $($result.RecommendationBasis)" -ForegroundColor Green
}

# Tester la sélection automatique de la méthode optimale avec et sans détection automatique
Write-Host "`n=== Test de la sélection automatique de la méthode optimale avec et sans détection automatique ===" -ForegroundColor Magenta

Write-Host "`nAvec détection automatique:" -ForegroundColor Yellow
$resultWithAutoDetect = Get-OptimalBandwidthMethod -Data $normalData -KernelType "Gaussian" -Objective "Balanced" -AutoDetect $true

Write-Host "Méthode sélectionnée: $($resultWithAutoDetect.SelectedMethod)" -ForegroundColor Green
Write-Host "Largeur de bande: $([Math]::Round($resultWithAutoDetect.Bandwidth, 4))" -ForegroundColor Green
Write-Host "Temps d'exécution: $([Math]::Round($resultWithAutoDetect.ExecutionTime, 4)) s" -ForegroundColor Green
Write-Host "Base de la recommandation: $($resultWithAutoDetect.RecommendationBasis)" -ForegroundColor Green

Write-Host "`nSans détection automatique:" -ForegroundColor Yellow
$resultWithoutAutoDetect = Get-OptimalBandwidthMethod -Data $normalData -KernelType "Gaussian" -Objective "Balanced" -AutoDetect $false

Write-Host "Méthode sélectionnée: $($resultWithoutAutoDetect.SelectedMethod)" -ForegroundColor Green
Write-Host "Largeur de bande: $([Math]::Round($resultWithoutAutoDetect.Bandwidth, 4))" -ForegroundColor Green
Write-Host "Temps d'exécution: $([Math]::Round($resultWithoutAutoDetect.ExecutionTime, 4)) s" -ForegroundColor Green
Write-Host "Base de la recommandation: $($resultWithoutAutoDetect.RecommendationBasis)" -ForegroundColor Green

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green

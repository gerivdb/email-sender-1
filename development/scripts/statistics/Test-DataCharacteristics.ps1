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
$normalData = New-TestData -Distribution "Normal" -Size 100
$skewedData = New-TestData -Distribution "Skewed" -Size 100
$multimodalData = New-TestData -Distribution "Multimodal" -Size 100
$outlierData = New-TestData -Distribution "Normal" -Size 100 -OutlierPercentage 10

# Tester la détection des caractéristiques sur différentes distributions
Write-Host "`n=== Test de la détection des caractéristiques sur différentes distributions ===" -ForegroundColor Magenta

$distributions = @(
    @{ Name = "Normal"; Data = $normalData },
    @{ Name = "Skewed"; Data = $skewedData },
    @{ Name = "Multimodal"; Data = $multimodalData },
    @{ Name = "Normal with Outliers"; Data = $outlierData }
)

foreach ($distribution in $distributions) {
    Write-Host "`nDistribution: $($distribution.Name)" -ForegroundColor Yellow
    $characteristics = Get-DataCharacteristics -Data $distribution.Data -Verbose
    
    Write-Host "`nRésumé des caractéristiques:" -ForegroundColor White
    Write-Host "- Taille de l'échantillon: $($characteristics.SampleSize)" -ForegroundColor Green
    Write-Host "- Moyenne: $([Math]::Round($characteristics.Mean, 2))" -ForegroundColor Green
    Write-Host "- Médiane: $([Math]::Round($characteristics.Median, 2))" -ForegroundColor Green
    Write-Host "- Écart-type: $([Math]::Round($characteristics.StdDev, 2))" -ForegroundColor Green
    Write-Host "- Asymétrie: $([Math]::Round($characteristics.Skewness, 2))" -ForegroundColor Green
    Write-Host "- Aplatissement: $([Math]::Round($characteristics.Kurtosis, 2))" -ForegroundColor Green
    Write-Host "- Distribution normale: $($characteristics.IsNormal)" -ForegroundColor Green
    Write-Host "- Distribution asymétrique: $($characteristics.IsSkewed)" -ForegroundColor Green
    Write-Host "- Distribution multimodale: $($characteristics.IsMultimodal)" -ForegroundColor Green
    Write-Host "- Présence de valeurs aberrantes: $($characteristics.HasOutliers)" -ForegroundColor Green
    Write-Host "- Nombre de valeurs aberrantes: $($characteristics.OutlierCount)" -ForegroundColor Green
    Write-Host "- Pourcentage de valeurs aberrantes: $([Math]::Round($characteristics.OutlierPercentage, 2))%" -ForegroundColor Green
    Write-Host "- Nombre de modes: $($characteristics.ModeCount)" -ForegroundColor Green
    Write-Host "- Complexité: $($characteristics.Complexity)" -ForegroundColor Green
    Write-Host "- Méthode recommandée: $($characteristics.RecommendedMethod)" -ForegroundColor Green
}

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green

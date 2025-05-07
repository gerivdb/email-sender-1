# Fonction simplifiée pour calculer la largeur de bande optimale en utilisant la règle de Silverman
function Get-SimpleSilvermanBandwidth {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,

        [Parameter(Mandatory = $false)]
        [string]$KernelType = "Gaussian",

        [Parameter(Mandatory = $false)]
        [string]$DistributionType = $null
    )

    # Vérifier que les données contiennent au moins 2 points
    if ($Data.Count -lt 2) {
        throw "Les données doivent contenir au moins 2 points pour calculer la largeur de bande optimale."
    }

    # Si le type de distribution n'est pas spécifié, le détecter automatiquement
    if ([string]::IsNullOrEmpty($DistributionType)) {
        # Calculer les statistiques de base
        $mean = ($Data | Measure-Object -Average).Average
        $n = $Data.Count
        
        # Calculer l'écart-type
        $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Average).Average)
        
        # Détecter le type de distribution en fonction de la taille de l'échantillon
        if ($n -lt 30) {
            $DistributionType = "Sparse"
        } else {
            $DistributionType = "Normal"
        }
        
        Write-Host "Type de distribution détecté: $DistributionType (n: $n)"
    }

    # Calculer l'écart-type
    $stdDev = [Math]::Sqrt(($Data | ForEach-Object { [Math]::Pow($_ - ($Data | Measure-Object -Average).Average, 2) } | Measure-Object -Average).Average)
    
    # Calculer l'IQR (écart interquartile)
    $sortedData = $Data | Sort-Object
    $q1Index = [Math]::Floor($sortedData.Count * 0.25)
    $q3Index = [Math]::Floor($sortedData.Count * 0.75)
    $q1 = $sortedData[$q1Index]
    $q3 = $sortedData[$q3Index]
    $iqr = $q3 - $q1
    
    # Calculer la largeur de bande optimale de base
    $minValue = [Math]::Min($stdDev, $iqr / 1.34)
    if ($minValue -le 0) {
        $minValue = $stdDev  # Fallback si IQR est trop petit
    }
    $bandwidth = 0.9 * $minValue * [Math]::Pow($Data.Count, -0.2)

    # Appliquer des facteurs de correction en fonction du type de noyau
    $kernelFactor = 1.0
    if ($KernelType -eq "Epanechnikov") {
        $kernelFactor = 1.05
    } elseif ($KernelType -eq "Triangular") {
        $kernelFactor = 1.1
    }
    $bandwidth *= $kernelFactor

    # Appliquer des ajustements en fonction du type de distribution
    $distributionFactor = 1.0
    if ($DistributionType -eq "Skewed") {
        $distributionFactor = 1.1
    } elseif ($DistributionType -eq "HeavyTailed") {
        $distributionFactor = 1.2
    } elseif ($DistributionType -eq "Multimodal") {
        $distributionFactor = 0.8
    } elseif ($DistributionType -eq "Sparse") {
        $distributionFactor = 1.2
    }
    $bandwidth *= $distributionFactor

    return $bandwidth
}

# Générer des données de test simples
$normalData = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

# Test simple
Write-Host "Test simple de la fonction Get-SimpleSilvermanBandwidth" -ForegroundColor Cyan
$bandwidth = Get-SimpleSilvermanBandwidth -Data $normalData -KernelType "Gaussian" -DistributionType "Normal"
Write-Host "Largeur de bande avec type de distribution spécifié: $bandwidth" -ForegroundColor Green

$autoBandwidth = Get-SimpleSilvermanBandwidth -Data $normalData -KernelType "Gaussian"
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

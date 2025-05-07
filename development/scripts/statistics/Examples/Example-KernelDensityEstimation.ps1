# Example-KernelDensityEstimation.ps1
# Exemple d'utilisation de la fonction Get-KernelDensityEstimation

# Importer le module
Import-Module ..\KernelDensityEstimation.psm1 -Force

# Fonction pour afficher un histogramme textuel
function Show-TextHistogram {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$Data,
        
        [Parameter(Mandatory = $false)]
        [int]$NumBins = 20,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 50,
        
        [Parameter(Mandatory = $false)]
        [int]$Height = 10
    )
    
    # Calculer les limites de l'histogramme
    $min = ($Data | Measure-Object -Minimum).Minimum
    $max = ($Data | Measure-Object -Maximum).Maximum
    $range = $max - $min
    
    # Calculer la largeur des bins
    $binWidth = $range / $NumBins
    
    # Initialiser les bins
    $bins = New-Object int[] $NumBins
    $binCenters = New-Object double[] $NumBins
    
    # Calculer les centres des bins
    for ($i = 0; $i -lt $NumBins; $i++) {
        $binCenters[$i] = $min + ($i + 0.5) * $binWidth
    }
    
    # Compter les points dans chaque bin
    foreach ($value in $Data) {
        if ($value -ge $min -and $value -lt $max) {
            $binIndex = [Math]::Floor(($value - $min) / $binWidth)
            
            # Gérer le cas où la valeur est exactement égale au max
            if ($binIndex -eq $NumBins) {
                $binIndex = $NumBins - 1
            }
            
            $bins[$binIndex]++
        }
    }
    
    # Trouver le nombre maximum de points dans un bin
    $maxBinCount = ($bins | Measure-Object -Maximum).Maximum
    
    # Afficher l'histogramme
    Write-Host "Histogramme des données:" -ForegroundColor Cyan
    Write-Host "Min: $min, Max: $max, Nombre de bins: $NumBins" -ForegroundColor Cyan
    
    # Afficher l'axe Y et les barres
    for ($i = $Height; $i -gt 0; $i--) {
        $threshold = $maxBinCount * $i / $Height
        $line = ""
        
        # Ajouter l'étiquette de l'axe Y
        if ($i -eq $Height) {
            $yLabel = [Math]::Round($maxBinCount, 2).ToString()
            $line += $yLabel.PadLeft(8) + " |"
        } elseif ($i -eq 1) {
            $yLabel = [Math]::Round($maxBinCount / $Height, 2).ToString()
            $line += $yLabel.PadLeft(8) + " |"
        } elseif ($i -eq [Math]::Ceiling($Height / 2)) {
            $yLabel = [Math]::Round($maxBinCount * $i / $Height, 2).ToString()
            $line += $yLabel.PadLeft(8) + " |"
        } else {
            $line += " " * 8 + " |"
        }
        
        # Ajouter les barres
        for ($j = 0; $j -lt $NumBins; $j++) {
            $binCount = $bins[$j]
            if ($binCount -ge $threshold) {
                $line += "#"
            } else {
                $line += " "
            }
        }
        
        Write-Host $line
    }
    
    # Afficher l'axe X
    $xAxis = " " * 8 + " +" + "-" * $NumBins
    Write-Host $xAxis
    
    # Afficher les étiquettes de l'axe X
    $xLabels = " " * 8 + "  "
    for ($i = 0; $i -lt $NumBins; $i += [Math]::Max(1, [Math]::Floor($NumBins / 5))) {
        $xLabel = [Math]::Round($binCenters[$i], 1).ToString()
        $xLabels += $xLabel.PadRight([Math]::Max(1, [Math]::Floor($NumBins / 5)))
    }
    Write-Host $xLabels
}

# Fonction pour afficher un graphique linéaire textuel
function Show-TextLinePlot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [double[]]$X,
        
        [Parameter(Mandatory = $true)]
        [double[]]$Y,
        
        [Parameter(Mandatory = $false)]
        [int]$Width = 50,
        
        [Parameter(Mandatory = $false)]
        [int]$Height = 10,
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "Graphique linéaire"
    )
    
    # Vérifier que les tableaux X et Y ont la même longueur
    if ($X.Count -ne $Y.Count) {
        throw "Les tableaux X et Y doivent avoir la même longueur."
    }
    
    # Calculer les limites du graphique
    $minX = ($X | Measure-Object -Minimum).Minimum
    $maxX = ($X | Measure-Object -Maximum).Maximum
    $minY = ($Y | Measure-Object -Minimum).Minimum
    $maxY = ($Y | Measure-Object -Maximum).Maximum
    
    # Afficher le titre
    Write-Host $Title -ForegroundColor Cyan
    
    # Créer une grille 2D pour le graphique
    $grid = New-Object 'char[,]' ($Height + 1), ($Width + 1)
    
    # Initialiser la grille avec des espaces
    for ($i = 0; $i -le $Height; $i++) {
        for ($j = 0; $j -le $Width; $j++) {
            $grid[$i, $j] = ' '
        }
    }
    
    # Ajouter l'axe Y
    for ($i = 0; $i -le $Height; $i++) {
        $grid[$i, 0] = '|'
    }
    
    # Ajouter l'axe X
    for ($j = 0; $j -le $Width; $j++) {
        $grid[$Height, $j] = '-'
    }
    
    # Ajouter l'origine
    $grid[$Height, 0] = '+'
    
    # Ajouter les points de données
    for ($i = 0; $i -lt $X.Count; $i++) {
        $x = $X[$i]
        $y = $Y[$i]
        
        # Mettre à l'échelle les valeurs x et y pour la grille
        $xScaled = [Math]::Floor(($x - $minX) / ($maxX - $minX) * $Width)
        $yScaled = [Math]::Floor(($y - $minY) / ($maxY - $minY) * $Height)
        
        # S'assurer que les valeurs mises à l'échelle sont dans la grille
        $xScaled = [Math]::Max(0, [Math]::Min($Width, $xScaled))
        $yScaled = [Math]::Max(0, [Math]::Min($Height, $yScaled))
        
        # Inverser l'axe Y (0 est en haut dans la grille)
        $yScaled = $Height - $yScaled
        
        # Ajouter le point de données à la grille
        $grid[$yScaled, $xScaled] = '*'
    }
    
    # Convertir la grille en chaînes
    for ($i = 0; $i -le $Height; $i++) {
        $line = ""
        
        # Ajouter l'étiquette de l'axe Y
        if ($i -eq 0) {
            $yLabel = [Math]::Round($maxY, 2).ToString()
            $line += $yLabel.PadLeft(8) + " "
        } elseif ($i -eq $Height) {
            $yLabel = [Math]::Round($minY, 2).ToString()
            $line += $yLabel.PadLeft(8) + " "
        } elseif ($i -eq [Math]::Floor($Height / 2)) {
            $yLabel = [Math]::Round($minY + ($maxY - $minY) * ($Height - $i) / $Height, 2).ToString()
            $line += $yLabel.PadLeft(8) + " "
        } else {
            $line += " " * 8 + " "
        }
        
        # Ajouter la ligne de la grille
        for ($j = 0; $j -le $Width; $j++) {
            $line += $grid[$i, $j]
        }
        
        Write-Host $line
    }
    
    # Ajouter les étiquettes de l'axe X
    $xLabels = " " * 8 + "  "
    for ($i = 0; $i -le $Width; $i += [Math]::Max(1, [Math]::Floor($Width / 5))) {
        $xValue = $minX + ($maxX - $minX) * $i / $Width
        $xLabel = [Math]::Round($xValue, 1).ToString()
        $xLabels += $xLabel.PadRight([Math]::Max(1, [Math]::Floor($Width / 5)))
    }
    Write-Host $xLabels
}

# Exemple 1: Distribution normale
Write-Host "`nExemple 1: Distribution normale" -ForegroundColor Magenta
Write-Host "----------------------------" -ForegroundColor Magenta

# Générer des données suivant une distribution normale
$mean = 0
$stdDev = 1
$sampleSize = 100
$random = New-Object System.Random(42)
$normalData = New-Object double[] $sampleSize

for ($i = 0; $i -lt $sampleSize; $i++) {
    # Transformation Box-Muller pour générer une distribution normale
    $u1 = $random.NextDouble()
    $u2 = $random.NextDouble()
    $z0 = [Math]::Sqrt(-2.0 * [Math]::Log($u1)) * [Math]::Cos(2.0 * [Math]::PI * $u2)
    $normalData[$i] = $mean + $stdDev * $z0
}

# Afficher l'histogramme des données
Show-TextHistogram -Data $normalData -NumBins 20 -Width 50 -Height 10

# Effectuer l'estimation de densité par noyau avec différents types de noyaux
$kernelTypes = @("Gaussian", "Epanechnikov", "Triangular")

foreach ($kernelType in $kernelTypes) {
    Write-Host "`nEstimation de densité par noyau ($kernelType):" -ForegroundColor Yellow
    
    # Effectuer l'estimation de densité par noyau
    $kde = Get-KernelDensityEstimation -Data $normalData -KernelType $kernelType -BandwidthMethod "Silverman"
    
    # Afficher les informations sur l'estimation
    Write-Host "  Largeur de bande: $($kde.Bandwidth)" -ForegroundColor Green
    Write-Host "  Nombre de points d'évaluation: $($kde.EvaluationPoints.Count)" -ForegroundColor Green
    
    # Afficher le graphique de l'estimation de densité
    Show-TextLinePlot -X $kde.EvaluationPoints -Y $kde.DensityEstimates -Width 50 -Height 10 -Title "Estimation de densité par noyau ($kernelType)"
}

# Exemple 2: Distribution bimodale
Write-Host "`nExemple 2: Distribution bimodale" -ForegroundColor Magenta
Write-Host "----------------------------" -ForegroundColor Magenta

# Générer des données suivant une distribution bimodale
$mean1 = -2
$mean2 = 2
$stdDev1 = 0.5
$stdDev2 = 0.5
$weight = 0.6
$bimodalData = New-Object double[] $sampleSize

for ($i = 0; $i -lt $sampleSize; $i++) {
    # Choisir la composante en fonction du poids
    if ($random.NextDouble() -lt $weight) {
        # Première composante
        $u1 = $random.NextDouble()
        $u2 = $random.NextDouble()
        $z0 = [Math]::Sqrt(-2.0 * [Math]::Log($u1)) * [Math]::Cos(2.0 * [Math]::PI * $u2)
        $bimodalData[$i] = $mean1 + $stdDev1 * $z0
    } else {
        # Deuxième composante
        $u1 = $random.NextDouble()
        $u2 = $random.NextDouble()
        $z0 = [Math]::Sqrt(-2.0 * [Math]::Log($u1)) * [Math]::Cos(2.0 * [Math]::PI * $u2)
        $bimodalData[$i] = $mean2 + $stdDev2 * $z0
    }
}

# Afficher l'histogramme des données
Show-TextHistogram -Data $bimodalData -NumBins 20 -Width 50 -Height 10

# Effectuer l'estimation de densité par noyau avec différentes méthodes de sélection de largeur de bande
$bandwidthMethods = @("Silverman", "Scott", "Manual")
$manualBandwidth = 0.5

foreach ($bandwidthMethod in $bandwidthMethods) {
    $params = @{
        Data = $bimodalData
        KernelType = "Gaussian"
        BandwidthMethod = $bandwidthMethod
    }
    
    if ($bandwidthMethod -eq "Manual") {
        $params["Bandwidth"] = $manualBandwidth
    }
    
    Write-Host "`nEstimation de densité par noyau (Méthode de largeur de bande: $bandwidthMethod):" -ForegroundColor Yellow
    
    # Effectuer l'estimation de densité par noyau
    $kde = Get-KernelDensityEstimation @params
    
    # Afficher les informations sur l'estimation
    Write-Host "  Largeur de bande: $($kde.Bandwidth)" -ForegroundColor Green
    Write-Host "  Nombre de points d'évaluation: $($kde.EvaluationPoints.Count)" -ForegroundColor Green
    
    # Afficher le graphique de l'estimation de densité
    Show-TextLinePlot -X $kde.EvaluationPoints -Y $kde.DensityEstimates -Width 50 -Height 10 -Title "Estimation de densité par noyau (Méthode: $bandwidthMethod)"
}

# Exemple 3: Sélection automatique du noyau optimal
Write-Host "`nExemple 3: Sélection automatique du noyau optimal" -ForegroundColor Magenta
Write-Host "-------------------------------------------" -ForegroundColor Magenta

# Effectuer l'estimation de densité par noyau avec sélection automatique du noyau
$kde = Get-KernelDensityEstimation -Data $bimodalData -KernelType "Optimal" -Objective "Precision"

# Afficher les informations sur l'estimation
Write-Host "Noyau optimal sélectionné: $($kde.KernelType)" -ForegroundColor Green
Write-Host "Largeur de bande: $($kde.Bandwidth)" -ForegroundColor Green
Write-Host "Nombre de points d'évaluation: $($kde.EvaluationPoints.Count)" -ForegroundColor Green

# Afficher le graphique de l'estimation de densité
Show-TextLinePlot -X $kde.EvaluationPoints -Y $kde.DensityEstimates -Width 50 -Height 10 -Title "Estimation de densité par noyau (Noyau optimal: $($kde.KernelType))"

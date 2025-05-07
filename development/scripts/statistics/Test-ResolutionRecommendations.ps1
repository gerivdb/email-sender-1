# Encoding: UTF-8 with BOM
#Requires -Version 5.1
<#
.SYNOPSIS
    Script de test pour les recommandations de résolution minimale.

.DESCRIPTION
    Ce script teste les fonctionnalités du module ResolutionRecommendations,
    notamment les fonctions de détermination du nombre optimal de bins pour les histogrammes.

.NOTES
    Version:        1.0
    Author:         EMAIL_SENDER_1
    Creation Date:  2023-05-16
#>

# Définir l'encodage de sortie en UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ResolutionRecommendations.psm1"
Import-Module -Name $modulePath -Force

# Fonction pour afficher les résultats de manière formatée
function Format-BinCountResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [int]$SampleSize,

        [Parameter(Mandatory = $true)]
        [string]$DataDistribution,

        [Parameter(Mandatory = $true)]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [int]$BinCount
    )

    Write-Host "=== $TestName ===" -ForegroundColor Cyan
    Write-Host "Taille d'échantillon: $SampleSize" -ForegroundColor White
    Write-Host "Distribution des données: $DataDistribution" -ForegroundColor White
    Write-Host "Méthode: $Method" -ForegroundColor White
    Write-Host "Nombre de bins recommandé: $BinCount" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Cyan
}

function Format-BinWidthResults {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,

        [Parameter(Mandatory = $true)]
        [int]$SampleSize,

        [Parameter(Mandatory = $true)]
        [double]$DataRange,

        [Parameter(Mandatory = $true)]
        [string]$DataDistribution,

        [Parameter(Mandatory = $true)]
        [string]$Method,

        [Parameter(Mandatory = $true)]
        [double]$BinWidth
    )

    Write-Host "=== $TestName ===" -ForegroundColor Cyan
    Write-Host "Taille d'échantillon: $SampleSize" -ForegroundColor White
    Write-Host "Étendue des données: $DataRange" -ForegroundColor White
    Write-Host "Distribution des données: $DataDistribution" -ForegroundColor White
    Write-Host "Méthode: $Method" -ForegroundColor White
    Write-Host "Largeur de bin recommandée: $BinWidth" -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Cyan
}

# Test 1: Nombre de bins pour un petit échantillon normal
$sampleSize1 = 50
$dataDistribution1 = "Normale"
$method1 = "Auto"
$binCount1 = Get-HistogramBinCount -SampleSize $sampleSize1 -DataDistribution $dataDistribution1 -Method $method1
Format-BinCountResults -TestName "Test 1: Petit échantillon normal" -SampleSize $sampleSize1 -DataDistribution $dataDistribution1 -Method $method1 -BinCount $binCount1

# Test 2: Nombre de bins pour un échantillon moyen asymétrique
$sampleSize2 = 200
$dataDistribution2 = "Asymétrique"
$method2 = "Auto"
$iqr2 = 15.5
$binCount2 = Get-HistogramBinCount -SampleSize $sampleSize2 -DataDistribution $dataDistribution2 -Method $method2 -IQR $iqr2
Format-BinCountResults -TestName "Test 2: Échantillon moyen asymétrique" -SampleSize $sampleSize2 -DataDistribution $dataDistribution2 -Method $method2 -BinCount $binCount2

# Test 3: Nombre de bins pour un grand échantillon multimodal
$sampleSize3 = 800
$dataDistribution3 = "Multimodale"
$method3 = "Auto"
$iqr3 = 25.2
$binCount3 = Get-HistogramBinCount -SampleSize $sampleSize3 -DataDistribution $dataDistribution3 -Method $method3 -IQR $iqr3
Format-BinCountResults -TestName "Test 3: Grand échantillon multimodal" -SampleSize $sampleSize3 -DataDistribution $dataDistribution3 -Method $method3 -BinCount $binCount3

# Test 4: Nombre de bins pour un très petit échantillon
$sampleSize4 = 15
$dataDistribution4 = "Inconnue"
$method4 = "Auto"
$binCount4 = Get-HistogramBinCount -SampleSize $sampleSize4 -DataDistribution $dataDistribution4 -Method $method4
Format-BinCountResults -TestName "Test 4: Très petit échantillon" -SampleSize $sampleSize4 -DataDistribution $dataDistribution4 -Method $method4 -BinCount $binCount4

# Test 5: Nombre de bins pour un très grand échantillon
$sampleSize5 = 5000
$dataDistribution5 = "Normale"
$method5 = "Auto"
$standardDeviation5 = 12.3
$binCount5 = Get-HistogramBinCount -SampleSize $sampleSize5 -DataDistribution $dataDistribution5 -Method $method5 -StandardDeviation $standardDeviation5
Format-BinCountResults -TestName "Test 5: Très grand échantillon" -SampleSize $sampleSize5 -DataDistribution $dataDistribution5 -Method $method5 -BinCount $binCount5

# Test 6: Nombre de bins avec méthode spécifique (Sturges)
$sampleSize6 = 100
$dataDistribution6 = "Normale"
$method6 = "Sturges"
$binCount6 = Get-HistogramBinCount -SampleSize $sampleSize6 -DataDistribution $dataDistribution6 -Method $method6
Format-BinCountResults -TestName "Test 6: Méthode de Sturges" -SampleSize $sampleSize6 -DataDistribution $dataDistribution6 -Method $method6 -BinCount $binCount6

# Test 7: Nombre de bins avec méthode spécifique (Scott)
$sampleSize7 = 300
$dataDistribution7 = "Normale"
$method7 = "Scott"
$standardDeviation7 = 8.7
$binCount7 = Get-HistogramBinCount -SampleSize $sampleSize7 -DataDistribution $dataDistribution7 -Method $method7 -StandardDeviation $standardDeviation7
Format-BinCountResults -TestName "Test 7: Méthode de Scott" -SampleSize $sampleSize7 -DataDistribution $dataDistribution7 -Method $method7 -BinCount $binCount7

# Test 8: Nombre de bins avec méthode spécifique (Freedman-Diaconis)
$sampleSize8 = 500
$dataDistribution8 = "Queue lourde"
$method8 = "Freedman-Diaconis"
$iqr8 = 18.9
$binCount8 = Get-HistogramBinCount -SampleSize $sampleSize8 -DataDistribution $dataDistribution8 -Method $method8 -IQR $iqr8
Format-BinCountResults -TestName "Test 8: Méthode de Freedman-Diaconis" -SampleSize $sampleSize8 -DataDistribution $dataDistribution8 -Method $method8 -BinCount $binCount8

# Test 9: Nombre de bins avec méthode spécifique (Rice)
$sampleSize9 = 150
$dataDistribution9 = "Inconnue"
$method9 = "Rice"
$binCount9 = Get-HistogramBinCount -SampleSize $sampleSize9 -DataDistribution $dataDistribution9 -Method $method9
Format-BinCountResults -TestName "Test 9: Méthode de Rice" -SampleSize $sampleSize9 -DataDistribution $dataDistribution9 -Method $method9 -BinCount $binCount9

# Test 10: Nombre de bins avec méthode spécifique (Square-root)
$sampleSize10 = 400
$dataDistribution10 = "Uniforme"
$method10 = "Square-root"
$binCount10 = Get-HistogramBinCount -SampleSize $sampleSize10 -DataDistribution $dataDistribution10 -Method $method10
Format-BinCountResults -TestName "Test 10: Méthode de la racine carrée" -SampleSize $sampleSize10 -DataDistribution $dataDistribution10 -Method $method10 -BinCount $binCount10

# Test 11: Largeur de bin pour un petit échantillon
$sampleSize11 = 50
$dataRange11 = 100
$dataDistribution11 = "Normale"
$method11 = "Auto"
$binWidth11 = Get-HistogramBinWidth -SampleSize $sampleSize11 -DataRange $dataRange11 -DataDistribution $dataDistribution11 -Method $method11
Format-BinWidthResults -TestName "Test 11: Largeur de bin pour petit échantillon" -SampleSize $sampleSize11 -DataRange $dataRange11 -DataDistribution $dataDistribution11 -Method $method11 -BinWidth $binWidth11

# Test 12: Largeur de bin pour un grand échantillon
$sampleSize12 = 1000
$dataRange12 = 200
$dataDistribution12 = "Asymétrique"
$method12 = "Auto"
$iqr12 = 30.5
$binWidth12 = Get-HistogramBinWidth -SampleSize $sampleSize12 -DataRange $dataRange12 -DataDistribution $dataDistribution12 -Method $method12 -IQR $iqr12
Format-BinWidthResults -TestName "Test 12: Largeur de bin pour grand échantillon" -SampleSize $sampleSize12 -DataRange $dataRange12 -DataDistribution $dataDistribution12 -Method $method12 -BinWidth $binWidth12

# Test 13: Largeur de bin avec nombre de bins spécifié
$sampleSize13 = 500
$dataRange13 = 150
$dataDistribution13 = "Normale"
$binCount13 = 20
$binWidth13 = Get-HistogramBinWidth -SampleSize $sampleSize13 -DataRange $dataRange13 -DataDistribution $dataDistribution13 -BinCount $binCount13
Format-BinWidthResults -TestName "Test 13: Largeur de bin avec nombre de bins spécifié" -SampleSize $sampleSize13 -DataRange $dataRange13 -DataDistribution $dataDistribution13 -Method "Auto" -BinWidth $binWidth13

# Test 14: Recommandations de largeur de bin optimale pour une distribution normale
Write-Host "`n=== Test 14: Recommandations de largeur de bin optimale pour une distribution normale ===" -ForegroundColor Magenta
$normalRecommendation = Get-OptimalBinWidthRecommendation -DataDistribution "Normale" -SampleSize 200
Write-Host "Distribution: $($normalRecommendation.Distribution)" -ForegroundColor White
Write-Host "Description: $($normalRecommendation.Description)" -ForegroundColor White
Write-Host "Taille d'échantillon: $($normalRecommendation.SampleSize) (Catégorie: $($normalRecommendation.SizeCategory))" -ForegroundColor White
Write-Host "Méthode optimale: $($normalRecommendation.OptimalMethod)" -ForegroundColor White
Write-Host "Formule: $($normalRecommendation.Formula)" -ForegroundColor White
Write-Host "Recommandation: $($normalRecommendation.Recommendation)" -ForegroundColor Green
Write-Host "`nConsidérations spéciales:" -ForegroundColor Yellow
foreach ($consideration in $normalRecommendation.SpecialConsiderations) {
    Write-Host "- $consideration" -ForegroundColor White
}

# Test 15: Recommandations de largeur de bin optimale pour une distribution asymétrique
Write-Host "`n=== Test 15: Recommandations de largeur de bin optimale pour une distribution asymétrique ===" -ForegroundColor Magenta
$skewedRecommendation = Get-OptimalBinWidthRecommendation -DataDistribution "Asymétrique" -SampleSize 500
Write-Host "Distribution: $($skewedRecommendation.Distribution)" -ForegroundColor White
Write-Host "Description: $($skewedRecommendation.Description)" -ForegroundColor White
Write-Host "Taille d'échantillon: $($skewedRecommendation.SampleSize) (Catégorie: $($skewedRecommendation.SizeCategory))" -ForegroundColor White
Write-Host "Méthode optimale: $($skewedRecommendation.OptimalMethod)" -ForegroundColor White
Write-Host "Formule: $($skewedRecommendation.Formula)" -ForegroundColor White
Write-Host "Recommandation: $($skewedRecommendation.Recommendation)" -ForegroundColor Green
Write-Host "`nConsidérations spéciales:" -ForegroundColor Yellow
foreach ($consideration in $skewedRecommendation.SpecialConsiderations) {
    Write-Host "- $consideration" -ForegroundColor White
}

# Test 16: Rapport de recommandations de largeur de bin au format texte
Write-Host "`n=== Test 16: Rapport de recommandations de largeur de bin au format texte ===" -ForegroundColor Magenta
$textReport = Get-BinWidthRecommendationReport -SampleSize 300 -Format "Text"
Write-Host $textReport -ForegroundColor White

# Test 17: Rapport de recommandations de largeur de bin au format HTML
Write-Host "`n=== Test 17: Rapport de recommandations de largeur de bin au format HTML ===" -ForegroundColor Magenta
$htmlReport = Get-BinWidthRecommendationReport -SampleSize 300 -Format "HTML"
$htmlFilePath = Join-Path -Path $PSScriptRoot -ChildPath "BinWidthRecommendationReport.html"
Set-Content -Path $htmlFilePath -Value $htmlReport -Encoding UTF8
Write-Host "Le rapport au format HTML a été sauvegardé dans le fichier: $htmlFilePath" -ForegroundColor Green

# Test 18: Densité de points optimale pour un petit échantillon
Write-Host "`n=== Test 18: Densité de points optimale pour un petit échantillon ===" -ForegroundColor Magenta
$smallSampleDensity = Get-ScatterPlotPointDensity -SampleSize 50 -PlotSize "Moyen (500x500)" -DPI "Moyenne (150 DPI)" -DataDistribution "Normale"
Write-Host "Taille d'échantillon: $($smallSampleDensity.SampleSize) (Catégorie: $($smallSampleDensity.SizeCategory))" -ForegroundColor White
Write-Host "Taille du graphique: $($smallSampleDensity.PlotSize)" -ForegroundColor White
Write-Host "Dimensions: $($smallSampleDensity.PlotDimensions.WidthPixels)x$($smallSampleDensity.PlotDimensions.HeightPixels) pixels, $([Math]::Round($smallSampleDensity.PlotDimensions.AreaSquareInches, 2)) pouces carrés" -ForegroundColor White
Write-Host "Résolution: $($smallSampleDensity.DPI) ($($smallSampleDensity.DPIValue) DPI)" -ForegroundColor White
Write-Host "Distribution: $($smallSampleDensity.DataDistribution) (Facteur: $($smallSampleDensity.DistributionFactor))" -ForegroundColor White
Write-Host "Densité optimale: $($smallSampleDensity.OptimalDensityPerSquareInch) points/pouce²" -ForegroundColor White
Write-Host "Nombre de points optimal: $($smallSampleDensity.OptimalPointCount)" -ForegroundColor White
Write-Host "Nombre de points recommandé: $($smallSampleDensity.RecommendedPointCount) ($($smallSampleDensity.SamplePercentage)% de l'échantillon)" -ForegroundColor Green
Write-Host "Densité finale: $($smallSampleDensity.FinalDensity) points/pouce²" -ForegroundColor Green
Write-Host "Échantillonnage requis: $($smallSampleDensity.SamplingRequired)" -ForegroundColor White
Write-Host "Stratégie d'échantillonnage: $($smallSampleDensity.SamplingStrategy)" -ForegroundColor White
Write-Host "Stratégie anti-chevauchement: $($smallSampleDensity.OverlapStrategy)" -ForegroundColor White
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $smallSampleDensity.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 19: Densité de points optimale pour un grand échantillon
Write-Host "`n=== Test 19: Densité de points optimale pour un grand échantillon ===" -ForegroundColor Magenta
$largeSampleDensity = Get-ScatterPlotPointDensity -SampleSize 5000 -PlotSize "Grand (800x800)" -DPI "Haute (300 DPI)" -DataDistribution "Groupée"
Write-Host "Taille d'échantillon: $($largeSampleDensity.SampleSize) (Catégorie: $($largeSampleDensity.SizeCategory))" -ForegroundColor White
Write-Host "Taille du graphique: $($largeSampleDensity.PlotSize)" -ForegroundColor White
Write-Host "Dimensions: $($largeSampleDensity.PlotDimensions.WidthPixels)x$($largeSampleDensity.PlotDimensions.HeightPixels) pixels, $([Math]::Round($largeSampleDensity.PlotDimensions.AreaSquareInches, 2)) pouces carrés" -ForegroundColor White
Write-Host "Résolution: $($largeSampleDensity.DPI) ($($largeSampleDensity.DPIValue) DPI)" -ForegroundColor White
Write-Host "Distribution: $($largeSampleDensity.DataDistribution) (Facteur: $($largeSampleDensity.DistributionFactor))" -ForegroundColor White
Write-Host "Densité optimale: $($largeSampleDensity.OptimalDensityPerSquareInch) points/pouce²" -ForegroundColor White
Write-Host "Nombre de points optimal: $($largeSampleDensity.OptimalPointCount)" -ForegroundColor White
Write-Host "Nombre de points recommandé: $($largeSampleDensity.RecommendedPointCount) ($($largeSampleDensity.SamplePercentage)% de l'échantillon)" -ForegroundColor Green
Write-Host "Densité finale: $($largeSampleDensity.FinalDensity) points/pouce²" -ForegroundColor Green
Write-Host "Échantillonnage requis: $($largeSampleDensity.SamplingRequired)" -ForegroundColor White
Write-Host "Stratégie d'échantillonnage: $($largeSampleDensity.SamplingStrategy)" -ForegroundColor White
Write-Host "Stratégie anti-chevauchement: $($largeSampleDensity.OverlapStrategy)" -ForegroundColor White
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $largeSampleDensity.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 20: Rapport de densité de points au format texte
Write-Host "`n=== Test 20: Rapport de densité de points au format texte ===" -ForegroundColor Magenta
$densityReport = Get-ScatterPlotDensityReport -PlotSize "Moyen (500x500)" -DPI "Moyenne (150 DPI)" -DataDistribution "Normale" -Format "Text"
Write-Host $densityReport -ForegroundColor White

# Test 21: Rapport de densité de points au format HTML
Write-Host "`n=== Test 21: Rapport de densité de points au format HTML ===" -ForegroundColor Magenta
$htmlDensityReport = Get-ScatterPlotDensityReport -PlotSize "Grand (800x800)" -DPI "Haute (300 DPI)" -DataDistribution "Dispersée" -Format "HTML"
$htmlDensityFilePath = Join-Path -Path $PSScriptRoot -ChildPath "ScatterPlotDensityReport.html"
Set-Content -Path $htmlDensityFilePath -Value $htmlDensityReport -Encoding UTF8
Write-Host "Le rapport au format HTML a été sauvegardé dans le fichier: $htmlDensityFilePath" -ForegroundColor Green

# Test 22: Paramètres de jittering pour un petit échantillon
Write-Host "`n=== Test 22: Paramètres de jittering pour un petit échantillon ===" -ForegroundColor Magenta
$smallSampleJitter = Get-JitteringParameters -SampleSize 50 -DataDistribution "Normale" -PlotType "Nuage de points standard" -DataRange @(100, 50)
Write-Host "Taille d'échantillon: $($smallSampleJitter.SampleSize) (Catégorie: $($smallSampleJitter.SizeCategory))" -ForegroundColor White
Write-Host "Type de distribution: $($smallSampleJitter.DataDistribution)" -ForegroundColor White
Write-Host "Type de graphique: $($smallSampleJitter.PlotType)" -ForegroundColor White
Write-Host "Étendue des données: X=$($smallSampleJitter.DataRange[0]), Y=$($smallSampleJitter.DataRange[1])" -ForegroundColor White
Write-Host "Densité de points: $([Math]::Round($smallSampleJitter.PointDensity, 4)) pts/px² (Catégorie: $($smallSampleJitter.DensityCategory))" -ForegroundColor White
Write-Host "Distribution de jittering: $($smallSampleJitter.JitterDistribution)" -ForegroundColor White
Write-Host "Directions de jittering: $($smallSampleJitter.JitterDirections)" -ForegroundColor White
Write-Host "Amplitude de base: $($smallSampleJitter.BaseJitterAmplitude)%" -ForegroundColor White
Write-Host "Facteur d'ajustement: $($smallSampleJitter.DistributionFactor)" -ForegroundColor White
Write-Host "Amplitude finale: $($smallSampleJitter.FinalJitterAmplitude)%" -ForegroundColor Green
Write-Host "Jitter X: $([Math]::Round($smallSampleJitter.JitterX, 2))" -ForegroundColor Green
Write-Host "Jitter Y: $([Math]::Round($smallSampleJitter.JitterY, 2))" -ForegroundColor Green
Write-Host "Stratégie: $($smallSampleJitter.JitterStrategy)" -ForegroundColor White
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $smallSampleJitter.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 23: Paramètres de jittering pour un grand échantillon
Write-Host "`n=== Test 23: Paramètres de jittering pour un grand échantillon ===" -ForegroundColor Magenta
$largeSampleJitter = Get-JitteringParameters -SampleSize 2000 -DataDistribution "Groupée" -PlotType "Nuage de points catégoriel" -DataRange @(50, 200)
Write-Host "Taille d'échantillon: $($largeSampleJitter.SampleSize) (Catégorie: $($largeSampleJitter.SizeCategory))" -ForegroundColor White
Write-Host "Type de distribution: $($largeSampleJitter.DataDistribution)" -ForegroundColor White
Write-Host "Type de graphique: $($largeSampleJitter.PlotType)" -ForegroundColor White
Write-Host "Étendue des données: X=$($largeSampleJitter.DataRange[0]), Y=$($largeSampleJitter.DataRange[1])" -ForegroundColor White
Write-Host "Densité de points: $([Math]::Round($largeSampleJitter.PointDensity, 4)) pts/px² (Catégorie: $($largeSampleJitter.DensityCategory))" -ForegroundColor White
Write-Host "Distribution de jittering: $($largeSampleJitter.JitterDistribution)" -ForegroundColor White
Write-Host "Directions de jittering: $($largeSampleJitter.JitterDirections)" -ForegroundColor White
Write-Host "Amplitude de base: $($largeSampleJitter.BaseJitterAmplitude)%" -ForegroundColor White
Write-Host "Facteur d'ajustement: $($largeSampleJitter.DistributionFactor)" -ForegroundColor White
Write-Host "Amplitude finale: $($largeSampleJitter.FinalJitterAmplitude)%" -ForegroundColor Green
Write-Host "Jitter X: $([Math]::Round($largeSampleJitter.JitterX, 2))" -ForegroundColor Green
Write-Host "Jitter Y: $([Math]::Round($largeSampleJitter.JitterY, 2))" -ForegroundColor Green
Write-Host "Stratégie: $($largeSampleJitter.JitterStrategy)" -ForegroundColor White
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $largeSampleJitter.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 24: Rapport de recommandations de jittering au format texte
Write-Host "`n=== Test 24: Rapport de recommandations de jittering au format texte ===" -ForegroundColor Magenta
$jitterReport = Get-JitteringRecommendationReport -DataDistribution "Normale" -PlotType "Nuage de points standard" -DataRange @(100, 100) -Format "Text"
Write-Host $jitterReport -ForegroundColor White

# Test 25: Rapport de recommandations de jittering au format HTML
Write-Host "`n=== Test 25: Rapport de recommandations de jittering au format HTML ===" -ForegroundColor Magenta
$htmlJitterReport = Get-JitteringRecommendationReport -DataDistribution "Asymétrique" -PlotType "Nuage de points standard" -DataRange @(200, 150) -Format "HTML"
$htmlJitterFilePath = Join-Path -Path $PSScriptRoot -ChildPath "JitteringRecommendationReport.html"
Set-Content -Path $htmlJitterFilePath -Value $htmlJitterReport -Encoding UTF8
Write-Host "Le rapport au format HTML a été sauvegardé dans le fichier: $htmlJitterFilePath" -ForegroundColor Green

# Test 26: Largeur minimale des boîtes pour un petit nombre de groupes
Write-Host "`n=== Test 26: Largeur minimale des boîtes pour un petit nombre de groupes ===" -ForegroundColor Magenta
$fewGroupsBoxWidth = Get-BoxplotMinWidth -ScreenSize "Moyen (1280x720)" -GroupCount 3 -DataDistribution "Normale"
Write-Host "Taille d'écran: $($fewGroupsBoxWidth.ScreenSize)" -ForegroundColor White
Write-Host "Nombre de groupes: $($fewGroupsBoxWidth.GroupCount) (Catégorie: $($fewGroupsBoxWidth.GroupCategory))" -ForegroundColor White
Write-Host "Type de distribution: $($fewGroupsBoxWidth.DataDistribution) (Facteur: $($fewGroupsBoxWidth.DistributionFactor))" -ForegroundColor White
Write-Host "Largeur du graphique: $($fewGroupsBoxWidth.PlotWidth) px" -ForegroundColor White
Write-Host "Largeur minimale par taille d'écran: $($fewGroupsBoxWidth.MinBoxWidthByScreen) px" -ForegroundColor White
Write-Host "Pourcentage minimal de largeur: $($fewGroupsBoxWidth.MinWidthPercentage)%" -ForegroundColor White
Write-Host "Largeur minimale par pourcentage: $($fewGroupsBoxWidth.MinBoxWidthByPercentage) px" -ForegroundColor White
Write-Host "Largeur minimale de base: $($fewGroupsBoxWidth.BaseMinBoxWidth) px" -ForegroundColor White
Write-Host "Largeur minimale ajustée: $($fewGroupsBoxWidth.AdjustedMinBoxWidth) px" -ForegroundColor Green
Write-Host "Largeur minimale des moustaches: $($fewGroupsBoxWidth.MinWhiskerWidth) px" -ForegroundColor Green
Write-Host "Espacement recommandé: $($fewGroupsBoxWidth.RecommendedSpacing) px" -ForegroundColor Green
Write-Host "Largeur totale: $($fewGroupsBoxWidth.TotalWidth) px" -ForegroundColor White
Write-Host "Dépasse la largeur du graphique: $($fewGroupsBoxWidth.ExceedsPlotWidth)" -ForegroundColor White
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $fewGroupsBoxWidth.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 27: Largeur minimale des boîtes pour un grand nombre de groupes
Write-Host "`n=== Test 27: Largeur minimale des boîtes pour un grand nombre de groupes ===" -ForegroundColor Magenta
$manyGroupsBoxWidth = Get-BoxplotMinWidth -ScreenSize "Grand (1920x1080)" -GroupCount 20 -DataDistribution "Asymétrique" -PlotWidth 1600
Write-Host "Taille d'écran: $($manyGroupsBoxWidth.ScreenSize)" -ForegroundColor White
Write-Host "Nombre de groupes: $($manyGroupsBoxWidth.GroupCount) (Catégorie: $($manyGroupsBoxWidth.GroupCategory))" -ForegroundColor White
Write-Host "Type de distribution: $($manyGroupsBoxWidth.DataDistribution) (Facteur: $($manyGroupsBoxWidth.DistributionFactor))" -ForegroundColor White
Write-Host "Largeur du graphique: $($manyGroupsBoxWidth.PlotWidth) px" -ForegroundColor White
Write-Host "Largeur minimale par taille d'écran: $($manyGroupsBoxWidth.MinBoxWidthByScreen) px" -ForegroundColor White
Write-Host "Pourcentage minimal de largeur: $($manyGroupsBoxWidth.MinWidthPercentage)%" -ForegroundColor White
Write-Host "Largeur minimale par pourcentage: $($manyGroupsBoxWidth.MinBoxWidthByPercentage) px" -ForegroundColor White
Write-Host "Largeur minimale de base: $($manyGroupsBoxWidth.BaseMinBoxWidth) px" -ForegroundColor White
Write-Host "Largeur minimale ajustée: $($manyGroupsBoxWidth.AdjustedMinBoxWidth) px" -ForegroundColor Green
Write-Host "Largeur minimale des moustaches: $($manyGroupsBoxWidth.MinWhiskerWidth) px" -ForegroundColor Green
Write-Host "Espacement recommandé: $($manyGroupsBoxWidth.RecommendedSpacing) px" -ForegroundColor Green
Write-Host "Largeur totale: $($manyGroupsBoxWidth.TotalWidth) px" -ForegroundColor White
Write-Host "Dépasse la largeur du graphique: $($manyGroupsBoxWidth.ExceedsPlotWidth)" -ForegroundColor White
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $manyGroupsBoxWidth.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 28: Rapport de largeur minimale des boîtes au format texte
Write-Host "`n=== Test 28: Rapport de largeur minimale des boîtes au format texte ===" -ForegroundColor Magenta
$boxWidthReport = Get-BoxplotWidthReport -ScreenSize "Moyen (1280x720)" -DataDistribution "Normale" -Format "Text"
Write-Host $boxWidthReport -ForegroundColor White

# Test 29: Rapport de largeur minimale des boîtes au format HTML
Write-Host "`n=== Test 29: Rapport de largeur minimale des boîtes au format HTML ===" -ForegroundColor Magenta
$htmlBoxWidthReport = Get-BoxplotWidthReport -ScreenSize "Grand (1920x1080)" -DataDistribution "Multimodale" -Format "HTML"
$htmlBoxWidthFilePath = Join-Path -Path $PSScriptRoot -ChildPath "BoxplotWidthReport.html"
Set-Content -Path $htmlBoxWidthFilePath -Value $htmlBoxWidthReport -Encoding UTF8
Write-Host "Le rapport au format HTML a été sauvegardé dans le fichier: $htmlBoxWidthFilePath" -ForegroundColor Green

# Test 30: Espacement entre les boîtes pour un petit nombre de groupes
Write-Host "`n=== Test 30: Espacement entre les boîtes pour un petit nombre de groupes ===" -ForegroundColor Magenta
$fewGroupsSpacing = Get-BoxplotSpacing -GroupCount 3 -BoxWidth 100 -ComparisonType "Standard"
Write-Host "Nombre de groupes: $($fewGroupsSpacing.GroupCount) (Catégorie: $($fewGroupsSpacing.GroupCategory))" -ForegroundColor White
Write-Host "Largeur des boîtes: $($fewGroupsSpacing.BoxWidth) px" -ForegroundColor White
Write-Host "Type de comparaison: $($fewGroupsSpacing.ComparisonType)" -ForegroundColor White
Write-Host "Ratio d'espacement: $($fewGroupsSpacing.SpacingRatio)" -ForegroundColor White
Write-Host "Espacement recommandé: $($fewGroupsSpacing.RecommendedSpacing) px" -ForegroundColor Green
Write-Host "Largeur du graphique: $($fewGroupsSpacing.PlotWidth) px" -ForegroundColor White
Write-Host "Largeur totale: $($fewGroupsSpacing.TotalWidth) px" -ForegroundColor White
Write-Host "Dépasse la largeur du graphique: $($fewGroupsSpacing.ExceedsPlotWidth)" -ForegroundColor White
if ($fewGroupsSpacing.ExceedsPlotWidth) {
    Write-Host "Espacement maximal possible: $($fewGroupsSpacing.MaxPossibleSpacing) px" -ForegroundColor Yellow
    Write-Host "Espacement ajusté: $($fewGroupsSpacing.AdjustedSpacing) px" -ForegroundColor Yellow
    Write-Host "Largeur totale ajustée: $($fewGroupsSpacing.AdjustedTotalWidth) px" -ForegroundColor Yellow
}
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $fewGroupsSpacing.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 31: Espacement entre les boîtes pour un grand nombre de groupes
Write-Host "`n=== Test 31: Espacement entre les boîtes pour un grand nombre de groupes ===" -ForegroundColor Magenta
$manyGroupsSpacing = Get-BoxplotSpacing -GroupCount 15 -BoxWidth 80 -ComparisonType "Compact" -PlotWidth 1000
Write-Host "Nombre de groupes: $($manyGroupsSpacing.GroupCount) (Catégorie: $($manyGroupsSpacing.GroupCategory))" -ForegroundColor White
Write-Host "Largeur des boîtes: $($manyGroupsSpacing.BoxWidth) px" -ForegroundColor White
Write-Host "Type de comparaison: $($manyGroupsSpacing.ComparisonType)" -ForegroundColor White
Write-Host "Ratio d'espacement: $($manyGroupsSpacing.SpacingRatio)" -ForegroundColor White
Write-Host "Espacement recommandé: $($manyGroupsSpacing.RecommendedSpacing) px" -ForegroundColor Green
Write-Host "Largeur du graphique: $($manyGroupsSpacing.PlotWidth) px" -ForegroundColor White
Write-Host "Largeur totale: $($manyGroupsSpacing.TotalWidth) px" -ForegroundColor White
Write-Host "Dépasse la largeur du graphique: $($manyGroupsSpacing.ExceedsPlotWidth)" -ForegroundColor White
if ($manyGroupsSpacing.ExceedsPlotWidth) {
    Write-Host "Espacement maximal possible: $($manyGroupsSpacing.MaxPossibleSpacing) px" -ForegroundColor Yellow
    Write-Host "Espacement ajusté: $($manyGroupsSpacing.AdjustedSpacing) px" -ForegroundColor Yellow
    Write-Host "Largeur totale ajustée: $($manyGroupsSpacing.AdjustedTotalWidth) px" -ForegroundColor Yellow
}
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $manyGroupsSpacing.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 32: Espacement entre les boîtes pour un type de comparaison précis
Write-Host "`n=== Test 32: Espacement entre les boîtes pour un type de comparaison précis ===" -ForegroundColor Magenta
$preciseSpacing = Get-BoxplotSpacing -GroupCount 5 -BoxWidth 120 -ComparisonType "Précis" -PlotWidth 1200
Write-Host "Nombre de groupes: $($preciseSpacing.GroupCount) (Catégorie: $($preciseSpacing.GroupCategory))" -ForegroundColor White
Write-Host "Largeur des boîtes: $($preciseSpacing.BoxWidth) px" -ForegroundColor White
Write-Host "Type de comparaison: $($preciseSpacing.ComparisonType)" -ForegroundColor White
Write-Host "Ratio d'espacement: $($preciseSpacing.SpacingRatio)" -ForegroundColor White
Write-Host "Espacement recommandé: $($preciseSpacing.RecommendedSpacing) px" -ForegroundColor Green
Write-Host "Largeur du graphique: $($preciseSpacing.PlotWidth) px" -ForegroundColor White
Write-Host "Largeur totale: $($preciseSpacing.TotalWidth) px" -ForegroundColor White
Write-Host "Dépasse la largeur du graphique: $($preciseSpacing.ExceedsPlotWidth)" -ForegroundColor White
if ($preciseSpacing.ExceedsPlotWidth) {
    Write-Host "Espacement maximal possible: $($preciseSpacing.MaxPossibleSpacing) px" -ForegroundColor Yellow
    Write-Host "Espacement ajusté: $($preciseSpacing.AdjustedSpacing) px" -ForegroundColor Yellow
    Write-Host "Largeur totale ajustée: $($preciseSpacing.AdjustedTotalWidth) px" -ForegroundColor Yellow
}
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $preciseSpacing.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 33: Rapport d'espacement entre les boîtes au format texte
Write-Host "`n=== Test 33: Rapport d'espacement entre les boîtes au format texte ===" -ForegroundColor Magenta
$spacingReport = Get-BoxplotSpacingReport -GroupCount 8 -BoxWidth 90 -Format "Text"
Write-Host $spacingReport -ForegroundColor White

# Test 34: Rapport d'espacement entre les boîtes au format HTML
Write-Host "`n=== Test 34: Rapport d'espacement entre les boîtes au format HTML ===" -ForegroundColor Magenta
$htmlSpacingReport = Get-BoxplotSpacingReport -GroupCount 10 -BoxWidth 80 -PlotWidth 1200 -Format "HTML"
$htmlSpacingFilePath = Join-Path -Path $PSScriptRoot -ChildPath "BoxplotSpacingReport.html"
Set-Content -Path $htmlSpacingFilePath -Value $htmlSpacingReport -Encoding UTF8
Write-Host "Le rapport au format HTML a été sauvegardé dans le fichier: $htmlSpacingFilePath" -ForegroundColor Green

# Test 35: Seuil de hauteur relative pour l'identification des modes dans une distribution normale
Write-Host "`n=== Test 35: Seuil de hauteur relative pour l'identification des modes dans une distribution normale ===" -ForegroundColor Magenta
$normalModeThreshold = Get-ModeHeightThreshold -SampleSize 200 -DataDistribution "Normale" -NoiseLevel "Faible" -SmoothingMethod "Noyau gaussien" -Application "Analyse statistique"
Write-Host "Taille d'échantillon: $($normalModeThreshold.SampleSize) (Catégorie: $($normalModeThreshold.SizeCategory))" -ForegroundColor White
Write-Host "Type de distribution: $($normalModeThreshold.DataDistribution) (Facteur: $($normalModeThreshold.DistributionFactor))" -ForegroundColor White
Write-Host "Niveau de bruit: $($normalModeThreshold.NoiseLevel)" -ForegroundColor White
Write-Host "Méthode de lissage: $($normalModeThreshold.SmoothingMethod)" -ForegroundColor White
Write-Host "Application: $($normalModeThreshold.Application)" -ForegroundColor White
Write-Host "Seuil de base par taille d'échantillon: $($normalModeThreshold.BaseThresholdCategory) ($($normalModeThreshold.BaseThreshold))" -ForegroundColor White
Write-Host "Seuil par niveau de bruit: $($normalModeThreshold.NoiseThresholdCategory) ($($normalModeThreshold.NoiseThreshold))" -ForegroundColor White
Write-Host "Seuil par méthode de lissage: $($normalModeThreshold.SmoothingThresholdCategory) ($($normalModeThreshold.SmoothingThreshold))" -ForegroundColor White
Write-Host "Seuil par application: $($normalModeThreshold.ApplicationThresholdCategory) ($($normalModeThreshold.ApplicationThreshold))" -ForegroundColor White
Write-Host "Seuil final: $($normalModeThreshold.FinalThreshold) ($($normalModeThreshold.FinalThresholdCategory))" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $normalModeThreshold.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 36: Seuil de hauteur relative pour l'identification des modes dans une distribution multimodale
Write-Host "`n=== Test 36: Seuil de hauteur relative pour l'identification des modes dans une distribution multimodale ===" -ForegroundColor Magenta
$multimodalModeThreshold = Get-ModeHeightThreshold -SampleSize 500 -DataDistribution "Multimodale" -NoiseLevel "Modéré" -SmoothingMethod "Moyenne mobile" -Application "Exploration de données"
Write-Host "Taille d'échantillon: $($multimodalModeThreshold.SampleSize) (Catégorie: $($multimodalModeThreshold.SizeCategory))" -ForegroundColor White
Write-Host "Type de distribution: $($multimodalModeThreshold.DataDistribution) (Facteur: $($multimodalModeThreshold.DistributionFactor))" -ForegroundColor White
Write-Host "Niveau de bruit: $($multimodalModeThreshold.NoiseLevel)" -ForegroundColor White
Write-Host "Méthode de lissage: $($multimodalModeThreshold.SmoothingMethod)" -ForegroundColor White
Write-Host "Application: $($multimodalModeThreshold.Application)" -ForegroundColor White
Write-Host "Seuil de base par taille d'échantillon: $($multimodalModeThreshold.BaseThresholdCategory) ($($multimodalModeThreshold.BaseThreshold))" -ForegroundColor White
Write-Host "Seuil par niveau de bruit: $($multimodalModeThreshold.NoiseThresholdCategory) ($($multimodalModeThreshold.NoiseThreshold))" -ForegroundColor White
Write-Host "Seuil par méthode de lissage: $($multimodalModeThreshold.SmoothingThresholdCategory) ($($multimodalModeThreshold.SmoothingThreshold))" -ForegroundColor White
Write-Host "Seuil par application: $($multimodalModeThreshold.ApplicationThresholdCategory) ($($multimodalModeThreshold.ApplicationThreshold))" -ForegroundColor White
Write-Host "Seuil final: $($multimodalModeThreshold.FinalThreshold) ($($multimodalModeThreshold.FinalThresholdCategory))" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $multimodalModeThreshold.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 37: Rapport de seuils de hauteur relative au format texte
Write-Host "`n=== Test 37: Rapport de seuils de hauteur relative au format texte ===" -ForegroundColor Magenta
$modeThresholdReport = Get-ModeHeightThresholdReport -DataDistribution "Asymétrique" -NoiseLevel "Faible" -SmoothingMethod "Spline" -Format "Text"
Write-Host $modeThresholdReport -ForegroundColor White

# Test 38: Rapport de seuils de hauteur relative au format HTML
Write-Host "`n=== Test 38: Rapport de seuils de hauteur relative au format HTML ===" -ForegroundColor Magenta
$htmlModeThresholdReport = Get-ModeHeightThresholdReport -DataDistribution "Queue lourde" -NoiseLevel "Élevé" -SmoothingMethod "Régression locale" -Format "HTML"
$htmlModeThresholdFilePath = Join-Path -Path $PSScriptRoot -ChildPath "ModeHeightThresholdReport.html"
Set-Content -Path $htmlModeThresholdFilePath -Value $htmlModeThresholdReport -Encoding UTF8
Write-Host "Le rapport au format HTML a été sauvegardé dans le fichier: $htmlModeThresholdFilePath" -ForegroundColor Green

# Test 39: Séparation minimale entre les modes dans une distribution normale
Write-Host "`n=== Test 39: Séparation minimale entre les modes dans une distribution normale ===" -ForegroundColor Magenta
$normalModeSeparation = Get-ModeSeparationThreshold -SampleSize 200 -DataDistribution "Normale" -NoiseLevel "Faible" -SmoothingMethod "Noyau gaussien" -Application "Analyse statistique" -StandardDeviation 2.5
Write-Host "Taille d'échantillon: $($normalModeSeparation.SampleSize) (Catégorie: $($normalModeSeparation.SizeCategory))" -ForegroundColor White
Write-Host "Type de distribution: $($normalModeSeparation.DataDistribution) (Facteur: $($normalModeSeparation.DistributionFactor))" -ForegroundColor White
Write-Host "Niveau de bruit: $($normalModeSeparation.NoiseLevel)" -ForegroundColor White
Write-Host "Méthode de lissage: $($normalModeSeparation.SmoothingMethod)" -ForegroundColor White
Write-Host "Application: $($normalModeSeparation.Application)" -ForegroundColor White
Write-Host "Écart-type: $($normalModeSeparation.StandardDeviation)" -ForegroundColor White
Write-Host "Séparation de base par taille d'échantillon: $($normalModeSeparation.BaseSeparationCategory) ($($normalModeSeparation.BaseSeparation))" -ForegroundColor White
Write-Host "Séparation par niveau de bruit: $($normalModeSeparation.NoiseSeparationCategory) ($($normalModeSeparation.NoiseSeparation))" -ForegroundColor White
Write-Host "Séparation par méthode de lissage: $($normalModeSeparation.SmoothingSeparationCategory) ($($normalModeSeparation.SmoothingSeparation))" -ForegroundColor White
Write-Host "Séparation par application: $($normalModeSeparation.ApplicationSeparationCategory) ($($normalModeSeparation.ApplicationSeparation))" -ForegroundColor White
Write-Host "Séparation finale: $($normalModeSeparation.FinalSeparation) écarts-types ($($normalModeSeparation.FinalSeparationCategory))" -ForegroundColor Green
Write-Host "Séparation en unités originales: $($normalModeSeparation.SeparationInOriginalUnits)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $normalModeSeparation.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 40: Séparation minimale entre les modes dans une distribution multimodale
Write-Host "`n=== Test 40: Séparation minimale entre les modes dans une distribution multimodale ===" -ForegroundColor Magenta
$multimodalModeSeparation = Get-ModeSeparationThreshold -SampleSize 500 -DataDistribution "Multimodale" -NoiseLevel "Modéré" -SmoothingMethod "Moyenne mobile" -Application "Exploration de données" -StandardDeviation 1.5
Write-Host "Taille d'échantillon: $($multimodalModeSeparation.SampleSize) (Catégorie: $($multimodalModeSeparation.SizeCategory))" -ForegroundColor White
Write-Host "Type de distribution: $($multimodalModeSeparation.DataDistribution) (Facteur: $($multimodalModeSeparation.DistributionFactor))" -ForegroundColor White
Write-Host "Niveau de bruit: $($multimodalModeSeparation.NoiseLevel)" -ForegroundColor White
Write-Host "Méthode de lissage: $($multimodalModeSeparation.SmoothingMethod)" -ForegroundColor White
Write-Host "Application: $($multimodalModeSeparation.Application)" -ForegroundColor White
Write-Host "Écart-type: $($multimodalModeSeparation.StandardDeviation)" -ForegroundColor White
Write-Host "Séparation de base par taille d'échantillon: $($multimodalModeSeparation.BaseSeparationCategory) ($($multimodalModeSeparation.BaseSeparation))" -ForegroundColor White
Write-Host "Séparation par niveau de bruit: $($multimodalModeSeparation.NoiseSeparationCategory) ($($multimodalModeSeparation.NoiseSeparation))" -ForegroundColor White
Write-Host "Séparation par méthode de lissage: $($multimodalModeSeparation.SmoothingSeparationCategory) ($($multimodalModeSeparation.SmoothingSeparation))" -ForegroundColor White
Write-Host "Séparation par application: $($multimodalModeSeparation.ApplicationSeparationCategory) ($($multimodalModeSeparation.ApplicationSeparation))" -ForegroundColor White
Write-Host "Séparation finale: $($multimodalModeSeparation.FinalSeparation) écarts-types ($($multimodalModeSeparation.FinalSeparationCategory))" -ForegroundColor Green
Write-Host "Séparation en unités originales: $($multimodalModeSeparation.SeparationInOriginalUnits)" -ForegroundColor Green
Write-Host "`nRecommandations:" -ForegroundColor Yellow
foreach ($recommendation in $multimodalModeSeparation.Recommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 41: Rapport de séparation minimale entre les modes au format texte
Write-Host "`n=== Test 41: Rapport de séparation minimale entre les modes au format texte ===" -ForegroundColor Magenta
$modeSeparationReport = Get-ModeSeparationReport -DataDistribution "Asymétrique" -NoiseLevel "Faible" -SmoothingMethod "Spline" -StandardDeviation 1.2 -Format "Text"
Write-Host $modeSeparationReport -ForegroundColor White

# Test 42: Rapport de séparation minimale entre les modes au format HTML
Write-Host "`n=== Test 42: Rapport de séparation minimale entre les modes au format HTML ===" -ForegroundColor Magenta
$htmlModeSeparationReport = Get-ModeSeparationReport -DataDistribution "Queue lourde" -NoiseLevel "Élevé" -SmoothingMethod "Régression locale" -StandardDeviation 2.0 -Format "HTML"
$htmlModeSeparationFilePath = Join-Path -Path $PSScriptRoot -ChildPath "ModeSeparationReport.html"
Set-Content -Path $htmlModeSeparationFilePath -Value $htmlModeSeparationReport -Encoding UTF8
Write-Host "Le rapport au format HTML a été sauvegardé dans le fichier: $htmlModeSeparationFilePath" -ForegroundColor Green

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés." -ForegroundColor Green
Write-Host "Vérifiez les résultats pour vous assurer que les recommandations de résolution sont appropriées." -ForegroundColor Green
Write-Host "Les rapports HTML ont été générés et sauvegardés dans le dossier du script." -ForegroundColor Green

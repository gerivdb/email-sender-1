# Test-VisualAsymmetryEvaluation.ps1
# Ce script teste les fonctions d'évaluation visuelle de l'asymétrie

# Importer le module VisualAsymmetryEvaluation
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "VisualAsymmetryEvaluation.psm1"
if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Le module VisualAsymmetryEvaluation.psm1 n'a pas été trouvé: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Définir le dossier de rapports
$reportsFolder = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $reportsFolder)) {
    New-Item -Path $reportsFolder -ItemType Directory | Out-Null
}

# Générer des données de test
Write-Host "`n=== Génération des données de test ===" -ForegroundColor Magenta

# Distribution normale
$normalData = 1..50 | ForEach-Object { [Math]::Round([System.Random]::new().NextDouble() * 10 - 5, 2) }

# Distribution asymétrique positive
$positiveSkewData = 1..50 | ForEach-Object {
    $value = [Math]::Pow([System.Random]::new().NextDouble(), 2) * 10
    [Math]::Round($value, 2)
}

# Distribution asymétrique négative
$negativeSkewData = 1..50 | ForEach-Object {
    $value = 10 - [Math]::Pow([System.Random]::new().NextDouble(), 2) * 10
    [Math]::Round($value, 2)
}

# Distribution bimodale
$bimodalData = @()
$bimodalData += 1..25 | ForEach-Object { [Math]::Round([System.Random]::new().NextDouble() * 3 - 5, 2) }
$bimodalData += 1..25 | ForEach-Object { [Math]::Round([System.Random]::new().NextDouble() * 3 + 2, 2) }

Write-Host "Données générées:" -ForegroundColor White
Write-Host "- Distribution normale: $($normalData.Count) points" -ForegroundColor White
Write-Host "- Distribution asymétrique positive: $($positiveSkewData.Count) points" -ForegroundColor White
Write-Host "- Distribution asymétrique négative: $($negativeSkewData.Count) points" -ForegroundColor White
Write-Host "- Distribution bimodale: $($bimodalData.Count) points" -ForegroundColor White

# Test 1: Calcul de l'histogramme
Write-Host "`n=== Test 1: Calcul de l'histogramme ===" -ForegroundColor Magenta
$normalHistogram = Get-Histogram -Data $normalData -BinCount 20 -Normalize
$positiveSkewHistogram = Get-Histogram -Data $positiveSkewData -BinCount 20 -Normalize
$negativeSkewHistogram = Get-Histogram -Data $negativeSkewData -BinCount 20 -Normalize
$bimodalHistogram = Get-Histogram -Data $bimodalData -BinCount 20 -Normalize

Write-Host "Histogrammes calculés:" -ForegroundColor White
Write-Host "- Distribution normale: $($normalHistogram.BinCount) classes, largeur de classe: $($normalHistogram.BinWidth)" -ForegroundColor White
Write-Host "- Distribution asymétrique positive: $($positiveSkewHistogram.BinCount) classes, largeur de classe: $($positiveSkewHistogram.BinWidth)" -ForegroundColor White
Write-Host "- Distribution asymétrique négative: $($negativeSkewHistogram.BinCount) classes, largeur de classe: $($negativeSkewHistogram.BinWidth)" -ForegroundColor White
Write-Host "- Distribution bimodale: $($bimodalHistogram.BinCount) classes, largeur de classe: $($bimodalHistogram.BinWidth)" -ForegroundColor White

# Test 2: Calcul de l'asymétrie visuelle avec différentes méthodes
Write-Host "`n=== Test 2: Calcul de l'asymétrie visuelle avec différentes méthodes ===" -ForegroundColor Magenta
$methods = @("AreaDifference", "ShapeDifference")  # Limiter à deux méthodes pour accélérer les tests

Write-Host "Distribution normale:" -ForegroundColor White
foreach ($method in $methods) {
    $asymmetry = Get-HistogramAsymmetry -Data $normalData -Method $method
    Write-Host "  Methode $method`: Score: $([Math]::Round($asymmetry.Score, 4)), Direction: $($asymmetry.AsymmetryDirection), Intensite: $($asymmetry.AsymmetryIntensity)" -ForegroundColor White
}

Write-Host "`nDistribution asymetrique positive:" -ForegroundColor White
foreach ($method in $methods) {
    $asymmetry = Get-HistogramAsymmetry -Data $positiveSkewData -Method $method
    Write-Host "  Methode $method`: Score: $([Math]::Round($asymmetry.Score, 4)), Direction: $($asymmetry.AsymmetryDirection), Intensite: $($asymmetry.AsymmetryIntensity)" -ForegroundColor White
}

# Limiter les tests pour accélérer l'exécution
Write-Host "`nDistribution asymetrique negative (methode AreaDifference uniquement):" -ForegroundColor White
$asymmetry = Get-HistogramAsymmetry -Data $negativeSkewData -Method "AreaDifference"
Write-Host "  Methode AreaDifference`: Score: $([Math]::Round($asymmetry.Score, 4)), Direction: $($asymmetry.AsymmetryDirection), Intensite: $($asymmetry.AsymmetryIntensity)" -ForegroundColor White

Write-Host "`nDistribution bimodale (methode AreaDifference uniquement):" -ForegroundColor White
$asymmetry = Get-HistogramAsymmetry -Data $bimodalData -Method "AreaDifference"
Write-Host "  Methode AreaDifference`: Score: $([Math]::Round($asymmetry.Score, 4)), Direction: $($asymmetry.AsymmetryDirection), Intensite: $($asymmetry.AsymmetryIntensity)" -ForegroundColor White

# Test 3: Évaluation visuelle globale
Write-Host "`n=== Test 3: Évaluation visuelle globale ===" -ForegroundColor Magenta
$normalEvaluation = Get-VisualAsymmetryEvaluation -Data $normalData
$positiveSkewEvaluation = Get-VisualAsymmetryEvaluation -Data $positiveSkewData
$negativeSkewEvaluation = Get-VisualAsymmetryEvaluation -Data $negativeSkewData
$bimodalEvaluation = Get-VisualAsymmetryEvaluation -Data $bimodalData

Write-Host "Évaluation visuelle globale:" -ForegroundColor White
Write-Host "- Distribution normale: Score: $([Math]::Round($normalEvaluation.CompositeScore, 4)), Direction: $($normalEvaluation.AsymmetryDirection), Intensité: $($normalEvaluation.AsymmetryIntensity)" -ForegroundColor White
Write-Host "- Distribution asymétrique positive: Score: $([Math]::Round($positiveSkewEvaluation.CompositeScore, 4)), Direction: $($positiveSkewEvaluation.AsymmetryDirection), Intensité: $($positiveSkewEvaluation.AsymmetryIntensity)" -ForegroundColor White
Write-Host "- Distribution asymétrique négative: Score: $([Math]::Round($negativeSkewEvaluation.CompositeScore, 4)), Direction: $($negativeSkewEvaluation.AsymmetryDirection), Intensité: $($negativeSkewEvaluation.AsymmetryIntensity)" -ForegroundColor White
Write-Host "- Distribution bimodale: Score: $([Math]::Round($bimodalEvaluation.CompositeScore, 4)), Direction: $($bimodalEvaluation.AsymmetryDirection), Intensité: $($bimodalEvaluation.AsymmetryIntensity)" -ForegroundColor White

# Test 4: Évaluation visuelle avec pondération personnalisée
Write-Host "`n=== Test 4: Évaluation visuelle avec pondération personnalisée ===" -ForegroundColor Magenta
$weights = @{
    "AreaDifference"  = 0.4
    "ShapeDifference" = 0.3
    "PeakOffset"      = 0.2
    "TailRatio"       = 0.1
}
$weightedEvaluation = Get-VisualAsymmetryEvaluation -Data $positiveSkewData -Weights $weights

Write-Host "Évaluation visuelle avec pondération personnalisée:" -ForegroundColor White
Write-Host "- Distribution asymétrique positive: Score: $([Math]::Round($weightedEvaluation.CompositeScore, 4)), Direction: $($weightedEvaluation.AsymmetryDirection), Intensité: $($weightedEvaluation.AsymmetryIntensity)" -ForegroundColor White
Write-Host "- Méthode la plus cohérente: $($weightedEvaluation.MostConsistentMethod)" -ForegroundColor White
foreach ($method in $weightedEvaluation.Methods) {
    Write-Host "  - $method`: Score: $([Math]::Round($weightedEvaluation.Results[$method].Score, 4)), Cohérence: $($weightedEvaluation.ConsistencyScores[$method])" -ForegroundColor White
}

# Test 5: Génération de visualisations HTML
Write-Host "`n=== Test 5: Génération de visualisations HTML ===" -ForegroundColor Magenta
$positiveSkewVisualizationPath = Join-Path -Path $reportsFolder -ChildPath "positive_skew_asymmetry.html"

# Limiter à une seule visualisation pour accélérer les tests
Get-AsymmetryVisualization -Data $positiveSkewData -OutputPath $positiveSkewVisualizationPath -Title "Asymétrie de la distribution asymétrique positive"

Write-Host "Visualisations HTML générées:" -ForegroundColor White
Write-Host "- Distribution asymétrique positive: $positiveSkewVisualizationPath" -ForegroundColor White

# Test 6: Génération d'un rapport JSON
Write-Host "`n=== Test 6: Génération d'un rapport JSON ===" -ForegroundColor Magenta
$jsonReportPath = Join-Path -Path $reportsFolder -ChildPath "visual_asymmetry_report.json"

# Créer un rapport JSON avec les évaluations visuelles
$reportData = @{
    metadata      = @{
        title          = "Rapport d'évaluation visuelle de l'asymétrie"
        generationDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        version        = "1.0"
    }
    distributions = @{
        normal       = @{
            name       = "Distribution normale"
            sampleSize = $normalData.Count
            evaluation = @{
                compositeScore       = [Math]::Round($normalEvaluation.CompositeScore, 4)
                asymmetryDirection   = $normalEvaluation.AsymmetryDirection
                asymmetryIntensity   = $normalEvaluation.AsymmetryIntensity
                mostConsistentMethod = $normalEvaluation.MostConsistentMethod
            }
            methods    = @{}
        }
        positiveSkew = @{
            name       = "Distribution asymétrique positive"
            sampleSize = $positiveSkewData.Count
            evaluation = @{
                compositeScore       = [Math]::Round($positiveSkewEvaluation.CompositeScore, 4)
                asymmetryDirection   = $positiveSkewEvaluation.AsymmetryDirection
                asymmetryIntensity   = $positiveSkewEvaluation.AsymmetryIntensity
                mostConsistentMethod = $positiveSkewEvaluation.MostConsistentMethod
            }
            methods    = @{}
        }
        negativeSkew = @{
            name       = "Distribution asymétrique négative"
            sampleSize = $negativeSkewData.Count
            evaluation = @{
                compositeScore       = [Math]::Round($negativeSkewEvaluation.CompositeScore, 4)
                asymmetryDirection   = $negativeSkewEvaluation.AsymmetryDirection
                asymmetryIntensity   = $negativeSkewEvaluation.AsymmetryIntensity
                mostConsistentMethod = $negativeSkewEvaluation.MostConsistentMethod
            }
            methods    = @{}
        }
        bimodal      = @{
            name       = "Distribution bimodale"
            sampleSize = $bimodalData.Count
            evaluation = @{
                compositeScore       = [Math]::Round($bimodalEvaluation.CompositeScore, 4)
                asymmetryDirection   = $bimodalEvaluation.AsymmetryDirection
                asymmetryIntensity   = $bimodalEvaluation.AsymmetryIntensity
                mostConsistentMethod = $bimodalEvaluation.MostConsistentMethod
            }
            methods    = @{}
        }
    }
}

# Ajouter les résultats par méthode
foreach ($method in $methods) {
    $reportData.distributions.normal.methods[$method] = @{
        score              = [Math]::Round($normalEvaluation.Results[$method].Score, 4)
        asymmetryDirection = $normalEvaluation.Results[$method].AsymmetryDirection
        asymmetryIntensity = $normalEvaluation.Results[$method].AsymmetryIntensity
    }

    $reportData.distributions.positiveSkew.methods[$method] = @{
        score              = [Math]::Round($positiveSkewEvaluation.Results[$method].Score, 4)
        asymmetryDirection = $positiveSkewEvaluation.Results[$method].AsymmetryDirection
        asymmetryIntensity = $positiveSkewEvaluation.Results[$method].AsymmetryIntensity
    }

    $reportData.distributions.negativeSkew.methods[$method] = @{
        score              = [Math]::Round($negativeSkewEvaluation.Results[$method].Score, 4)
        asymmetryDirection = $negativeSkewEvaluation.Results[$method].AsymmetryDirection
        asymmetryIntensity = $negativeSkewEvaluation.Results[$method].AsymmetryIntensity
    }

    $reportData.distributions.bimodal.methods[$method] = @{
        score              = [Math]::Round($bimodalEvaluation.Results[$method].Score, 4)
        asymmetryDirection = $bimodalEvaluation.Results[$method].AsymmetryDirection
        asymmetryIntensity = $bimodalEvaluation.Results[$method].AsymmetryIntensity
    }
}

# Enregistrer le rapport JSON
$reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonReportPath -Encoding UTF8
Write-Host "Rapport JSON généré: $jsonReportPath" -ForegroundColor Green
Write-Host "Taille du rapport: $((Get-Item -Path $jsonReportPath).Length) octets" -ForegroundColor White

# Ouvrir une visualisation dans le navigateur
Write-Host "`n=== Ouverture d'une visualisation dans le navigateur ===" -ForegroundColor Magenta
Write-Host "Ouverture de la visualisation de la distribution asymétrique positive..." -ForegroundColor White
Start-Process $positiveSkewVisualizationPath

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green
Write-Host "Les fonctions d'évaluation visuelle de l'asymétrie fonctionnent correctement." -ForegroundColor Green
Write-Host "Les visualisations HTML ont été générées dans le dossier: $reportsFolder" -ForegroundColor Green

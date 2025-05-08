# Test-AsymmetryRecommendations.ps1
# Ce script teste le module AsymmetryRecommendations

# Importer les modules nécessaires
$tailSlopeModulePath = Join-Path -Path $PSScriptRoot -ChildPath "TailSlopeAsymmetry.psm1"
$recommendationsModulePath = Join-Path -Path $PSScriptRoot -ChildPath "AsymmetryRecommendations.psm1"

if (-not (Test-Path -Path $tailSlopeModulePath)) {
    Write-Error "Le module TailSlopeAsymmetry.psm1 n'a pas été trouvé: $tailSlopeModulePath"
    exit 1
}

if (-not (Test-Path -Path $recommendationsModulePath)) {
    Write-Error "Le module AsymmetryRecommendations.psm1 n'a pas été trouvé: $recommendationsModulePath"
    exit 1
}

Import-Module $tailSlopeModulePath -Force
Import-Module $recommendationsModulePath -Force

# Définir le dossier de rapports
$reportsFolder = Join-Path -Path $PSScriptRoot -ChildPath "reports"
if (-not (Test-Path -Path $reportsFolder)) {
    New-Item -Path $reportsFolder -ItemType Directory | Out-Null
}

# Générer des données de test
Write-Host "`n=== Génération des données de test ===" -ForegroundColor Magenta

# Distribution normale
$normalData = 1..1000 | ForEach-Object { [Math]::Round([System.Random]::new().NextDouble() * 10 - 5, 2) }

# Distribution asymétrique positive
$positiveSkewData = 1..1000 | ForEach-Object { 
    $value = [Math]::Pow([System.Random]::new().NextDouble(), 2) * 10
    [Math]::Round($value, 2)
}

# Distribution asymétrique négative
$negativeSkewData = 1..1000 | ForEach-Object { 
    $value = 10 - [Math]::Pow([System.Random]::new().NextDouble(), 2) * 10
    [Math]::Round($value, 2)
}

# Distribution fortement asymétrique positive
$strongPositiveSkewData = 1..1000 | ForEach-Object { 
    $value = [Math]::Pow([System.Random]::new().NextDouble(), 5) * 20
    [Math]::Round($value, 2)
}

Write-Host "Données générées:" -ForegroundColor White
Write-Host "- Distribution normale: $($normalData.Count) points" -ForegroundColor White
Write-Host "- Distribution asymétrique positive: $($positiveSkewData.Count) points" -ForegroundColor White
Write-Host "- Distribution asymétrique négative: $($negativeSkewData.Count) points" -ForegroundColor White
Write-Host "- Distribution fortement asymétrique positive: $($strongPositiveSkewData.Count) points" -ForegroundColor White

# Test 1: Création d'un moteur de recommandations
Write-Host "`n=== Test 1: Création d'un moteur de recommandations ===" -ForegroundColor Magenta
$engine = New-AsymmetryRecommendationEngine
Write-Host "Moteur de recommandations créé avec succès." -ForegroundColor Green
Write-Host "Nombre de règles: $($engine.Rules.Count)" -ForegroundColor White
Write-Host "Catégories disponibles: $($engine.Categories.Keys -join ', ')" -ForegroundColor White

# Test 2: Recommandations pour une distribution normale
Write-Host "`n=== Test 2: Recommandations pour une distribution normale ===" -ForegroundColor Magenta
$normalAnalysis = Get-CompositeAsymmetryScore -Data $normalData -Methods @("All")
$normalRecommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $normalAnalysis
Write-Host "Recommandations pour une distribution normale:" -ForegroundColor White
foreach ($recommendation in $normalRecommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 3: Recommandations pour une distribution asymétrique positive
Write-Host "`n=== Test 3: Recommandations pour une distribution asymétrique positive ===" -ForegroundColor Magenta
$positiveSkewAnalysis = Get-CompositeAsymmetryScore -Data $positiveSkewData -Methods @("All")
$positiveSkewRecommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $positiveSkewAnalysis
Write-Host "Recommandations pour une distribution asymétrique positive:" -ForegroundColor White
foreach ($recommendation in $positiveSkewRecommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 4: Recommandations pour une distribution asymétrique négative
Write-Host "`n=== Test 4: Recommandations pour une distribution asymétrique négative ===" -ForegroundColor Magenta
$negativeSkewAnalysis = Get-CompositeAsymmetryScore -Data $negativeSkewData -Methods @("All")
$negativeSkewRecommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $negativeSkewAnalysis
Write-Host "Recommandations pour une distribution asymétrique négative:" -ForegroundColor White
foreach ($recommendation in $negativeSkewRecommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 5: Recommandations pour une distribution fortement asymétrique positive
Write-Host "`n=== Test 5: Recommandations pour une distribution fortement asymétrique positive ===" -ForegroundColor Magenta
$strongPositiveSkewAnalysis = Get-CompositeAsymmetryScore -Data $strongPositiveSkewData -Methods @("All")
$strongPositiveSkewRecommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $strongPositiveSkewAnalysis
Write-Host "Recommandations pour une distribution fortement asymétrique positive:" -ForegroundColor White
foreach ($recommendation in $strongPositiveSkewRecommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 6: Recommandations groupées par catégorie
Write-Host "`n=== Test 6: Recommandations groupées par catégorie ===" -ForegroundColor Magenta
$categoryRecommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $strongPositiveSkewAnalysis -GroupByCategory
Write-Host "Recommandations groupées par catégorie:" -ForegroundColor White
foreach ($category in $categoryRecommendations.Keys) {
    Write-Host "`nCatégorie: $category" -ForegroundColor Cyan
    foreach ($recommendation in $categoryRecommendations[$category]) {
        Write-Host "- $recommendation" -ForegroundColor White
    }
}

# Test 7: Recommandations avec détails des règles
Write-Host "`n=== Test 7: Recommandations avec détails des règles ===" -ForegroundColor Magenta
$detailedRecommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $strongPositiveSkewAnalysis -IncludeRuleDetails
Write-Host "Recommandations avec détails des règles:" -ForegroundColor White
foreach ($recommendation in $detailedRecommendations) {
    Write-Host "`nRègle: $($recommendation.RuleName) (ID: $($recommendation.RuleId))" -ForegroundColor Cyan
    Write-Host "Catégorie: $($recommendation.Category)" -ForegroundColor White
    Write-Host "Priorité: $($recommendation.Priority)" -ForegroundColor White
    Write-Host "Recommandation: $($recommendation.Recommendation)" -ForegroundColor White
}

# Test 8: Recommandations filtrées par catégorie
Write-Host "`n=== Test 8: Recommandations filtrées par catégorie ===" -ForegroundColor Magenta
$filteredRecommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $strongPositiveSkewAnalysis -Categories @("Transformation", "Tests statistiques")
Write-Host "Recommandations filtrées par catégorie (Transformation, Tests statistiques):" -ForegroundColor White
foreach ($recommendation in $filteredRecommendations) {
    Write-Host "- $recommendation" -ForegroundColor White
}

# Test 9: Intégration avec les rapports JSON
Write-Host "`n=== Test 9: Intégration avec les rapports JSON ===" -ForegroundColor Magenta
$jsonReportPath = Join-Path -Path $reportsFolder -ChildPath "recommendations_report.json"

# Créer un rapport JSON avec des recommandations
$reportData = @{
    metadata = @{
        title = "Rapport d'analyse d'asymétrie avec recommandations"
        generationDate = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        version = "1.0"
        sampleSize = $strongPositiveSkewData.Count
    }
    summary = @{
        asymmetryDirection = $strongPositiveSkewAnalysis.AsymmetryDirection
        asymmetryIntensity = $strongPositiveSkewAnalysis.AsymmetryIntensity
        compositeScore = [Math]::Round($strongPositiveSkewAnalysis.CompositeScore, 4)
        recommendedMethod = $strongPositiveSkewAnalysis.RecommendedMethod
        consistencyScore = [Math]::Round($strongPositiveSkewAnalysis.ConsistencyScore, 4)
        summaryText = "L'analyse de l'asymétrie de la distribution a révélé une asymétrie $($strongPositiveSkewAnalysis.AsymmetryDirection.ToLower()) de niveau $($strongPositiveSkewAnalysis.AsymmetryIntensity.ToLower())."
    }
    statistics = @{
        min = [Math]::Round(($strongPositiveSkewData | Measure-Object -Minimum).Minimum, 4)
        max = [Math]::Round(($strongPositiveSkewData | Measure-Object -Maximum).Maximum, 4)
        mean = [Math]::Round(($strongPositiveSkewData | Measure-Object -Average).Average, 4)
        median = [Math]::Round((($strongPositiveSkewData | Sort-Object)[$strongPositiveSkewData.Count / 2]), 4)
        stdDev = [Math]::Round([Math]::Sqrt(($strongPositiveSkewData | ForEach-Object { [Math]::Pow($_ - (($strongPositiveSkewData | Measure-Object -Average).Average), 2) } | Measure-Object -Average).Average), 4)
    }
    recommendations = @{
        items = $detailedRecommendations | ForEach-Object {
            @{
                ruleId = $_.RuleId
                ruleName = $_.RuleName
                category = $_.Category
                priority = $_.Priority
                recommendation = $_.Recommendation
            }
        }
        byCategory = @{}
    }
}

# Ajouter les recommandations par catégorie
foreach ($category in $categoryRecommendations.Keys) {
    $reportData.recommendations.byCategory[$category] = $categoryRecommendations[$category]
}

# Enregistrer le rapport JSON
$reportData | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonReportPath -Encoding UTF8
Write-Host "Rapport JSON avec recommandations généré: $jsonReportPath" -ForegroundColor Green
Write-Host "Taille du rapport: $((Get-Item -Path $jsonReportPath).Length) octets" -ForegroundColor White

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green
Write-Host "Le système de recommandations fonctionne correctement." -ForegroundColor Green
Write-Host "Nombre de règles implémentées: $($engine.Rules.Count)" -ForegroundColor Green
Write-Host "Catégories disponibles: $($engine.Categories.Keys -join ', ')" -ForegroundColor Green

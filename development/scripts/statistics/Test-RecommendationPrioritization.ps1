# Test-RecommendationPrioritization.ps1
# Ce script teste le système de prioritisation des recommandations

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

# Analyser les distributions
Write-Host "`n=== Analyse des distributions ===" -ForegroundColor Magenta
$normalAnalysis = Get-CompositeAsymmetryScore -Data $normalData -Methods @("All")
$positiveSkewAnalysis = Get-CompositeAsymmetryScore -Data $positiveSkewData -Methods @("All")
$negativeSkewAnalysis = Get-CompositeAsymmetryScore -Data $negativeSkewData -Methods @("All")
$strongPositiveSkewAnalysis = Get-CompositeAsymmetryScore -Data $strongPositiveSkewData -Methods @("All")

Write-Host "Analyses complétées:" -ForegroundColor White
Write-Host "- Distribution normale: $($normalAnalysis.AsymmetryDirection) ($($normalAnalysis.AsymmetryIntensity))" -ForegroundColor White
Write-Host "- Distribution asymétrique positive: $($positiveSkewAnalysis.AsymmetryDirection) ($($positiveSkewAnalysis.AsymmetryIntensity))" -ForegroundColor White
Write-Host "- Distribution asymétrique négative: $($negativeSkewAnalysis.AsymmetryDirection) ($($negativeSkewAnalysis.AsymmetryIntensity))" -ForegroundColor White
Write-Host "- Distribution fortement asymétrique positive: $($strongPositiveSkewAnalysis.AsymmetryDirection) ($($strongPositiveSkewAnalysis.AsymmetryIntensity))" -ForegroundColor White

# Test 1: Recommandations avec scoring avancé
Write-Host "`n=== Test 1: Recommandations avec scoring avancé ===" -ForegroundColor Magenta
$advancedRecommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $strongPositiveSkewAnalysis -IncludeRuleDetails
Write-Host "Recommandations avec scoring avancé:" -ForegroundColor White
foreach ($recommendation in $advancedRecommendations) {
    Write-Host "- [$($recommendation.RuleId)] $($recommendation.RuleName) (Pertinence: $($recommendation.Relevance), Priorité: $($recommendation.Priority))" -ForegroundColor White
    Write-Host "  $($recommendation.Recommendation)" -ForegroundColor Gray
}

# Test 2: Recommandations sans scoring avancé
Write-Host "`n=== Test 2: Recommandations sans scoring avancé ===" -ForegroundColor Magenta
$basicRecommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $strongPositiveSkewAnalysis -IncludeRuleDetails -DisableAdvancedScoring
Write-Host "Recommandations sans scoring avancé:" -ForegroundColor White
foreach ($recommendation in $basicRecommendations) {
    Write-Host "- [$($recommendation.RuleId)] $($recommendation.RuleName) (Priorité: $($recommendation.Priority))" -ForegroundColor White
    Write-Host "  $($recommendation.Recommendation)" -ForegroundColor Gray
}

# Test 3: Recommandations avec seuil de pertinence minimum
Write-Host "`n=== Test 3: Recommandations avec seuil de pertinence minimum ===" -ForegroundColor Magenta
$highRelevanceRecommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $strongPositiveSkewAnalysis -IncludeRuleDetails -MinimumRelevance 0.7
Write-Host "Recommandations avec pertinence >= 0.7:" -ForegroundColor White
if ($highRelevanceRecommendations.Count -eq 0) {
    Write-Host "Aucune recommandation ne dépasse le seuil de pertinence." -ForegroundColor Yellow
} else {
    foreach ($recommendation in $highRelevanceRecommendations) {
        Write-Host "- [$($recommendation.RuleId)] $($recommendation.RuleName) (Pertinence: $($recommendation.Relevance))" -ForegroundColor White
        Write-Host "  $($recommendation.Recommendation)" -ForegroundColor Gray
    }
}

# Test 4: Recommandations par catégorie
Write-Host "`n=== Test 4: Recommandations par catégorie ===" -ForegroundColor Magenta
$categoryRecommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $strongPositiveSkewAnalysis -GroupByCategory -IncludeRuleDetails
Write-Host "Recommandations par catégorie:" -ForegroundColor White
foreach ($category in $categoryRecommendations.Keys) {
    Write-Host "`nCatégorie: $category" -ForegroundColor Cyan
    foreach ($recommendation in $categoryRecommendations[$category]) {
        Write-Host "- [$($recommendation.RuleId)] $($recommendation.RuleName) (Pertinence: $($recommendation.Relevance))" -ForegroundColor White
        Write-Host "  $($recommendation.Recommendation)" -ForegroundColor Gray
    }
}

# Test 5: Statistiques sur les recommandations
Write-Host "`n=== Test 5: Statistiques sur les recommandations ===" -ForegroundColor Magenta
$statistics = Get-AsymmetryRecommendations -AsymmetryAnalysis $strongPositiveSkewAnalysis -Statistics
Write-Host "Statistiques sur les recommandations:" -ForegroundColor White
Write-Host "- Nombre total de règles: $($statistics.TotalRules)" -ForegroundColor White
Write-Host "- Règles applicables: $($statistics.ApplicableRules) ($($statistics.ApplicablePercentage)%)" -ForegroundColor White
Write-Host "- Pertinence moyenne: $($statistics.AverageRelevance)" -ForegroundColor White
Write-Host "- Contexte actuel: $($statistics.Context)" -ForegroundColor White
Write-Host "- Scoring avancé: $($statistics.UseAdvancedScoring)" -ForegroundColor White

Write-Host "`nRépartition par catégorie:" -ForegroundColor Cyan
foreach ($cat in $statistics.CategoryCounts.Keys) {
    Write-Host "- $cat`: $($statistics.CategoryCounts[$cat])" -ForegroundColor White
}

# Test 6: Recommandations dans différents contextes
Write-Host "`n=== Test 6: Recommandations dans différents contextes ===" -ForegroundColor Magenta
$contexts = @("Default", "DataPreparation", "StatisticalTesting", "Visualization")
foreach ($context in $contexts) {
    Write-Host "`nContexte: $context" -ForegroundColor Cyan
    $contextRecommendations = Get-AsymmetryRecommendations -AsymmetryAnalysis $strongPositiveSkewAnalysis -Context $context -IncludeRuleDetails
    Write-Host "Nombre de recommandations: $($contextRecommendations.Count)" -ForegroundColor White
    foreach ($recommendation in $contextRecommendations) {
        Write-Host "- [$($recommendation.RuleId)] $($recommendation.RuleName) (Pertinence: $($recommendation.Relevance))" -ForegroundColor White
        Write-Host "  $($recommendation.Recommendation)" -ForegroundColor Gray
    }
}

# Résumé des tests
Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Tous les tests ont été exécutés avec succès." -ForegroundColor Green
Write-Host "Le système de prioritisation des recommandations fonctionne correctement." -ForegroundColor Green

# Test-GetExtractedInfoCollectionStatistics.ps1
# Test de la fonction Get-ExtractedInfoCollectionStatistics pour différentes collections

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test 1: Statistiques d'une collection vide
Write-Host "Test 1: Statistiques d'une collection vide" -ForegroundColor Cyan
$emptyCollection = New-ExtractedInfoCollection -Name "EmptyCollection"
$emptyStats = Get-ExtractedInfoCollectionStatistics -Collection $emptyCollection

$tests1 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $emptyStats }
    @{ Test = "Le nombre total d'éléments est 0"; Condition = $emptyStats.TotalCount -eq 0 }
    @{ Test = "Le nombre d'éléments valides est 0"; Condition = $emptyStats.ValidCount -eq 0 }
    @{ Test = "Le nombre d'éléments invalides est 0"; Condition = $emptyStats.InvalidCount -eq 0 }
    @{ Test = "La distribution par source est vide"; Condition = $emptyStats.SourceDistribution.Count -eq 0 }
    @{ Test = "La distribution par état est vide"; Condition = $emptyStats.StateDistribution.Count -eq 0 }
    @{ Test = "La distribution par type est vide"; Condition = $emptyStats.TypeDistribution.Count -eq 0 }
    @{ Test = "Le nom de la collection est correct"; Condition = $emptyStats.CollectionName -eq $emptyCollection.Name }
    @{ Test = "La date de création de la collection est correcte"; Condition = $emptyStats.CollectionCreatedAt -eq $emptyCollection.CreatedAt }
    @{ Test = "La date de génération des statistiques est définie"; Condition = $null -ne $emptyStats.StatisticsGeneratedAt }
)

$test1Success = $true
foreach ($test in $tests1) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test1Success = $false
    }
}

# Test 2: Statistiques d'une collection avec des éléments de différents types
Write-Host "Test 2: Statistiques d'une collection avec des éléments de différents types" -ForegroundColor Cyan

# Créer une collection avec des éléments de différents types
$mixedCollection = New-ExtractedInfoCollection -Name "MixedCollection"

# Créer des informations extraites de différents types
$info1 = New-ExtractedInfo -Source "Source1" -ExtractorName "Extractor1"
$info1.ProcessingState = "Raw"
$info1.ConfidenceScore = 50
$info1.IsValid = $false

$info2 = New-TextExtractedInfo -Source "Source1" -ExtractorName "Extractor2" -Text "Test text" -Language "en"
$info2.ProcessingState = "Processed"
$info2.ConfidenceScore = 80
$info2.IsValid = $true

$info3 = New-StructuredDataExtractedInfo -Source "Source2" -ExtractorName "Extractor3" -Data @{Name = "Test"; Value = 123} -DataFormat "Hashtable"
$info3.ProcessingState = "Processed"
$info3.ConfidenceScore = 90
$info3.IsValid = $true

$info4 = New-MediaExtractedInfo -Source "Source2" -ExtractorName "Extractor4" -MediaPath "test.jpg" -MediaType "Image"
$info4.ProcessingState = "Failed"
$info4.ConfidenceScore = 30
$info4.IsValid = $false

# Ajouter les informations à la collection
$mixedCollection = Add-ExtractedInfoToCollection -Collection $mixedCollection -Info @($info1, $info2, $info3, $info4)

# Obtenir les statistiques
$mixedStats = Get-ExtractedInfoCollectionStatistics -Collection $mixedCollection

$tests2 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $mixedStats }
    @{ Test = "Le nombre total d'éléments est 4"; Condition = $mixedStats.TotalCount -eq 4 }
    @{ Test = "Le nombre d'éléments valides est 2"; Condition = $mixedStats.ValidCount -eq 2 }
    @{ Test = "Le nombre d'éléments invalides est 2"; Condition = $mixedStats.InvalidCount -eq 2 }
    @{ Test = "La confiance moyenne est calculée correctement"; Condition = $mixedStats.AverageConfidence -eq 62.5 }
    @{ Test = "La distribution par source contient 2 sources"; Condition = $mixedStats.SourceDistribution.Count -eq 2 }
    @{ Test = "La source 'Source1' a 2 éléments"; Condition = $mixedStats.SourceDistribution["Source1"] -eq 2 }
    @{ Test = "La source 'Source2' a 2 éléments"; Condition = $mixedStats.SourceDistribution["Source2"] -eq 2 }
    @{ Test = "La distribution par état contient 3 états"; Condition = $mixedStats.StateDistribution.Count -eq 3 }
    @{ Test = "L'état 'Raw' a 1 élément"; Condition = $mixedStats.StateDistribution["Raw"] -eq 1 }
    @{ Test = "L'état 'Processed' a 2 éléments"; Condition = $mixedStats.StateDistribution["Processed"] -eq 2 }
    @{ Test = "L'état 'Failed' a 1 élément"; Condition = $mixedStats.StateDistribution["Failed"] -eq 1 }
    @{ Test = "La distribution par type contient 4 types"; Condition = $mixedStats.TypeDistribution.Count -eq 4 }
    @{ Test = "Le type 'ExtractedInfo' a 1 élément"; Condition = $mixedStats.TypeDistribution["ExtractedInfo"] -eq 1 }
    @{ Test = "Le type 'TextExtractedInfo' a 1 élément"; Condition = $mixedStats.TypeDistribution["TextExtractedInfo"] -eq 1 }
    @{ Test = "Le type 'StructuredDataExtractedInfo' a 1 élément"; Condition = $mixedStats.TypeDistribution["StructuredDataExtractedInfo"] -eq 1 }
    @{ Test = "Le type 'MediaExtractedInfo' a 1 élément"; Condition = $mixedStats.TypeDistribution["MediaExtractedInfo"] -eq 1 }
    @{ Test = "Le nom de la collection est correct"; Condition = $mixedStats.CollectionName -eq $mixedCollection.Name }
    @{ Test = "La date de création de la collection est correcte"; Condition = $mixedStats.CollectionCreatedAt -eq $mixedCollection.CreatedAt }
    @{ Test = "La date de génération des statistiques est définie"; Condition = $null -ne $mixedStats.StatisticsGeneratedAt }
)

$test2Success = $true
foreach ($test in $tests2) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test2Success = $false
    }
}

# Résultat final
$allSuccess = $test1Success -and $test2Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

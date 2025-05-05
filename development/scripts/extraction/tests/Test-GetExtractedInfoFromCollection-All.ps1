# Test-GetExtractedInfoFromCollection-All.ps1
# Test de la fonction Get-ExtractedInfoFromCollection pour tous les éléments

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer une collection pour les tests
$collection = New-ExtractedInfoCollection -Name "TestCollection"

# Créer plusieurs informations extraites pour les tests
$info1 = New-ExtractedInfo -Source "TestSource1" -ExtractorName "TestExtractor1"
$info1 = Add-ExtractedInfoMetadata -Info $info1 -Key "TestKey1" -Value "TestValue1"

$info2 = New-TextExtractedInfo -Source "TestSource2" -ExtractorName "TestExtractor2" -Text "Test text" -Language "en"
$info2 = Add-ExtractedInfoMetadata -Info $info2 -Key "TestKey2" -Value "TestValue2"

$info3 = New-StructuredDataExtractedInfo -Source "TestSource3" -ExtractorName "TestExtractor3" -Data @{Name = "Test"; Value = 123} -DataFormat "Hashtable"
$info3 = Add-ExtractedInfoMetadata -Info $info3 -Key "TestKey3" -Value "TestValue3"

# Ajouter les informations à la collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info @($info1, $info2, $info3)

# Test 1: Récupérer tous les éléments de la collection
Write-Host "Test 1: Récupérer tous les éléments de la collection" -ForegroundColor Cyan
$allItems = Get-ExtractedInfoFromCollection -Collection $collection

$tests1 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $allItems }
    @{ Test = "Le résultat est un tableau"; Condition = $allItems -is [array] }
    @{ Test = "Le tableau contient tous les éléments"; Condition = $allItems.Count -eq $collection.Items.Count }
    @{ Test = "Le premier élément est présent"; Condition = ($allItems | Where-Object { $_.Id -eq $info1.Id }).Count -eq 1 }
    @{ Test = "Le deuxième élément est présent"; Condition = ($allItems | Where-Object { $_.Id -eq $info2.Id }).Count -eq 1 }
    @{ Test = "Le troisième élément est présent"; Condition = ($allItems | Where-Object { $_.Id -eq $info3.Id }).Count -eq 1 }
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

# Test 2: Récupérer tous les éléments d'une collection vide
Write-Host "Test 2: Récupérer tous les éléments d'une collection vide" -ForegroundColor Cyan
$emptyCollection = New-ExtractedInfoCollection -Name "EmptyCollection"
$emptyItems = Get-ExtractedInfoFromCollection -Collection $emptyCollection

$tests2 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $emptyItems }
    @{ Test = "Le résultat est un tableau"; Condition = $emptyItems -is [array] }
    @{ Test = "Le tableau est vide"; Condition = $emptyItems.Count -eq 0 }
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

# Test 3: Récupérer tous les éléments sans spécifier d'ID
Write-Host "Test 3: Récupérer tous les éléments sans spécifier d'ID" -ForegroundColor Cyan
$allItemsNoId = Get-ExtractedInfoFromCollection -Collection $collection -Id ""

$tests3 = @(
    @{ Test = "Le résultat n'est pas null"; Condition = $null -ne $allItemsNoId }
    @{ Test = "Le résultat est un tableau"; Condition = $allItemsNoId -is [array] }
    @{ Test = "Le tableau contient tous les éléments"; Condition = $allItemsNoId.Count -eq $collection.Items.Count }
    @{ Test = "Le premier élément est présent"; Condition = ($allItemsNoId | Where-Object { $_.Id -eq $info1.Id }).Count -eq 1 }
    @{ Test = "Le deuxième élément est présent"; Condition = ($allItemsNoId | Where-Object { $_.Id -eq $info2.Id }).Count -eq 1 }
    @{ Test = "Le troisième élément est présent"; Condition = ($allItemsNoId | Where-Object { $_.Id -eq $info3.Id }).Count -eq 1 }
)

$test3Success = $true
foreach ($test in $tests3) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $test3Success = $false
    }
}

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

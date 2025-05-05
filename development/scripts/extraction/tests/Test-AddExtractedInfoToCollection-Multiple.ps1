# Test-AddExtractedInfoToCollection-Multiple.ps1
# Test de la fonction Add-ExtractedInfoToCollection avec plusieurs éléments

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

# Test 1: Ajouter plusieurs éléments à la collection en une seule fois
Write-Host "Test 1: Ajouter plusieurs éléments à la collection en une seule fois" -ForegroundColor Cyan
$initialCount = $collection.Items.Count
$updatedCollection = Add-ExtractedInfoToCollection -Collection $collection -Info @($info1, $info2, $info3)

$tests1 = @(
    @{ Test = "L'objet collection mis à jour n'est pas null"; Condition = $null -ne $updatedCollection }
    @{ Test = "Le nom de la collection reste inchangé"; Condition = $updatedCollection.Name -eq $collection.Name }
    @{ Test = "La date de création reste inchangée"; Condition = $updatedCollection.CreatedAt -eq $collection.CreatedAt }
    @{ Test = "Le tableau d'éléments n'est pas vide"; Condition = $updatedCollection.Items.Count -gt 0 }
    @{ Test = "Le nombre d'éléments a augmenté de 3"; Condition = $updatedCollection.Items.Count -eq ($initialCount + 3) }
    @{ Test = "Le premier élément ajouté est présent"; Condition = $updatedCollection.Items[0].Id -eq $info1.Id }
    @{ Test = "Le deuxième élément ajouté est présent"; Condition = $updatedCollection.Items[1].Id -eq $info2.Id }
    @{ Test = "Le troisième élément ajouté est présent"; Condition = $updatedCollection.Items[2].Id -eq $info3.Id }
    @{ Test = "Les métadonnées du premier élément sont préservées"; Condition = $updatedCollection.Items[0].Metadata["TestKey1"] -eq "TestValue1" }
    @{ Test = "Les métadonnées du deuxième élément sont préservées"; Condition = $updatedCollection.Items[1].Metadata["TestKey2"] -eq "TestValue2" }
    @{ Test = "Les métadonnées du troisième élément sont préservées"; Condition = $updatedCollection.Items[2].Metadata["TestKey3"] -eq "TestValue3" }
    @{ Test = "Les métadonnées de la collection contiennent _LastModified"; Condition = $updatedCollection.Metadata.ContainsKey("_LastModified") }
    @{ Test = "Les métadonnées de la collection contiennent _ItemCount"; Condition = $updatedCollection.Metadata.ContainsKey("_ItemCount") }
    @{ Test = "Le nombre d'éléments dans les métadonnées est correct"; Condition = $updatedCollection.Metadata["_ItemCount"] -eq $updatedCollection.Items.Count }
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

# Test 2: Ajouter un élément supplémentaire à la collection déjà remplie
Write-Host "Test 2: Ajouter un élément supplémentaire à la collection déjà remplie" -ForegroundColor Cyan
$info4 = New-MediaExtractedInfo -Source "TestSource4" -ExtractorName "TestExtractor4" -MediaPath "test.jpg" -MediaType "Image"
$info4 = Add-ExtractedInfoMetadata -Info $info4 -Key "TestKey4" -Value "TestValue4"

$initialCount = $updatedCollection.Items.Count
$finalCollection = Add-ExtractedInfoToCollection -Collection $updatedCollection -Info $info4

$tests2 = @(
    @{ Test = "L'objet collection mis à jour n'est pas null"; Condition = $null -ne $finalCollection }
    @{ Test = "Le nombre d'éléments a augmenté de 1"; Condition = $finalCollection.Items.Count -eq ($initialCount + 1) }
    @{ Test = "Le nouvel élément ajouté est présent"; Condition = $finalCollection.Items[$initialCount].Id -eq $info4.Id }
    @{ Test = "Les métadonnées du nouvel élément sont préservées"; Condition = $finalCollection.Items[$initialCount].Metadata["TestKey4"] -eq "TestValue4" }
    @{ Test = "Les métadonnées de la collection ont été mises à jour"; Condition = $finalCollection.Metadata["_LastModified"] -ne $updatedCollection.Metadata["_LastModified"] }
    @{ Test = "Le nombre d'éléments dans les métadonnées est correct"; Condition = $finalCollection.Metadata["_ItemCount"] -eq $finalCollection.Items.Count }
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

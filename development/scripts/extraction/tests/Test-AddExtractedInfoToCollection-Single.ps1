# Test-AddExtractedInfoToCollection-Single.ps1
# Test de la fonction Add-ExtractedInfoToCollection avec un seul élément

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer une collection pour les tests
$collection = New-ExtractedInfoCollection -Name "TestCollection"

# Créer une information extraite pour les tests
$info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
$info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"

# Test: Ajouter un élément à la collection
Write-Host "Test: Ajouter un élément à la collection" -ForegroundColor Cyan
$initialCount = $collection.Items.Count
$updatedCollection = Add-ExtractedInfoToCollection -Collection $collection -Info $info

$tests = @(
    @{ Test = "L'objet collection mis à jour n'est pas null"; Condition = $null -ne $updatedCollection }
    @{ Test = "Le nom de la collection reste inchangé"; Condition = $updatedCollection.Name -eq $collection.Name }
    @{ Test = "La date de création reste inchangée"; Condition = $updatedCollection.CreatedAt -eq $collection.CreatedAt }
    @{ Test = "Le tableau d'éléments n'est pas vide"; Condition = $updatedCollection.Items.Count -gt 0 }
    @{ Test = "Le nombre d'éléments a augmenté"; Condition = $updatedCollection.Items.Count -gt $initialCount }
    @{ Test = "L'élément ajouté est présent"; Condition = $updatedCollection.Items[0].Id -eq $info.Id }
    @{ Test = "Les métadonnées de l'élément sont préservées"; Condition = $updatedCollection.Items[0].Metadata["TestKey"] -eq "TestValue" }
    @{ Test = "Les métadonnées de la collection contiennent _LastModified"; Condition = $updatedCollection.Metadata.ContainsKey("_LastModified") }
    @{ Test = "Les métadonnées de la collection contiennent _ItemCount"; Condition = $updatedCollection.Metadata.ContainsKey("_ItemCount") }
    @{ Test = "Le nombre d'éléments dans les métadonnées est correct"; Condition = $updatedCollection.Metadata["_ItemCount"] -eq $updatedCollection.Items.Count }
)

$success = $true
foreach ($test in $tests) {
    if ($test.Condition) {
        Write-Host "  [SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "  [ÉCHEC] $($test.Test)" -ForegroundColor Red
        $success = $false
    }
}

# Résultat final
if ($success) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

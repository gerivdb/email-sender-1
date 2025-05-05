# Test-NewExtractedInfoCollection.ps1
# Test de la fonction New-ExtractedInfoCollection avec nom par défaut et personnalisé

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Test 1: Créer une collection avec le nom par défaut
Write-Host "Test 1: Créer une collection avec le nom par défaut" -ForegroundColor Cyan
$collection1 = New-ExtractedInfoCollection

$tests1 = @(
    @{ Test = "L'objet collection n'est pas null"; Condition = $null -ne $collection1 }
    @{ Test = "Le nom est 'Collection'"; Condition = $collection1.Name -eq "Collection" }
    @{ Test = "La date de création est définie"; Condition = $null -ne $collection1.CreatedAt }
    @{ Test = "Le tableau d'éléments est vide"; Condition = $collection1.Items.Count -eq 0 }
    @{ Test = "Les métadonnées ne sont pas nulles"; Condition = $null -ne $collection1.Metadata }
    @{ Test = "Le type est 'ExtractedInfoCollection'"; Condition = $collection1._Type -eq "ExtractedInfoCollection" }
    @{ Test = "Les métadonnées contiennent _CreatedBy"; Condition = $collection1.Metadata.ContainsKey("_CreatedBy") }
    @{ Test = "Les métadonnées contiennent _CreatedAt"; Condition = $collection1.Metadata.ContainsKey("_CreatedAt") }
    @{ Test = "Les métadonnées contiennent _Version"; Condition = $collection1.Metadata.ContainsKey("_Version") }
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

# Test 2: Créer une collection avec un nom personnalisé
Write-Host "Test 2: Créer une collection avec un nom personnalisé" -ForegroundColor Cyan
$customName = "CustomCollection"
$collection2 = New-ExtractedInfoCollection -Name $customName

$tests2 = @(
    @{ Test = "L'objet collection n'est pas null"; Condition = $null -ne $collection2 }
    @{ Test = "Le nom est correct"; Condition = $collection2.Name -eq $customName }
    @{ Test = "La date de création est définie"; Condition = $null -ne $collection2.CreatedAt }
    @{ Test = "Le tableau d'éléments est vide"; Condition = $collection2.Items.Count -eq 0 }
    @{ Test = "Les métadonnées ne sont pas nulles"; Condition = $null -ne $collection2.Metadata }
    @{ Test = "Le type est 'ExtractedInfoCollection'"; Condition = $collection2._Type -eq "ExtractedInfoCollection" }
    @{ Test = "Les métadonnées contiennent _CreatedBy"; Condition = $collection2.Metadata.ContainsKey("_CreatedBy") }
    @{ Test = "Les métadonnées contiennent _CreatedAt"; Condition = $collection2.Metadata.ContainsKey("_CreatedAt") }
    @{ Test = "Les métadonnées contiennent _Version"; Condition = $collection2.Metadata.ContainsKey("_Version") }
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

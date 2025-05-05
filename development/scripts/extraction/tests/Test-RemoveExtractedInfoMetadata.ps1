# Test-RemoveExtractedInfoMetadata.ps1
# Test de la fonction Remove-ExtractedInfoMetadata pour supprimer des métadonnées

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer une information extraite de base pour les tests
$info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"

# Ajouter quelques métadonnées pour les tests
$info = Add-ExtractedInfoMetadata -Info $info -Key "StringKey" -Value "StringValue"
$info = Add-ExtractedInfoMetadata -Info $info -Key "NumberKey" -Value 123
$info = Add-ExtractedInfoMetadata -Info $info -Key "BoolKey" -Value $true

# Test 1: Supprimer une métadonnée existante
Write-Host "Test 1: Supprimer une métadonnée existante" -ForegroundColor Cyan
$initialCount = $info.Metadata.Count
$updatedInfo = Remove-ExtractedInfoMetadata -Info $info -Key "StringKey"
$value1 = Get-ExtractedInfoMetadata -Info $updatedInfo -Key "StringKey"

$tests1 = @(
    @{ Test = "L'objet mis à jour n'est pas null"; Condition = $null -ne $updatedInfo }
    @{ Test = "L'ID reste inchangé"; Condition = $updatedInfo.Id -eq $info.Id }
    @{ Test = "La métadonnée a été supprimée"; Condition = -not $updatedInfo.Metadata.ContainsKey("StringKey") }
    @{ Test = "La valeur récupérée est null"; Condition = $null -eq $value1 }
    @{ Test = "Le nombre de métadonnées a diminué"; Condition = $updatedInfo.Metadata.Count -lt $initialCount }
    @{ Test = "La métadonnée _LastModified a été mise à jour"; Condition = $updatedInfo.Metadata.ContainsKey("_LastModified") }
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

# Mettre à jour l'objet info pour le test suivant
$info = $updatedInfo

# Test 2: Supprimer une métadonnée inexistante
Write-Host "Test 2: Supprimer une métadonnée inexistante" -ForegroundColor Cyan
$initialCount = $info.Metadata.Count
$lastModified = $info.Metadata["_LastModified"]
$updatedInfo = Remove-ExtractedInfoMetadata -Info $info -Key "NonExistentKey"

$tests2 = @(
    @{ Test = "L'objet mis à jour n'est pas null"; Condition = $null -ne $updatedInfo }
    @{ Test = "L'ID reste inchangé"; Condition = $updatedInfo.Id -eq $info.Id }
    @{ Test = "Le nombre de métadonnées reste inchangé"; Condition = $updatedInfo.Metadata.Count -eq $initialCount }
    @{ Test = "La métadonnée _LastModified n'a pas été mise à jour"; Condition = $updatedInfo.Metadata["_LastModified"] -eq $lastModified }
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

# Test 3: Supprimer une métadonnée système
Write-Host "Test 3: Supprimer une métadonnée système" -ForegroundColor Cyan
$initialCount = $info.Metadata.Count
$updatedInfo = Remove-ExtractedInfoMetadata -Info $info -Key "_CreatedBy"
$value3 = Get-ExtractedInfoMetadata -Info $updatedInfo -Key "_CreatedBy"

$tests3 = @(
    @{ Test = "L'objet mis à jour n'est pas null"; Condition = $null -ne $updatedInfo }
    @{ Test = "L'ID reste inchangé"; Condition = $updatedInfo.Id -eq $info.Id }
    @{ Test = "La métadonnée système a été supprimée"; Condition = -not $updatedInfo.Metadata.ContainsKey("_CreatedBy") }
    @{ Test = "La valeur récupérée est null"; Condition = $null -eq $value3 }
    @{ Test = "Le nombre de métadonnées a diminué"; Condition = $updatedInfo.Metadata.Count -lt $initialCount }
    @{ Test = "La métadonnée _LastModified a été mise à jour"; Condition = $updatedInfo.Metadata.ContainsKey("_LastModified") }
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

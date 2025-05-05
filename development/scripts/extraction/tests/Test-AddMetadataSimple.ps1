# Test-AddMetadataSimple.ps1
# Test simplifié de la fonction Add-ExtractedInfoMetadata

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer une information extraite de base pour les tests
$info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"

# Test avec une valeur chaîne de caractères
$key = "StringKey"
$value = "StringValue"
$updatedInfo = Add-ExtractedInfoMetadata -Info $info -Key $key -Value $value

# Vérifications
$tests = @(
    @{ Test = "L'objet mis à jour n'est pas null"; Condition = $null -ne $updatedInfo }
    @{ Test = "L'ID reste inchangé"; Condition = $updatedInfo.Id -eq $info.Id }
    @{ Test = "La métadonnée a été ajoutée"; Condition = $updatedInfo.Metadata.ContainsKey($key) }
    @{ Test = "La valeur de la métadonnée est correcte"; Condition = $updatedInfo.Metadata[$key] -eq $value }
    @{ Test = "La métadonnée _LastModified a été ajoutée"; Condition = $updatedInfo.Metadata.ContainsKey("_LastModified") }
)

# Exécuter les tests
$success = $true
foreach ($test in $tests) {
    if ($test.Condition) {
        Write-Host "[SUCCÈS] $($test.Test)" -ForegroundColor Green
    } else {
        Write-Host "[ÉCHEC] $($test.Test)" -ForegroundColor Red
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

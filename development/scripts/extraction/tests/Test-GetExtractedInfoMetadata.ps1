# Test-GetExtractedInfoMetadata.ps1
# Test de la fonction Get-ExtractedInfoMetadata pour des clés existantes et non-existantes

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force -ErrorAction Stop

# Créer une information extraite de base pour les tests
$info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"

# Ajouter quelques métadonnées pour les tests
$info = Add-ExtractedInfoMetadata -Info $info -Key "StringKey" -Value "StringValue"
$info = Add-ExtractedInfoMetadata -Info $info -Key "NumberKey" -Value 123
$info = Add-ExtractedInfoMetadata -Info $info -Key "BoolKey" -Value $true

# Test 1: Récupérer une métadonnée existante (chaîne)
Write-Host "Test 1: Récupérer une métadonnée existante (chaîne)" -ForegroundColor Cyan
$value1 = Get-ExtractedInfoMetadata -Info $info -Key "StringKey"
if ($value1 -eq "StringValue") {
    Write-Host "  [SUCCÈS] La valeur récupérée est correcte: $value1" -ForegroundColor Green
    $test1Success = $true
} else {
    Write-Host "  [ÉCHEC] La valeur récupérée est incorrecte: $value1" -ForegroundColor Red
    $test1Success = $false
}

# Test 2: Récupérer une métadonnée existante (nombre)
Write-Host "Test 2: Récupérer une métadonnée existante (nombre)" -ForegroundColor Cyan
$value2 = Get-ExtractedInfoMetadata -Info $info -Key "NumberKey"
if ($value2 -eq 123) {
    Write-Host "  [SUCCÈS] La valeur récupérée est correcte: $value2" -ForegroundColor Green
    $test2Success = $true
} else {
    Write-Host "  [ÉCHEC] La valeur récupérée est incorrecte: $value2" -ForegroundColor Red
    $test2Success = $false
}

# Test 3: Récupérer une métadonnée existante (booléen)
Write-Host "Test 3: Récupérer une métadonnée existante (booléen)" -ForegroundColor Cyan
$value3 = Get-ExtractedInfoMetadata -Info $info -Key "BoolKey"
if ($value3 -eq $true) {
    Write-Host "  [SUCCÈS] La valeur récupérée est correcte: $value3" -ForegroundColor Green
    $test3Success = $true
} else {
    Write-Host "  [ÉCHEC] La valeur récupérée est incorrecte: $value3" -ForegroundColor Red
    $test3Success = $false
}

# Test 4: Récupérer une métadonnée système
Write-Host "Test 4: Récupérer une métadonnée système" -ForegroundColor Cyan
$value4 = Get-ExtractedInfoMetadata -Info $info -Key "_CreatedBy"
if ($null -ne $value4 -and $value4 -ne "") {
    Write-Host "  [SUCCÈS] La valeur système récupérée est correcte: $value4" -ForegroundColor Green
    $test4Success = $true
} else {
    Write-Host "  [ÉCHEC] La valeur système récupérée est incorrecte: $value4" -ForegroundColor Red
    $test4Success = $false
}

# Test 5: Récupérer une métadonnée inexistante
Write-Host "Test 5: Récupérer une métadonnée inexistante" -ForegroundColor Cyan
$value5 = Get-ExtractedInfoMetadata -Info $info -Key "NonExistentKey"
if ($null -eq $value5) {
    Write-Host "  [SUCCÈS] La valeur récupérée est null comme attendu" -ForegroundColor Green
    $test5Success = $true
} else {
    Write-Host "  [ÉCHEC] La valeur récupérée n'est pas null: $value5" -ForegroundColor Red
    $test5Success = $false
}

# Résultat final
$allSuccess = $test1Success -and $test2Success -and $test3Success -and $test4Success -and $test5Success

if ($allSuccess) {
    Write-Host "Tous les tests ont réussi!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué!" -ForegroundColor Red
    exit 1
}

# Script de test manuel pour la conversion JSON vers CSV

# Chemins des modules Ã  tester
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"

# Importer le module
. $unifiedSegmenterPath

# Initialiser le segmenteur unifiÃ©
Write-Host "Initialisation du segmenteur unifiÃ©..."
$initResult = Initialize-UnifiedSegmenter
Write-Host "Initialisation rÃ©ussie: $initResult"

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "JsonToCsvTest"
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de test
$jsonObjectPath = Join-Path -Path $testDir -ChildPath "object.json"
$jsonArrayPath = Join-Path -Path $testDir -ChildPath "array.json"
$jsonNestedPath = Join-Path -Path $testDir -ChildPath "nested.json"
$outputDir = Join-Path -Path $testDir -ChildPath "output"
New-Item -Path $outputDir -ItemType Directory -Force | Out-Null

# CrÃ©er un fichier JSON objet
$jsonObjectContent = @{
    "name" = "Test Object"
    "id" = 1
    "value" = "Value 1"
    "active" = $true
} | ConvertTo-Json -Depth 10
Set-Content -Path $jsonObjectPath -Value $jsonObjectContent -Encoding UTF8

# CrÃ©er un fichier JSON tableau
$jsonArrayContent = @(
    @{ "id" = 1; "name" = "Item 1"; "value" = "Value 1"; "active" = $true },
    @{ "id" = 2; "name" = "Item 2"; "value" = "Value 2"; "active" = $false },
    @{ "id" = 3; "name" = "Item 3"; "value" = "Value 3"; "active" = $true }
) | ConvertTo-Json -Depth 10
Set-Content -Path $jsonArrayPath -Value $jsonArrayContent -Encoding UTF8

# CrÃ©er un fichier JSON avec structure imbriquÃ©e
$jsonNestedContent = @{
    "name" = "Test Object"
    "items" = @(
        @{ "id" = 1; "value" = "Item 1" },
        @{ "id" = 2; "value" = "Item 2" },
        @{ "id" = 3; "value" = "Item 3" }
    )
    "metadata" = @{
        "created" = "2025-06-06"
        "version" = "1.0.0"
    }
} | ConvertTo-Json -Depth 10
Set-Content -Path $jsonNestedPath -Value $jsonNestedContent -Encoding UTF8

# Test 1: Conversion JSON objet vers CSV
Write-Host "`n=== Test 1: Conversion JSON objet vers CSV ==="
$objectToCsvPath = Join-Path -Path $outputDir -ChildPath "object_to_csv.csv"
$objectToCsvResult = Convert-FileFormat -InputFile $jsonObjectPath -OutputFile $objectToCsvPath -InputFormat "JSON" -OutputFormat "CSV"
Write-Host "RÃ©sultat: $objectToCsvResult"
if ($objectToCsvResult -and (Test-Path -Path $objectToCsvPath)) {
    Write-Host "Contenu CSV:"
    Get-Content -Path $objectToCsvPath | ForEach-Object { Write-Host "  $_" }
}

# Test 2: Conversion JSON tableau vers CSV
Write-Host "`n=== Test 2: Conversion JSON tableau vers CSV ==="
$arrayToCsvPath = Join-Path -Path $outputDir -ChildPath "array_to_csv.csv"
$arrayToCsvResult = Convert-FileFormat -InputFile $jsonArrayPath -OutputFile $arrayToCsvPath -InputFormat "JSON" -OutputFormat "CSV"
Write-Host "RÃ©sultat: $arrayToCsvResult"
if ($arrayToCsvResult -and (Test-Path -Path $arrayToCsvPath)) {
    Write-Host "Contenu CSV:"
    Get-Content -Path $arrayToCsvPath | ForEach-Object { Write-Host "  $_" }
}

# Test 3: Conversion JSON imbriquÃ© vers CSV
Write-Host "`n=== Test 3: Conversion JSON imbriquÃ© vers CSV ==="
$nestedToCsvPath = Join-Path -Path $outputDir -ChildPath "nested_to_csv.csv"
$nestedToCsvResult = Convert-FileFormat -InputFile $jsonNestedPath -OutputFile $nestedToCsvPath -InputFormat "JSON" -OutputFormat "CSV"
Write-Host "RÃ©sultat: $nestedToCsvResult"
if ($nestedToCsvResult -and (Test-Path -Path $nestedToCsvPath)) {
    Write-Host "Contenu CSV:"
    Get-Content -Path $nestedToCsvPath | ForEach-Object { Write-Host "  $_" }
}

# Test 4: Validation des fichiers CSV gÃ©nÃ©rÃ©s
Write-Host "`n=== Test 4: Validation des fichiers CSV gÃ©nÃ©rÃ©s ==="
if (Test-Path -Path $objectToCsvPath) {
    $isValid = Test-FileValidity -FilePath $objectToCsvPath -Format "CSV"
    Write-Host "CSV objet valide: $isValid"
}

if (Test-Path -Path $arrayToCsvPath) {
    $isValid = Test-FileValidity -FilePath $arrayToCsvPath -Format "CSV"
    Write-Host "CSV tableau valide: $isValid"
}

if (Test-Path -Path $nestedToCsvPath) {
    $isValid = Test-FileValidity -FilePath $nestedToCsvPath -Format "CSV"
    Write-Host "CSV imbriquÃ© valide: $isValid"
}

# Nettoyer
Write-Host "`nNettoyage des fichiers de test..."
Remove-Item -Path $testDir -Recurse -Force

Write-Host "`nTests terminÃ©s."

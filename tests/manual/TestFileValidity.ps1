# Script de test manuel pour la validation de fichiers CSV et YAML

# Chemins des modules à tester
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"

# Importer le module
. $unifiedSegmenterPath

# Initialiser le segmenteur unifié
Write-Host "Initialisation du segmenteur unifié..."
$initResult = Initialize-UnifiedSegmenter
Write-Host "Initialisation réussie: $initResult"

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "FileValidityTest"
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Créer des fichiers de test
$validCsvPath = Join-Path -Path $testDir -ChildPath "valid.csv"
$invalidCsvPath = Join-Path -Path $testDir -ChildPath "invalid.csv"
$validYamlPath = Join-Path -Path $testDir -ChildPath "valid.yaml"
$invalidYamlPath = Join-Path -Path $testDir -ChildPath "invalid.yaml"

# Créer un fichier CSV valide
$validCsvContent = @"
id,name,value
1,Item 1,Value 1
2,Item 2,Value 2
3,Item 3,Value 3
"@
Set-Content -Path $validCsvPath -Value $validCsvContent -Encoding UTF8

# Créer un fichier CSV invalide (colonnes incohérentes)
$invalidCsvContent = @"
id,name,value
1,Item 1,Value 1
2,Item 2
3,Item 3,Value 3
"@
Set-Content -Path $invalidCsvPath -Value $invalidCsvContent -Encoding UTF8

# Créer un fichier YAML valide
$validYamlContent = @"
name: Test Object
items:
  - id: 1
    value: Item 1
  - id: 2
    value: Item 2
  - id: 3
    value: Item 3
metadata:
  created: 2025-06-06
  version: 1.0.0
"@
Set-Content -Path $validYamlPath -Value $validYamlContent -Encoding UTF8

# Créer un fichier YAML invalide
$invalidYamlContent = @"
name: Test Object
items:
  - id: 1
    value: Item 1
  - id: 2
    value: Item 2
  - id: 3
    value: Item 3
  metadata:
  created: 2025-06-06
  version: 1.0.0
"@
Set-Content -Path $invalidYamlPath -Value $invalidYamlContent -Encoding UTF8

# Test 1: Validation de fichiers CSV
Write-Host "`n=== Test 1: Validation de fichiers CSV ==="
$validCsvResult = Test-FileValidity -FilePath $validCsvPath -Format "CSV"
Write-Host "CSV valide: $validCsvResult"

$invalidCsvResult = Test-FileValidity -FilePath $invalidCsvPath -Format "CSV"
Write-Host "CSV invalide: $invalidCsvResult"

# Test 2: Validation de fichiers YAML
Write-Host "`n=== Test 2: Validation de fichiers YAML ==="
$validYamlResult = Test-FileValidity -FilePath $validYamlPath -Format "YAML"
Write-Host "YAML valide: $validYamlResult"

$invalidYamlResult = Test-FileValidity -FilePath $invalidYamlPath -Format "YAML"
Write-Host "YAML invalide: $invalidYamlResult"

# Test 3: Afficher le contenu des fichiers
Write-Host "`n=== Test 3: Contenu des fichiers ==="
Write-Host "Contenu CSV valide:"
Get-Content -Path $validCsvPath | ForEach-Object { Write-Host "  $_" }

Write-Host "`nContenu CSV invalide:"
Get-Content -Path $invalidCsvPath | ForEach-Object { Write-Host "  $_" }

Write-Host "`nContenu YAML valide:"
Get-Content -Path $validYamlPath | ForEach-Object { Write-Host "  $_" }

Write-Host "`nContenu YAML invalide:"
Get-Content -Path $invalidYamlPath | ForEach-Object { Write-Host "  $_" }

# Nettoyer
Write-Host "`nNettoyage des fichiers de test..."
Remove-Item -Path $testDir -Recurse -Force

Write-Host "`nTests terminés."

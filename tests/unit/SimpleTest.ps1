# Importer le module UnifiedSegmenter
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"

# Importer le module
. $unifiedSegmenterPath

# Initialiser le segmenteur unifié
$initResult = Initialize-UnifiedSegmenter

# Vérifier que l'initialisation a réussi
Write-Host "Initialisation réussie: $initResult"

# Créer un fichier de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "SimpleTest"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

$jsonFilePath = Join-Path -Path $testDir -ChildPath "test.json"
$jsonContent = @{
    "name" = "Test Object"
    "items" = @(
        @{ "id" = 1; "value" = "Item 1" },
        @{ "id" = 2; "value" = "Item 2" },
        @{ "id" = 3; "value" = "Item 3" }
    )
} | ConvertTo-Json -Depth 10
Set-Content -Path $jsonFilePath -Value $jsonContent -Encoding UTF8

# Tester la détection de format
$format = Get-FileFormat -FilePath $jsonFilePath
Write-Host "Format détecté: $format"

# Tester la détection d'encodage
$encodingInfo = Get-FileEncoding -FilePath $jsonFilePath
Write-Host "Encodage détecté: $($encodingInfo.encoding)"
Write-Host "Type de fichier détecté: $($encodingInfo.file_type)"

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force

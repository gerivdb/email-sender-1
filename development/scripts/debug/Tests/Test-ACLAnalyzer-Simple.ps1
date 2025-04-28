# Test simple pour ACLAnalyzer.ps1
# Importer le module Ã  tester
$scriptPath = Split-Path -Parent $PSCommandPath
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ACLAnalyzer.ps1"
. $modulePath

# CrÃ©er un dossier de test unique
$testGuid = [System.Guid]::NewGuid().ToString()
$testFolder = Join-Path -Path $env:TEMP -ChildPath "ACLTest_$testGuid"
$testFile = Join-Path -Path $testFolder -ChildPath "testfile.txt"

# CrÃ©er le dossier et le fichier pour les tests
New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
"Test content" | Out-File -FilePath $testFile -Encoding utf8

# Test simple pour Get-NTFSPermission
Write-Host "Test 1: Get-NTFSPermission sur un dossier"
$result = Get-NTFSPermission -Path $testFolder -Recurse $false
if ($result) {
    Write-Host "  RÃ‰USSI: Get-NTFSPermission a retournÃ© des rÃ©sultats pour $testFolder" -ForegroundColor Green
} else {
    Write-Host "  Ã‰CHEC: Get-NTFSPermission n'a pas retournÃ© de rÃ©sultats" -ForegroundColor Red
}

# Test simple pour Get-NTFSPermissionInheritance
Write-Host "Test 2: Get-NTFSPermissionInheritance sur un dossier"
$result = Get-NTFSPermissionInheritance -Path $testFolder -Recurse $false
if ($result) {
    Write-Host "  RÃ‰USSI: Get-NTFSPermissionInheritance a retournÃ© des rÃ©sultats pour $testFolder" -ForegroundColor Green
} else {
    Write-Host "  Ã‰CHEC: Get-NTFSPermissionInheritance n'a pas retournÃ© de rÃ©sultats" -ForegroundColor Red
}

# Test simple pour Get-NTFSOwnershipInfo
Write-Host "Test 3: Get-NTFSOwnershipInfo sur un dossier"
$result = Get-NTFSOwnershipInfo -Path $testFolder -Recurse $false
if ($result) {
    Write-Host "  RÃ‰USSI: Get-NTFSOwnershipInfo a retournÃ© des rÃ©sultats pour $testFolder" -ForegroundColor Green
} else {
    Write-Host "  Ã‰CHEC: Get-NTFSOwnershipInfo n'a pas retournÃ© de rÃ©sultats" -ForegroundColor Red
}

# Test simple pour Find-NTFSPermissionAnomaly
Write-Host "Test 4: Find-NTFSPermissionAnomaly sur un dossier"
$result = Find-NTFSPermissionAnomaly -Path $testFolder -Recurse $false
if ($result -ne $null) {
    Write-Host "  RÃ‰USSI: Find-NTFSPermissionAnomaly a Ã©tÃ© exÃ©cutÃ© sans erreur" -ForegroundColor Green
} else {
    Write-Host "  INFORMATION: Find-NTFSPermissionAnomaly n'a pas trouvÃ© d'anomalies" -ForegroundColor Yellow
}

# Test simple pour New-NTFSPermissionReport
Write-Host "Test 5: New-NTFSPermissionReport sur un dossier"
$result = New-NTFSPermissionReport -Path $testFolder -OutputFormat "Text"
if ($result) {
    Write-Host "  RÃ‰USSI: New-NTFSPermissionReport a retournÃ© des rÃ©sultats pour $testFolder" -ForegroundColor Green
} else {
    Write-Host "  Ã‰CHEC: New-NTFSPermissionReport n'a pas retournÃ© de rÃ©sultats" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "Nettoyage des fichiers de test..."
Remove-Item -Path $testFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Tests terminÃ©s."

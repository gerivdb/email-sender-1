# Test simple pour ACLAnalyzer.ps1
# Importer le module à tester
$scriptPath = Split-Path -Parent $PSCommandPath
$modulePath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "ACLAnalyzer.ps1"
. $modulePath

# Créer un dossier de test unique
$testGuid = [System.Guid]::NewGuid().ToString()
$testFolder = Join-Path -Path $env:TEMP -ChildPath "ACLTest_$testGuid"
$testFile = Join-Path -Path $testFolder -ChildPath "testfile.txt"

# Créer le dossier et le fichier pour les tests
New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
"Test content" | Out-File -FilePath $testFile -Encoding utf8

# Test simple pour Get-NTFSPermission
Write-Host "Test 1: Get-NTFSPermission sur un dossier"
$result = Get-NTFSPermission -Path $testFolder -Recurse $false
if ($result) {
    Write-Host "  RÉUSSI: Get-NTFSPermission a retourné des résultats pour $testFolder" -ForegroundColor Green
} else {
    Write-Host "  ÉCHEC: Get-NTFSPermission n'a pas retourné de résultats" -ForegroundColor Red
}

# Test simple pour Get-NTFSPermissionInheritance
Write-Host "Test 2: Get-NTFSPermissionInheritance sur un dossier"
$result = Get-NTFSPermissionInheritance -Path $testFolder -Recurse $false
if ($result) {
    Write-Host "  RÉUSSI: Get-NTFSPermissionInheritance a retourné des résultats pour $testFolder" -ForegroundColor Green
} else {
    Write-Host "  ÉCHEC: Get-NTFSPermissionInheritance n'a pas retourné de résultats" -ForegroundColor Red
}

# Test simple pour Get-NTFSOwnershipInfo
Write-Host "Test 3: Get-NTFSOwnershipInfo sur un dossier"
$result = Get-NTFSOwnershipInfo -Path $testFolder -Recurse $false
if ($result) {
    Write-Host "  RÉUSSI: Get-NTFSOwnershipInfo a retourné des résultats pour $testFolder" -ForegroundColor Green
} else {
    Write-Host "  ÉCHEC: Get-NTFSOwnershipInfo n'a pas retourné de résultats" -ForegroundColor Red
}

# Test simple pour Find-NTFSPermissionAnomaly
Write-Host "Test 4: Find-NTFSPermissionAnomaly sur un dossier"
$result = Find-NTFSPermissionAnomaly -Path $testFolder -Recurse $false
if ($result -ne $null) {
    Write-Host "  RÉUSSI: Find-NTFSPermissionAnomaly a été exécuté sans erreur" -ForegroundColor Green
} else {
    Write-Host "  INFORMATION: Find-NTFSPermissionAnomaly n'a pas trouvé d'anomalies" -ForegroundColor Yellow
}

# Test simple pour New-NTFSPermissionReport
Write-Host "Test 5: New-NTFSPermissionReport sur un dossier"
$result = New-NTFSPermissionReport -Path $testFolder -OutputFormat "Text"
if ($result) {
    Write-Host "  RÉUSSI: New-NTFSPermissionReport a retourné des résultats pour $testFolder" -ForegroundColor Green
} else {
    Write-Host "  ÉCHEC: New-NTFSPermissionReport n'a pas retourné de résultats" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "Nettoyage des fichiers de test..."
Remove-Item -Path $testFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Tests terminés."

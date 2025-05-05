# Test du module EncryptionUtils
Write-Host "Test du module EncryptionUtils" -ForegroundColor Green

# Importer le module
$scriptPath = $MyInvocation.MyCommand.Path
$testRoot = Split-Path -Parent $scriptPath
$manualTestRoot = Split-Path -Parent $testRoot
$projectRoot = Split-Path -Parent $manualTestRoot
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
Write-Host "Chemin du projet : $projectRoot" -ForegroundColor Cyan
$encryptionUtilsPath = Join-Path -Path $modulesPath -ChildPath "EncryptionUtils.ps1"

Write-Host "Chemin du module : $encryptionUtilsPath" -ForegroundColor Cyan
if (-not (Test-Path -Path $encryptionUtilsPath)) {
    Write-Error "Le module EncryptionUtils.ps1 n'existe pas au chemin spÃ©cifiÃ©."
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$tempDir = Join-Path -Path $env:TEMP -ChildPath "EncryptionTest"
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
}
New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

# CrÃ©er un fichier de test
$testFilePath = Join-Path -Path $tempDir -ChildPath "test.txt"
$testContent = "Ceci est un fichier de test pour le chiffrement."
Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8

# Charger les fonctions du module
. $encryptionUtilsPath

# Tester la fonction New-EncryptionKey
Write-Host "Test de New-EncryptionKey..." -ForegroundColor Yellow
$password = ConvertTo-SecureString -String "TestPassword" -AsPlainText -Force
$key = New-EncryptionKey -Password $password
Write-Host "ClÃ© gÃ©nÃ©rÃ©e : $($key.KeyBase64)" -ForegroundColor Cyan

# Tester la fonction Protect-String
Write-Host "Test de Protect-String..." -ForegroundColor Yellow
$originalString = "DonnÃ©es sensibles Ã  chiffrer"
$encryptedString = Protect-String -InputString $originalString -EncryptionKey $key
Write-Host "ChaÃ®ne chiffrÃ©e : $encryptedString" -ForegroundColor Cyan

# Tester la fonction Unprotect-String
Write-Host "Test de Unprotect-String..." -ForegroundColor Yellow
$decryptedString = Unprotect-String -EncryptedString $encryptedString -EncryptionKey $key
Write-Host "ChaÃ®ne dÃ©chiffrÃ©e : $decryptedString" -ForegroundColor Cyan
Write-Host "Correspondance : $($originalString -eq $decryptedString)" -ForegroundColor $(if ($originalString -eq $decryptedString) { "Green" } else { "Red" })

# Tester la fonction Protect-File
Write-Host "Test de Protect-File..." -ForegroundColor Yellow
$encryptedFilePath = Join-Path -Path $tempDir -ChildPath "test.enc"
$encryptResult = Protect-File -InputFile $testFilePath -OutputFile $encryptedFilePath -EncryptionKey $key
Write-Host "RÃ©sultat du chiffrement : $encryptResult" -ForegroundColor $(if ($encryptResult) { "Green" } else { "Red" })

# Tester la fonction Unprotect-File
Write-Host "Test de Unprotect-File..." -ForegroundColor Yellow
$decryptedFilePath = Join-Path -Path $tempDir -ChildPath "test_decrypted.txt"
$decryptResult = Unprotect-File -InputFile $encryptedFilePath -OutputFile $decryptedFilePath -EncryptionKey $key
Write-Host "RÃ©sultat du dÃ©chiffrement : $decryptResult" -ForegroundColor $(if ($decryptResult) { "Green" } else { "Red" })

# VÃ©rifier que le contenu est identique
$originalContent = Get-Content -Path $testFilePath -Raw
$decryptedContent = Get-Content -Path $decryptedFilePath -Raw
Write-Host "Correspondance du contenu : $($originalContent -eq $decryptedContent)" -ForegroundColor $(if ($originalContent -eq $decryptedContent) { "Green" } else { "Red" })

# Tester la fonction Get-FileHash
Write-Host "Test de Get-FileHash..." -ForegroundColor Yellow
$hash = Get-FileHash -FilePath $testFilePath -Algorithm "SHA256"
Write-Host "Hachage du fichier : $($hash.Hash)" -ForegroundColor Cyan

# Tester la fonction New-FileSignature
Write-Host "Test de New-FileSignature..." -ForegroundColor Yellow
$signatureFilePath = Join-Path -Path $tempDir -ChildPath "test.sig"
$signature = New-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
Write-Host "Signature gÃ©nÃ©rÃ©e : $signature" -ForegroundColor Cyan

# Tester la fonction Test-FileSignature
Write-Host "Test de Test-FileSignature..." -ForegroundColor Yellow
$verifyResult = Test-FileSignature -FilePath $testFilePath -EncryptionKey $key -SignatureFile $signatureFilePath
Write-Host "RÃ©sultat de la vÃ©rification : $($verifyResult.IsValid)" -ForegroundColor $(if ($verifyResult.IsValid) { "Green" } else { "Red" })

# Nettoyer
Write-Host "Nettoyage..." -ForegroundColor Yellow
Remove-Item -Path $tempDir -Recurse -Force

Write-Host "Tests terminÃ©s." -ForegroundColor Green

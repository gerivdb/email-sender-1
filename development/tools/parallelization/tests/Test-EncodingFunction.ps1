# Script de test simple pour la fonction Initialize-EncodingSettings
# Ce script teste manuellement la fonction sans dépendre de Pester

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Afficher les informations d'encodage avant l'initialisation
Write-Host "=== Encodage avant initialisation ===" -ForegroundColor Cyan
Write-Host "OutputEncoding: $($OutputEncoding.WebName)" -ForegroundColor Yellow
Write-Host "Console::OutputEncoding: $([Console]::OutputEncoding.WebName)" -ForegroundColor Yellow
Write-Host "PSDefaultParameterValues['Out-File:Encoding']: $($PSDefaultParameterValues['Out-File:Encoding'])" -ForegroundColor Yellow
Write-Host ""

# Exécuter la fonction à tester
Write-Host "=== Exécution de Initialize-EncodingSettings ===" -ForegroundColor Cyan
$result = Initialize-EncodingSettings -Verbose
Write-Host "Résultat: $($result | ConvertTo-Json -Depth 3)" -ForegroundColor Green
Write-Host ""

# Afficher les informations d'encodage après l'initialisation
Write-Host "=== Encodage après initialisation ===" -ForegroundColor Cyan
Write-Host "OutputEncoding: $($OutputEncoding.WebName)" -ForegroundColor Yellow
Write-Host "Console::OutputEncoding: $([Console]::OutputEncoding.WebName)" -ForegroundColor Yellow
Write-Host "PSDefaultParameterValues['Out-File:Encoding']: $($PSDefaultParameterValues['Out-File:Encoding'])" -ForegroundColor Yellow
Write-Host ""

# Tester l'affichage des caractères accentués
Write-Host "=== Test d'affichage des caractères accentués ===" -ForegroundColor Cyan
Write-Host "éèêëàâäùûüôöçÉÈÊËÀÂÄÙÛÜÔÖÇ" -ForegroundColor Green
Write-Host ""

# Tester l'écriture et la lecture de fichiers avec des caractères accentués
Write-Host "=== Test d'écriture et de lecture de fichiers avec des caractères accentués ===" -ForegroundColor Cyan
$tempFile = Join-Path -Path $env:TEMP -ChildPath "test_encoding_$(Get-Random).txt"
$testString = "Caractères accentués : éèêëàâäùûüôöçÉÈÊËÀÂÄÙÛÜÔÖÇ"

# Écrire dans le fichier
$testString | Out-File -FilePath $tempFile
Write-Host "Fichier écrit: $tempFile" -ForegroundColor Yellow

# Lire le contenu du fichier
$content = Get-Content -Path $tempFile -Raw
Write-Host "Contenu lu: $content" -ForegroundColor Yellow

# Vérifier que les caractères accentués sont préservés
$success = $content.Trim() -eq $testString
Write-Host "Test réussi: $success" -ForegroundColor $(if ($success) { "Green" } else { "Red" })

# Nettoyer
Remove-Item -Path $tempFile -Force
Write-Host "Fichier temporaire supprimé" -ForegroundColor Yellow
Write-Host ""

# Tester avec System.IO.File
Write-Host "=== Test avec System.IO.File ===" -ForegroundColor Cyan
$tempFile2 = Join-Path -Path $env:TEMP -ChildPath "test_encoding2_$(Get-Random).txt"

# Créer un encodeur UTF-8 avec BOM
$utf8WithBom = New-Object System.Text.UTF8Encoding $true

# Écrire dans le fichier
[System.IO.File]::WriteAllText($tempFile2, $testString, $utf8WithBom)
Write-Host "Fichier écrit avec System.IO.File: $tempFile2" -ForegroundColor Yellow

# Lire le contenu du fichier
$content2 = [System.IO.File]::ReadAllText($tempFile2)
Write-Host "Contenu lu avec System.IO.File: $content2" -ForegroundColor Yellow

# Vérifier que les caractères accentués sont préservés
$success2 = $content2 -eq $testString
Write-Host "Test réussi: $success2" -ForegroundColor $(if ($success2) { "Green" } else { "Red" })

# Nettoyer
Remove-Item -Path $tempFile2 -Force
Write-Host "Fichier temporaire supprimé" -ForegroundColor Yellow
Write-Host ""

# Résumé
Write-Host "=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Test d'initialisation: $($result.Success)" -ForegroundColor $(if ($result.Success) { "Green" } else { "Red" })
Write-Host "Test d'écriture/lecture de fichier: $success" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
Write-Host "Test avec System.IO.File: $success2" -ForegroundColor $(if ($success2) { "Green" } else { "Red" })
Write-Host ""

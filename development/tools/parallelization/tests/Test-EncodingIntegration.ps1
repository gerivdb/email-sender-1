# Script de test pour vérifier l'intégration de Initialize-EncodingSettings dans Initialize-UnifiedParallel
# Ce script teste manuellement l'intégration sans dépendre de Pester

# Fonction pour afficher les informations d'encodage
function Show-EncodingInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host "=== $Title ===" -ForegroundColor Cyan
    Write-Host "OutputEncoding: $($OutputEncoding.WebName)" -ForegroundColor Yellow
    Write-Host "Console::OutputEncoding: $([Console]::OutputEncoding.WebName)" -ForegroundColor Yellow
    Write-Host "PSDefaultParameterValues['Out-File:Encoding']: $($PSDefaultParameterValues['Out-File:Encoding'])" -ForegroundColor Yellow
    Write-Host "PSDefaultParameterValues['Set-Content:Encoding']: $($PSDefaultParameterValues['Set-Content:Encoding'])" -ForegroundColor Yellow
    Write-Host "PSDefaultParameterValues['Add-Content:Encoding']: $($PSDefaultParameterValues['Add-Content:Encoding'])" -ForegroundColor Yellow
    Write-Host "PSDefaultParameterValues['Export-Csv:Encoding']: $($PSDefaultParameterValues['Export-Csv:Encoding'])" -ForegroundColor Yellow
    Write-Host ""
}

# Fonction pour tester l'écriture et la lecture de fichiers avec des caractères accentués
function Test-FileEncoding {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title
    )

    Write-Host "=== $Title ===" -ForegroundColor Cyan
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

    return $success
}

# Sauvegarder les paramètres initiaux
$originalOutputEncoding = $OutputEncoding
$originalConsoleEncoding = [Console]::OutputEncoding
$originalDefaultParams = $PSDefaultParameterValues.Clone()

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Afficher les informations d'encodage avant l'initialisation du module
Show-EncodingInfo "Encodage avant initialisation du module"

# Test 1: Initialisation normale
Write-Host "=== Test 1: Initialisation normale du module ===" -ForegroundColor Cyan
$result1 = Initialize-UnifiedParallel -Verbose
Write-Host "Module initialisé avec succès" -ForegroundColor Green
Write-Host ""

# Afficher les informations d'encodage après l'initialisation du module
Show-EncodingInfo "Encodage après initialisation normale du module"

# Tester l'affichage des caractères accentués
Write-Host "=== Test d'affichage des caractères accentués ===" -ForegroundColor Cyan
Write-Host "éèêëàâäùûüôöçÉÈÊËÀÂÄÙÛÜÔÖÇ" -ForegroundColor Green
Write-Host ""

# Tester l'écriture et la lecture de fichiers avec des caractères accentués
$test1Success = Test-FileEncoding "Test d'écriture et de lecture de fichiers après initialisation normale"

# Nettoyer le module
Write-Host "=== Nettoyage du module UnifiedParallel ===" -ForegroundColor Cyan
Clear-UnifiedParallel -Verbose
Write-Host "Module nettoyé avec succès" -ForegroundColor Green
Write-Host ""

# Réinitialiser les paramètres
$OutputEncoding = $originalOutputEncoding
$PSDefaultParameterValues = @{}
[Console]::OutputEncoding = $originalConsoleEncoding

# Test 2: Initialisation avec Force
Write-Host "=== Test 2: Initialisation du module avec Force ===" -ForegroundColor Cyan
$result2 = Initialize-UnifiedParallel -Force -Verbose
Write-Host "Module initialisé avec succès (Force)" -ForegroundColor Green
Write-Host ""

# Afficher les informations d'encodage après l'initialisation du module
Show-EncodingInfo "Encodage après initialisation du module avec Force"

# Tester l'écriture et la lecture de fichiers avec des caractères accentués
$test2Success = Test-FileEncoding "Test d'écriture et de lecture de fichiers après initialisation avec Force"

# Nettoyer le module
Write-Host "=== Nettoyage du module UnifiedParallel ===" -ForegroundColor Cyan
Clear-UnifiedParallel -Verbose
Write-Host "Module nettoyé avec succès" -ForegroundColor Green
Write-Host ""

# Restaurer les paramètres originaux
$OutputEncoding = $originalOutputEncoding
[Console]::OutputEncoding = $originalConsoleEncoding
$PSDefaultParameterValues = $originalDefaultParams

# Résumé
Write-Host "=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Test 1 (Initialisation normale): $test1Success" -ForegroundColor $(if ($test1Success) { "Green" } else { "Red" })
Write-Host "Test 2 (Initialisation avec Force): $test2Success" -ForegroundColor $(if ($test2Success) { "Green" } else { "Red" })
Write-Host ""

# Script de test pour la fonction Initialize-EncodingSettings avec différents paramètres
# Ce script teste manuellement la fonction sans dépendre de Pester

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

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

# Réinitialiser les paramètres par défaut
$PSDefaultParameterValues = @{}

# Afficher les informations d'encodage avant l'initialisation
Show-EncodingInfo "Encodage avant initialisation"

# Test 1: Paramètres par défaut
Write-Host "=== Test 1: Paramètres par défaut ===" -ForegroundColor Cyan
$result1 = Initialize-EncodingSettings -Verbose
Write-Host "Résultat: $($result1 | ConvertTo-Json -Depth 3)" -ForegroundColor Green
Write-Host ""

# Afficher les informations d'encodage après l'initialisation
Show-EncodingInfo "Encodage après initialisation avec paramètres par défaut"

# Tester l'écriture et la lecture de fichiers avec des caractères accentués
$test1Success = Test-FileEncoding "Test d'écriture et de lecture de fichiers avec paramètres par défaut"

# Réinitialiser les paramètres
$OutputEncoding = $originalOutputEncoding
$PSDefaultParameterValues = @{}
[Console]::OutputEncoding = $originalConsoleEncoding

# Test 2: Sans BOM
Write-Host "=== Test 2: Sans BOM ===" -ForegroundColor Cyan
$result2 = Initialize-EncodingSettings -UseBOM $false -Verbose
Write-Host "Résultat: $($result2 | ConvertTo-Json -Depth 3)" -ForegroundColor Green
Write-Host ""

# Afficher les informations d'encodage
Show-EncodingInfo "Encodage après initialisation sans BOM"

# Tester l'écriture et la lecture de fichiers avec des caractères accentués
$test2Success = Test-FileEncoding "Test d'écriture et de lecture de fichiers sans BOM"

# Réinitialiser les paramètres
$OutputEncoding = $originalOutputEncoding
$PSDefaultParameterValues = @{}
[Console]::OutputEncoding = $originalConsoleEncoding

# Test 3: Sans configurer la console
Write-Host "=== Test 3: Sans configurer la console ===" -ForegroundColor Cyan
$result3 = Initialize-EncodingSettings -ConfigureConsole $false -Verbose
Write-Host "Résultat: $($result3 | ConvertTo-Json -Depth 3)" -ForegroundColor Green
Write-Host ""

# Afficher les informations d'encodage
Show-EncodingInfo "Encodage après initialisation sans configurer la console"

# Tester l'écriture et la lecture de fichiers avec des caractères accentués
$test3Success = Test-FileEncoding "Test d'écriture et de lecture de fichiers sans configurer la console"

# Réinitialiser les paramètres
$OutputEncoding = $originalOutputEncoding
$PSDefaultParameterValues = @{}
[Console]::OutputEncoding = $originalConsoleEncoding

# Test 4: Sans configurer les paramètres par défaut
Write-Host "=== Test 4: Sans configurer les paramètres par défaut ===" -ForegroundColor Cyan
$result4 = Initialize-EncodingSettings -ConfigureDefaultParameters $false -Verbose
Write-Host "Résultat: $($result4 | ConvertTo-Json -Depth 3)" -ForegroundColor Green
Write-Host ""

# Afficher les informations d'encodage
Show-EncodingInfo "Encodage après initialisation sans configurer les paramètres par défaut"

# Tester l'écriture et la lecture de fichiers avec des caractères accentués
$test4Success = Test-FileEncoding "Test d'écriture et de lecture de fichiers sans configurer les paramètres par défaut"

# Restaurer les paramètres originaux
$OutputEncoding = $originalOutputEncoding
[Console]::OutputEncoding = $originalConsoleEncoding
$PSDefaultParameterValues = $originalDefaultParams

# Résumé
Write-Host "=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "Test 1 (Paramètres par défaut): $test1Success" -ForegroundColor $(if ($test1Success) { "Green" } else { "Red" })
Write-Host "Test 2 (Sans BOM): $test2Success" -ForegroundColor $(if ($test2Success) { "Green" } else { "Red" })
Write-Host "Test 3 (Sans configurer la console): $test3Success" -ForegroundColor $(if ($test3Success) { "Green" } else { "Red" })
Write-Host "Test 4 (Sans configurer les paramètres par défaut): $test4Success" -ForegroundColor $(if ($test4Success) { "Green" } else { "Red" })
Write-Host ""

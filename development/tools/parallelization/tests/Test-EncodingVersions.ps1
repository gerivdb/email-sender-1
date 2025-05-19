# Script de test pour vérifier la gestion des différences entre PowerShell 5.1 et 7.x
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
    Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Magenta
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
        [string]$Title,
        
        [Parameter(Mandatory = $false)]
        [switch]$CheckBOM
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
    Write-Host "Test de contenu réussi: $success" -ForegroundColor $(if ($success) { "Green" } else { "Red" })
    
    # Vérifier la présence du BOM si demandé
    if ($CheckBOM) {
        $bytes = [System.IO.File]::ReadAllBytes($tempFile)
        $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
        Write-Host "Présence du BOM: $hasBOM" -ForegroundColor $(if ($hasBOM) { "Green" } else { "Red" })
        $success = $success -and $hasBOM
    }
    
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
$test1Success = Test-FileEncoding "Test d'écriture et de lecture de fichiers avec paramètres par défaut" -CheckBOM

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
$test2Success = Test-FileEncoding "Test d'écriture et de lecture de fichiers sans BOM" -CheckBOM

# Restaurer les paramètres originaux
$OutputEncoding = $originalOutputEncoding
[Console]::OutputEncoding = $originalConsoleEncoding
$PSDefaultParameterValues = $originalDefaultParams

# Résumé
Write-Host "=== Résumé des tests ===" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Magenta
Write-Host "Test 1 (Paramètres par défaut): $test1Success" -ForegroundColor $(if ($test1Success) { "Green" } else { "Red" })
Write-Host "Test 2 (Sans BOM): $test2Success" -ForegroundColor $(if ($test2Success) { "Green" } else { "Red" })
Write-Host ""

# Afficher des informations sur les différences entre PowerShell 5.1 et 7.x
Write-Host "=== Différences entre PowerShell 5.1 et 7.x ===" -ForegroundColor Cyan
Write-Host "PowerShell 5.1 :" -ForegroundColor Yellow
Write-Host "- Utilise 'utf8' pour UTF-8 avec BOM" -ForegroundColor Yellow
Write-Host "- N'a pas de paramètre pour UTF-8 sans BOM" -ForegroundColor Yellow
Write-Host "- Nécessite de configurer manuellement `$OutputEncoding et [Console]::OutputEncoding" -ForegroundColor Yellow
Write-Host ""
Write-Host "PowerShell 7.x :" -ForegroundColor Yellow
Write-Host "- Utilise 'utf8BOM' pour UTF-8 avec BOM" -ForegroundColor Yellow
Write-Host "- Utilise 'utf8NoBOM' pour UTF-8 sans BOM" -ForegroundColor Yellow
Write-Host "- Utilise UTF-8 par défaut, mais il est recommandé de configurer explicitement" -ForegroundColor Yellow
Write-Host ""

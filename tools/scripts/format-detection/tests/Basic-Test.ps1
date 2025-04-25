#Requires -Version 5.1
<#
.SYNOPSIS
    Test basique des fonctionnalités de détection de format et d'encodage.

.DESCRIPTION
    Ce script teste de manière basique les fonctionnalités de détection de format et d'encodage
    en vérifiant simplement que les scripts existent et peuvent être chargés.

.EXAMPLE
    .\Basic-Test.ps1

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param()

# Chemins des scripts à tester
$encodingScriptPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\analysis\Detect-FileEncoding.ps1"
$formatScriptPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\analysis\Improved-FormatDetection.ps1"

# Vérifier si les scripts à tester existent
$encodingScriptExists = Test-Path -Path $encodingScriptPath -PathType Leaf
$formatScriptExists = Test-Path -Path $formatScriptPath -PathType Leaf

Write-Host "Vérification des scripts à tester..." -ForegroundColor Cyan
Write-Host "  Script de détection d'encodage : $(if ($encodingScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($encodingScriptExists) { 'Green' } else { 'Red' })
Write-Host "  Script de détection de format : $(if ($formatScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($formatScriptExists) { 'Green' } else { 'Red' })

# Tester le chargement des scripts
$encodingScriptLoaded = $false
$formatScriptLoaded = $false

if ($encodingScriptExists) {
    try {
        Write-Host "`nTest du chargement du script de détection d'encodage..." -ForegroundColor Cyan
        $encodingScriptContent = Get-Content -Path $encodingScriptPath -Raw
        $encodingScriptLoaded = $true
        Write-Host "  Le script de détection d'encodage a été chargé avec succès." -ForegroundColor Green
    }
    catch {
        Write-Host "  Erreur lors du chargement du script de détection d'encodage : $_" -ForegroundColor Red
    }
}

if ($formatScriptExists) {
    try {
        Write-Host "`nTest du chargement du script de détection de format..." -ForegroundColor Cyan
        $formatScriptContent = Get-Content -Path $formatScriptPath -Raw
        $formatScriptLoaded = $true
        Write-Host "  Le script de détection de format a été chargé avec succès." -ForegroundColor Green
    }
    catch {
        Write-Host "  Erreur lors du chargement du script de détection de format : $_" -ForegroundColor Red
    }
}

# Vérifier la présence de fonctions clés dans les scripts
$encodingFunctionFound = $false
$formatFunctionFound = $false

if ($encodingScriptLoaded) {
    if ($encodingScriptContent -match "function\s+Get-FileEncoding") {
        $encodingFunctionFound = $true
        Write-Host "  La fonction Get-FileEncoding a été trouvée dans le script." -ForegroundColor Green
    }
    else {
        Write-Host "  La fonction Get-FileEncoding n'a pas été trouvée dans le script." -ForegroundColor Red
    }
}

if ($formatScriptLoaded) {
    # Le script Improved-FormatDetection.ps1 est lui-même une fonction, vérifions s'il contient les éléments clés
    if ($formatScriptContent -match "\[CmdletBinding\(\)\]" -and $formatScriptContent -match "param\(" -and $formatScriptContent -match "Mandatory") {
        $formatFunctionFound = $true
        Write-Host "  Le script de détection de format contient les éléments d'une fonction." -ForegroundColor Green
    }
    else {
        Write-Host "  Le script de détection de format ne contient pas les éléments d'une fonction." -ForegroundColor Red
    }
}

# Afficher un résumé
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "  Script de détection d'encodage : $(if ($encodingScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($encodingScriptExists) { 'Green' } else { 'Red' })
Write-Host "  Script de détection d'encodage chargé : $(if ($encodingScriptLoaded) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($encodingScriptLoaded) { 'Green' } else { 'Red' })
Write-Host "  Fonction Get-FileEncoding trouvée : $(if ($encodingFunctionFound) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($encodingFunctionFound) { 'Green' } else { 'Red' })
Write-Host "  Script de détection de format : $(if ($formatScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($formatScriptExists) { 'Green' } else { 'Red' })
Write-Host "  Script de détection de format chargé : $(if ($formatScriptLoaded) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($formatScriptLoaded) { 'Green' } else { 'Red' })
Write-Host "  Éléments de fonction dans le script de format : $(if ($formatFunctionFound) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($formatFunctionFound) { 'Green' } else { 'Red' })

# Résultat global
$allTestsPassed = $encodingScriptExists -and $encodingScriptLoaded -and $encodingFunctionFound -and $formatScriptExists -and $formatScriptLoaded -and $formatFunctionFound
Write-Host "`nRésultat global : $(if ($allTestsPassed) { 'SUCCÈS' } else { 'ÉCHEC' })" -ForegroundColor $(if ($allTestsPassed) { 'Green' } else { 'Red' })

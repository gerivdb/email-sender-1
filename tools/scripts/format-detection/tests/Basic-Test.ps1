#Requires -Version 5.1
<#
.SYNOPSIS
    Test basique des fonctionnalitÃ©s de dÃ©tection de format et d'encodage.

.DESCRIPTION
    Ce script teste de maniÃ¨re basique les fonctionnalitÃ©s de dÃ©tection de format et d'encodage
    en vÃ©rifiant simplement que les scripts existent et peuvent Ãªtre chargÃ©s.

.EXAMPLE
    .\Basic-Test.ps1

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param()

# Chemins des scripts Ã  tester
$encodingScriptPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\analysis\Detect-FileEncoding.ps1"
$formatScriptPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\analysis\Improved-FormatDetection.ps1"

# VÃ©rifier si les scripts Ã  tester existent
$encodingScriptExists = Test-Path -Path $encodingScriptPath -PathType Leaf
$formatScriptExists = Test-Path -Path $formatScriptPath -PathType Leaf

Write-Host "VÃ©rification des scripts Ã  tester..." -ForegroundColor Cyan
Write-Host "  Script de dÃ©tection d'encodage : $(if ($encodingScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($encodingScriptExists) { 'Green' } else { 'Red' })
Write-Host "  Script de dÃ©tection de format : $(if ($formatScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($formatScriptExists) { 'Green' } else { 'Red' })

# Tester le chargement des scripts
$encodingScriptLoaded = $false
$formatScriptLoaded = $false

if ($encodingScriptExists) {
    try {
        Write-Host "`nTest du chargement du script de dÃ©tection d'encodage..." -ForegroundColor Cyan
        $encodingScriptContent = Get-Content -Path $encodingScriptPath -Raw
        $encodingScriptLoaded = $true
        Write-Host "  Le script de dÃ©tection d'encodage a Ã©tÃ© chargÃ© avec succÃ¨s." -ForegroundColor Green
    }
    catch {
        Write-Host "  Erreur lors du chargement du script de dÃ©tection d'encodage : $_" -ForegroundColor Red
    }
}

if ($formatScriptExists) {
    try {
        Write-Host "`nTest du chargement du script de dÃ©tection de format..." -ForegroundColor Cyan
        $formatScriptContent = Get-Content -Path $formatScriptPath -Raw
        $formatScriptLoaded = $true
        Write-Host "  Le script de dÃ©tection de format a Ã©tÃ© chargÃ© avec succÃ¨s." -ForegroundColor Green
    }
    catch {
        Write-Host "  Erreur lors du chargement du script de dÃ©tection de format : $_" -ForegroundColor Red
    }
}

# VÃ©rifier la prÃ©sence de fonctions clÃ©s dans les scripts
$encodingFunctionFound = $false
$formatFunctionFound = $false

if ($encodingScriptLoaded) {
    if ($encodingScriptContent -match "function\s+Get-FileEncoding") {
        $encodingFunctionFound = $true
        Write-Host "  La fonction Get-FileEncoding a Ã©tÃ© trouvÃ©e dans le script." -ForegroundColor Green
    }
    else {
        Write-Host "  La fonction Get-FileEncoding n'a pas Ã©tÃ© trouvÃ©e dans le script." -ForegroundColor Red
    }
}

if ($formatScriptLoaded) {
    # Le script Improved-FormatDetection.ps1 est lui-mÃªme une fonction, vÃ©rifions s'il contient les Ã©lÃ©ments clÃ©s
    if ($formatScriptContent -match "\[CmdletBinding\(\)\]" -and $formatScriptContent -match "param\(" -and $formatScriptContent -match "Mandatory") {
        $formatFunctionFound = $true
        Write-Host "  Le script de dÃ©tection de format contient les Ã©lÃ©ments d'une fonction." -ForegroundColor Green
    }
    else {
        Write-Host "  Le script de dÃ©tection de format ne contient pas les Ã©lÃ©ments d'une fonction." -ForegroundColor Red
    }
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
Write-Host "  Script de dÃ©tection d'encodage : $(if ($encodingScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($encodingScriptExists) { 'Green' } else { 'Red' })
Write-Host "  Script de dÃ©tection d'encodage chargÃ© : $(if ($encodingScriptLoaded) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($encodingScriptLoaded) { 'Green' } else { 'Red' })
Write-Host "  Fonction Get-FileEncoding trouvÃ©e : $(if ($encodingFunctionFound) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($encodingFunctionFound) { 'Green' } else { 'Red' })
Write-Host "  Script de dÃ©tection de format : $(if ($formatScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($formatScriptExists) { 'Green' } else { 'Red' })
Write-Host "  Script de dÃ©tection de format chargÃ© : $(if ($formatScriptLoaded) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($formatScriptLoaded) { 'Green' } else { 'Red' })
Write-Host "  Ã‰lÃ©ments de fonction dans le script de format : $(if ($formatFunctionFound) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($formatFunctionFound) { 'Green' } else { 'Red' })

# RÃ©sultat global
$allTestsPassed = $encodingScriptExists -and $encodingScriptLoaded -and $encodingFunctionFound -and $formatScriptExists -and $formatScriptLoaded -and $formatFunctionFound
Write-Host "`nRÃ©sultat global : $(if ($allTestsPassed) { 'SUCCÃˆS' } else { 'Ã‰CHEC' })" -ForegroundColor $(if ($allTestsPassed) { 'Green' } else { 'Red' })

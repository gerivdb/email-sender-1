#Requires -Version 5.1
<#
.SYNOPSIS
    Test fonctionnel simplifiÃ© des fonctionnalitÃ©s de dÃ©tection de format et d'encodage.

.DESCRIPTION
    Ce script teste de maniÃ¨re fonctionnelle simplifiÃ©e les fonctionnalitÃ©s de dÃ©tection de format et d'encodage
    en vÃ©rifiant que les scripts peuvent Ãªtre exÃ©cutÃ©s sans erreur.

.EXAMPLE
    .\Simple-Functional-Test.ps1

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

# Chemins des rÃ©pertoires d'Ã©chantillons
$samplesPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\samples"
$formatSamplesPath = Join-Path -Path $samplesPath -ChildPath "formats"
$encodingSamplesPath = Join-Path -Path $samplesPath -ChildPath "encodings"

# VÃ©rifier si les scripts Ã  tester existent
$encodingScriptExists = Test-Path -Path $encodingScriptPath -PathType Leaf
$formatScriptExists = Test-Path -Path $formatScriptPath -PathType Leaf

Write-Host "VÃ©rification des scripts Ã  tester..." -ForegroundColor Cyan
Write-Host "  Script de dÃ©tection d'encodage : $(if ($encodingScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($encodingScriptExists) { 'Green' } else { 'Red' })
Write-Host "  Script de dÃ©tection de format : $(if ($formatScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($formatScriptExists) { 'Green' } else { 'Red' })

if (-not $encodingScriptExists -or -not $formatScriptExists) {
    Write-Error "Les scripts Ã  tester n'existent pas."
    return
}

# VÃ©rifier si les rÃ©pertoires d'Ã©chantillons existent
$formatSamplesExist = Test-Path -Path $formatSamplesPath -PathType Container
$encodingSamplesExist = Test-Path -Path $encodingSamplesPath -PathType Container

Write-Host "`nVÃ©rification des rÃ©pertoires d'Ã©chantillons..." -ForegroundColor Cyan
Write-Host "  RÃ©pertoire d'Ã©chantillons de format : $(if ($formatSamplesExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($formatSamplesExist) { 'Green' } else { 'Red' })
Write-Host "  RÃ©pertoire d'Ã©chantillons d'encodage : $(if ($encodingSamplesExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($encodingSamplesExist) { 'Green' } else { 'Red' })

if (-not $formatSamplesExist -or -not $encodingSamplesExist) {
    Write-Warning "Les rÃ©pertoires d'Ã©chantillons n'existent pas. GÃ©nÃ©ration des Ã©chantillons..."
    $generateSamplesScript = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\Generate-TestSamples.ps1"
    if (Test-Path -Path $generateSamplesScript -PathType Leaf) {
        & $generateSamplesScript -Force
    }
    else {
        Write-Error "Le script de gÃ©nÃ©ration des Ã©chantillons n'existe pas : $generateSamplesScript"
        return
    }
}

# VÃ©rifier si les fichiers d'Ã©chantillon existent
$utf8BomPath = Join-Path -Path $encodingSamplesPath -ChildPath "utf8-bom.txt"
$xmlPath = Join-Path -Path $formatSamplesPath -ChildPath "sample.xml"

$utf8BomExists = Test-Path -Path $utf8BomPath -PathType Leaf
$xmlExists = Test-Path -Path $xmlPath -PathType Leaf

Write-Host "`nVÃ©rification des fichiers d'Ã©chantillon..." -ForegroundColor Cyan
Write-Host "  Fichier UTF-8 avec BOM : $(if ($utf8BomExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($utf8BomExists) { 'Green' } else { 'Red' })
Write-Host "  Fichier XML : $(if ($xmlExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($xmlExists) { 'Green' } else { 'Red' })

if (-not $utf8BomExists -or -not $xmlExists) {
    Write-Error "Les fichiers d'Ã©chantillon n'existent pas."
    return
}

# Tester l'exÃ©cution des scripts
$encodingScriptExecuted = $false
$formatScriptExecuted = $false

Write-Host "`nTest d'exÃ©cution des scripts..." -ForegroundColor Cyan

try {
    Write-Host "  ExÃ©cution du script de dÃ©tection d'encodage..." -ForegroundColor White
    $encodingResult = & $encodingScriptPath -FilePath $utf8BomPath
    $encodingScriptExecuted = $true
    Write-Host "  Le script de dÃ©tection d'encodage a Ã©tÃ© exÃ©cutÃ© avec succÃ¨s." -ForegroundColor Green
    Write-Host "  Encodage dÃ©tectÃ© : $($encodingResult.Encoding)" -ForegroundColor White
}
catch {
    Write-Host "  Erreur lors de l'exÃ©cution du script de dÃ©tection d'encodage : $_" -ForegroundColor Red
}

try {
    Write-Host "`n  ExÃ©cution du script de dÃ©tection de format..." -ForegroundColor White
    $formatResult = & $formatScriptPath -FilePath $xmlPath -DetailedOutput
    $formatScriptExecuted = $true
    Write-Host "  Le script de dÃ©tection de format a Ã©tÃ© exÃ©cutÃ© avec succÃ¨s." -ForegroundColor Green
    Write-Host "  Format dÃ©tectÃ© : $($formatResult.DetectedFormat)" -ForegroundColor White
    Write-Host "  CatÃ©gorie : $($formatResult.Category)" -ForegroundColor White
}
catch {
    Write-Host "  Erreur lors de l'exÃ©cution du script de dÃ©tection de format : $_" -ForegroundColor Red
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests fonctionnels simplifiÃ©s :" -ForegroundColor Cyan
Write-Host "  Script de dÃ©tection d'encodage exÃ©cutÃ© : $(if ($encodingScriptExecuted) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($encodingScriptExecuted) { 'Green' } else { 'Red' })
Write-Host "  Script de dÃ©tection de format exÃ©cutÃ© : $(if ($formatScriptExecuted) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($formatScriptExecuted) { 'Green' } else { 'Red' })

# RÃ©sultat global
$allTestsPassed = $encodingScriptExecuted -and $formatScriptExecuted
Write-Host "`nRÃ©sultat global : $(if ($allTestsPassed) { 'SUCCÃˆS' } else { 'Ã‰CHEC' })" -ForegroundColor $(if ($allTestsPassed) { 'Green' } else { 'Red' })

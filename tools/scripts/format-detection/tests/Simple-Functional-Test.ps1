#Requires -Version 5.1
<#
.SYNOPSIS
    Test fonctionnel simplifié des fonctionnalités de détection de format et d'encodage.

.DESCRIPTION
    Ce script teste de manière fonctionnelle simplifiée les fonctionnalités de détection de format et d'encodage
    en vérifiant que les scripts peuvent être exécutés sans erreur.

.EXAMPLE
    .\Simple-Functional-Test.ps1

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

# Chemins des répertoires d'échantillons
$samplesPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\samples"
$formatSamplesPath = Join-Path -Path $samplesPath -ChildPath "formats"
$encodingSamplesPath = Join-Path -Path $samplesPath -ChildPath "encodings"

# Vérifier si les scripts à tester existent
$encodingScriptExists = Test-Path -Path $encodingScriptPath -PathType Leaf
$formatScriptExists = Test-Path -Path $formatScriptPath -PathType Leaf

Write-Host "Vérification des scripts à tester..." -ForegroundColor Cyan
Write-Host "  Script de détection d'encodage : $(if ($encodingScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($encodingScriptExists) { 'Green' } else { 'Red' })
Write-Host "  Script de détection de format : $(if ($formatScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($formatScriptExists) { 'Green' } else { 'Red' })

if (-not $encodingScriptExists -or -not $formatScriptExists) {
    Write-Error "Les scripts à tester n'existent pas."
    return
}

# Vérifier si les répertoires d'échantillons existent
$formatSamplesExist = Test-Path -Path $formatSamplesPath -PathType Container
$encodingSamplesExist = Test-Path -Path $encodingSamplesPath -PathType Container

Write-Host "`nVérification des répertoires d'échantillons..." -ForegroundColor Cyan
Write-Host "  Répertoire d'échantillons de format : $(if ($formatSamplesExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($formatSamplesExist) { 'Green' } else { 'Red' })
Write-Host "  Répertoire d'échantillons d'encodage : $(if ($encodingSamplesExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($encodingSamplesExist) { 'Green' } else { 'Red' })

if (-not $formatSamplesExist -or -not $encodingSamplesExist) {
    Write-Warning "Les répertoires d'échantillons n'existent pas. Génération des échantillons..."
    $generateSamplesScript = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\Generate-TestSamples.ps1"
    if (Test-Path -Path $generateSamplesScript -PathType Leaf) {
        & $generateSamplesScript -Force
    }
    else {
        Write-Error "Le script de génération des échantillons n'existe pas : $generateSamplesScript"
        return
    }
}

# Vérifier si les fichiers d'échantillon existent
$utf8BomPath = Join-Path -Path $encodingSamplesPath -ChildPath "utf8-bom.txt"
$xmlPath = Join-Path -Path $formatSamplesPath -ChildPath "sample.xml"

$utf8BomExists = Test-Path -Path $utf8BomPath -PathType Leaf
$xmlExists = Test-Path -Path $xmlPath -PathType Leaf

Write-Host "`nVérification des fichiers d'échantillon..." -ForegroundColor Cyan
Write-Host "  Fichier UTF-8 avec BOM : $(if ($utf8BomExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($utf8BomExists) { 'Green' } else { 'Red' })
Write-Host "  Fichier XML : $(if ($xmlExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($xmlExists) { 'Green' } else { 'Red' })

if (-not $utf8BomExists -or -not $xmlExists) {
    Write-Error "Les fichiers d'échantillon n'existent pas."
    return
}

# Tester l'exécution des scripts
$encodingScriptExecuted = $false
$formatScriptExecuted = $false

Write-Host "`nTest d'exécution des scripts..." -ForegroundColor Cyan

try {
    Write-Host "  Exécution du script de détection d'encodage..." -ForegroundColor White
    $encodingResult = & $encodingScriptPath -FilePath $utf8BomPath
    $encodingScriptExecuted = $true
    Write-Host "  Le script de détection d'encodage a été exécuté avec succès." -ForegroundColor Green
    Write-Host "  Encodage détecté : $($encodingResult.Encoding)" -ForegroundColor White
}
catch {
    Write-Host "  Erreur lors de l'exécution du script de détection d'encodage : $_" -ForegroundColor Red
}

try {
    Write-Host "`n  Exécution du script de détection de format..." -ForegroundColor White
    $formatResult = & $formatScriptPath -FilePath $xmlPath -DetailedOutput
    $formatScriptExecuted = $true
    Write-Host "  Le script de détection de format a été exécuté avec succès." -ForegroundColor Green
    Write-Host "  Format détecté : $($formatResult.DetectedFormat)" -ForegroundColor White
    Write-Host "  Catégorie : $($formatResult.Category)" -ForegroundColor White
}
catch {
    Write-Host "  Erreur lors de l'exécution du script de détection de format : $_" -ForegroundColor Red
}

# Afficher un résumé
Write-Host "`nRésumé des tests fonctionnels simplifiés :" -ForegroundColor Cyan
Write-Host "  Script de détection d'encodage exécuté : $(if ($encodingScriptExecuted) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($encodingScriptExecuted) { 'Green' } else { 'Red' })
Write-Host "  Script de détection de format exécuté : $(if ($formatScriptExecuted) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($formatScriptExecuted) { 'Green' } else { 'Red' })

# Résultat global
$allTestsPassed = $encodingScriptExecuted -and $formatScriptExecuted
Write-Host "`nRésultat global : $(if ($allTestsPassed) { 'SUCCÈS' } else { 'ÉCHEC' })" -ForegroundColor $(if ($allTestsPassed) { 'Green' } else { 'Red' })

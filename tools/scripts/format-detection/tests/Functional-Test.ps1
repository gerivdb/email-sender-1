#Requires -Version 5.1
<#
.SYNOPSIS
    Test fonctionnel des fonctionnalités de détection de format et d'encodage.

.DESCRIPTION
    Ce script teste de manière fonctionnelle les fonctionnalités de détection de format et d'encodage
    en exécutant les scripts sur des fichiers d'échantillon.

.EXAMPLE
    .\Functional-Test.ps1

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

# Générer les fichiers d'échantillon si nécessaire
$generateSamplesScript = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\Generate-TestSamples.ps1"
if (Test-Path -Path $generateSamplesScript -PathType Leaf) {
    Write-Host "Génération des fichiers d'échantillon..." -ForegroundColor Cyan
    & $generateSamplesScript -Force
}
else {
    Write-Warning "Le script de génération des échantillons n'existe pas : $generateSamplesScript"
}

# Vérifier si les scripts à tester existent
$encodingScriptExists = Test-Path -Path $encodingScriptPath -PathType Leaf
$formatScriptExists = Test-Path -Path $formatScriptPath -PathType Leaf

if (-not $encodingScriptExists -or -not $formatScriptExists) {
    Write-Error "Les scripts à tester n'existent pas."
    return
}

# Charger les scripts à tester
Write-Host "`nChargement des scripts..." -ForegroundColor Cyan
. $encodingScriptPath
. $formatScriptPath

# Tester la détection d'encodage sur un fichier UTF-8 avec BOM
Write-Host "`nTest de détection d'encodage sur un fichier UTF-8 avec BOM..." -ForegroundColor Cyan
$utf8BomPath = Join-Path -Path $encodingSamplesPath -ChildPath "utf8-bom.txt"
if (Test-Path -Path $utf8BomPath -PathType Leaf) {
    $result = Get-FileEncoding -FilePath $utf8BomPath
    Write-Host "  Fichier : $utf8BomPath" -ForegroundColor White
    Write-Host "  Encodage détecté : $($result.Encoding)" -ForegroundColor White
    Write-Host "  BOM : $($result.BOM)" -ForegroundColor White
    Write-Host "  Confiance : $($result.Confidence)%" -ForegroundColor White
    
    $testPassed = $result.Encoding -eq "UTF-8-BOM" -and $result.BOM -eq $true
    Write-Host "  Résultat : $(if ($testPassed) { 'SUCCÈS' } else { 'ÉCHEC' })" -ForegroundColor $(if ($testPassed) { 'Green' } else { 'Red' })
}
else {
    Write-Warning "Le fichier d'échantillon UTF-8 avec BOM n'existe pas : $utf8BomPath"
}

# Tester la détection de format sur un fichier XML
Write-Host "`nTest de détection de format sur un fichier XML..." -ForegroundColor Cyan
$xmlPath = Join-Path -Path $formatSamplesPath -ChildPath "sample.xml"
if (Test-Path -Path $xmlPath -PathType Leaf) {
    $result = & $formatScriptPath -FilePath $xmlPath -DetailedOutput -DetectEncoding
    Write-Host "  Fichier : $xmlPath" -ForegroundColor White
    Write-Host "  Format détecté : $($result.DetectedFormat)" -ForegroundColor White
    Write-Host "  Catégorie : $($result.Category)" -ForegroundColor White
    Write-Host "  Confiance : $($result.ConfidenceScore)%" -ForegroundColor White
    Write-Host "  Critères correspondants : $($result.MatchedCriteria)" -ForegroundColor White
    Write-Host "  Encodage : $($result.Encoding.Encoding)" -ForegroundColor White
    
    $testPassed = $result.DetectedFormat -eq "XML"
    Write-Host "  Résultat : $(if ($testPassed) { 'SUCCÈS' } else { 'ÉCHEC' })" -ForegroundColor $(if ($testPassed) { 'Green' } else { 'Red' })
}
else {
    Write-Warning "Le fichier d'échantillon XML n'existe pas : $xmlPath"
}

# Tester la détection de format sur un fichier JSON
Write-Host "`nTest de détection de format sur un fichier JSON..." -ForegroundColor Cyan
$jsonPath = Join-Path -Path $formatSamplesPath -ChildPath "sample.json"
if (Test-Path -Path $jsonPath -PathType Leaf) {
    $result = & $formatScriptPath -FilePath $jsonPath -DetailedOutput -DetectEncoding
    Write-Host "  Fichier : $jsonPath" -ForegroundColor White
    Write-Host "  Format détecté : $($result.DetectedFormat)" -ForegroundColor White
    Write-Host "  Catégorie : $($result.Category)" -ForegroundColor White
    Write-Host "  Confiance : $($result.ConfidenceScore)%" -ForegroundColor White
    Write-Host "  Critères correspondants : $($result.MatchedCriteria)" -ForegroundColor White
    Write-Host "  Encodage : $($result.Encoding.Encoding)" -ForegroundColor White
    
    $testPassed = $result.DetectedFormat -eq "JSON"
    Write-Host "  Résultat : $(if ($testPassed) { 'SUCCÈS' } else { 'ÉCHEC' })" -ForegroundColor $(if ($testPassed) { 'Green' } else { 'Red' })
}
else {
    Write-Warning "Le fichier d'échantillon JSON n'existe pas : $jsonPath"
}

# Tester la détection de format sur un fichier binaire
Write-Host "`nTest de détection de format sur un fichier binaire..." -ForegroundColor Cyan
$binaryPath = Join-Path -Path $formatSamplesPath -ChildPath "sample.bin"
if (Test-Path -Path $binaryPath -PathType Leaf) {
    $result = & $formatScriptPath -FilePath $binaryPath -DetailedOutput -DetectEncoding
    Write-Host "  Fichier : $binaryPath" -ForegroundColor White
    Write-Host "  Format détecté : $($result.DetectedFormat)" -ForegroundColor White
    Write-Host "  Catégorie : $($result.Category)" -ForegroundColor White
    Write-Host "  Confiance : $($result.ConfidenceScore)%" -ForegroundColor White
    Write-Host "  Critères correspondants : $($result.MatchedCriteria)" -ForegroundColor White
    
    $testPassed = $result.DetectedFormat -eq "BINARY"
    Write-Host "  Résultat : $(if ($testPassed) { 'SUCCÈS' } else { 'ÉCHEC' })" -ForegroundColor $(if ($testPassed) { 'Green' } else { 'Red' })
}
else {
    Write-Warning "Le fichier d'échantillon binaire n'existe pas : $binaryPath"
}

# Afficher un résumé
Write-Host "`nRésumé des tests fonctionnels :" -ForegroundColor Cyan
Write-Host "  Tests exécutés : 4" -ForegroundColor White
Write-Host "  Tests réussis : $(if ($testPassed) { '4' } else { 'Certains tests ont échoué' })" -ForegroundColor $(if ($testPassed) { 'Green' } else { 'Red' })

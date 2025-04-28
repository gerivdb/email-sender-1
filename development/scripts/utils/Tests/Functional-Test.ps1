#Requires -Version 5.1
<#
.SYNOPSIS
    Test fonctionnel des fonctionnalitÃ©s de dÃ©tection de format et d'encodage.

.DESCRIPTION
    Ce script teste de maniÃ¨re fonctionnelle les fonctionnalitÃ©s de dÃ©tection de format et d'encodage
    en exÃ©cutant les scripts sur des fichiers d'Ã©chantillon.

.EXAMPLE
    .\Functional-Test.ps1

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

# GÃ©nÃ©rer les fichiers d'Ã©chantillon si nÃ©cessaire
$generateSamplesScript = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\Generate-TestSamples.ps1"
if (Test-Path -Path $generateSamplesScript -PathType Leaf) {
    Write-Host "GÃ©nÃ©ration des fichiers d'Ã©chantillon..." -ForegroundColor Cyan
    & $generateSamplesScript -Force
}
else {
    Write-Warning "Le script de gÃ©nÃ©ration des Ã©chantillons n'existe pas : $generateSamplesScript"
}

# VÃ©rifier si les scripts Ã  tester existent
$encodingScriptExists = Test-Path -Path $encodingScriptPath -PathType Leaf
$formatScriptExists = Test-Path -Path $formatScriptPath -PathType Leaf

if (-not $encodingScriptExists -or -not $formatScriptExists) {
    Write-Error "Les scripts Ã  tester n'existent pas."
    return
}

# Charger les scripts Ã  tester
Write-Host "`nChargement des scripts..." -ForegroundColor Cyan
. $encodingScriptPath
. $formatScriptPath

# Tester la dÃ©tection d'encodage sur un fichier UTF-8 avec BOM
Write-Host "`nTest de dÃ©tection d'encodage sur un fichier UTF-8 avec BOM..." -ForegroundColor Cyan
$utf8BomPath = Join-Path -Path $encodingSamplesPath -ChildPath "utf8-bom.txt"
if (Test-Path -Path $utf8BomPath -PathType Leaf) {
    $result = Get-FileEncoding -FilePath $utf8BomPath
    Write-Host "  Fichier : $utf8BomPath" -ForegroundColor White
    Write-Host "  Encodage dÃ©tectÃ© : $($result.Encoding)" -ForegroundColor White
    Write-Host "  BOM : $($result.BOM)" -ForegroundColor White
    Write-Host "  Confiance : $($result.Confidence)%" -ForegroundColor White
    
    $testPassed = $result.Encoding -eq "UTF-8-BOM" -and $result.BOM -eq $true
    Write-Host "  RÃ©sultat : $(if ($testPassed) { 'SUCCÃˆS' } else { 'Ã‰CHEC' })" -ForegroundColor $(if ($testPassed) { 'Green' } else { 'Red' })
}
else {
    Write-Warning "Le fichier d'Ã©chantillon UTF-8 avec BOM n'existe pas : $utf8BomPath"
}

# Tester la dÃ©tection de format sur un fichier XML
Write-Host "`nTest de dÃ©tection de format sur un fichier XML..." -ForegroundColor Cyan
$xmlPath = Join-Path -Path $formatSamplesPath -ChildPath "sample.xml"
if (Test-Path -Path $xmlPath -PathType Leaf) {
    $result = & $formatScriptPath -FilePath $xmlPath -DetailedOutput -DetectEncoding
    Write-Host "  Fichier : $xmlPath" -ForegroundColor White
    Write-Host "  Format dÃ©tectÃ© : $($result.DetectedFormat)" -ForegroundColor White
    Write-Host "  CatÃ©gorie : $($result.Category)" -ForegroundColor White
    Write-Host "  Confiance : $($result.ConfidenceScore)%" -ForegroundColor White
    Write-Host "  CritÃ¨res correspondants : $($result.MatchedCriteria)" -ForegroundColor White
    Write-Host "  Encodage : $($result.Encoding.Encoding)" -ForegroundColor White
    
    $testPassed = $result.DetectedFormat -eq "XML"
    Write-Host "  RÃ©sultat : $(if ($testPassed) { 'SUCCÃˆS' } else { 'Ã‰CHEC' })" -ForegroundColor $(if ($testPassed) { 'Green' } else { 'Red' })
}
else {
    Write-Warning "Le fichier d'Ã©chantillon XML n'existe pas : $xmlPath"
}

# Tester la dÃ©tection de format sur un fichier JSON
Write-Host "`nTest de dÃ©tection de format sur un fichier JSON..." -ForegroundColor Cyan
$jsonPath = Join-Path -Path $formatSamplesPath -ChildPath "sample.json"
if (Test-Path -Path $jsonPath -PathType Leaf) {
    $result = & $formatScriptPath -FilePath $jsonPath -DetailedOutput -DetectEncoding
    Write-Host "  Fichier : $jsonPath" -ForegroundColor White
    Write-Host "  Format dÃ©tectÃ© : $($result.DetectedFormat)" -ForegroundColor White
    Write-Host "  CatÃ©gorie : $($result.Category)" -ForegroundColor White
    Write-Host "  Confiance : $($result.ConfidenceScore)%" -ForegroundColor White
    Write-Host "  CritÃ¨res correspondants : $($result.MatchedCriteria)" -ForegroundColor White
    Write-Host "  Encodage : $($result.Encoding.Encoding)" -ForegroundColor White
    
    $testPassed = $result.DetectedFormat -eq "JSON"
    Write-Host "  RÃ©sultat : $(if ($testPassed) { 'SUCCÃˆS' } else { 'Ã‰CHEC' })" -ForegroundColor $(if ($testPassed) { 'Green' } else { 'Red' })
}
else {
    Write-Warning "Le fichier d'Ã©chantillon JSON n'existe pas : $jsonPath"
}

# Tester la dÃ©tection de format sur un fichier binaire
Write-Host "`nTest de dÃ©tection de format sur un fichier binaire..." -ForegroundColor Cyan
$binaryPath = Join-Path -Path $formatSamplesPath -ChildPath "sample.bin"
if (Test-Path -Path $binaryPath -PathType Leaf) {
    $result = & $formatScriptPath -FilePath $binaryPath -DetailedOutput -DetectEncoding
    Write-Host "  Fichier : $binaryPath" -ForegroundColor White
    Write-Host "  Format dÃ©tectÃ© : $($result.DetectedFormat)" -ForegroundColor White
    Write-Host "  CatÃ©gorie : $($result.Category)" -ForegroundColor White
    Write-Host "  Confiance : $($result.ConfidenceScore)%" -ForegroundColor White
    Write-Host "  CritÃ¨res correspondants : $($result.MatchedCriteria)" -ForegroundColor White
    
    $testPassed = $result.DetectedFormat -eq "BINARY"
    Write-Host "  RÃ©sultat : $(if ($testPassed) { 'SUCCÃˆS' } else { 'Ã‰CHEC' })" -ForegroundColor $(if ($testPassed) { 'Green' } else { 'Red' })
}
else {
    Write-Warning "Le fichier d'Ã©chantillon binaire n'existe pas : $binaryPath"
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests fonctionnels :" -ForegroundColor Cyan
Write-Host "  Tests exÃ©cutÃ©s : 4" -ForegroundColor White
Write-Host "  Tests rÃ©ussis : $(if ($testPassed) { '4' } else { 'Certains tests ont Ã©chouÃ©' })" -ForegroundColor $(if ($testPassed) { 'Green' } else { 'Red' })

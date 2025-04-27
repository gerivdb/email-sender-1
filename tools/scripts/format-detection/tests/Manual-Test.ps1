#Requires -Version 5.1
<#
.SYNOPSIS
    Test manuel des fonctionnalitÃ©s de dÃ©tection de format et d'encodage.

.DESCRIPTION
    Ce script teste manuellement les fonctionnalitÃ©s de dÃ©tection de format et d'encodage
    en utilisant les fichiers d'Ã©chantillon gÃ©nÃ©rÃ©s.

.EXAMPLE
    .\Manual-Test.ps1

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

Write-Host "`nVÃ©rification des scripts Ã  tester..." -ForegroundColor Cyan
Write-Host "  Script de dÃ©tection d'encodage : $(if ($encodingScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($encodingScriptExists) { 'Green' } else { 'Red' })
Write-Host "  Script de dÃ©tection de format : $(if ($formatScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($formatScriptExists) { 'Green' } else { 'Red' })

# Charger les scripts Ã  tester
if ($encodingScriptExists) {
    Write-Host "`nChargement du script de dÃ©tection d'encodage..." -ForegroundColor Cyan
    . $encodingScriptPath
}

if ($formatScriptExists) {
    Write-Host "Chargement du script de dÃ©tection de format..." -ForegroundColor Cyan
    . $formatScriptPath
}

# Tester la dÃ©tection d'encodage
if ($encodingScriptExists) {
    Write-Host "`nTest de la dÃ©tection d'encodage..." -ForegroundColor Cyan
    
    $encodingFiles = Get-ChildItem -Path $encodingSamplesPath -File
    $encodingResults = @()
    
    foreach ($file in $encodingFiles) {
        try {
            $result = Get-FileEncoding -FilePath $file.FullName
            $encodingResults += [PSCustomObject]@{
                FileName = $file.Name
                Encoding = $result.Encoding
                BOM = $result.BOM
                Confidence = $result.Confidence
                Description = $result.Description
            }
        }
        catch {
            Write-Warning "Erreur lors de la dÃ©tection de l'encodage du fichier $($file.Name) : $_"
        }
    }
    
    # Afficher les rÃ©sultats
    $encodingResults | Format-Table -AutoSize
}

# Tester la dÃ©tection de format
if ($formatScriptExists) {
    Write-Host "`nTest de la dÃ©tection de format..." -ForegroundColor Cyan
    
    $formatFiles = Get-ChildItem -Path $formatSamplesPath -File
    $formatResults = @()
    
    foreach ($file in $formatFiles) {
        try {
            $result = Detect-ImprovedFormat -FilePath $file.FullName -DetectEncoding -DetailedOutput
            $formatResults += [PSCustomObject]@{
                FileName = $file.Name
                DetectedFormat = $result.DetectedFormat
                Category = $result.Category
                ConfidenceScore = $result.ConfidenceScore
                MatchedCriteria = $result.MatchedCriteria -join ", "
                Encoding = $result.Encoding
            }
        }
        catch {
            Write-Warning "Erreur lors de la dÃ©tection du format du fichier $($file.Name) : $_"
        }
    }
    
    # Afficher les rÃ©sultats
    $formatResults | Format-Table -AutoSize
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests :" -ForegroundColor Cyan
if ($encodingScriptExists) {
    $encodingSuccessCount = $encodingResults.Count
    Write-Host "  Tests de dÃ©tection d'encodage : $encodingSuccessCount rÃ©ussis sur $($encodingFiles.Count) fichiers" -ForegroundColor $(if ($encodingSuccessCount -eq $encodingFiles.Count) { 'Green' } else { 'Yellow' })
}

if ($formatScriptExists) {
    $formatSuccessCount = $formatResults.Count
    Write-Host "  Tests de dÃ©tection de format : $formatSuccessCount rÃ©ussis sur $($formatFiles.Count) fichiers" -ForegroundColor $(if ($formatSuccessCount -eq $formatFiles.Count) { 'Green' } else { 'Yellow' })
}

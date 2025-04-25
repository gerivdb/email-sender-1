#Requires -Version 5.1
<#
.SYNOPSIS
    Test manuel des fonctionnalités de détection de format et d'encodage.

.DESCRIPTION
    Ce script teste manuellement les fonctionnalités de détection de format et d'encodage
    en utilisant les fichiers d'échantillon générés.

.EXAMPLE
    .\Manual-Test.ps1

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

Write-Host "`nVérification des scripts à tester..." -ForegroundColor Cyan
Write-Host "  Script de détection d'encodage : $(if ($encodingScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($encodingScriptExists) { 'Green' } else { 'Red' })
Write-Host "  Script de détection de format : $(if ($formatScriptExists) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($formatScriptExists) { 'Green' } else { 'Red' })

# Charger les scripts à tester
if ($encodingScriptExists) {
    Write-Host "`nChargement du script de détection d'encodage..." -ForegroundColor Cyan
    . $encodingScriptPath
}

if ($formatScriptExists) {
    Write-Host "Chargement du script de détection de format..." -ForegroundColor Cyan
    . $formatScriptPath
}

# Tester la détection d'encodage
if ($encodingScriptExists) {
    Write-Host "`nTest de la détection d'encodage..." -ForegroundColor Cyan
    
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
            Write-Warning "Erreur lors de la détection de l'encodage du fichier $($file.Name) : $_"
        }
    }
    
    # Afficher les résultats
    $encodingResults | Format-Table -AutoSize
}

# Tester la détection de format
if ($formatScriptExists) {
    Write-Host "`nTest de la détection de format..." -ForegroundColor Cyan
    
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
            Write-Warning "Erreur lors de la détection du format du fichier $($file.Name) : $_"
        }
    }
    
    # Afficher les résultats
    $formatResults | Format-Table -AutoSize
}

# Afficher un résumé
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
if ($encodingScriptExists) {
    $encodingSuccessCount = $encodingResults.Count
    Write-Host "  Tests de détection d'encodage : $encodingSuccessCount réussis sur $($encodingFiles.Count) fichiers" -ForegroundColor $(if ($encodingSuccessCount -eq $encodingFiles.Count) { 'Green' } else { 'Yellow' })
}

if ($formatScriptExists) {
    $formatSuccessCount = $formatResults.Count
    Write-Host "  Tests de détection de format : $formatSuccessCount réussis sur $($formatFiles.Count) fichiers" -ForegroundColor $(if ($formatSuccessCount -eq $formatFiles.Count) { 'Green' } else { 'Yellow' })
}

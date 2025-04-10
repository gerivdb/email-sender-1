#Requires -Version 5.1
<#
.SYNOPSIS
    Vérifie que les fichiers d'échantillon ont été correctement générés.

.DESCRIPTION
    Ce script vérifie que les fichiers d'échantillon ont été correctement générés
    et affiche un résumé des fichiers trouvés.

.EXAMPLE
    .\Verify-SampleFiles.ps1

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param()

# Chemins des répertoires d'échantillons
$samplesPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\samples"
$formatSamplesPath = Join-Path -Path $samplesPath -ChildPath "formats"
$encodingSamplesPath = Join-Path -Path $samplesPath -ChildPath "encodings"

# Vérifier si les répertoires existent
$samplesExist = Test-Path -Path $samplesPath -PathType Container
$formatSamplesExist = Test-Path -Path $formatSamplesPath -PathType Container
$encodingSamplesExist = Test-Path -Path $encodingSamplesPath -PathType Container

Write-Host "Vérification des fichiers d'échantillon..." -ForegroundColor Cyan
Write-Host "  Répertoire d'échantillons : $(if ($samplesExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($samplesExist) { 'Green' } else { 'Red' })
Write-Host "  Répertoire d'échantillons de format : $(if ($formatSamplesExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($formatSamplesExist) { 'Green' } else { 'Red' })
Write-Host "  Répertoire d'échantillons d'encodage : $(if ($encodingSamplesExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($encodingSamplesExist) { 'Green' } else { 'Red' })

# Vérifier les fichiers d'échantillon de format
if ($formatSamplesExist) {
    $formatFiles = Get-ChildItem -Path $formatSamplesPath -File
    Write-Host "`nFichiers d'échantillon de format trouvés : $($formatFiles.Count)" -ForegroundColor Cyan
    foreach ($file in $formatFiles) {
        Write-Host "  $($file.Name) ($($file.Length) octets)" -ForegroundColor White
    }
}

# Vérifier les fichiers d'échantillon d'encodage
if ($encodingSamplesExist) {
    $encodingFiles = Get-ChildItem -Path $encodingSamplesPath -File
    Write-Host "`nFichiers d'échantillon d'encodage trouvés : $($encodingFiles.Count)" -ForegroundColor Cyan
    foreach ($file in $encodingFiles) {
        Write-Host "  $($file.Name) ($($file.Length) octets)" -ForegroundColor White
    }
}

# Vérifier les fichiers de formats et d'encodages attendus
$expectedFormatsPath = Join-Path -Path $samplesPath -ChildPath "ExpectedFormats.json"
$expectedEncodingsPath = Join-Path -Path $samplesPath -ChildPath "ExpectedEncodings.json"

$expectedFormatsExist = Test-Path -Path $expectedFormatsPath -PathType Leaf
$expectedEncodingsExist = Test-Path -Path $expectedEncodingsPath -PathType Leaf

Write-Host "`nFichiers de formats et d'encodages attendus :" -ForegroundColor Cyan
Write-Host "  Formats attendus : $(if ($expectedFormatsExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($expectedFormatsExist) { 'Green' } else { 'Red' })
Write-Host "  Encodages attendus : $(if ($expectedEncodingsExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($expectedEncodingsExist) { 'Green' } else { 'Red' })

# Afficher un résumé
Write-Host "`nRésumé :" -ForegroundColor Cyan
$totalFiles = 0
if ($formatSamplesExist) { $totalFiles += $formatFiles.Count }
if ($encodingSamplesExist) { $totalFiles += $encodingFiles.Count }
if ($expectedFormatsExist) { $totalFiles += 1 }
if ($expectedEncodingsExist) { $totalFiles += 1 }

Write-Host "  Nombre total de fichiers : $totalFiles" -ForegroundColor White
$allFilesPresent = $samplesExist -and $formatSamplesExist -and $encodingSamplesExist -and $expectedFormatsExist -and $expectedEncodingsExist
Write-Host "  Tous les fichiers nécessaires sont présents : $(if ($allFilesPresent) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($allFilesPresent) { 'Green' } else { 'Red' })

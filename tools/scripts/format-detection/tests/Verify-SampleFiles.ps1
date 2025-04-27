#Requires -Version 5.1
<#
.SYNOPSIS
    VÃ©rifie que les fichiers d'Ã©chantillon ont Ã©tÃ© correctement gÃ©nÃ©rÃ©s.

.DESCRIPTION
    Ce script vÃ©rifie que les fichiers d'Ã©chantillon ont Ã©tÃ© correctement gÃ©nÃ©rÃ©s
    et affiche un rÃ©sumÃ© des fichiers trouvÃ©s.

.EXAMPLE
    .\Verify-SampleFiles.ps1

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param()

# Chemins des rÃ©pertoires d'Ã©chantillons
$samplesPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\samples"
$formatSamplesPath = Join-Path -Path $samplesPath -ChildPath "formats"
$encodingSamplesPath = Join-Path -Path $samplesPath -ChildPath "encodings"

# VÃ©rifier si les rÃ©pertoires existent
$samplesExist = Test-Path -Path $samplesPath -PathType Container
$formatSamplesExist = Test-Path -Path $formatSamplesPath -PathType Container
$encodingSamplesExist = Test-Path -Path $encodingSamplesPath -PathType Container

Write-Host "VÃ©rification des fichiers d'Ã©chantillon..." -ForegroundColor Cyan
Write-Host "  RÃ©pertoire d'Ã©chantillons : $(if ($samplesExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($samplesExist) { 'Green' } else { 'Red' })
Write-Host "  RÃ©pertoire d'Ã©chantillons de format : $(if ($formatSamplesExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($formatSamplesExist) { 'Green' } else { 'Red' })
Write-Host "  RÃ©pertoire d'Ã©chantillons d'encodage : $(if ($encodingSamplesExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($encodingSamplesExist) { 'Green' } else { 'Red' })

# VÃ©rifier les fichiers d'Ã©chantillon de format
if ($formatSamplesExist) {
    $formatFiles = Get-ChildItem -Path $formatSamplesPath -File
    Write-Host "`nFichiers d'Ã©chantillon de format trouvÃ©s : $($formatFiles.Count)" -ForegroundColor Cyan
    foreach ($file in $formatFiles) {
        Write-Host "  $($file.Name) ($($file.Length) octets)" -ForegroundColor White
    }
}

# VÃ©rifier les fichiers d'Ã©chantillon d'encodage
if ($encodingSamplesExist) {
    $encodingFiles = Get-ChildItem -Path $encodingSamplesPath -File
    Write-Host "`nFichiers d'Ã©chantillon d'encodage trouvÃ©s : $($encodingFiles.Count)" -ForegroundColor Cyan
    foreach ($file in $encodingFiles) {
        Write-Host "  $($file.Name) ($($file.Length) octets)" -ForegroundColor White
    }
}

# VÃ©rifier les fichiers de formats et d'encodages attendus
$expectedFormatsPath = Join-Path -Path $samplesPath -ChildPath "ExpectedFormats.json"
$expectedEncodingsPath = Join-Path -Path $samplesPath -ChildPath "ExpectedEncodings.json"

$expectedFormatsExist = Test-Path -Path $expectedFormatsPath -PathType Leaf
$expectedEncodingsExist = Test-Path -Path $expectedEncodingsPath -PathType Leaf

Write-Host "`nFichiers de formats et d'encodages attendus :" -ForegroundColor Cyan
Write-Host "  Formats attendus : $(if ($expectedFormatsExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($expectedFormatsExist) { 'Green' } else { 'Red' })
Write-Host "  Encodages attendus : $(if ($expectedEncodingsExist) { 'Existe' } else { 'N''existe pas' })" -ForegroundColor $(if ($expectedEncodingsExist) { 'Green' } else { 'Red' })

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© :" -ForegroundColor Cyan
$totalFiles = 0
if ($formatSamplesExist) { $totalFiles += $formatFiles.Count }
if ($encodingSamplesExist) { $totalFiles += $encodingFiles.Count }
if ($expectedFormatsExist) { $totalFiles += 1 }
if ($expectedEncodingsExist) { $totalFiles += 1 }

Write-Host "  Nombre total de fichiers : $totalFiles" -ForegroundColor White
$allFilesPresent = $samplesExist -and $formatSamplesExist -and $encodingSamplesExist -and $expectedFormatsExist -and $expectedEncodingsExist
Write-Host "  Tous les fichiers nÃ©cessaires sont prÃ©sents : $(if ($allFilesPresent) { 'Oui' } else { 'Non' })" -ForegroundColor $(if ($allFilesPresent) { 'Green' } else { 'Red' })

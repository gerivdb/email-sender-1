#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute tous les scripts d'amÃ©lioration et de test pour la dÃ©tection de format.

.DESCRIPTION
    Ce script exÃ©cute tous les scripts d'amÃ©lioration et de test pour la dÃ©tection de format,
    y compris la gÃ©nÃ©ration de fichiers d'Ã©chantillon, les tests de dÃ©tection et la mise Ã  jour
    de la roadmap et du journal de dÃ©veloppement.

.PARAMETER SampleDirectory
    Le rÃ©pertoire oÃ¹ les fichiers d'Ã©chantillon seront enregistrÃ©s.
    Par dÃ©faut, utilise le rÃ©pertoire 'samples'.

.PARAMETER GenerateHtmlReports
    Indique si des rapports HTML doivent Ãªtre gÃ©nÃ©rÃ©s en plus des rapports JSON.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit Ãªtre mise Ã  jour avec les amÃ©liorations implÃ©mentÃ©es.

.PARAMETER UpdateDevJournal
    Indique si le journal de dÃ©veloppement doit Ãªtre mis Ã  jour avec les amÃ©liorations implÃ©mentÃ©es.

.EXAMPLE
    .\Run-FormatDetectionImprovements.ps1 -GenerateHtmlReports -UpdateRoadmap -UpdateDevJournal

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SampleDirectory = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\samples",

    [Parameter()]
    [switch]$GenerateHtmlReports,

    [Parameter()]
    [switch]$UpdateRoadmap,

    [Parameter()]
    [switch]$UpdateDevJournal
)

# VÃ©rifier si le rÃ©pertoire d'Ã©chantillons existe
if (-not (Test-Path -Path $SampleDirectory -PathType Container)) {
    New-Item -Path $SampleDirectory -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire d'Ã©chantillons crÃ©Ã© : $SampleDirectory" -ForegroundColor Green
}

# CrÃ©er le rÃ©pertoire d'Ã©chantillons pour les encodages
$encodingSampleDirectory = Join-Path -Path $SampleDirectory -ChildPath "encoding"
if (-not (Test-Path -Path $encodingSampleDirectory -PathType Container)) {
    New-Item -Path $encodingSampleDirectory -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire d'Ã©chantillons pour les encodages crÃ©Ã© : $encodingSampleDirectory" -ForegroundColor Green
}

# DÃ©finir les chemins des scripts
$defineFormatCriteriaScript = Join-Path -Path $PSScriptRoot -ChildPath "Define-FormatDetectionCriteria.ps1"
$generateEncodingSamplesScript = Join-Path -Path $PSScriptRoot -ChildPath "Generate-EncodingSamples.ps1"
$generateExpectedFormatsScript = Join-Path -Path $PSScriptRoot -ChildPath "Generate-ExpectedFormats.ps1"
$testEncodingDetectionScript = Join-Path -Path $PSScriptRoot -ChildPath "Test-EncodingDetection.ps1"
$updateRoadmapScript = Join-Path -Path $PSScriptRoot -ChildPath "Update-Roadmap.ps1"
$updateDevJournalScript = Join-Path -Path $PSScriptRoot -ChildPath "Update-DevJournal.ps1"

# Ã‰tape 1 : DÃ©finir les critÃ¨res de dÃ©tection de format
Write-Host "`nÃ‰tape 1 : DÃ©finition des critÃ¨res de dÃ©tection de format" -ForegroundColor Cyan
if (Test-Path -Path $defineFormatCriteriaScript -PathType Leaf) {
    & $defineFormatCriteriaScript
} else {
    Write-Warning "Le script $defineFormatCriteriaScript n'existe pas."
}

# Ã‰tape 2 : GÃ©nÃ©rer des fichiers d'Ã©chantillon pour les encodages
Write-Host "`nÃ‰tape 2 : GÃ©nÃ©ration des fichiers d'Ã©chantillon pour les encodages" -ForegroundColor Cyan
if (Test-Path -Path $generateEncodingSamplesScript -PathType Leaf) {
    & $generateEncodingSamplesScript -OutputDirectory $encodingSampleDirectory -GenerateExpectedEncodings
} else {
    Write-Warning "Le script $generateEncodingSamplesScript n'existe pas."
}

# Ã‰tape 3 : GÃ©nÃ©rer les formats attendus pour les tests
Write-Host "`nÃ‰tape 3 : GÃ©nÃ©ration des formats attendus pour les tests" -ForegroundColor Cyan
if (Test-Path -Path $generateExpectedFormatsScript -PathType Leaf) {
    & $generateExpectedFormatsScript -SampleDirectory $SampleDirectory
} else {
    Write-Warning "Le script $generateExpectedFormatsScript n'existe pas."
}

# Ã‰tape 4 : Tester la dÃ©tection de format amÃ©liorÃ©e
Write-Host "`nÃ‰tape 4 : Test de la dÃ©tection de format amÃ©liorÃ©e" -ForegroundColor Cyan
$simpleTestScript = Join-Path -Path $PSScriptRoot -ChildPath "Simple-FormatDetectionTest.ps1"
if (Test-Path -Path $simpleTestScript -PathType Leaf) {
    $params = @{
        SampleDirectory = $SampleDirectory
    }

    if ($GenerateHtmlReports) {
        $params.Add("GenerateHtmlReport", $true)
    }

    & $simpleTestScript @params
} else {
    Write-Warning "Le script $simpleTestScript n'existe pas."
}

# Ã‰tape 5 : Tester la dÃ©tection d'encodage
Write-Host "`nÃ‰tape 5 : Test de la dÃ©tection d'encodage" -ForegroundColor Cyan
if (Test-Path -Path $testEncodingDetectionScript -PathType Leaf) {
    $params = @{
        SampleDirectory = $encodingSampleDirectory
        ExpectedEncodingsPath = (Join-Path -Path $encodingSampleDirectory -ChildPath "ExpectedEncodings.json")
    }

    if ($GenerateHtmlReports) {
        $params.Add("GenerateHtmlReport", $true)
    }

    & $testEncodingDetectionScript @params
} else {
    Write-Warning "Le script $testEncodingDetectionScript n'existe pas."
}

# Ã‰tape 6 : Mettre Ã  jour la roadmap
if ($UpdateRoadmap) {
    Write-Host "`nÃ‰tape 6 : Mise Ã  jour de la roadmap" -ForegroundColor Cyan
    if (Test-Path -Path $updateRoadmapScript -PathType Leaf) {
        & $updateRoadmapScript
    } else {
        Write-Warning "Le script $updateRoadmapScript n'existe pas."
    }
}

# Ã‰tape 7 : Mettre Ã  jour le journal de dÃ©veloppement
if ($UpdateDevJournal) {
    Write-Host "`nÃ‰tape 7 : Mise Ã  jour du journal de dÃ©veloppement" -ForegroundColor Cyan
    if (Test-Path -Path $updateDevJournalScript -PathType Leaf) {
        & $updateDevJournalScript
    } else {
        Write-Warning "Le script $updateDevJournalScript n'existe pas."
    }
}

Write-Host "`nExÃ©cution des scripts d'amÃ©lioration et de test terminÃ©e." -ForegroundColor Green

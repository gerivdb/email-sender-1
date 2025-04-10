#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les scripts d'amélioration et de test pour la détection de format.

.DESCRIPTION
    Ce script exécute tous les scripts d'amélioration et de test pour la détection de format,
    y compris la génération de fichiers d'échantillon, les tests de détection et la mise à jour
    de la roadmap et du journal de développement.

.PARAMETER SampleDirectory
    Le répertoire où les fichiers d'échantillon seront enregistrés.
    Par défaut, utilise le répertoire 'samples'.

.PARAMETER GenerateHtmlReports
    Indique si des rapports HTML doivent être générés en plus des rapports JSON.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit être mise à jour avec les améliorations implémentées.

.PARAMETER UpdateDevJournal
    Indique si le journal de développement doit être mis à jour avec les améliorations implémentées.

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

# Vérifier si le répertoire d'échantillons existe
if (-not (Test-Path -Path $SampleDirectory -PathType Container)) {
    New-Item -Path $SampleDirectory -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire d'échantillons créé : $SampleDirectory" -ForegroundColor Green
}

# Créer le répertoire d'échantillons pour les encodages
$encodingSampleDirectory = Join-Path -Path $SampleDirectory -ChildPath "encoding"
if (-not (Test-Path -Path $encodingSampleDirectory -PathType Container)) {
    New-Item -Path $encodingSampleDirectory -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire d'échantillons pour les encodages créé : $encodingSampleDirectory" -ForegroundColor Green
}

# Définir les chemins des scripts
$defineFormatCriteriaScript = Join-Path -Path $PSScriptRoot -ChildPath "Define-FormatDetectionCriteria.ps1"
$generateEncodingSamplesScript = Join-Path -Path $PSScriptRoot -ChildPath "Generate-EncodingSamples.ps1"
$generateExpectedFormatsScript = Join-Path -Path $PSScriptRoot -ChildPath "Generate-ExpectedFormats.ps1"
$testEncodingDetectionScript = Join-Path -Path $PSScriptRoot -ChildPath "Test-EncodingDetection.ps1"
$updateRoadmapScript = Join-Path -Path $PSScriptRoot -ChildPath "Update-Roadmap.ps1"
$updateDevJournalScript = Join-Path -Path $PSScriptRoot -ChildPath "Update-DevJournal.ps1"

# Étape 1 : Définir les critères de détection de format
Write-Host "`nÉtape 1 : Définition des critères de détection de format" -ForegroundColor Cyan
if (Test-Path -Path $defineFormatCriteriaScript -PathType Leaf) {
    & $defineFormatCriteriaScript
} else {
    Write-Warning "Le script $defineFormatCriteriaScript n'existe pas."
}

# Étape 2 : Générer des fichiers d'échantillon pour les encodages
Write-Host "`nÉtape 2 : Génération des fichiers d'échantillon pour les encodages" -ForegroundColor Cyan
if (Test-Path -Path $generateEncodingSamplesScript -PathType Leaf) {
    & $generateEncodingSamplesScript -OutputDirectory $encodingSampleDirectory -GenerateExpectedEncodings
} else {
    Write-Warning "Le script $generateEncodingSamplesScript n'existe pas."
}

# Étape 3 : Générer les formats attendus pour les tests
Write-Host "`nÉtape 3 : Génération des formats attendus pour les tests" -ForegroundColor Cyan
if (Test-Path -Path $generateExpectedFormatsScript -PathType Leaf) {
    & $generateExpectedFormatsScript -SampleDirectory $SampleDirectory
} else {
    Write-Warning "Le script $generateExpectedFormatsScript n'existe pas."
}

# Étape 4 : Tester la détection de format améliorée
Write-Host "`nÉtape 4 : Test de la détection de format améliorée" -ForegroundColor Cyan
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

# Étape 5 : Tester la détection d'encodage
Write-Host "`nÉtape 5 : Test de la détection d'encodage" -ForegroundColor Cyan
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

# Étape 6 : Mettre à jour la roadmap
if ($UpdateRoadmap) {
    Write-Host "`nÉtape 6 : Mise à jour de la roadmap" -ForegroundColor Cyan
    if (Test-Path -Path $updateRoadmapScript -PathType Leaf) {
        & $updateRoadmapScript
    } else {
        Write-Warning "Le script $updateRoadmapScript n'existe pas."
    }
}

# Étape 7 : Mettre à jour le journal de développement
if ($UpdateDevJournal) {
    Write-Host "`nÉtape 7 : Mise à jour du journal de développement" -ForegroundColor Cyan
    if (Test-Path -Path $updateDevJournalScript -PathType Leaf) {
        & $updateDevJournalScript
    } else {
        Write-Warning "Le script $updateDevJournalScript n'existe pas."
    }
}

Write-Host "`nExécution des scripts d'amélioration et de test terminée." -ForegroundColor Green

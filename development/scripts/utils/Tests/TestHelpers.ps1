#Requires -Version 5.1
<#
.SYNOPSIS
    Fonctions d'aide pour les tests unitaires du module Format-Converters.

.DESCRIPTION
    Ce script contient des fonctions d'aide pour les tests unitaires du module Format-Converters.
    Il est utilisÃ© par les scripts de test pour crÃ©er des fichiers de test, rÃ©cupÃ©rer des chemins de fichiers, etc.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$script:testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConvertersTests_$(Get-Random)"
New-Item -Path $script:testTempDir -ItemType Directory -Force | Out-Null

# Fonction pour crÃ©er des fichiers de test temporaires
function New-TempTestFile {
    param (
        [string]$FileName,
        [string]$Content
    )

    $filePath = Join-Path -Path $script:testTempDir -ChildPath $FileName
    $Content | Set-Content -Path $filePath -Encoding UTF8
    Write-Verbose "Fichier crÃ©Ã© : $filePath"
    return $filePath
}

# Fonction pour rÃ©cupÃ©rer le chemin d'un fichier de test statique
function Get-TestFilePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FileName
    )

    $testDataPath = Join-Path -Path $PSScriptRoot -ChildPath "TestData"
    $filePath = Join-Path -Path $testDataPath -ChildPath $FileName

    if (-not (Test-Path -Path $filePath -PathType Leaf)) {
        throw "Le fichier de test '$filePath' n'existe pas."
    }

    return $filePath
}

# Fonction pour nettoyer les fichiers temporaires
function Remove-TestTempFiles {
    if (Test-Path -Path $script:testTempDir) {
        Remove-Item -Path $script:testTempDir -Recurse -Force
    }
}

# CrÃ©er un objet de rÃ©sultat de dÃ©tection pour les tests
function New-TestDetectionResult {
    param (
        [string]$FilePath = "test.json",
        [string]$DetectedFormat = "JSON",
        [int]$Confidence = 90,
        [hashtable]$AllFormats = @{ "JSON" = 90; "TEXT" = 50 }
    )

    return [PSCustomObject]@{
        FilePath = $FilePath
        DetectedFormat = $DetectedFormat
        Confidence = $Confidence
        AllFormats = $AllFormats
    }
}

# Les fonctions sont disponibles dans le script qui dot-source ce fichier

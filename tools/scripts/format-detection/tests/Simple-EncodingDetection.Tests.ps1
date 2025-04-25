#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiés pour la fonction de détection d'encodage.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiés pour valider le bon fonctionnement
    de la fonction de détection d'encodage.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas disponible. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    }
    catch {
        Write-Error "Impossible d'installer le module Pester. Les tests ne peuvent pas être exécutés."
        return
    }
}

# Chemin vers le script à tester
$scriptPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\analysis\Detect-FileEncoding.ps1"

# Chemin vers le répertoire d'échantillons
$samplesPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\samples\encodings"

# Générer les fichiers d'échantillon si nécessaire
if (-not (Test-Path -Path $samplesPath -PathType Container)) {
    $generateSamplesScript = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\Generate-TestSamples.ps1"
    if (Test-Path -Path $generateSamplesScript -PathType Leaf) {
        Write-Host "Génération des fichiers d'échantillon..." -ForegroundColor Cyan
        & $generateSamplesScript -Force
    }
    else {
        Write-Error "Le script de génération des échantillons n'existe pas : $generateSamplesScript"
        return
    }
}

# Charger le script à tester
$scriptContent = Get-Content -Path $scriptPath -Raw
$scriptBlock = [ScriptBlock]::Create($scriptContent)
. $scriptBlock

# Démarrer les tests Pester
Describe "Tests simplifiés de détection d'encodage" {
    Context "Détection des BOM" {
        It "Détecte correctement l'encodage UTF-8 avec BOM" {
            $utf8BomPath = Join-Path -Path $samplesPath -ChildPath "utf8-bom.txt"
            if (Test-Path -Path $utf8BomPath -PathType Leaf) {
                $result = Get-FileEncoding -FilePath $utf8BomPath
                $result.Encoding | Should -Be "UTF-8-BOM"
                $result.BOM | Should -Be $true
            }
            else {
                Set-ItResult -Skipped -Because "Le fichier d'échantillon n'existe pas : $utf8BomPath"
            }
        }

        It "Détecte correctement l'encodage UTF-16LE avec BOM" {
            $utf16LEBomPath = Join-Path -Path $samplesPath -ChildPath "utf16le-bom.txt"
            if (Test-Path -Path $utf16LEBomPath -PathType Leaf) {
                $result = Get-FileEncoding -FilePath $utf16LEBomPath
                $result.Encoding | Should -Be "UTF-16LE"
                $result.BOM | Should -Be $true
            }
            else {
                Set-ItResult -Skipped -Because "Le fichier d'échantillon n'existe pas : $utf16LEBomPath"
            }
        }
    }

    Context "Détection sans BOM" {
        It "Détecte correctement l'encodage ASCII" {
            $asciiPath = Join-Path -Path $samplesPath -ChildPath "ascii.txt"
            if (Test-Path -Path $asciiPath -PathType Leaf) {
                $result = Get-FileEncoding -FilePath $asciiPath
                $result.Encoding | Should -Be "ASCII"
                $result.BOM | Should -Be $false
            }
            else {
                Set-ItResult -Skipped -Because "Le fichier d'échantillon n'existe pas : $asciiPath"
            }
        }

        It "Détecte correctement l'encodage UTF-8 sans BOM" {
            $utf8Path = Join-Path -Path $samplesPath -ChildPath "utf8.txt"
            if (Test-Path -Path $utf8Path -PathType Leaf) {
                $result = Get-FileEncoding -FilePath $utf8Path
                $result.Encoding | Should -Be "UTF-8"
                $result.BOM | Should -Be $false
            }
            else {
                Set-ItResult -Skipped -Because "Le fichier d'échantillon n'existe pas : $utf8Path"
            }
        }
    }

    Context "Gestion des erreurs" {
        It "Retourne FILE_NOT_FOUND pour un fichier inexistant" {
            $nonExistentPath = Join-Path -Path $samplesPath -ChildPath "non_existent.txt"
            $result = Get-FileEncoding -FilePath $nonExistentPath
            $result.Encoding | Should -Be "FILE_NOT_FOUND"
        }
    }
}

#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiÃ©s pour la fonction de dÃ©tection de format.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiÃ©s pour valider le bon fonctionnement
    de la fonction de dÃ©tection de format.

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
        Write-Error "Impossible d'installer le module Pester. Les tests ne peuvent pas Ãªtre exÃ©cutÃ©s."
        return
    }
}

# Chemin vers le script Ã  tester
$scriptPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\analysis\Improved-FormatDetection.ps1"

# Chemin vers le rÃ©pertoire d'Ã©chantillons
$samplesPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\samples\formats"

# GÃ©nÃ©rer les fichiers d'Ã©chantillon si nÃ©cessaire
if (-not (Test-Path -Path $samplesPath -PathType Container)) {
    $generateSamplesScript = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\Generate-TestSamples.ps1"
    if (Test-Path -Path $generateSamplesScript -PathType Leaf) {
        Write-Host "GÃ©nÃ©ration des fichiers d'Ã©chantillon..." -ForegroundColor Cyan
        & $generateSamplesScript -Force
    }
    else {
        Write-Error "Le script de gÃ©nÃ©ration des Ã©chantillons n'existe pas : $generateSamplesScript"
        return
    }
}

# Charger le script Ã  tester
$scriptContent = Get-Content -Path $scriptPath -Raw
$scriptBlock = [ScriptBlock]::Create($scriptContent)
. $scriptBlock

# DÃ©marrer les tests Pester
Describe "Tests simplifiÃ©s de dÃ©tection de format" {
    Context "DÃ©tection par extension" {
        It "DÃ©tecte correctement le format XML" {
            $xmlPath = Join-Path -Path $samplesPath -ChildPath "sample.xml"
            if (Test-Path -Path $xmlPath -PathType Leaf) {
                $result = Detect-ImprovedFormat -FilePath $xmlPath -DetectEncoding -DetailedOutput
                $result.DetectedFormat | Should -Be "XML"
            }
            else {
                Set-ItResult -Skipped -Because "Le fichier d'Ã©chantillon n'existe pas : $xmlPath"
            }
        }

        It "DÃ©tecte correctement le format JSON" {
            $jsonPath = Join-Path -Path $samplesPath -ChildPath "sample.json"
            if (Test-Path -Path $jsonPath -PathType Leaf) {
                $result = Detect-ImprovedFormat -FilePath $jsonPath -DetectEncoding -DetailedOutput
                $result.DetectedFormat | Should -Be "JSON"
            }
            else {
                Set-ItResult -Skipped -Because "Le fichier d'Ã©chantillon n'existe pas : $jsonPath"
            }
        }

        It "DÃ©tecte correctement le format HTML" {
            $htmlPath = Join-Path -Path $samplesPath -ChildPath "sample.html"
            if (Test-Path -Path $htmlPath -PathType Leaf) {
                $result = Detect-ImprovedFormat -FilePath $htmlPath -DetectEncoding -DetailedOutput
                $result.DetectedFormat | Should -Be "HTML"
            }
            else {
                Set-ItResult -Skipped -Because "Le fichier d'Ã©chantillon n'existe pas : $htmlPath"
            }
        }
    }

    Context "DÃ©tection par contenu" {
        It "DÃ©tecte correctement le format XML mÃªme avec une extension incorrecte" {
            $xmlPath = Join-Path -Path $samplesPath -ChildPath "sample.xml"
            $xmlWrongExtPath = Join-Path -Path $samplesPath -ChildPath "xml_with_wrong_ext.txt"

            if (Test-Path -Path $xmlPath -PathType Leaf) {
                Copy-Item -Path $xmlPath -Destination $xmlWrongExtPath -Force
                $result = Detect-ImprovedFormat -FilePath $xmlWrongExtPath -DetectEncoding -DetailedOutput
                $result.DetectedFormat | Should -Be "XML"
                Remove-Item -Path $xmlWrongExtPath -Force -ErrorAction SilentlyContinue
            }
            else {
                Set-ItResult -Skipped -Because "Le fichier d'Ã©chantillon n'existe pas : $xmlPath"
            }
        }
    }

    Context "Gestion des erreurs" {
        It "GÃ¨re correctement un fichier inexistant" {
            $nonExistentPath = Join-Path -Path $samplesPath -ChildPath "non_existent.txt"
            { Detect-ImprovedFormat -FilePath $nonExistentPath -DetectEncoding -DetailedOutput } | Should -Throw
        }
    }
}

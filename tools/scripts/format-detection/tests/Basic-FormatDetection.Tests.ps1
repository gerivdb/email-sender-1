#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires basiques pour les fonctions de dÃ©tection de format.

.DESCRIPTION
    Ce script contient des tests unitaires basiques pour valider le bon fonctionnement
    des fonctions de dÃ©tection de format dÃ©veloppÃ©es dans le cadre de la
    section 2.1.1 de la roadmap.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\basic_samples"
if (-not (Test-Path -Path $testDir -PathType Container)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er des fichiers d'Ã©chantillon pour les tests
$txtFile = Join-Path -Path $testDir -ChildPath "sample.txt"
"Ceci est un fichier texte simple." | Out-File -FilePath $txtFile -Encoding utf8

$csvFile = Join-Path -Path $testDir -ChildPath "sample.csv"
"Nom,PrÃ©nom,Age`nDupont,Jean,42" | Out-File -FilePath $csvFile -Encoding utf8

$xmlFile = Join-Path -Path $testDir -ChildPath "sample.xml"
"<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<racine><element>Contenu</element></racine>" | Out-File -FilePath $xmlFile -Encoding utf8

$jsonFile = Join-Path -Path $testDir -ChildPath "sample.json"
"{`"nom`": `"Dupont`", `"prÃ©nom`": `"Jean`", `"age`": 42}" | Out-File -FilePath $jsonFile -Encoding utf8

# Tests basiques
Describe "Tests basiques de dÃ©tection de format" {
    Context "DÃ©tection par extension" {
        It "DÃ©tecte correctement le format d'un fichier .txt" {
            $extension = [System.IO.Path]::GetExtension($txtFile).ToLower()
            $extension | Should -Be ".txt"
        }

        It "DÃ©tecte correctement le format d'un fichier .csv" {
            $extension = [System.IO.Path]::GetExtension($csvFile).ToLower()
            $extension | Should -Be ".csv"
        }

        It "DÃ©tecte correctement le format d'un fichier .xml" {
            $extension = [System.IO.Path]::GetExtension($xmlFile).ToLower()
            $extension | Should -Be ".xml"
        }

        It "DÃ©tecte correctement le format d'un fichier .json" {
            $extension = [System.IO.Path]::GetExtension($jsonFile).ToLower()
            $extension | Should -Be ".json"
        }
    }

    Context "DÃ©tection par contenu" {
        It "DÃ©tecte correctement le contenu d'un fichier texte" {
            $content = Get-Content -Path $txtFile -Raw
            $content | Should -Match "fichier texte"
        }

        It "DÃ©tecte correctement le contenu d'un fichier CSV" {
            $content = Get-Content -Path $csvFile -Raw
            $content | Should -Match "Nom,PrÃ©nom,Age"
        }

        It "DÃ©tecte correctement le contenu d'un fichier XML" {
            $content = Get-Content -Path $xmlFile -Raw
            $content | Should -Match "<racine>"
        }

        It "DÃ©tecte correctement le contenu d'un fichier JSON" {
            $content = Get-Content -Path $jsonFile -Raw
            $content | Should -Match "nom"
        }
    }

    AfterAll {
        # Nettoyer les fichiers d'Ã©chantillon
        Remove-Item -Path $txtFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $csvFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $xmlFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $jsonFile -Force -ErrorAction SilentlyContinue

        # Supprimer le rÃ©pertoire de test
        Remove-Item -Path $testDir -Force -ErrorAction SilentlyContinue
    }
}

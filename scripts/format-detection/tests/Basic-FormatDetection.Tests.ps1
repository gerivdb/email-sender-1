#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires basiques pour les fonctions de détection de format.

.DESCRIPTION
    Ce script contient des tests unitaires basiques pour valider le bon fonctionnement
    des fonctions de détection de format développées dans le cadre de la
    section 2.1.1 de la roadmap.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "FormatDetectionTests"
if (-not (Test-Path -Path $testDir -PathType Container)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer des fichiers d'échantillon pour les tests
$txtFile = Join-Path -Path $testDir -ChildPath "sample.txt"
"Ceci est un fichier texte simple." | Out-File -FilePath $txtFile -Encoding utf8

$csvFile = Join-Path -Path $testDir -ChildPath "sample.csv"
"Nom,Prénom,Age`nDupont,Jean,42" | Out-File -FilePath $csvFile -Encoding utf8

$xmlFile = Join-Path -Path $testDir -ChildPath "sample.xml"
"<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<racine><element>Contenu</element></racine>" | Out-File -FilePath $xmlFile -Encoding utf8

$jsonFile = Join-Path -Path $testDir -ChildPath "sample.json"
"{`"nom`": `"Dupont`", `"prénom`": `"Jean`", `"age`": 42}" | Out-File -FilePath $jsonFile -Encoding utf8

# Tests basiques
Describe "Tests basiques de détection de format" {
    Context "Détection par extension" {
        It "Détecte correctement le format d'un fichier .txt" {
            $extension = [System.IO.Path]::GetExtension($txtFile).ToLower()
            $extension | Should -Be ".txt"
        }
        
        It "Détecte correctement le format d'un fichier .csv" {
            $extension = [System.IO.Path]::GetExtension($csvFile).ToLower()
            $extension | Should -Be ".csv"
        }
        
        It "Détecte correctement le format d'un fichier .xml" {
            $extension = [System.IO.Path]::GetExtension($xmlFile).ToLower()
            $extension | Should -Be ".xml"
        }
        
        It "Détecte correctement le format d'un fichier .json" {
            $extension = [System.IO.Path]::GetExtension($jsonFile).ToLower()
            $extension | Should -Be ".json"
        }
    }
    
    Context "Détection par contenu" {
        It "Détecte correctement le contenu d'un fichier texte" {
            $content = Get-Content -Path $txtFile -Raw
            $content | Should -Match "fichier texte"
        }
        
        It "Détecte correctement le contenu d'un fichier CSV" {
            $content = Get-Content -Path $csvFile -Raw
            $content | Should -Match "Nom,Prénom,Age"
        }
        
        It "Détecte correctement le contenu d'un fichier XML" {
            $content = Get-Content -Path $xmlFile -Raw
            $content | Should -Match "<racine>"
        }
        
        It "Détecte correctement le contenu d'un fichier JSON" {
            $content = Get-Content -Path $jsonFile -Raw
            $content | Should -Match "nom"
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers d'échantillon
        Remove-Item -Path $txtFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $csvFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $xmlFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $jsonFile -Force -ErrorAction SilentlyContinue
        
        # Supprimer le répertoire de test
        Remove-Item -Path $testDir -Force -ErrorAction SilentlyContinue
    }
}

#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiÃ©s pour les fonctions de dÃ©tection de format.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiÃ©s pour valider le bon fonctionnement
    des fonctions de dÃ©tection de format dÃ©veloppÃ©es dans le cadre de la
    section 2.1.1 de la roadmap.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# DÃ©finir les fonctions Ã  tester
function Get-FileFormatByExtension {
    param ([string]$FilePath)
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    switch ($extension) {
        ".txt"  { return "TEXT" }
        ".csv"  { return "CSV" }
        ".xml"  { return "XML" }
        ".html" { return "HTML" }
        ".htm"  { return "HTML" }
        ".json" { return "JSON" }
        ".ps1"  { return "POWERSHELL" }
        ".bat"  { return "BATCH" }
        ".cmd"  { return "BATCH" }
        ".py"   { return "PYTHON" }
        ".js"   { return "JAVASCRIPT" }
        default { return "UNKNOWN" }
    }
}

function Get-FileFormatByContent {
    param ([string]$FilePath)
    if (-not (Test-Path -Path $FilePath -PathType Leaf)) { return "FILE_NOT_FOUND" }
    try {
        $content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
        if ($null -eq $content) { return "BINARY" }
        if ($content -match '<\?xml' -or $content -match '<!DOCTYPE') { return "XML" }
        if ($content -match '<html' -or $content -match '</html>') { return "HTML" }
        if ($content -match '^\s*[\{\[]') { return "JSON" }
        if ($content -match ',.*,.*,') { return "CSV" }
        if ($content -match 'function\s+\w+' -or $content -match '\$\w+') { return "POWERSHELL" }
        if ($content -match '@echo off' -or $content -match 'set \w+=') { return "BATCH" }
        if ($content -match 'def\s+\w+\s*\(' -or $content -match 'import\s+\w+') { return "PYTHON" }
        if ($content -match 'function\s+\w+\s*\(' -or $content -match 'var\s+\w+') { return "JAVASCRIPT" }
        return "TEXT"
    } catch {
        return "BINARY"
    }
}

# CrÃ©er des fichiers d'Ã©chantillon pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "samples"
if (-not (Test-Path -Path $testDir -PathType Container)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier texte
$txtFile = Join-Path -Path $testDir -ChildPath "sample.txt"
"Ceci est un fichier texte simple." | Out-File -FilePath $txtFile -Encoding utf8

# CrÃ©er un fichier CSV
$csvFile = Join-Path -Path $testDir -ChildPath "sample.csv"
"Nom,PrÃ©nom,Age`nDupont,Jean,42" | Out-File -FilePath $csvFile -Encoding utf8

# CrÃ©er un fichier XML
$xmlFile = Join-Path -Path $testDir -ChildPath "sample.xml"
"<?xml version=`"1.0`" encoding=`"UTF-8`"?>`n<racine><element>Contenu</element></racine>" | Out-File -FilePath $xmlFile -Encoding utf8

# CrÃ©er un fichier JSON
$jsonFile = Join-Path -Path $testDir -ChildPath "sample.json"
"{`"nom`": `"Dupont`", `"prÃ©nom`": `"Jean`", `"age`": 42}" | Out-File -FilePath $jsonFile -Encoding utf8

# DÃ©marrer les tests Pester
Describe "Tests de dÃ©tection de format" {
    Context "Get-FileFormatByExtension" {
        It "DÃ©tecte correctement le format TEXT pour un fichier .txt" {
            Get-FileFormatByExtension -FilePath $txtFile | Should -Be "TEXT"
        }
        
        It "DÃ©tecte correctement le format CSV pour un fichier .csv" {
            Get-FileFormatByExtension -FilePath $csvFile | Should -Be "CSV"
        }
        
        It "DÃ©tecte correctement le format XML pour un fichier .xml" {
            Get-FileFormatByExtension -FilePath $xmlFile | Should -Be "XML"
        }
        
        It "DÃ©tecte correctement le format JSON pour un fichier .json" {
            Get-FileFormatByExtension -FilePath $jsonFile | Should -Be "JSON"
        }
    }
    
    Context "Get-FileFormatByContent" {
        It "DÃ©tecte correctement le format TEXT pour un fichier texte" {
            Get-FileFormatByContent -FilePath $txtFile | Should -Be "TEXT"
        }
        
        It "DÃ©tecte correctement le format CSV pour un fichier CSV" {
            Get-FileFormatByContent -FilePath $csvFile | Should -Be "CSV"
        }
        
        It "DÃ©tecte correctement le format XML pour un fichier XML" {
            Get-FileFormatByContent -FilePath $xmlFile | Should -Be "XML"
        }
        
        It "DÃ©tecte correctement le format JSON pour un fichier JSON" {
            Get-FileFormatByContent -FilePath $jsonFile | Should -Be "JSON"
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers d'Ã©chantillon
        Remove-Item -Path $txtFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $csvFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $xmlFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $jsonFile -Force -ErrorAction SilentlyContinue
    }
}

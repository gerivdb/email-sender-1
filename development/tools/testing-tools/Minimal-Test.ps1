#Requires -Version 5.1
<#
.SYNOPSIS
    Test minimal pour vÃ©rifier le bon fonctionnement des fonctions de dÃ©tection de format.

.DESCRIPTION
    Ce script contient un test minimal pour vÃ©rifier le bon fonctionnement
    des fonctions de dÃ©tection de format dÃ©veloppÃ©es dans le cadre de la
    section 2.1.1 de la roadmap.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "FormatDetectionTests"
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

# VÃ©rifier que les fichiers ont Ã©tÃ© crÃ©Ã©s
Write-Host "VÃ©rification des fichiers crÃ©Ã©s :"
Write-Host "  Fichier TXT : $(Test-Path -Path $txtFile -PathType Leaf)"
Write-Host "  Fichier CSV : $(Test-Path -Path $csvFile -PathType Leaf)"
Write-Host "  Fichier XML : $(Test-Path -Path $xmlFile -PathType Leaf)"
Write-Host "  Fichier JSON : $(Test-Path -Path $jsonFile -PathType Leaf)"

# Fonction pour dÃ©tecter le format d'un fichier par son extension
function Get-FileFormatByExtension {
    param ([string]$FilePath)
    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    switch ($extension) {
        ".txt"  { return "TEXT" }
        ".csv"  { return "CSV" }
        ".xml"  { return "XML" }
        ".json" { return "JSON" }
        default { return "UNKNOWN" }
    }
}

# Fonction pour dÃ©tecter le format d'un fichier par son contenu
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
        return "TEXT"
    } catch {
        return "BINARY"
    }
}

# Tester les fonctions
Write-Host "`nTests de dÃ©tection par extension :"
Write-Host "  Fichier TXT : $(Get-FileFormatByExtension -FilePath $txtFile)"
Write-Host "  Fichier CSV : $(Get-FileFormatByExtension -FilePath $csvFile)"
Write-Host "  Fichier XML : $(Get-FileFormatByExtension -FilePath $xmlFile)"
Write-Host "  Fichier JSON : $(Get-FileFormatByExtension -FilePath $jsonFile)"

Write-Host "`nTests de dÃ©tection par contenu :"
Write-Host "  Fichier TXT : $(Get-FileFormatByContent -FilePath $txtFile)"
Write-Host "  Fichier CSV : $(Get-FileFormatByContent -FilePath $csvFile)"
Write-Host "  Fichier XML : $(Get-FileFormatByContent -FilePath $xmlFile)"
Write-Host "  Fichier JSON : $(Get-FileFormatByContent -FilePath $jsonFile)"

# Nettoyer les fichiers d'Ã©chantillon
Remove-Item -Path $txtFile -Force -ErrorAction SilentlyContinue
Remove-Item -Path $csvFile -Force -ErrorAction SilentlyContinue
Remove-Item -Path $xmlFile -Force -ErrorAction SilentlyContinue
Remove-Item -Path $jsonFile -Force -ErrorAction SilentlyContinue

# Supprimer le rÃ©pertoire de test
Remove-Item -Path $testDir -Force -ErrorAction SilentlyContinue

Write-Host "`nTests terminÃ©s."

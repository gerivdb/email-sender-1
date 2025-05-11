<#
.SYNOPSIS
    Test simple pour le convertisseur de format.

.DESCRIPTION
    Ce script teste les fonctionnalités de base du convertisseur de format.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer les modules requis
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$formatConverterPath = Join-Path -Path $scriptDir -ChildPath "FormatConverter.ps1"

if (Test-Path -Path $formatConverterPath) {
    . $formatConverterPath
}
else {
    throw "Le module FormatConverter.ps1 est requis mais n'a pas été trouvé à l'emplacement: $formatConverterPath"
}

# Créer un répertoire de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "FormatConverterTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Host "Répertoire de test créé: $testDir" -ForegroundColor Cyan

# Créer un objet de test
$testObject = @{
    Id = [guid]::NewGuid().ToString()
    Name = "Objet de test"
    Properties = @{
        Color = "Red"
        Size = 100
    }
    Items = @(1, 2, 3)
}

# Test 1: Créer un convertisseur de format
Write-Host "Test 1: Création d'un convertisseur de format" -ForegroundColor Cyan
$converter = New-FormatConverter -EnableDebug

if ($null -ne $converter) {
    Write-Host "Convertisseur de format créé avec succès" -ForegroundColor Green
}
else {
    Write-Host "Échec de la création du convertisseur de format" -ForegroundColor Red
    exit 1
}

# Test 2: Convertir un objet en JSON
Write-Host "Test 2: Conversion d'un objet en JSON" -ForegroundColor Cyan
$jsonContent = $testObject | ConvertTo-Json -Depth 10
$jsonPath = Join-Path -Path $testDir -ChildPath "test_object.json"
$jsonContent | Out-File -FilePath $jsonPath -Encoding utf8

if (Test-Path -Path $jsonPath) {
    Write-Host "Objet JSON créé avec succès: $jsonPath" -ForegroundColor Green
}
else {
    Write-Host "Échec de la création de l'objet JSON" -ForegroundColor Red
    exit 1
}

# Test 3: Détecter automatiquement le format d'un contenu
Write-Host "Test 3: Détection automatique du format d'un contenu" -ForegroundColor Cyan
$jsonContent = Get-Content -Path $jsonPath -Raw
$detectedFormat = $converter.DetectFormat($jsonContent)

if ($detectedFormat -eq "JSON") {
    Write-Host "Format JSON détecté avec succès" -ForegroundColor Green
}
else {
    Write-Host "Échec de la détection du format JSON: $detectedFormat" -ForegroundColor Red
    exit 1
}

# Test 4: Convertir un contenu JSON en XML
Write-Host "Test 4: Conversion d'un contenu JSON en XML" -ForegroundColor Cyan
try {
    $xmlContent = $converter.ConvertFormat($jsonContent, "JSON", "XML")
    
    if (-not [string]::IsNullOrEmpty($xmlContent)) {
        Write-Host "Contenu JSON converti en XML avec succès" -ForegroundColor Green
        $xmlPath = Join-Path -Path $testDir -ChildPath "test_object.xml"
        $xmlContent | Out-File -FilePath $xmlPath -Encoding utf8
        Write-Host "Contenu XML sauvegardé dans: $xmlPath" -ForegroundColor Green
    }
    else {
        Write-Host "Échec de la conversion du contenu JSON en XML" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Erreur lors de la conversion du contenu JSON en XML: $_" -ForegroundColor Red
    exit 1
}

# Test 5: Convertir un fichier JSON en XML
Write-Host "Test 5: Conversion d'un fichier JSON en XML" -ForegroundColor Cyan
try {
    $xmlFilePath = $converter.ConvertFile($jsonPath, $null, "XML")
    
    if (-not [string]::IsNullOrEmpty($xmlFilePath) -and (Test-Path -Path $xmlFilePath)) {
        Write-Host "Fichier JSON converti en XML avec succès: $xmlFilePath" -ForegroundColor Green
    }
    else {
        Write-Host "Échec de la conversion du fichier JSON en XML" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Erreur lors de la conversion du fichier JSON en XML: $_" -ForegroundColor Red
    exit 1
}

# Nettoyage
Remove-Item -Path $testDir -Recurse -Force
Write-Host "Tests terminés avec succès" -ForegroundColor Green

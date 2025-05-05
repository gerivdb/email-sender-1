#Requires -Version 5.1
<#
.SYNOPSIS
Script de test pour la fonction Export-GenericExtractedInfo.

.DESCRIPTION
Ce script teste l'exportation d'objets d'information extraite génériques vers différents formats.

.NOTES
Date de création : 2025-05-15
#>

# Importer les fonctions directement
$scriptPath = "$PSScriptRoot\..\Public\Types\Export-GenericExtractedInfo.ps1"
Write-Host "Importation du script : $scriptPath" -ForegroundColor Cyan
. $scriptPath

# Créer un répertoire de sortie pour les tests
$outputDir = Join-Path -Path $env:TEMP -ChildPath "GenericExportTest"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Créer un objet ExtractedInfo de base pour les tests
function New-TestExtractedInfo {
    param (
        [string]$Source = "Test",
        [string]$Type = "ExtractedInfo",
        [hashtable]$Properties = @{},
        [hashtable]$Metadata = @{}
    )

    $info = @{
        Id               = [guid]::NewGuid().ToString()
        _Type            = $Type
        Source           = $Source
        ExtractedAt      = [datetime]::Now
        LastModifiedDate = [datetime]::Now
        ProcessingState  = "Raw"
        ConfidenceScore  = 75
        Metadata         = $Metadata.Clone()
    }

    # Ajouter les propriétés spécifiques
    foreach ($key in $Properties.Keys) {
        $info[$key] = $Properties[$key]
    }

    return $info
}

# Créer des objets de test
$basicInfo = New-TestExtractedInfo -Source "document.txt"

$customInfo = New-TestExtractedInfo -Source "data.json" -Type "CustomExtractedInfo" -Properties @{
    CustomProperty1 = "Value1"
    CustomProperty2 = 42
    CustomProperty3 = @{
        NestedProperty1 = "NestedValue1"
        NestedProperty2 = @(1, 2, 3)
    }
} -Metadata @{
    Author       = "Test User"
    CreationDate = [datetime]::Now.ToString("o")
    Tags         = @("test", "generic", "export")
}

# Test d'exportation en JSON
Write-Host "Test d'exportation en JSON..." -ForegroundColor Green
$jsonBasic = Export-GenericExtractedInfo -Info $basicInfo -Format "JSON"
$jsonBasicPath = Join-Path -Path $outputDir -ChildPath "basic.json"
$jsonBasic | Out-File -FilePath $jsonBasicPath -Encoding utf8
Write-Host "Fichier JSON créé : $jsonBasicPath" -ForegroundColor Green

$jsonCustom = Export-GenericExtractedInfo -Info $customInfo -Format "JSON" -IncludeMetadata
$jsonCustomPath = Join-Path -Path $outputDir -ChildPath "custom.json"
$jsonCustom | Out-File -FilePath $jsonCustomPath -Encoding utf8
Write-Host "Fichier JSON avec métadonnées créé : $jsonCustomPath" -ForegroundColor Green

# Test d'exportation en XML
Write-Host "Test d'exportation en XML..." -ForegroundColor Green
$xmlCustom = Export-GenericExtractedInfo -Info $customInfo -Format "XML" -IncludeMetadata
$xmlCustomPath = Join-Path -Path $outputDir -ChildPath "custom.xml"
$xmlCustom | Out-File -FilePath $xmlCustomPath -Encoding utf8
Write-Host "Fichier XML créé : $xmlCustomPath" -ForegroundColor Green

# Test d'exportation en CSV
Write-Host "Test d'exportation en CSV..." -ForegroundColor Green
$csvCustom = Export-GenericExtractedInfo -Info $customInfo -Format "CSV" -IncludeMetadata
$csvCustomPath = Join-Path -Path $outputDir -ChildPath "custom.csv"
$csvCustom | Out-File -FilePath $csvCustomPath -Encoding utf8
Write-Host "Fichier CSV créé : $csvCustomPath" -ForegroundColor Green

# Test d'exportation en TXT
Write-Host "Test d'exportation en TXT..." -ForegroundColor Green
$txtCustom = Export-GenericExtractedInfo -Info $customInfo -Format "TXT" -IncludeMetadata
$txtCustomPath = Join-Path -Path $outputDir -ChildPath "custom.txt"
$txtCustom | Out-File -FilePath $txtCustomPath -Encoding utf8
Write-Host "Fichier TXT créé : $txtCustomPath" -ForegroundColor Green

# Test d'exportation en HTML
Write-Host "Test d'exportation en HTML..." -ForegroundColor Green
$htmlCustom = Export-GenericExtractedInfo -Info $customInfo -Format "HTML" -IncludeMetadata
$htmlCustomPath = Join-Path -Path $outputDir -ChildPath "custom.html"
$htmlCustom | Out-File -FilePath $htmlCustomPath -Encoding utf8
Write-Host "Fichier HTML créé : $htmlCustomPath" -ForegroundColor Green

# Test d'exportation en HTML avec thème sombre
Write-Host "Test d'exportation en HTML avec thème sombre..." -ForegroundColor Green
$htmlDarkCustom = Export-GenericExtractedInfo -Info $customInfo -Format "HTML" -IncludeMetadata -ExportOptions @{ Theme = "Dark" }
$htmlDarkCustomPath = Join-Path -Path $outputDir -ChildPath "custom_dark.html"
$htmlDarkCustom | Out-File -FilePath $htmlDarkCustomPath -Encoding utf8
Write-Host "Fichier HTML (thème sombre) créé : $htmlDarkCustomPath" -ForegroundColor Green

# Test d'exportation en Markdown
Write-Host "Test d'exportation en Markdown..." -ForegroundColor Green
$mdCustom = Export-GenericExtractedInfo -Info $customInfo -Format "MARKDOWN" -IncludeMetadata
$mdCustomPath = Join-Path -Path $outputDir -ChildPath "custom.md"
$mdCustom | Out-File -FilePath $mdCustomPath -Encoding utf8
Write-Host "Fichier Markdown créé : $mdCustomPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $htmlCustomPath
Start-Process $mdCustomPath

Write-Host "Tests terminés avec succès !" -ForegroundColor Green

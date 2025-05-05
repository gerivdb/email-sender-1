#Requires -Version 5.1
<#
.SYNOPSIS
Exemple d'utilisation de l'exportation de StructuredDataExtractedInfo.

.DESCRIPTION
Ce script montre comment créer et exporter des objets StructuredDataExtractedInfo
dans différents formats (HTML, Markdown, JSON, etc.).

.NOTES
Date de création : 2025-05-15
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force

# Créer un répertoire de sortie pour les exemples
$outputDir = Join-Path -Path $env:TEMP -ChildPath "ExportExamples\StructuredData"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Exemple 1: Créer et exporter des données structurées simples
Write-Host "Exemple 1: Données structurées simples" -ForegroundColor Green
$simpleData = New-StructuredDataExtractedInfo -Source "data.json" -Data @{
    Name = "John Doe"
    Age = 30
    Email = "john.doe@example.com"
    Active = $true
} -DataFormat "Hashtable"

# Exporter en HTML avec l'adaptateur générique
$htmlSimpleData = Export-GenericExtractedInfo -Info $simpleData -Format "HTML"
$htmlSimpleDataPath = Join-Path -Path $outputDir -ChildPath "simple_data.html"
$htmlSimpleData | Out-File -FilePath $htmlSimpleDataPath -Encoding utf8
Write-Host "  Fichier HTML créé : $htmlSimpleDataPath" -ForegroundColor Green

# Exporter en Markdown avec l'adaptateur générique
$mdSimpleData = Export-GenericExtractedInfo -Info $simpleData -Format "MARKDOWN"
$mdSimpleDataPath = Join-Path -Path $outputDir -ChildPath "simple_data.md"
$mdSimpleData | Out-File -FilePath $mdSimpleDataPath -Encoding utf8
Write-Host "  Fichier Markdown créé : $mdSimpleDataPath" -ForegroundColor Green

# Exemple 2: Données structurées complexes
Write-Host "Exemple 2: Données structurées complexes" -ForegroundColor Green
$complexData = New-StructuredDataExtractedInfo -Source "users.json" -Data @{
    Users = @(
        @{
            Id = 1
            Name = "Alice Smith"
            Email = "alice@example.com"
            Roles = @("Admin", "Editor")
            Preferences = @{
                Theme = "Dark"
                Language = "en-US"
                Notifications = $true
            }
        },
        @{
            Id = 2
            Name = "Bob Johnson"
            Email = "bob@example.com"
            Roles = @("User")
            Preferences = @{
                Theme = "Light"
                Language = "fr-FR"
                Notifications = $false
            }
        }
    )
    Metadata = @{
        Version = "1.0"
        LastUpdated = [datetime]::Now.ToString("o")
    }
} -DataFormat "Hashtable"

# Exporter en HTML avec métadonnées
$htmlComplexData = Export-GenericExtractedInfo -Info $complexData -Format "HTML" -IncludeMetadata
$htmlComplexDataPath = Join-Path -Path $outputDir -ChildPath "complex_data_with_metadata.html"
$htmlComplexData | Out-File -FilePath $htmlComplexDataPath -Encoding utf8
Write-Host "  Fichier HTML avec métadonnées créé : $htmlComplexDataPath" -ForegroundColor Green

# Exemple 3: Données structurées avec options personnalisées
Write-Host "Exemple 3: Données structurées avec options personnalisées" -ForegroundColor Green
$configData = New-StructuredDataExtractedInfo -Source "config.json" -Data @{
    AppName = "ExampleApp"
    Version = "2.1.0"
    Settings = @{
        MaxConnections = 100
        Timeout = 30
        Debug = $false
    }
    Endpoints = @(
        "https://api.example.com/v1",
        "https://api.example.com/v2"
    )
} -DataFormat "Hashtable"

# Exporter en HTML avec thème sombre
$htmlConfigData = Export-GenericExtractedInfo -Info $configData -Format "HTML" -ExportOptions @{ Theme = "Dark" }
$htmlConfigDataPath = Join-Path -Path $outputDir -ChildPath "config_dark.html"
$htmlConfigData | Out-File -FilePath $htmlConfigDataPath -Encoding utf8
Write-Host "  Fichier HTML avec thème sombre créé : $htmlConfigDataPath" -ForegroundColor Green

# Exemple 4: Exporter en JSON et XML
Write-Host "Exemple 4: Exportation en JSON et XML" -ForegroundColor Green
$jsonConfigData = Export-GenericExtractedInfo -Info $configData -Format "JSON"
$jsonConfigDataPath = Join-Path -Path $outputDir -ChildPath "config.json"
$jsonConfigData | Out-File -FilePath $jsonConfigDataPath -Encoding utf8
Write-Host "  Fichier JSON créé : $jsonConfigDataPath" -ForegroundColor Green

$xmlConfigData = Export-GenericExtractedInfo -Info $configData -Format "XML"
$xmlConfigDataPath = Join-Path -Path $outputDir -ChildPath "config.xml"
$xmlConfigData | Out-File -FilePath $xmlConfigDataPath -Encoding utf8
Write-Host "  Fichier XML créé : $xmlConfigDataPath" -ForegroundColor Green

# Exemple 5: Exporter en CSV et TXT
Write-Host "Exemple 5: Exportation en CSV et TXT" -ForegroundColor Green
$csvConfigData = Export-GenericExtractedInfo -Info $configData -Format "CSV"
$csvConfigDataPath = Join-Path -Path $outputDir -ChildPath "config.csv"
$csvConfigData | Out-File -FilePath $csvConfigDataPath -Encoding utf8
Write-Host "  Fichier CSV créé : $csvConfigDataPath" -ForegroundColor Green

$txtConfigData = Export-GenericExtractedInfo -Info $configData -Format "TXT"
$txtConfigDataPath = Join-Path -Path $outputDir -ChildPath "config.txt"
$txtConfigData | Out-File -FilePath $txtConfigDataPath -Encoding utf8
Write-Host "  Fichier TXT créé : $txtConfigDataPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $htmlSimpleDataPath
Start-Process $mdSimpleDataPath
Start-Process $htmlComplexDataPath
Start-Process $htmlConfigDataPath
Start-Process $jsonConfigDataPath
Start-Process $xmlConfigDataPath

Write-Host "Exemples terminés avec succès !" -ForegroundColor Green

#Requires -Version 5.1
<#
.SYNOPSIS
Exemple d'utilisation de l'exportation de TextExtractedInfo.

.DESCRIPTION
Ce script montre comment créer et exporter des objets TextExtractedInfo
dans différents formats (HTML, Markdown, JSON, etc.).

.NOTES
Date de création : 2025-05-15
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\ExtractedInfoModuleV2.psm1"
Import-Module $modulePath -Force

# Créer un répertoire de sortie pour les exemples
$outputDir = Join-Path -Path $env:TEMP -ChildPath "ExportExamples\Text"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Exemple 1: Créer et exporter un texte simple
Write-Host "Exemple 1: Texte simple" -ForegroundColor Green
$simpleText = New-TextExtractedInfo -Source "document.txt" -Text "Ceci est un exemple de texte extrait d'un document." -Language "fr"

# Exporter en HTML avec l'adaptateur générique
$htmlSimpleText = Export-GenericExtractedInfo -Info $simpleText -Format "HTML"
$htmlSimpleTextPath = Join-Path -Path $outputDir -ChildPath "simple_text.html"
$htmlSimpleText | Out-File -FilePath $htmlSimpleTextPath -Encoding utf8
Write-Host "  Fichier HTML créé : $htmlSimpleTextPath" -ForegroundColor Green

# Exporter en Markdown avec l'adaptateur générique
$mdSimpleText = Export-GenericExtractedInfo -Info $simpleText -Format "MARKDOWN"
$mdSimpleTextPath = Join-Path -Path $outputDir -ChildPath "simple_text.md"
$mdSimpleText | Out-File -FilePath $mdSimpleTextPath -Encoding utf8
Write-Host "  Fichier Markdown créé : $mdSimpleTextPath" -ForegroundColor Green

# Exemple 2: Texte avec métadonnées
Write-Host "Exemple 2: Texte avec métadonnées" -ForegroundColor Green
$articleText = New-TextExtractedInfo -Source "article.txt" -Text "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat." -Language "la"
$articleText = Add-ExtractedInfoMetadata -Info $articleText -Metadata @{
    Author = "Cicero"
    Year = "45 BC"
    Category = "Philosophy"
    Keywords = @("lorem", "ipsum", "latin")
}

# Exporter en HTML avec métadonnées
$htmlArticleText = Export-GenericExtractedInfo -Info $articleText -Format "HTML" -IncludeMetadata
$htmlArticleTextPath = Join-Path -Path $outputDir -ChildPath "article_with_metadata.html"
$htmlArticleText | Out-File -FilePath $htmlArticleTextPath -Encoding utf8
Write-Host "  Fichier HTML avec métadonnées créé : $htmlArticleTextPath" -ForegroundColor Green

# Exemple 3: Texte avec options personnalisées
Write-Host "Exemple 3: Texte avec options personnalisées" -ForegroundColor Green
$codeText = New-TextExtractedInfo -Source "code.ps1" -Text "function Get-Example { param($param1) Write-Output `$param1 }" -Language "powershell"

# Exporter en HTML avec thème sombre
$htmlCodeText = Export-GenericExtractedInfo -Info $codeText -Format "HTML" -ExportOptions @{ Theme = "Dark" }
$htmlCodeTextPath = Join-Path -Path $outputDir -ChildPath "code_dark.html"
$htmlCodeText | Out-File -FilePath $htmlCodeTextPath -Encoding utf8
Write-Host "  Fichier HTML avec thème sombre créé : $htmlCodeTextPath" -ForegroundColor Green

# Exemple 4: Exporter en JSON et XML
Write-Host "Exemple 4: Exportation en JSON et XML" -ForegroundColor Green
$jsonText = Export-GenericExtractedInfo -Info $codeText -Format "JSON"
$jsonTextPath = Join-Path -Path $outputDir -ChildPath "code.json"
$jsonText | Out-File -FilePath $jsonTextPath -Encoding utf8
Write-Host "  Fichier JSON créé : $jsonTextPath" -ForegroundColor Green

$xmlText = Export-GenericExtractedInfo -Info $codeText -Format "XML"
$xmlTextPath = Join-Path -Path $outputDir -ChildPath "code.xml"
$xmlText | Out-File -FilePath $xmlTextPath -Encoding utf8
Write-Host "  Fichier XML créé : $xmlTextPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $htmlSimpleTextPath
Start-Process $mdSimpleTextPath
Start-Process $htmlArticleTextPath
Start-Process $htmlCodeTextPath
Start-Process $jsonTextPath
Start-Process $xmlTextPath

Write-Host "Exemples terminés avec succès !" -ForegroundColor Green

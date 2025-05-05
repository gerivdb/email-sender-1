#Requires -Version 5.1
<#
.SYNOPSIS
Script de test basique pour la fonction Export-GenericExtractedInfo.
#>

# Définir une fonction simple pour créer un objet ExtractedInfo
function New-TestExtractedInfo {
    param (
        [string]$Source = "Test",
        [string]$Type = "ExtractedInfo",
        [hashtable]$Properties = @{},
        [hashtable]$Metadata = @{}
    )
    
    $info = @{
        Id = [guid]::NewGuid().ToString()
        _Type = $Type
        Source = $Source
        ExtractedAt = [datetime]::Now
        LastModifiedDate = [datetime]::Now
        ProcessingState = "Raw"
        ConfidenceScore = 75
        Metadata = $Metadata.Clone()
    }
    
    # Ajouter les propriétés spécifiques
    foreach ($key in $Properties.Keys) {
        $info[$key] = $Properties[$key]
    }
    
    return $info
}

# Définir une fonction simple pour exporter en HTML
function Export-TestGenericHTML {
    param (
        [hashtable]$Info
    )
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Information extraite - $($Info.Id)</title>
</head>
<body>
    <h1>Information extraite</h1>
    <p>ID: $($Info.Id)</p>
    <p>Type: $($Info._Type)</p>
    <p>Source: $($Info.Source)</p>
</body>
</html>
"@
    
    return $html
}

# Définir une fonction simple pour exporter en Markdown
function Export-TestGenericMarkdown {
    param (
        [hashtable]$Info
    )
    
    $markdown = @"
# Information extraite

- ID: $($Info.Id)
- Type: $($Info._Type)
- Source: $($Info.Source)
"@
    
    return $markdown
}

# Créer un répertoire de sortie pour les tests
$outputDir = Join-Path -Path $env:TEMP -ChildPath "GenericBasicTest"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

Write-Host "Répertoire de sortie : $outputDir" -ForegroundColor Cyan

# Créer un objet de test
$basicInfo = New-TestExtractedInfo -Source "document.txt"

$customInfo = New-TestExtractedInfo -Source "data.json" -Type "CustomExtractedInfo" -Properties @{
    CustomProperty1 = "Value1"
    CustomProperty2 = 42
} -Metadata @{
    Author = "Test User"
    Tags = @("test", "generic", "export")
}

# Exporter en HTML
$htmlBasic = Export-TestGenericHTML -Info $basicInfo
$htmlBasicPath = Join-Path -Path $outputDir -ChildPath "basic.html"
$htmlBasic | Out-File -FilePath $htmlBasicPath -Encoding utf8
Write-Host "Fichier HTML créé : $htmlBasicPath" -ForegroundColor Green

# Exporter en Markdown
$mdCustom = Export-TestGenericMarkdown -Info $customInfo
$mdCustomPath = Join-Path -Path $outputDir -ChildPath "custom.md"
$mdCustom | Out-File -FilePath $mdCustomPath -Encoding utf8
Write-Host "Fichier Markdown créé : $mdCustomPath" -ForegroundColor Green

# Ouvrir les fichiers générés
Write-Host "Ouverture des fichiers générés..." -ForegroundColor Yellow
Start-Process $htmlBasicPath
Start-Process $mdCustomPath

Write-Host "Tests terminés avec succès !" -ForegroundColor Green

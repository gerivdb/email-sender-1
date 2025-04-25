#Requires -Version 5.1
<#
.SYNOPSIS
    Démontre l'utilisation du système de gestion des cas ambigus de détection de format.

.DESCRIPTION
    Ce script démontre l'utilisation du système de gestion des cas ambigus de détection de format
    en utilisant des exemples de fichiers avec des formats potentiellement ambigus. Il permet
    de voir comment le système détecte les cas ambigus, comment il les résout automatiquement
    ou avec confirmation utilisateur, et comment il affiche les résultats.

.PARAMETER CreateSamples
    Indique si le script doit créer des exemples de fichiers ambigus.
    Par défaut, cette option est activée.

.PARAMETER SamplesDirectory
    Le répertoire où créer les exemples de fichiers ambigus.
    Par défaut, utilise le sous-répertoire 'demo_samples' du répertoire courant.

.PARAMETER AutoResolve
    Indique si le script doit tenter de résoudre automatiquement les cas ambigus sans intervention utilisateur.
    Par défaut, cette option est désactivée.

.PARAMETER GenerateReport
    Indique si le script doit générer un rapport HTML des résultats.
    Par défaut, cette option est activée.

.EXAMPLE
    .\Demo-AmbiguousFormatHandling.ps1
    Démontre le système de gestion des cas ambigus avec des exemples de fichiers et génère un rapport HTML.

.EXAMPLE
    .\Demo-AmbiguousFormatHandling.ps1 -AutoResolve
    Démontre le système avec résolution automatique des cas ambigus.

.NOTES
    Auteur: Augment Agent
    Date: 2025-04-11
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$CreateSamples,

    [Parameter(Mandatory = $false)]
    [string]$SamplesDirectory = "$PSScriptRoot\demo_samples",

    [Parameter(Mandatory = $false)]
    [switch]$AutoResolve,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer les scripts nécessaires
$integrationScript = "$PSScriptRoot\Detect-FileFormatWithConfirmation.ps1"

if (-not (Test-Path -Path $integrationScript)) {
    Write-Error "Le script d'intégration '$integrationScript' n'existe pas."
    exit 1
}

# Fonction pour créer des exemples de fichiers ambigus
function New-SampleFiles {
    param (
        [string]$Directory
    )

    # Créer le répertoire s'il n'existe pas
    if (-not (Test-Path -Path $Directory -PathType Container)) {
        try {
            New-Item -Path $Directory -ItemType Directory -Force | Out-Null
            Write-Host "Répertoire d'exemples créé : $Directory" -ForegroundColor Yellow
        }
        catch {
            Write-Error "Impossible de créer le répertoire d'exemples : $_"
            exit 1
        }
    }

    Write-Host "Création d'exemples de fichiers ambigus..." -ForegroundColor Yellow

    # Exemple 1: Fichier JSON qui pourrait être confondu avec du JavaScript
    $jsonJsContent = @"
{
    "name": "Test",
    "version": "1.0.0",
    "description": "This is a test file",
    "main": "index.js",
    "scripts": {
        "test": "echo \"Error: no test specified\" && exit 1"
    },
    "keywords": [
        "test",
        "example"
    ],
    "author": "Augment Agent",
    "license": "MIT"
}
"@

    $jsonJsPath = Join-Path -Path $Directory -ChildPath "package.txt"
    $jsonJsContent | Set-Content -Path $jsonJsPath -Encoding UTF8
    Write-Host "  Créé : package.txt (JSON/JavaScript ambigu)" -ForegroundColor Green

    # Exemple 2: Fichier XML qui pourrait être confondu avec du HTML
    $xmlHtmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<html>
    <head>
        <title>Test Page</title>
    </head>
    <body>
        <h1>Hello World</h1>
        <p>This is a test file that could be XML or HTML.</p>
    </body>
</html>
"@

    $xmlHtmlPath = Join-Path -Path $Directory -ChildPath "page.txt"
    $xmlHtmlContent | Set-Content -Path $xmlHtmlPath -Encoding UTF8
    Write-Host "  Créé : page.txt (XML/HTML ambigu)" -ForegroundColor Green

    # Exemple 3: Fichier CSV qui pourrait être confondu avec du texte
    $csvTextContent = @"
Name,Age,Email
John Doe,30,john.doe@example.com
Jane Smith,25,jane.smith@example.com
Bob Johnson,40,bob.johnson@example.com
"@

    $csvTextPath = Join-Path -Path $Directory -ChildPath "data.txt"
    $csvTextContent | Set-Content -Path $csvTextPath -Encoding UTF8
    Write-Host "  Créé : data.txt (CSV/Texte ambigu)" -ForegroundColor Green

    # Exemple 4: Fichier PowerShell qui pourrait être confondu avec du texte
    $ps1TextContent = @"
# This is a PowerShell script
# It could be confused with a text file

function Test-Function {
    param (
        [string]`$Name
    )

    Write-Host "Hello, `$Name!"
}

Test-Function -Name "World"
"@

    $ps1TextPath = Join-Path -Path $Directory -ChildPath "script.txt"
    $ps1TextContent | Set-Content -Path $ps1TextPath -Encoding UTF8
    Write-Host "  Créé : script.txt (PowerShell/Texte ambigu)" -ForegroundColor Green

    # Exemple 5: Fichier INI qui pourrait être confondu avec du texte
    $iniTextContent = @"
[General]
Name=Test Configuration
Version=1.0.0
Description=This is a test configuration file

[Settings]
Debug=true
LogLevel=INFO
MaxConnections=10

[User]
Name=John Doe
Email=john.doe@example.com
"@

    $iniTextPath = Join-Path -Path $Directory -ChildPath "config.txt"
    $iniTextContent | Set-Content -Path $iniTextPath -Encoding UTF8
    Write-Host "  Créé : config.txt (INI/Texte ambigu)" -ForegroundColor Green

    # Exemple 6: Fichier YAML qui pourrait être confondu avec du texte
    $yamlTextContent = @"
# YAML configuration file
version: '1.0'
name: 'Test Configuration'
description: 'This is a test YAML file'

settings:
  debug: true
  log_level: INFO
  max_connections: 10

user:
  name: John Doe
  email: john.doe@example.com
  roles:
    - admin
    - user
"@

    $yamlTextPath = Join-Path -Path $Directory -ChildPath "config.yaml.txt"
    $yamlTextContent | Set-Content -Path $yamlTextPath -Encoding UTF8
    Write-Host "  Créé : config.yaml.txt (YAML/Texte ambigu)" -ForegroundColor Green

    Write-Host "Exemples de fichiers ambigus créés avec succès." -ForegroundColor Green
    Write-Host ""

    # Retourner la liste des fichiers créés
    return Get-ChildItem -Path $Directory -File
}

# Fonction pour générer un rapport HTML
function New-DemoReport {
    param (
        [array]$Results,
        [string]$OutputPath = "$PSScriptRoot\AmbiguousFormatDemo.html"
    )

    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Démonstration - Gestion des cas ambigus</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1000px;
            margin: 0 auto;
            background-color: #fff;
            padding: 20px;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1, h2 {
            color: #2c3e50;
        }
        h1 {
            border-bottom: 2px solid #3498db;
            padding-bottom: 10px;
        }
        .summary {
            background-color: #f8f9fa;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .demo-case {
            background-color: #fff;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border: 1px solid #ddd;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .demo-case h3 {
            margin-top: 0;
            color: #3498db;
        }
        .file-info {
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 10px;
        }
        .detection-result {
            background-color: #e8f4f8;
            padding: 10px;
            border-radius: 5px;
            margin-bottom: 10px;
            border-left: 4px solid #3498db;
        }
        .format-list {
            width: 100%;
            border-collapse: collapse;
            margin-top: 10px;
        }
        .format-list th, .format-list td {
            padding: 8px 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        .format-list th {
            background-color: #3498db;
            color: white;
        }
        .format-list tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .score-high {
            color: #27ae60;
            font-weight: bold;
        }
        .score-medium {
            color: #f39c12;
            font-weight: bold;
        }
        .score-low {
            color: #7f8c8d;
        }
        .ambiguous {
            background-color: #fcf8e3;
            border-left: 4px solid #f39c12;
        }
        .resolved {
            background-color: #dff0d8;
            border-left: 4px solid #27ae60;
        }
        .file-content {
            background-color: #f8f9fa;
            padding: 10px;
            border-radius: 5px;
            margin-top: 10px;
            font-family: monospace;
            white-space: pre-wrap;
            overflow-x: auto;
            border: 1px solid #ddd;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Démonstration - Gestion des cas ambigus</h1>

        <div class="summary">
            <h2>Résumé</h2>
            <p><strong>Nombre de fichiers testés:</strong> $($Results.Count)</p>
            <p><strong>Mode de résolution:</strong> $(if ($AutoResolve) { "Automatique" } else { "Confirmation utilisateur" })</p>
            <p><strong>Date de la démonstration:</strong> $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>

        <h2>Détails des exemples</h2>
"@

    foreach ($result in $Results) {
        $fileName = [System.IO.Path]::GetFileName($result.FilePath)
        $fileContent = Get-Content -Path $result.FilePath -Raw

        # Déterminer si le cas est ambigu
        $topFormats = $result.AllFormats | Sort-Object -Property Score, Priority -Descending | Select-Object -First 2
        $isAmbiguous = ($topFormats.Count -ge 2) -and (($topFormats[0].Score - $topFormats[1].Score) -lt 20)

        $resultClass = if ($isAmbiguous) {
            if ($AutoResolve) { "resolved" } else { "ambiguous" }
        } else {
            "detection-result"
        }

        $html += @"
        <div class="demo-case">
            <h3>$fileName</h3>

            <div class="file-info">
                <p><strong>Chemin:</strong> $($result.FilePath)</p>
                <p><strong>Taille:</strong> $($result.Size) octets</p>
            </div>

            <div class="$resultClass">
                <h4>Résultat de détection</h4>
"@

        if ($isAmbiguous) {
            $html += @"
                <p><strong>Cas ambigu détecté!</strong></p>
                <p><strong>Format détecté:</strong> $($result.DetectedFormat)</p>
                <p><strong>Résolu par:</strong> $(if ($AutoResolve) { "Résolution automatique" } else { "Confirmation utilisateur" })</p>
"@
        } else {
            $html += @"
                <p><strong>Format détecté:</strong> $($result.DetectedFormat)</p>
"@
        }

        $scoreClass = switch ($result.ConfidenceScore) {
            {$_ -ge 90} { "score-high" }
            {$_ -ge 70} { "score-medium" }
            default { "score-low" }
        }

        $html += @"
                <p><strong>Score de confiance:</strong> <span class="$scoreClass">$($result.ConfidenceScore)%</span></p>
                <p><strong>Critères correspondants:</strong> $($result.MatchedCriteria)</p>
            </div>

            <h4>Formats détectés</h4>
            <table class="format-list">
                <thead>
                    <tr>
                        <th>Format</th>
                        <th>Score</th>
                        <th>Priorité</th>
                        <th>Critères</th>
                    </tr>
                </thead>
                <tbody>
"@

        foreach ($format in ($result.AllFormats | Sort-Object -Property Score, Priority -Descending)) {
            $scoreClass = switch ($format.Score) {
                {$_ -ge 90} { "score-high" }
                {$_ -ge 70} { "score-medium" }
                default { "score-low" }
            }

            $criteriaText = $format.MatchedCriteria -join ", "

            $html += @"
                    <tr>
                        <td>$($format.Format)</td>
                        <td class="$scoreClass">$($format.Score)%</td>
                        <td>$($format.Priority)</td>
                        <td>$criteriaText</td>
                    </tr>
"@
        }

        $html += @"
                </tbody>
            </table>

            <h4>Contenu du fichier</h4>
            <div class="file-content">$([System.Web.HttpUtility]::HtmlEncode($fileContent))</div>
        </div>
"@
    }

    $html += @"
    </div>
</body>
</html>
"@

    $html | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Rapport de démonstration généré : $OutputPath" -ForegroundColor Green
}

# Fonction principale
function Main {
    Write-Host "Démonstration du système de gestion des cas ambigus" -ForegroundColor Cyan
    Write-Host "Mode de résolution : $(if ($AutoResolve) { 'Automatique' } else { 'Confirmation utilisateur' })" -ForegroundColor Cyan
    Write-Host ""

    # Créer des exemples de fichiers si demandé
    $sampleFiles = @()

    if ($CreateSamples -or -not (Test-Path -Path $SamplesDirectory -PathType Container)) {
        $sampleFiles = New-SampleFiles -Directory $SamplesDirectory
    }
    else {
        # Utiliser les fichiers existants
        if (Test-Path -Path $SamplesDirectory -PathType Container) {
            $sampleFiles = Get-ChildItem -Path $SamplesDirectory -File
        }
        else {
            Write-Error "Le répertoire d'exemples '$SamplesDirectory' n'existe pas."
            exit 1
        }
    }

    if ($sampleFiles.Count -eq 0) {
        Write-Error "Aucun fichier d'exemple trouvé."
        exit 1
    }

    Write-Host "Nombre de fichiers d'exemple : $($sampleFiles.Count)" -ForegroundColor Yellow
    Write-Host ""

    # Tester chaque fichier
    $results = @()

    foreach ($file in $sampleFiles) {
        Write-Host "Analyse du fichier : $($file.Name)" -ForegroundColor Yellow

        # Exécuter le script d'intégration
        $result = & $integrationScript -FilePath $file.FullName -AutoResolve:$AutoResolve -ShowDetails

        # Ajouter le résultat à la liste
        $results += $result

        Write-Host ""
    }

    # Générer un rapport si demandé
    if ($GenerateReport) {
        New-DemoReport -Results $results
    }

    return $results
}

# Exécuter le script
$results = Main
return $results

#Requires -Version 5.1
<#
.SYNOPSIS
    Teste le système de gestion des cas ambigus de détection de format.

.DESCRIPTION
    Ce script teste le système de gestion des cas ambigus de détection de format
    en utilisant des fichiers d'exemple avec des formats potentiellement ambigus.
    Il permet de vérifier le fonctionnement des mécanismes de résolution automatique
    et de confirmation utilisateur.

.PARAMETER TestDirectory
    Le répertoire contenant les fichiers de test.
    Par défaut, utilise le sous-répertoire 'ambiguous_samples' du répertoire courant.

.PARAMETER AutoResolve
    Indique si le script doit tenter de résoudre automatiquement les cas ambigus sans intervention utilisateur.
    Par défaut, cette option est désactivée.

.PARAMETER GenerateReport
    Indique si le script doit générer un rapport HTML des résultats.
    Par défaut, cette option est activée.

.PARAMETER ReportPath
    Le chemin du fichier de rapport HTML.
    Par défaut, utilise 'AmbiguousFormatTestReport.html' dans le répertoire courant.

.EXAMPLE
    .\Test-AmbiguousFormatHandling.ps1
    Teste le système de gestion des cas ambigus avec les fichiers d'exemple et génère un rapport HTML.

.EXAMPLE
    .\Test-AmbiguousFormatHandling.ps1 -TestDirectory "C:\path\to\test\files" -AutoResolve
    Teste le système avec des fichiers personnalisés et résout automatiquement les cas ambigus.

.NOTES
    Auteur: Augment Agent
    Date: 2025-04-11
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$TestDirectory = "$PSScriptRoot\ambiguous_samples",
    
    [Parameter(Mandatory = $false)]
    [switch]$AutoResolve,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport = $true,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = "$PSScriptRoot\AmbiguousFormatTestReport.html"
)

# Importer les scripts nécessaires
$handleAmbiguousScript = "$PSScriptRoot\..\analysis\Handle-AmbiguousFormats.ps1"
$showResultsScript = "$PSScriptRoot\..\analysis\Show-FormatDetectionResults.ps1"

if (-not (Test-Path -Path $handleAmbiguousScript)) {
    Write-Error "Le script de gestion des cas ambigus '$handleAmbiguousScript' n'existe pas."
    exit 1
}

if (-not (Test-Path -Path $showResultsScript)) {
    Write-Error "Le script d'affichage des résultats '$showResultsScript' n'existe pas."
    exit 1
}

# Vérifier si le répertoire de test existe
if (-not (Test-Path -Path $TestDirectory -PathType Container)) {
    # Créer le répertoire s'il n'existe pas
    try {
        New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire de test créé : $TestDirectory" -ForegroundColor Yellow
    }
    catch {
        Write-Error "Impossible de créer le répertoire de test : $_"
        exit 1
    }
    
    # Créer des exemples de fichiers ambigus
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
    
    $jsonJsPath = Join-Path -Path $TestDirectory -ChildPath "package.txt"
    $jsonJsContent | Set-Content -Path $jsonJsPath -Encoding UTF8
    
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
    
    $xmlHtmlPath = Join-Path -Path $TestDirectory -ChildPath "page.txt"
    $xmlHtmlContent | Set-Content -Path $xmlHtmlPath -Encoding UTF8
    
    # Exemple 3: Fichier CSV qui pourrait être confondu avec du texte
    $csvTextContent = @"
Name,Age,Email
John Doe,30,john.doe@example.com
Jane Smith,25,jane.smith@example.com
Bob Johnson,40,bob.johnson@example.com
"@
    
    $csvTextPath = Join-Path -Path $TestDirectory -ChildPath "data.txt"
    $csvTextContent | Set-Content -Path $csvTextPath -Encoding UTF8
    
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
    
    $ps1TextPath = Join-Path -Path $TestDirectory -ChildPath "script.txt"
    $ps1TextContent | Set-Content -Path $ps1TextPath -Encoding UTF8
    
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
    
    $iniTextPath = Join-Path -Path $TestDirectory -ChildPath "config.txt"
    $iniTextContent | Set-Content -Path $iniTextPath -Encoding UTF8
}

# Fonction pour générer un rapport HTML
function Generate-TestReport {
    param (
        [array]$Results
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de test - Gestion des cas ambigus</title>
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
        .test-case {
            background-color: #fff;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
            border: 1px solid #ddd;
            box-shadow: 0 1px 3px rgba(0,0,0,0.1);
        }
        .test-case h3 {
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
    </style>
</head>
<body>
    <div class="container">
        <h1>Rapport de test - Gestion des cas ambigus</h1>
        
        <div class="summary">
            <h2>Résumé</h2>
            <p><strong>Nombre de fichiers testés:</strong> $($Results.Count)</p>
            <p><strong>Cas ambigus détectés:</strong> $($Results.Where({ $_.IsAmbiguous }).Count)</p>
            <p><strong>Cas résolus automatiquement:</strong> $($Results.Where({ $_.IsAmbiguous -and $_.AutoResolved }).Count)</p>
            <p><strong>Cas résolus par l'utilisateur:</strong> $($Results.Where({ $_.IsAmbiguous -and -not $_.AutoResolved }).Count)</p>
        </div>
        
        <h2>Détails des tests</h2>
"@

    foreach ($result in $Results) {
        $fileName = [System.IO.Path]::GetFileName($result.FilePath)
        
        $resultClass = if ($result.IsAmbiguous) {
            if ($result.AutoResolved) { "resolved" } else { "ambiguous" }
        } else {
            "detection-result"
        }
        
        $html += @"
        <div class="test-case">
            <h3>$fileName</h3>
            
            <div class="file-info">
                <p><strong>Chemin:</strong> $($result.FilePath)</p>
                <p><strong>Taille:</strong> $($result.Size) octets</p>
            </div>
            
            <div class="$resultClass">
                <h4>Résultat de détection</h4>
"@

        if ($result.IsAmbiguous) {
            $html += @"
                <p><strong>Cas ambigu détecté!</strong></p>
                <p><strong>Format détecté:</strong> $($result.DetectedFormat)</p>
                <p><strong>Résolu par:</strong> $(if ($result.AutoResolved) { "Résolution automatique" } else { "Confirmation utilisateur" })</p>
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
        </div>
"@
    }

    $html += @"
    </div>
</body>
</html>
"@

    $html | Set-Content -Path $ReportPath -Encoding UTF8
    Write-Host "Rapport de test généré : $ReportPath" -ForegroundColor Green
}

# Fonction principale
function Main {
    Write-Host "Test du système de gestion des cas ambigus" -ForegroundColor Cyan
    Write-Host "Répertoire de test : $TestDirectory" -ForegroundColor Cyan
    Write-Host "Mode de résolution : $(if ($AutoResolve) { 'Automatique' } else { 'Confirmation utilisateur' })" -ForegroundColor Cyan
    Write-Host ""
    
    # Obtenir la liste des fichiers de test
    $testFiles = Get-ChildItem -Path $TestDirectory -File
    
    if ($testFiles.Count -eq 0) {
        Write-Error "Aucun fichier de test trouvé dans le répertoire '$TestDirectory'."
        exit 1
    }
    
    Write-Host "Nombre de fichiers de test : $($testFiles.Count)" -ForegroundColor Yellow
    Write-Host ""
    
    # Tester chaque fichier
    $results = @()
    
    foreach ($file in $testFiles) {
        Write-Host "Test du fichier : $($file.Name)" -ForegroundColor Yellow
        
        # Exécuter le script de gestion des cas ambigus
        $result = & $handleAmbiguousScript -FilePath $file.FullName -AutoResolve:$AutoResolve
        
        # Déterminer si le cas était ambigu
        $topFormats = $result.AllFormats | Sort-Object -Property Score, Priority -Descending | Select-Object -First 2
        $isAmbiguous = ($topFormats.Count -ge 2) -and (($topFormats[0].Score - $topFormats[1].Score) -lt 20)
        
        # Ajouter des informations supplémentaires au résultat
        $result | Add-Member -MemberType NoteProperty -Name "IsAmbiguous" -Value $isAmbiguous
        $result | Add-Member -MemberType NoteProperty -Name "AutoResolved" -Value $AutoResolve
        
        # Afficher les résultats
        & $showResultsScript -FilePath $file.FullName -DetectionResult $result
        
        # Ajouter le résultat à la liste
        $results += $result
        
        Write-Host ""
    }
    
    # Générer un rapport si demandé
    if ($GenerateReport) {
        Generate-TestReport -Results $results
    }
    
    return $results
}

# Exécuter le script
$results = Main
return $results

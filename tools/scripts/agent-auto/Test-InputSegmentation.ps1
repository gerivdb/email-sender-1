#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le système de segmentation d'entrée.
.DESCRIPTION
    Ce script exécute une série de tests pour valider le fonctionnement
    du système de segmentation d'entrée pour Agent Auto.
.PARAMETER TestsPath
    Chemin du dossier contenant les tests.
.PARAMETER GenerateReport
    Génère un rapport détaillé des tests.
.PARAMETER ReportPath
    Chemin du fichier de rapport.
.EXAMPLE
    .\Test-InputSegmentation.ps1 -GenerateReport -ReportPath ".\reports\segmentation_tests.html"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$TestsPath = ".\tests\segmentation",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = ".\reports\segmentation_tests.html"
)

# Importer le module de segmentation
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\InputSegmentation.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module de segmentation introuvable: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "TITLE" { "Cyan" }
    }
    
    Write-Host "[$timestamp] " -NoNewline
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

# Fonction pour créer des fichiers de test
function New-TestFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestsPath
    )
    
    # Créer le dossier de tests s'il n'existe pas
    if (-not (Test-Path -Path $TestsPath)) {
        New-Item -Path $TestsPath -ItemType Directory -Force | Out-Null
    }
    
    # Créer un fichier texte volumineux
    $largeTextPath = Join-Path -Path $TestsPath -ChildPath "large_text.txt"
    $largeText = ""
    
    for ($i = 0; $i -lt 1000; $i++) {
        $largeText += "Ligne $i : Ceci est une ligne de test pour la segmentation d'entrée. " * 5
        $largeText += "`n"
    }
    
    $largeText | Out-File -FilePath $largeTextPath -Encoding utf8
    
    # Créer un fichier JSON volumineux
    $largeJsonPath = Join-Path -Path $TestsPath -ChildPath "large_json.json"
    $largeJson = @{
        items = @()
    }
    
    for ($i = 0; $i -lt 500; $i++) {
        $largeJson.items += @{
            id = $i
            name = "Item $i"
            description = "Description de l'item $i. " * 10
            properties = @{
                prop1 = "Valeur 1"
                prop2 = "Valeur 2"
                prop3 = "Valeur 3"
                prop4 = "Valeur 4"
                prop5 = "Valeur 5"
            }
        }
    }
    
    $largeJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $largeJsonPath -Encoding utf8
    
    # Créer un petit fichier texte
    $smallTextPath = Join-Path -Path $TestsPath -ChildPath "small_text.txt"
    $smallText = "Ceci est un petit fichier texte pour tester la segmentation d'entrée."
    $smallText | Out-File -FilePath $smallTextPath -Encoding utf8
    
    # Créer un petit fichier JSON
    $smallJsonPath = Join-Path -Path $TestsPath -ChildPath "small_json.json"
    $smallJson = @{
        name = "Test"
        description = "Petit fichier JSON pour tester la segmentation d'entrée"
        properties = @{
            prop1 = "Valeur 1"
            prop2 = "Valeur 2"
        }
    }
    
    $smallJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $smallJsonPath -Encoding utf8
    
    Write-Log "Fichiers de test créés dans $TestsPath" -Level "SUCCESS"
    
    return @{
        LargeTextPath = $largeTextPath
        LargeJsonPath = $largeJsonPath
        SmallTextPath = $smallTextPath
        SmallJsonPath = $smallJsonPath
    }
}

# Fonction pour exécuter les tests
function Start-SegmentationTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestsPath
    )
    
    Write-Log "Démarrage des tests de segmentation d'entrée..." -Level "TITLE"
    
    # Créer les fichiers de test
    $testFiles = New-TestFiles -TestsPath $TestsPath
    
    # Initialiser le module de segmentation
    Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5
    
    # Tableau pour stocker les résultats des tests
    $testResults = @()
    
    # Test 1: Mesurer la taille d'une petite chaîne
    $smallText = "Ceci est un petit texte de test."
    $smallTextSize = Measure-InputSize -Input $smallText
    
    $test1 = [PSCustomObject]@{
        Name = "Test 1: Mesure de la taille d'une petite chaîne"
        Success = ($smallTextSize -lt 1)
        Details = "Taille mesurée: $smallTextSize KB"
    }
    
    $testResults += $test1
    
    # Test 2: Mesurer la taille d'un petit objet JSON
    $smallJson = @{
        name = "Test"
        description = "Petit objet JSON pour tester la segmentation d'entrée"
    }
    
    $smallJsonSize = Measure-InputSize -Input $smallJson
    
    $test2 = [PSCustomObject]@{
        Name = "Test 2: Mesure de la taille d'un petit objet JSON"
        Success = ($smallJsonSize -lt 1)
        Details = "Taille mesurée: $smallJsonSize KB"
    }
    
    $testResults += $test2
    
    # Test 3: Mesurer la taille d'un fichier texte volumineux
    $largeTextSize = Measure-InputSize -Input (Get-Content -Path $testFiles.LargeTextPath -Raw)
    
    $test3 = [PSCustomObject]@{
        Name = "Test 3: Mesure de la taille d'un fichier texte volumineux"
        Success = ($largeTextSize -gt 10)
        Details = "Taille mesurée: $largeTextSize KB"
    }
    
    $testResults += $test3
    
    # Test 4: Segmenter une chaîne de texte volumineuse
    $largeText = Get-Content -Path $testFiles.LargeTextPath -Raw
    $textSegments = Split-TextInput -Text $largeText -ChunkSizeKB 5
    
    $test4 = [PSCustomObject]@{
        Name = "Test 4: Segmentation d'une chaîne de texte volumineuse"
        Success = ($textSegments.Count -gt 1)
        Details = "Nombre de segments: $($textSegments.Count)"
    }
    
    $testResults += $test4
    
    # Test 5: Segmenter un objet JSON volumineux
    $largeJson = Get-Content -Path $testFiles.LargeJsonPath -Raw | ConvertFrom-Json
    $jsonSegments = Split-JsonInput -JsonObject $largeJson -ChunkSizeKB 5
    
    $test5 = [PSCustomObject]@{
        Name = "Test 5: Segmentation d'un objet JSON volumineux"
        Success = ($jsonSegments.Count -gt 1)
        Details = "Nombre de segments: $($jsonSegments.Count)"
    }
    
    $testResults += $test5
    
    # Test 6: Segmenter un fichier
    $fileSegments = Split-FileInput -FilePath $testFiles.LargeTextPath -ChunkSizeKB 5 -PreserveLines
    
    $test6 = [PSCustomObject]@{
        Name = "Test 6: Segmentation d'un fichier"
        Success = ($fileSegments.Count -gt 1)
        Details = "Nombre de segments: $($fileSegments.Count)"
    }
    
    $testResults += $test6
    
    # Test 7: Segmenter un petit fichier (ne devrait pas être segmenté)
    $smallFileSegments = Split-FileInput -FilePath $testFiles.SmallTextPath -ChunkSizeKB 5
    
    $test7 = [PSCustomObject]@{
        Name = "Test 7: Segmentation d'un petit fichier"
        Success = ($smallFileSegments.Count -eq 1)
        Details = "Nombre de segments: $($smallFileSegments.Count)"
    }
    
    $testResults += $test7
    
    # Test 8: Utiliser Invoke-WithSegmentation pour traiter une entrée volumineuse
    $outputPath = Join-Path -Path $TestsPath -ChildPath "output"
    
    if (-not (Test-Path -Path $outputPath)) {
        New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
    }
    
    $scriptBlock = {
        param($input)
        # Simuler un traitement
        Start-Sleep -Milliseconds 100
        return "Traité: $($input.Length) caractères"
    }
    
    $largeText = Get-Content -Path $testFiles.LargeTextPath -Raw
    $segmentationResults = Invoke-WithSegmentation -Input $largeText -ScriptBlock $scriptBlock -Id "test" -ChunkSizeKB 5
    
    $test8 = [PSCustomObject]@{
        Name = "Test 8: Invoke-WithSegmentation pour une entrée volumineuse"
        Success = ($segmentationResults.Count -gt 1)
        Details = "Nombre de résultats: $($segmentationResults.Count)"
    }
    
    $testResults += $test8
    
    # Test 9: Sauvegarder et charger l'état de segmentation
    $testId = "test_state"
    $testSegments = @("Segment 1", "Segment 2", "Segment 3")
    
    Save-SegmentationState -Id $testId -Segments $testSegments -CurrentIndex 1
    $loadedState = Get-SegmentationState -Id $testId
    
    $test9 = [PSCustomObject]@{
        Name = "Test 9: Sauvegarder et charger l'état de segmentation"
        Success = ($loadedState -and $loadedState.Id -eq $testId -and $loadedState.CurrentIndex -eq 1)
        Details = "État chargé: $($loadedState -ne $null), ID: $($loadedState.Id), Index: $($loadedState.CurrentIndex)"
    }
    
    $testResults += $test9
    
    # Test 10: Segmenter une entrée générique
    $genericInput = @{
        text = $largeText
        metadata = @{
            source = "Test"
            timestamp = Get-Date
        }
    }
    
    $genericSegments = Split-Input -Input $genericInput -ChunkSizeKB 5
    
    $test10 = [PSCustomObject]@{
        Name = "Test 10: Segmentation d'une entrée générique"
        Success = ($genericSegments.Count -gt 1)
        Details = "Nombre de segments: $($genericSegments.Count)"
    }
    
    $testResults += $test10
    
    # Afficher les résultats
    $successCount = ($testResults | Where-Object { $_.Success }).Count
    $totalCount = $testResults.Count
    
    Write-Log "Résultats des tests: $successCount / $totalCount tests réussis" -Level $(if ($successCount -eq $totalCount) { "SUCCESS" } else { "WARNING" })
    
    foreach ($result in $testResults) {
        $status = if ($result.Success) { "RÉUSSI" } else { "ÉCHOUÉ" }
        $color = if ($result.Success) { "Green" } else { "Red" }
        
        Write-Host "[$status] " -NoNewline -ForegroundColor $color
        Write-Host "$($result.Name): $($result.Details)"
    }
    
    return $testResults
}

# Fonction pour générer un rapport HTML
function New-TestReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$TestResults,
        
        [Parameter(Mandatory = $true)]
        [string]$ReportPath
    )
    
    $successCount = ($TestResults | Where-Object { $_.Success }).Count
    $totalCount = $TestResults.Count
    $successRate = [math]::Round(($successCount / $totalCount) * 100, 2)
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport des tests de segmentation d'entrée</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2 {
            color: #0066cc;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .success-rate {
            font-size: 24px;
            font-weight: bold;
            color: $(if ($successRate -eq 100) { "#2ecc71" } else { "#e74c3c" });
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #0066cc;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .success {
            color: #2ecc71;
            font-weight: bold;
        }
        .failure {
            color: #e74c3c;
            font-weight: bold;
        }
        .timestamp {
            color: #666;
            font-style: italic;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>Rapport des tests de segmentation d'entrée</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Tests réussis: <span class="success-rate">$successCount / $totalCount ($successRate%)</span></p>
    </div>
    
    <h2>Détails des tests</h2>
    <table>
        <tr>
            <th>Test</th>
            <th>Résultat</th>
            <th>Détails</th>
        </tr>
"@
    
    foreach ($result in $TestResults) {
        $status = if ($result.Success) { "RÉUSSI" } else { "ÉCHOUÉ" }
        $statusClass = if ($result.Success) { "success" } else { "failure" }
        
        $html += @"
        <tr>
            <td>$($result.Name)</td>
            <td class="$statusClass">$status</td>
            <td>$($result.Details)</td>
        </tr>
"@
    }
    
    $html += @"
    </table>
    
    <p class="timestamp">Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
</body>
</html>
"@
    
    # Créer le dossier de sortie s'il n'existe pas
    $outputDir = [System.IO.Path]::GetDirectoryName($ReportPath)
    
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le rapport
    $html | Out-File -FilePath $ReportPath -Encoding utf8
    
    Write-Log "Rapport généré: $ReportPath" -Level "SUCCESS"
}

# Exécuter les tests
$testResults = Start-SegmentationTests -TestsPath $TestsPath

# Générer le rapport si demandé
if ($GenerateReport) {
    New-TestReport -TestResults $testResults -ReportPath $ReportPath
}

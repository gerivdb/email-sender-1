#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le systÃ¨me de segmentation d'entrÃ©e.
.DESCRIPTION
    Ce script exÃ©cute une sÃ©rie de tests pour valider le fonctionnement
    du systÃ¨me de segmentation d'entrÃ©e pour Agent Auto.
.PARAMETER TestsPath
    Chemin du dossier contenant les tests.
.PARAMETER GenerateReport
    GÃ©nÃ¨re un rapport dÃ©taillÃ© des tests.
.PARAMETER ReportPath
    Chemin du fichier de rapport.
.EXAMPLE
    .\Test-InputSegmentation.ps1 -GenerateReport -ReportPath ".\reports\segmentation_tests.html"
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-17
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

# Fonction pour Ã©crire dans le journal
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

# Fonction pour crÃ©er des fichiers de test
function New-TestFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestsPath
    )
    
    # CrÃ©er le dossier de tests s'il n'existe pas
    if (-not (Test-Path -Path $TestsPath)) {
        New-Item -Path $TestsPath -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er un fichier texte volumineux
    $largeTextPath = Join-Path -Path $TestsPath -ChildPath "large_text.txt"
    $largeText = ""
    
    for ($i = 0; $i -lt 1000; $i++) {
        $largeText += "Ligne $i : Ceci est une ligne de test pour la segmentation d'entrÃ©e. " * 5
        $largeText += "`n"
    }
    
    $largeText | Out-File -FilePath $largeTextPath -Encoding utf8
    
    # CrÃ©er un fichier JSON volumineux
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
    
    # CrÃ©er un petit fichier texte
    $smallTextPath = Join-Path -Path $TestsPath -ChildPath "small_text.txt"
    $smallText = "Ceci est un petit fichier texte pour tester la segmentation d'entrÃ©e."
    $smallText | Out-File -FilePath $smallTextPath -Encoding utf8
    
    # CrÃ©er un petit fichier JSON
    $smallJsonPath = Join-Path -Path $TestsPath -ChildPath "small_json.json"
    $smallJson = @{
        name = "Test"
        description = "Petit fichier JSON pour tester la segmentation d'entrÃ©e"
        properties = @{
            prop1 = "Valeur 1"
            prop2 = "Valeur 2"
        }
    }
    
    $smallJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $smallJsonPath -Encoding utf8
    
    Write-Log "Fichiers de test crÃ©Ã©s dans $TestsPath" -Level "SUCCESS"
    
    return @{
        LargeTextPath = $largeTextPath
        LargeJsonPath = $largeJsonPath
        SmallTextPath = $smallTextPath
        SmallJsonPath = $smallJsonPath
    }
}

# Fonction pour exÃ©cuter les tests
function Start-SegmentationTests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestsPath
    )
    
    Write-Log "DÃ©marrage des tests de segmentation d'entrÃ©e..." -Level "TITLE"
    
    # CrÃ©er les fichiers de test
    $testFiles = New-TestFiles -TestsPath $TestsPath
    
    # Initialiser le module de segmentation
    Initialize-InputSegmentation -MaxInputSizeKB 10 -DefaultChunkSizeKB 5
    
    # Tableau pour stocker les rÃ©sultats des tests
    $testResults = @()
    
    # Test 1: Mesurer la taille d'une petite chaÃ®ne
    $smallText = "Ceci est un petit texte de test."
    $smallTextSize = Measure-InputSize -Input $smallText
    
    $test1 = [PSCustomObject]@{
        Name = "Test 1: Mesure de la taille d'une petite chaÃ®ne"
        Success = ($smallTextSize -lt 1)
        Details = "Taille mesurÃ©e: $smallTextSize KB"
    }
    
    $testResults += $test1
    
    # Test 2: Mesurer la taille d'un petit objet JSON
    $smallJson = @{
        name = "Test"
        description = "Petit objet JSON pour tester la segmentation d'entrÃ©e"
    }
    
    $smallJsonSize = Measure-InputSize -Input $smallJson
    
    $test2 = [PSCustomObject]@{
        Name = "Test 2: Mesure de la taille d'un petit objet JSON"
        Success = ($smallJsonSize -lt 1)
        Details = "Taille mesurÃ©e: $smallJsonSize KB"
    }
    
    $testResults += $test2
    
    # Test 3: Mesurer la taille d'un fichier texte volumineux
    $largeTextSize = Measure-InputSize -Input (Get-Content -Path $testFiles.LargeTextPath -Raw)
    
    $test3 = [PSCustomObject]@{
        Name = "Test 3: Mesure de la taille d'un fichier texte volumineux"
        Success = ($largeTextSize -gt 10)
        Details = "Taille mesurÃ©e: $largeTextSize KB"
    }
    
    $testResults += $test3
    
    # Test 4: Segmenter une chaÃ®ne de texte volumineuse
    $largeText = Get-Content -Path $testFiles.LargeTextPath -Raw
    $textSegments = Split-TextInput -Text $largeText -ChunkSizeKB 5
    
    $test4 = [PSCustomObject]@{
        Name = "Test 4: Segmentation d'une chaÃ®ne de texte volumineuse"
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
    
    # Test 7: Segmenter un petit fichier (ne devrait pas Ãªtre segmentÃ©)
    $smallFileSegments = Split-FileInput -FilePath $testFiles.SmallTextPath -ChunkSizeKB 5
    
    $test7 = [PSCustomObject]@{
        Name = "Test 7: Segmentation d'un petit fichier"
        Success = ($smallFileSegments.Count -eq 1)
        Details = "Nombre de segments: $($smallFileSegments.Count)"
    }
    
    $testResults += $test7
    
    # Test 8: Utiliser Invoke-WithSegmentation pour traiter une entrÃ©e volumineuse
    $outputPath = Join-Path -Path $TestsPath -ChildPath "output"
    
    if (-not (Test-Path -Path $outputPath)) {
        New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
    }
    
    $scriptBlock = {
        param($input)
        # Simuler un traitement
        Start-Sleep -Milliseconds 100
        return "TraitÃ©: $($input.Length) caractÃ¨res"
    }
    
    $largeText = Get-Content -Path $testFiles.LargeTextPath -Raw
    $segmentationResults = Invoke-WithSegmentation -Input $largeText -ScriptBlock $scriptBlock -Id "test" -ChunkSizeKB 5
    
    $test8 = [PSCustomObject]@{
        Name = "Test 8: Invoke-WithSegmentation pour une entrÃ©e volumineuse"
        Success = ($segmentationResults.Count -gt 1)
        Details = "Nombre de rÃ©sultats: $($segmentationResults.Count)"
    }
    
    $testResults += $test8
    
    # Test 9: Sauvegarder et charger l'Ã©tat de segmentation
    $testId = "test_state"
    $testSegments = @("Segment 1", "Segment 2", "Segment 3")
    
    Save-SegmentationState -Id $testId -Segments $testSegments -CurrentIndex 1
    $loadedState = Get-SegmentationState -Id $testId
    
    $test9 = [PSCustomObject]@{
        Name = "Test 9: Sauvegarder et charger l'Ã©tat de segmentation"
        Success = ($loadedState -and $loadedState.Id -eq $testId -and $loadedState.CurrentIndex -eq 1)
        Details = "Ã‰tat chargÃ©: $($loadedState -ne $null), ID: $($loadedState.Id), Index: $($loadedState.CurrentIndex)"
    }
    
    $testResults += $test9
    
    # Test 10: Segmenter une entrÃ©e gÃ©nÃ©rique
    $genericInput = @{
        text = $largeText
        metadata = @{
            source = "Test"
            timestamp = Get-Date
        }
    }
    
    $genericSegments = Split-Input -Input $genericInput -ChunkSizeKB 5
    
    $test10 = [PSCustomObject]@{
        Name = "Test 10: Segmentation d'une entrÃ©e gÃ©nÃ©rique"
        Success = ($genericSegments.Count -gt 1)
        Details = "Nombre de segments: $($genericSegments.Count)"
    }
    
    $testResults += $test10
    
    # Afficher les rÃ©sultats
    $successCount = ($testResults | Where-Object { $_.Success }).Count
    $totalCount = $testResults.Count
    
    Write-Log "RÃ©sultats des tests: $successCount / $totalCount tests rÃ©ussis" -Level $(if ($successCount -eq $totalCount) { "SUCCESS" } else { "WARNING" })
    
    foreach ($result in $testResults) {
        $status = if ($result.Success) { "RÃ‰USSI" } else { "Ã‰CHOUÃ‰" }
        $color = if ($result.Success) { "Green" } else { "Red" }
        
        Write-Host "[$status] " -NoNewline -ForegroundColor $color
        Write-Host "$($result.Name): $($result.Details)"
    }
    
    return $testResults
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
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
    <title>Rapport des tests de segmentation d'entrÃ©e</title>
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
    <h1>Rapport des tests de segmentation d'entrÃ©e</h1>
    
    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p>Tests rÃ©ussis: <span class="success-rate">$successCount / $totalCount ($successRate%)</span></p>
    </div>
    
    <h2>DÃ©tails des tests</h2>
    <table>
        <tr>
            <th>Test</th>
            <th>RÃ©sultat</th>
            <th>DÃ©tails</th>
        </tr>
"@
    
    foreach ($result in $TestResults) {
        $status = if ($result.Success) { "RÃ‰USSI" } else { "Ã‰CHOUÃ‰" }
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
    
    <p class="timestamp">Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
</body>
</html>
"@
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    $outputDir = [System.IO.Path]::GetDirectoryName($ReportPath)
    
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le rapport
    $html | Out-File -FilePath $ReportPath -Encoding utf8
    
    Write-Log "Rapport gÃ©nÃ©rÃ©: $ReportPath" -Level "SUCCESS"
}

# ExÃ©cuter les tests
$testResults = Start-SegmentationTests -TestsPath $TestsPath

# GÃ©nÃ©rer le rapport si demandÃ©
if ($GenerateReport) {
    New-TestReport -TestResults $testResults -ReportPath $ReportPath
}

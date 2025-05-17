#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute tous les tests du système de détection des modifications en temps réel.
.DESCRIPTION
    Ce script exécute tous les tests du système de détection des modifications
    en temps réel et génère un rapport de résultats.
.PARAMETER OutputPath
    Chemin où enregistrer le rapport de résultats. Si non spécifié,
    le rapport sera affiché dans la console.
.PARAMETER SkipTests
    Liste des tests à ignorer.
.EXAMPLE
    .\Run-AllTests.ps1 -OutputPath "rapport-tests.html"
    Exécute tous les tests et génère un rapport HTML.
.NOTES
    Nom: Run-AllTests.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [string[]]$SkipTests = @()
)

# Définir les tests à exécuter
$tests = @(
    @{
        Name = "Test-LoggingModule"
        Description = "Test du module de journalisation"
        Path = "Test-LoggingModule.ps1"
    },
    @{
        Name = "Test-MarkdownParserModule"
        Description = "Test du module d'analyse Markdown"
        Path = "Test-MarkdownParserModule.ps1"
    },
    @{
        Name = "Test-MarkdownChanges"
        Description = "Test de la détection des modifications dans les fichiers Markdown"
        Path = "Test-MarkdownChanges.ps1"
    },
    @{
        Name = "Test-SimpleWatcher"
        Description = "Test simple du système de surveillance des fichiers"
        Path = "Test-SimpleWatcher.ps1"
    },
    @{
        Name = "Test-GitHooks"
        Description = "Test de l'intégration avec Git hooks"
        Path = "Test-GitHooks.ps1"
    }
)

# Initialiser les résultats
$results = @()
$totalTests = 0
$passedTests = 0
$failedTests = 0
$skippedTests = 0

# Fonction pour exécuter un test
function Invoke-Test {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Test
    )
    
    $testName = $Test.Name
    $testDescription = $Test.Description
    $testPath = $Test.Path
    
    # Vérifier si le test doit être ignoré
    if ($SkipTests -contains $testName) {
        Write-Host "Test ignoré: $testName" -ForegroundColor Yellow
        
        return @{
            Name = $testName
            Description = $testDescription
            Result = "Skipped"
            Duration = 0
            Output = "Test ignoré"
        }
    }
    
    # Vérifier que le fichier de test existe
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $testFilePath = Join-Path -Path $scriptPath -ChildPath $testPath
    
    if (-not (Test-Path -Path $testFilePath)) {
        Write-Host "Erreur: Fichier de test non trouvé: $testFilePath" -ForegroundColor Red
        
        return @{
            Name = $testName
            Description = $testDescription
            Result = "Failed"
            Duration = 0
            Output = "Fichier de test non trouvé: $testFilePath"
        }
    }
    
    # Exécuter le test
    Write-Host "Exécution du test: $testName" -ForegroundColor Cyan
    Write-Host "Description: $testDescription" -ForegroundColor Cyan
    
    $startTime = Get-Date
    $output = $null
    $success = $false
    
    try {
        # Rediriger la sortie du test
        $tempFile = [System.IO.Path]::GetTempFileName()
        
        # Exécuter le test et capturer la sortie
        & $testFilePath *> $tempFile
        $success = $LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null
        
        # Lire la sortie du test
        $output = Get-Content -Path $tempFile -Raw
        
        # Supprimer le fichier temporaire
        Remove-Item -Path $tempFile -Force
    } catch {
        $output = $_.Exception.Message
        $success = $false
    }
    
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    # Afficher le résultat
    if ($success) {
        Write-Host "Test réussi: $testName" -ForegroundColor Green
    } else {
        Write-Host "Test échoué: $testName" -ForegroundColor Red
    }
    
    Write-Host "Durée: $duration secondes" -ForegroundColor Cyan
    
    return @{
        Name = $testName
        Description = $testDescription
        Result = if ($success) { "Passed" } else { "Failed" }
        Duration = $duration
        Output = $output
    }
}

# Exécuter tous les tests
Write-Host "Exécution de tous les tests..." -ForegroundColor Yellow
$startTimeAll = Get-Date

foreach ($test in $tests) {
    $totalTests++
    $result = Invoke-Test -Test $test
    $results += $result
    
    switch ($result.Result) {
        "Passed" { $passedTests++ }
        "Failed" { $failedTests++ }
        "Skipped" { $skippedTests++ }
    }
    
    Write-Host "-----------------------------------" -ForegroundColor Gray
}

$endTimeAll = Get-Date
$totalDuration = ($endTimeAll - $startTimeAll).TotalSeconds

# Afficher le résumé
Write-Host "Résumé des tests:" -ForegroundColor Yellow
Write-Host "  Tests exécutés: $totalTests" -ForegroundColor Cyan
Write-Host "  Tests réussis: $passedTests" -ForegroundColor Green
Write-Host "  Tests échoués: $failedTests" -ForegroundColor Red
Write-Host "  Tests ignorés: $skippedTests" -ForegroundColor Yellow
Write-Host "  Durée totale: $totalDuration secondes" -ForegroundColor Cyan

# Générer le rapport
if ($OutputPath) {
    # Créer le contenu HTML
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de tests - Système de détection des modifications en temps réel</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .summary { margin: 20px 0; padding: 10px; background-color: #f5f5f5; border-radius: 5px; }
        .test { margin: 10px 0; padding: 10px; border-radius: 5px; }
        .passed { background-color: #dff0d8; border: 1px solid #d6e9c6; }
        .failed { background-color: #f2dede; border: 1px solid #ebccd1; }
        .skipped { background-color: #fcf8e3; border: 1px solid #faebcc; }
        .output { margin-top: 10px; padding: 10px; background-color: #f9f9f9; border: 1px solid #ddd; border-radius: 3px; white-space: pre-wrap; }
    </style>
</head>
<body>
    <h1>Rapport de tests - Système de détection des modifications en temps réel</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Tests exécutés: $totalTests</p>
        <p>Tests réussis: $passedTests</p>
        <p>Tests échoués: $failedTests</p>
        <p>Tests ignorés: $skippedTests</p>
        <p>Durée totale: $totalDuration secondes</p>
    </div>
    
    <h2>Détails des tests</h2>
"@

    foreach ($result in $results) {
        $class = switch ($result.Result) {
            "Passed" { "passed" }
            "Failed" { "failed" }
            "Skipped" { "skipped" }
        }
        
        $htmlContent += @"
    <div class="test $class">
        <h3>$($result.Name)</h3>
        <p>Description: $($result.Description)</p>
        <p>Résultat: $($result.Result)</p>
        <p>Durée: $($result.Duration) secondes</p>
        <div class="output">$($result.Output)</div>
    </div>
"@
    }

    $htmlContent += @"
</body>
</html>
"@

    # Enregistrer le rapport
    $htmlContent | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Rapport enregistré dans: $OutputPath" -ForegroundColor Green
}

# Retourner le code de sortie
if ($failedTests -gt 0) {
    exit 1
} else {
    exit 0
}

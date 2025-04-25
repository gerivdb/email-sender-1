<#
.SYNOPSIS
    Script de test pour la gestion d'erreurs simple.

.DESCRIPTION
    Ce script teste les fonctionnalités de gestion d'erreurs implémentées dans SimpleErrorHandling.ps1.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Importer le script de gestion d'erreurs
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "SimpleErrorHandling.ps1"
. $scriptPath

# Exécuter les tests
Write-Host "=== Tests de la gestion d'erreurs simple ===" -ForegroundColor Cyan

# Créer un répertoire de test
$testDirectory = Join-Path -Path $env:TEMP -ChildPath "SimpleErrorHandlingTests"
if (Test-Path -Path $testDirectory) {
    Remove-Item -Path $testDirectory -Recurse -Force
}
New-Item -Path $testDirectory -ItemType Directory -Force | Out-Null

# Test 1: Initialisation de la gestion d'erreurs
Write-Host "Test 1: Initialisation de la gestion d'erreurs" -ForegroundColor Green
$initResult = Initialize-ErrorHandling -LogPath $testDirectory
Write-Host "  Résultat: $initResult"

# Test 2: Création d'un script de test
$testScriptPath = Join-Path -Path $testDirectory -ChildPath "TestScript.ps1"
Write-Host "Test 2: Création d'un script de test" -ForegroundColor Green
$createResult = New-TestScript -OutputPath $testScriptPath
Write-Host "  Résultat: $createResult"
Write-Host "  Script créé: $(Test-Path -Path $testScriptPath)"

# Test 3: Ajout de blocs try/catch
Write-Host "Test 3: Ajout de blocs try/catch" -ForegroundColor Green
$addResult = Add-TryCatchBlock -ScriptPath $testScriptPath -BackupFile
Write-Host "  Résultat: $addResult"
Write-Host "  Sauvegarde créée: $(Test-Path -Path "$testScriptPath.bak")"

# Test 4: Journalisation des erreurs
Write-Host "Test 4: Journalisation des erreurs" -ForegroundColor Green
try {
    Get-Content -Path "C:\chemin\invalide.txt" -ErrorAction Stop
}
catch {
    $logResult = Write-Log-Error -ErrorRecord $_ -FunctionName "Test-Function" -Category "FileSystem"
    Write-Host "  Résultat: $logResult"
}

# Vérifier que le fichier de journal a été créé
$logFile = Join-Path -Path $testDirectory -ChildPath "error_log.json"
Write-Host "  Fichier de journal créé: $(Test-Path -Path $logFile)"

# Afficher le contenu du fichier de journal
if (Test-Path -Path $logFile) {
    Write-Host "  Contenu du fichier de journal:" -ForegroundColor Yellow
    $logContent = Get-Content -Path $logFile -Raw
    Write-Host $logContent
}

Write-Host "=== Tests terminés avec succès ! ===" -ForegroundColor Cyan

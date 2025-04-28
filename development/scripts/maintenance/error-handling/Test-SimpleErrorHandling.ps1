<#
.SYNOPSIS
    Script de test pour la gestion d'erreurs simple.

.DESCRIPTION
    Ce script teste les fonctionnalitÃ©s de gestion d'erreurs implÃ©mentÃ©es dans SimpleErrorHandling.ps1.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# Importer le script de gestion d'erreurs
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "SimpleErrorHandling.ps1"
. $scriptPath

# ExÃ©cuter les tests
Write-Host "=== Tests de la gestion d'erreurs simple ===" -ForegroundColor Cyan

# CrÃ©er un rÃ©pertoire de test
$testDirectory = Join-Path -Path $env:TEMP -ChildPath "SimpleErrorHandlingTests"
if (Test-Path -Path $testDirectory) {
    Remove-Item -Path $testDirectory -Recurse -Force
}
New-Item -Path $testDirectory -ItemType Directory -Force | Out-Null

# Test 1: Initialisation de la gestion d'erreurs
Write-Host "Test 1: Initialisation de la gestion d'erreurs" -ForegroundColor Green
$initResult = Initialize-ErrorHandling -LogPath $testDirectory
Write-Host "  RÃ©sultat: $initResult"

# Test 2: CrÃ©ation d'un script de test
$testScriptPath = Join-Path -Path $testDirectory -ChildPath "TestScript.ps1"
Write-Host "Test 2: CrÃ©ation d'un script de test" -ForegroundColor Green
$createResult = New-TestScript -OutputPath $testScriptPath
Write-Host "  RÃ©sultat: $createResult"
Write-Host "  Script crÃ©Ã©: $(Test-Path -Path $testScriptPath)"

# Test 3: Ajout de blocs try/catch
Write-Host "Test 3: Ajout de blocs try/catch" -ForegroundColor Green
$addResult = Add-TryCatchBlock -ScriptPath $testScriptPath -BackupFile
Write-Host "  RÃ©sultat: $addResult"
Write-Host "  Sauvegarde crÃ©Ã©e: $(Test-Path -Path "$testScriptPath.bak")"

# Test 4: Journalisation des erreurs
Write-Host "Test 4: Journalisation des erreurs" -ForegroundColor Green
try {
    Get-Content -Path "C:\chemin\invalide.txt" -ErrorAction Stop
}
catch {
    $logResult = Write-Log-Error -ErrorRecord $_ -FunctionName "Test-Function" -Category "FileSystem"
    Write-Host "  RÃ©sultat: $logResult"
}

# VÃ©rifier que le fichier de journal a Ã©tÃ© crÃ©Ã©
$logFile = Join-Path -Path $testDirectory -ChildPath "error_log.json"
Write-Host "  Fichier de journal crÃ©Ã©: $(Test-Path -Path $logFile)"

# Afficher le contenu du fichier de journal
if (Test-Path -Path $logFile) {
    Write-Host "  Contenu du fichier de journal:" -ForegroundColor Yellow
    $logContent = Get-Content -Path $logFile -Raw
    Write-Host $logContent
}

Write-Host "=== Tests terminÃ©s avec succÃ¨s ! ===" -ForegroundColor Cyan

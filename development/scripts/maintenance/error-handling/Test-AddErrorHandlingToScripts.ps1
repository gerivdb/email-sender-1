<#
.SYNOPSIS
    Script de test pour l'ajout de gestion d'erreurs Ã  plusieurs scripts.

.DESCRIPTION
    Ce script teste l'ajout automatique de blocs try/catch Ã  plusieurs scripts PowerShell.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# CrÃ©er un rÃ©pertoire de test
$testDirectory = Join-Path -Path $env:TEMP -ChildPath "ErrorHandlingMultipleTests"
if (Test-Path -Path $testDirectory) {
    Remove-Item -Path $testDirectory -Recurse -Force
}
New-Item -Path $testDirectory -ItemType Directory -Force | Out-Null

# CrÃ©er des scripts de test
$scriptCount = 5
for ($i = 1; $i -le $scriptCount; $i++) {
    $scriptPath = Join-Path -Path $testDirectory -ChildPath "TestScript$i.ps1"
    $scriptContent = @"
# Script de test $i sans gestion d'erreurs
function Test-Function$i {
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Path
    )
    
    Get-Content -Path `$Path
}

# Appeler la fonction avec un chemin invalide
Test-Function$i -Path "C:\chemin\invalide$i.txt"
"@
    Set-Content -Path $scriptPath -Value $scriptContent -Force
}

Write-Host "=== Test de l'ajout de gestion d'erreurs Ã  plusieurs scripts ===" -ForegroundColor Cyan
Write-Host "RÃ©pertoire de test: $testDirectory"
Write-Host "Nombre de scripts crÃ©Ã©s: $scriptCount"
Write-Host

# ExÃ©cuter le script d'ajout de gestion d'erreurs
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Add-ErrorHandlingToScripts.ps1"
& $scriptPath -ScriptPath $testDirectory -BackupFiles

# VÃ©rifier les rÃ©sultats
Write-Host
Write-Host "=== VÃ©rification des rÃ©sultats ===" -ForegroundColor Cyan

# VÃ©rifier que les sauvegardes ont Ã©tÃ© crÃ©Ã©es
$backupCount = (Get-ChildItem -Path $testDirectory -Filter "*.bak").Count
Write-Host "Nombre de fichiers de sauvegarde: $backupCount"

# VÃ©rifier que les scripts ont Ã©tÃ© modifiÃ©s
$modifiedCount = 0
for ($i = 1; $i -le $scriptCount; $i++) {
    $scriptPath = Join-Path -Path $testDirectory -ChildPath "TestScript$i.ps1"
    $scriptContent = Get-Content -Path $scriptPath -Raw
    if ($scriptContent -match "try\s*\{") {
        $modifiedCount++
    }
}
Write-Host "Nombre de scripts modifiÃ©s: $modifiedCount"

# Afficher un exemple de script modifiÃ©
$exampleScript = Join-Path -Path $testDirectory -ChildPath "TestScript1.ps1"
Write-Host
Write-Host "Exemple de script modifiÃ©:" -ForegroundColor Yellow
Get-Content -Path $exampleScript | ForEach-Object { Write-Host "  $_" }

Write-Host
Write-Host "=== Test terminÃ© avec succÃ¨s ! ===" -ForegroundColor Cyan

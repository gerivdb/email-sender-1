<#
.SYNOPSIS
    Script de test pour l'ajout de gestion d'erreurs à plusieurs scripts.

.DESCRIPTION
    Ce script teste l'ajout automatique de blocs try/catch à plusieurs scripts PowerShell.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Créer un répertoire de test
$testDirectory = Join-Path -Path $env:TEMP -ChildPath "ErrorHandlingMultipleTests"
if (Test-Path -Path $testDirectory) {
    Remove-Item -Path $testDirectory -Recurse -Force
}
New-Item -Path $testDirectory -ItemType Directory -Force | Out-Null

# Créer des scripts de test
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

Write-Host "=== Test de l'ajout de gestion d'erreurs à plusieurs scripts ===" -ForegroundColor Cyan
Write-Host "Répertoire de test: $testDirectory"
Write-Host "Nombre de scripts créés: $scriptCount"
Write-Host

# Exécuter le script d'ajout de gestion d'erreurs
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Add-ErrorHandlingToScripts.ps1"
& $scriptPath -ScriptPath $testDirectory -BackupFiles

# Vérifier les résultats
Write-Host
Write-Host "=== Vérification des résultats ===" -ForegroundColor Cyan

# Vérifier que les sauvegardes ont été créées
$backupCount = (Get-ChildItem -Path $testDirectory -Filter "*.bak").Count
Write-Host "Nombre de fichiers de sauvegarde: $backupCount"

# Vérifier que les scripts ont été modifiés
$modifiedCount = 0
for ($i = 1; $i -le $scriptCount; $i++) {
    $scriptPath = Join-Path -Path $testDirectory -ChildPath "TestScript$i.ps1"
    $scriptContent = Get-Content -Path $scriptPath -Raw
    if ($scriptContent -match "try\s*\{") {
        $modifiedCount++
    }
}
Write-Host "Nombre de scripts modifiés: $modifiedCount"

# Afficher un exemple de script modifié
$exampleScript = Join-Path -Path $testDirectory -ChildPath "TestScript1.ps1"
Write-Host
Write-Host "Exemple de script modifié:" -ForegroundColor Yellow
Get-Content -Path $exampleScript | ForEach-Object { Write-Host "  $_" }

Write-Host
Write-Host "=== Test terminé avec succès ! ===" -ForegroundColor Cyan

#Requires -Version 5.1
<#
.SYNOPSIS
    Test de base pour le système d'inventaire des scripts
.DESCRIPTION
    Ce script effectue un test de base pour vérifier le fonctionnement
    du système d'inventaire des scripts.
.EXAMPLE
    .\Test-ScriptInventoryBasic.ps1
.NOTES
    Auteur: Augment Agent
    Version: 1.0
#>
[CmdletBinding()]
param()

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\ScriptInventoryManager.psm1"
Import-Module $modulePath -Force

# Créer un répertoire de test temporaire
$testDir = Join-Path -Path $env:TEMP -ChildPath "ScriptInventoryTest_$(Get-Random)"
New-Item -ItemType Directory -Path $testDir -Force | Out-Null

# Créer un fichier de test
$testFilePath = Join-Path -Path $testDir -ChildPath "Test-Script.ps1"
$testFileContent = @"
<#
.SYNOPSIS
    Script de test
.DESCRIPTION
    Ce script est utilisé pour tester l'inventaire des scripts
.AUTHOR
    Test Author
.VERSION
    1.0
.TAGS
    Test, Exemple
#>

function Test-Function {
    # Fonction de test
}
"@
Set-Content -Path $testFilePath -Value $testFileContent

# Tester l'inventaire des scripts
Write-Host "Test de l'inventaire des scripts..." -ForegroundColor Cyan
Write-Host "Répertoire de test: $testDir" -ForegroundColor White
Write-Host "Fichier de test: $testFilePath" -ForegroundColor White

# Vérifier que le fichier de test existe
if (Test-Path $testFilePath) {
    Write-Host "Le fichier de test existe." -ForegroundColor Green
} else {
    Write-Host "Le fichier de test n'existe pas!" -ForegroundColor Red
}

# Exécuter l'inventaire avec verbosité
$VerbosePreference = 'Continue'
$scripts = Get-ScriptInventory -Path $testDir -ForceRescan -Verbose
$VerbosePreference = 'SilentlyContinue'

Write-Host "Nombre de scripts trouvés: $($scripts.Count)" -ForegroundColor Green

# Afficher les métadonnées du script
if ($scripts.Count -gt 0) {
    $script = $scripts[0]
    Write-Host "`nMétadonnées du script:" -ForegroundColor Cyan
    Write-Host "Nom: $($script.FileName)" -ForegroundColor White
    Write-Host "Chemin: $($script.FullPath)" -ForegroundColor White
    Write-Host "Langage: $($script.Language)" -ForegroundColor White
    Write-Host "Auteur: $($script.Author)" -ForegroundColor White
    Write-Host "Version: $($script.Version)" -ForegroundColor White
    Write-Host "Description: $($script.Description)" -ForegroundColor White
    Write-Host "Tags: $($script.Tags -join ', ')" -ForegroundColor White
    Write-Host "Catégorie: $($script.Category)" -ForegroundColor White
    Write-Host "Sous-catégorie: $($script.SubCategory)" -ForegroundColor White
    Write-Host "Dernière modification: $($script.LastModified)" -ForegroundColor White
    Write-Host "Nombre de lignes: $($script.LineCount)" -ForegroundColor White
}

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force

# Afficher un résumé
Write-Host "`nTest terminé." -ForegroundColor Green

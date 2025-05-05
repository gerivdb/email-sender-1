# Script pour tester l'environnement PowerShell
# Ce script utilise uniquement des fonctionnalités de base pour vérifier l'environnement

# Afficher les informations sur l'environnement PowerShell
Write-Host "Test de l'environnement PowerShell" -ForegroundColor Cyan
Write-Host "--------------------------------" -ForegroundColor Cyan
Write-Host "Version PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Green
Write-Host "Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Green
Write-Host "OS: $($PSVersionTable.OS)" -ForegroundColor Green
Write-Host "Repertoire courant: $(Get-Location)" -ForegroundColor Green
Write-Host "--------------------------------" -ForegroundColor Cyan

# Tester la création d'un objet simple
Write-Host "Test de creation d'objet..." -ForegroundColor Cyan
$testObject = @{
    Name = "Test Object"
    Value = 123
    Created = Get-Date
}
Write-Host "Objet cree avec succes: $($testObject.Name)" -ForegroundColor Green

# Tester une fonction simple
Write-Host "Test de fonction simple..." -ForegroundColor Cyan
function Get-TestValue {
    param (
        [string]$Prefix = "Test"
    )
    
    return "$Prefix Value"
}

$result = Get-TestValue -Prefix "Environment"
Write-Host "Fonction executee avec succes: $result" -ForegroundColor Green

# Tester l'accès aux fichiers
Write-Host "Test d'acces aux fichiers..." -ForegroundColor Cyan
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
Write-Host "Chemin du script: $scriptPath" -ForegroundColor Green
Write-Host "Chemin parent: $parentPath" -ForegroundColor Green

$files = Get-ChildItem -Path $scriptPath -File
Write-Host "Fichiers dans le repertoire de test: $($files.Count)" -ForegroundColor Green
foreach ($file in $files) {
    Write-Host "  - $($file.Name)" -ForegroundColor Green
}

# Résumé des tests
Write-Host "`nTests d'environnement termines avec succes!" -ForegroundColor Cyan
exit 0

# Test-SuperSimple.ps1
# Script de test super simple pour la création et la lecture d'un fichier

# Définir le chemin du fichier de test
$testFilePath = Join-Path -Path $PSScriptRoot -ChildPath "TestSuperSimple.txt"

# Supprimer le fichier s'il existe déjà
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier existant supprimé" -ForegroundColor Yellow
}

# Créer un contenu simple
$testContent = "Ceci est un test"

# Enregistrer le contenu
Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8

# Vérifier que le fichier existe
if (Test-Path -Path $testFilePath) {
    Write-Host "Fichier créé avec succès" -ForegroundColor Green
} else {
    Write-Host "Échec de création du fichier" -ForegroundColor Red
    exit 1
}

# Lire le fichier
$loadedContent = Get-Content -Path $testFilePath -Raw

# Vérifier le contenu
if ($loadedContent -eq $testContent) {
    Write-Host "Le contenu est correct" -ForegroundColor Green
} else {
    Write-Host "Le contenu est incorrect" -ForegroundColor Red
    Write-Host "Attendu: $testContent" -ForegroundColor Yellow
    Write-Host "Obtenu: $loadedContent" -ForegroundColor Yellow
}

# Nettoyer
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de test supprimé" -ForegroundColor Yellow
}

Write-Host "Test terminé" -ForegroundColor Cyan

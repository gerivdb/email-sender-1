# Script pour exécuter les tests unitaires de l'extension

# Se placer dans le répertoire de l'extension
Set-Location -Path "$PSScriptRoot"

# Compiler l'extension
Write-Host "Compilation de l'extension..." -ForegroundColor Cyan
npm run compile

# Exécuter les tests
Write-Host "Exécution des tests..." -ForegroundColor Cyan
npm run test

# Afficher un message de succès
Write-Host "Tests terminés !" -ForegroundColor Green

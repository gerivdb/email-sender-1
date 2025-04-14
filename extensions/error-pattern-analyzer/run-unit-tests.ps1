# Script pour exécuter les tests unitaires de l'extension

# Se placer dans le répertoire de l'extension
Set-Location -Path "$PSScriptRoot"

# Compiler l'extension
Write-Host "Compilation de l'extension..." -ForegroundColor Cyan
npm run compile

# Exécuter les tests unitaires
Write-Host "Exécution des tests unitaires..." -ForegroundColor Cyan
npm run test:unit

# Afficher un message de succès
Write-Host "Tests terminés !" -ForegroundColor Green

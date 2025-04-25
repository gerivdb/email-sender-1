# Script pour exécuter Example-Integration.ps1 avec le bon encodage
# Ce script configure l'encodage de la console PowerShell avant d'exécuter le script d'intégration

# Configurer l'encodage de la console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Chemin vers le script d'intégration
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Example-Integration.ps1"

# Exécuter le script d'intégration
& $scriptPath

# Afficher un message de confirmation
Write-Host "`nScript exécuté avec encodage UTF-8" -ForegroundColor Green

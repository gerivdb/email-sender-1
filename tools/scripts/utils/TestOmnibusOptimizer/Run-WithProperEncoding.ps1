# Script pour exÃ©cuter Example-Integration.ps1 avec le bon encodage
# Ce script configure l'encodage de la console PowerShell avant d'exÃ©cuter le script d'intÃ©gration

# Configurer l'encodage de la console
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# Chemin vers le script d'intÃ©gration
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Example-Integration.ps1"

# ExÃ©cuter le script d'intÃ©gration
& $scriptPath

# Afficher un message de confirmation
Write-Host "`nScript exÃ©cutÃ© avec encodage UTF-8" -ForegroundColor Green

# Test-Simple.ps1
# Script simple pour tester l'exécution PowerShell
# Version: 1.0
# Date: 2025-05-15

Write-Host "Test simple"
Write-Host "==========="

Write-Host "Hello, world!"

# Afficher la date et l'heure
Write-Host "Date et heure: $(Get-Date)"

# Afficher la version de PowerShell
Write-Host "Version de PowerShell: $($PSVersionTable.PSVersion)"

# Afficher le chemin du script
Write-Host "Chemin du script: $PSCommandPath"

# Afficher le répertoire courant
Write-Host "Répertoire courant: $(Get-Location)"

Write-Host "Test terminé."

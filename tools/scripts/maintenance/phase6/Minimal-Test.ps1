# Script de test minimal
Write-Host "Test minimal exécuté avec succès"
Write-Host "PowerShell version: $($PSVersionTable.PSVersion)"
Write-Host "Répertoire courant: $(Get-Location)"
Write-Host "Utilisateur actuel: $env:USERNAME"
Write-Host "Ordinateur: $env:COMPUTERNAME"
Write-Host "Date et heure: $(Get-Date)"

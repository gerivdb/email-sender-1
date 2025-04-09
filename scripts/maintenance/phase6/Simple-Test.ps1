# Script de test simple
Write-Host "Test simple exécuté avec succès"
Write-Host "Répertoire courant : $(Get-Location)"
Write-Host "Fichiers dans le répertoire courant :"
Get-ChildItem | Select-Object Name, Length | Format-Table

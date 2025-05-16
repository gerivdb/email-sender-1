# Script de test simple pour vérifier l'affichage des couleurs
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  TEST SIMPLE D'AFFICHAGE" -ForegroundColor Cyan
Write-Host "  $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host "Message en vert" -ForegroundColor Green
Write-Host "Message en rouge" -ForegroundColor Red
Write-Host "Message en jaune" -ForegroundColor Yellow
Write-Host "Message en cyan" -ForegroundColor Cyan
Write-Host "Message en magenta" -ForegroundColor Magenta

Write-Host "Test des scripts disponibles dans le dossier:"
Get-ChildItem -Path $PSScriptRoot -Filter "*.ps1" | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor Cyan
}

Write-Host "Version PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Green
Write-Host "Chemin du script: $PSCommandPath" -ForegroundColor Green

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  FIN DU TEST" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

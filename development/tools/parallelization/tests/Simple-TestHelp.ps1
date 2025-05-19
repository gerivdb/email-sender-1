# Script simple pour tester l'affichage de l'aide
Write-Host "Importation du module..."
Import-Module -Name "$PSScriptRoot\..\UnifiedParallel.psm1" -Force

Write-Host "Affichage de l'aide pour Get-RunspacePoolCacheInfo..."
Get-Help -Name Get-RunspacePoolCacheInfo -Detailed

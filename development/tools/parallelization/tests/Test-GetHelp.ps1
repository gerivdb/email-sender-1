# Script pour tester l'affichage de l'aide avec Get-Help
#Requires -Version 5.1

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Fonction à tester
$functionName = "Get-RunspacePoolCacheInfo"

# Afficher l'aide de la fonction
Write-Host "=== Aide pour $functionName ===" -ForegroundColor Cyan
Get-Help -Name $functionName -Full

# Tester l'affichage de l'aide pour d'autres fonctions
$otherFunctions = @(
    "Initialize-UnifiedParallel",
    "Invoke-UnifiedParallel",
    "Clear-UnifiedParallel",
    "Get-OptimalThreadCount",
    "New-UnifiedError"
)

foreach ($function in $otherFunctions) {
    Write-Host "`n=== Synopsis de $function ===" -ForegroundColor Cyan
    Get-Help -Name $function | Select-Object -ExpandProperty Synopsis
}

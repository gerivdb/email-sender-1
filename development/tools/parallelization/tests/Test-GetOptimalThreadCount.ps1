# Script pour tester la fonction Get-OptimalThreadCount
#Requires -Version 5.1

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel

# Tester la fonction avec différents paramètres
Write-Host "=== Test de Get-OptimalThreadCount avec différents paramètres ===" -ForegroundColor Cyan

# Test 1: Paramètres par défaut
$result = Get-OptimalThreadCount
Write-Host "Paramètres par défaut: $result threads" -ForegroundColor Yellow

# Test 2: Type de tâche CPU
$result = Get-OptimalThreadCount -TaskType 'CPU'
Write-Host "Type de tâche CPU: $result threads" -ForegroundColor Yellow

# Test 3: Type de tâche IO
$result = Get-OptimalThreadCount -TaskType 'IO'
Write-Host "Type de tâche IO: $result threads" -ForegroundColor Yellow

# Test 4: Type de tâche Mixed
$result = Get-OptimalThreadCount -TaskType 'Mixed'
Write-Host "Type de tâche Mixed: $result threads" -ForegroundColor Yellow

# Test 5: Type de tâche LowPriority
$result = Get-OptimalThreadCount -TaskType 'LowPriority'
Write-Host "Type de tâche LowPriority: $result threads" -ForegroundColor Yellow

# Test 6: Type de tâche HighPriority
$result = Get-OptimalThreadCount -TaskType 'HighPriority'
Write-Host "Type de tâche HighPriority: $result threads" -ForegroundColor Yellow

# Test 7: Avec charge système
$result = Get-OptimalThreadCount -SystemLoadPercent 50 -Dynamic
Write-Host "Avec charge système 50% et Dynamic: $result threads" -ForegroundColor Yellow

# Test 8: Avec charge système élevée
$result = Get-OptimalThreadCount -SystemLoadPercent 80 -Dynamic
Write-Host "Avec charge système 80% et Dynamic: $result threads" -ForegroundColor Yellow

# Test 9: Avec considération de la mémoire
$result = Get-OptimalThreadCount -ConsiderMemory -Dynamic
Write-Host "Avec considération de la mémoire: $result threads" -ForegroundColor Yellow

# Test 10: Avec considération des E/S disque
$result = Get-OptimalThreadCount -TaskType 'IO' -ConsiderDiskIO -Dynamic
Write-Host "Avec considération des E/S disque: $result threads" -ForegroundColor Yellow

# Test 11: Avec considération du réseau
$result = Get-OptimalThreadCount -TaskType 'IO' -ConsiderNetworkIO -Dynamic
Write-Host "Avec considération du réseau: $result threads" -ForegroundColor Yellow

# Test 12: Combinaison de paramètres
$result = Get-OptimalThreadCount -TaskType 'Mixed' -SystemLoadPercent 60 -ConsiderMemory -Dynamic
Write-Host "Combinaison de paramètres: $result threads" -ForegroundColor Yellow

# Afficher l'aide de la fonction
Write-Host "`n=== Aide de la fonction Get-OptimalThreadCount ===" -ForegroundColor Cyan
Get-Help -Name Get-OptimalThreadCount -Detailed

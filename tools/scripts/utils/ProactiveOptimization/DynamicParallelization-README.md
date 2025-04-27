# Optimisation Dynamique de la ParallÃ©lisation

Ce module implÃ©mente un systÃ¨me d'optimisation dynamique de la parallÃ©lisation qui ajuste automatiquement le nombre de threads et la prioritÃ© des tÃ¢ches en fonction de la charge systÃ¨me et des patterns d'utilisation.

## FonctionnalitÃ©s

- **Ajustement dynamique du nombre de threads** : Adapte automatiquement le nombre de threads en fonction de la charge CPU et de la mÃ©moire disponible.
- **File d'attente prioritaire** : Organise les tÃ¢ches par prioritÃ© et promeut automatiquement les tÃ¢ches qui attendent depuis longtemps.
- **DÃ©tection des blocages** : Identifie et priorise les tÃ¢ches qui bloquent souvent d'autres processus.
- **SystÃ¨me de feedback** : Collecte des mÃ©triques de performance pour amÃ©liorer continuellement les stratÃ©gies de parallÃ©lisation.

## Structure du module

- `Dynamic-ThreadManager.psm1` : Module pour l'ajustement dynamique du nombre de threads.
- `TaskPriorityQueue.psm1` : Module pour la gestion de la file d'attente prioritaire des tÃ¢ches.
- `Demo-DynamicParallelization.ps1` : Script de dÃ©monstration montrant l'utilisation des modules.
- `tests/` : Tests unitaires pour les modules.

## Utilisation

### Ajustement dynamique du nombre de threads

```powershell
# Importer le module
Import-Module .\Dynamic-ThreadManager.psm1

# Obtenir le nombre optimal de threads
$optimalThreads = Get-OptimalThreadCount -CpuThreshold 80 -MemoryThreshold 20

# DÃ©marrer le monitoring des threads avec un callback
$monitoring = Start-ThreadMonitoring -IntervalSeconds 5 -AdjustmentCallback {
    param($optimalThreads)
    Write-Host "Nombre optimal de threads: $optimalThreads"
}

# ArrÃªter le monitoring
Stop-ThreadMonitoring -MonitoringId $monitoring.MonitoringId
```

### Gestion de la file d'attente prioritaire

```powershell
# Importer le module
Import-Module .\TaskPriorityQueue.psm1

# CrÃ©er une file d'attente prioritaire
$queue = New-TaskPriorityQueue -PromotionThreshold 5 -MaxPriority 10

# CrÃ©er une tÃ¢che
$task = New-PriorityTask -Name "Ma tÃ¢che" -ScriptBlock {
    param($data)
    # Traitement de la tÃ¢che
    return "RÃ©sultat: $data"
} -Priority 7 -Parameters @{ Data = "Test" }

# Ajouter la tÃ¢che Ã  la file d'attente
Add-TaskToQueue -Queue $queue -Task $task

# Promouvoir les tÃ¢ches en attente
Invoke-TaskPromotion -Queue $queue

# Signaler qu'une tÃ¢che est bloquÃ©e
Register-TaskBlocked -Queue $queue -TaskId $task.Id

# RÃ©cupÃ©rer la prochaine tÃ¢che
$nextTask = Get-NextTask -Queue $queue
```

## ExÃ©cution des tests

Pour exÃ©cuter les tests unitaires :

```powershell
# ExÃ©cuter tous les tests
.\tests\Run-ParallelizationTests.ps1

# ExÃ©cuter un test spÃ©cifique
Invoke-Pester -Path .\tests\Dynamic-ThreadManager.Tests.ps1
```

## DÃ©monstration

Pour voir le systÃ¨me en action :

```powershell
# ExÃ©cuter la dÃ©monstration
.\Demo-DynamicParallelization.ps1
```

## IntÃ©gration avec d'autres modules

Ce systÃ¨me d'optimisation dynamique peut Ãªtre intÃ©grÃ© avec d'autres modules du projet :

- **PSCacheManager** : Pour mettre en cache les rÃ©sultats des tÃ¢ches frÃ©quemment exÃ©cutÃ©es.
- **UsageMonitor** : Pour collecter des statistiques d'utilisation et amÃ©liorer les stratÃ©gies de parallÃ©lisation.
- **TestOmnibus** : Pour optimiser l'exÃ©cution des tests en fonction de leur historique d'exÃ©cution.

## Bonnes pratiques

- Utilisez `Get-OptimalThreadCount` pour dÃ©terminer le nombre optimal de threads en fonction de la charge systÃ¨me.
- Ajustez progressivement le nombre de threads avec `Update-ThreadCount` pour Ã©viter les oscillations.
- Utilisez la file d'attente prioritaire pour organiser les tÃ¢ches par ordre d'importance.
- Signalez les tÃ¢ches bloquantes avec `Register-TaskBlocked` pour amÃ©liorer la dÃ©tection des dÃ©pendances.
- ExÃ©cutez rÃ©guliÃ¨rement `Invoke-TaskPromotion` pour Ã©viter la famine des tÃ¢ches Ã  faible prioritÃ©.

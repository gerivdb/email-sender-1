# Optimisation Dynamique de la Parallélisation

Ce module implémente un système d'optimisation dynamique de la parallélisation qui ajuste automatiquement le nombre de threads et la priorité des tâches en fonction de la charge système et des patterns d'utilisation.

## Fonctionnalités

- **Ajustement dynamique du nombre de threads** : Adapte automatiquement le nombre de threads en fonction de la charge CPU et de la mémoire disponible.
- **File d'attente prioritaire** : Organise les tâches par priorité et promeut automatiquement les tâches qui attendent depuis longtemps.
- **Détection des blocages** : Identifie et priorise les tâches qui bloquent souvent d'autres processus.
- **Système de feedback** : Collecte des métriques de performance pour améliorer continuellement les stratégies de parallélisation.

## Structure du module

- `Dynamic-ThreadManager.psm1` : Module pour l'ajustement dynamique du nombre de threads.
- `TaskPriorityQueue.psm1` : Module pour la gestion de la file d'attente prioritaire des tâches.
- `Demo-DynamicParallelization.ps1` : Script de démonstration montrant l'utilisation des modules.
- `tests/` : Tests unitaires pour les modules.

## Utilisation

### Ajustement dynamique du nombre de threads

```powershell
# Importer le module
Import-Module .\Dynamic-ThreadManager.psm1

# Obtenir le nombre optimal de threads
$optimalThreads = Get-OptimalThreadCount -CpuThreshold 80 -MemoryThreshold 20

# Démarrer le monitoring des threads avec un callback
$monitoring = Start-ThreadMonitoring -IntervalSeconds 5 -AdjustmentCallback {
    param($optimalThreads)
    Write-Host "Nombre optimal de threads: $optimalThreads"
}

# Arrêter le monitoring
Stop-ThreadMonitoring -MonitoringId $monitoring.MonitoringId
```

### Gestion de la file d'attente prioritaire

```powershell
# Importer le module
Import-Module .\TaskPriorityQueue.psm1

# Créer une file d'attente prioritaire
$queue = New-TaskPriorityQueue -PromotionThreshold 5 -MaxPriority 10

# Créer une tâche
$task = New-PriorityTask -Name "Ma tâche" -ScriptBlock {
    param($data)
    # Traitement de la tâche
    return "Résultat: $data"
} -Priority 7 -Parameters @{ Data = "Test" }

# Ajouter la tâche à la file d'attente
Add-TaskToQueue -Queue $queue -Task $task

# Promouvoir les tâches en attente
Invoke-TaskPromotion -Queue $queue

# Signaler qu'une tâche est bloquée
Register-TaskBlocked -Queue $queue -TaskId $task.Id

# Récupérer la prochaine tâche
$nextTask = Get-NextTask -Queue $queue
```

## Exécution des tests

Pour exécuter les tests unitaires :

```powershell
# Exécuter tous les tests
.\tests\Run-ParallelizationTests.ps1

# Exécuter un test spécifique
Invoke-Pester -Path .\tests\Dynamic-ThreadManager.Tests.ps1
```

## Démonstration

Pour voir le système en action :

```powershell
# Exécuter la démonstration
.\Demo-DynamicParallelization.ps1
```

## Intégration avec d'autres modules

Ce système d'optimisation dynamique peut être intégré avec d'autres modules du projet :

- **PSCacheManager** : Pour mettre en cache les résultats des tâches fréquemment exécutées.
- **UsageMonitor** : Pour collecter des statistiques d'utilisation et améliorer les stratégies de parallélisation.
- **TestOmnibus** : Pour optimiser l'exécution des tests en fonction de leur historique d'exécution.

## Bonnes pratiques

- Utilisez `Get-OptimalThreadCount` pour déterminer le nombre optimal de threads en fonction de la charge système.
- Ajustez progressivement le nombre de threads avec `Update-ThreadCount` pour éviter les oscillations.
- Utilisez la file d'attente prioritaire pour organiser les tâches par ordre d'importance.
- Signalez les tâches bloquantes avec `Register-TaskBlocked` pour améliorer la détection des dépendances.
- Exécutez régulièrement `Invoke-TaskPromotion` pour éviter la famine des tâches à faible priorité.

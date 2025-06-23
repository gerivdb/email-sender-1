# CleanupManager

- **Rôle :** Nettoyage, organisation intelligente, suppression, détection de doublons, analyse de structure, reporting.
- **Interfaces :**
  - `ScanForCleanup(ctx context.Context, directories []string) ([]CleanupTask, error)`
  - `ExecuteTasks(ctx context.Context, tasks []CleanupTask, dryRun bool) error`
  - `GetStats() CleanupStats`
  - `GetHealthStatus(ctx context.Context) core.HealthStatus`
- **Utilisation :** Analyse et nettoyage de répertoires, suppression de fichiers temporaires ou obsolètes, détection de doublons, organisation automatique, reporting, intégration IA. Utilisé par MaintenanceManager et d’autres modules pour la maintenance documentaire.
- **Entrée/Sortie :**
  - Entrées : contextes d’exécution, configurations, listes de répertoires, tâches de nettoyage.
  - Sorties : rapports, logs, statistiques, statuts de santé, erreurs éventuelles.

---

[Retour à l’index des managers](INDEX.md) | [Vue d’ensemble de l’architecture](../ARCHITECTURE/ecosystem-overview.md)

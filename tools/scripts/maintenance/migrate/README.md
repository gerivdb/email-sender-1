# Scripts de migration

Ce répertoire contient des scripts pour migrer des fichiers d'un répertoire à un autre.

## Utilisation avec Hygen

```bash
hygen maintenance migrate
```

## Bonnes pratiques

1. Toujours exécuter les scripts en mode simulation (`-DryRun`) avant de les exécuter réellement
2. Créer des sauvegardes avant d'effectuer des opérations potentiellement destructives
3. Journaliser toutes les actions effectuées
4. Tester les scripts de rollback après une migration réussie

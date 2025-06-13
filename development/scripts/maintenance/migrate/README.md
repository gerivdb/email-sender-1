# Scripts de migration

Ce rÃ©pertoire contient des scripts pour migrer des fichiers d'un rÃ©pertoire Ã  un autre.

## Utilisation avec Hygen

```bash
hygen maintenance migrate
```plaintext
## Bonnes pratiques

1. Toujours exÃ©cuter les scripts en mode simulation (`-DryRun`) avant de les exÃ©cuter rÃ©ellement
2. CrÃ©er des sauvegardes avant d'effectuer des opÃ©rations potentiellement destructives
3. Journaliser toutes les actions effectuÃ©es
4. Tester les scripts de rollback aprÃ¨s une migration rÃ©ussie

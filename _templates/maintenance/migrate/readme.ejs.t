<#
---
to: D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/maintenance/migrate/README.md
unless_exists: true
---
# Scripts de migration

Ce répertoire contient des scripts pour migrer des fichiers d'un répertoire à un autre.

## Scripts disponibles

- `<%= name %>.ps1` - <%= description %>
<% if (createRollback) { %>
- `rollback-<%= name %>.ps1` - Script de rollback pour <%= description.toLowerCase() %>
<% } %>

## Utilisation

```powershell
# Exécuter en mode simulation (dry run)
.\<%= name %>.ps1 -DryRun

# Exécuter avec confirmation pour chaque action
.\<%= name %>.ps1

# Exécuter sans confirmation et avec journalisation
.\<%= name %>.ps1 -Force -LogFile "migration.log"
<% if (createRollback) { %>

# Annuler la migration (rollback)
.\rollback-<%= name %>.ps1 -DryRun
.\rollback-<%= name %>.ps1 -Force -LogFile "rollback.log"
<% } %>
```

## Détails de la migration

- **Source** : `<%= sourceDir %>`
- **Destination** : `<%= targetDir %>`
- **Type de fichiers** : `<%= fileType === 'custom' ? customPattern : '*.' + fileType %>`

## Journalisation

Les scripts de migration et de rollback peuvent générer des fichiers de log détaillés pour suivre les actions effectuées. Ces logs incluent :

- Horodatage de début et de fin
- Répertoires source et cible
- Motif de fichiers
- Liste des fichiers migrés/restaurés
- Résumé des opérations

## Bonnes pratiques

1. Toujours exécuter d'abord en mode simulation (`-DryRun`) pour vérifier les actions qui seront effectuées
2. Créer une sauvegarde des données importantes avant d'exécuter une migration
3. Utiliser le paramètre `-LogFile` pour conserver une trace des actions effectuées
4. Tester le script de rollback après une migration réussie pour s'assurer qu'il fonctionne correctement

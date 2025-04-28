<#
---
to: D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/maintenance/cleanup/README.md
unless_exists: true
---
# Scripts de nettoyage

Ce répertoire contient des scripts pour nettoyer les fichiers inutiles dans différents répertoires du projet.

## Scripts disponibles

- `<%= name %>.ps1` - <%= description %>

## Utilisation

```powershell
# Exécuter en mode simulation (dry run)
.\<%= name %>.ps1 -DryRun

# Exécuter avec confirmation pour chaque action
.\<%= name %>.ps1

# Exécuter sans confirmation et avec journalisation
.\<%= name %>.ps1 -Force -LogFile "cleanup.log"
```

## Détails du nettoyage

- **Répertoire cible** : `<%= targetDir %>`
- **Type de nettoyage** : `<%= cleanupType %>`
<% if (cleanupType === 'custom') { %>
- **Motif personnalisé** : `<%= customPattern %>`
<% } %>
- **Récursif** : `<%= recursive ? 'Oui' : 'Non' %>`
<% if (createBackup) { %>
- **Sauvegarde** : Oui (créée avant le nettoyage)
<% } %>

## Types de nettoyage disponibles

- **temp** : Fichiers temporaires (*.tmp, *.temp, ~*, *.cache)
- **logs** : Fichiers de journalisation (*.log, *.log.*, *_log_*, *.trace)
- **backups** : Fichiers de sauvegarde (*.bak, *.backup, *_backup_*, *.old)
- **duplicates** : Fichiers dupliqués (*_copy*.*, *_copie*.*, * - Copy*.*, * - Copie*.*)
- **empty** : Dossiers vides
- **custom** : Motif personnalisé

## Journalisation

Le script de nettoyage peut générer un fichier de log détaillé pour suivre les actions effectuées. Ce log inclut :

- Horodatage de début et de fin
- Répertoire cible
- Motifs de fichiers
- Liste des fichiers supprimés
- Résumé des opérations

## Bonnes pratiques

1. Toujours exécuter d'abord en mode simulation (`-DryRun`) pour vérifier les actions qui seront effectuées
2. Créer une sauvegarde des données importantes avant d'exécuter un nettoyage
3. Utiliser le paramètre `-LogFile` pour conserver une trace des actions effectuées
4. Nettoyer régulièrement les fichiers temporaires et les logs pour économiser de l'espace disque

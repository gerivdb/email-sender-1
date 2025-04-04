# Guide d'organisation automatique (mise à jour)

Ce guide explique comment configurer l'organisation automatique du projet après les changements de chemins.

## Configuration manuelle des tâches planifiées

Puisque la configuration automatique nécessite des privilèges d'administrateur, voici comment configurer manuellement les tâches planifiées :

### 1. Organiser les scripts (hebdomadaire)

1. Ouvrez le Planificateur de tâches Windows (tapez "Planificateur de tâches" dans la recherche Windows)
2. Cliquez sur "Créer une tâche de base..."
3. Nom : "Organisation des scripts N8N"
4. Description : "Organise les scripts du projet N8N"
5. Déclencheur : Hebdomadaire (choisissez le jour qui vous convient)
6. Action : Démarrer un programme
7. Programme/script : `powershell.exe`
8. Arguments : `-ExecutionPolicy Bypass -File "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1\scripts\utils\automation\auto-organize-folders.ps1" -FolderPath "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1\scripts" -MaxFilesPerFolder 15`

### 2. Organiser les dossiers (quotidienne)

1. Ouvrez le Planificateur de tâches Windows
2. Cliquez sur "Créer une tâche de base..."
3. Nom : "Organisation des dossiers N8N"
4. Description : "Organise les dossiers du projet N8N"
5. Déclencheur : Quotidienne
6. Action : Démarrer un programme
7. Programme/script : `powershell.exe`
8. Arguments : `-ExecutionPolicy Bypass -File "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1\scripts\utils\automation\auto-organize-folders.ps1" -MaxFilesPerFolder 15`

### 3. Gérer les logs (quotidienne)

1. Ouvrez le Planificateur de tâches Windows
2. Cliquez sur "Créer une tâche de base..."
3. Nom : "Gestion des logs N8N"
4. Description : "Gère les logs du projet N8N"
5. Déclencheur : Quotidienne
6. Action : Démarrer un programme
7. Programme/script : `powershell.exe`
8. Arguments : `-ExecutionPolicy Bypass -File "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1\scripts\utils\automation\manage-logs.ps1" -LogName "n8n" -Category "daily"`

## Configuration automatique (avec privilèges administrateur)

Si vous préférez utiliser le script automatique, suivez ces étapes :

1. Ouvrez PowerShell en tant qu'administrateur
2. Naviguez vers le dossier du projet :
   ```powershell
   cd "D:\DO\WEB\N8N_tests\scripts_ json_a_ tester\EMAIL_SENDER_1"
   ```
3. Exécutez le script de configuration :
   ```powershell
   .\scripts\utils\automation\setup-auto-organization.ps1
   ```

## Vérification des tâches planifiées

Pour vérifier que les tâches ont été correctement créées :

1. Ouvrez le Planificateur de tâches Windows
2. Naviguez vers "Bibliothèque du Planificateur de tâches"
3. Recherchez les tâches "Organisation des scripts N8N", "Organisation des dossiers N8N" et "Gestion des logs N8N"

## Principes d'organisation

- **Limitation du nombre de fichiers** : Maximum 15 fichiers par dossier
- **Organisation sémantique** : Classement par type d'usage
- **Logs par unité de temps** : Quotidien, hebdomadaire, mensuel
- **Archivage automatique** : Compression des anciens logs

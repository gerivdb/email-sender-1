# Système d'Exclusion AVG pour le Développement

Ce document détaille le système d'exclusion automatique d'AVG mis en place pour résoudre les problèmes de blocage des fichiers exécutables pendant le développement.

## Problématique

L'antivirus AVG a tendance à bloquer les fichiers exécutables (`.exe`) générés lors de la compilation de code Go, Python ou d'autres langages, ce qui perturbe le flux de développement. Les principaux problèmes rencontrés étaient :

- Blocage des compilations Go (build) et des exécutables générés
- Faux positifs sur les binaires générés par les tests
- Latence importante lors des opérations de build
- Nécessité de constamment ajouter des exclusions manuelles

## Solution mise en place

Un système automatique d'exclusion AVG a été développé, s'articulant autour de plusieurs composants :

### 1. Scripts PowerShell d'exclusion

Trois scripts principaux ont été créés :

- **auto-avg-exclusion.ps1** : Script principal qui configure les exclusions AVG pour les dossiers et extensions critiques
- **ensure-exe-exclusion.ps1** : Script spécifique focalisé sur l'exclusion des fichiers `.exe`
- **avg-exclusion-vscode-hook.ps1** : Script wrapper qui s'exécute automatiquement à l'ouverture de VS Code

### 2. Marqueurs d'exclusion

Le système crée des "marqueurs d'exclusion" dans les dossiers critiques, permettant à AVG de reconnaître les zones à exclure :

- `.avg-exclude-marker` : Marqueur général d'exclusion pour un dossier
- `.avg-exclude-exe-marker` : Marqueur spécifique pour les fichiers `.exe` dans un dossier

### 3. Intégration VS Code

L'intégration avec VS Code permet le lancement automatique du système d'exclusion :

- Tâches VS Code configurées dans `.vscode/tasks.json`
- Démarrage automatique à l'ouverture du projet via `.vscode/settings.json`
- Interface utilisateur pour contrôler et vérifier l'état des exclusions

### 4. Script de test

Un script de test (`test-avg-exe-exclusion.ps1`) vérifie que les exclusions fonctionnent correctement en :

- Compilant un fichier Go en exécutable `.exe`
- Exécutant ce fichier pour vérifier qu'il n'est pas bloqué
- Générant un rapport de succès

## Utilisation

### Exécution automatique

Le système s'exécute automatiquement à l'ouverture du projet dans VS Code. Aucune intervention n'est requise.

### Commandes VS Code disponibles

Des tâches VS Code ont été configurées pour gérer les exclusions :

- `avg-exclusion.auto-start` : Démarre automatiquement le système (exécuté à l'ouverture)
- `avg-exclusion.start` : Démarre manuellement le système
- `avg-exclusion.status` : Affiche l'état actuel du système
- `avg-exclusion.stop` : Arrête le système
- `avg-exclusion.test-exe` : Exécute un test pour vérifier que les exclusions fonctionnent

Pour exécuter ces tâches, utilisez `Ctrl+Shift+P` → "Tasks: Run Task" → sélectionnez la tâche souhaitée.

### Vérification du fonctionnement

Pour vérifier que le système fonctionne correctement :

1. Exécutez la tâche `avg-exclusion.test-exe`
2. Si le test réussit, un fichier de rapport est généré dans `logs/avg-exe-exclusion-success.txt`

## Fichiers et dossiers exclus

### Dossiers critiques automatiquement exclus

```plaintext
D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1
D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\cmd
D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\pkg
D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools
D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development
D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\logs
%TEMP%\go-build*
%LOCALAPPDATA%\go-build
C:\Users\<username>\AppData\Local\go-build
```

### Extensions critiques exclues

```plaintext
.exe, .go, .mod, .sum, .dll, .a, .obj, .bin, .out,
.ps1, .bat, .cmd, .py, .pyc, .pyo, .pyd,
.js, .ts, .json, .yaml, .yml, .toml, .ini
```

### Patterns spécifiques pour les fichiers .exe

```plaintext
*go-build*.exe
*backup-qdrant.exe
*migrate-qdrant.exe
*monitoring-dashboard.exe
*simple-api-server.exe
*vector-migration.exe
*test*.exe
*debug*.exe
```

## Architecture technique

```plaintext
scripts/
├── auto-avg-exclusion.ps1        # Script principal d'exclusion AVG
├── ensure-exe-exclusion.ps1      # Script spécifique pour les fichiers .exe
├── avg-exclusion-vscode-hook.ps1 # Hook VS Code pour exécution automatique
├── test-avg-exe-exclusion.ps1    # Script de test des exclusions
└── manual-exe-exclusion.ps1      # Instructions manuelles (généré)

.vscode/
├── tasks.json                    # Configuration des tâches VS Code
└── settings.json                 # Configuration pour l'exécution automatique

logs/
├── avg-exclusion.log             # Logs du système d'exclusion
└── avg-exe-exclusion-success.txt # Rapport de succès des tests
```

## Dépannage

### AVG continue de bloquer certains fichiers

1. Vérifiez si les marqueurs d'exclusion existent dans les dossiers concernés
2. Exécutez manuellement le script de test pour diagnostiquer : `.\scripts\test-avg-exe-exclusion.ps1`
3. Consultez les logs dans `logs/avg-exclusion.log`

### Permissions insuffisantes

Pour une exclusion optimale, certaines opérations nécessitent des droits administrateur. Si vous rencontrez des problèmes :

1. Exécutez VS Code en tant qu'administrateur
2. Lancez la tâche `avg-exclusion.start` pour une configuration complète

## Limitations connues

- Certaines opérations nécessitent des droits administrateur pour une exclusion complète
- La configuration doit être refaite si AVG est mis à jour ou réinstallé
- Les exclusions sont spécifiques à l'emplacement du projet (chemin absolu)

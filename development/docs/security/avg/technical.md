# Documentation Technique des Scripts d'Exclusion AVG

Ce document détaille le fonctionnement technique des scripts d'exclusion AVG développés pour résoudre les problèmes de blocage des fichiers `.exe` pendant le développement.

## auto-avg-exclusion.ps1

Script principal qui configure les exclusions AVG pour les dossiers et extensions critiques.

### Fonctionnalités

- Détection automatique d'AVG
- Configuration des exclusions pour les dossiers critiques
- Configuration des exclusions pour les extensions critiques
- Création de marqueurs d'exclusion
- Journalisation des actions

### Paramètres

```powershell
param(
   [switch]$Silent = $false,  # Mode silencieux (sans sortie console)
   [switch]$Force = $false    # Mode forcé (pour surveillance continue)
)
```

### Variables clés

```powershell
# Liste des dossiers critiques
$criticalFolders = @(
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",
   "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\cmd",
   # ...autres dossiers...
)

# Extensions critiques à exclure
$criticalExtensions = @(
   ".exe", ".go", ".mod", ".sum", ".dll", ".a", ".obj",
   # ...autres extensions...
)

# Patterns spécifiques pour les fichiers .exe
$exePatterns = @(
   "*go-build*.exe", "*backup-qdrant.exe",
   # ...autres patterns...
)
```

### Fonctions principales

- `Test-AVGInstalled` : Vérifie si AVG est installé et actif
- `Add-AVGExclusions` : Configure les exclusions automatiques
- `New-ManualConfigScript` : Crée un script de configuration manuelle
- `Start-CompilationMonitoring` : Surveille les processus de compilation

### Mode d'exécution

1. Détecte la présence d'AVG
2. Crée des marqueurs d'exclusion dans les dossiers critiques
3. Crée des fichiers factices pour les patterns spécifiques
4. Génère un script de configuration manuelle si nécessaire
5. Surveille en continu les processus de compilation si demandé

## ensure-exe-exclusion.ps1

Script spécifique focalisé sur l'exclusion des fichiers `.exe`.

### Fonctionnalités

- Focus spécifique sur les fichiers `.exe`
- Création de marqueurs d'exclusion spécifiques
- Génération d'un script de configuration manuelle spécifique

### Paramètres

```powershell
param(
   [switch]$Silent = $false,  # Mode silencieux
   [switch]$Force = $false    # Mode forcé
)
```

### Dossiers critiques spécifiques

```powershell
$criticalFolders = @(
   "$ProjectPath",
   "$ProjectPath\cmd",
   "$ProjectPath\tools",
   "$ProjectPath\bin",
   # ...autres dossiers...
)
```

### Fonctions principales

- `Test-AVGInstalled` : Vérifie si AVG est installé et actif
- `New-ExeExclusionScript` : Crée un script d'instructions spécifiques pour les fichiers `.exe`

### Mode d'exécution

1. Vérifie la présence d'AVG
2. Crée des marqueurs spécifiques pour les fichiers `.exe` dans les dossiers critiques
3. Génère un script de configuration manuelle spécifique aux fichiers `.exe`

## avg-exclusion-vscode-hook.ps1

Script wrapper qui s'exécute automatiquement à l'ouverture de VS Code.

### Fonctionnalités

- Interface entre VS Code et les scripts d'exclusion
- Gestion des processus en arrière-plan
- Différents modes d'exécution (auto, start, stop, status, monitor)
- Journalisation silencieuse

### Paramètres

```powershell
param(
   [string]$Action = "auto",   # Action à exécuter
   [switch]$Background = $false, # Exécution en arrière-plan
   [string]$Profile = "development" # Profil de configuration
)
```

### Actions disponibles

- `auto` : Démarrage automatique ou vérification d'un processus existant
- `start` : Démarrage forcé d'un nouveau processus
- `stop` : Arrêt des processus en cours
- `status` : Vérification de l'état actuel
- `monitor` : Mode surveillance interactive

### Fonctions principales

- `Start-BackgroundScript` : Démarre les scripts en arrière-plan
- `Start-SyncScript` : Exécute les scripts en mode synchrone
- `Get-ExistingProcesses` : Vérifie les processus déjà en cours

### Mode d'exécution

1. Selon l'action demandée :
   - Vérifie si un processus existe déjà (`auto`)
   - Lance un nouveau processus (`start`)
   - Arrête les processus existants (`stop`)
   - Affiche des informations sur l'état (`status`)
   - Lance la surveillance interactive (`monitor`)
2. Lance également le script d'exclusion spécifique pour les fichiers `.exe`

## test-avg-exe-exclusion.ps1

Script de test vérifiant que les exclusions fonctionnent correctement.

### Fonctionnalités

- Vérification des marqueurs d'exclusion
- Compilation d'un fichier Go en exécutable `.exe`
- Exécution de l'exécutable généré
- Génération d'un rapport de test

### Mode d'exécution

1. Vérifie si les marqueurs d'exclusion existent
2. Crée un fichier Go de test simple
3. Compile le fichier en un exécutable `.exe`
4. Exécute l'exécutable généré
5. Vérifie que l'exécution a réussi en cherchant un fichier de succès
6. Génère un rapport de test dans `logs/avg-exe-exclusion-success.txt`

## Intégration avec VS Code

### Configuration des tâches (tasks.json)

```json
{
  "tasks": [
    {
      "label": "avg-exclusion.auto-start",
      "type": "shell",
      "command": "pwsh",
      "args": [
        "-File", 
        "${workspaceFolder}/scripts/avg-exclusion-vscode-hook.ps1",
        "auto",
        "-Background"
      ],
      "isBackground": true,
      "runOptions": {
        "runOn": "folderOpen"
      }
    },
    // ...autres tâches...
  ]
}
```

### Configuration du démarrage automatique (settings.json)

```json
{
  "terminal.integrated.profiles.windows": {
    "PowerShell": {
      "source": "PowerShell",
      "icon": "terminal-powershell",
      "args": ["-ExecutionPolicy", "Bypass"]
    }
  },
  "tasks.runOn": {
    "folderOpen": ["avg-exclusion.auto-start"]
  },
  // ...autres configurations...
}
```

## Bonnes pratiques et recommandations

### Optimisations

1. **Performances** : Les scripts sont optimisés pour minimiser l'impact sur les performances du système
2. **Mémoire** : Minimisation de l'utilisation de la mémoire en arrière-plan
3. **Mode silencieux** : Exécution invisible pour ne pas perturber l'utilisateur

### Sécurité

1. **Isolation** : Les scripts opèrent uniquement sur les dossiers spécifiques du projet
2. **Droits** : Demande de privilèges administrateur uniquement si nécessaire
3. **Logging** : Journalisation détaillée pour le diagnostic et l'audit

### Maintenance

Pour maintenir le système d'exclusion efficace :

1. Mettre à jour les listes de dossiers si la structure du projet change
2. Ajouter de nouveaux patterns de fichiers `.exe` si nécessaire
3. Vérifier périodiquement que les exclusions fonctionnent avec `avg-exclusion.test-exe`

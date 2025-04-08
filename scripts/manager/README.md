# Script Manager

Script Manager est un système proactif pour gérer, analyser et organiser les scripts du projet.

## Fonctionnalités

- **Inventaire** : Scanner récursivement les répertoires pour trouver tous les scripts
- **Analyse** : Analyser le contenu, les dépendances et les fonctionnalités des scripts
- **Cartographie** : Créer une cartographie des relations entre scripts
- **Organisation** : Classer intelligemment les scripts selon leur usage
- **Documentation** : Générer automatiquement la documentation des scripts
- **Surveillance** : Détecter les nouveaux scripts et les modifications
- **Optimisation** : Identifier les anti-patterns, proposer des améliorations et assister dans le refactoring

## Structure

```
scripts/manager/
├── ScriptManager.ps1         # Script principal
├── modules/                  # Modules PowerShell
│   ├── Inventory.psm1        # Module d'inventaire
│   ├── Database.psm1         # Module de base de données
│   ├── CLI.psm1              # Module d'interface en ligne de commande
│   ├── Analysis.psm1         # Module d'analyse
│   ├── Mapping.psm1          # Module de cartographie
│   ├── Organization.psm1     # Module d'organisation
│   ├── Documentation.psm1    # Module de documentation
│   ├── Monitoring.psm1       # Module de surveillance
│   └── Optimization/         # Module d'optimisation
│       ├── OptimizationModule.psm1  # Module principal d'optimisation
│       ├── SuggestionEngine.psm1    # Moteur de suggestions
│       ├── CodeLearning.psm1        # Apprentissage des modèles de code
│       ├── RefactoringAssistant.psm1 # Assistant de refactoring
│       └── AntiPatternDetector.psm1  # Détecteur d'anti-patterns
├── config/                   # Fichiers de configuration
│   ├── categories.json       # Définition des catégories
│   ├── patterns.json         # Patterns de reconnaissance
│   └── rules.json            # Règles d'organisation
└── data/                     # Données générées
    ├── inventory.json        # Base de données des scripts
    ├── analysis.json         # Résultats d'analyse
    ├── mapping.json          # Cartographie des scripts
    ├── metrics.json          # Métriques d'utilisation
    └── ScriptManager.log     # Journal d'activité
```

## Utilisation

### Optimisation des scripts

```powershell
.\Start-ScriptOptimization.ps1 -AnalysisPath "data\analysis.json" -OutputPath "optimization"
```

Cette commande exécute l'optimisation des scripts en mode suggestion.

Options :
- `-AnalysisPath` : Chemin vers le fichier d'analyse JSON
- `-OutputPath` : Chemin où enregistrer les résultats de l'optimisation
- `-LearningEnabled` : Active l'apprentissage des modèles de code
- `-RefactoringMode` : Mode de refactoring (Suggestion, Interactive, Automatic)

### Inventaire des scripts

```powershell
.\ScriptManager.ps1 -Action inventory
```

Cette commande scanne récursivement tous les répertoires à partir du répertoire courant et génère un inventaire des scripts trouvés.

Options :
- `-Target` : Spécifie le répertoire à scanner (par défaut : répertoire courant)
- `-Verbose` : Affiche des informations détaillées pendant l'exécution

### Analyse des scripts

```powershell
.\ScriptManager.ps1 -Action analyze
```

Cette commande analyse les scripts inventoriés pour détecter les dépendances, les problèmes potentiels, etc.

### Organisation des scripts

```powershell
.\ScriptManager.ps1 -Action organize -AutoApply
```

Cette commande organise les scripts selon les règles définies dans le fichier de configuration.

Options :
- `-AutoApply` : Applique automatiquement les recommandations d'organisation

### Documentation des scripts

```powershell
.\ScriptManager.ps1 -Action document -Format Markdown
```

Cette commande génère la documentation des scripts au format spécifié.

Options :
- `-Format` : Format de sortie (JSON, Markdown, HTML)

## Principes de développement

Le Script Manager suit les principes suivants :

- **SOLID** : Chaque module a une responsabilité unique et bien définie
- **DRY** (Don't Repeat Yourself) : Évite la duplication de code
- **KISS** (Keep It Simple, Stupid) : Privilégie les solutions simples et compréhensibles
- **Clean Code** : Code lisible, bien commenté et facile à maintenir

## Roadmap de développement

1. **Phase 1** : Fondations du Script Manager
   - Module d'inventaire des scripts
   - Base de données de scripts
   - Interface en ligne de commande basique

2. **Phase 2** : Analyse et organisation
   - Module d'analyse de scripts
   - Module d'organisation
   - Règles de classification automatique

3. **Phase 3** : Documentation et surveillance
   - Module de documentation
   - Module de surveillance
   - Intégration avec Git

4. **Phase 4** : Optimisation et intelligence
   - Module d'optimisation
   - Détection des anti-patterns
   - Suggestions d'amélioration automatiques
   - Apprentissage des modèles de code
   - Refactoring assisté

5. **Phase 5** : Intégration et déploiement
   - Intégration avec les outils existants
   - Documentation complète
   - Déploiement automatique

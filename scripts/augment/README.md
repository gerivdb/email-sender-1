# Gestionnaire de MEMORIES pour Augment

Ce dossier contient des scripts et modules pour améliorer l'autonomie, la proactivité et la granularité des réponses d'Augment en optimisant ses MEMORIES.

## Fonctionnalités principales

1. **Automate d'état pour la roadmap** : Permet à Augment de progresser automatiquement dans la roadmap sans demandes de confirmation.
2. **Segmentation proactive des inputs** : Divise automatiquement les inputs volumineux pour éviter les erreurs "too large of an input".
3. **Optimisation des MEMORIES** : Restructure les MEMORIES pour améliorer l'efficacité d'Augment.
4. **Intégration avec VS Code** : Exporte les MEMORIES optimisées vers l'emplacement utilisé par l'extension Augment dans VS Code.

## Fichiers inclus

- `AugmentMemoriesManager.ps1` : Module PowerShell contenant les fonctions principales.
- `Update-AugmentMemories.ps1` : Script pour mettre à jour les MEMORIES d'Augment.
- `Install-AugmentMemoriesModule.ps1` : Script pour installer le module dans le dossier des modules PowerShell.
- `augment_memories.json` : Exemple de fichier de MEMORIES optimisées.

## Installation

Pour installer le module, exécutez :

```powershell
.\Install-AugmentMemoriesModule.ps1
```

Cela copiera le module dans votre dossier de modules PowerShell et exécutera les tests pour vérifier son bon fonctionnement.

## Utilisation

### Mettre à jour les MEMORIES d'Augment

Pour générer et mettre à jour les MEMORIES d'Augment :

```powershell
# Générer dans le dossier courant
.\Update-AugmentMemories.ps1

# Générer dans un emplacement spécifique
.\Update-AugmentMemories.ps1 -OutputPath "C:\chemin\vers\memories.json"

# Exporter directement vers VS Code
.\Update-AugmentMemories.ps1 -ExportToVSCode
```

### Utiliser les fonctions du module

Après avoir importé le module, vous pouvez utiliser les fonctions suivantes :

```powershell
# Importer le module
Import-Module AugmentMemoriesManager

# Utiliser l'automate d'état pour la roadmap
$state = @{ CurrentTask = "T1"; Status = "Completed"; Roadmap = @("T1", "T2", "T3") }
$newState = Move-NextTask -State $state
# $newState.CurrentTask sera "T2"

# Diviser un input volumineux
$input = "Texte très long..."
$segments = Split-LargeInput -Input $input -MaxSize 2000

# Mettre à jour les MEMORIES
Update-AugmentMemories -OutputPath "C:\chemin\vers\memories.json"

# Exporter vers VS Code
Export-MemoriesToVSCode
```

## Tests

Le module inclut des tests TDD pour vérifier le bon fonctionnement des fonctions. Pour exécuter les tests :

```powershell
# Via le script d'installation
.\Install-AugmentMemoriesModule.ps1

# Via le script de mise à jour
.\Update-AugmentMemories.ps1 -RunTests

# Directement via le module
Import-Module AugmentMemoriesManager
Invoke-MemoriesManagerTests
```

## Structure des MEMORIES optimisées

Les MEMORIES optimisées sont structurées en sections :

1. **Approche méthodologique** : Décomposition des tâches, extraction de patterns, exploration, etc.
2. **Standards techniques** : SOLID, TDD, mesures, documentation, validation.
3. **Optimisation d'inputs** : Prévalidation, segmentation, compression, prévention.
4. **Autonomie d'exécution** : Progression, décision, résilience, estimation, reprise.
5. **Communication optimisée** : Format, synthèse, métadonnées, langage, feedback.
6. **Exécution PowerShell** : Verbes, taille, structure, modularité, optimisation.
7. **Optimisation IA** : One-shot, progression, métrique, adaptation, fractionnement.
8. **Méta-optimisation** : Apprentissage, auto-évaluation, anticipation, résilience, journalisation.
9. **Gestion des erreurs** : Prévention, segmentation réactive, journalisation, stratégie de repli, continuité.

## Taille des MEMORIES

Les MEMORIES générées sont optimisées pour rester sous la limite de 4 Ko, garantissant une marge de sécurité par rapport à la limite stricte de 5 Ko.

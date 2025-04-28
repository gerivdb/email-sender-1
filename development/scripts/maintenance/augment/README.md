# Gestionnaire de MEMORIES pour Augment

Ce dossier contient des scripts et modules pour amÃ©liorer l'autonomie, la proactivitÃ© et la granularitÃ© des rÃ©ponses d'Augment en optimisant ses MEMORIES.

## FonctionnalitÃ©s principales

1. **Automate d'Ã©tat pour la roadmap** : Permet Ã  Augment de progresser automatiquement dans la roadmap sans demandes de confirmation.
2. **Segmentation proactive des inputs** : Divise automatiquement les inputs volumineux pour Ã©viter les erreurs "too large of an input".
3. **Optimisation des MEMORIES** : Restructure les MEMORIES pour amÃ©liorer l'efficacitÃ© d'Augment.
4. **IntÃ©gration avec VS Code** : Exporte les MEMORIES optimisÃ©es vers l'emplacement utilisÃ© par l'extension Augment dans VS Code.

## Fichiers inclus

- `AugmentMemoriesManager.ps1` : Module PowerShell contenant les fonctions principales.
- `Update-AugmentMemories.ps1` : Script pour mettre Ã  jour les MEMORIES d'Augment.
- `Install-AugmentMemoriesModule.ps1` : Script pour installer le module dans le dossier des modules PowerShell.
- `augment_memories.json` : Exemple de fichier de MEMORIES optimisÃ©es.

## Installation

Pour installer le module, exÃ©cutez :

```powershell
.\Install-AugmentMemoriesModule.ps1
```

Cela copiera le module dans votre dossier de modules PowerShell et exÃ©cutera les tests pour vÃ©rifier son bon fonctionnement.

## Utilisation

### Mettre Ã  jour les MEMORIES d'Augment

Pour gÃ©nÃ©rer et mettre Ã  jour les MEMORIES d'Augment :

```powershell
# GÃ©nÃ©rer dans le dossier courant
.\Update-AugmentMemories.ps1

# GÃ©nÃ©rer dans un emplacement spÃ©cifique
.\Update-AugmentMemories.ps1 -OutputPath "C:\chemin\vers\memories.json"

# Exporter directement vers VS Code
.\Update-AugmentMemories.ps1 -ExportToVSCode
```

### Utiliser les fonctions du module

AprÃ¨s avoir importÃ© le module, vous pouvez utiliser les fonctions suivantes :

```powershell
# Importer le module
Import-Module AugmentMemoriesManager

# Utiliser l'automate d'Ã©tat pour la roadmap
$state = @{ CurrentTask = "T1"; Status = "Completed"; Roadmap = @("T1", "T2", "T3") }
$newState = Move-NextTask -State $state
# $newState.CurrentTask sera "T2"

# Diviser un input volumineux
$input = "Texte trÃ¨s long..."
$segments = Split-LargeInput -Input $input -MaxSize 2000

# Mettre Ã  jour les MEMORIES
Update-AugmentMemories -OutputPath "C:\chemin\vers\memories.json"

# Exporter vers VS Code
Export-MemoriesToVSCode
```

## Tests

Le module inclut des tests TDD pour vÃ©rifier le bon fonctionnement des fonctions. Pour exÃ©cuter les tests :

```powershell
# Via le script d'installation
.\Install-AugmentMemoriesModule.ps1

# Via le script de mise Ã  jour
.\Update-AugmentMemories.ps1 -RunTests

# Directement via le module
Import-Module AugmentMemoriesManager
Invoke-MemoriesManagerTests
```

## Structure des MEMORIES optimisÃ©es

Les MEMORIES optimisÃ©es sont structurÃ©es en sections :

1. **Approche mÃ©thodologique** : DÃ©composition des tÃ¢ches, extraction de patterns, exploration, etc.
2. **Standards techniques** : SOLID, TDD, mesures, documentation, validation.
3. **Optimisation d'inputs** : PrÃ©validation, segmentation, compression, prÃ©vention.
4. **Autonomie d'exÃ©cution** : Progression, dÃ©cision, rÃ©silience, estimation, reprise.
5. **Communication optimisÃ©e** : Format, synthÃ¨se, mÃ©tadonnÃ©es, langage, feedback.
6. **ExÃ©cution PowerShell** : Verbes, taille, structure, modularitÃ©, optimisation.
7. **Optimisation IA** : One-shot, progression, mÃ©trique, adaptation, fractionnement.
8. **MÃ©ta-optimisation** : Apprentissage, auto-Ã©valuation, anticipation, rÃ©silience, journalisation.
9. **Gestion des erreurs** : PrÃ©vention, segmentation rÃ©active, journalisation, stratÃ©gie de repli, continuitÃ©.

## Taille des MEMORIES

Les MEMORIES gÃ©nÃ©rÃ©es sont optimisÃ©es pour rester sous la limite de 4 Ko, garantissant une marge de sÃ©curitÃ© par rapport Ã  la limite stricte de 5 Ko.

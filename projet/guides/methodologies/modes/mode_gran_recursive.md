# Mode GRAN Récursif

## Description
Le mode GRAN Récursif est une extension du mode GRAN standard qui permet de granulariser automatiquement une tâche et toutes ses sous-tâches en une seule opération. Il analyse la complexité de chaque tâche et adapte le niveau de granularité en fonction de cette complexité et du domaine technique concerné.

## Objectif
L'objectif principal du mode GRAN Récursif est d'éviter d'avoir à exécuter plusieurs fois le mode GRAN pour granulariser une hiérarchie complète de tâches. Il permet de décomposer automatiquement une tâche complexe en sous-tâches, puis de décomposer ces sous-tâches en sous-sous-tâches, et ainsi de suite jusqu'à une profondeur spécifiée.

## Fonctionnalités
- Décomposition récursive des tâches complexes en sous-tâches
- Analyse automatique de la complexité de chaque tâche et sous-tâche
- Adaptation du niveau de granularité en fonction de la complexité détectée
- Détection automatique du domaine technique des tâches
- Contrôle de la profondeur de récursion
- Support pour l'estimation de temps
- Intégration avec l'IA pour la génération de sous-tâches

## Utilisation

```powershell
# Granulariser récursivement une tâche avec détection automatique de la complexité
.\development\scripts\maintenance\modes\gran-mode-recursive.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3"

# Granulariser récursivement avec une profondeur spécifique (par défaut: 2)
.\development\scripts\maintenance\modes\gran-mode-recursive.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -RecursionDepth 3

# Granulariser récursivement avec analyse de complexité pour chaque sous-tâche
.\development\scripts\maintenance\modes\gran-mode-recursive.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -AnalyzeComplexity

# Granulariser récursivement avec un domaine spécifique
.\development\scripts\maintenance\modes\gran-mode-recursive.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -Domain "Backend"

# Granulariser récursivement avec estimation de temps
.\development\scripts\maintenance\modes\gran-mode-recursive.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -AddTimeEstimation

# Granulariser récursivement avec génération par IA
.\development\scripts\maintenance\modes\gran-mode-recursive.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -UseAI
```

## Paramètres

| Paramètre | Type | Description |
|-----------|------|-------------|
| `FilePath` | string | Chemin vers le fichier de roadmap à modifier |
| `TaskIdentifier` | string | Identifiant de la tâche à granulariser (ex: "1.2.3") |
| `ComplexityLevel` | string | Niveau de complexité à utiliser (Auto, Simple, Medium, Complex, VeryComplex) |
| `Domain` | string | Domaine technique de la tâche (ex: Frontend, Backend, Database) |
| `SubTasksFile` | string | Chemin vers un fichier contenant des sous-tâches personnalisées |
| `AddTimeEstimation` | switch | Ajouter des estimations de temps aux sous-tâches |
| `UseAI` | switch | Utiliser l'IA pour générer les sous-tâches |
| `SimulateAI` | switch | Simuler l'utilisation de l'IA (pour les tests) |
| `IndentationStyle` | string | Style d'indentation à utiliser (Auto, Spaces, Tabs) |
| `CheckboxStyle` | string | Style de case à cocher à utiliser (Auto, Dash, Asterisk) |
| `RecursionDepth` | int | Profondeur maximale de récursion (par défaut: 2) |
| `AnalyzeComplexity` | switch | Analyser la complexité de chaque sous-tâche individuellement |

## Analyse de complexité

Le mode GRAN Récursif peut analyser automatiquement la complexité de chaque tâche et sous-tâche en fonction de son contenu. Cette analyse se base sur plusieurs facteurs :

1. **Mots-clés** : Présence de mots-clés indiquant une complexité élevée, moyenne ou faible
2. **Longueur du titre** : Les titres plus longs tendent à indiquer des tâches plus complexes
3. **Domaine technique** : Certains domaines sont intrinsèquement plus complexes que d'autres

L'analyse de complexité permet d'adapter automatiquement le niveau de granularité pour chaque tâche et sous-tâche, ce qui évite d'avoir à spécifier manuellement la complexité pour chaque niveau.

### Niveaux de complexité

- **Simple** : Tâches simples, généralement décomposées en 3-5 sous-tâches
- **Medium** : Tâches de complexité moyenne, généralement décomposées en 5-7 sous-tâches
- **Complex** : Tâches complexes, généralement décomposées en 7-10 sous-tâches
- **VeryComplex** : Tâches très complexes, généralement décomposées en 10-15 sous-tâches

## Contrôle de la profondeur

Le paramètre `RecursionDepth` permet de contrôler la profondeur maximale de récursion. Par défaut, la profondeur est fixée à 2, ce qui signifie que le script granularisera la tâche principale et ses sous-tâches directes.

- `RecursionDepth = 1` : Granularise uniquement la tâche principale
- `RecursionDepth = 2` : Granularise la tâche principale et ses sous-tâches directes
- `RecursionDepth = 3` : Granularise la tâche principale, ses sous-tâches directes et les sous-sous-tâches
- Et ainsi de suite...

## Exemples

### Exemple 1 : Granularisation récursive simple

```powershell
.\development\scripts\maintenance\modes\gran-mode-recursive.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3"
```

Cette commande va :
1. Granulariser la tâche 1.2.3 en fonction de sa complexité détectée
2. Granulariser chaque sous-tâche générée en fonction de la même complexité
3. S'arrêter après avoir granularisé les sous-tâches (profondeur 2)

### Exemple 2 : Granularisation récursive avec analyse de complexité

```powershell
.\development\scripts\maintenance\modes\gran-mode-recursive.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -AnalyzeComplexity
```

Cette commande va :
1. Granulariser la tâche 1.2.3 en fonction de sa complexité détectée
2. Analyser la complexité de chaque sous-tâche générée
3. Granulariser chaque sous-tâche en fonction de sa complexité spécifique
4. S'arrêter après avoir granularisé les sous-tâches (profondeur 2)

### Exemple 3 : Granularisation récursive profonde

```powershell
.\development\scripts\maintenance\modes\gran-mode-recursive.ps1 -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -RecursionDepth 3 -AnalyzeComplexity
```

Cette commande va :
1. Granulariser la tâche 1.2.3 en fonction de sa complexité détectée
2. Analyser la complexité de chaque sous-tâche générée
3. Granulariser chaque sous-tâche en fonction de sa complexité spécifique
4. Analyser la complexité de chaque sous-sous-tâche générée
5. Granulariser chaque sous-sous-tâche en fonction de sa complexité spécifique
6. S'arrêter après avoir granularisé les sous-sous-tâches (profondeur 3)

## Bonnes pratiques

- Commencer avec une profondeur de récursion de 2 pour éviter une granularisation excessive
- Utiliser l'option `-AnalyzeComplexity` pour adapter la granularisation à chaque niveau
- Vérifier le résultat après la granularisation et ajuster manuellement si nécessaire
- Pour les tâches très complexes, envisager d'utiliser l'option `-UseAI` pour générer des sous-tâches plus pertinentes
- Combiner avec l'option `-AddTimeEstimation` pour obtenir des estimations de temps à tous les niveaux

## Intégration avec le mode-manager

Le mode GRAN Récursif peut être intégré au mode-manager en ajoutant une entrée dans le fichier de configuration du mode-manager :

```json
{
  "modes": {
    "GRAN-R": {
      "script": "development\\scripts\\maintenance\\modes\\gran-mode-recursive.ps1",
      "description": "Mode de granularisation récursive des tâches",
      "parameters": {
        "FilePath": {
          "required": true,
          "description": "Chemin vers le fichier de roadmap"
        },
        "TaskIdentifier": {
          "required": true,
          "description": "Identifiant de la tâche à granulariser"
        },
        "RecursionDepth": {
          "required": false,
          "default": 2,
          "description": "Profondeur maximale de récursion"
        },
        "AnalyzeComplexity": {
          "required": false,
          "default": false,
          "description": "Analyser la complexité de chaque sous-tâche"
        }
      }
    }
  }
}
```

Vous pourrez alors utiliser le mode GRAN Récursif via le mode-manager :

```powershell
.\development\scripts\mode-manager\mode-manager.ps1 -Mode GRAN-R -FilePath "projet\roadmaps\active\roadmap_active.md" -TaskIdentifier "1.2.3" -RecursionDepth 3 -AnalyzeComplexity
```

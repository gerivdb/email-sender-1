# Mode C-BREAK

## Description
Le mode C-BREAK (Cycle Breaker) est un mode opérationnel qui se concentre sur la détection et la résolution des dépendances circulaires dans le code et les workflows.

## Objectif
L'objectif principal du mode C-BREAK est d'identifier et d'éliminer les dépendances circulaires qui peuvent causer des problèmes de performance, de maintenabilité et de stabilité.

## Fonctionnalités
- Détection de dépendances circulaires
- Analyse de graphe de dépendances
- Suggestion de refactoring
- Validation de workflows
- Résolution automatique de cycles

## Utilisation

```powershell
# Détecter les dépendances circulaires dans un dossier
.\c-break-mode.ps1 -FolderPath "src" -DetectCycles

# Analyser un workflow spécifique
.\c-break-mode.ps1 -WorkflowPath "src/workflows/main.json" -ValidateWorkflow

# Suggérer des solutions pour résoudre les cycles
.\c-break-mode.ps1 -FolderPath "src" -DetectCycles -SuggestSolutions
```

## Types de dépendances circulaires
Le mode C-BREAK peut détecter différents types de dépendances circulaires :
- **Dépendances de code** : Modules ou classes qui dépendent mutuellement
- **Dépendances d'import** : Fichiers qui s'importent mutuellement
- **Dépendances de workflow** : Étapes de workflow qui créent des boucles
- **Dépendances de données** : Structures de données qui se référencent mutuellement

## Intégration avec d'autres modes
Le mode C-BREAK peut être utilisé en combinaison avec d'autres modes :
- **ARCHI** : Pour concevoir une architecture sans dépendances circulaires
- **REVIEW** : Pour vérifier l'absence de dépendances circulaires
- **OPTI** : Pour optimiser le code en éliminant les dépendances circulaires

## Implémentation
Le mode C-BREAK est implémenté dans le script `c-break-mode.ps1` qui se trouve dans le dossier `tools/scripts/roadmap/modes/c-break`.

## Exemple de rapport de dépendances circulaires
```
Rapport de dépendances circulaires :
- Cycles détectés : 3

Cycle 1 :
  ModuleA -> ModuleB -> ModuleC -> ModuleA
  Suggestion : Extraire les fonctionnalités communes dans un nouveau module

Cycle 2 :
  FileX.ps1 -> FileY.ps1 -> FileZ.ps1 -> FileX.ps1
  Suggestion : Utiliser l'injection de dépendances

Cycle 3 :
  WorkflowStep1 -> WorkflowStep2 -> WorkflowStep3 -> WorkflowStep1
  Suggestion : Restructurer le workflow en phases séquentielles
```

## Bonnes pratiques
- Détecter les dépendances circulaires tôt dans le processus de développement
- Utiliser des patterns comme l'injection de dépendances pour éviter les cycles
- Concevoir une architecture en couches pour minimiser les dépendances
- Tester les modifications après avoir résolu les cycles
- Documenter les décisions de conception pour éviter la réintroduction de cycles
- Utiliser des outils d'analyse statique pour détecter les cycles automatiquement

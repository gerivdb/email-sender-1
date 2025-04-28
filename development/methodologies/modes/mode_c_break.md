# Mode C-BREAK

## Description
Le mode C-BREAK (Cycle Breaker) est un mode opÃ©rationnel qui se concentre sur la dÃ©tection et la rÃ©solution des dÃ©pendances circulaires dans le code et les workflows.

## Objectif
L'objectif principal du mode C-BREAK est d'identifier et d'Ã©liminer les dÃ©pendances circulaires qui peuvent causer des problÃ¨mes de performance, de maintenabilitÃ© et de stabilitÃ©.

## FonctionnalitÃ©s
- DÃ©tection de dÃ©pendances circulaires
- Analyse de graphe de dÃ©pendances
- Suggestion de refactoring
- Validation de workflows
- RÃ©solution automatique de cycles

## Utilisation

```powershell
# DÃ©tecter les dÃ©pendances circulaires dans un dossier
.\c-break-mode.ps1 -FolderPath "src" -DetectCycles

# Analyser un workflow spÃ©cifique
.\c-break-mode.ps1 -WorkflowPath "src/workflows/main.json" -ValidateWorkflow

# SuggÃ©rer des solutions pour rÃ©soudre les cycles
.\c-break-mode.ps1 -FolderPath "src" -DetectCycles -SuggestSolutions
```

## Types de dÃ©pendances circulaires
Le mode C-BREAK peut dÃ©tecter diffÃ©rents types de dÃ©pendances circulaires :
- **DÃ©pendances de code** : Modules ou classes qui dÃ©pendent mutuellement
- **DÃ©pendances d'import** : Fichiers qui s'importent mutuellement
- **DÃ©pendances de workflow** : Ã‰tapes de workflow qui crÃ©ent des boucles
- **DÃ©pendances de donnÃ©es** : Structures de donnÃ©es qui se rÃ©fÃ©rencent mutuellement

## IntÃ©gration avec d'autres modes
Le mode C-BREAK peut Ãªtre utilisÃ© en combinaison avec d'autres modes :
- **ARCHI** : Pour concevoir une architecture sans dÃ©pendances circulaires
- **REVIEW** : Pour vÃ©rifier l'absence de dÃ©pendances circulaires
- **OPTI** : Pour optimiser le code en Ã©liminant les dÃ©pendances circulaires

## ImplÃ©mentation
Le mode C-BREAK est implÃ©mentÃ© dans le script `c-break-mode.ps1` qui se trouve dans le dossier `development/tools/development/roadmap/scripts/modes/c-break`.

## Exemple de rapport de dÃ©pendances circulaires
```
Rapport de dÃ©pendances circulaires :
- Cycles dÃ©tectÃ©s : 3

Cycle 1 :
  ModuleA -> ModuleB -> ModuleC -> ModuleA
  Suggestion : Extraire les fonctionnalitÃ©s communes dans un nouveau module

Cycle 2 :
  FileX.ps1 -> FileY.ps1 -> FileZ.ps1 -> FileX.ps1
  Suggestion : Utiliser l'injection de dÃ©pendances

Cycle 3 :
  WorkflowStep1 -> WorkflowStep2 -> WorkflowStep3 -> WorkflowStep1
  Suggestion : Restructurer le workflow en phases sÃ©quentielles
```

## Bonnes pratiques
- DÃ©tecter les dÃ©pendances circulaires tÃ´t dans le processus de dÃ©veloppement
- Utiliser des patterns comme l'injection de dÃ©pendances pour Ã©viter les cycles
- Concevoir une architecture en couches pour minimiser les dÃ©pendances
- Tester les modifications aprÃ¨s avoir rÃ©solu les cycles
- Documenter les dÃ©cisions de conception pour Ã©viter la rÃ©introduction de cycles
- Utiliser des outils d'analyse statique pour dÃ©tecter les cycles automatiquement


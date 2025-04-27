# Mode GRAN

## Description
Le mode GRAN (Granularisation) est un mode opÃ©rationnel qui dÃ©compose les tÃ¢ches complexes en sous-tÃ¢ches plus petites et plus faciles Ã  gÃ©rer.

## Objectif
L'objectif principal du mode GRAN est de faciliter la gestion de tÃ¢ches complexes en les dÃ©composant en unitÃ©s de travail plus petites, plus prÃ©cises et plus faciles Ã  estimer.

## FonctionnalitÃ©s
- DÃ©composition des tÃ¢ches complexes en sous-tÃ¢ches
- Ajout automatique de sous-tÃ¢ches Ã  partir de modÃ¨les
- Mise Ã  jour de la roadmap avec les nouvelles sous-tÃ¢ches
- Estimation automatique de la complexitÃ© des sous-tÃ¢ches

## Utilisation

```powershell
# Granulariser une tÃ¢che spÃ©cifique
.\gran-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3"

# Granulariser une tÃ¢che avec un modÃ¨le de sous-tÃ¢ches
.\gran-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3" -SubTasksFile "templates/subtasks.txt"

# Granulariser une tÃ¢che directement dans le document actif
.\gran-mode.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskId "1.2.3" -SubTasksFile "templates/subtasks.txt"
```

## ModÃ¨les de sous-tÃ¢ches
Le mode GRAN peut utiliser des modÃ¨les de sous-tÃ¢ches pour accÃ©lÃ©rer la dÃ©composition. Voici un exemple de modÃ¨le :

```
Analyser les besoins
Concevoir l'architecture
ImplÃ©menter le code
Tester la fonctionnalitÃ©
Documenter l'implÃ©mentation
```

## IntÃ©gration avec d'autres modes
Le mode GRAN peut Ãªtre utilisÃ© en combinaison avec d'autres modes :
- **DEV-R** : Pour dÃ©composer les tÃ¢ches avant de commencer le dÃ©veloppement
- **ARCHI** : Pour dÃ©composer les tÃ¢ches d'architecture en composants plus petits
- **CHECK** : Pour vÃ©rifier l'Ã©tat d'avancement des sous-tÃ¢ches

## ImplÃ©mentation
Le mode GRAN est implÃ©mentÃ© dans le script `gran-mode.ps1` qui se trouve dans le dossier `tools/scripts/roadmap/modes/gran`.

## Exemple de granularisation
Avant :
```
- [ ] **1.3** ImplÃ©menter la fonctionnalitÃ© C
```

AprÃ¨s :
```
- [ ] **1.3** ImplÃ©menter la fonctionnalitÃ© C
  - [ ] **1.3.1** Analyser les besoins
  - [ ] **1.3.2** Concevoir l'architecture
  - [ ] **1.3.3** ImplÃ©menter le code
  - [ ] **1.3.4** Tester la fonctionnalitÃ©
  - [ ] **1.3.5** Documenter l'implÃ©mentation
```

## Bonnes pratiques
- DÃ©composer les tÃ¢ches en sous-tÃ¢ches qui prennent moins d'une journÃ©e Ã  rÃ©aliser
- Utiliser des modÃ¨les de sous-tÃ¢ches pour assurer la cohÃ©rence
- Estimer la complexitÃ© de chaque sous-tÃ¢che
- Mettre Ã  jour la roadmap aprÃ¨s la granularisation
- Granulariser les tÃ¢ches juste avant de commencer Ã  les travailler

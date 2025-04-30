# Mode GRAN

## Description
Le mode GRAN (Granularisation) est un mode opérationnel qui décompose les tâches complexes en sous-tâches plus petites et plus faciles à gérer.

## Objectif
L'objectif principal du mode GRAN est de faciliter la gestion de tâches complexes en les décomposant en unités de travail plus petites, plus précises et plus faciles à estimer.

## Fonctionnalités
- Décomposition des tâches complexes en sous-tâches
- Ajout automatique de sous-tâches à partir de modèles
- Mise à jour de la roadmap avec les nouvelles sous-tâches
- Estimation automatique de la complexité des sous-tâches

## Utilisation

`powershell
# Granulariser une tâche spécifique
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath \ projet\roadmaps\roadmap_complete_converted.md\ -TaskIdentifier \1.2.3\

# Granulariser une tâche avec un modèle de sous-tâches
.\development\scripts\maintenance\modes\gran-mode.ps1 -FilePath \projet\roadmaps\roadmap_complete_converted.md\ -TaskIdentifier \1.2.3\ -SubTasksFile \templates\subtasks.txt\

# Utiliser le mode-manager pour exécuter le mode GRAN
.\development\scripts\mode-manager\mode-manager.ps1 -Mode GRAN -FilePath \projet\roadmaps\roadmap_complete_converted.md\ -TaskIdentifier \1.2.3\
`

## Modèles de sous-tâches
Le mode GRAN peut utiliser des modèles de sous-tâches pour accélérer la décomposition. Voici un exemple de modèle :

`
Analyser les besoins
Concevoir l'architecture
Implémenter le code
Tester la fonctionnalité
Documenter l'implémentation
`

## Intégration avec d'autres modes
Le mode GRAN peut être utilisé en combinaison avec d'autres modes :
- **DEV-R** : Pour décomposer les tâches avant de commencer le développement
- **ARCHI** : Pour décomposer les tâches d'architecture en composants plus petits
- **CHECK** : Pour vérifier l'état d'avancement des sous-tâches

## Implémentation
Le mode GRAN est implémenté dans le script gran-mode.ps1 qui se trouve dans le dossier development\scripts\maintenance\modes\.

## Exemple de granularisation
Avant :
`
- [ ] **1.3** Implémenter la fonctionnalité C
`

Après :
`
- [ ] **1.3** Implémenter la fonctionnalité C
  - [ ] **1.3.1** Analyser les besoins
  - [ ] **1.3.2** Concevoir l'architecture
  - [ ] **1.3.3** Implémenter le code
  - [ ] **1.3.4** Tester la fonctionnalité
  - [ ] **1.3.5** Documenter l'implémentation
`

## Bonnes pratiques
- Décomposer les tâches en sous-tâches qui prennent moins d'une journée à réaliser
- Utiliser des modèles de sous-tâches pour assurer la cohérence
- Estimer la complexité de chaque sous-tâche
- Mettre à jour la roadmap après la granularisation
- Granulariser les tâches juste avant de commencer à les travailler

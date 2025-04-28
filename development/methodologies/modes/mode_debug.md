# Mode DEBUG

## Description
Le mode DEBUG est un mode opÃ©rationnel qui aide Ã  identifier et rÃ©soudre les problÃ¨mes dans le code et les processus.

## Objectif
L'objectif principal du mode DEBUG est de faciliter la dÃ©tection, l'analyse et la rÃ©solution des bugs et des problÃ¨mes de performance.

## FonctionnalitÃ©s
- Analyse dÃ©taillÃ©e des erreurs
- TraÃ§age des exÃ©cutions
- Inspection des variables
- Analyse de performance
- GÃ©nÃ©ration de rapports de dÃ©bogage

## Utilisation

```powershell
# DÃ©boguer un script spÃ©cifique
.\debug-mode.ps1 -ScriptPath "development/tools/development/roadmap/scripts/parser.ps1" -Verbose

# DÃ©boguer une tÃ¢che spÃ©cifique
.\debug-mode.ps1 -RoadmapPath "projet/documentation/roadmap/roadmap.md" -TaskId "1.2.3" -Verbose

# Analyser les performances
.\debug-mode.ps1 -ScriptPath "development/tools/development/roadmap/scripts/parser.ps1" -PerformanceAnalysis
```

## Niveaux de dÃ©bogage
Le mode DEBUG propose plusieurs niveaux de dÃ©bogage :
- **Niveau 1** : Informations de base (erreurs, avertissements)
- **Niveau 2** : Informations dÃ©taillÃ©es (variables, appels de fonction)
- **Niveau 3** : Informations trÃ¨s dÃ©taillÃ©es (trace complÃ¨te, performance)

## IntÃ©gration avec d'autres modes
Le mode DEBUG peut Ãªtre utilisÃ© en combinaison avec d'autres modes :
- **TEST** : Pour dÃ©boguer les tests qui Ã©chouent
- **OPTI** : Pour identifier les problÃ¨mes de performance
- **DEV-R** : Pour rÃ©soudre les problÃ¨mes pendant le dÃ©veloppement

## ImplÃ©mentation
Le mode DEBUG est implÃ©mentÃ© dans le script `debug-mode.ps1` qui se trouve dans le dossier `development/tools/development/roadmap/scripts/modes/debug`.

## Exemple de rapport de dÃ©bogage
```
Rapport de dÃ©bogage :
- Erreur dÃ©tectÃ©e : Null reference exception Ã  la ligne 42
- Variable $data : null
- Appel de fonction : Get-Data -Path "invalid/path.txt"
- Trace d'appel : Main -> Process-Data -> Get-Data
- Suggestion : VÃ©rifier que le fichier "invalid/path.txt" existe
```

## Bonnes pratiques
- Utiliser le mode DEBUG dÃ¨s qu'un problÃ¨me est dÃ©tectÃ©
- Commencer par le niveau de dÃ©bogage le plus bas et augmenter si nÃ©cessaire
- Documenter les problÃ¨mes et les solutions trouvÃ©s
- Ajouter des tests pour Ã©viter que les problÃ¨mes ne se reproduisent
- Utiliser les outils d'analyse de performance pour les problÃ¨mes de performance


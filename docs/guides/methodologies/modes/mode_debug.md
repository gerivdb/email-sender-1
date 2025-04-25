# Mode DEBUG

## Description
Le mode DEBUG est un mode opérationnel qui aide à identifier et résoudre les problèmes dans le code et les processus.

## Objectif
L'objectif principal du mode DEBUG est de faciliter la détection, l'analyse et la résolution des bugs et des problèmes de performance.

## Fonctionnalités
- Analyse détaillée des erreurs
- Traçage des exécutions
- Inspection des variables
- Analyse de performance
- Génération de rapports de débogage

## Utilisation

```powershell
# Déboguer un script spécifique
.\debug-mode.ps1 -ScriptPath "tools/scripts/roadmap/parser.ps1" -Verbose

# Déboguer une tâche spécifique
.\debug-mode.ps1 -RoadmapPath "docs/roadmap/roadmap.md" -TaskId "1.2.3" -Verbose

# Analyser les performances
.\debug-mode.ps1 -ScriptPath "tools/scripts/roadmap/parser.ps1" -PerformanceAnalysis
```

## Niveaux de débogage
Le mode DEBUG propose plusieurs niveaux de débogage :
- **Niveau 1** : Informations de base (erreurs, avertissements)
- **Niveau 2** : Informations détaillées (variables, appels de fonction)
- **Niveau 3** : Informations très détaillées (trace complète, performance)

## Intégration avec d'autres modes
Le mode DEBUG peut être utilisé en combinaison avec d'autres modes :
- **TEST** : Pour déboguer les tests qui échouent
- **OPTI** : Pour identifier les problèmes de performance
- **DEV-R** : Pour résoudre les problèmes pendant le développement

## Implémentation
Le mode DEBUG est implémenté dans le script `debug-mode.ps1` qui se trouve dans le dossier `tools/scripts/roadmap/modes/debug`.

## Exemple de rapport de débogage
```
Rapport de débogage :
- Erreur détectée : Null reference exception à la ligne 42
- Variable $data : null
- Appel de fonction : Get-Data -Path "invalid/path.txt"
- Trace d'appel : Main -> Process-Data -> Get-Data
- Suggestion : Vérifier que le fichier "invalid/path.txt" existe
```

## Bonnes pratiques
- Utiliser le mode DEBUG dès qu'un problème est détecté
- Commencer par le niveau de débogage le plus bas et augmenter si nécessaire
- Documenter les problèmes et les solutions trouvés
- Ajouter des tests pour éviter que les problèmes ne se reproduisent
- Utiliser les outils d'analyse de performance pour les problèmes de performance

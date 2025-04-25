# Mode REVIEW

## Description
Le mode REVIEW est un mode opérationnel qui se concentre sur l'évaluation et l'amélioration de la qualité du code, de la documentation et des tests.

## Objectif
L'objectif principal du mode REVIEW est d'assurer que le code respecte les standards de qualité, est bien documenté et testé, et suit les bonnes pratiques.

## Fonctionnalités
- Analyse statique de code
- Vérification des standards de codage
- Évaluation de la documentation
- Vérification de la couverture des tests
- Détection des problèmes potentiels
- Génération de rapports de revue

## Utilisation

```powershell
# Analyser un script spécifique
.\review-mode.ps1 -ScriptPath "tools/scripts/roadmap/parser.ps1"

# Analyser un dossier complet
.\review-mode.ps1 -FolderPath "tools/scripts/roadmap"

# Générer un rapport de revue
.\review-mode.ps1 -FolderPath "tools/scripts/roadmap" -GenerateReport
```

## Critères de revue
Le mode REVIEW évalue le code selon plusieurs critères :
- **Qualité du code** : Complexité, lisibilité, maintenabilité
- **Standards de codage** : Respect des conventions
- **Documentation** : Commentaires, documentation API
- **Tests** : Couverture, qualité des tests
- **Sécurité** : Vulnérabilités potentielles
- **Performance** : Problèmes de performance évidents

## Intégration avec d'autres modes
Le mode REVIEW peut être utilisé en combinaison avec d'autres modes :
- **DEV-R** : Pour valider le code avant de marquer une tâche comme complète
- **OPTI** : Pour identifier les opportunités d'optimisation
- **CHECK** : Pour vérifier que le code respecte les standards avant de le valider

## Implémentation
Le mode REVIEW est implémenté dans le script `review-mode.ps1` qui se trouve dans le dossier `tools/scripts/roadmap/modes/review`.

## Exemple de rapport de revue
```
Rapport de revue :
- Fichiers analysés : 15
- Problèmes critiques : 2
- Problèmes majeurs : 5
- Problèmes mineurs : 12
- Score de qualité : 85/100

Problèmes critiques :
- parser.ps1:42 - Vulnérabilité d'injection
- parser.ps1:78 - Fuite de mémoire potentielle

Problèmes majeurs :
- parser.ps1:120 - Complexité cyclomatique trop élevée (15)
- parser.ps1:200 - Fonction trop longue (150 lignes)
- ...
```

## Bonnes pratiques
- Effectuer des revues régulières du code
- Corriger les problèmes critiques immédiatement
- Planifier la correction des problèmes majeurs
- Documenter les décisions de conception
- Utiliser des outils d'analyse statique
- Suivre les principes SOLID, DRY et KISS
- Maintenir une couverture de tests élevée

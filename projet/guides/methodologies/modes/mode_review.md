# Mode REVIEW

## Description
Le mode REVIEW est un mode opÃ©rationnel qui se concentre sur l'Ã©valuation et l'amÃ©lioration de la qualitÃ© du code, de la documentation et des tests.

## Objectif
L'objectif principal du mode REVIEW est d'assurer que le code respecte les standards de qualitÃ©, est bien documentÃ© et testÃ©, et suit les bonnes pratiques.

## FonctionnalitÃ©s
- Analyse statique de code
- VÃ©rification des standards de codage
- Ã‰valuation de la documentation
- VÃ©rification de la couverture des tests
- DÃ©tection des problÃ¨mes potentiels
- GÃ©nÃ©ration de rapports de revue

## Utilisation

```powershell
# Analyser un script spÃ©cifique
.\review-mode.ps1 -ScriptPath "tools/scripts/roadmap/parser.ps1"

# Analyser un dossier complet
.\review-mode.ps1 -FolderPath "tools/scripts/roadmap"

# GÃ©nÃ©rer un rapport de revue
.\review-mode.ps1 -FolderPath "tools/scripts/roadmap" -GenerateReport
```

## CritÃ¨res de revue
Le mode REVIEW Ã©value le code selon plusieurs critÃ¨res :
- **QualitÃ© du code** : ComplexitÃ©, lisibilitÃ©, maintenabilitÃ©
- **Standards de codage** : Respect des conventions
- **Documentation** : Commentaires, documentation API
- **Tests** : Couverture, qualitÃ© des tests
- **SÃ©curitÃ©** : VulnÃ©rabilitÃ©s potentielles
- **Performance** : ProblÃ¨mes de performance Ã©vidents

## IntÃ©gration avec d'autres modes
Le mode REVIEW peut Ãªtre utilisÃ© en combinaison avec d'autres modes :
- **DEV-R** : Pour valider le code avant de marquer une tÃ¢che comme complÃ¨te
- **OPTI** : Pour identifier les opportunitÃ©s d'optimisation
- **CHECK** : Pour vÃ©rifier que le code respecte les standards avant de le valider

## ImplÃ©mentation
Le mode REVIEW est implÃ©mentÃ© dans le script `review-mode.ps1` qui se trouve dans le dossier `tools/scripts/roadmap/modes/review`.

## Exemple de rapport de revue
```
Rapport de revue :
- Fichiers analysÃ©s : 15
- ProblÃ¨mes critiques : 2
- ProblÃ¨mes majeurs : 5
- ProblÃ¨mes mineurs : 12
- Score de qualitÃ© : 85/100

ProblÃ¨mes critiques :
- parser.ps1:42 - VulnÃ©rabilitÃ© d'injection
- parser.ps1:78 - Fuite de mÃ©moire potentielle

ProblÃ¨mes majeurs :
- parser.ps1:120 - ComplexitÃ© cyclomatique trop Ã©levÃ©e (15)
- parser.ps1:200 - Fonction trop longue (150 lignes)
- ...
```

## Bonnes pratiques
- Effectuer des revues rÃ©guliÃ¨res du code
- Corriger les problÃ¨mes critiques immÃ©diatement
- Planifier la correction des problÃ¨mes majeurs
- Documenter les dÃ©cisions de conception
- Utiliser des outils d'analyse statique
- Suivre les principes SOLID, DRY et KISS
- Maintenir une couverture de tests Ã©levÃ©e

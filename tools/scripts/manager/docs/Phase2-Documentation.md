# Phase 2 : Analyse et organisation avancÃ©es

Cette documentation dÃ©crit la Phase 2 du Script Manager, qui se concentre sur l'analyse approfondie des scripts et leur organisation intelligente selon les principes SOLID, DRY, KISS et Clean Code.

## Table des matiÃ¨res

1. [Vue d'ensemble](#vue-densemble)
2. [Modules](#modules)
   - [Module d'analyse](#module-danalyse)
   - [Module d'organisation](#module-dorganisation)
3. [FonctionnalitÃ©s](#fonctionnalitÃ©s)
   - [Analyse statique](#analyse-statique)
   - [DÃ©tection des dÃ©pendances](#dÃ©tection-des-dÃ©pendances)
   - [Analyse de la qualitÃ© du code](#analyse-de-la-qualitÃ©-du-code)
   - [DÃ©tection des problÃ¨mes](#dÃ©tection-des-problÃ¨mes)
   - [Classification des scripts](#classification-des-scripts)
   - [Organisation intelligente](#organisation-intelligente)
   - [Mise Ã  jour des rÃ©fÃ©rences](#mise-Ã -jour-des-rÃ©fÃ©rences)
4. [Utilisation](#utilisation)
5. [Tests](#tests)
6. [Bonnes pratiques](#bonnes-pratiques)

## Vue d'ensemble

La Phase 2 du Script Manager Ã©tend les fonctionnalitÃ©s de base de la Phase 1 en ajoutant des capacitÃ©s d'analyse approfondie et d'organisation intelligente. Elle permet de :

- Analyser statiquement le code des scripts pour en extraire des informations structurelles
- DÃ©tecter les dÃ©pendances entre les scripts
- Ã‰valuer la qualitÃ© du code selon plusieurs mÃ©triques
- Identifier les problÃ¨mes potentiels et proposer des solutions
- Classifier les scripts selon des rÃ¨gles dÃ©finies
- Organiser les scripts dans une structure de dossiers sÃ©mantiques
- Mettre Ã  jour les rÃ©fÃ©rences entre scripts aprÃ¨s dÃ©placement

Cette phase suit les principes SOLID, DRY, KISS et Clean Code pour offrir une solution modulaire, maintenable et extensible.

## Modules

### Module d'analyse

Le module d'analyse est responsable de l'analyse approfondie des scripts. Il est composÃ© des sous-modules suivants :

- **AnalysisModule.psm1** : Module principal qui coordonne l'analyse
- **StaticAnalyzer.psm1** : Analyse statique du code
- **DependencyDetector.psm1** : DÃ©tection des dÃ©pendances entre scripts
- **CodeQualityAnalyzer.psm1** : Ã‰valuation de la qualitÃ© du code
- **ProblemDetector.psm1** : DÃ©tection des problÃ¨mes potentiels

### Module d'organisation

Le module d'organisation est responsable de l'organisation intelligente des scripts. Il est composÃ© des sous-modules suivants :

- **OrganizationModule.psm1** : Module principal qui coordonne l'organisation
- **ClassificationEngine.psm1** : Classification des scripts selon des rÃ¨gles
- **ScriptMover.psm1** : DÃ©placement des scripts
- **ReferenceUpdater.psm1** : Mise Ã  jour des rÃ©fÃ©rences entre scripts
- **FolderStructureCreator.psm1** : CrÃ©ation de la structure de dossiers

## FonctionnalitÃ©s

### Analyse statique

L'analyse statique extrait des informations structurelles du code, telles que :

- Nombre de lignes de code
- Nombre de commentaires
- Nombre de fonctions et leurs noms
- Nombre de variables et leurs noms
- Imports et dÃ©pendances
- Structures conditionnelles et boucles
- Classes et mÃ©thodes (pour les langages orientÃ©s objet)

Cette analyse est adaptÃ©e au type de script (PowerShell, Python, Batch, Shell) et peut Ãªtre effectuÃ©e Ã  diffÃ©rents niveaux de profondeur (Basic, Standard, Advanced).

### DÃ©tection des dÃ©pendances

La dÃ©tection des dÃ©pendances identifie les relations entre les scripts, telles que :

- Imports de modules
- Sources de scripts
- Appels Ã  d'autres scripts
- ExÃ©cutions de scripts

Ces dÃ©pendances sont utilisÃ©es pour construire un graphe de dÃ©pendances et pour mettre Ã  jour les rÃ©fÃ©rences lors du dÃ©placement des scripts.

### Analyse de la qualitÃ© du code

L'analyse de la qualitÃ© du code Ã©value plusieurs mÃ©triques, telles que :

- Ratio de commentaires
- Longueur moyenne et maximale des lignes
- Ratio de lignes vides
- ComplexitÃ© du code
- Duplication de code

Ces mÃ©triques sont utilisÃ©es pour calculer un score de qualitÃ© global et pour proposer des recommandations d'amÃ©lioration.

### DÃ©tection des problÃ¨mes

La dÃ©tection des problÃ¨mes identifie les problÃ¨mes potentiels dans le code, tels que :

- Lignes trop longues
- Utilisation de chemins absolus
- Comparaisons incorrectes avec $null (PowerShell)
- Utilisation de print au lieu de logging (Python)
- Absence de @ECHO OFF (Batch)
- Absence de shebang (Shell)

Ces problÃ¨mes sont classÃ©s par type (Style, BestPractice, Portability, Encoding) et par sÃ©vÃ©ritÃ© (Low, Medium, High).

### Classification des scripts

La classification des scripts utilise des rÃ¨gles dÃ©finies pour dÃ©terminer la catÃ©gorie et la sous-catÃ©gorie de chaque script. Ces rÃ¨gles peuvent Ãªtre basÃ©es sur :

- Le contenu du script
- Le chemin du script
- Le nom du script
- Le type de script

### Organisation intelligente

L'organisation intelligente dÃ©place les scripts vers une structure de dossiers sÃ©mantiques basÃ©e sur leur classification. Cette structure suit les principes SOLID, avec une sÃ©paration claire des responsabilitÃ©s :

- Chaque dossier a une responsabilitÃ© unique
- Les scripts sont organisÃ©s par fonction, pas par type
- Les dÃ©pendances sont clairement identifiÃ©es
- Les interfaces sont stables et bien dÃ©finies

### Mise Ã  jour des rÃ©fÃ©rences

La mise Ã  jour des rÃ©fÃ©rences modifie les rÃ©fÃ©rences entre scripts aprÃ¨s dÃ©placement pour maintenir la cohÃ©rence du systÃ¨me. Elle prend en compte :

- Les chemins relatifs
- Les diffÃ©rents types d'imports selon le langage
- Les dÃ©pendances directes et indirectes

## Utilisation

Pour utiliser la Phase 2 du Script Manager, exÃ©cutez le script `Phase2-AnalyzeAndOrganize.ps1` :

```powershell
# Mode simulation (sans appliquer les changements)
.\Phase2-AnalyzeAndOrganize.ps1

# Analyse approfondie et application des changements
.\Phase2-AnalyzeAndOrganize.ps1 -AnalysisDepth Advanced -AutoApply
```

Options disponibles :

- `-InventoryPath` : Chemin vers le fichier d'inventaire (par dÃ©faut : scripts\manager\data\inventory.json)
- `-RulesPath` : Chemin vers le fichier de rÃ¨gles (par dÃ©faut : scripts\manager\config\rules.json)
- `-AnalysisDepth` : Niveau de profondeur de l'analyse (Basic, Standard, Advanced)
- `-AutoApply` : Applique automatiquement les recommandations d'organisation

## Tests

Des tests unitaires sont disponibles pour valider le fonctionnement des modules :

```powershell
# Tester le module d'analyse
.\tests\Test-AnalysisModule.ps1

# Tester le module d'organisation
.\tests\Test-OrganizationModule.ps1
```

Ces tests utilisent le framework Pester et suivent une approche de Test-Driven Development.

## Bonnes pratiques

La Phase 2 du Script Manager suit les bonnes pratiques suivantes :

### SOLID

- **S**ingle Responsibility Principle : Chaque module a une responsabilitÃ© unique
- **O**pen/Closed Principle : Les modules sont ouverts Ã  l'extension mais fermÃ©s Ã  la modification
- **L**iskov Substitution Principle : Les sous-modules peuvent Ãªtre remplacÃ©s sans affecter le comportement
- **I**nterface Segregation Principle : Les interfaces sont spÃ©cifiques et cohÃ©rentes
- **D**ependency Inversion Principle : Les modules dÃ©pendent d'abstractions, pas d'implÃ©mentations

### DRY (Don't Repeat Yourself)

- Factorisation du code commun dans des fonctions rÃ©utilisables
- Utilisation de modules pour Ã©viter la duplication de code
- Centralisation des configurations et des rÃ¨gles

### KISS (Keep It Simple, Stupid)

- Fonctions courtes et focalisÃ©es
- Noms de variables et de fonctions explicites
- Documentation claire et concise
- Ã‰viter les solutions complexes quand des solutions simples existent

### Clean Code

- Code lisible et bien commentÃ©
- Nommage significatif
- Gestion des erreurs appropriÃ©e
- Tests unitaires
- Documentation Ã  jour

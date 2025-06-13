# Phase 2 : Analyse et organisation avancÃƒÂ©es

Cette documentation dÃƒÂ©crit la Phase 2 du Script Manager, qui se concentre sur l'analyse approfondie des scripts et leur organisation intelligente selon les principes SOLID, DRY, KISS et Clean Code.

## Table des matiÃƒÂ¨res

1. [Vue d'ensemble](#vue-densemble)

2. [Modules](#modules)

   - [Module d'analyse](#module-danalyse)

   - [Module d'organisation](#module-dorganisation)

3. [FonctionnalitÃƒÂ©s](#fonctionnalitÃƒÂ©s)

   - [Analyse statique](#analyse-statique)

   - [DÃƒÂ©tection des dÃƒÂ©pendances](#dÃƒÂ©tection-des-dÃƒÂ©pendances)

   - [Analyse de la qualitÃƒÂ© du code](#analyse-de-la-qualitÃƒÂ©-du-code)

   - [DÃƒÂ©tection des problÃƒÂ¨mes](#dÃƒÂ©tection-des-problÃƒÂ¨mes)

   - [Classification des scripts](#classification-des-scripts)

   - [Organisation intelligente](#organisation-intelligente)

   - [Mise ÃƒÂ  jour des rÃƒÂ©fÃƒÂ©rences](#mise-ÃƒÂ -jour-des-rÃƒÂ©fÃƒÂ©rences)

4. [Utilisation](#utilisation)

5. [Tests](#tests)

6. [Bonnes pratiques](#bonnes-pratiques)

## Vue d'ensemble

La Phase 2 du Script Manager ÃƒÂ©tend les fonctionnalitÃƒÂ©s de base de la Phase 1 en ajoutant des capacitÃƒÂ©s d'analyse approfondie et d'organisation intelligente. Elle permet de :

- Analyser statiquement le code des scripts pour en extraire des informations structurelles
- DÃƒÂ©tecter les dÃƒÂ©pendances entre les scripts
- Ãƒâ€°valuer la qualitÃƒÂ© du code selon plusieurs mÃƒÂ©triques
- Identifier les problÃƒÂ¨mes potentiels et proposer des solutions
- Classifier les scripts selon des rÃƒÂ¨gles dÃƒÂ©finies
- Organiser les scripts dans une structure de dossiers sÃƒÂ©mantiques
- Mettre ÃƒÂ  jour les rÃƒÂ©fÃƒÂ©rences entre scripts aprÃƒÂ¨s dÃƒÂ©placement

Cette phase suit les principes SOLID, DRY, KISS et Clean Code pour offrir une solution modulaire, maintenable et extensible.

## Modules

### Module d'analyse

Le module d'analyse est responsable de l'analyse approfondie des scripts. Il est composÃƒÂ© des sous-modules suivants :

- **AnalysisModule.psm1** : Module principal qui coordonne l'analyse
- **StaticAnalyzer.psm1** : Analyse statique du code
- **DependencyDetector.psm1** : DÃƒÂ©tection des dÃƒÂ©pendances entre scripts
- **CodeQualityAnalyzer.psm1** : Ãƒâ€°valuation de la qualitÃƒÂ© du code
- **ProblemDetector.psm1** : DÃƒÂ©tection des problÃƒÂ¨mes potentiels

### Module d'organisation

Le module d'organisation est responsable de l'organisation intelligente des scripts. Il est composÃƒÂ© des sous-modules suivants :

- **OrganizationModule.psm1** : Module principal qui coordonne l'organisation
- **ClassificationEngine.psm1** : Classification des scripts selon des rÃƒÂ¨gles
- **ScriptMover.psm1** : DÃƒÂ©placement des scripts
- **ReferenceUpdater.psm1** : Mise ÃƒÂ  jour des rÃƒÂ©fÃƒÂ©rences entre scripts
- **FolderStructureCreator.psm1** : CrÃƒÂ©ation de la structure de dossiers

## FonctionnalitÃƒÂ©s

### Analyse statique

L'analyse statique extrait des informations structurelles du code, telles que :

- Nombre de lignes de code
- Nombre de commentaires
- Nombre de fonctions et leurs noms
- Nombre de variables et leurs noms
- Imports et dÃƒÂ©pendances
- Structures conditionnelles et boucles
- Classes et mÃƒÂ©thodes (pour les langages orientÃƒÂ©s objet)

Cette analyse est adaptÃƒÂ©e au type de script (PowerShell, Python, Batch, Shell) et peut ÃƒÂªtre effectuÃƒÂ©e ÃƒÂ  diffÃƒÂ©rents niveaux de profondeur (Basic, Standard, Advanced).

### DÃƒÂ©tection des dÃƒÂ©pendances

La dÃƒÂ©tection des dÃƒÂ©pendances identifie les relations entre les scripts, telles que :

- Imports de modules
- Sources de scripts
- Appels ÃƒÂ  d'autres scripts
- ExÃƒÂ©cutions de scripts

Ces dÃƒÂ©pendances sont utilisÃƒÂ©es pour construire un graphe de dÃƒÂ©pendances et pour mettre ÃƒÂ  jour les rÃƒÂ©fÃƒÂ©rences lors du dÃƒÂ©placement des scripts.

### Analyse de la qualitÃƒÂ© du code

L'analyse de la qualitÃƒÂ© du code ÃƒÂ©value plusieurs mÃƒÂ©triques, telles que :

- Ratio de commentaires
- Longueur moyenne et maximale des lignes
- Ratio de lignes vides
- ComplexitÃƒÂ© du code
- Duplication de code

Ces mÃƒÂ©triques sont utilisÃƒÂ©es pour calculer un score de qualitÃƒÂ© global et pour proposer des recommandations d'amÃƒÂ©lioration.

### DÃƒÂ©tection des problÃƒÂ¨mes

La dÃƒÂ©tection des problÃƒÂ¨mes identifie les problÃƒÂ¨mes potentiels dans le code, tels que :

- Lignes trop longues
- Utilisation de chemins absolus
- Comparaisons incorrectes avec $null (PowerShell)
- Utilisation de print au lieu de logging (Python)
- Absence de @ECHO OFF (Batch)
- Absence de shebang (Shell)

Ces problÃƒÂ¨mes sont classÃƒÂ©s par type (Style, BestPractice, Portability, Encoding) et par sÃƒÂ©vÃƒÂ©ritÃƒÂ© (Low, Medium, High).

### Classification des scripts

La classification des scripts utilise des rÃƒÂ¨gles dÃƒÂ©finies pour dÃƒÂ©terminer la catÃƒÂ©gorie et la sous-catÃƒÂ©gorie de chaque script. Ces rÃƒÂ¨gles peuvent ÃƒÂªtre basÃƒÂ©es sur :

- Le contenu du script
- Le chemin du script
- Le nom du script
- Le type de script

### Organisation intelligente

L'organisation intelligente dÃƒÂ©place les scripts vers une structure de dossiers sÃƒÂ©mantiques basÃƒÂ©e sur leur classification. Cette structure suit les principes SOLID, avec une sÃƒÂ©paration claire des responsabilitÃƒÂ©s :

- Chaque dossier a une responsabilitÃƒÂ© unique
- Les scripts sont organisÃƒÂ©s par fonction, pas par type
- Les dÃƒÂ©pendances sont clairement identifiÃƒÂ©es
- Les interfaces sont stables et bien dÃƒÂ©finies

### Mise ÃƒÂ  jour des rÃƒÂ©fÃƒÂ©rences

La mise ÃƒÂ  jour des rÃƒÂ©fÃƒÂ©rences modifie les rÃƒÂ©fÃƒÂ©rences entre scripts aprÃƒÂ¨s dÃƒÂ©placement pour maintenir la cohÃƒÂ©rence du systÃƒÂ¨me. Elle prend en compte :

- Les chemins relatifs
- Les diffÃƒÂ©rents types d'imports selon le langage
- Les dÃƒÂ©pendances directes et indirectes

## Utilisation

Pour utiliser la Phase 2 du Script Manager, exÃƒÂ©cutez le script `Phase2-AnalyzeAndOrganize.ps1` :

```powershell
# Mode simulation (sans appliquer les changements)

.\Phase2-AnalyzeAndOrganize.ps1

# Analyse approfondie et application des changements

.\Phase2-AnalyzeAndOrganize.ps1 -AnalysisDepth Advanced -AutoApply
```plaintext
Options disponibles :

- `-InventoryPath` : Chemin vers le fichier d'inventaire (par dÃƒÂ©faut : scripts\\mode-manager\data\inventory.json)
- `-RulesPath` : Chemin vers le fichier de rÃƒÂ¨gles (par dÃƒÂ©faut : scripts\\mode-manager\config\rules.json)
- `-AnalysisDepth` : Niveau de profondeur de l'analyse (Basic, Standard, Advanced)
- `-AutoApply` : Applique automatiquement les recommandations d'organisation

## Tests

Des tests unitaires sont disponibles pour valider le fonctionnement des modules :

```powershell
# Tester le module d'analyse

.\development\testing\tests\Test-AnalysisModule.ps1

# Tester le module d'organisation

.\development\testing\tests\Test-OrganizationModule.ps1
```plaintext
Ces tests utilisent le framework Pester et suivent une approche de Test-Driven Development.

## Bonnes pratiques

La Phase 2 du Script Manager suit les bonnes pratiques suivantes :

### SOLID

- **S**ingle Responsibility Principle : Chaque module a une responsabilitÃƒÂ© unique
- **O**pen/Closed Principle : Les modules sont ouverts ÃƒÂ  l'extension mais fermÃƒÂ©s ÃƒÂ  la modification
- **L**iskov Substitution Principle : Les sous-modules peuvent ÃƒÂªtre remplacÃƒÂ©s sans affecter le comportement
- **I**nterface Segregation Principle : Les interfaces sont spÃƒÂ©cifiques et cohÃƒÂ©rentes
- **D**ependency Inversion Principle : Les modules dÃƒÂ©pendent d'abstractions, pas d'implÃƒÂ©mentations

### DRY (Don't Repeat Yourself)

- Factorisation du code commun dans des fonctions rÃƒÂ©utilisables
- Utilisation de modules pour ÃƒÂ©viter la duplication de code
- Centralisation des configurations et des rÃƒÂ¨gles

### KISS (Keep It Simple, Stupid)

- Fonctions courtes et focalisÃƒÂ©es
- Noms de variables et de fonctions explicites
- Documentation claire et concise
- Ãƒâ€°viter les solutions complexes quand des solutions simples existent

### Clean Code

- Code lisible et bien commentÃƒÂ©
- Nommage significatif
- Gestion des erreurs appropriÃƒÂ©e
- Tests unitaires
- Documentation ÃƒÂ  jour


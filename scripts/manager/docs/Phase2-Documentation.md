# Phase 2 : Analyse et organisation avancées

Cette documentation décrit la Phase 2 du Script Manager, qui se concentre sur l'analyse approfondie des scripts et leur organisation intelligente selon les principes SOLID, DRY, KISS et Clean Code.

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Modules](#modules)
   - [Module d'analyse](#module-danalyse)
   - [Module d'organisation](#module-dorganisation)
3. [Fonctionnalités](#fonctionnalités)
   - [Analyse statique](#analyse-statique)
   - [Détection des dépendances](#détection-des-dépendances)
   - [Analyse de la qualité du code](#analyse-de-la-qualité-du-code)
   - [Détection des problèmes](#détection-des-problèmes)
   - [Classification des scripts](#classification-des-scripts)
   - [Organisation intelligente](#organisation-intelligente)
   - [Mise à jour des références](#mise-à-jour-des-références)
4. [Utilisation](#utilisation)
5. [Tests](#tests)
6. [Bonnes pratiques](#bonnes-pratiques)

## Vue d'ensemble

La Phase 2 du Script Manager étend les fonctionnalités de base de la Phase 1 en ajoutant des capacités d'analyse approfondie et d'organisation intelligente. Elle permet de :

- Analyser statiquement le code des scripts pour en extraire des informations structurelles
- Détecter les dépendances entre les scripts
- Évaluer la qualité du code selon plusieurs métriques
- Identifier les problèmes potentiels et proposer des solutions
- Classifier les scripts selon des règles définies
- Organiser les scripts dans une structure de dossiers sémantiques
- Mettre à jour les références entre scripts après déplacement

Cette phase suit les principes SOLID, DRY, KISS et Clean Code pour offrir une solution modulaire, maintenable et extensible.

## Modules

### Module d'analyse

Le module d'analyse est responsable de l'analyse approfondie des scripts. Il est composé des sous-modules suivants :

- **AnalysisModule.psm1** : Module principal qui coordonne l'analyse
- **StaticAnalyzer.psm1** : Analyse statique du code
- **DependencyDetector.psm1** : Détection des dépendances entre scripts
- **CodeQualityAnalyzer.psm1** : Évaluation de la qualité du code
- **ProblemDetector.psm1** : Détection des problèmes potentiels

### Module d'organisation

Le module d'organisation est responsable de l'organisation intelligente des scripts. Il est composé des sous-modules suivants :

- **OrganizationModule.psm1** : Module principal qui coordonne l'organisation
- **ClassificationEngine.psm1** : Classification des scripts selon des règles
- **ScriptMover.psm1** : Déplacement des scripts
- **ReferenceUpdater.psm1** : Mise à jour des références entre scripts
- **FolderStructureCreator.psm1** : Création de la structure de dossiers

## Fonctionnalités

### Analyse statique

L'analyse statique extrait des informations structurelles du code, telles que :

- Nombre de lignes de code
- Nombre de commentaires
- Nombre de fonctions et leurs noms
- Nombre de variables et leurs noms
- Imports et dépendances
- Structures conditionnelles et boucles
- Classes et méthodes (pour les langages orientés objet)

Cette analyse est adaptée au type de script (PowerShell, Python, Batch, Shell) et peut être effectuée à différents niveaux de profondeur (Basic, Standard, Advanced).

### Détection des dépendances

La détection des dépendances identifie les relations entre les scripts, telles que :

- Imports de modules
- Sources de scripts
- Appels à d'autres scripts
- Exécutions de scripts

Ces dépendances sont utilisées pour construire un graphe de dépendances et pour mettre à jour les références lors du déplacement des scripts.

### Analyse de la qualité du code

L'analyse de la qualité du code évalue plusieurs métriques, telles que :

- Ratio de commentaires
- Longueur moyenne et maximale des lignes
- Ratio de lignes vides
- Complexité du code
- Duplication de code

Ces métriques sont utilisées pour calculer un score de qualité global et pour proposer des recommandations d'amélioration.

### Détection des problèmes

La détection des problèmes identifie les problèmes potentiels dans le code, tels que :

- Lignes trop longues
- Utilisation de chemins absolus
- Comparaisons incorrectes avec $null (PowerShell)
- Utilisation de print au lieu de logging (Python)
- Absence de @ECHO OFF (Batch)
- Absence de shebang (Shell)

Ces problèmes sont classés par type (Style, BestPractice, Portability, Encoding) et par sévérité (Low, Medium, High).

### Classification des scripts

La classification des scripts utilise des règles définies pour déterminer la catégorie et la sous-catégorie de chaque script. Ces règles peuvent être basées sur :

- Le contenu du script
- Le chemin du script
- Le nom du script
- Le type de script

### Organisation intelligente

L'organisation intelligente déplace les scripts vers une structure de dossiers sémantiques basée sur leur classification. Cette structure suit les principes SOLID, avec une séparation claire des responsabilités :

- Chaque dossier a une responsabilité unique
- Les scripts sont organisés par fonction, pas par type
- Les dépendances sont clairement identifiées
- Les interfaces sont stables et bien définies

### Mise à jour des références

La mise à jour des références modifie les références entre scripts après déplacement pour maintenir la cohérence du système. Elle prend en compte :

- Les chemins relatifs
- Les différents types d'imports selon le langage
- Les dépendances directes et indirectes

## Utilisation

Pour utiliser la Phase 2 du Script Manager, exécutez le script `Phase2-AnalyzeAndOrganize.ps1` :

```powershell
# Mode simulation (sans appliquer les changements)
.\Phase2-AnalyzeAndOrganize.ps1

# Analyse approfondie et application des changements
.\Phase2-AnalyzeAndOrganize.ps1 -AnalysisDepth Advanced -AutoApply
```

Options disponibles :

- `-InventoryPath` : Chemin vers le fichier d'inventaire (par défaut : scripts\manager\data\inventory.json)
- `-RulesPath` : Chemin vers le fichier de règles (par défaut : scripts\manager\config\rules.json)
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

- **S**ingle Responsibility Principle : Chaque module a une responsabilité unique
- **O**pen/Closed Principle : Les modules sont ouverts à l'extension mais fermés à la modification
- **L**iskov Substitution Principle : Les sous-modules peuvent être remplacés sans affecter le comportement
- **I**nterface Segregation Principle : Les interfaces sont spécifiques et cohérentes
- **D**ependency Inversion Principle : Les modules dépendent d'abstractions, pas d'implémentations

### DRY (Don't Repeat Yourself)

- Factorisation du code commun dans des fonctions réutilisables
- Utilisation de modules pour éviter la duplication de code
- Centralisation des configurations et des règles

### KISS (Keep It Simple, Stupid)

- Fonctions courtes et focalisées
- Noms de variables et de fonctions explicites
- Documentation claire et concise
- Éviter les solutions complexes quand des solutions simples existent

### Clean Code

- Code lisible et bien commenté
- Nommage significatif
- Gestion des erreurs appropriée
- Tests unitaires
- Documentation à jour

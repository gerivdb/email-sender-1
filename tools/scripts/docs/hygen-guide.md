# Guide d'utilisation de Hygen pour scripts

Ce guide explique comment utiliser Hygen pour générer des scripts standardisés pour le projet.

## Qu'est-ce que Hygen ?

Hygen est un générateur de code simple, rapide et évolutif qui vit dans votre projet. Il permet de créer des templates pour générer du code de manière cohérente et standardisée.

## Installation

### Prérequis

- Node.js et npm installés
- Projet initialisé

### Installation automatique

La méthode la plus simple pour installer Hygen est d'utiliser le script d'installation :

```batch
.\scripts\cmd\utils\install-hygen.cmd
```

Ce script installera Hygen et créera la structure de dossiers nécessaire.

### Installation manuelle

Si vous préférez installer Hygen manuellement, suivez ces étapes :

1. Installez Hygen en tant que dépendance de développement :

```bash
npm install --save-dev hygen
```

2. Créez la structure de dossiers nécessaire :

```powershell
.\scripts\setup\ensure-hygen-structure.ps1
```

### Vérification de l'installation

Pour vérifier que Hygen est correctement installé, exécutez :

```powershell
.\scripts\setup\verify-hygen-installation.ps1
```

## Utilisation

### Génération de scripts

#### Utilisation du script de commande

La méthode la plus simple pour générer des scripts est d'utiliser le script de commande :

```batch
.\scripts\cmd\utils\generate-script.cmd
```

Ce script vous présentera un menu avec les options suivantes :

1. Générer un script d'automatisation
2. Générer un script d'analyse
3. Générer un script de test
4. Générer un script d'intégration
Q. Quitter

#### Utilisation du script PowerShell

Vous pouvez également utiliser directement le script PowerShell :

```powershell
# Générer un script en mode interactif
.\scripts\utils\Generate-Script.ps1

# Générer un script d'automatisation
.\scripts\utils\Generate-Script.ps1 -Type automation -Name "Auto-ProcessFiles" -Description "Script d'automatisation pour traiter des fichiers" -Author "John Doe"

# Générer un script d'analyse
.\scripts\utils\Generate-Script.ps1 -Type analysis -Name "Analyze-CodeQuality" -Description "Script d'analyse de la qualité du code" -SubFolder "plugins" -Author "Jane Smith"

# Générer un script de test
.\scripts\utils\Generate-Script.ps1 -Type test -Name "Example-Script" -Description "Tests pour Example-Script" -ScriptToTest "automation/Example-Script.ps1" -FunctionName "ExampleScript" -Author "Dev Team"

# Générer un script d'intégration
.\scripts\utils\Generate-Script.ps1 -Type integration -Name "Sync-GitHubIssues" -Description "Script d'intégration avec GitHub Issues" -Author "Integration Team"
```

### Exemples

#### Création d'un script d'automatisation

```bash
npx hygen script-automation new
# Nom: Auto-ProcessFiles
# Description: Script d'automatisation pour traiter des fichiers
# Description additionnelle: Ce script traite automatiquement les fichiers dans un répertoire
# Auteur: John Doe
# Tags: automation, files, processing
```

Ou avec le script PowerShell :

```powershell
.\scripts\utils\Generate-Script.ps1 -Type automation -Name "Auto-ProcessFiles" -Description "Script d'automatisation pour traiter des fichiers" -AdditionalDescription "Ce script traite automatiquement les fichiers dans un répertoire" -Author "John Doe" -Tags "automation, files, processing"
```

#### Création d'un script d'analyse

```bash
npx hygen script-analysis new
# Nom: Analyze-CodeQuality
# Description: Script d'analyse de la qualité du code
# Description additionnelle: Ce script analyse la qualité du code selon les standards du projet
# Sous-dossier: plugins
# Auteur: Jane Smith
# Tags: analysis, code quality, standards
```

Ou avec le script PowerShell :

```powershell
.\scripts\utils\Generate-Script.ps1 -Type analysis -Name "Analyze-CodeQuality" -Description "Script d'analyse de la qualité du code" -AdditionalDescription "Ce script analyse la qualité du code selon les standards du projet" -SubFolder "plugins" -Author "Jane Smith" -Tags "analysis, code quality, standards"
```

#### Création d'un script de test

```bash
npx hygen script-test new
# Nom: Example-Script
# Description: Tests pour Example-Script
# Description additionnelle: Ce script teste les fonctionnalités de Example-Script
# Chemin relatif du script à tester: automation/Example-Script.ps1
# Nom de la fonction principale à tester: ExampleScript
# Auteur: Dev Team
# Tags: tests, pester, example
```

Ou avec le script PowerShell :

```powershell
.\scripts\utils\Generate-Script.ps1 -Type test -Name "Example-Script" -Description "Tests pour Example-Script" -AdditionalDescription "Ce script teste les fonctionnalités de Example-Script" -ScriptToTest "automation/Example-Script.ps1" -FunctionName "ExampleScript" -Author "Dev Team" -Tags "tests, pester, example"
```

#### Création d'un script d'intégration

```bash
npx hygen script-integration new
# Nom: Sync-GitHubIssues
# Description: Script d'intégration avec GitHub Issues
# Description additionnelle: Ce script synchronise les issues GitHub avec le système de suivi interne
# Auteur: Integration Team
# Tags: integration, github, issues
```

Ou avec le script PowerShell :

```powershell
.\scripts\utils\Generate-Script.ps1 -Type integration -Name "Sync-GitHubIssues" -Description "Script d'intégration avec GitHub Issues" -AdditionalDescription "Ce script synchronise les issues GitHub avec le système de suivi interne" -Author "Integration Team" -Tags "integration, github, issues"
```

## Structure des templates

Les templates sont stockés dans le dossier `scripts/_templates`. Chaque générateur a son propre dossier avec des templates spécifiques.

```
scripts/_templates/
  script-automation/
    new/
      hello.ejs.t
      prompt.js
  script-analysis/
    new/
      hello.ejs.t
      prompt.js
  script-test/
    new/
      hello.ejs.t
      prompt.js
  script-integration/
    new/
      hello.ejs.t
      prompt.js
```

Les scripts générés sont placés dans les dossiers suivants :

```
scripts/
  ├── automation/       # Scripts d'automatisation
  ├── analysis/         # Scripts d'analyse
  │   ├── plugins/      # Plugins d'analyse
  │   └── tests/        # Tests d'analyse
  ├── tests/            # Scripts de test
  └── integration/      # Scripts d'intégration
```

## Personnalisation des templates

Si vous souhaitez personnaliser les templates existants ou en créer de nouveaux, vous pouvez modifier les fichiers dans le dossier `scripts/_templates`.

Pour créer un nouveau générateur :

```bash
npx hygen generator new mon-generateur
```

## Bonnes pratiques

1. Utilisez toujours les générateurs pour créer de nouveaux scripts afin de maintenir une structure cohérente.
2. Respectez les conventions de nommage définies dans les templates.
3. Mettez à jour les templates si nécessaire pour refléter les évolutions des standards du projet.
4. Documentez les nouveaux générateurs que vous créez.
5. Exécutez régulièrement les tests pour vérifier que tout fonctionne correctement.
6. Utilisez les scripts d'utilitaires pour faciliter l'utilisation de Hygen.

## Résolution des problèmes

### Hygen n'est pas installé

Si Hygen n'est pas installé, exécutez :

```powershell
npm install --save-dev hygen
```

### Structure de dossiers incomplète

Si la structure de dossiers est incomplète, exécutez :

```powershell
.\scripts\setup\ensure-hygen-structure.ps1
```

### Erreurs lors de la génération de scripts

Si vous rencontrez des erreurs lors de la génération de scripts, vérifiez :

- Que Hygen est correctement installé
- Que les templates sont présents dans le dossier `scripts/_templates`
- Que les dossiers de destination existent

## Références

- [Documentation officielle de Hygen](https://www.hygen.io/)
- [GitHub de Hygen](https://github.com/jondot/hygen)
- [Analyse de la structure scripts](hygen-analysis.md)
- [Plan des templates](hygen-templates-plan.md)
- [Plan d'intégration](hygen-integration-plan.md)

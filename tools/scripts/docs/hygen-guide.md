# Guide d'utilisation de Hygen pour scripts

Ce guide explique comment utiliser Hygen pour gÃ©nÃ©rer des scripts standardisÃ©s pour le projet.

## Qu'est-ce que Hygen ?

Hygen est un gÃ©nÃ©rateur de code simple, rapide et Ã©volutif qui vit dans votre projet. Il permet de crÃ©er des templates pour gÃ©nÃ©rer du code de maniÃ¨re cohÃ©rente et standardisÃ©e.

## Installation

### PrÃ©requis

- Node.js et npm installÃ©s
- Projet initialisÃ©

### Installation automatique

La mÃ©thode la plus simple pour installer Hygen est d'utiliser le script d'installation :

```batch
.\scripts\cmd\utils\install-hygen.cmd
```

Ce script installera Hygen et crÃ©era la structure de dossiers nÃ©cessaire.

### Installation manuelle

Si vous prÃ©fÃ©rez installer Hygen manuellement, suivez ces Ã©tapes :

1. Installez Hygen en tant que dÃ©pendance de dÃ©veloppement :

```bash
npm install --save-dev hygen
```

2. CrÃ©ez la structure de dossiers nÃ©cessaire :

```powershell
.\scripts\setup\ensure-hygen-structure.ps1
```

### VÃ©rification de l'installation

Pour vÃ©rifier que Hygen est correctement installÃ©, exÃ©cutez :

```powershell
.\scripts\setup\verify-hygen-installation.ps1
```

## Utilisation

### GÃ©nÃ©ration de scripts

#### Utilisation du script de commande

La mÃ©thode la plus simple pour gÃ©nÃ©rer des scripts est d'utiliser le script de commande :

```batch
.\scripts\cmd\utils\generate-script.cmd
```

Ce script vous prÃ©sentera un menu avec les options suivantes :

1. GÃ©nÃ©rer un script d'automatisation
2. GÃ©nÃ©rer un script d'analyse
3. GÃ©nÃ©rer un script de test
4. GÃ©nÃ©rer un script d'intÃ©gration
Q. Quitter

#### Utilisation du script PowerShell

Vous pouvez Ã©galement utiliser directement le script PowerShell :

```powershell
# GÃ©nÃ©rer un script en mode interactif
.\scripts\utils\Generate-Script.ps1

# GÃ©nÃ©rer un script d'automatisation
.\scripts\utils\Generate-Script.ps1 -Type automation -Name "Auto-ProcessFiles" -Description "Script d'automatisation pour traiter des fichiers" -Author "John Doe"

# GÃ©nÃ©rer un script d'analyse
.\scripts\utils\Generate-Script.ps1 -Type analysis -Name "Analyze-CodeQuality" -Description "Script d'analyse de la qualitÃ© du code" -SubFolder "plugins" -Author "Jane Smith"

# GÃ©nÃ©rer un script de test
.\scripts\utils\Generate-Script.ps1 -Type test -Name "Example-Script" -Description "Tests pour Example-Script" -ScriptToTest "automation/Example-Script.ps1" -FunctionName "ExampleScript" -Author "Dev Team"

# GÃ©nÃ©rer un script d'intÃ©gration
.\scripts\utils\Generate-Script.ps1 -Type integration -Name "Sync-GitHubIssues" -Description "Script d'intÃ©gration avec GitHub Issues" -Author "Integration Team"
```

### Exemples

#### CrÃ©ation d'un script d'automatisation

```bash
npx hygen script-automation new
# Nom: Auto-ProcessFiles
# Description: Script d'automatisation pour traiter des fichiers
# Description additionnelle: Ce script traite automatiquement les fichiers dans un rÃ©pertoire
# Auteur: John Doe
# Tags: automation, files, processing
```

Ou avec le script PowerShell :

```powershell
.\scripts\utils\Generate-Script.ps1 -Type automation -Name "Auto-ProcessFiles" -Description "Script d'automatisation pour traiter des fichiers" -AdditionalDescription "Ce script traite automatiquement les fichiers dans un rÃ©pertoire" -Author "John Doe" -Tags "automation, files, processing"
```

#### CrÃ©ation d'un script d'analyse

```bash
npx hygen script-analysis new
# Nom: Analyze-CodeQuality
# Description: Script d'analyse de la qualitÃ© du code
# Description additionnelle: Ce script analyse la qualitÃ© du code selon les standards du projet
# Sous-dossier: plugins
# Auteur: Jane Smith
# Tags: analysis, code quality, standards
```

Ou avec le script PowerShell :

```powershell
.\scripts\utils\Generate-Script.ps1 -Type analysis -Name "Analyze-CodeQuality" -Description "Script d'analyse de la qualitÃ© du code" -AdditionalDescription "Ce script analyse la qualitÃ© du code selon les standards du projet" -SubFolder "plugins" -Author "Jane Smith" -Tags "analysis, code quality, standards"
```

#### CrÃ©ation d'un script de test

```bash
npx hygen script-test new
# Nom: Example-Script
# Description: Tests pour Example-Script
# Description additionnelle: Ce script teste les fonctionnalitÃ©s de Example-Script
# Chemin relatif du script Ã  tester: automation/Example-Script.ps1
# Nom de la fonction principale Ã  tester: ExampleScript
# Auteur: Dev Team
# Tags: tests, pester, example
```

Ou avec le script PowerShell :

```powershell
.\scripts\utils\Generate-Script.ps1 -Type test -Name "Example-Script" -Description "Tests pour Example-Script" -AdditionalDescription "Ce script teste les fonctionnalitÃ©s de Example-Script" -ScriptToTest "automation/Example-Script.ps1" -FunctionName "ExampleScript" -Author "Dev Team" -Tags "tests, pester, example"
```

#### CrÃ©ation d'un script d'intÃ©gration

```bash
npx hygen script-integration new
# Nom: Sync-GitHubIssues
# Description: Script d'intÃ©gration avec GitHub Issues
# Description additionnelle: Ce script synchronise les issues GitHub avec le systÃ¨me de suivi interne
# Auteur: Integration Team
# Tags: integration, github, issues
```

Ou avec le script PowerShell :

```powershell
.\scripts\utils\Generate-Script.ps1 -Type integration -Name "Sync-GitHubIssues" -Description "Script d'intÃ©gration avec GitHub Issues" -AdditionalDescription "Ce script synchronise les issues GitHub avec le systÃ¨me de suivi interne" -Author "Integration Team" -Tags "integration, github, issues"
```

## Structure des templates

Les templates sont stockÃ©s dans le dossier `scripts/_templates`. Chaque gÃ©nÃ©rateur a son propre dossier avec des templates spÃ©cifiques.

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

Les scripts gÃ©nÃ©rÃ©s sont placÃ©s dans les dossiers suivants :

```
scripts/
  â”œâ”€â”€ automation/       # Scripts d'automatisation
  â”œâ”€â”€ analysis/         # Scripts d'analyse
  â”‚   â”œâ”€â”€ plugins/      # Plugins d'analyse
  â”‚   â””â”€â”€ tests/        # Tests d'analyse
  â”œâ”€â”€ tests/            # Scripts de test
  â””â”€â”€ integration/      # Scripts d'intÃ©gration
```

## Personnalisation des templates

Si vous souhaitez personnaliser les templates existants ou en crÃ©er de nouveaux, vous pouvez modifier les fichiers dans le dossier `scripts/_templates`.

Pour crÃ©er un nouveau gÃ©nÃ©rateur :

```bash
npx hygen generator new mon-generateur
```

## Bonnes pratiques

1. Utilisez toujours les gÃ©nÃ©rateurs pour crÃ©er de nouveaux scripts afin de maintenir une structure cohÃ©rente.
2. Respectez les conventions de nommage dÃ©finies dans les templates.
3. Mettez Ã  jour les templates si nÃ©cessaire pour reflÃ©ter les Ã©volutions des standards du projet.
4. Documentez les nouveaux gÃ©nÃ©rateurs que vous crÃ©ez.
5. ExÃ©cutez rÃ©guliÃ¨rement les tests pour vÃ©rifier que tout fonctionne correctement.
6. Utilisez les scripts d'utilitaires pour faciliter l'utilisation de Hygen.

## RÃ©solution des problÃ¨mes

### Hygen n'est pas installÃ©

Si Hygen n'est pas installÃ©, exÃ©cutez :

```powershell
npm install --save-dev hygen
```

### Structure de dossiers incomplÃ¨te

Si la structure de dossiers est incomplÃ¨te, exÃ©cutez :

```powershell
.\scripts\setup\ensure-hygen-structure.ps1
```

### Erreurs lors de la gÃ©nÃ©ration de scripts

Si vous rencontrez des erreurs lors de la gÃ©nÃ©ration de scripts, vÃ©rifiez :

- Que Hygen est correctement installÃ©
- Que les templates sont prÃ©sents dans le dossier `scripts/_templates`
- Que les dossiers de destination existent

## RÃ©fÃ©rences

- [Documentation officielle de Hygen](https://www.hygen.io/)
- [GitHub de Hygen](https://github.com/jondot/hygen)
- [Analyse de la structure scripts](hygen-analysis.md)
- [Plan des templates](hygen-templates-plan.md)
- [Plan d'intÃ©gration](hygen-integration-plan.md)

# IntÃ©gration avec des outils d'analyse tiers

Ce document dÃ©crit comment utiliser le systÃ¨me d'intÃ©gration avec des outils d'analyse tiers pour amÃ©liorer la couverture d'analyse de code dans le projet.

## Table des matiÃ¨res

1. [Introduction](#introduction)
2. [Outils pris en charge](#outils-pris-en-charge)
3. [Installation](#installation)
4. [Utilisation](#utilisation)
   - [Analyse avec PSScriptAnalyzer](#analyse-avec-psscriptanalyzer)
   - [Analyse avec ESLint](#analyse-avec-eslint)
   - [Analyse avec Pylint](#analyse-avec-pylint)
   - [Analyse avec SonarQube](#analyse-avec-sonarqube)
5. [Fusion des rÃ©sultats](#fusion-des-rÃ©sultats)
6. [SystÃ¨me de plugins](#systÃ¨me-de-plugins)
7. [CrÃ©ation de plugins personnalisÃ©s](#crÃ©ation-de-plugins-personnalisÃ©s)
8. [DÃ©pannage](#dÃ©pannage)

## Introduction

Le systÃ¨me d'intÃ©gration avec des outils d'analyse tiers permet d'analyser le code source avec diffÃ©rents outils spÃ©cialisÃ©s (PSScriptAnalyzer, ESLint, Pylint, SonarQube, etc.) et de fusionner les rÃ©sultats dans un format unifiÃ©. Cela permet d'avoir une vue d'ensemble de la qualitÃ© du code et de dÃ©tecter des problÃ¨mes qui pourraient Ãªtre manquÃ©s par un seul outil.

## Outils pris en charge

Le systÃ¨me prend en charge les outils d'analyse suivants :

- **PSScriptAnalyzer** : Analyse des scripts PowerShell
- **ESLint** : Analyse des fichiers JavaScript/TypeScript
- **Pylint** : Analyse des fichiers Python
- **SonarQube** : Analyse multi-langage avec SonarQube Scanner

D'autres outils peuvent Ãªtre ajoutÃ©s via le systÃ¨me de plugins.

## Installation

### PrÃ©requis

- PowerShell 5.1 ou supÃ©rieur
- Les outils d'analyse que vous souhaitez utiliser doivent Ãªtre installÃ©s sur votre systÃ¨me

### Installation des outils d'analyse

#### PSScriptAnalyzer

```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
```

#### ESLint

```bash
npm install -g eslint
# ou localement dans votre projet
npm install eslint --save-dev
```

#### Pylint

```bash
pip install pylint
```

#### SonarQube Scanner

TÃ©lÃ©chargez et installez SonarQube Scanner depuis le site officiel : https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/

## Utilisation

### Analyse avec PSScriptAnalyzer

Pour analyser un fichier ou un rÃ©pertoire avec PSScriptAnalyzer :

```powershell
.\scripts\analysis\tools\Connect-PSScriptAnalyzer.ps1 -FilePath "chemin\vers\fichier.ps1" -OutputPath "resultats.json"
```

Options disponibles :

- `-FilePath` : Chemin du fichier ou du rÃ©pertoire Ã  analyser
- `-IncludeRule` : RÃ¨gles Ã  inclure dans l'analyse
- `-ExcludeRule` : RÃ¨gles Ã  exclure de l'analyse
- `-Severity` : SÃ©vÃ©ritÃ© des problÃ¨mes Ã  inclure (Error, Warning, Information, All)
- `-Recurse` : Analyser rÃ©cursivement les sous-rÃ©pertoires
- `-OutputPath` : Chemin du fichier de sortie pour les rÃ©sultats

### Analyse avec ESLint

Pour analyser un fichier ou un rÃ©pertoire avec ESLint :

```powershell
.\scripts\analysis\tools\Connect-ESLint.ps1 -FilePath "chemin\vers\fichier.js" -OutputPath "resultats.json"
```

Options disponibles :

- `-FilePath` : Chemin du fichier ou du rÃ©pertoire Ã  analyser
- `-ConfigFile` : Chemin du fichier de configuration ESLint
- `-Fix` : Corriger automatiquement les problÃ¨mes qui peuvent Ãªtre corrigÃ©s
- `-OutputPath` : Chemin du fichier de sortie pour les rÃ©sultats

### Analyse avec Pylint

Pour analyser un fichier ou un rÃ©pertoire avec Pylint :

```powershell
.\scripts\analysis\tools\Connect-Pylint.ps1 -FilePath "chemin\vers\fichier.py" -OutputPath "resultats.json"
```

Options disponibles :

- `-FilePath` : Chemin du fichier ou du rÃ©pertoire Ã  analyser
- `-ConfigFile` : Chemin du fichier de configuration Pylint
- `-DisableRules` : RÃ¨gles Ã  dÃ©sactiver lors de l'analyse
- `-EnableRules` : RÃ¨gles Ã  activer lors de l'analyse
- `-OutputPath` : Chemin du fichier de sortie pour les rÃ©sultats

### Analyse avec SonarQube

Pour analyser un projet avec SonarQube Scanner :

```powershell
.\scripts\analysis\tools\Connect-SonarQube.ps1 -ProjectKey "mon-projet" -ProjectName "Mon Projet" -ProjectVersion "1.0" -SourceDirectory "chemin\vers\sources" -OutputPath "resultats.json"
```

Options disponibles :

- `-ProjectKey` : ClÃ© du projet SonarQube
- `-ProjectName` : Nom du projet SonarQube
- `-ProjectVersion` : Version du projet SonarQube
- `-SourceDirectory` : RÃ©pertoire contenant les sources Ã  analyser
- `-SonarQubeUrl` : URL du serveur SonarQube (par dÃ©faut: http://localhost:9000)
- `-Token` : Token d'authentification pour l'API SonarQube
- `-OutputPath` : Chemin du fichier de sortie pour les rÃ©sultats

## Fusion des rÃ©sultats

Pour fusionner les rÃ©sultats de plusieurs analyses :

```powershell
.\scripts\analysis\Merge-AnalysisResults.ps1 -InputPath "resultats1.json", "resultats2.json" -OutputPath "resultats-fusionnes.json" -RemoveDuplicates -GenerateHtmlReport
```

Options disponibles :

- `-InputPath` : Chemin du fichier ou des fichiers contenant les rÃ©sultats d'analyse Ã  fusionner
- `-OutputPath` : Chemin du fichier de sortie pour les rÃ©sultats fusionnÃ©s
- `-RemoveDuplicates` : Supprimer les rÃ©sultats en double
- `-Severity` : Filtrer les rÃ©sultats par sÃ©vÃ©ritÃ© (Error, Warning, Information, All)
- `-ToolName` : Filtrer les rÃ©sultats par outil d'analyse
- `-Category` : Filtrer les rÃ©sultats par catÃ©gorie
- `-GenerateHtmlReport` : GÃ©nÃ©rer un rapport HTML en plus du fichier JSON

## SystÃ¨me de plugins

Le systÃ¨me de plugins permet d'Ã©tendre les fonctionnalitÃ©s d'analyse avec des plugins personnalisÃ©s.

### Enregistrement des plugins intÃ©grÃ©s

Pour enregistrer les connecteurs intÃ©grÃ©s comme plugins :

```powershell
.\scripts\analysis\Register-AnalysisPlugin.ps1
```

### Liste des plugins enregistrÃ©s

Pour afficher la liste des plugins enregistrÃ©s :

```powershell
.\scripts\analysis\Register-AnalysisPlugin.ps1 -ListPlugins
```

### Activation/dÃ©sactivation des plugins

Pour activer ou dÃ©sactiver un plugin :

```powershell
.\scripts\analysis\Register-AnalysisPlugin.ps1 -EnablePlugin "ESLint"
.\scripts\analysis\Register-AnalysisPlugin.ps1 -DisablePlugin "ESLint"
```

### Exportation des plugins

Pour exporter un plugin vers un fichier :

```powershell
.\scripts\analysis\Register-AnalysisPlugin.ps1 -ExportPlugin "ESLint" -OutputDirectory "chemin\vers\repertoire"
```

## CrÃ©ation de plugins personnalisÃ©s

Vous pouvez crÃ©er vos propres plugins pour intÃ©grer d'autres outils d'analyse. Un plugin est un script PowerShell qui enregistre une fonction d'analyse avec le systÃ¨me de plugins.

Exemple de plugin personnalisÃ© :

```powershell
# MonPlugin.ps1
#Requires -Version 5.1

# Importer le module de gestion des plugins
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$pluginManagerPath = Join-Path -Path $modulesPath -ChildPath "AnalysisPluginManager.psm1"
Import-Module -Name $pluginManagerPath -Force

# Fonction d'analyse
$analyzeFunction = {
    param (
        [string]$FilePath
    )
    
    # Analyser le fichier avec votre outil
    $results = @()
    
    # CrÃ©er un rÃ©sultat unifiÃ©
    $result = New-UnifiedAnalysisResult -ToolName "MonOutil" `
                                       -FilePath $FilePath `
                                       -Line 1 `
                                       -Column 1 `
                                       -RuleId "REGLE001" `
                                       -Severity "Warning" `
                                       -Message "Exemple de message d'avertissement" `
                                       -Category "Style"
    
    $results += $result
    
    return $results
}

# Enregistrer le plugin
Register-AnalysisPlugin -Name "MonPlugin" `
                       -Description "Mon plugin personnalisÃ©" `
                       -Version "1.0" `
                       -Author "Votre nom" `
                       -Language "Generic" `
                       -AnalyzeFunction $analyzeFunction `
                       -Configuration @{} `
                       -Dependencies @() `
                       -Force
```

Pour enregistrer votre plugin :

```powershell
.\scripts\analysis\Register-AnalysisPlugin.ps1 -Path "chemin\vers\MonPlugin.ps1"
```

## DÃ©pannage

### ProblÃ¨mes courants

#### PSScriptAnalyzer n'est pas disponible

Assurez-vous que PSScriptAnalyzer est installÃ© :

```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
```

#### ESLint n'est pas disponible

VÃ©rifiez que ESLint est installÃ© et accessible dans le PATH :

```bash
eslint --version
```

#### Pylint n'est pas disponible

VÃ©rifiez que Pylint est installÃ© et accessible dans le PATH :

```bash
pylint --version
```

#### SonarQube Scanner n'est pas disponible

VÃ©rifiez que SonarQube Scanner est installÃ© et accessible dans le PATH :

```bash
sonar-scanner --version
```

### Journalisation dÃ©taillÃ©e

Pour obtenir des informations de dÃ©bogage dÃ©taillÃ©es, utilisez le paramÃ¨tre `-Verbose` :

```powershell
.\scripts\analysis\tools\Connect-PSScriptAnalyzer.ps1 -FilePath "chemin\vers\fichier.ps1" -Verbose
```

### VÃ©rification des outils disponibles

Pour vÃ©rifier quels outils d'analyse sont disponibles sur votre systÃ¨me :

```powershell
Import-Module -Name ".\scripts\analysis\modules\AnalysisTools.psm1"
Test-AnalysisTool -ToolName "PSScriptAnalyzer"
Test-AnalysisTool -ToolName "ESLint"
Test-AnalysisTool -ToolName "Pylint"
Test-AnalysisTool -ToolName "SonarQube"
```

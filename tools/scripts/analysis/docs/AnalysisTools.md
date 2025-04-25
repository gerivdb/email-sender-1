# Intégration avec des outils d'analyse tiers

Ce document décrit comment utiliser le système d'intégration avec des outils d'analyse tiers pour améliorer la couverture d'analyse de code dans le projet.

## Table des matières

1. [Introduction](#introduction)
2. [Outils pris en charge](#outils-pris-en-charge)
3. [Installation](#installation)
4. [Utilisation](#utilisation)
   - [Analyse avec PSScriptAnalyzer](#analyse-avec-psscriptanalyzer)
   - [Analyse avec ESLint](#analyse-avec-eslint)
   - [Analyse avec Pylint](#analyse-avec-pylint)
   - [Analyse avec SonarQube](#analyse-avec-sonarqube)
5. [Fusion des résultats](#fusion-des-résultats)
6. [Système de plugins](#système-de-plugins)
7. [Création de plugins personnalisés](#création-de-plugins-personnalisés)
8. [Dépannage](#dépannage)

## Introduction

Le système d'intégration avec des outils d'analyse tiers permet d'analyser le code source avec différents outils spécialisés (PSScriptAnalyzer, ESLint, Pylint, SonarQube, etc.) et de fusionner les résultats dans un format unifié. Cela permet d'avoir une vue d'ensemble de la qualité du code et de détecter des problèmes qui pourraient être manqués par un seul outil.

## Outils pris en charge

Le système prend en charge les outils d'analyse suivants :

- **PSScriptAnalyzer** : Analyse des scripts PowerShell
- **ESLint** : Analyse des fichiers JavaScript/TypeScript
- **Pylint** : Analyse des fichiers Python
- **SonarQube** : Analyse multi-langage avec SonarQube Scanner

D'autres outils peuvent être ajoutés via le système de plugins.

## Installation

### Prérequis

- PowerShell 5.1 ou supérieur
- Les outils d'analyse que vous souhaitez utiliser doivent être installés sur votre système

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

Téléchargez et installez SonarQube Scanner depuis le site officiel : https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/

## Utilisation

### Analyse avec PSScriptAnalyzer

Pour analyser un fichier ou un répertoire avec PSScriptAnalyzer :

```powershell
.\scripts\analysis\tools\Connect-PSScriptAnalyzer.ps1 -FilePath "chemin\vers\fichier.ps1" -OutputPath "resultats.json"
```

Options disponibles :

- `-FilePath` : Chemin du fichier ou du répertoire à analyser
- `-IncludeRule` : Règles à inclure dans l'analyse
- `-ExcludeRule` : Règles à exclure de l'analyse
- `-Severity` : Sévérité des problèmes à inclure (Error, Warning, Information, All)
- `-Recurse` : Analyser récursivement les sous-répertoires
- `-OutputPath` : Chemin du fichier de sortie pour les résultats

### Analyse avec ESLint

Pour analyser un fichier ou un répertoire avec ESLint :

```powershell
.\scripts\analysis\tools\Connect-ESLint.ps1 -FilePath "chemin\vers\fichier.js" -OutputPath "resultats.json"
```

Options disponibles :

- `-FilePath` : Chemin du fichier ou du répertoire à analyser
- `-ConfigFile` : Chemin du fichier de configuration ESLint
- `-Fix` : Corriger automatiquement les problèmes qui peuvent être corrigés
- `-OutputPath` : Chemin du fichier de sortie pour les résultats

### Analyse avec Pylint

Pour analyser un fichier ou un répertoire avec Pylint :

```powershell
.\scripts\analysis\tools\Connect-Pylint.ps1 -FilePath "chemin\vers\fichier.py" -OutputPath "resultats.json"
```

Options disponibles :

- `-FilePath` : Chemin du fichier ou du répertoire à analyser
- `-ConfigFile` : Chemin du fichier de configuration Pylint
- `-DisableRules` : Règles à désactiver lors de l'analyse
- `-EnableRules` : Règles à activer lors de l'analyse
- `-OutputPath` : Chemin du fichier de sortie pour les résultats

### Analyse avec SonarQube

Pour analyser un projet avec SonarQube Scanner :

```powershell
.\scripts\analysis\tools\Connect-SonarQube.ps1 -ProjectKey "mon-projet" -ProjectName "Mon Projet" -ProjectVersion "1.0" -SourceDirectory "chemin\vers\sources" -OutputPath "resultats.json"
```

Options disponibles :

- `-ProjectKey` : Clé du projet SonarQube
- `-ProjectName` : Nom du projet SonarQube
- `-ProjectVersion` : Version du projet SonarQube
- `-SourceDirectory` : Répertoire contenant les sources à analyser
- `-SonarQubeUrl` : URL du serveur SonarQube (par défaut: http://localhost:9000)
- `-Token` : Token d'authentification pour l'API SonarQube
- `-OutputPath` : Chemin du fichier de sortie pour les résultats

## Fusion des résultats

Pour fusionner les résultats de plusieurs analyses :

```powershell
.\scripts\analysis\Merge-AnalysisResults.ps1 -InputPath "resultats1.json", "resultats2.json" -OutputPath "resultats-fusionnes.json" -RemoveDuplicates -GenerateHtmlReport
```

Options disponibles :

- `-InputPath` : Chemin du fichier ou des fichiers contenant les résultats d'analyse à fusionner
- `-OutputPath` : Chemin du fichier de sortie pour les résultats fusionnés
- `-RemoveDuplicates` : Supprimer les résultats en double
- `-Severity` : Filtrer les résultats par sévérité (Error, Warning, Information, All)
- `-ToolName` : Filtrer les résultats par outil d'analyse
- `-Category` : Filtrer les résultats par catégorie
- `-GenerateHtmlReport` : Générer un rapport HTML en plus du fichier JSON

## Système de plugins

Le système de plugins permet d'étendre les fonctionnalités d'analyse avec des plugins personnalisés.

### Enregistrement des plugins intégrés

Pour enregistrer les connecteurs intégrés comme plugins :

```powershell
.\scripts\analysis\Register-AnalysisPlugin.ps1
```

### Liste des plugins enregistrés

Pour afficher la liste des plugins enregistrés :

```powershell
.\scripts\analysis\Register-AnalysisPlugin.ps1 -ListPlugins
```

### Activation/désactivation des plugins

Pour activer ou désactiver un plugin :

```powershell
.\scripts\analysis\Register-AnalysisPlugin.ps1 -EnablePlugin "ESLint"
.\scripts\analysis\Register-AnalysisPlugin.ps1 -DisablePlugin "ESLint"
```

### Exportation des plugins

Pour exporter un plugin vers un fichier :

```powershell
.\scripts\analysis\Register-AnalysisPlugin.ps1 -ExportPlugin "ESLint" -OutputDirectory "chemin\vers\repertoire"
```

## Création de plugins personnalisés

Vous pouvez créer vos propres plugins pour intégrer d'autres outils d'analyse. Un plugin est un script PowerShell qui enregistre une fonction d'analyse avec le système de plugins.

Exemple de plugin personnalisé :

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
    
    # Créer un résultat unifié
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
                       -Description "Mon plugin personnalisé" `
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

## Dépannage

### Problèmes courants

#### PSScriptAnalyzer n'est pas disponible

Assurez-vous que PSScriptAnalyzer est installé :

```powershell
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
```

#### ESLint n'est pas disponible

Vérifiez que ESLint est installé et accessible dans le PATH :

```bash
eslint --version
```

#### Pylint n'est pas disponible

Vérifiez que Pylint est installé et accessible dans le PATH :

```bash
pylint --version
```

#### SonarQube Scanner n'est pas disponible

Vérifiez que SonarQube Scanner est installé et accessible dans le PATH :

```bash
sonar-scanner --version
```

### Journalisation détaillée

Pour obtenir des informations de débogage détaillées, utilisez le paramètre `-Verbose` :

```powershell
.\scripts\analysis\tools\Connect-PSScriptAnalyzer.ps1 -FilePath "chemin\vers\fichier.ps1" -Verbose
```

### Vérification des outils disponibles

Pour vérifier quels outils d'analyse sont disponibles sur votre système :

```powershell
Import-Module -Name ".\scripts\analysis\modules\AnalysisTools.psm1"
Test-AnalysisTool -ToolName "PSScriptAnalyzer"
Test-AnalysisTool -ToolName "ESLint"
Test-AnalysisTool -ToolName "Pylint"
Test-AnalysisTool -ToolName "SonarQube"
```

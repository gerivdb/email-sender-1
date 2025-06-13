# SystÃ¨me d'analyse de code

Ce systÃ¨me permet d'analyser le code source avec diffÃ©rents outils et d'intÃ©grer les rÃ©sultats avec des outils tiers.

## Documentation

- [Guide d'intÃ©gration](INTEGRATION.md) - Guide complet pour l'intÃ©gration avec des outils d'analyse tiers
- [Guide de performance](PERFORMANCE.md) - Guide pour optimiser les performances du systÃ¨me d'analyse
- [Exemples](EXAMPLES.md) - Exemples concrets d'utilisation du systÃ¨me d'analyse

## Vue d'ensemble

Le systÃ¨me d'analyse de code est composÃ© des scripts suivants :

- `Start-CodeAnalysis.ps1` - Script principal pour l'analyse de code avec diffÃ©rents outils
- `Fix-HtmlReportEncoding.ps1` - Script pour corriger les problÃ¨mes d'encodage dans les rapports HTML
- `Integrate-ThirdPartyTools.ps1` - Script pour intÃ©grer les rÃ©sultats d'analyse avec des outils tiers
- `modules/UnifiedResultsFormat.psm1` - Module pour dÃ©finir un format unifiÃ© pour les rÃ©sultats d'analyse

## Installation

1. Clonez ce dÃ©pÃ´t ou tÃ©lÃ©chargez les fichiers dans un rÃ©pertoire de votre choix.
2. Assurez-vous que PowerShell 5.1 ou supÃ©rieur est installÃ© sur votre systÃ¨me.
3. Installez les dÃ©pendances requises :

```powershell
# Installer PSScriptAnalyzer

Install-Module -Name PSScriptAnalyzer -Force

# Installer ESLint (si vous souhaitez analyser des fichiers JavaScript)

npm install -g eslint

# Installer Pylint (si vous souhaitez analyser des fichiers Python)

pip install pylint
```plaintext
## Utilisation

### Analyse de code

```powershell
# Analyser un fichier avec PSScriptAnalyzer

.\Start-CodeAnalysis.ps1 -Path ".\development\scripts\test.ps1" -Tools PSScriptAnalyzer

# Analyser un rÃ©pertoire avec PSScriptAnalyzer et TodoAnalyzer

.\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools PSScriptAnalyzer, TodoAnalyzer -Recurse

# Analyser un fichier avec tous les outils disponibles et gÃ©nÃ©rer un rapport HTML

.\Start-CodeAnalysis.ps1 -Path ".\development\scripts\test.ps1" -Tools All -GenerateHtmlReport

# Analyser un rÃ©pertoire avec tous les outils disponibles, gÃ©nÃ©rer un rapport HTML et l'ouvrir

.\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools All -GenerateHtmlReport -OpenReport -Recurse
```plaintext
### Correction des problÃ¨mes d'encodage dans les rapports HTML

```powershell
# Corriger l'encodage d'un fichier HTML

.\Fix-HtmlReportEncoding.ps1 -Path ".\results\report.html"

# Corriger l'encodage de tous les fichiers HTML dans un rÃ©pertoire

.\Fix-HtmlReportEncoding.ps1 -Path ".\results"

# Corriger l'encodage de tous les fichiers HTML dans un rÃ©pertoire et ses sous-rÃ©pertoires

.\Fix-HtmlReportEncoding.ps1 -Path ".\results" -Recurse
```plaintext
### IntÃ©gration avec des outils tiers

```powershell
# IntÃ©grer les rÃ©sultats avec GitHub Actions

.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool GitHub -OutputPath ".\github-annotations.json"

# IntÃ©grer les rÃ©sultats avec SonarQube

.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool SonarQube -OutputPath ".\sonarqube-issues.json" -ProjectKey "my-project"

# IntÃ©grer les rÃ©sultats avec Azure DevOps

.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool AzureDevOps -OutputPath ".\azuredevops-issues.json"
```plaintext
## Outils d'analyse pris en charge

- **PSScriptAnalyzer** - Outil d'analyse statique pour les scripts PowerShell
- **ESLint** - Outil d'analyse statique pour les fichiers JavaScript, TypeScript, etc.
- **Pylint** - Outil d'analyse statique pour les fichiers Python
- **TodoAnalyzer** - Outil d'analyse intÃ©grÃ© pour dÃ©tecter les commentaires TODO, FIXME, HACK, NOTE, etc.

## IntÃ©gration avec des outils tiers

- **GitHub Actions** - IntÃ©gration avec GitHub Actions pour afficher les problÃ¨mes dans les pull requests
- **SonarQube** - IntÃ©gration avec SonarQube pour afficher les problÃ¨mes dans l'interface web
- **Azure DevOps** - IntÃ©gration avec Azure DevOps pour afficher les problÃ¨mes dans les pull requests

## Personnalisation

Le systÃ¨me d'analyse peut Ãªtre personnalisÃ© pour prendre en charge d'autres outils d'analyse ou d'autres formats de rÃ©sultats. Consultez le [guide d'intÃ©gration](INTEGRATION.md) pour plus d'informations.

## DÃ©pannage

Si vous rencontrez des problÃ¨mes lors de l'utilisation du systÃ¨me d'analyse, consultez la section "DÃ©pannage" du [guide d'intÃ©gration](INTEGRATION.md).

## Licence

Ce projet est sous licence MIT. Consultez le fichier LICENSE pour plus d'informations.

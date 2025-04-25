# Système d'analyse de code

Ce système permet d'analyser le code source avec différents outils et d'intégrer les résultats avec des outils tiers.

## Documentation

- [Guide d'intégration](INTEGRATION.md) - Guide complet pour l'intégration avec des outils d'analyse tiers
- [Guide de performance](PERFORMANCE.md) - Guide pour optimiser les performances du système d'analyse
- [Exemples](EXAMPLES.md) - Exemples concrets d'utilisation du système d'analyse

## Vue d'ensemble

Le système d'analyse de code est composé des scripts suivants :

- `Start-CodeAnalysis.ps1` - Script principal pour l'analyse de code avec différents outils
- `Fix-HtmlReportEncoding.ps1` - Script pour corriger les problèmes d'encodage dans les rapports HTML
- `Integrate-ThirdPartyTools.ps1` - Script pour intégrer les résultats d'analyse avec des outils tiers
- `modules/UnifiedResultsFormat.psm1` - Module pour définir un format unifié pour les résultats d'analyse

## Installation

1. Clonez ce dépôt ou téléchargez les fichiers dans un répertoire de votre choix.
2. Assurez-vous que PowerShell 5.1 ou supérieur est installé sur votre système.
3. Installez les dépendances requises :

```powershell
# Installer PSScriptAnalyzer
Install-Module -Name PSScriptAnalyzer -Force

# Installer ESLint (si vous souhaitez analyser des fichiers JavaScript)
npm install -g eslint

# Installer Pylint (si vous souhaitez analyser des fichiers Python)
pip install pylint
```

## Utilisation

### Analyse de code

```powershell
# Analyser un fichier avec PSScriptAnalyzer
.\Start-CodeAnalysis.ps1 -Path ".\scripts\test.ps1" -Tools PSScriptAnalyzer

# Analyser un répertoire avec PSScriptAnalyzer et TodoAnalyzer
.\Start-CodeAnalysis.ps1 -Path ".\scripts" -Tools PSScriptAnalyzer, TodoAnalyzer -Recurse

# Analyser un fichier avec tous les outils disponibles et générer un rapport HTML
.\Start-CodeAnalysis.ps1 -Path ".\scripts\test.ps1" -Tools All -GenerateHtmlReport

# Analyser un répertoire avec tous les outils disponibles, générer un rapport HTML et l'ouvrir
.\Start-CodeAnalysis.ps1 -Path ".\scripts" -Tools All -GenerateHtmlReport -OpenReport -Recurse
```

### Correction des problèmes d'encodage dans les rapports HTML

```powershell
# Corriger l'encodage d'un fichier HTML
.\Fix-HtmlReportEncoding.ps1 -Path ".\results\report.html"

# Corriger l'encodage de tous les fichiers HTML dans un répertoire
.\Fix-HtmlReportEncoding.ps1 -Path ".\results"

# Corriger l'encodage de tous les fichiers HTML dans un répertoire et ses sous-répertoires
.\Fix-HtmlReportEncoding.ps1 -Path ".\results" -Recurse
```

### Intégration avec des outils tiers

```powershell
# Intégrer les résultats avec GitHub Actions
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool GitHub -OutputPath ".\github-annotations.json"

# Intégrer les résultats avec SonarQube
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool SonarQube -OutputPath ".\sonarqube-issues.json" -ProjectKey "my-project"

# Intégrer les résultats avec Azure DevOps
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool AzureDevOps -OutputPath ".\azuredevops-issues.json"
```

## Outils d'analyse pris en charge

- **PSScriptAnalyzer** - Outil d'analyse statique pour les scripts PowerShell
- **ESLint** - Outil d'analyse statique pour les fichiers JavaScript, TypeScript, etc.
- **Pylint** - Outil d'analyse statique pour les fichiers Python
- **TodoAnalyzer** - Outil d'analyse intégré pour détecter les commentaires TODO, FIXME, HACK, NOTE, etc.

## Intégration avec des outils tiers

- **GitHub Actions** - Intégration avec GitHub Actions pour afficher les problèmes dans les pull requests
- **SonarQube** - Intégration avec SonarQube pour afficher les problèmes dans l'interface web
- **Azure DevOps** - Intégration avec Azure DevOps pour afficher les problèmes dans les pull requests

## Personnalisation

Le système d'analyse peut être personnalisé pour prendre en charge d'autres outils d'analyse ou d'autres formats de résultats. Consultez le [guide d'intégration](INTEGRATION.md) pour plus d'informations.

## Dépannage

Si vous rencontrez des problèmes lors de l'utilisation du système d'analyse, consultez la section "Dépannage" du [guide d'intégration](INTEGRATION.md).

## Licence

Ce projet est sous licence MIT. Consultez le fichier LICENSE pour plus d'informations.

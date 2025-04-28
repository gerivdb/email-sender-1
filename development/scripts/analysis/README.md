# SystÃ¨me d'analyse de code et d'intÃ©gration avec des outils tiers

Ce rÃ©pertoire contient des scripts pour analyser le code source avec diffÃ©rents outils et intÃ©grer les rÃ©sultats avec des outils tiers.

## Scripts disponibles

### Start-CodeAnalysis.ps1

Script principal pour l'analyse de code avec diffÃ©rents outils.

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools PSScriptAnalyzer, TodoAnalyzer -GenerateHtmlReport -Recurse
```

**ParamÃ¨tres :**
- `-Path` : Chemin du fichier ou du rÃ©pertoire Ã  analyser.
- `-Tools` : Outils d'analyse Ã  utiliser (PSScriptAnalyzer, ESLint, Pylint, TodoAnalyzer, All).
- `-OutputPath` : Chemin du fichier de sortie pour les rÃ©sultats.
- `-GenerateHtmlReport` : GÃ©nÃ©rer un rapport HTML en plus du fichier JSON.
- `-OpenReport` : Ouvrir le rapport HTML dans le navigateur par dÃ©faut.
- `-Recurse` : Analyser rÃ©cursivement les sous-rÃ©pertoires.

### Fix-HtmlReportEncoding.ps1

Corrige les problÃ¨mes d'encodage dans les rapports HTML d'analyse.

```powershell
.\Fix-HtmlReportEncoding.ps1 -Path ".\results\report.html"
```

**ParamÃ¨tres :**
- `-Path` : Chemin du fichier HTML Ã  corriger ou du rÃ©pertoire contenant les fichiers HTML.
- `-Recurse` : Rechercher rÃ©cursivement les fichiers HTML dans les sous-rÃ©pertoires.

### Integrate-ThirdPartyTools.ps1

IntÃ¨gre les rÃ©sultats d'analyse de code avec des outils tiers.

```powershell
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool SonarQube -ApiKey "your-api-key" -ApiUrl "https://sonarqube.example.com/api" -ProjectKey "your-project-key"
```

**ParamÃ¨tres :**
- `-Path` : Chemin du fichier JSON contenant les rÃ©sultats d'analyse.
- `-Tool` : Outil tiers avec lequel intÃ©grer les rÃ©sultats (SonarQube, GitHub, AzureDevOps).
- `-OutputPath` : Chemin du fichier de sortie pour les rÃ©sultats convertis.
- `-ApiKey` : ClÃ© API pour l'authentification avec l'outil tiers.
- `-ApiUrl` : URL de l'API de l'outil tiers.
- `-ProjectKey` : ClÃ© du projet dans l'outil tiers.

## Exemples d'utilisation

### Analyser un rÃ©pertoire avec PSScriptAnalyzer et gÃ©nÃ©rer un rapport HTML

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools PSScriptAnalyzer -GenerateHtmlReport -Recurse
```

### Analyser un fichier spÃ©cifique avec tous les outils disponibles

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts\test.ps1" -Tools All -GenerateHtmlReport -OpenReport
```

### Corriger l'encodage de tous les rapports HTML dans un rÃ©pertoire

```powershell
.\Fix-HtmlReportEncoding.ps1 -Path ".\results" -Recurse
```

### IntÃ©grer les rÃ©sultats d'analyse avec GitHub Actions

```powershell
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool GitHub -OutputPath ".\github-annotations.json"
```

### IntÃ©grer les rÃ©sultats d'analyse avec Azure DevOps

```powershell
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool AzureDevOps -OutputPath ".\azure-devops-issues.json"
```

## Format de rÃ©sultats unifiÃ©

Tous les outils d'analyse utilisent un format de rÃ©sultats unifiÃ© dÃ©fini dans le module `UnifiedResultsFormat.psm1`. Ce format permet de comparer, fusionner et traiter les rÃ©sultats de diffÃ©rents outils de maniÃ¨re cohÃ©rente.

Chaque rÃ©sultat d'analyse contient les propriÃ©tÃ©s suivantes :
- `ToolName` : Nom de l'outil d'analyse (PSScriptAnalyzer, ESLint, Pylint, etc.)
- `FilePath` : Chemin complet du fichier analysÃ©
- `FileName` : Nom du fichier analysÃ©
- `Line` : NumÃ©ro de ligne oÃ¹ le problÃ¨me a Ã©tÃ© dÃ©tectÃ©
- `Column` : NumÃ©ro de colonne oÃ¹ le problÃ¨me a Ã©tÃ© dÃ©tectÃ©
- `RuleId` : Identifiant de la rÃ¨gle qui a dÃ©tectÃ© le problÃ¨me
- `Severity` : SÃ©vÃ©ritÃ© du problÃ¨me (Error, Warning, Information)
- `Message` : Description du problÃ¨me
- `Category` : CatÃ©gorie du problÃ¨me (Style, Performance, Security, etc.)
- `Suggestion` : Suggestion de correction (si disponible)
- `OriginalObject` : Objet original retournÃ© par l'outil d'analyse

## IntÃ©gration avec des outils tiers

Le script `Integrate-ThirdPartyTools.ps1` permet d'intÃ©grer les rÃ©sultats d'analyse avec diffÃ©rents outils tiers :

### SonarQube

Les rÃ©sultats sont convertis au format SonarQube et peuvent Ãªtre envoyÃ©s Ã  l'API SonarQube pour Ãªtre affichÃ©s dans l'interface web.

### GitHub Actions

Les rÃ©sultats sont convertis au format d'annotations GitHub Actions et peuvent Ãªtre utilisÃ©s dans un workflow GitHub pour afficher les problÃ¨mes directement dans les pull requests.

### Azure DevOps

Les rÃ©sultats sont convertis au format Azure DevOps et peuvent Ãªtre utilisÃ©s dans un pipeline Azure DevOps pour afficher les problÃ¨mes dans les pull requests.

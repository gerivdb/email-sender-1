# Système d'analyse de code et d'intégration avec des outils tiers

Ce répertoire contient des scripts pour analyser le code source avec différents outils et intégrer les résultats avec des outils tiers.

## Scripts disponibles

### Start-CodeAnalysis.ps1

Script principal pour l'analyse de code avec différents outils.

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\scripts" -Tools PSScriptAnalyzer, TodoAnalyzer -GenerateHtmlReport -Recurse
```

**Paramètres :**
- `-Path` : Chemin du fichier ou du répertoire à analyser.
- `-Tools` : Outils d'analyse à utiliser (PSScriptAnalyzer, ESLint, Pylint, TodoAnalyzer, All).
- `-OutputPath` : Chemin du fichier de sortie pour les résultats.
- `-GenerateHtmlReport` : Générer un rapport HTML en plus du fichier JSON.
- `-OpenReport` : Ouvrir le rapport HTML dans le navigateur par défaut.
- `-Recurse` : Analyser récursivement les sous-répertoires.

### Fix-HtmlReportEncoding.ps1

Corrige les problèmes d'encodage dans les rapports HTML d'analyse.

```powershell
.\Fix-HtmlReportEncoding.ps1 -Path ".\results\report.html"
```

**Paramètres :**
- `-Path` : Chemin du fichier HTML à corriger ou du répertoire contenant les fichiers HTML.
- `-Recurse` : Rechercher récursivement les fichiers HTML dans les sous-répertoires.

### Integrate-ThirdPartyTools.ps1

Intègre les résultats d'analyse de code avec des outils tiers.

```powershell
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool SonarQube -ApiKey "your-api-key" -ApiUrl "https://sonarqube.example.com/api" -ProjectKey "your-project-key"
```

**Paramètres :**
- `-Path` : Chemin du fichier JSON contenant les résultats d'analyse.
- `-Tool` : Outil tiers avec lequel intégrer les résultats (SonarQube, GitHub, AzureDevOps).
- `-OutputPath` : Chemin du fichier de sortie pour les résultats convertis.
- `-ApiKey` : Clé API pour l'authentification avec l'outil tiers.
- `-ApiUrl` : URL de l'API de l'outil tiers.
- `-ProjectKey` : Clé du projet dans l'outil tiers.

## Exemples d'utilisation

### Analyser un répertoire avec PSScriptAnalyzer et générer un rapport HTML

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\scripts" -Tools PSScriptAnalyzer -GenerateHtmlReport -Recurse
```

### Analyser un fichier spécifique avec tous les outils disponibles

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\scripts\test.ps1" -Tools All -GenerateHtmlReport -OpenReport
```

### Corriger l'encodage de tous les rapports HTML dans un répertoire

```powershell
.\Fix-HtmlReportEncoding.ps1 -Path ".\results" -Recurse
```

### Intégrer les résultats d'analyse avec GitHub Actions

```powershell
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool GitHub -OutputPath ".\github-annotations.json"
```

### Intégrer les résultats d'analyse avec Azure DevOps

```powershell
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool AzureDevOps -OutputPath ".\azure-devops-issues.json"
```

## Format de résultats unifié

Tous les outils d'analyse utilisent un format de résultats unifié défini dans le module `UnifiedResultsFormat.psm1`. Ce format permet de comparer, fusionner et traiter les résultats de différents outils de manière cohérente.

Chaque résultat d'analyse contient les propriétés suivantes :
- `ToolName` : Nom de l'outil d'analyse (PSScriptAnalyzer, ESLint, Pylint, etc.)
- `FilePath` : Chemin complet du fichier analysé
- `FileName` : Nom du fichier analysé
- `Line` : Numéro de ligne où le problème a été détecté
- `Column` : Numéro de colonne où le problème a été détecté
- `RuleId` : Identifiant de la règle qui a détecté le problème
- `Severity` : Sévérité du problème (Error, Warning, Information)
- `Message` : Description du problème
- `Category` : Catégorie du problème (Style, Performance, Security, etc.)
- `Suggestion` : Suggestion de correction (si disponible)
- `OriginalObject` : Objet original retourné par l'outil d'analyse

## Intégration avec des outils tiers

Le script `Integrate-ThirdPartyTools.ps1` permet d'intégrer les résultats d'analyse avec différents outils tiers :

### SonarQube

Les résultats sont convertis au format SonarQube et peuvent être envoyés à l'API SonarQube pour être affichés dans l'interface web.

### GitHub Actions

Les résultats sont convertis au format d'annotations GitHub Actions et peuvent être utilisés dans un workflow GitHub pour afficher les problèmes directement dans les pull requests.

### Azure DevOps

Les résultats sont convertis au format Azure DevOps et peuvent être utilisés dans un pipeline Azure DevOps pour afficher les problèmes dans les pull requests.

# Exemples d'utilisation du système d'analyse

Ce document présente des exemples concrets d'utilisation du système d'analyse de code.

## Exemples de base

### Analyser un fichier PowerShell avec PSScriptAnalyzer

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\scripts\test.ps1" -Tools PSScriptAnalyzer
```

Cet exemple analyse un fichier PowerShell avec PSScriptAnalyzer et génère un fichier JSON avec les résultats.

### Analyser un répertoire avec PSScriptAnalyzer et TodoAnalyzer

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\scripts" -Tools PSScriptAnalyzer, TodoAnalyzer -Recurse
```

Cet exemple analyse tous les fichiers PowerShell dans le répertoire `.\scripts` et ses sous-répertoires avec PSScriptAnalyzer et TodoAnalyzer.

### Analyser un fichier avec tous les outils disponibles et générer un rapport HTML

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\scripts\test.ps1" -Tools All -GenerateHtmlReport
```

Cet exemple analyse un fichier PowerShell avec tous les outils disponibles et génère un rapport HTML interactif.

### Analyser un répertoire avec tous les outils disponibles, générer un rapport HTML et l'ouvrir

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\scripts" -Tools All -GenerateHtmlReport -OpenReport -Recurse
```

Cet exemple analyse tous les fichiers dans le répertoire `.\scripts` et ses sous-répertoires avec tous les outils disponibles, génère un rapport HTML interactif et l'ouvre dans le navigateur par défaut.

## Exemples avancés

### Analyser un fichier et spécifier le chemin de sortie

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\scripts\test.ps1" -Tools PSScriptAnalyzer -OutputPath ".\results\test-analysis.json"
```

Cet exemple analyse un fichier PowerShell avec PSScriptAnalyzer et génère un fichier JSON avec les résultats à l'emplacement spécifié.

### Analyser un répertoire et filtrer les résultats

```powershell
$results = .\Start-CodeAnalysis.ps1 -Path ".\scripts" -Tools All -Recurse
$errors = $results | Where-Object { $_.Severity -eq "Error" }
$warnings = $results | Where-Object { $_.Severity -eq "Warning" }
$information = $results | Where-Object { $_.Severity -eq "Information" }

Write-Host "Erreurs: $($errors.Count)"
Write-Host "Avertissements: $($warnings.Count)"
Write-Host "Informations: $($information.Count)"
```

Cet exemple analyse tous les fichiers dans le répertoire `.\scripts` et ses sous-répertoires avec tous les outils disponibles, puis filtre les résultats par sévérité.

### Analyser un fichier et intégrer les résultats avec GitHub Actions

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\scripts\test.ps1" -Tools All -OutputPath ".\results\test-analysis.json"
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\test-analysis.json" -Tool GitHub -OutputPath ".\results\github-annotations.json"
```

Cet exemple analyse un fichier PowerShell avec tous les outils disponibles, puis convertit les résultats au format d'annotations GitHub Actions.

### Analyser un répertoire et intégrer les résultats avec SonarQube

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\scripts" -Tools All -OutputPath ".\results\analysis-results.json" -Recurse
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool SonarQube -OutputPath ".\results\sonarqube-issues.json" -ProjectKey "my-project"
```

Cet exemple analyse tous les fichiers dans le répertoire `.\scripts` et ses sous-répertoires avec tous les outils disponibles, puis convertit les résultats au format SonarQube.

### Analyser un répertoire et intégrer les résultats avec Azure DevOps

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\scripts" -Tools All -OutputPath ".\results\analysis-results.json" -Recurse
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool AzureDevOps -OutputPath ".\results\azuredevops-issues.json"
```

Cet exemple analyse tous les fichiers dans le répertoire `.\scripts` et ses sous-répertoires avec tous les outils disponibles, puis convertit les résultats au format Azure DevOps.

## Exemples d'intégration continue

### GitHub Actions

```yaml
name: Code Analysis

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  analyze:
    runs-on: windows-latest
    steps:
    - uses: actions/checkout@v2
    - name: Install dependencies
      run: |
        Install-Module -Name PSScriptAnalyzer -Force
    - name: Analyze code
      run: |
        .\scripts\analysis\Start-CodeAnalysis.ps1 -Path ".\scripts" -Tools All -OutputPath ".\results\analysis-results.json" -Recurse
    - name: Convert results to GitHub format
      run: |
        .\scripts\analysis\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool GitHub -OutputPath ".\results\github-annotations.json"
    - name: Upload results
      uses: actions/upload-artifact@v2
      with:
        name: analysis-results
        path: .\results\github-annotations.json
```

Cet exemple montre comment intégrer le système d'analyse dans un workflow GitHub Actions.

### Azure DevOps

```yaml
trigger:
- main

pool:
  vmImage: 'windows-latest'

steps:
- task: PowerShell@2
  displayName: 'Install dependencies'
  inputs:
    targetType: 'inline'
    script: |
      Install-Module -Name PSScriptAnalyzer -Force

- task: PowerShell@2
  displayName: 'Analyze code'
  inputs:
    targetType: 'inline'
    script: |
      .\scripts\analysis\Start-CodeAnalysis.ps1 -Path ".\scripts" -Tools All -OutputPath ".\results\analysis-results.json" -Recurse

- task: PowerShell@2
  displayName: 'Convert results to Azure DevOps format'
  inputs:
    targetType: 'inline'
    script: |
      .\scripts\analysis\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool AzureDevOps -OutputPath ".\results\azuredevops-issues.json"

- task: PublishBuildArtifacts@1
  displayName: 'Publish analysis results'
  inputs:
    pathtoPublish: '.\results\azuredevops-issues.json'
    artifactName: 'analysis-results'
```

Cet exemple montre comment intégrer le système d'analyse dans un pipeline Azure DevOps.

### Jenkins

```groovy
pipeline {
    agent {
        label 'windows'
    }
    stages {
        stage('Install dependencies') {
            steps {
                powershell '''
                    Install-Module -Name PSScriptAnalyzer -Force
                '''
            }
        }
        stage('Analyze code') {
            steps {
                powershell '''
                    .\\scripts\\analysis\\Start-CodeAnalysis.ps1 -Path ".\\scripts" -Tools All -OutputPath ".\\results\\analysis-results.json" -Recurse
                '''
            }
        }
        stage('Convert results to SonarQube format') {
            steps {
                powershell '''
                    .\\scripts\\analysis\\Integrate-ThirdPartyTools.ps1 -Path ".\\results\\analysis-results.json" -Tool SonarQube -OutputPath ".\\results\\sonarqube-issues.json" -ProjectKey "my-project"
                '''
            }
        }
        stage('Upload results') {
            steps {
                archiveArtifacts artifacts: 'results/sonarqube-issues.json', fingerprint: true
            }
        }
    }
}
```

Cet exemple montre comment intégrer le système d'analyse dans un pipeline Jenkins.

## Exemples de personnalisation

### Ajouter un nouvel outil d'analyse

```powershell
# Ajouter une fonction pour analyser les fichiers avec le nouvel outil
function Invoke-MyAnalyzerAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    Write-Verbose "Analyse de '$FilePath' avec MyAnalyzer..."
    
    # Vérifier si MyAnalyzer est disponible
    $myAnalyzer = Get-Command -Name myanalyzer -ErrorAction SilentlyContinue
    if ($null -eq $myAnalyzer) {
        Write-Warning "MyAnalyzer n'est pas disponible. Installez-le avec 'npm install -g myanalyzer'."
        return @()
    }
    
    # Exécuter MyAnalyzer
    try {
        $output = & $myAnalyzer.Source --format json $FilePath 2>&1
        
        # Convertir la sortie JSON en objet PowerShell
        $results = $output | ConvertFrom-Json
        
        # Convertir les résultats vers le format unifié
        $unifiedResults = @()
        
        foreach ($result in $results) {
            $unifiedResult = New-UnifiedAnalysisResult -ToolName "MyAnalyzer" `
                                                      -FilePath $FilePath `
                                                      -Line $result.line `
                                                      -Column $result.column `
                                                      -RuleId $result.rule_id `
                                                      -Severity $result.severity `
                                                      -Message $result.message `
                                                      -Category $result.category `
                                                      -OriginalObject $result
            
            $unifiedResults += $unifiedResult
        }
        
        return $unifiedResults
    }
    catch {
        Write-Warning "Erreur lors de l'analyse avec MyAnalyzer: $_"
        return @()
    }
}

# Modifier la fonction Invoke-FileAnalysis pour utiliser le nouvel outil
function Invoke-FileAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $true)]
        [string[]]$Tools
    )
    
    $results = @()
    
    # Déterminer les outils à utiliser
    $useAll = $Tools -contains "All"
    $usePSScriptAnalyzer = $useAll -or ($Tools -contains "PSScriptAnalyzer")
    $useESLint = $useAll -or ($Tools -contains "ESLint")
    $usePylint = $useAll -or ($Tools -contains "Pylint")
    $useTodoAnalyzer = $useAll -or ($Tools -contains "TodoAnalyzer")
    $useMyAnalyzer = $useAll -or ($Tools -contains "MyAnalyzer") # Ajouter le nouvel outil
    
    # ... code existant ...
    
    # Analyser avec MyAnalyzer si applicable
    if ($useMyAnalyzer) {
        $myAnalyzerResults = Invoke-MyAnalyzerAnalysis -FilePath $FilePath
        $results += $myAnalyzerResults
    }
    
    return $results
}
```

Cet exemple montre comment ajouter un nouvel outil d'analyse au système d'analyse.

### Ajouter un nouveau format de résultats

```powershell
# Ajouter une fonction pour convertir les résultats vers le nouveau format
function ConvertTo-MyFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Results
    )
    
    $myFormatResults = @()
    
    foreach ($result in $Results) {
        $myFormatResult = @{
            file = $result.FilePath
            line = $result.Line
            column = $result.Column
            rule = $result.RuleId
            severity = $result.Severity
            message = $result.Message
            category = $result.Category
        }
        
        $myFormatResults += $myFormatResult
    }
    
    return @{
        results = $myFormatResults
        count = $myFormatResults.Count
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
    }
}

# Modifier le script principal pour utiliser le nouveau format
# Convertir les résultats vers le format approprié
try {
    $convertedResults = switch ($Tool) {
        "SonarQube" {
            if (-not $ProjectKey) {
                throw "Le paramètre ProjectKey est requis pour l'intégration avec SonarQube."
            }
            
            ConvertTo-SonarQubeFormat -Results $results -ProjectKey $ProjectKey
        }
        "GitHub" {
            ConvertTo-GitHubFormat -Results $results
        }
        "AzureDevOps" {
            ConvertTo-AzureDevOpsFormat -Results $results
        }
        "MyFormat" { # Ajouter le nouveau format
            ConvertTo-MyFormat -Results $results
        }
        default {
            throw "Format non pris en charge: $Tool"
        }
    }
    
    # ... code existant ...
}
```

Cet exemple montre comment ajouter un nouveau format de résultats au système d'analyse.

## Conclusion

Ces exemples montrent comment utiliser le système d'analyse de code dans différents scénarios. Vous pouvez les adapter à vos besoins spécifiques pour améliorer la qualité de votre code.

# Exemples d'utilisation du systÃ¨me d'analyse

Ce document prÃ©sente des exemples concrets d'utilisation du systÃ¨me d'analyse de code.

## Exemples de base

### Analyser un fichier PowerShell avec PSScriptAnalyzer

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts\test.ps1" -Tools PSScriptAnalyzer
```plaintext
Cet exemple analyse un fichier PowerShell avec PSScriptAnalyzer et gÃ©nÃ¨re un fichier JSON avec les rÃ©sultats.

### Analyser un rÃ©pertoire avec PSScriptAnalyzer et TodoAnalyzer

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools PSScriptAnalyzer, TodoAnalyzer -Recurse
```plaintext
Cet exemple analyse tous les fichiers PowerShell dans le rÃ©pertoire `.\development\scripts` et ses sous-rÃ©pertoires avec PSScriptAnalyzer et TodoAnalyzer.

### Analyser un fichier avec tous les outils disponibles et gÃ©nÃ©rer un rapport HTML

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts\test.ps1" -Tools All -GenerateHtmlReport
```plaintext
Cet exemple analyse un fichier PowerShell avec tous les outils disponibles et gÃ©nÃ¨re un rapport HTML interactif.

### Analyser un rÃ©pertoire avec tous les outils disponibles, gÃ©nÃ©rer un rapport HTML et l'ouvrir

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools All -GenerateHtmlReport -OpenReport -Recurse
```plaintext
Cet exemple analyse tous les fichiers dans le rÃ©pertoire `.\development\scripts` et ses sous-rÃ©pertoires avec tous les outils disponibles, gÃ©nÃ¨re un rapport HTML interactif et l'ouvre dans le navigateur par dÃ©faut.

## Exemples avancÃ©s

### Analyser un fichier et spÃ©cifier le chemin de sortie

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts\test.ps1" -Tools PSScriptAnalyzer -OutputPath ".\results\test-analysis.json"
```plaintext
Cet exemple analyse un fichier PowerShell avec PSScriptAnalyzer et gÃ©nÃ¨re un fichier JSON avec les rÃ©sultats Ã  l'emplacement spÃ©cifiÃ©.

### Analyser un rÃ©pertoire et filtrer les rÃ©sultats

```powershell
$results = .\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools All -Recurse
$errors = $results | Where-Object { $_.Severity -eq "Error" }
$warnings = $results | Where-Object { $_.Severity -eq "Warning" }
$information = $results | Where-Object { $_.Severity -eq "Information" }

Write-Host "Erreurs: $($errors.Count)"
Write-Host "Avertissements: $($warnings.Count)"
Write-Host "Informations: $($information.Count)"
```plaintext
Cet exemple analyse tous les fichiers dans le rÃ©pertoire `.\development\scripts` et ses sous-rÃ©pertoires avec tous les outils disponibles, puis filtre les rÃ©sultats par sÃ©vÃ©ritÃ©.

### Analyser un fichier et intÃ©grer les rÃ©sultats avec GitHub Actions

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts\test.ps1" -Tools All -OutputPath ".\results\test-analysis.json"
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\test-analysis.json" -Tool GitHub -OutputPath ".\results\github-annotations.json"
```plaintext
Cet exemple analyse un fichier PowerShell avec tous les outils disponibles, puis convertit les rÃ©sultats au format d'annotations GitHub Actions.

### Analyser un rÃ©pertoire et intÃ©grer les rÃ©sultats avec SonarQube

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools All -OutputPath ".\results\analysis-results.json" -Recurse
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool SonarQube -OutputPath ".\results\sonarqube-issues.json" -ProjectKey "my-project"
```plaintext
Cet exemple analyse tous les fichiers dans le rÃ©pertoire `.\development\scripts` et ses sous-rÃ©pertoires avec tous les outils disponibles, puis convertit les rÃ©sultats au format SonarQube.

### Analyser un rÃ©pertoire et intÃ©grer les rÃ©sultats avec Azure DevOps

```powershell
.\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools All -OutputPath ".\results\analysis-results.json" -Recurse
.\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool AzureDevOps -OutputPath ".\results\azuredevops-issues.json"
```plaintext
Cet exemple analyse tous les fichiers dans le rÃ©pertoire `.\development\scripts` et ses sous-rÃ©pertoires avec tous les outils disponibles, puis convertit les rÃ©sultats au format Azure DevOps.

## Exemples d'intÃ©gration continue

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
        .\development\scripts\analysis\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools All -OutputPath ".\results\analysis-results.json" -Recurse
    - name: Convert results to GitHub format
      run: |
        .\development\scripts\analysis\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool GitHub -OutputPath ".\results\github-annotations.json"
    - name: Upload results
      uses: actions/upload-artifact@v2
      with:
        name: analysis-results
        path: .\results\github-annotations.json
```plaintext
Cet exemple montre comment intÃ©grer le systÃ¨me d'analyse dans un workflow GitHub Actions.

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
      .\development\scripts\analysis\Start-CodeAnalysis.ps1 -Path ".\development\scripts" -Tools All -OutputPath ".\results\analysis-results.json" -Recurse

- task: PowerShell@2
  displayName: 'Convert results to Azure DevOps format'
  inputs:
    targetType: 'inline'
    script: |
      .\development\scripts\analysis\Integrate-ThirdPartyTools.ps1 -Path ".\results\analysis-results.json" -Tool AzureDevOps -OutputPath ".\results\azuredevops-issues.json"

- task: PublishBuildArtifacts@1
  displayName: 'Publish analysis results'
  inputs:
    pathtoPublish: '.\results\azuredevops-issues.json'
    artifactName: 'analysis-results'
```plaintext
Cet exemple montre comment intÃ©grer le systÃ¨me d'analyse dans un pipeline Azure DevOps.

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
```plaintext
Cet exemple montre comment intÃ©grer le systÃ¨me d'analyse dans un pipeline Jenkins.

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
    
    # VÃ©rifier si MyAnalyzer est disponible

    $myAnalyzer = Get-Command -Name myanalyzer -ErrorAction SilentlyContinue
    if ($null -eq $myAnalyzer) {
        Write-Warning "MyAnalyzer n'est pas disponible. Installez-le avec 'npm install -g myanalyzer'."
        return @()
    }
    
    # ExÃ©cuter MyAnalyzer

    try {
        $output = & $myAnalyzer.Source --format json $FilePath 2>&1
        
        # Convertir la sortie JSON en objet PowerShell

        $results = $output | ConvertFrom-Json
        
        # Convertir les rÃ©sultats vers le format unifiÃ©

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
    
    # DÃ©terminer les outils Ã  utiliser

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
```plaintext
Cet exemple montre comment ajouter un nouvel outil d'analyse au systÃ¨me d'analyse.

### Ajouter un nouveau format de rÃ©sultats

```powershell
# Ajouter une fonction pour convertir les rÃ©sultats vers le nouveau format

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

# Convertir les rÃ©sultats vers le format appropriÃ©

try {
    $convertedResults = switch ($Tool) {
        "SonarQube" {
            if (-not $ProjectKey) {
                throw "Le paramÃ¨tre ProjectKey est requis pour l'intÃ©gration avec SonarQube."
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
```plaintext
Cet exemple montre comment ajouter un nouveau format de rÃ©sultats au systÃ¨me d'analyse.

## Conclusion

Ces exemples montrent comment utiliser le systÃ¨me d'analyse de code dans diffÃ©rents scÃ©narios. Vous pouvez les adapter Ã  vos besoins spÃ©cifiques pour amÃ©liorer la qualitÃ© de votre code.

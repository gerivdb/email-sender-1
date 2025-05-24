<#
.SYNOPSIS
    Initialise un environnement de test pour l'analyse des pull requests.
.DESCRIPTION
    Ce script crÃƒÂ©e un environnement de test isolÃƒÂ© pour tester le systÃƒÂ¨me d'analyse des pull requests.
    Il configure un dÃƒÂ©pÃƒÂ´t Git local, crÃƒÂ©e des fichiers PowerShell de rÃƒÂ©fÃƒÂ©rence avec des erreurs connues,
    et configure les webhooks nÃƒÂ©cessaires pour l'intÃƒÂ©gration.
.PARAMETER TestRepoPath
    Chemin oÃƒÂ¹ le dÃƒÂ©pÃƒÂ´t de test sera crÃƒÂ©ÃƒÂ©. Par dÃƒÂ©faut, un rÃƒÂ©pertoire temporaire est utilisÃƒÂ©.
.PARAMETER ErrorPatterns
    Nombre de patterns d'erreurs ÃƒÂ  inclure dans les fichiers de test. Par dÃƒÂ©faut, 10.
.PARAMETER CleanExisting
    Si spÃƒÂ©cifiÃƒÂ©, supprime le dÃƒÂ©pÃƒÂ´t de test existant s'il existe dÃƒÂ©jÃƒÂ .
.EXAMPLE
    .\Initialize-TestEnvironment.ps1 -TestRepoPath "D:\TestRepo" -ErrorPatterns 20 -CleanExisting
.NOTES
    Auteur: Augment Code
    Date: 15/04/2025
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter()]
    [string]$TestRepoPath = (Join-Path -Path $env:TEMP -ChildPath "PR-Analysis-TestRepo"),
    
    [Parameter()]
    [int]$ErrorPatterns = 10,
    
    [Parameter()]
    [switch]$CleanExisting
)

# Importer les modules nÃƒÂ©cessaires
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# VÃƒÂ©rifier si Git est installÃƒÂ©
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Git n'est pas installÃƒÂ© ou n'est pas dans le PATH."
    exit 1
}

# Fonction pour crÃƒÂ©er un fichier PowerShell avec des erreurs connues
function New-PowerShellFileWithErrors {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [int]$ErrorCount = 5,
        
        [Parameter()]
        [string[]]$ErrorTypes = @(
            "NullReference",
            "IndexOutOfRange",
            "TypeConversion",
            "UninitializedVariable",
            "DivisionByZero",
            "MissingProperty",
            "MissingParameter",
            "UndeclaredVariable",
            "IncorrectComparison",
            "ResourceLeak"
        )
    )
    
    # CrÃƒÂ©er le contenu du fichier
    $content = @"
<#
.SYNOPSIS
    Fichier PowerShell de test avec des erreurs connues.
.DESCRIPTION
    Ce fichier contient des erreurs PowerShell connues pour tester le systÃƒÂ¨me d'analyse des pull requests.
    Il a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ© automatiquement par le script Initialize-TestEnvironment.ps1.
.NOTES
    GÃƒÂ©nÃƒÂ©rÃƒÂ© le: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Nombre d'erreurs: $ErrorCount
#>

# Fonctions et variables globales
`$global:testConfig = @{
    MaxRetries = 3
    Timeout = 30
    LogLevel = "Verbose"
}

function Write-TestLog {
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Message,
        
        [Parameter()]
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]`$Level = "Info"
    )
    
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "`$timestamp [`$Level] `$Message"
}

"@
    
    # Ajouter des erreurs spÃƒÂ©cifiques en fonction des types d'erreurs demandÃƒÂ©s
    $errorFunctions = @()
    
    for ($i = 1; $i -le $ErrorCount; $i++) {
        $errorType = $ErrorTypes[$i % $ErrorTypes.Count]
        $functionName = "Test-$errorType$i"
        
        $errorFunction = switch ($errorType) {
            "NullReference" {
@"

function $functionName {
    # Erreur: RÃƒÂ©fÃƒÂ©rence nulle
    `$user = `$null
    `$name = `$user.Name  # Erreur potentielle: rÃƒÂ©fÃƒÂ©rence nulle
    return `$name
}
"@
            }
            "IndexOutOfRange" {
@"

function $functionName {
    # Erreur: Index hors limites
    `$array = @(1, 2, 3)
    `$value = `$array[5]  # Erreur potentielle: index hors limites
    return `$value
}
"@
            }
            "TypeConversion" {
@"

function $functionName {
    # Erreur: Conversion de type
    `$input = "abc"
    `$number = [int]`$input  # Erreur potentielle: conversion de type
    return `$number
}
"@
            }
            "UninitializedVariable" {
@"

function $functionName {
    # Erreur: Variable non initialisÃƒÂ©e
    `$result = `$total + 10  # Erreur potentielle: `$total n'est pas initialisÃƒÂ©
    return `$result
}
"@
            }
            "DivisionByZero" {
@"

function $functionName {
    # Erreur: Division par zÃƒÂ©ro
    `$divisor = 0
    `$quotient = 10 / `$divisor  # Erreur potentielle: division par zÃƒÂ©ro
    return `$quotient
}
"@
            }
            "MissingProperty" {
@"

function $functionName {
    # Erreur: AccÃƒÂ¨s ÃƒÂ  une propriÃƒÂ©tÃƒÂ© inexistante
    `$obj = New-Object PSObject
    `$value = `$obj.MissingProperty  # Erreur potentielle: propriÃƒÂ©tÃƒÂ© inexistante
    return `$value
}
"@
            }
            "MissingParameter" {
@"

function $functionName {
    # Erreur: Appel de fonction avec des paramÃƒÂ¨tres manquants
    function Get-Test {
        param (
            [Parameter(Mandatory = `$true)]
            [string]`$Name
        )
        return "Hello, `$Name!"
    }
    
    `$result = Get-Test  # Erreur potentielle: paramÃƒÂ¨tre obligatoire manquant
    return `$result
}
"@
            }
            "UndeclaredVariable" {
@"

function $functionName {
    # Erreur: Utilisation d'une variable non dÃƒÂ©clarÃƒÂ©e
    `$result = `$undeclaredVariable * 2  # Erreur potentielle: variable non dÃƒÂ©clarÃƒÂ©e
    return `$result
}
"@
            }
            "IncorrectComparison" {
@"

function $functionName {
    # Erreur: Comparaison incorrecte
    `$value = "10"
    if (`$value > 5) {  # Erreur potentielle: comparaison de types diffÃƒÂ©rents
        return `$true
    }
    return `$false
}
"@
            }
            "ResourceLeak" {
@"

function $functionName {
    # Erreur: Fuite de ressources
    `$stream = [System.IO.File]::OpenRead("C:\temp\test.txt")
    `$content = [System.IO.StreamReader]::new(`$stream).ReadToEnd()
    # Erreur potentielle: le stream n'est pas fermÃƒÂ© avec `$stream.Close() ou `$stream.Dispose()
    return `$content
}
"@
            }
            default {
@"

function $functionName {
    # Erreur gÃƒÂ©nÃƒÂ©rique
    Write-Host "Fonction avec erreur potentielle"
    return `$null
}
"@
            }
        }
        
        $errorFunctions += $errorFunction
    }
    
    # Ajouter les fonctions d'erreur au contenu
    $content += [string]::Join("`n", $errorFunctions)
    
    # Ajouter une fonction principale qui appelle toutes les fonctions d'erreur
    $content += @"

function Test-AllErrors {
    Write-TestLog "DÃƒÂ©marrage des tests d'erreurs..."
    
    try {

"@
    
    for ($i = 1; $i -le $ErrorCount; $i++) {
        $errorType = $ErrorTypes[$i % $ErrorTypes.Count]
        $functionName = "Test-$errorType$i"
        
        $content += @"
        try {
            `$result = $functionName
            Write-TestLog "Test $functionName terminÃƒÂ© avec rÃƒÂ©sultat: `$result" -Level "Info"
        } catch {
            Write-TestLog "Erreur dans $functionName: `$_" -Level "Error"
        }

"@
    }
    
    $content += @"
        Write-TestLog "Tous les tests d'erreurs sont terminÃƒÂ©s." -Level "Info"
    } catch {
        Write-TestLog "Erreur gÃƒÂ©nÃƒÂ©rale: `$_" -Level "Error"
    }
}

# Appeler la fonction principale si le script est exÃƒÂ©cutÃƒÂ© directement
if (`$MyInvocation.InvocationName -ne '.') {
    Test-AllErrors
}
"@
    
    # Ãƒâ€°crire le contenu dans le fichier
    $content | Out-File -FilePath $FilePath -Encoding utf8
    
    Write-Verbose "Fichier PowerShell avec $ErrorCount erreurs crÃƒÂ©ÃƒÂ©: $FilePath"
}

# Fonction pour crÃƒÂ©er un fichier PowerShell sans erreurs
function New-CleanPowerShellFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter()]
        [int]$FunctionCount = 5
    )
    
    # CrÃƒÂ©er le contenu du fichier
    $content = @"
<#
.SYNOPSIS
    Fichier PowerShell de test sans erreurs.
.DESCRIPTION
    Ce fichier contient des fonctions PowerShell sans erreurs pour tester le systÃƒÂ¨me d'analyse des pull requests.
    Il a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ© automatiquement par le script Initialize-TestEnvironment.ps1.
.NOTES
    GÃƒÂ©nÃƒÂ©rÃƒÂ© le: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Nombre de fonctions: $FunctionCount
#>

# Fonctions et variables globales
`$global:testConfig = @{
    MaxRetries = 3
    Timeout = 30
    LogLevel = "Verbose"
}

function Write-TestLog {
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Message,
        
        [Parameter()]
        [ValidateSet("Info", "Warning", "Error", "Debug")]
        [string]`$Level = "Info"
    )
    
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "`$timestamp [`$Level] `$Message"
}

"@
    
    # Ajouter des fonctions sans erreurs
    $cleanFunctions = @()
    
    for ($i = 1; $i -le $FunctionCount; $i++) {
        $functionName = "Test-CleanFunction$i"
        
        $cleanFunction = @"

function $functionName {
    param (
        [Parameter()]
        [string]`$InputValue = "Default"
    )
    
    # Fonction sans erreurs
    `$result = "Processed: `$InputValue"
    Write-TestLog "Fonction $functionName exÃƒÂ©cutÃƒÂ©e avec succÃƒÂ¨s" -Level "Info"
    return `$result
}
"@
        
        $cleanFunctions += $cleanFunction
    }
    
    # Ajouter les fonctions sans erreurs au contenu
    $content += [string]::Join("`n", $cleanFunctions)
    
    # Ajouter une fonction principale qui appelle toutes les fonctions sans erreurs
    $content += @"

function Test-AllCleanFunctions {
    Write-TestLog "DÃƒÂ©marrage des tests des fonctions sans erreurs..."
    
    try {

"@
    
    for ($i = 1; $i -le $FunctionCount; $i++) {
        $functionName = "Test-CleanFunction$i"
        
        $content += @"
        `$result = $functionName -InputValue "Test$i"
        Write-TestLog "Test $functionName terminÃƒÂ© avec rÃƒÂ©sultat: `$result" -Level "Info"

"@
    }
    
    $content += @"
        Write-TestLog "Tous les tests des fonctions sans erreurs sont terminÃƒÂ©s." -Level "Info"
    } catch {
        Write-TestLog "Erreur gÃƒÂ©nÃƒÂ©rale: `$_" -Level "Error"
    }
}

# Appeler la fonction principale si le script est exÃƒÂ©cutÃƒÂ© directement
if (`$MyInvocation.InvocationName -ne '.') {
    Test-AllCleanFunctions
}
"@
    
    # Ãƒâ€°crire le contenu dans le fichier
    $content | Out-File -FilePath $FilePath -Encoding utf8
    
    Write-Verbose "Fichier PowerShell sans erreurs crÃƒÂ©ÃƒÂ©: $FilePath"
}

# Fonction pour crÃƒÂ©er un fichier de configuration pour les webhooks
function New-WebhookConfigFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $content = @"
{
    "webhooks": [
        {
            "id": "pr-analysis",
            "url": "http://localhost:8080/api/webhooks/github/pr-analysis",
            "contentType": "json",
            "secret": "test-webhook-secret",
            "events": ["pull_request.opened", "pull_request.synchronize", "pull_request.reopened"]
        },
        {
            "id": "commit-analysis",
            "url": "http://localhost:8080/api/webhooks/github/commit-analysis",
            "contentType": "json",
            "secret": "test-webhook-secret",
            "events": ["push"]
        }
    ]
}
"@
    
    $content | Out-File -FilePath $FilePath -Encoding utf8
    
    Write-Verbose "Fichier de configuration des webhooks crÃƒÂ©ÃƒÂ©: $FilePath"
}

# Fonction pour crÃƒÂ©er un fichier de configuration pour GitHub Actions
function New-GitHubActionsConfigFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    $content = @"
name: PR Analysis Test

on:
  pull_request:
    branches: [ main ]
    types: [ opened, synchronize, reopened ]
    paths:
      - '**/*.ps1'
      - '**/*.psm1'
      - '**/*.psd1'

jobs:
  analyze:
    name: Analyze Pull Request
    runs-on: windows-latest
    
    steps:
      - name: Checkout repository
        uses: actions/checkout@v3
        with:
          fetch-depth: 0
        
      - name: Set up PowerShell
        uses: actions/setup-powershell@v1
        with:
          powershell-version: '7.2'
      
      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.10'
      
      - name: Install Python dependencies
        run: |
          python -m pip install --upgrade pip
          pip install requests
      
      - name: Install PSScriptAnalyzer
        shell: pwsh
        run: |
          Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser
      
      - name: Analyze Pull Request
        shell: pwsh
        run: |
          `$prNumber = `${{ github.event.pull_request.number }}
          
          # ExÃƒÂ©cuter l'analyse
          .\git-hooks\Analyze-PullRequest.ps1 -Action Comment -PullRequestNumber `$prNumber
      
      - name: Upload Analysis Report
        uses: actions/upload-artifact@v3
        with:
          name: pr-analysis-report
          path: git-hooks/reports/pr-*.md
"@
    
    $content | Out-File -FilePath $FilePath -Encoding utf8
    
    Write-Verbose "Fichier de configuration GitHub Actions crÃƒÂ©ÃƒÂ©: $FilePath"
}

# VÃƒÂ©rifier si le rÃƒÂ©pertoire de test existe dÃƒÂ©jÃƒÂ 
if (Test-Path -Path $TestRepoPath) {
    if ($CleanExisting) {
        if ($PSCmdlet.ShouldProcess($TestRepoPath, "Supprimer le rÃƒÂ©pertoire de test existant")) {
            Write-Verbose "Suppression du rÃƒÂ©pertoire de test existant: $TestRepoPath"
            Remove-Item -Path $TestRepoPath -Recurse -Force
        }
    } else {
        Write-Error "Le rÃƒÂ©pertoire de test existe dÃƒÂ©jÃƒÂ : $TestRepoPath. Utilisez -CleanExisting pour le supprimer."
        exit 1
    }
}

# CrÃƒÂ©er le rÃƒÂ©pertoire de test
if ($PSCmdlet.ShouldProcess($TestRepoPath, "CrÃƒÂ©er le rÃƒÂ©pertoire de test")) {
    Write-Verbose "CrÃƒÂ©ation du rÃƒÂ©pertoire de test: $TestRepoPath"
    New-Item -Path $TestRepoPath -ItemType Directory -Force | Out-Null
}

# Initialiser le dÃƒÂ©pÃƒÂ´t Git
if ($PSCmdlet.ShouldProcess($TestRepoPath, "Initialiser le dÃƒÂ©pÃƒÂ´t Git")) {
    Write-Verbose "Initialisation du dÃƒÂ©pÃƒÂ´t Git dans: $TestRepoPath"
    Push-Location $TestRepoPath
    try {
        git init
        
        # CrÃƒÂ©er un fichier README.md
        @"
# PR Analysis Test Repository

Ce dÃƒÂ©pÃƒÂ´t est utilisÃƒÂ© pour tester le systÃƒÂ¨me d'analyse des pull requests.

## Structure du dÃƒÂ©pÃƒÂ´t

- `development/scripts/` : Contient des scripts PowerShell avec et sans erreurs
- `.github/workflows/` : Contient les workflows GitHub Actions
- `projet/config/` : Contient les fichiers de configuration

## Utilisation

Ce dÃƒÂ©pÃƒÂ´t est gÃƒÂ©nÃƒÂ©rÃƒÂ© automatiquement par le script `Initialize-TestEnvironment.ps1`.
"@ | Out-File -FilePath "README.md" -Encoding utf8
        
        # CrÃƒÂ©er les rÃƒÂ©pertoires nÃƒÂ©cessaires
        New-Item -Path "scripts" -ItemType Directory -Force | Out-Null
        New-Item -Path "development/scripts/with-errors" -ItemType Directory -Force | Out-Null
        New-Item -Path "development/scripts/clean" -ItemType Directory -Force | Out-Null
        New-Item -Path ".github/workflows" -ItemType Directory -Force | Out-Null
        New-Item -Path "config" -ItemType Directory -Force | Out-Null
        New-Item -Path "git-hooks" -ItemType Directory -Force | Out-Null
        New-Item -Path "git-hooks/reports" -ItemType Directory -Force | Out-Null
        
        # CrÃƒÂ©er des fichiers PowerShell avec des erreurs
        for ($i = 1; $i -le $ErrorPatterns; $i++) {
            $filePath = "development/scripts/with-errors/Test-Errors$i.ps1"
            New-PowerShellFileWithErrors -FilePath $filePath -ErrorCount (Get-Random -Minimum 3 -Maximum 8)
        }
        
        # CrÃƒÂ©er des fichiers PowerShell sans erreurs
        for ($i = 1; $i -le 5; $i++) {
            $filePath = "development/scripts/clean/Test-Clean$i.ps1"
            New-CleanPowerShellFile -FilePath $filePath -FunctionCount (Get-Random -Minimum 3 -Maximum 8)
        }
        
        # CrÃƒÂ©er un fichier de configuration pour les webhooks
        New-WebhookConfigFile -FilePath "projet/config/webhooks.json"
        
        # CrÃƒÂ©er un fichier de configuration pour GitHub Actions
        New-GitHubActionsConfigFile -FilePath ".github/workflows/pr-analysis.yml"
        
        # Copier les scripts d'analyse des pull requests
        $sourceDir = Join-Path -Path (git rev-parse --show-toplevel) -ChildPath "git-hooks"
        if (Test-Path -Path $sourceDir) {
            Write-Verbose "Copie des scripts d'analyse des pull requests depuis: $sourceDir"
            Copy-Item -Path "$sourceDir\Analyze-PullRequest.ps1" -Destination "git-hooks\" -Force
            
            $sourcePythonDir = Join-Path -Path (git rev-parse --show-toplevel) -ChildPath "scripts\journal\web"
            if (Test-Path -Path $sourcePythonDir) {
                Write-Verbose "Copie du script Python d'intÃƒÂ©gration depuis: $sourcePythonDir"
                Copy-Item -Path "$sourcePythonDir\pr_integration.py" -Destination "scripts\" -Force
            }
        }
        
        # Faire un commit initial
        git add .
        git config user.email "test@example.com"
        git config user.name "Test User"
        git commit -m "Initial commit"
        
        Write-Verbose "DÃƒÂ©pÃƒÂ´t Git initialisÃƒÂ© avec succÃƒÂ¨s dans: $TestRepoPath"
    } finally {
        Pop-Location
    }
}

Write-Host "Environnement de test crÃƒÂ©ÃƒÂ© avec succÃƒÂ¨s dans: $TestRepoPath" -ForegroundColor Green
Write-Host "Nombre de fichiers PowerShell avec erreurs: $ErrorPatterns" -ForegroundColor Cyan
Write-Host "Nombre de fichiers PowerShell sans erreurs: 5" -ForegroundColor Cyan
Write-Host ""
Write-Host "Pour utiliser cet environnement de test:" -ForegroundColor Yellow
Write-Host "1. AccÃƒÂ©dez au rÃƒÂ©pertoire: cd $TestRepoPath" -ForegroundColor Yellow
Write-Host "2. CrÃƒÂ©ez une branche pour les tests: git checkout -b test-branch" -ForegroundColor Yellow
Write-Host "3. Modifiez les fichiers et crÃƒÂ©ez des commits" -ForegroundColor Yellow
Write-Host "4. Poussez la branche et crÃƒÂ©ez une pull request" -ForegroundColor Yellow


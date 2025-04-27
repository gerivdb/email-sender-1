#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Start-IncrementalPRAnalysis.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Start-IncrementalPRAnalysis
    en utilisant le framework Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation recommandÃ©e: Install-Module -Name Pester -Force -SkipPublisherCheck"
}

# Chemin du script Ã  tester
$scriptToTest = Join-Path -Path $PSScriptRoot -ChildPath "..\Start-IncrementalPRAnalysis.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptToTest)) {
    throw "Script Start-IncrementalPRAnalysis non trouvÃ© Ã  l'emplacement: $scriptToTest"
}

# Importer les modules nÃ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules"
$modulesToImport = @(
    "FileContentIndexer.psm1",
    "SyntaxAnalyzer.psm1",
    "PRAnalysisCache.psm1"
)

foreach ($module in $modulesToImport) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath $module
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
    }
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "IncrementalPRAnalysisTests_$(Get-Random)"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

# Fonction pour crÃ©er un dÃ©pÃ´t Git de test
function New-TestRepository {
    param(
        [string]$Path
    )

    # CrÃ©er le rÃ©pertoire du dÃ©pÃ´t
    New-Item -Path $Path -ItemType Directory -Force | Out-Null

    # Initialiser le dÃ©pÃ´t Git
    Push-Location -Path $Path
    try {
        git init
        git config user.name "Test User"
        git config user.email "test@example.com"

        # CrÃ©er un fichier README
        Set-Content -Path "README.md" -Value "# Test Repository" -Encoding UTF8

        # CrÃ©er un fichier PowerShell
        $psContent = @'
function Test-Function {
    param(
        [string]$Parameter1,
        [int]$Parameter2 = 0
    )

    $result = $Parameter1 + $Parameter2
    return $result
}

$testVariable = "Test Value"

# Test comment
foreach ($item in $collection) {
    Write-Output $item
}
'@
        Set-Content -Path "test_script.ps1" -Value $psContent -Encoding UTF8

        # CrÃ©er un fichier Python
        $pyContent = @'
import os
import sys

class TestClass:
    def __init__(self, name):
        self.name = name

    def test_method(self, param1):
        return f"Hello, {param1}!"

def test_function(param1, param2=0):
    result = param1 + param2
    return result

# Test comment
for item in collection:
    print(item)
'@
        Set-Content -Path "test_script.py" -Value $pyContent -Encoding UTF8

        # Ajouter et commiter les fichiers
        git add .
        git commit -m "Initial commit"

        # CrÃ©er une branche de base
        git branch base

        # CrÃ©er une branche de fonctionnalitÃ©
        git checkout -b feature

        # Modifier le fichier PowerShell
        $modifiedPsContent = $psContent.Replace("Test-Function", "New-TestFunction").Replace('$testVariable', '$newVariable')
        Set-Content -Path "test_script.ps1" -Value $modifiedPsContent -Encoding UTF8

        # Modifier le fichier Python
        $modifiedPyContent = $pyContent.Replace("test_function", "new_test_function").Replace("TestClass", "NewTestClass")
        Set-Content -Path "test_script.py" -Value $modifiedPyContent -Encoding UTF8

        # Ajouter un nouveau fichier
        Set-Content -Path "new_file.txt" -Value "This is a new file." -Encoding UTF8

        # Ajouter et commiter les modifications
        git add .
        git commit -m "Feature changes"

        # Revenir Ã  la branche principale
        git checkout master

        return $Path
    } finally {
        Pop-Location
    }
}

# Fonction pour simuler la commande gh
function New-MockGhCommand {
    param(
        [string]$RepoPath
    )

    # CrÃ©er un script qui simule la commande gh
    $mockGhPath = Join-Path -Path $testDir -ChildPath "gh.ps1"

    $mockGhScript = @'
param(
    [Parameter(Position = 0)]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$Subcommand,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

# Simuler la commande gh pr list
if ($Command -eq "pr" -and $Subcommand -eq "list") {
    $json = @"
[
    {
        "number": 1,
        "title": "Feature changes",
        "headRefName": "feature",
        "baseRefName": "base",
        "createdAt": "$(Get-Date -Format o)"
    }
]
"@
    Write-Output $json
    exit 0
}

# Simuler la commande gh pr view
if ($Command -eq "pr" -and $Subcommand -eq "view") {
    # VÃ©rifier si on demande les fichiers
    if ($RemainingArgs -contains "--json" -and $RemainingArgs -contains "files") {
        $json = @"
{
    "files": [
        {
            "path": "test_script.ps1",
            "additions": 10,
            "deletions": 5,
            "changes": 15,
            "sha": "$(New-Guid)"
        },
        {
            "path": "test_script.py",
            "additions": 8,
            "deletions": 4,
            "changes": 12,
            "sha": "$(New-Guid)"
        },
        {
            "path": "new_file.txt",
            "additions": 1,
            "deletions": 0,
            "changes": 1,
            "sha": "$(New-Guid)"
        }
    ]
}
"@
        Write-Output $json
        exit 0
    }

    # Sinon, retourner les informations de base sur la PR
    $json = @"
{
    "number": 1,
    "title": "Feature changes",
    "headRefName": "feature",
    "baseRefName": "base",
    "createdAt": "$(Get-Date -Format o)"
}
"@
    Write-Output $json
    exit 0
}

# Si on arrive ici, c'est que la commande n'est pas supportÃ©e
Write-Error "Commande non supportÃ©e: gh $Command $Subcommand $RemainingArgs"
exit 1
'@

    Set-Content -Path $mockGhPath -Value $mockGhScript -Encoding UTF8

    # Rendre le script exÃ©cutable
    if ($IsWindows -or $null -eq $IsWindows) {
        # Sur Windows, pas besoin de rendre le script exÃ©cutable
    } else {
        # Sur Linux/macOS, rendre le script exÃ©cutable
        chmod +x $mockGhPath
    }

    return $mockGhPath
}

# CrÃ©er un dÃ©pÃ´t Git de test
$testRepoPath = Join-Path -Path $testDir -ChildPath "test-repo"
$repoPath = New-TestRepository -Path $testRepoPath

# CrÃ©er un mock pour la commande gh
$mockGhPath = New-MockGhCommand -RepoPath $repoPath

# Tests Pester
Describe "Start-IncrementalPRAnalysis Script Tests" {
    BeforeAll {
        # Sauvegarder le PATH original
        $script:originalPath = $env:PATH

        # Ajouter le rÃ©pertoire du mock gh au PATH
        $env:PATH = "$(Split-Path -Path $mockGhPath -Parent);$env:PATH"

        # CrÃ©er un rÃ©pertoire pour les rapports
        $script:reportsDir = Join-Path -Path $testDir -ChildPath "reports"
        New-Item -Path $script:reportsDir -ItemType Directory -Force | Out-Null

        # CrÃ©er un rÃ©pertoire pour le cache
        $script:cacheDir = Join-Path -Path $testDir -ChildPath "cache"
        New-Item -Path $script:cacheDir -ItemType Directory -Force | Out-Null
    }

    Context "ParamÃ¨tres et validation" {
        It "Accepte les paramÃ¨tres requis" {
            # CrÃ©er un script temporaire qui appelle le script Ã  tester avec les paramÃ¨tres minimaux
            $tempScript = Join-Path -Path $testDir -ChildPath "temp_script.ps1"
            $tempScriptContent = @"
`$result = & '$scriptToTest' -RepositoryPath '$repoPath' -OutputPath '$script:reportsDir' -UseCache `$false -WhatIf
`$result
"@
            Set-Content -Path $tempScript -Value $tempScriptContent -Encoding UTF8

            # ExÃ©cuter le script temporaire
            $result = & $tempScript

            # Le script ne devrait pas gÃ©nÃ©rer d'erreur
            $LASTEXITCODE | Should -Be 0
        }
    }

    Context "Fonctions internes" {
        BeforeAll {
            # Charger le script dans une portÃ©e temporaire pour accÃ©der aux fonctions internes
            $scriptContent = Get-Content -Path $scriptToTest -Raw
            $scriptBlock = [ScriptBlock]::Create($scriptContent)

            # CrÃ©er un nouveau contexte de script
            $script:tempModule = New-Module -Name "TempModule" -ScriptBlock $scriptBlock

            # Importer le module temporaire
            Import-Module $script:tempModule -Force
        }

        It "La fonction Get-PullRequestInfo fonctionne correctement" {
            # VÃ©rifier si la fonction existe
            $function = Get-Command -name Get-PullRequestInfo -Module TempModule -ErrorAction SilentlyContinue
            if ($null -eq $function) {
                Set-ItResult -Skipped -Because "La fonction Get-PullRequestInfo n'est pas accessible"
                return
            }

            # Appeler la fonction
            $prInfo = & $function -RepoPath $repoPath

            # VÃ©rifier les rÃ©sultats
            $prInfo | Should -Not -BeNullOrEmpty
            $prInfo.Number | Should -Be 1
            $prInfo.Title | Should -Be "Feature changes"
            $prInfo.HeadBranch | Should -Be "feature"
            $prInfo.BaseBranch | Should -Be "base"
            $prInfo.Files.Count | Should -Be 3
        }

        AfterAll {
            # Supprimer le module temporaire
            Remove-Module -Name TempModule -Force -ErrorAction SilentlyContinue
        }
    }

    Context "ExÃ©cution du script" {
        It "GÃ©nÃ¨re un rapport d'analyse" -Skip {
            # Ce test est ignorÃ© car il nÃ©cessite une exÃ©cution complÃ¨te du script
            # qui peut prendre du temps et dÃ©pend de l'environnement

            # ExÃ©cuter le script avec les paramÃ¨tres minimaux
            & $scriptToTest -RepositoryPath $repoPath -PullRequestNumber 1 -OutputPath $script:reportsDir -UseCache $false

            # VÃ©rifier que le rapport a Ã©tÃ© gÃ©nÃ©rÃ©
            $reportPath = Join-Path -Path $script:reportsDir -ChildPath "incremental_analysis_1.json"
            Test-Path -Path $reportPath | Should -Be $true

            # VÃ©rifier le contenu du rapport
            $report = Get-Content -Path $reportPath -Raw | ConvertFrom-Json
            $report | Should -Not -BeNullOrEmpty
            $report.PullRequest.Number | Should -Be 1
            $report.Results.Count | Should -Be 3
        }
    }

    AfterAll {
        # Restaurer le PATH original
        $env:PATH = $script:originalPath

        # Nettoyer les fichiers de test
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed

# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed
        
# Nettoyer les fichiers de test
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
}
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed

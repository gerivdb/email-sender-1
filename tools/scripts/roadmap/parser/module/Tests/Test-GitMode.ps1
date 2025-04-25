<#
.SYNOPSIS
    Tests pour le script git-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intégration pour le script git-mode.ps1
    qui implémente le mode GIT pour gérer efficacement les modifications du code source.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne seront pas exécutés avec le framework Pester."
}

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent (Split-Path -Parent $modulePath)
$gitModePath = Join-Path -Path $projectRoot -ChildPath "git-mode.ps1"

# Chemin vers les fonctions à tester
$invokeGitPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapGit.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $gitModePath)) {
    Write-Warning "Le script git-mode.ps1 est introuvable à l'emplacement : $gitModePath"
}

if (-not (Test-Path -Path $invokeGitPath)) {
    Write-Warning "Le fichier Invoke-RoadmapGit.ps1 est introuvable à l'emplacement : $invokeGitPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeGitPath) {
    . $invokeGitPath
    Write-Host "Fonction Invoke-RoadmapGit importée." -ForegroundColor Green
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Gestion des commits
  - [ ] **1.1.1** Développer les mécanismes de commit thématique
  - [ ] **1.1.2** Implémenter la validation finale
- [ ] **1.2** Gestion des branches
  - [ ] **1.2.1** Développer les mécanismes de création de branches
  - [ ] **1.2.2** Implémenter la fusion de branches

## Section 2

- [ ] **2.1** Tests de gestion de version
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Créer des répertoires temporaires pour les tests
$testRepoPath = Join-Path -Path $env:TEMP -ChildPath "TestRepo_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# Créer la structure du dépôt de test
New-Item -Path $testRepoPath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testRepoPath -ChildPath "src") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testRepoPath -ChildPath "docs") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testRepoPath -ChildPath "tests") -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# Créer des fichiers pour les tests
@"
# Module principal

function Get-Data {
    param (
        [string]`$Source
    )
    
    return "Données de `$Source"
}
"@ | Set-Content -Path (Join-Path -Path $testRepoPath -ChildPath "src\Module.ps1") -Encoding UTF8

@"
# Documentation du module

## Fonctions

### Get-Data

Récupère des données à partir d'une source.

#### Paramètres

- Source : La source des données.

#### Exemple

```powershell
Get-Data -Source "Fichier"
```
"@ | Set-Content -Path (Join-Path -Path $testRepoPath -ChildPath "docs\README.md") -Encoding UTF8

@"
# Tests du module

Describe "Get-Data" {
    It "Devrait retourner les données de la source" {
        Get-Data -Source "Test" | Should -Be "Données de Test"
    }
}
"@ | Set-Content -Path (Join-Path -Path $testRepoPath -ChildPath "tests\Module.Tests.ps1") -Encoding UTF8

# Initialiser le dépôt Git
try {
    Push-Location $testRepoPath
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    git commit -m "Initial commit"
    Pop-Location
    
    Write-Host "Dépôt Git initialisé : $testRepoPath" -ForegroundColor Green
} catch {
    Write-Warning "Impossible d'initialiser le dépôt Git : $_"
    Pop-Location
}

Write-Host "Répertoire de sortie créé : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapGit" {
    BeforeEach {
        # Préparation avant chaque test
    }

    AfterEach {
        # Nettoyage après chaque test
    }

    It "Devrait exécuter correctement avec des paramètres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapGit -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapGit -RepositoryPath $testRepoPath -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapGit n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le dépôt n'existe pas" {
        # Appeler la fonction avec un dépôt inexistant
        if (Get-Command -Name Invoke-RoadmapGit -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapGit -RepositoryPath "DepotInexistant" -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapGit n'est pas disponible"
        }
    }

    It "Devrait organiser les modifications par thème" {
        # Modifier des fichiers pour le test
        if (Get-Command -Name Invoke-RoadmapGit -ErrorAction SilentlyContinue) {
            # Créer une copie du dépôt pour le test
            $testRepoCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestRepoCopy_$(Get-Random)"
            Copy-Item -Path $testRepoPath -Destination $testRepoCopyPath -Recurse
            
            # Modifier des fichiers dans différents thèmes
            @"
# Module principal

function Get-Data {
    param (
        [string]`$Source
    )
    
    return "Données de `$Source"
}

function Set-Data {
    param (
        [string]`$Destination,
        [string]`$Data
    )
    
    return "Données `$Data écrites dans `$Destination"
}
"@ | Set-Content -Path (Join-Path -Path $testRepoCopyPath -ChildPath "src\Module.ps1") -Encoding UTF8

            @"
# Documentation du module

## Fonctions

### Get-Data

Récupère des données à partir d'une source.

#### Paramètres

- Source : La source des données.

#### Exemple

```powershell
Get-Data -Source "Fichier"
```

### Set-Data

Écrit des données dans une destination.

#### Paramètres

- Destination : La destination des données.
- Data : Les données à écrire.

#### Exemple

```powershell
Set-Data -Destination "Fichier" -Data "Test"
```
"@ | Set-Content -Path (Join-Path -Path $testRepoCopyPath -ChildPath "docs\README.md") -Encoding UTF8

            # Appeler la fonction
            $result = Invoke-RoadmapGit -RepositoryPath $testRepoCopyPath -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true
            
            # Vérifier que les modifications sont organisées par thème
            $result.Themes | Should -Not -BeNullOrEmpty
            $result.Themes.Count | Should -BeGreaterThan 0
            
            # Supprimer la copie du dépôt
            Remove-Item -Path $testRepoCopyPath -Recurse -Force
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapGit n'est pas disponible"
        }
    }

    It "Devrait créer des commits thématiques" {
        # Modifier des fichiers et créer des commits
        if (Get-Command -Name Invoke-RoadmapGit -ErrorAction SilentlyContinue) {
            # Créer une copie du dépôt pour le test
            $testRepoCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestRepoCopy_$(Get-Random)"
            Copy-Item -Path $testRepoPath -Destination $testRepoCopyPath -Recurse
            
            # Modifier des fichiers
            @"
# Module principal

function Get-Data {
    param (
        [string]`$Source
    )
    
    return "Données de `$Source"
}

function Set-Data {
    param (
        [string]`$Destination,
        [string]`$Data
    )
    
    return "Données `$Data écrites dans `$Destination"
}
"@ | Set-Content -Path (Join-Path -Path $testRepoCopyPath -ChildPath "src\Module.ps1") -Encoding UTF8
            
            # Appeler la fonction
            $result = Invoke-RoadmapGit -RepositoryPath $testRepoCopyPath -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true -PushAfterCommit $false
            
            # Vérifier que des commits sont créés
            $result.Commits | Should -Not -BeNullOrEmpty
            $result.Commits.Count | Should -BeGreaterThan 0
            
            # Supprimer la copie du dépôt
            Remove-Item -Path $testRepoCopyPath -Recurse -Force
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapGit n'est pas disponible"
        }
    }

    It "Devrait effectuer une vérification finale" {
        # Modifier des fichiers et effectuer une vérification finale
        if (Get-Command -Name Invoke-RoadmapGit -ErrorAction SilentlyContinue) {
            # Créer une copie du dépôt pour le test
            $testRepoCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestRepoCopy_$(Get-Random)"
            Copy-Item -Path $testRepoPath -Destination $testRepoCopyPath -Recurse
            
            # Modifier des fichiers
            @"
# Module principal

function Get-Data {
    param (
        [string]`$Source
    )
    
    return "Données de `$Source"
}

function Set-Data {
    param (
        [string]`$Destination,
        [string]`$Data
    )
    
    return "Données `$Data écrites dans `$Destination"
}
"@ | Set-Content -Path (Join-Path -Path $testRepoCopyPath -ChildPath "src\Module.ps1") -Encoding UTF8
            
            # Appeler la fonction
            $result = Invoke-RoadmapGit -RepositoryPath $testRepoCopyPath -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true -PushAfterCommit $false
            
            # Vérifier que la vérification finale est effectuée
            $result.FinalVerification | Should -Not -BeNullOrEmpty
            
            # Supprimer la copie du dépôt
            Remove-Item -Path $testRepoCopyPath -Recurse -Force
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapGit n'est pas disponible"
        }
    }
}

# Test d'intégration du script git-mode.ps1
Describe "git-mode.ps1 Integration" {
    It "Devrait s'exécuter correctement avec des paramètres valides" {
        if (Test-Path -Path $gitModePath) {
            # Créer une copie du dépôt pour le test
            $testRepoCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestRepoCopy_$(Get-Random)"
            Copy-Item -Path $testRepoPath -Destination $testRepoCopyPath -Recurse
            
            # Modifier des fichiers
            @"
# Module principal

function Get-Data {
    param (
        [string]`$Source
    )
    
    return "Données de `$Source"
}

function Set-Data {
    param (
        [string]`$Destination,
        [string]`$Data
    )
    
    return "Données `$Data écrites dans `$Destination"
}
"@ | Set-Content -Path (Join-Path -Path $testRepoCopyPath -ChildPath "src\Module.ps1") -Encoding UTF8
            
            # Exécuter le script
            $output = & $gitModePath -RepositoryPath $testRepoCopyPath -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true -PushAfterCommit $false
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Supprimer la copie du dépôt
            Remove-Item -Path $testRepoCopyPath -Recurse -Force
        } else {
            Set-ItResult -Skipped -Because "Le script git-mode.ps1 n'est pas disponible"
        }
    }
}

# Nettoyage
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de roadmap supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testRepoPath) {
    Remove-Item -Path $testRepoPath -Recurse -Force
    Write-Host "Dépôt de test supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "Répertoire de sortie supprimé." -ForegroundColor Gray
}

# Exécuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminés. Utilisez Invoke-Pester pour exécuter les tests avec le framework Pester." -ForegroundColor Yellow
}

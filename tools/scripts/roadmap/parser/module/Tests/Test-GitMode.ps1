<#
.SYNOPSIS
    Tests pour le script git-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intÃ©gration pour le script git-mode.ps1
    qui implÃ©mente le mode GIT pour gÃ©rer efficacement les modifications du code source.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installÃ©. Les tests ne seront pas exÃ©cutÃ©s avec le framework Pester."
}

# Chemin vers le script Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent (Split-Path -Parent $modulePath)
$gitModePath = Join-Path -Path $projectRoot -ChildPath "git-mode.ps1"

# Chemin vers les fonctions Ã  tester
$invokeGitPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapGit.ps1"

# VÃ©rifier si les fichiers existent
if (-not (Test-Path -Path $gitModePath)) {
    Write-Warning "Le script git-mode.ps1 est introuvable Ã  l'emplacement : $gitModePath"
}

if (-not (Test-Path -Path $invokeGitPath)) {
    Write-Warning "Le fichier Invoke-RoadmapGit.ps1 est introuvable Ã  l'emplacement : $invokeGitPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeGitPath) {
    . $invokeGitPath
    Write-Host "Fonction Invoke-RoadmapGit importÃ©e." -ForegroundColor Green
}

# CrÃ©er un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# CrÃ©er un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Gestion des commits
  - [ ] **1.1.1** DÃ©velopper les mÃ©canismes de commit thÃ©matique
  - [ ] **1.1.2** ImplÃ©menter la validation finale
- [ ] **1.2** Gestion des branches
  - [ ] **1.2.1** DÃ©velopper les mÃ©canismes de crÃ©ation de branches
  - [ ] **1.2.2** ImplÃ©menter la fusion de branches

## Section 2

- [ ] **2.1** Tests de gestion de version
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap crÃ©Ã© : $testFilePath" -ForegroundColor Green

# CrÃ©er des rÃ©pertoires temporaires pour les tests
$testRepoPath = Join-Path -Path $env:TEMP -ChildPath "TestRepo_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"

# CrÃ©er la structure du dÃ©pÃ´t de test
New-Item -Path $testRepoPath -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testRepoPath -ChildPath "src") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testRepoPath -ChildPath "docs") -ItemType Directory -Force | Out-Null
New-Item -Path (Join-Path -Path $testRepoPath -ChildPath "tests") -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers pour les tests
@"
# Module principal

function Get-Data {
    param (
        [string]`$Source
    )
    
    return "DonnÃ©es de `$Source"
}
"@ | Set-Content -Path (Join-Path -Path $testRepoPath -ChildPath "src\Module.ps1") -Encoding UTF8

@"
# Documentation du module

## Fonctions

### Get-Data

RÃ©cupÃ¨re des donnÃ©es Ã  partir d'une source.

#### ParamÃ¨tres

- Source : La source des donnÃ©es.

#### Exemple

```powershell
Get-Data -Source "Fichier"
```
"@ | Set-Content -Path (Join-Path -Path $testRepoPath -ChildPath "docs\README.md") -Encoding UTF8

@"
# Tests du module

Describe "Get-Data" {
    It "Devrait retourner les donnÃ©es de la source" {
        Get-Data -Source "Test" | Should -Be "DonnÃ©es de Test"
    }
}
"@ | Set-Content -Path (Join-Path -Path $testRepoPath -ChildPath "tests\Module.Tests.ps1") -Encoding UTF8

# Initialiser le dÃ©pÃ´t Git
try {
    Push-Location $testRepoPath
    git init
    git config user.name "Test User"
    git config user.email "test@example.com"
    git add .
    git commit -m "Initial commit"
    Pop-Location
    
    Write-Host "DÃ©pÃ´t Git initialisÃ© : $testRepoPath" -ForegroundColor Green
} catch {
    Write-Warning "Impossible d'initialiser le dÃ©pÃ´t Git : $_"
    Pop-Location
}

Write-Host "RÃ©pertoire de sortie crÃ©Ã© : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapGit" {
    BeforeEach {
        # PrÃ©paration avant chaque test
    }

    AfterEach {
        # Nettoyage aprÃ¨s chaque test
    }

    It "Devrait exÃ©cuter correctement avec des paramÃ¨tres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapGit -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapGit -RepositoryPath $testRepoPath -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapGit n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le dÃ©pÃ´t n'existe pas" {
        # Appeler la fonction avec un dÃ©pÃ´t inexistant
        if (Get-Command -Name Invoke-RoadmapGit -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapGit -RepositoryPath "DepotInexistant" -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapGit n'est pas disponible"
        }
    }

    It "Devrait organiser les modifications par thÃ¨me" {
        # Modifier des fichiers pour le test
        if (Get-Command -Name Invoke-RoadmapGit -ErrorAction SilentlyContinue) {
            # CrÃ©er une copie du dÃ©pÃ´t pour le test
            $testRepoCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestRepoCopy_$(Get-Random)"
            Copy-Item -Path $testRepoPath -Destination $testRepoCopyPath -Recurse
            
            # Modifier des fichiers dans diffÃ©rents thÃ¨mes
            @"
# Module principal

function Get-Data {
    param (
        [string]`$Source
    )
    
    return "DonnÃ©es de `$Source"
}

function Set-Data {
    param (
        [string]`$Destination,
        [string]`$Data
    )
    
    return "DonnÃ©es `$Data Ã©crites dans `$Destination"
}
"@ | Set-Content -Path (Join-Path -Path $testRepoCopyPath -ChildPath "src\Module.ps1") -Encoding UTF8

            @"
# Documentation du module

## Fonctions

### Get-Data

RÃ©cupÃ¨re des donnÃ©es Ã  partir d'une source.

#### ParamÃ¨tres

- Source : La source des donnÃ©es.

#### Exemple

```powershell
Get-Data -Source "Fichier"
```

### Set-Data

Ã‰crit des donnÃ©es dans une destination.

#### ParamÃ¨tres

- Destination : La destination des donnÃ©es.
- Data : Les donnÃ©es Ã  Ã©crire.

#### Exemple

```powershell
Set-Data -Destination "Fichier" -Data "Test"
```
"@ | Set-Content -Path (Join-Path -Path $testRepoCopyPath -ChildPath "docs\README.md") -Encoding UTF8

            # Appeler la fonction
            $result = Invoke-RoadmapGit -RepositoryPath $testRepoCopyPath -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true
            
            # VÃ©rifier que les modifications sont organisÃ©es par thÃ¨me
            $result.Themes | Should -Not -BeNullOrEmpty
            $result.Themes.Count | Should -BeGreaterThan 0
            
            # Supprimer la copie du dÃ©pÃ´t
            Remove-Item -Path $testRepoCopyPath -Recurse -Force
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapGit n'est pas disponible"
        }
    }

    It "Devrait crÃ©er des commits thÃ©matiques" {
        # Modifier des fichiers et crÃ©er des commits
        if (Get-Command -Name Invoke-RoadmapGit -ErrorAction SilentlyContinue) {
            # CrÃ©er une copie du dÃ©pÃ´t pour le test
            $testRepoCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestRepoCopy_$(Get-Random)"
            Copy-Item -Path $testRepoPath -Destination $testRepoCopyPath -Recurse
            
            # Modifier des fichiers
            @"
# Module principal

function Get-Data {
    param (
        [string]`$Source
    )
    
    return "DonnÃ©es de `$Source"
}

function Set-Data {
    param (
        [string]`$Destination,
        [string]`$Data
    )
    
    return "DonnÃ©es `$Data Ã©crites dans `$Destination"
}
"@ | Set-Content -Path (Join-Path -Path $testRepoCopyPath -ChildPath "src\Module.ps1") -Encoding UTF8
            
            # Appeler la fonction
            $result = Invoke-RoadmapGit -RepositoryPath $testRepoCopyPath -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true -PushAfterCommit $false
            
            # VÃ©rifier que des commits sont crÃ©Ã©s
            $result.Commits | Should -Not -BeNullOrEmpty
            $result.Commits.Count | Should -BeGreaterThan 0
            
            # Supprimer la copie du dÃ©pÃ´t
            Remove-Item -Path $testRepoCopyPath -Recurse -Force
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapGit n'est pas disponible"
        }
    }

    It "Devrait effectuer une vÃ©rification finale" {
        # Modifier des fichiers et effectuer une vÃ©rification finale
        if (Get-Command -Name Invoke-RoadmapGit -ErrorAction SilentlyContinue) {
            # CrÃ©er une copie du dÃ©pÃ´t pour le test
            $testRepoCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestRepoCopy_$(Get-Random)"
            Copy-Item -Path $testRepoPath -Destination $testRepoCopyPath -Recurse
            
            # Modifier des fichiers
            @"
# Module principal

function Get-Data {
    param (
        [string]`$Source
    )
    
    return "DonnÃ©es de `$Source"
}

function Set-Data {
    param (
        [string]`$Destination,
        [string]`$Data
    )
    
    return "DonnÃ©es `$Data Ã©crites dans `$Destination"
}
"@ | Set-Content -Path (Join-Path -Path $testRepoCopyPath -ChildPath "src\Module.ps1") -Encoding UTF8
            
            # Appeler la fonction
            $result = Invoke-RoadmapGit -RepositoryPath $testRepoCopyPath -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true -PushAfterCommit $false
            
            # VÃ©rifier que la vÃ©rification finale est effectuÃ©e
            $result.FinalVerification | Should -Not -BeNullOrEmpty
            
            # Supprimer la copie du dÃ©pÃ´t
            Remove-Item -Path $testRepoCopyPath -Recurse -Force
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapGit n'est pas disponible"
        }
    }
}

# Test d'intÃ©gration du script git-mode.ps1
Describe "git-mode.ps1 Integration" {
    It "Devrait s'exÃ©cuter correctement avec des paramÃ¨tres valides" {
        if (Test-Path -Path $gitModePath) {
            # CrÃ©er une copie du dÃ©pÃ´t pour le test
            $testRepoCopyPath = Join-Path -Path $env:TEMP -ChildPath "TestRepoCopy_$(Get-Random)"
            Copy-Item -Path $testRepoPath -Destination $testRepoCopyPath -Recurse
            
            # Modifier des fichiers
            @"
# Module principal

function Get-Data {
    param (
        [string]`$Source
    )
    
    return "DonnÃ©es de `$Source"
}

function Set-Data {
    param (
        [string]`$Destination,
        [string]`$Data
    )
    
    return "DonnÃ©es `$Data Ã©crites dans `$Destination"
}
"@ | Set-Content -Path (Join-Path -Path $testRepoCopyPath -ChildPath "src\Module.ps1") -Encoding UTF8
            
            # ExÃ©cuter le script
            $output = & $gitModePath -RepositoryPath $testRepoCopyPath -CommitStyle "Thematic" -SkipVerify $true -FinalVerify $true -PushAfterCommit $false
            
            # VÃ©rifier que le script s'est exÃ©cutÃ© sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Supprimer la copie du dÃ©pÃ´t
            Remove-Item -Path $testRepoCopyPath -Recurse -Force
        } else {
            Set-ItResult -Skipped -Because "Le script git-mode.ps1 n'est pas disponible"
        }
    }
}

# Nettoyage
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de roadmap supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testRepoPath) {
    Remove-Item -Path $testRepoPath -Recurse -Force
    Write-Host "DÃ©pÃ´t de test supprimÃ©." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "RÃ©pertoire de sortie supprimÃ©." -ForegroundColor Gray
}

# ExÃ©cuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminÃ©s. Utilisez Invoke-Pester pour exÃ©cuter les tests avec le framework Pester." -ForegroundColor Yellow
}

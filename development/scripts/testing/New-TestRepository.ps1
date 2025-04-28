#Requires -Version 5.1
<#
.SYNOPSIS
    CrÃ©e un dÃ©pÃ´t Git de test isolÃ© pour les tests de pull requests.

.DESCRIPTION
    Ce script crÃ©e un dÃ©pÃ´t Git isolÃ© (PR-Analysis-TestRepo) pour tester
    le systÃ¨me d'analyse des pull requests. Il configure le dÃ©pÃ´t avec la
    mÃªme structure que le dÃ©pÃ´t principal et met en place les branches
    nÃ©cessaires.

.PARAMETER Path
    Le chemin oÃ¹ crÃ©er le dÃ©pÃ´t de test.
    Par dÃ©faut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER SourceRepo
    Le chemin du dÃ©pÃ´t source Ã  partir duquel copier la structure.
    Par dÃ©faut: "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

.PARAMETER SetupBranches
    Indique s'il faut configurer les branches de test (develop, feature, hotfix).
    Par dÃ©faut: $true

.EXAMPLE
    .\New-TestRepository.ps1
    CrÃ©e un dÃ©pÃ´t de test avec les paramÃ¨tres par dÃ©faut.

.EXAMPLE
    .\New-TestRepository.ps1 -Path "D:\TestRepos\PR-Test" -SourceRepo "D:\MyProject"
    CrÃ©e un dÃ©pÃ´t de test Ã  l'emplacement spÃ©cifiÃ© en utilisant le dÃ©pÃ´t source spÃ©cifiÃ©.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-14
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$Path = "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo",

    [Parameter()]
    [string]$SourceRepo = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter()]
    [bool]$SetupBranches = $true,

    [Parameter()]
    [switch]$Force
)

# Fonction pour crÃ©er un dÃ©pÃ´t Git
function Initialize-GitRepository {
    param (
        [string]$Path,
        [switch]$Force
    )

    Write-Host "Initialisation du dÃ©pÃ´t Git Ã  $Path..." -ForegroundColor Cyan

    if (Test-Path -Path $Path) {
        if ($Force) {
            # Supprimer le dossier existant sans confirmation
            Remove-Item -Path $Path -Recurse -Force
        } else {
            Write-Warning "Le dossier $Path existe dÃ©jÃ . Voulez-vous le supprimer et le recrÃ©er ? (O/N)"
            $response = Read-Host
            if ($response -eq "O" -or $response -eq "o") {
                Remove-Item -Path $Path -Recurse -Force
            } else {
                Write-Host "OpÃ©ration annulÃ©e." -ForegroundColor Yellow
                return $false
            }
        }
    }

    # CrÃ©er le dossier
    New-Item -ItemType Directory -Path $Path -Force | Out-Null

    # Initialiser le dÃ©pÃ´t Git
    Push-Location $Path
    try {
        git init
        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de l'initialisation du dÃ©pÃ´t Git."
        }

        # Configurer l'utilisateur Git pour ce dÃ©pÃ´t
        git config user.name "PR Test User"
        git config user.email "pr.test@example.com"

        # CrÃ©er un fichier README initial
        Set-Content -Path "README.md" -Value "# PR Analysis Test Repository`n`nCe dÃ©pÃ´t est utilisÃ© pour tester le systÃ¨me d'analyse des pull requests."

        # Ajouter et committer le README
        git add README.md
        git commit -m "Initial commit"

        Write-Host "DÃ©pÃ´t Git initialisÃ© avec succÃ¨s." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de l'initialisation du dÃ©pÃ´t Git: $_"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour copier la structure du dÃ©pÃ´t source
function Copy-RepositoryStructure {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )

    Write-Host "Copie de la structure du dÃ©pÃ´t source..." -ForegroundColor Cyan

    # Dossiers Ã  exclure de la copie
    $excludeFolders = @(
        ".git",
        "node_modules",
        "dist",
        "build"
    )

    # CrÃ©er les dossiers principaux
    $mainFolders = Get-ChildItem -Path $SourcePath -Directory | Where-Object { $excludeFolders -notcontains $_.Name }

    foreach ($folder in $mainFolders) {
        $destinationFolder = Join-Path -Path $DestinationPath -ChildPath $folder.Name
        Write-Host "  CrÃ©ation du dossier $($folder.Name)..." -ForegroundColor Yellow

        # CrÃ©er le dossier
        New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null

        # Copier quelques fichiers d'exemple (pas tous pour garder le dÃ©pÃ´t lÃ©ger)
        $sampleFiles = Get-ChildItem -Path $folder.FullName -File -Recurse | Where-Object {
            $_.Extension -in @(".ps1", ".py", ".md", ".json")
        } | Select-Object -First 5

        foreach ($file in $sampleFiles) {
            $relativePath = $file.FullName.Substring($folder.FullName.Length + 1)
            $destinationFile = Join-Path -Path $destinationFolder -ChildPath $relativePath
            $destinationDir = Split-Path -Parent $destinationFile

            if (-not (Test-Path -Path $destinationDir)) {
                New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
            }

            Copy-Item -Path $file.FullName -Destination $destinationFile -Force
        }
    }

    # Ajouter et committer les fichiers
    Push-Location $DestinationPath
    try {
        git add .
        git commit -m "Add repository structure"

        Write-Host "Structure du dÃ©pÃ´t copiÃ©e avec succÃ¨s." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de la copie de la structure du dÃ©pÃ´t: $_"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour configurer les branches
function Set-GitBranches {
    param (
        [string]$Path
    )

    Write-Host "Configuration des branches..." -ForegroundColor Cyan

    Push-Location $Path
    try {
        # CrÃ©er la branche develop
        git checkout -b develop
        git commit --allow-empty -m "Initialize develop branch"

        # CrÃ©er quelques branches feature
        git checkout -b feature/test-feature-1 develop
        git commit --allow-empty -m "Initialize feature branch 1"

        git checkout -b feature/test-feature-2 develop
        git commit --allow-empty -m "Initialize feature branch 2"

        # CrÃ©er une branche hotfix
        git checkout -b hotfix/test-hotfix-1 main
        git commit --allow-empty -m "Initialize hotfix branch"

        # Revenir Ã  la branche develop
        git checkout develop

        Write-Host "Branches configurÃ©es avec succÃ¨s." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de la configuration des branches: $_"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction principale
function New-TestRepository {
    # Initialiser le dÃ©pÃ´t Git
    $initResult = Initialize-GitRepository -Path $Path -Force:$Force
    if (-not $initResult) {
        return
    }

    # Copier la structure du dÃ©pÃ´t source
    $copyResult = Copy-RepositoryStructure -SourcePath $SourceRepo -DestinationPath $Path
    if (-not $copyResult) {
        return
    }

    # Configurer les branches si demandÃ©
    if ($SetupBranches) {
        $branchResult = Set-GitBranches -Path $Path
        if (-not $branchResult) {
            return
        }
    }

    Write-Host "`nDÃ©pÃ´t de test crÃ©Ã© avec succÃ¨s Ã  $Path" -ForegroundColor Green
    Write-Host "Vous pouvez maintenant utiliser ce dÃ©pÃ´t pour tester le systÃ¨me d'analyse des pull requests." -ForegroundColor Cyan
}

# Exporter la fonction principale
Export-ModuleMember -Function New-TestRepository

# Si le script est exÃ©cutÃ© directement (pas importÃ© comme module)
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    # ExÃ©cuter la fonction principale
    New-TestRepository
}

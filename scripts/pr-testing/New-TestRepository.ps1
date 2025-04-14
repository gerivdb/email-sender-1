#Requires -Version 5.1
<#
.SYNOPSIS
    Crée un dépôt Git de test isolé pour les tests de pull requests.

.DESCRIPTION
    Ce script crée un dépôt Git isolé (PR-Analysis-TestRepo) pour tester
    le système d'analyse des pull requests. Il configure le dépôt avec la
    même structure que le dépôt principal et met en place les branches
    nécessaires.

.PARAMETER Path
    Le chemin où créer le dépôt de test.
    Par défaut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER SourceRepo
    Le chemin du dépôt source à partir duquel copier la structure.
    Par défaut: "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

.PARAMETER SetupBranches
    Indique s'il faut configurer les branches de test (develop, feature, hotfix).
    Par défaut: $true

.EXAMPLE
    .\New-TestRepository.ps1
    Crée un dépôt de test avec les paramètres par défaut.

.EXAMPLE
    .\New-TestRepository.ps1 -Path "D:\TestRepos\PR-Test" -SourceRepo "D:\MyProject"
    Crée un dépôt de test à l'emplacement spécifié en utilisant le dépôt source spécifié.

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

# Fonction pour créer un dépôt Git
function Initialize-GitRepository {
    param (
        [string]$Path,
        [switch]$Force
    )

    Write-Host "Initialisation du dépôt Git à $Path..." -ForegroundColor Cyan

    if (Test-Path -Path $Path) {
        if ($Force) {
            # Supprimer le dossier existant sans confirmation
            Remove-Item -Path $Path -Recurse -Force
        } else {
            Write-Warning "Le dossier $Path existe déjà. Voulez-vous le supprimer et le recréer ? (O/N)"
            $response = Read-Host
            if ($response -eq "O" -or $response -eq "o") {
                Remove-Item -Path $Path -Recurse -Force
            } else {
                Write-Host "Opération annulée." -ForegroundColor Yellow
                return $false
            }
        }
    }

    # Créer le dossier
    New-Item -ItemType Directory -Path $Path -Force | Out-Null

    # Initialiser le dépôt Git
    Push-Location $Path
    try {
        git init
        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de l'initialisation du dépôt Git."
        }

        # Configurer l'utilisateur Git pour ce dépôt
        git config user.name "PR Test User"
        git config user.email "pr.test@example.com"

        # Créer un fichier README initial
        Set-Content -Path "README.md" -Value "# PR Analysis Test Repository`n`nCe dépôt est utilisé pour tester le système d'analyse des pull requests."

        # Ajouter et committer le README
        git add README.md
        git commit -m "Initial commit"

        Write-Host "Dépôt Git initialisé avec succès." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de l'initialisation du dépôt Git: $_"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour copier la structure du dépôt source
function Copy-RepositoryStructure {
    param (
        [string]$SourcePath,
        [string]$DestinationPath
    )

    Write-Host "Copie de la structure du dépôt source..." -ForegroundColor Cyan

    # Dossiers à exclure de la copie
    $excludeFolders = @(
        ".git",
        "node_modules",
        "dist",
        "build"
    )

    # Créer les dossiers principaux
    $mainFolders = Get-ChildItem -Path $SourcePath -Directory | Where-Object { $excludeFolders -notcontains $_.Name }

    foreach ($folder in $mainFolders) {
        $destinationFolder = Join-Path -Path $DestinationPath -ChildPath $folder.Name
        Write-Host "  Création du dossier $($folder.Name)..." -ForegroundColor Yellow

        # Créer le dossier
        New-Item -ItemType Directory -Path $destinationFolder -Force | Out-Null

        # Copier quelques fichiers d'exemple (pas tous pour garder le dépôt léger)
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

        Write-Host "Structure du dépôt copiée avec succès." -ForegroundColor Green
        return $true
    } catch {
        Write-Error "Erreur lors de la copie de la structure du dépôt: $_"
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
        # Créer la branche develop
        git checkout -b develop
        git commit --allow-empty -m "Initialize develop branch"

        # Créer quelques branches feature
        git checkout -b feature/test-feature-1 develop
        git commit --allow-empty -m "Initialize feature branch 1"

        git checkout -b feature/test-feature-2 develop
        git commit --allow-empty -m "Initialize feature branch 2"

        # Créer une branche hotfix
        git checkout -b hotfix/test-hotfix-1 main
        git commit --allow-empty -m "Initialize hotfix branch"

        # Revenir à la branche develop
        git checkout develop

        Write-Host "Branches configurées avec succès." -ForegroundColor Green
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
    # Initialiser le dépôt Git
    $initResult = Initialize-GitRepository -Path $Path -Force:$Force
    if (-not $initResult) {
        return
    }

    # Copier la structure du dépôt source
    $copyResult = Copy-RepositoryStructure -SourcePath $SourceRepo -DestinationPath $Path
    if (-not $copyResult) {
        return
    }

    # Configurer les branches si demandé
    if ($SetupBranches) {
        $branchResult = Set-GitBranches -Path $Path
        if (-not $branchResult) {
            return
        }
    }

    Write-Host "`nDépôt de test créé avec succès à $Path" -ForegroundColor Green
    Write-Host "Vous pouvez maintenant utiliser ce dépôt pour tester le système d'analyse des pull requests." -ForegroundColor Cyan
}

# Exporter la fonction principale
Export-ModuleMember -Function New-TestRepository

# Si le script est exécuté directement (pas importé comme module)
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    # Exécuter la fonction principale
    New-TestRepository
}

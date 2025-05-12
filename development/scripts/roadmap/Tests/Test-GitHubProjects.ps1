# Test-GitHubProjects.ps1
# Script de test pour l'intégration avec les projets GitHub
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste l'intégration avec les projets GitHub.

.DESCRIPTION
    Ce script teste l'intégration avec les projets GitHub,
    en vérifiant que les projets sont correctement créés et mis à jour.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$integrationPath = Join-Path -Path $parentPath -ChildPath "integration"
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"

$connectGitHubRoadmapPath = Join-Path -Path $integrationPath -ChildPath "Connect-GitHubRoadmap.ps1"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"
$generateRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Generate-Roadmap.ps1"

Write-Host "Chargement des modules..." -ForegroundColor Cyan

if (Test-Path $connectGitHubRoadmapPath) {
    . $connectGitHubRoadmapPath
    Write-Host "  Module Connect-GitHubRoadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Connect-GitHubRoadmap.ps1 introuvable à l'emplacement: $connectGitHubRoadmapPath" -ForegroundColor Red
    exit
}

if (Test-Path $parseRoadmapPath) {
    . $parseRoadmapPath
    Write-Host "  Module Parse-Roadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Parse-Roadmap.ps1 introuvable à l'emplacement: $parseRoadmapPath" -ForegroundColor Red
    exit
}

if (Test-Path $generateRoadmapPath) {
    . $generateRoadmapPath
    Write-Host "  Module Generate-Roadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Generate-Roadmap.ps1 introuvable à l'emplacement: $generateRoadmapPath" -ForegroundColor Red
    exit
}

# Créer un dossier de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "GitHubProjectsTests"
if (-not (Test-Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

Write-Host "Dossier de test créé: $testDir" -ForegroundColor Cyan

# Créer une roadmap de test
$roadmapContent = @"
# Plan de test pour les projets GitHub

## 1. Première section
- [x] **1.1** Tâche complétée de niveau 1
  - [x] **1.1.1** Sous-tâche complétée
    - [x] **1.1.1.1** Sous-sous-tâche complétée
  - [ ] **1.1.2** Sous-tâche en cours
    - [ ] **1.1.2.1** Sous-sous-tâche en cours
    - [ ] **1.1.2.2** Autre sous-sous-tâche en cours
- [ ] **1.2** Tâche en cours de niveau 1
  - [ ] **1.2.1** Sous-tâche en cours
  - [ ] **1.2.2** Autre sous-tâche en cours

## 2. Deuxième section
- [ ] **2.1** Tâche de développement
  - [ ] **2.1.1** Implémenter la fonctionnalité A
  - [ ] **2.1.2** Implémenter la fonctionnalité B
  - [ ] **2.1.3** Implémenter la fonctionnalité C
- [ ] **2.2** Tâche de test
  - [ ] **2.2.1** Tester la fonctionnalité A
  - [ ] **2.2.2** Tester la fonctionnalité B
  - [ ] **2.2.3** Tester la fonctionnalité C
"@

$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
$roadmapContent | Out-File -FilePath $testRoadmapPath -Encoding utf8

Write-Host "Roadmap de test créée: $testRoadmapPath" -ForegroundColor Cyan

# Test 1: Parser la roadmap
Write-Host "`nTest 1: Parser la roadmap" -ForegroundColor Yellow

try {
    $roadmap = Parse-RoadmapFile -FilePath $testRoadmapPath
    
    if ($null -ne $roadmap) {
        Write-Host "  Succès: Roadmap parsée correctement." -ForegroundColor Green
        Write-Host "  Titre: $($roadmap.Title)" -ForegroundColor Gray
        Write-Host "  Nombre de tâches: $($roadmap.Tasks.Count)" -ForegroundColor Gray
        
        # Afficher quelques tâches
        Write-Host "  Exemples de tâches:" -ForegroundColor Gray
        for ($i = 0; $i -lt [Math]::Min(3, $roadmap.Tasks.Count); $i++) {
            $task = $roadmap.Tasks[$i]
            Write-Host "    $($task.Id): $($task.Title) - $($task.Status)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Échec: Échec du parsing de la roadmap." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur lors du parsing de la roadmap: $_" -ForegroundColor Red
}

# Test 2: Convertir la roadmap en issues GitHub
Write-Host "`nTest 2: Convertir la roadmap en issues GitHub" -ForegroundColor Yellow

try {
    $githubRoadmap = ConvertTo-GitHubIssues -RoadmapPath $testRoadmapPath
    
    if ($null -ne $githubRoadmap) {
        Write-Host "  Succès: Roadmap convertie en issues GitHub." -ForegroundColor Green
        Write-Host "  Titre: $($githubRoadmap.Title)" -ForegroundColor Gray
        Write-Host "  Nombre d'issues: $($githubRoadmap.Issues.Count)" -ForegroundColor Gray
        
        # Afficher quelques issues
        Write-Host "  Exemples d'issues:" -ForegroundColor Gray
        for ($i = 0; $i -lt [Math]::Min(3, $githubRoadmap.Issues.Count); $i++) {
            $issue = $githubRoadmap.Issues[$i]
            Write-Host "    $($issue.Title) - $($issue.State)" -ForegroundColor Gray
            Write-Host "      Labels: $($issue.Labels -join ', ')" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Échec: Échec de la conversion de la roadmap en issues GitHub." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur lors de la conversion de la roadmap en issues GitHub: $_" -ForegroundColor Red
}

# Test 3: Tester la connexion à l'API GitHub (si un token est fourni)
Write-Host "`nTest 3: Tester la connexion à l'API GitHub" -ForegroundColor Yellow

try {
    Write-Host "  Token d'accès personnel GitHub (laisser vide pour ignorer): " -ForegroundColor Yellow -NoNewline
    $githubToken = Read-Host
    
    if (-not [string]::IsNullOrEmpty($githubToken)) {
        $connection = Connect-GitHubApi -Token $githubToken
        
        if ($null -ne $connection) {
            Write-Host "  Succès: Connexion à l'API GitHub réussie." -ForegroundColor Green
            Write-Host "  Utilisateur: $($connection.User.login)" -ForegroundColor Gray
        } else {
            Write-Host "  Échec: Échec de la connexion à l'API GitHub." -ForegroundColor Red
        }
    } else {
        Write-Host "  Test ignoré: Aucun token fourni." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Erreur lors de la connexion à l'API GitHub: $_" -ForegroundColor Red
}

# Test 4: Tester la création d'un projet GitHub (si un token est fourni)
Write-Host "`nTest 4: Tester la création d'un projet GitHub" -ForegroundColor Yellow

try {
    if (-not [string]::IsNullOrEmpty($githubToken) -and $null -ne $connection) {
        Write-Host "  Propriétaire du dépôt GitHub: " -ForegroundColor Yellow -NoNewline
        $owner = Read-Host
        
        if (-not [string]::IsNullOrEmpty($owner)) {
            Write-Host "  Nom du dépôt GitHub: " -ForegroundColor Yellow -NoNewline
            $repo = Read-Host
            
            if (-not [string]::IsNullOrEmpty($repo)) {
                # Vérifier que le dépôt existe
                $repository = Get-GitHubRepository -Connection $connection -Owner $owner -Repo $repo
                
                if ($null -ne $repository) {
                    Write-Host "  Succès: Dépôt GitHub trouvé." -ForegroundColor Green
                    
                    # Créer un projet
                    Write-Host "  Création d'un projet GitHub..." -ForegroundColor Gray
                    
                    $project = New-GitHubProject -Connection $connection -Owner $owner -Repo $repo -Name "Test Project" -Body "Projet de test pour les roadmaps"
                    
                    if ($null -ne $project) {
                        Write-Host "  Succès: Projet GitHub créé." -ForegroundColor Green
                        Write-Host "  Projet: $($project.name) (ID: $($project.id))" -ForegroundColor Gray
                        
                        # Créer des colonnes
                        Write-Host "  Création des colonnes du projet..." -ForegroundColor Gray
                        
                        $todoColumn = New-GitHubProjectColumn -Connection $connection -ProjectId $project.id -Name "À faire"
                        $inProgressColumn = New-GitHubProjectColumn -Connection $connection -ProjectId $project.id -Name "En cours"
                        $doneColumn = New-GitHubProjectColumn -Connection $connection -ProjectId $project.id -Name "Terminé"
                        
                        if ($null -ne $todoColumn -and $null -ne $inProgressColumn -and $null -ne $doneColumn) {
                            Write-Host "  Succès: Colonnes du projet créées." -ForegroundColor Green
                            
                            # Synchroniser la roadmap avec le projet
                            Write-Host "  Synchronisation de la roadmap avec le projet..." -ForegroundColor Gray
                            
                            $result = Sync-RoadmapToGitHubProject -Connection $connection -RoadmapPath $testRoadmapPath -Owner $owner -Repo $repo -ProjectId $project.id
                            
                            if ($null -ne $result) {
                                Write-Host "  Succès: Roadmap synchronisée avec le projet." -ForegroundColor Green
                                Write-Host "  Issues créées: $($result.IssuesCreated)" -ForegroundColor Gray
                                Write-Host "  Issues mises à jour: $($result.IssuesUpdated)" -ForegroundColor Gray
                                Write-Host "  Cartes créées: $($result.CardsCreated)" -ForegroundColor Gray
                            } else {
                                Write-Host "  Échec: Échec de la synchronisation de la roadmap avec le projet." -ForegroundColor Red
                            }
                        } else {
                            Write-Host "  Échec: Échec de la création des colonnes du projet." -ForegroundColor Red
                        }
                    } else {
                        Write-Host "  Échec: Échec de la création du projet GitHub." -ForegroundColor Red
                    }
                } else {
                    Write-Host "  Échec: Dépôt GitHub introuvable." -ForegroundColor Red
                }
            } else {
                Write-Host "  Test ignoré: Aucun nom de dépôt fourni." -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Test ignoré: Aucun propriétaire de dépôt fourni." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Test ignoré: Aucun token fourni ou connexion échouée." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Erreur lors de la création du projet GitHub: $_" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "Nettoyage terminé." -ForegroundColor Green
}

Write-Host "`nTests terminés." -ForegroundColor Cyan

# Test-GitHubPullRequests.ps1
# Script de test pour l'intégration avec les pull requests et reviews GitHub
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste l'intégration avec les pull requests et reviews GitHub.

.DESCRIPTION
    Ce script teste l'intégration avec les pull requests et reviews GitHub,
    en vérifiant que les pull requests sont correctement créées et liées aux issues.

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
$testDir = Join-Path -Path $env:TEMP -ChildPath "GitHubPullRequestsTests"
if (-not (Test-Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

Write-Host "Dossier de test créé: $testDir" -ForegroundColor Cyan

# Créer une roadmap de test
$roadmapContent = @"
# Plan de test pour les pull requests GitHub

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

# Test 4: Tester la synchronisation avec les pull requests GitHub (si un token est fourni)
Write-Host "`nTest 4: Tester la synchronisation avec les pull requests GitHub" -ForegroundColor Yellow

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
                    
                    # Demander les paramètres pour la synchronisation
                    Write-Host "  Branche cible (défaut: main): " -ForegroundColor Yellow -NoNewline
                    $baseBranch = Read-Host
                    
                    if ([string]::IsNullOrEmpty($baseBranch)) {
                        $baseBranch = "main"
                    }
                    
                    Write-Host "  Préfixe des branches source (défaut: feature/): " -ForegroundColor Yellow -NoNewline
                    $headBranchPrefix = Read-Host
                    
                    if ([string]::IsNullOrEmpty($headBranchPrefix)) {
                        $headBranchPrefix = "feature/"
                    }
                    
                    Write-Host "  Créer des issues pour les tâches (o/n, défaut: o): " -ForegroundColor Yellow -NoNewline
                    $createIssues = Read-Host
                    $createIssuesSwitch = $createIssues -ne "n"
                    
                    # Synchroniser la roadmap avec les pull requests GitHub
                    Write-Host "  Synchronisation de la roadmap avec les pull requests GitHub..." -ForegroundColor Gray
                    
                    $result = Sync-RoadmapToGitHubPullRequests -Connection $connection -RoadmapPath $testRoadmapPath -Owner $owner -Repo $repo -BaseBranch $baseBranch -HeadBranchPrefix $headBranchPrefix -CreateIssues:$createIssuesSwitch
                    
                    if ($null -ne $result) {
                        Write-Host "  Succès: Roadmap synchronisée avec les pull requests GitHub." -ForegroundColor Green
                        Write-Host "  Dépôt GitHub: $($result.Repository)" -ForegroundColor Gray
                        Write-Host "  Branche cible: $($result.BaseBranch)" -ForegroundColor Gray
                        Write-Host "  Préfixe des branches source: $($result.HeadBranchPrefix)" -ForegroundColor Gray
                        Write-Host "  Pull requests créées: $($result.PullRequestsCreated)" -ForegroundColor Gray
                        Write-Host "  Pull requests liées: $($result.PullRequestsLinked)" -ForegroundColor Gray
                    } else {
                        Write-Host "  Échec: Échec de la synchronisation de la roadmap avec les pull requests GitHub." -ForegroundColor Red
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
    Write-Host "  Erreur lors de la synchronisation avec les pull requests GitHub: $_" -ForegroundColor Red
}

# Test 5: Tester les fonctionnalités de review (si un token est fourni)
Write-Host "`nTest 5: Tester les fonctionnalités de review" -ForegroundColor Yellow

try {
    if (-not [string]::IsNullOrEmpty($githubToken) -and $null -ne $connection -and -not [string]::IsNullOrEmpty($owner) -and -not [string]::IsNullOrEmpty($repo)) {
        # Obtenir les pull requests existantes
        Write-Host "  Obtention des pull requests existantes..." -ForegroundColor Gray
        
        $pullRequests = Get-GitHubPullRequests -Connection $connection -Owner $owner -Repo $repo -State "open"
        
        if ($null -ne $pullRequests -and $pullRequests.Count -gt 0) {
            Write-Host "  Succès: Pull requests obtenues." -ForegroundColor Green
            Write-Host "  Nombre de pull requests: $($pullRequests.Count)" -ForegroundColor Gray
            
            # Afficher les pull requests
            Write-Host "  Pull requests:" -ForegroundColor Gray
            foreach ($pr in $pullRequests) {
                Write-Host "    #$($pr.number): $($pr.title)" -ForegroundColor Gray
            }
            
            # Demander quelle pull request utiliser pour les tests
            Write-Host "  Numéro de la pull request à utiliser pour les tests (laisser vide pour ignorer): " -ForegroundColor Yellow -NoNewline
            $prNumber = Read-Host
            
            if (-not [string]::IsNullOrEmpty($prNumber)) {
                # Créer une review
                Write-Host "  Création d'une review..." -ForegroundColor Gray
                
                $review = New-GitHubPullRequestReview -Connection $connection -Owner $owner -Repo $repo -PullRequestNumber $prNumber -Body "Ceci est une review de test." -Event "COMMENT"
                
                if ($null -ne $review) {
                    Write-Host "  Succès: Review créée." -ForegroundColor Green
                    Write-Host "  ID de la review: $($review.id)" -ForegroundColor Gray
                    
                    # Obtenir les reviews
                    Write-Host "  Obtention des reviews..." -ForegroundColor Gray
                    
                    $reviews = Get-GitHubPullRequestReviews -Connection $connection -Owner $owner -Repo $repo -PullRequestNumber $prNumber
                    
                    if ($null -ne $reviews) {
                        Write-Host "  Succès: Reviews obtenues." -ForegroundColor Green
                        Write-Host "  Nombre de reviews: $($reviews.Count)" -ForegroundColor Gray
                    } else {
                        Write-Host "  Échec: Échec de l'obtention des reviews." -ForegroundColor Red
                    }
                } else {
                    Write-Host "  Échec: Échec de la création de la review." -ForegroundColor Red
                }
            } else {
                Write-Host "  Test ignoré: Aucun numéro de pull request fourni." -ForegroundColor Yellow
            }
        } else {
            Write-Host "  Aucune pull request ouverte trouvée." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Test ignoré: Informations manquantes." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Erreur lors des tests de review: $_" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "Nettoyage terminé." -ForegroundColor Green
}

Write-Host "`nTests terminés." -ForegroundColor Cyan

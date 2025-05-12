# Test-ExternalIntegration.ps1
# Script de test pour l'intégration avec les services externes
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste l'intégration avec les services externes.

.DESCRIPTION
    Ce script teste l'intégration avec les services externes,
    comme Notion, GitHub, etc.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$integrationPath = Join-Path -Path $parentPath -ChildPath "integration"
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"

$connectNotionRoadmapPath = Join-Path -Path $integrationPath -ChildPath "Connect-NotionRoadmap.ps1"
$connectGitHubRoadmapPath = Join-Path -Path $integrationPath -ChildPath "Connect-GitHubRoadmap.ps1"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"
$generateRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Generate-Roadmap.ps1"

Write-Host "Chargement des modules..." -ForegroundColor Cyan

if (Test-Path $connectNotionRoadmapPath) {
    . $connectNotionRoadmapPath
    Write-Host "  Module Connect-NotionRoadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Connect-NotionRoadmap.ps1 introuvable à l'emplacement: $connectNotionRoadmapPath" -ForegroundColor Red
    exit
}

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
$testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapExternalTests"
if (-not (Test-Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

Write-Host "Dossier de test créé: $testDir" -ForegroundColor Cyan

# Créer une roadmap de test
$roadmapContent = @"
# Plan de test pour l'intégration externe

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

# Test 2: Convertir la roadmap en structure Notion
Write-Host "`nTest 2: Convertir la roadmap en structure Notion" -ForegroundColor Yellow

try {
    $notionRoadmap = ConvertTo-NotionRoadmap -RoadmapPath $testRoadmapPath
    
    if ($null -ne $notionRoadmap) {
        Write-Host "  Succès: Roadmap convertie en structure Notion." -ForegroundColor Green
        Write-Host "  Titre: $($notionRoadmap.Title)" -ForegroundColor Gray
        Write-Host "  Nombre de pages: $($notionRoadmap.Pages.Count)" -ForegroundColor Gray
        
        # Afficher quelques pages
        Write-Host "  Exemples de pages:" -ForegroundColor Gray
        for ($i = 0; $i -lt [Math]::Min(3, $notionRoadmap.Pages.Count); $i++) {
            $page = $notionRoadmap.Pages[$i]
            Write-Host "    $($page.properties.ID.rich_text[0].text.content): $($page.properties.Title.title[0].text.content)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Échec: Échec de la conversion de la roadmap en structure Notion." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur lors de la conversion de la roadmap en structure Notion: $_" -ForegroundColor Red
}

# Test 3: Convertir la roadmap en issues GitHub
Write-Host "`nTest 3: Convertir la roadmap en issues GitHub" -ForegroundColor Yellow

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

# Test 4: Tester la connexion à l'API Notion (si un token est fourni)
Write-Host "`nTest 4: Tester la connexion à l'API Notion" -ForegroundColor Yellow

try {
    Write-Host "  Token d'intégration Notion (laisser vide pour ignorer): " -ForegroundColor Yellow -NoNewline
    $notionToken = Read-Host
    
    if (-not [string]::IsNullOrEmpty($notionToken)) {
        $connection = Connect-NotionApi -Token $notionToken
        
        if ($null -ne $connection) {
            Write-Host "  Succès: Connexion à l'API Notion réussie." -ForegroundColor Green
            Write-Host "  Utilisateur: $($connection.User.name)" -ForegroundColor Gray
        } else {
            Write-Host "  Échec: Échec de la connexion à l'API Notion." -ForegroundColor Red
        }
    } else {
        Write-Host "  Test ignoré: Aucun token fourni." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Erreur lors de la connexion à l'API Notion: $_" -ForegroundColor Red
}

# Test 5: Tester la connexion à l'API GitHub (si un token est fourni)
Write-Host "`nTest 5: Tester la connexion à l'API GitHub" -ForegroundColor Yellow

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

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "Nettoyage terminé." -ForegroundColor Green
}

Write-Host "`nTests terminés." -ForegroundColor Cyan

# Test-Minimal.ps1
# Script de test minimal pour vérifier le fonctionnement de base
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste le fonctionnement de base des modules de roadmap.

.DESCRIPTION
    Ce script teste le fonctionnement de base des modules de roadmap,
    en vérifiant que les fonctions principales fonctionnent correctement.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Créer un dossier de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapTests"
if (-not (Test-Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

Write-Host "Dossier de test créé: $testDir" -ForegroundColor Cyan

# Créer une roadmap de test
$roadmapContent = @"
# Plan de test pour l'analyse de roadmaps

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

# Créer une fonction simple pour parser la roadmap
function ConvertFrom-SimpleRoadmap {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    # Vérifier que le fichier existe
    if (-not (Test-Path $FilePath)) {
        Write-Error "Le fichier de roadmap n'existe pas: $FilePath"
        return $null
    }
    
    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    
    if ([string]::IsNullOrEmpty($content)) {
        Write-Error "Le fichier de roadmap est vide: $FilePath"
        return $null
    }
    
    # Extraire le titre de la roadmap
    $titleMatch = [regex]::Match($content, "^#\s+(.+)$", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $title = if ($titleMatch.Success) { $titleMatch.Groups[1].Value.Trim() } else { "Roadmap sans titre" }
    
    # Extraire les tâches
    $tasks = @()
    $taskRegex = [regex]::new("- \[([ x])\]\s+\*\*([0-9.]+)\*\*\s+(.+?)(?:\n|$)", [System.Text.RegularExpressions.RegexOptions]::Multiline)
    $matches = $taskRegex.Matches($content)
    
    foreach ($match in $matches) {
        $status = if ($match.Groups[1].Value -eq "x") { "Completed" } else { "Pending" }
        $id = $match.Groups[2].Value.Trim()
        $title = $match.Groups[3].Value.Trim()
        
        # Créer l'objet tâche
        $task = [PSCustomObject]@{
            Id = $id
            Title = $title
            Status = $status
        }
        
        $tasks += $task
    }
    
    # Créer l'objet résultat
    $result = [PSCustomObject]@{
        Title = $title
        FilePath = $FilePath
        Tasks = $tasks
    }
    
    return $result
}

# Test 1: Parser la roadmap
Write-Host "`nTest 1: Parser la roadmap" -ForegroundColor Yellow

try {
    $result = ConvertFrom-SimpleRoadmap -FilePath $testRoadmapPath
    
    if ($null -ne $result) {
        Write-Host "  Succès: Roadmap parsée correctement." -ForegroundColor Green
        Write-Host "  Titre: $($result.Title)" -ForegroundColor Gray
        Write-Host "  Nombre de tâches: $($result.Tasks.Count)" -ForegroundColor Gray
        
        # Afficher quelques tâches
        Write-Host "  Exemples de tâches:" -ForegroundColor Gray
        for ($i = 0; $i -lt [Math]::Min(3, $result.Tasks.Count); $i++) {
            $task = $result.Tasks[$i]
            Write-Host "    $($task.Id): $($task.Title) - $($task.Status)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Échec: Échec du parsing de la roadmap." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur lors du parsing de la roadmap: $_" -ForegroundColor Red
}

# Test 2: Créer une roadmap simple
Write-Host "`nTest 2: Créer une roadmap simple" -ForegroundColor Yellow

try {
    $simpleRoadmapPath = Join-Path -Path $testDir -ChildPath "simple-roadmap.md"
    
    $simpleRoadmapContent = @"
# Roadmap simple de test

## 1. Première section
- [ ] **1.1** Première tâche
  - [ ] **1.1.1** Première sous-tâche
  - [ ] **1.1.2** Deuxième sous-tâche
- [ ] **1.2** Deuxième tâche
  - [ ] **1.2.1** Première sous-tâche
  - [ ] **1.2.2** Deuxième sous-tâche

## 2. Deuxième section
- [ ] **2.1** Première tâche
  - [ ] **2.1.1** Première sous-tâche
  - [ ] **2.1.2** Deuxième sous-tâche
- [ ] **2.2** Deuxième tâche
  - [ ] **2.2.1** Première sous-tâche
  - [ ] **2.2.2** Deuxième sous-tâche
"@
    
    $simpleRoadmapContent | Out-File -FilePath $simpleRoadmapPath -Encoding utf8
    
    if (Test-Path $simpleRoadmapPath) {
        Write-Host "  Succès: Roadmap simple créée correctement." -ForegroundColor Green
        Write-Host "  Fichier: $simpleRoadmapPath" -ForegroundColor Gray
        
        # Parser la roadmap créée
        $result = ConvertFrom-SimpleRoadmap -FilePath $simpleRoadmapPath
        
        if ($null -ne $result) {
            Write-Host "  Succès: Roadmap simple parsée correctement." -ForegroundColor Green
            Write-Host "  Titre: $($result.Title)" -ForegroundColor Gray
            Write-Host "  Nombre de tâches: $($result.Tasks.Count)" -ForegroundColor Gray
        } else {
            Write-Host "  Échec: Échec du parsing de la roadmap simple." -ForegroundColor Red
        }
    } else {
        Write-Host "  Échec: Le fichier de roadmap simple n'a pas été créé." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur lors de la création de la roadmap simple: $_" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "Nettoyage terminé." -ForegroundColor Green
}

Write-Host "`nTests terminés." -ForegroundColor Cyan


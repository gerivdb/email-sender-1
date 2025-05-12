# Test-BidirectionalSync.ps1
# Script de test pour la synchronisation bidirectionnelle
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste la synchronisation bidirectionnelle avec Notion.

.DESCRIPTION
    Ce script teste la synchronisation bidirectionnelle avec Notion,
    en vérifiant que les modifications sont correctement synchronisées
    dans les deux directions.

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
$testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapBidirectionalTests"
if (-not (Test-Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

Write-Host "Dossier de test créé: $testDir" -ForegroundColor Cyan

# Créer une roadmap de test
$roadmapContent = @"
# Plan de test pour la synchronisation bidirectionnelle

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

# Test 3: Modifier la roadmap locale
Write-Host "`nTest 3: Modifier la roadmap locale" -ForegroundColor Yellow

try {
    # Créer une copie modifiée de la roadmap
    $modifiedRoadmapPath = Join-Path -Path $testDir -ChildPath "modified-roadmap.md"
    
    # Lire le contenu de la roadmap
    $content = Get-Content -Path $testRoadmapPath -Raw
    
    # Modifier le contenu (changer le statut d'une tâche et ajouter une nouvelle tâche)
    $content = $content -replace "- \[ \] \*\*1\.2\*\* Tâche en cours de niveau 1", "- [x] **1.2** Tâche en cours de niveau 1"
    $content = $content -replace "- \[ \] \*\*2\.2\.3\*\* Tester la fonctionnalité C", "- [ ] **2.2.3** Tester la fonctionnalité C`n  - [ ] **2.2.4** Tester la fonctionnalité D"
    
    # Écrire le contenu modifié dans le nouveau fichier
    $content | Out-File -FilePath $modifiedRoadmapPath -Encoding utf8
    
    if (Test-Path $modifiedRoadmapPath) {
        Write-Host "  Succès: Roadmap modifiée créée." -ForegroundColor Green
        Write-Host "  Fichier: $modifiedRoadmapPath" -ForegroundColor Gray
        
        # Parser la roadmap modifiée
        $modifiedRoadmap = Parse-RoadmapFile -FilePath $modifiedRoadmapPath
        
        if ($null -ne $modifiedRoadmap) {
            Write-Host "  Succès: Roadmap modifiée parsée correctement." -ForegroundColor Green
            Write-Host "  Titre: $($modifiedRoadmap.Title)" -ForegroundColor Gray
            Write-Host "  Nombre de tâches: $($modifiedRoadmap.Tasks.Count)" -ForegroundColor Gray
            
            # Vérifier les modifications
            $task12 = $modifiedRoadmap.Tasks | Where-Object { $_.Id -eq "1.2" } | Select-Object -First 1
            $task224 = $modifiedRoadmap.Tasks | Where-Object { $_.Id -eq "2.2.4" } | Select-Object -First 1
            
            if ($null -ne $task12 -and $task12.Status -eq "Completed") {
                Write-Host "  Succès: Statut de la tâche 1.2 modifié correctement." -ForegroundColor Green
            } else {
                Write-Host "  Échec: Statut de la tâche 1.2 non modifié." -ForegroundColor Red
            }
            
            if ($null -ne $task224) {
                Write-Host "  Succès: Tâche 2.2.4 ajoutée correctement." -ForegroundColor Green
            } else {
                Write-Host "  Échec: Tâche 2.2.4 non ajoutée." -ForegroundColor Red
            }
        } else {
            Write-Host "  Échec: Échec du parsing de la roadmap modifiée." -ForegroundColor Red
        }
    } else {
        Write-Host "  Échec: Le fichier de roadmap modifiée n'a pas été créé." -ForegroundColor Red
    }
} catch {
    Write-Host "  Erreur lors de la modification de la roadmap: $_" -ForegroundColor Red
}

# Test 4: Tester la synchronisation bidirectionnelle (si un token est fourni)
Write-Host "`nTest 4: Tester la synchronisation bidirectionnelle" -ForegroundColor Yellow

try {
    Write-Host "  Token d'intégration Notion (laisser vide pour ignorer): " -ForegroundColor Yellow -NoNewline
    $notionToken = Read-Host
    
    if (-not [string]::IsNullOrEmpty($notionToken)) {
        Write-Host "  ID de la page parent Notion: " -ForegroundColor Yellow -NoNewline
        $parentPageId = Read-Host
        
        if (-not [string]::IsNullOrEmpty($parentPageId)) {
            # Se connecter à l'API Notion
            $connection = Connect-NotionApi -Token $notionToken
            
            if ($null -ne $connection) {
                Write-Host "  Succès: Connexion à l'API Notion réussie." -ForegroundColor Green
                
                # Synchroniser la roadmap avec Notion
                Write-Host "  Synchronisation de la roadmap avec Notion..." -ForegroundColor Gray
                
                $result = Sync-RoadmapToNotion -Connection $connection -RoadmapPath $testRoadmapPath -ParentPageId $parentPageId
                
                if ($null -ne $result) {
                    Write-Host "  Succès: Roadmap synchronisée avec Notion." -ForegroundColor Green
                    Write-Host "  Base de données Notion: $($result.DatabaseId)" -ForegroundColor Gray
                    
                    # Synchroniser bidirectionnellement la roadmap modifiée
                    Write-Host "  Synchronisation bidirectionnelle de la roadmap modifiée..." -ForegroundColor Gray
                    
                    $bidirectionalResult = Sync-RoadmapBidirectional -Connection $connection -RoadmapPath $modifiedRoadmapPath -DatabaseId $result.DatabaseId -Direction "Both" -ConflictResolution "Remote"
                    
                    if ($null -ne $bidirectionalResult) {
                        Write-Host "  Succès: Synchronisation bidirectionnelle réussie." -ForegroundColor Green
                        Write-Host "  Tâches ajoutées: $($bidirectionalResult.TasksAdded)" -ForegroundColor Gray
                        Write-Host "  Tâches supprimées: $($bidirectionalResult.TasksDeleted)" -ForegroundColor Gray
                        Write-Host "  Conflits: $($bidirectionalResult.Conflicts)" -ForegroundColor Gray
                        Write-Host "  Conflits résolus: $($bidirectionalResult.ResolvedConflicts)" -ForegroundColor Gray
                    } else {
                        Write-Host "  Échec: Échec de la synchronisation bidirectionnelle." -ForegroundColor Red
                    }
                } else {
                    Write-Host "  Échec: Échec de la synchronisation avec Notion." -ForegroundColor Red
                }
            } else {
                Write-Host "  Échec: Échec de la connexion à l'API Notion." -ForegroundColor Red
            }
        } else {
            Write-Host "  Test ignoré: Aucun ID de page parent fourni." -ForegroundColor Yellow
        }
    } else {
        Write-Host "  Test ignoré: Aucun token fourni." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Erreur lors de la synchronisation bidirectionnelle: $_" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "Nettoyage terminé." -ForegroundColor Green
}

Write-Host "`nTests terminés." -ForegroundColor Cyan

# Test-ImportExport.ps1
# Script de test pour l'import/export de bases de données Notion
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste l'import/export de bases de données Notion.

.DESCRIPTION
    Ce script teste l'import/export de bases de données Notion,
    en vérifiant que les bases de données sont correctement exportées et importées.

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
$importExportNotionPath = Join-Path -Path $integrationPath -ChildPath "Import-ExportNotion.ps1"
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

if (Test-Path $importExportNotionPath) {
    . $importExportNotionPath
    Write-Host "  Module Import-ExportNotion.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Import-ExportNotion.ps1 introuvable à l'emplacement: $importExportNotionPath" -ForegroundColor Red
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
$testDir = Join-Path -Path $env:TEMP -ChildPath "NotionImportExportTests"
if (-not (Test-Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

Write-Host "Dossier de test créé: $testDir" -ForegroundColor Cyan

# Créer une roadmap de test
$roadmapContent = @"
# Plan de test pour l'import/export

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

# Test 2: Créer une base de données Notion et l'exporter (si un token est fourni)
Write-Host "`nTest 2: Créer une base de données Notion et l'exporter" -ForegroundColor Yellow

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
                
                # Créer une base de données Notion à partir de la roadmap
                Write-Host "  Création d'une base de données Notion..." -ForegroundColor Gray
                
                $result = Sync-RoadmapToNotion -Connection $connection -RoadmapPath $testRoadmapPath -ParentPageId $parentPageId
                
                if ($null -ne $result) {
                    Write-Host "  Succès: Base de données Notion créée." -ForegroundColor Green
                    Write-Host "  Base de données Notion: $($result.DatabaseId)" -ForegroundColor Gray
                    
                    # Exporter la base de données Notion
                    Write-Host "  Export de la base de données Notion..." -ForegroundColor Gray
                    
                    $exportPath = Join-Path -Path $testDir -ChildPath "notion-export.json"
                    $exportResult = Export-NotionDatabase -Connection $connection -DatabaseId $result.DatabaseId -OutputPath $exportPath -IncludeContent
                    
                    if ($null -ne $exportResult) {
                        Write-Host "  Succès: Base de données Notion exportée." -ForegroundColor Green
                        Write-Host "  Fichier d'export: $($exportResult.OutputPath)" -ForegroundColor Gray
                        
                        # Exporter la base de données Notion vers un fichier Markdown
                        Write-Host "  Export de la base de données Notion vers Markdown..." -ForegroundColor Gray
                        
                        $markdownPath = Join-Path -Path $testDir -ChildPath "notion-export.md"
                        $markdownResult = Export-NotionToMarkdown -Connection $connection -DatabaseId $result.DatabaseId -OutputPath $markdownPath
                        
                        if ($null -ne $markdownResult) {
                            Write-Host "  Succès: Base de données Notion exportée vers Markdown." -ForegroundColor Green
                            Write-Host "  Fichier Markdown: $($markdownResult.OutputPath)" -ForegroundColor Gray
                        } else {
                            Write-Host "  Échec: Échec de l'export de la base de données Notion vers Markdown." -ForegroundColor Red
                        }
                    } else {
                        Write-Host "  Échec: Échec de l'export de la base de données Notion." -ForegroundColor Red
                    }
                } else {
                    Write-Host "  Échec: Échec de la création de la base de données Notion." -ForegroundColor Red
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
    Write-Host "  Erreur lors de la création et de l'export de la base de données Notion: $_" -ForegroundColor Red
}

# Test 3: Importer une base de données Notion (si un token est fourni)
Write-Host "`nTest 3: Importer une base de données Notion" -ForegroundColor Yellow

try {
    if (-not [string]::IsNullOrEmpty($notionToken) -and -not [string]::IsNullOrEmpty($parentPageId) -and (Test-Path $exportPath)) {
        # Se connecter à l'API Notion (si ce n'est pas déjà fait)
        if ($null -eq $connection) {
            $connection = Connect-NotionApi -Token $notionToken
        }
        
        if ($null -ne $connection) {
            Write-Host "  Succès: Connexion à l'API Notion réussie." -ForegroundColor Green
            
            # Importer la base de données Notion
            Write-Host "  Import de la base de données Notion..." -ForegroundColor Gray
            
            $importResult = Import-NotionDatabase -Connection $connection -InputPath $exportPath -ParentPageId $parentPageId
            
            if ($null -ne $importResult) {
                Write-Host "  Succès: Base de données Notion importée." -ForegroundColor Green
                Write-Host "  Base de données Notion: $($importResult.DatabaseId)" -ForegroundColor Gray
                Write-Host "  Pages créées: $($importResult.PagesCreated)" -ForegroundColor Gray
                Write-Host "  Pages mises à jour: $($importResult.PagesUpdated)" -ForegroundColor Gray
                
                # Importer un fichier Markdown vers une base de données Notion
                Write-Host "  Import d'un fichier Markdown vers Notion..." -ForegroundColor Gray
                
                $importMarkdownResult = Import-MarkdownToNotion -Connection $connection -InputPath $testRoadmapPath -ParentPageId $parentPageId
                
                if ($null -ne $importMarkdownResult) {
                    Write-Host "  Succès: Fichier Markdown importé vers Notion." -ForegroundColor Green
                    Write-Host "  Base de données Notion: $($importMarkdownResult.DatabaseId)" -ForegroundColor Gray
                } else {
                    Write-Host "  Échec: Échec de l'import du fichier Markdown vers Notion." -ForegroundColor Red
                }
            } else {
                Write-Host "  Échec: Échec de l'import de la base de données Notion." -ForegroundColor Red
            }
        } else {
            Write-Host "  Échec: Échec de la connexion à l'API Notion." -ForegroundColor Red
        }
    } else {
        Write-Host "  Test ignoré: Informations manquantes pour l'import." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Erreur lors de l'import de la base de données Notion: $_" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "Nettoyage terminé." -ForegroundColor Green
}

Write-Host "`nTests terminés." -ForegroundColor Cyan

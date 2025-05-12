# Test-NotionTemplates.ps1
# Script de test pour les templates Notion
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste les fonctionnalités de gestion des templates Notion.

.DESCRIPTION
    Ce script teste les fonctionnalités de gestion des templates Notion,
    en vérifiant que les templates sont correctement créés et appliqués.

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
$manageNotionTemplatesPath = Join-Path -Path $integrationPath -ChildPath "Manage-NotionTemplates.ps1"
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

if (Test-Path $manageNotionTemplatesPath) {
    . $manageNotionTemplatesPath
    Write-Host "  Module Manage-NotionTemplates.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Manage-NotionTemplates.ps1 introuvable à l'emplacement: $manageNotionTemplatesPath" -ForegroundColor Red
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
$testDir = Join-Path -Path $env:TEMP -ChildPath "NotionTemplatesTests"
if (-not (Test-Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

Write-Host "Dossier de test créé: $testDir" -ForegroundColor Cyan

# Créer une roadmap de test
$roadmapContent = @"
# Plan de test pour les templates Notion

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

# Test 2: Créer une base de données Notion et un template (si un token est fourni)
Write-Host "`nTest 2: Créer une base de données Notion et un template" -ForegroundColor Yellow

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
                    
                    # Créer un template à partir de la base de données
                    Write-Host "  Création d'un template à partir de la base de données..." -ForegroundColor Gray
                    
                    $templatePath = Join-Path -Path $testDir -ChildPath "test-template.json"
                    $templateResult = New-NotionTemplate -Connection $connection -DatabaseId $result.DatabaseId -TemplateName "Test Template" -TemplateDescription "Template de test pour les roadmaps" -OutputPath $templatePath -IncludeContent
                    
                    if ($null -ne $templateResult) {
                        Write-Host "  Succès: Template créé." -ForegroundColor Green
                        Write-Host "  Fichier de template: $($templateResult.OutputPath)" -ForegroundColor Gray
                    } else {
                        Write-Host "  Échec: Échec de la création du template." -ForegroundColor Red
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
    Write-Host "  Erreur lors de la création de la base de données Notion et du template: $_" -ForegroundColor Red
}

# Test 3: Lister les templates disponibles
Write-Host "`nTest 3: Lister les templates disponibles" -ForegroundColor Yellow

try {
    $templates = Get-NotionTemplates -TemplatesDir $testDir
    
    if ($null -ne $templates -and $templates.Count -gt 0) {
        Write-Host "  Succès: Templates listés correctement." -ForegroundColor Green
        Write-Host "  Nombre de templates: $($templates.Count)" -ForegroundColor Gray
        
        # Afficher les templates
        Write-Host "  Templates disponibles:" -ForegroundColor Gray
        foreach ($template in $templates) {
            Write-Host "    $($template.Name): $($template.Description)" -ForegroundColor Gray
            Write-Host "      Créé le: $($template.CreatedAt)" -ForegroundColor Gray
            Write-Host "      Nombre de pages: $($template.PageCount)" -ForegroundColor Gray
            Write-Host "      Chemin: $($template.Path)" -ForegroundColor Gray
        }
    } else {
        Write-Host "  Aucun template trouvé." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Erreur lors de la liste des templates: $_" -ForegroundColor Red
}

# Test 4: Appliquer un template (si un token est fourni)
Write-Host "`nTest 4: Appliquer un template" -ForegroundColor Yellow

try {
    if (-not [string]::IsNullOrEmpty($notionToken) -and -not [string]::IsNullOrEmpty($parentPageId) -and (Test-Path $templatePath)) {
        # Se connecter à l'API Notion (si ce n'est pas déjà fait)
        if ($null -eq $connection) {
            $connection = Connect-NotionApi -Token $notionToken
        }
        
        if ($null -ne $connection) {
            Write-Host "  Succès: Connexion à l'API Notion réussie." -ForegroundColor Green
            
            # Appliquer le template
            Write-Host "  Application du template..." -ForegroundColor Gray
            
            $applyResult = Apply-NotionTemplate -Connection $connection -TemplatePath $templatePath -ParentPageId $parentPageId -IncludeContent
            
            if ($null -ne $applyResult) {
                Write-Host "  Succès: Template appliqué." -ForegroundColor Green
                Write-Host "  Base de données Notion: $($applyResult.DatabaseId)" -ForegroundColor Gray
                Write-Host "  Pages créées: $($applyResult.PagesCreated)" -ForegroundColor Gray
            } else {
                Write-Host "  Échec: Échec de l'application du template." -ForegroundColor Red
            }
        } else {
            Write-Host "  Échec: Échec de la connexion à l'API Notion." -ForegroundColor Red
        }
    } else {
        Write-Host "  Test ignoré: Informations manquantes pour l'application du template." -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Erreur lors de l'application du template: $_" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "Nettoyage terminé." -ForegroundColor Green
}

Write-Host "`nTests terminés." -ForegroundColor Cyan

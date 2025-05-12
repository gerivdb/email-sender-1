# Test-N8nIntegration.ps1
# Script de test pour l'intégration avec n8n
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste l'intégration avec n8n.

.DESCRIPTION
    Ce script teste l'intégration avec n8n, en vérifiant que l'API,
    les nodes et les workflows fonctionnent correctement.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$integrationPath = Join-Path -Path $parentPath -ChildPath "integration"

$connectN8nRoadmapPath = Join-Path -Path $integrationPath -ChildPath "Connect-N8nRoadmap.ps1"
$generateN8nNodesPath = Join-Path -Path $integrationPath -ChildPath "Generate-N8nNodes.ps1"
$createN8nWorkflowsPath = Join-Path -Path $integrationPath -ChildPath "Create-N8nWorkflows.ps1"

Write-Host "Chargement des modules..." -ForegroundColor Cyan

if (Test-Path $connectN8nRoadmapPath) {
    . $connectN8nRoadmapPath
    Write-Host "  Module Connect-N8nRoadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Connect-N8nRoadmap.ps1 introuvable à l'emplacement: $connectN8nRoadmapPath" -ForegroundColor Red
    exit
}

if (Test-Path $generateN8nNodesPath) {
    . $generateN8nNodesPath
    Write-Host "  Module Generate-N8nNodes.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Generate-N8nNodes.ps1 introuvable à l'emplacement: $generateN8nNodesPath" -ForegroundColor Red
    exit
}

if (Test-Path $createN8nWorkflowsPath) {
    . $createN8nWorkflowsPath
    Write-Host "  Module Create-N8nWorkflows.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Create-N8nWorkflows.ps1 introuvable à l'emplacement: $createN8nWorkflowsPath" -ForegroundColor Red
    exit
}

# Créer un dossier de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "RoadmapN8nTests"
if (-not (Test-Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

$roadmapsPath = Join-Path -Path $testDir -ChildPath "roadmaps"
if (-not (Test-Path $roadmapsPath)) {
    New-Item -Path $roadmapsPath -ItemType Directory -Force | Out-Null
}

$modelsPath = Join-Path -Path $testDir -ChildPath "models"
if (-not (Test-Path $modelsPath)) {
    New-Item -Path $modelsPath -ItemType Directory -Force | Out-Null
}

$workflowsPath = Join-Path -Path $testDir -ChildPath "workflows"
if (-not (Test-Path $workflowsPath)) {
    New-Item -Path $workflowsPath -ItemType Directory -Force | Out-Null
}

$nodesPath = Join-Path -Path $testDir -ChildPath "nodes"
if (-not (Test-Path $nodesPath)) {
    New-Item -Path $nodesPath -ItemType Directory -Force | Out-Null
}

Write-Host "Dossiers de test créés:" -ForegroundColor Cyan
Write-Host "  - $testDir" -ForegroundColor Gray
Write-Host "  - $roadmapsPath" -ForegroundColor Gray
Write-Host "  - $modelsPath" -ForegroundColor Gray
Write-Host "  - $workflowsPath" -ForegroundColor Gray
Write-Host "  - $nodesPath" -ForegroundColor Gray

# Créer une roadmap de test
$roadmapContent = @"
# Plan de test pour l'intégration avec n8n

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

$testRoadmapPath = Join-Path -Path $roadmapsPath -ChildPath "test-roadmap.md"
$roadmapContent | Out-File -FilePath $testRoadmapPath -Encoding utf8

Write-Host "Roadmap de test créée: $testRoadmapPath" -ForegroundColor Cyan

# Test 1: Démarrer l'API
Write-Host "`nTest 1: Démarrer l'API" -ForegroundColor Yellow

try {
    Write-Host "  Démarrage de l'API..." -ForegroundColor Gray
    $api = Start-N8nRoadmapApi -Port 3000 -RoadmapsPath $roadmapsPath -ModelsPath $modelsPath -EnableCors
    
    if ($null -ne $api) {
        Write-Host "    Succès: API démarrée sur $($api.Endpoint.Url)" -ForegroundColor Green
        
        # Tester l'API avec une requête HTTP
        try {
            Write-Host "  Test de l'API avec une requête HTTP..." -ForegroundColor Gray
            $response = Invoke-RestMethod -Uri "http://localhost:3000/api/roadmap/roadmaps" -Method Get
            
            if ($null -ne $response -and $null -ne $response.roadmaps) {
                Write-Host "    Succès: API répond correctement." -ForegroundColor Green
                Write-Host "    Nombre de roadmaps: $($response.roadmaps.Count)" -ForegroundColor Gray
            } else {
                Write-Host "    Échec: L'API ne répond pas correctement." -ForegroundColor Red
            }
        } catch {
            Write-Host "    Erreur lors du test de l'API: $_" -ForegroundColor Red
        }
        
        # Arrêter l'API
        Write-Host "  Arrêt de l'API..." -ForegroundColor Gray
        Stop-N8nRoadmapApi -Api $api
        Write-Host "    API arrêtée." -ForegroundColor Gray
    } else {
        Write-Host "    Échec: Impossible de démarrer l'API." -ForegroundColor Red
    }
} catch {
    Write-Host "    Erreur lors du démarrage de l'API: $_" -ForegroundColor Red
}

# Test 2: Générer les nodes n8n
Write-Host "`nTest 2: Générer les nodes n8n" -ForegroundColor Yellow

try {
    Write-Host "  Génération des nodes n8n..." -ForegroundColor Gray
    $nodes = New-N8nRoadmapNodes -OutputPath $nodesPath
    
    if ($null -ne $nodes -and $nodes.Count -gt 0) {
        Write-Host "    Succès: Nodes n8n générés." -ForegroundColor Green
        Write-Host "    Nombre de nodes: $($nodes.Count)" -ForegroundColor Gray
        
        foreach ($node in $nodes) {
            Write-Host "      - $($node.DisplayName) ($($node.Name))" -ForegroundColor Gray
            
            # Vérifier que les fichiers ont été créés
            if (Test-Path $node.JsonPath -and Test-Path $node.TsPath) {
                Write-Host "        Fichiers créés: OK" -ForegroundColor Green
            } else {
                Write-Host "        Fichiers créés: NON" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "    Échec: Aucun node n8n généré." -ForegroundColor Red
    }
} catch {
    Write-Host "    Erreur lors de la génération des nodes n8n: $_" -ForegroundColor Red
}

# Test 3: Créer les workflows n8n
Write-Host "`nTest 3: Créer les workflows n8n" -ForegroundColor Yellow

try {
    Write-Host "  Création des workflows n8n..." -ForegroundColor Gray
    $workflows = New-N8nRoadmapWorkflows -OutputPath $workflowsPath
    
    if ($null -ne $workflows -and $workflows.Count -gt 0) {
        Write-Host "    Succès: Workflows n8n créés." -ForegroundColor Green
        Write-Host "    Nombre de workflows: $($workflows.Count)" -ForegroundColor Gray
        
        foreach ($workflow in $workflows) {
            Write-Host "      - $($workflow.Name)" -ForegroundColor Gray
            
            # Vérifier que le fichier a été créé
            if (Test-Path $workflow.Path) {
                Write-Host "        Fichier créé: OK" -ForegroundColor Green
                
                # Vérifier le contenu du fichier
                $content = Get-Content -Path $workflow.Path -Raw | ConvertFrom-Json
                
                if ($null -ne $content -and $null -ne $content.nodes -and $content.nodes.Count -gt 0) {
                    Write-Host "        Contenu valide: OK" -ForegroundColor Green
                    Write-Host "        Nombre de nodes: $($content.nodes.Count)" -ForegroundColor Gray
                } else {
                    Write-Host "        Contenu valide: NON" -ForegroundColor Red
                }
            } else {
                Write-Host "        Fichier créé: NON" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "    Échec: Aucun workflow n8n créé." -ForegroundColor Red
    }
} catch {
    Write-Host "    Erreur lors de la création des workflows n8n: $_" -ForegroundColor Red
}

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..." -ForegroundColor Cyan
if (Test-Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
    Write-Host "Nettoyage terminé." -ForegroundColor Green
}

Write-Host "`nTests terminés." -ForegroundColor Cyan

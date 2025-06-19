#!/usr/bin/env pwsh
# Script pour identifier les dépendances entre workflows N8N
# Tâche Atomique 013: Identifier Dépendances Inter-Workflows
# Durée: 20 minutes max

param(
    [string]$WorkflowsFile = "output/phase1/n8n-workflows-export.json",
    [string]$OutputFile = "output/phase1/workflow-dependencies.graphml"
)

Write-Host "🔍 TÂCHE 013: Identifier Dépendances Inter-Workflows" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green

# Créer le répertoire de sortie
$outputDir = Split-Path $OutputFile -Parent
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Charger les workflows exportés
if (!(Test-Path $WorkflowsFile)) {
    Write-Warning "Fichier workflows non trouvé: $WorkflowsFile"
    Write-Host "Exécution de la tâche 009 d'abord..."
    & "$PSScriptRoot/task-009-scanner-workflows-n8n.ps1"
}

$workflows = Get-Content $WorkflowsFile | ConvertFrom-Json

# Analyser les dépendances
$dependencies = @()
$workflows_nodes = @{}

# Construire l'index des workflows et leurs nodes
foreach ($workflow in $workflows.workflows) {
    $workflows_nodes[$workflow.id] = @{
        "name" = $workflow.name
        "nodes" = $workflow.nodes
        "active" = $workflow.active
        "webhooks" = @()
        "api_calls" = @()
        "database_ops" = @()
    }
    
    # Identifier les webhooks et API calls
    foreach ($node in $workflow.nodes) {
        if ($node.type -like "*webhook*") {
            $workflows_nodes[$workflow.id].webhooks += $node.parameters.path
        }
        if ($node.type -like "*httpRequest*") {
            $workflows_nodes[$workflow.id].api_calls += $node.parameters.url
        }
        if ($node.type -like "*postgres*" -or $node.type -like "*mysql*") {
            $workflows_nodes[$workflow.id].database_ops += $node.parameters.query
        }
    }
}

# Analyser les dépendances croisées
foreach ($workflow1 in $workflows.workflows) {
    foreach ($workflow2 in $workflows.workflows) {
        if ($workflow1.id -ne $workflow2.id) {
            # Vérifier si workflow1 appelle workflow2 via webhook
            foreach ($node in $workflow1.nodes) {
                if ($node.type -like "*httpRequest*" -and $node.parameters.url) {
                    $url = $node.parameters.url
                    foreach ($webhook in $workflows_nodes[$workflow2.id].webhooks) {
                        if ($url -like "*$webhook*") {
                            $dependencies += @{
                                "source" = $workflow1.id
                                "target" = $workflow2.id
                                "type" = "webhook_call"
                                "description" = "Workflow '$($workflow1.name)' appelle webhook '$webhook' de workflow '$($workflow2.name)'"
                            }
                        }
                    }
                }
                
                # Vérifier les dépendances de données (même base de données)
                if ($node.type -like "*postgres*" -or $node.type -like "*mysql*") {
                    foreach ($otherNode in $workflows_nodes[$workflow2.id].nodes) {
                        if (($otherNode.type -like "*postgres*" -or $otherNode.type -like "*mysql*") -and
                            $node.parameters.database -eq $otherNode.parameters.database) {
                            $dependencies += @{
                                "source" = $workflow1.id
                                "target" = $workflow2.id
                                "type" = "database_shared"
                                "description" = "Workflows partagent la base de données '$($node.parameters.database)'"
                            }
                        }
                    }
                }
            }
        }
    }
}

# Générer le fichier GraphML
$graphml = @"
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
                             http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
  <key id="name" for="node" attr.name="name" attr.type="string"/>
  <key id="active" for="node" attr.name="active" attr.type="boolean"/>
  <key id="type" for="edge" attr.name="type" attr.type="string"/>
  <key id="description" for="edge" attr.name="description" attr.type="string"/>
  
  <graph id="workflow-dependencies" edgedefault="directed">
"@

# Ajouter les nodes (workflows)
foreach ($workflow in $workflows.workflows) {
    $graphml += @"
    <node id="$($workflow.id)">
      <data key="name">$($workflow.name)</data>
      <data key="active">$($workflow.active)</data>
    </node>
"@
}

# Ajouter les edges (dépendances)
$edgeId = 0
foreach ($dep in $dependencies) {
    $graphml += @"
    <edge id="e$edgeId" source="$($dep.source)" target="$($dep.target)">
      <data key="type">$($dep.type)</data>
      <data key="description">$($dep.description)</data>
    </edge>
"@
    $edgeId++
}

$graphml += @"
  </graph>
</graphml>
"@

# Sauvegarder le fichier GraphML
$graphml | Out-File -FilePath $OutputFile -Encoding UTF8

# Générer aussi un rapport texte
$reportFile = $OutputFile -replace "\.graphml$", ".md"
$report = @"
# 🔗 ANALYSE DES DÉPENDANCES INTER-WORKFLOWS

**Date d'analyse**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Fichier source**: $WorkflowsFile  
**Total workflows analysés**: $($workflows.workflows.Count)  
**Dépendances identifiées**: $($dependencies.Count)

---

## 📊 RÉSUMÉ DES DÉPENDANCES

"@

$depsByType = $dependencies | Group-Object type
foreach ($group in $depsByType) {
    $report += "- **$($group.Name)**: $($group.Count) dépendances`n"
}

$report += @"

---

## 🔗 DÉTAIL DES DÉPENDANCES

"@

foreach ($dep in $dependencies) {
    $sourceWorkflow = $workflows.workflows | Where-Object { $_.id -eq $dep.source }
    $targetWorkflow = $workflows.workflows | Where-Object { $_.id -eq $dep.target }
    
    $report += @"

### $($sourceWorkflow.name) → $($targetWorkflow.name)
- **Type**: $($dep.type)
- **Description**: $($dep.description)
- **Source**: $($dep.source)
- **Target**: $($dep.target)

"@
}

$report += @"

---

## 🎯 ANALYSE ET IMPACT

### Impact sur la Migration

"@

if ($dependencies.Count -eq 0) {
    $report += "✅ **Aucune dépendance critique identifiée** - Les workflows peuvent être migrés indépendamment.`n"
} else {
    $report += @"
⚠️ **$($dependencies.Count) dépendances identifiées** - Migration nécessite planification:

1. **Dépendances Webhook**: Maintenir compatibilité API
2. **Dépendances Database**: Coordonner accès aux données
3. **Ordre de migration**: Respecter la chaîne de dépendances

"@
}

$report += @"

### Recommandations

1. **Grouper les workflows dépendants** pour migration simultanée
2. **Maintenir les APIs** pendant la période de transition
3. **Tester les intégrations** après chaque migration
4. **Surveiller les logs** pour détecter les appels manqués

---

**📝 Rapport généré automatiquement par la Tâche 013**
"@

$report | Out-File -FilePath $reportFile -Encoding UTF8

Write-Host "✅ Analyse des dépendances terminée" -ForegroundColor Green
Write-Host "📁 GraphML: $OutputFile" -ForegroundColor Cyan
Write-Host "📁 Rapport: $reportFile" -ForegroundColor Cyan
Write-Host "📊 Dépendances trouvées: $($dependencies.Count)" -ForegroundColor Cyan

# Afficher un résumé
if ($dependencies.Count -gt 0) {
    Write-Host "`n📋 RÉSUMÉ DES DÉPENDANCES:" -ForegroundColor Yellow
    foreach ($group in $depsByType) {
        Write-Host "  - $($group.Name): $($group.Count)" -ForegroundColor White
    }
} else {
    Write-Host "`n✅ Aucune dépendance critique trouvée" -ForegroundColor Green
}

Write-Host "`n🎯 TÂCHE 013 TERMINÉE avec succès!" -ForegroundColor Green

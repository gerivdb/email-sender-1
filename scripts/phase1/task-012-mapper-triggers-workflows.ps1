#!/usr/bin/env pwsh
# Script pour mapper les triggers des workflows N8N
# Tâche Atomique 012: Mapper Triggers Workflows
# Durée: 15 minutes max

param(
   [string]$WorkflowsFile = "output/phase1/n8n-workflows-export.json",
   [string]$OutputFile = "output/phase1/triggers-mapping.md"
)

Write-Host "🔍 TÂCHE 012: Mapper Triggers Workflows" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Green

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

# Analyser les triggers
$triggerMapping = @{
   "webhook"  = @()
   "schedule" = @()
   "manual"   = @()
   "database" = @()
   "email"    = @()
   "other"    = @()
}

$triggerStats = @{}

foreach ($workflow in $workflows.workflows) {
   # Trouver le premier node (trigger)
   $triggerNode = $workflow.nodes | Where-Object { $_.type -like "*trigger*" -or $_.position[0] -eq 20 } | Select-Object -First 1
    
   if ($triggerNode) {
      $triggerType = switch -Wildcard ($triggerNode.type) {
         "*webhook*" { "webhook" }
         "*schedule*" { "schedule" }
         "*manual*" { "manual" }
         "*email*" { "email" }
         "*database*" { "database" }
         "*postgres*" { "database" }
         "*mysql*" { "database" }
         default { "other" }
      }
        
      $triggerMapping[$triggerType] += @{
         "workflow_id"   = $workflow.id
         "workflow_name" = $workflow.name
         "trigger_node"  = $triggerNode.name
         "trigger_type"  = $triggerNode.type
         "active"        = $workflow.active
         "parameters"    = $triggerNode.parameters
      }
        
      if ($triggerStats.ContainsKey($triggerType)) {
         $triggerStats[$triggerType]++
      }
      else {
         $triggerStats[$triggerType] = 1
      }
   }
}

# Générer le rapport Markdown
$report = @"
# 📋 MAPPING DES TRIGGERS WORKFLOWS N8N

**Date d'analyse**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**Fichier source**: $WorkflowsFile  
**Total workflows analysés**: $($workflows.workflows.Count)

---

## 📊 STATISTIQUES GLOBALES

"@

foreach ($type in $triggerStats.Keys | Sort-Object) {
   $count = $triggerStats[$type]
   $percentage = [math]::Round(($count / $workflows.workflows.Count) * 100, 1)
   $report += "- **${type}**: $count workflows ($percentage%)`n"
}

$report += @"

---

## 🔗 DÉTAIL DES TRIGGERS PAR TYPE

"@

foreach ($type in $triggerMapping.Keys | Sort-Object) {
   if ($triggerMapping[$type].Count -gt 0) {
      $report += @"

### 🎯 TRIGGERS $($type.ToUpper())

"@
      foreach ($trigger in $triggerMapping[$type]) {
         $status = if ($trigger.active) { "🟢 Active" } else { "🔴 Inactive" }
         $report += @"
#### $($trigger.workflow_name) ($($trigger.workflow_id))
- **Status**: $status
- **Node**: $($trigger.trigger_node)
- **Type**: $($trigger.trigger_type)

"@
         if ($trigger.parameters) {
            $report += "**Paramètres**:`n"
            $params = $trigger.parameters | ConvertTo-Json -Depth 3
            $report += "``````json`n$params`n```````n`n"
         }
      }
   }
}

$report += @"

---

## 🎯 ANALYSE ET RECOMMANDATIONS

### Types de Triggers Identifiés

"@

foreach ($type in $triggerMapping.Keys | Sort-Object) {
   $count = $triggerMapping[$type].Count
   if ($count -gt 0) {
      $report += @"
- **$($type.ToUpper())** ($count workflows):
"@
      switch ($type) {
         "webhook" {
            $report += " API endpoints pour intégrations externes`n"
         }
         "schedule" {
            $report += " Tâches programmées automatiques`n"
         }
         "manual" {
            $report += " Déclenchement manuel par utilisateur`n"
         }
         "email" {
            $report += " Triggers basés sur réception email`n"
         }
         "database" {
            $report += " Triggers basés sur événements database`n"
         }
         "other" {
            $report += " Autres types de triggers`n"
         }
      }
   }
}

$report += @"

### Points d'Attention pour Migration

1. **Webhooks**: Nécessitent exposition HTTP publique
2. **Schedulers**: Peuvent être remplacés par cron jobs Go
3. **Email Triggers**: Requièrent accès IMAP/POP3
4. **Database Triggers**: Nécessitent connectivité base de données

### Prochaines Étapes

- Valider la connectivité pour chaque type de trigger
- Planifier la migration par ordre de priorité
- Identifier les dépendances critiques

---

**📝 Rapport généré automatiquement par la Tâche 012**
"@

# Sauvegarder le rapport
$report | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "✅ Mapping des triggers terminé" -ForegroundColor Green
Write-Host "📁 Fichier: $OutputFile" -ForegroundColor Cyan
Write-Host "📊 Types de triggers trouvés: $($triggerStats.Keys.Count)" -ForegroundColor Cyan

# Afficher un résumé
Write-Host "`n📋 RÉSUMÉ DES TRIGGERS:" -ForegroundColor Yellow
foreach ($type in $triggerStats.Keys | Sort-Object) {
   Write-Host "  - $($type.ToUpper()): $($triggerStats[$type]) workflows" -ForegroundColor White
}

Write-Host "`n🎯 TÂCHE 012 TERMINÉE avec succès!" -ForegroundColor Green

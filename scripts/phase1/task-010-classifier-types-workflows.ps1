# Task 010: Classifier Types Workflows
# Durée: 15 minutes max
# Sortie: workflow-classification.yaml

param(
   [string]$OutputDir = "output/phase1",
   [string]$InputFile = "",
   [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date

Write-Host "🚀 PHASE 1.2.1 - TÂCHE 010: Classifier Types Workflows" -ForegroundColor Cyan
Write-Host "=" * 60

# Création du répertoire de sortie
if (!(Test-Path $OutputDir)) {
   New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$Results = @{
   task                    = "010-classifier-types-workflows"
   timestamp               = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
   source_data             = @{}
   classification_criteria = @{}
   workflow_types          = @{}
   complexity_analysis     = @{}
   trigger_analysis        = @{}
   email_provider_analysis = @{}
   taxonomie               = @{}
   summary                 = @{}
   errors                  = @()
}

# Définir les critères de classification
$Results.classification_criteria = @{
   trigger_types     = @(
      "webhook", "manual", "cron", "interval", "emailTrigger", 
      "httpRequest", "apiCall", "database", "file", "form"
   )
   email_providers   = @(
      "gmail", "outlook", "smtp", "sendgrid", "mailgun", 
      "ses", "mandrill", "postmark", "sparkpost", "custom"
   )
   complexity_levels = @(
      "simple", "medium", "complex", "enterprise"
   )
   node_categories   = @(
      "trigger", "action", "transform", "condition", "loop", 
      "webhook", "email", "database", "api", "file"
   )
}

Write-Host "📂 Chargement des données workflows..." -ForegroundColor Yellow

# Charger les données depuis le fichier d'export précédent
try {
   $inputFiles = @()
   
   if ($InputFile -and (Test-Path $InputFile)) {
      $inputFiles += $InputFile
   }
   else {
      # Chercher les fichiers d'export de la tâche 009
      $possibleFiles = @(
         (Join-Path $OutputDir "n8n-workflows-export.json"),
         (Join-Path $OutputDir "n8n-cli-export.json")
      )
      
      foreach ($file in $possibleFiles) {
         if (Test-Path $file) {
            $inputFiles += $file
         }
      }
   }
   
   $allWorkflows = @()
   
   foreach ($file in $inputFiles) {
      Write-Host "📄 Lecture: $file" -ForegroundColor White
      $content = Get-Content $file -Raw | ConvertFrom-Json
      
      if ($content.workflows_found) {
         $allWorkflows += $content.workflows_found
         $Results.source_data[$file] = @{
            workflows_count = $content.workflows_found.Count
            source_type     = "task_009_export"
         }
      }
      elseif ($content -is [Array]) {
         # Export CLI direct
         $allWorkflows += $content
         $Results.source_data[$file] = @{
            workflows_count = $content.Count
            source_type     = "cli_export"
         }
      }
   }
   
   Write-Host "✅ $($allWorkflows.Count) workflows chargés pour classification" -ForegroundColor Green
   
}
catch {
   $errorMsg = "Erreur chargement données: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Classification par type de trigger
Write-Host "🎯 Classification par triggers..." -ForegroundColor Yellow
try {
   $triggerStats = @{}
   
   foreach ($workflow in $allWorkflows) {
      $triggerType = "unknown"
      
      # Analyser le contenu pour déterminer le trigger
      if ($workflow.content_preview -or $workflow.name) {
         $content = $workflow.content_preview
         
         # Détecter les types de triggers courants
         if ($content -match "webhook|Webhook") { $triggerType = "webhook" }
         elseif ($content -match "cron|schedule|Cron") { $triggerType = "cron" }
         elseif ($content -match "manual|Manual") { $triggerType = "manual" }
         elseif ($content -match "email|Email|IMAP|SMTP") { $triggerType = "email" }
         elseif ($content -match "http|HTTP|API") { $triggerType = "http" }
         elseif ($content -match "database|Database|SQL") { $triggerType = "database" }
         elseif ($content -match "file|File|FTP") { $triggerType = "file" }
         else {
            # Analyser le nom du workflow
            $name = $workflow.name.ToLower()
            if ($name -match "webhook") { $triggerType = "webhook" }
            elseif ($name -match "email|mail") { $triggerType = "email" }
            elseif ($name -match "schedule|cron|daily|hourly") { $triggerType = "cron" }
            elseif ($name -match "api|http") { $triggerType = "http" }
         }
      }
      
      if (-not $triggerStats[$triggerType]) {
         $triggerStats[$triggerType] = @{
            count      = 0
            workflows  = @()
            percentage = 0
         }
      }
      
      $triggerStats[$triggerType].count++
      $triggerStats[$triggerType].workflows += $workflow.name
   }
   
   # Calculer les pourcentages
   $totalWorkflows = $allWorkflows.Count
   foreach ($type in $triggerStats.Keys) {
      $triggerStats[$type].percentage = [math]::Round(($triggerStats[$type].count / $totalWorkflows) * 100, 1)
   }
   
   $Results.trigger_analysis = $triggerStats
   Write-Host "✅ Classification triggers complétée" -ForegroundColor Green
   
}
catch {
   $errorMsg = "Erreur classification triggers: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Classification par complexité
Write-Host "⚡ Classification par complexité..." -ForegroundColor Yellow
try {
   $complexityStats = @{
      simple     = @{ count = 0; workflows = @(); criteria = "1-3 nodes, linear flow" }
      medium     = @{ count = 0; workflows = @(); criteria = "4-10 nodes, some conditions" }
      complex    = @{ count = 0; workflows = @(); criteria = "11-25 nodes, multiple branches" }
      enterprise = @{ count = 0; workflows = @(); criteria = "25+ nodes, advanced logic" }
   }
   
   foreach ($workflow in $allWorkflows) {
      $nodeCount = if ($workflow.node_count) { $workflow.node_count } else { 1 }
      $complexity = "simple"
      
      if ($nodeCount -ge 25) {
         $complexity = "enterprise"
      }
      elseif ($nodeCount -ge 11) {
         $complexity = "complex"
      }
      elseif ($nodeCount -ge 4) {
         $complexity = "medium"
      }
      
      # Ajuster selon la présence de connections
      if ($workflow.has_connections -and $nodeCount -ge 3) {
         if ($complexity -eq "simple") { $complexity = "medium" }
      }
      
      $complexityStats[$complexity].count++
      $complexityStats[$complexity].workflows += @{
         name            = $workflow.name
         nodes           = $nodeCount
         has_connections = $workflow.has_connections
      }
   }
   
   # Calculer pourcentages
   foreach ($level in $complexityStats.Keys) {
      $complexityStats[$level].percentage = [math]::Round(($complexityStats[$level].count / $totalWorkflows) * 100, 1)
   }
   
   $Results.complexity_analysis = $complexityStats
   Write-Host "✅ Classification complexité complétée" -ForegroundColor Green
   
}
catch {
   $errorMsg = "Erreur classification complexité: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Classification par provider email
Write-Host "📧 Classification par provider email..." -ForegroundColor Yellow
try {
   $emailStats = @{}
   
   foreach ($workflow in $allWorkflows) {
      $providers = @()
      $content = if ($workflow.content_preview) { $workflow.content_preview.ToLower() } else { $workflow.name.ToLower() }
      
      # Détecter les providers email
      if ($content -match "gmail|google") { $providers += "gmail" }
      if ($content -match "outlook|office365|microsoft") { $providers += "outlook" }
      if ($content -match "smtp|mail") { $providers += "smtp" }
      if ($content -match "sendgrid") { $providers += "sendgrid" }
      if ($content -match "mailgun") { $providers += "mailgun" }
      if ($content -match "ses|amazon") { $providers += "ses" }
      if ($content -match "mandrill") { $providers += "mandrill" }
      if ($content -match "postmark") { $providers += "postmark" }
      
      if ($providers.Count -eq 0 -and $content -match "email|mail") {
         $providers += "generic_email"
      }
      
      foreach ($provider in $providers) {
         if (-not $emailStats[$provider]) {
            $emailStats[$provider] = @{
               count      = 0
               workflows  = @()
               percentage = 0
            }
         }
         
         $emailStats[$provider].count++
         $emailStats[$provider].workflows += $workflow.name
      }
   }
   
   # Calculer pourcentages
   foreach ($provider in $emailStats.Keys) {
      $emailStats[$provider].percentage = [math]::Round(($emailStats[$provider].count / $totalWorkflows) * 100, 1)
   }
   
   $Results.email_provider_analysis = $emailStats
   Write-Host "✅ Classification providers email complétée" -ForegroundColor Green
   
}
catch {
   $errorMsg = "Erreur classification email: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Analyse des types de workflows
Write-Host "📊 Analyse types de workflows..." -ForegroundColor Yellow
try {
   $workflowTypes = @{
      email_automation = @{ count = 0; workflows = @(); description = "Workflows centrés sur l'email" }
      data_processing  = @{ count = 0; workflows = @(); description = "Traitement et transformation de données" }
      api_integration  = @{ count = 0; workflows = @(); description = "Intégrations API et webhooks" }
      notification     = @{ count = 0; workflows = @(); description = "Notifications et alertes" }
      scheduled_tasks  = @{ count = 0; workflows = @(); description = "Tâches programmées" }
      manual_tasks     = @{ count = 0; workflows = @(); description = "Tâches manuelles" }
      mixed            = @{ count = 0; workflows = @(); description = "Workflows mixtes" }
   }
   
   foreach ($workflow in $allWorkflows) {
      $name = $workflow.name.ToLower()
      $content = if ($workflow.content_preview) { $workflow.content_preview.ToLower() } else { "" }
      $type = "mixed"
      
      # Classification basée sur le nom et contenu
      if ($name -match "email|mail|send|notification" -or $content -match "email|smtp|imap") {
         $type = "email_automation"
      }
      elseif ($name -match "api|webhook|integration" -or $content -match "webhook|http|api") {
         $type = "api_integration"
      }
      elseif ($name -match "schedule|cron|daily|hourly" -or $content -match "cron|schedule") {
         $type = "scheduled_tasks"
      }
      elseif ($name -match "process|transform|data" -or $content -match "database|sql|transform") {
         $type = "data_processing"
      }
      elseif ($name -match "alert|notify" -or $content -match "notification|alert") {
         $type = "notification"
      }
      elseif ($name -match "manual" -or $content -match "manual") {
         $type = "manual_tasks"
      }
      
      $workflowTypes[$type].count++
      $workflowTypes[$type].workflows += @{
         name    = $workflow.name
         nodes   = $workflow.node_count
         trigger = if ($Results.trigger_analysis) { 
            ($Results.trigger_analysis.Keys | Where-Object { $Results.trigger_analysis[$_].workflows -contains $workflow.name })[0] 
         }
         else { "unknown" }
      }
   }
   
   # Calculer pourcentages
   foreach ($type in $workflowTypes.Keys) {
      $workflowTypes[$type].percentage = [math]::Round(($workflowTypes[$type].count / $totalWorkflows) * 100, 1)
   }
   
   $Results.workflow_types = $workflowTypes
   Write-Host "✅ Classification types workflows complétée" -ForegroundColor Green
   
}
catch {
   $errorMsg = "Erreur classification types: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Créer la taxonomie complète
Write-Host "📋 Création taxonomie complète..." -ForegroundColor Yellow
try {
   $Results.taxonomie = @{
      metadata        = @{
         created_at             = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
         total_workflows        = $totalWorkflows
         classification_version = "1.0"
      }
      dimensions      = @{
         by_trigger        = $Results.trigger_analysis
         by_complexity     = $Results.complexity_analysis
         by_email_provider = $Results.email_provider_analysis
         by_workflow_type  = $Results.workflow_types
      }
      criteria_used   = $Results.classification_criteria
      recommendations = @{
         high_priority   = @()
         medium_priority = @()
         low_priority    = @()
      }
   }
   
   # Générer recommandations basées sur l'analyse
   if ($Results.workflow_types.email_automation.count -gt 0) {
      $Results.taxonomie.recommendations.high_priority += "Migration prioritaire des workflows email_automation ($($Results.workflow_types.email_automation.count) workflows)"
   }
   
   if ($Results.complexity_analysis.enterprise.count -gt 0) {
      $Results.taxonomie.recommendations.high_priority += "Attention particulière aux workflows enterprise ($($Results.complexity_analysis.enterprise.count) workflows)"
   }
   
   if ($Results.trigger_analysis.webhook.count -gt 0) {
      $Results.taxonomie.recommendations.medium_priority += "Prévoir interfaces webhook pour $($Results.trigger_analysis.webhook.count) workflows"
   }
   
   Write-Host "✅ Taxonomie créée avec succès" -ForegroundColor Green
   
}
catch {
   $errorMsg = "Erreur création taxonomie: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Calcul du résumé
$EndTime = Get-Date
$TotalDuration = ($EndTime - $StartTime).TotalSeconds

$Results.summary = @{
   total_duration_seconds    = $TotalDuration
   workflows_classified      = $totalWorkflows
   trigger_types_found       = $Results.trigger_analysis.Keys.Count
   complexity_levels_used    = ($Results.complexity_analysis.Values | Where-Object { $_.count -gt 0 }).Count
   email_providers_detected  = $Results.email_provider_analysis.Keys.Count
   workflow_types_identified = ($Results.workflow_types.Values | Where-Object { $_.count -gt 0 }).Count
   errors_count              = $Results.errors.Count
   status                    = if ($totalWorkflows -gt 0) { "SUCCESS" } else { "NO_DATA" }
}

# Sauvegarde au format YAML
$outputFile = Join-Path $OutputDir "workflow-classification.yaml"
try {
   # Convertir en YAML manually (PowerShell n'a pas de ConvertTo-Yaml natif)
   $yamlContent = @"
# Workflow Classification - Generated on $($StartTime.ToString("yyyy-MM-dd HH:mm:ss"))

metadata:
  task: $($Results.task)
  timestamp: $($Results.timestamp)
  total_workflows: $($Results.summary.workflows_classified)
  classification_version: "1.0"

trigger_types:
"@

   foreach ($trigger in $Results.trigger_analysis.Keys) {
      $stats = $Results.trigger_analysis[$trigger]
      $yamlContent += @"

  $trigger:
    count: $($stats.count)
    percentage: $($stats.percentage)%
    workflows: [$($stats.workflows -join ', ')]
"@
   }

   $yamlContent += @"

complexity_levels:
"@

   foreach ($level in $Results.complexity_analysis.Keys) {
      $stats = $Results.complexity_analysis[$level]
      $yamlContent += @"

  $level:
    count: $($stats.count)
    percentage: $($stats.percentage)%
    criteria: "$($stats.criteria)"
"@
   }

   $yamlContent += @"

workflow_types:
"@

   foreach ($type in $Results.workflow_types.Keys) {
      $stats = $Results.workflow_types[$type]
      $yamlContent += @"

  $type:
    count: $($stats.count)
    percentage: $($stats.percentage)%
    description: "$($stats.description)"
"@
   }

   $yamlContent += @"

summary:
  total_duration_seconds: $($Results.summary.total_duration_seconds)
  trigger_types_found: $($Results.summary.trigger_types_found)
  complexity_levels_used: $($Results.summary.complexity_levels_used)
  email_providers_detected: $($Results.summary.email_providers_detected)
  workflow_types_identified: $($Results.summary.workflow_types_identified)
  status: $($Results.summary.status)
"@

   $yamlContent | Set-Content $outputFile -Encoding UTF8
   Write-Host "✅ Classification YAML sauvée: $outputFile" -ForegroundColor Green
   
}
catch {
   # Fallback JSON si YAML échoue
   $outputFileJson = Join-Path $OutputDir "workflow-classification.json"
   $Results | ConvertTo-Json -Depth 10 | Set-Content $outputFileJson -Encoding UTF8
   Write-Host "⚠️ Sauvé en JSON à la place: $outputFileJson" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 RÉSUMÉ TÂCHE 010:" -ForegroundColor Cyan
Write-Host "   Durée totale: $([math]::Round($TotalDuration, 2))s" -ForegroundColor White
Write-Host "   Workflows classifiés: $($Results.summary.workflows_classified)" -ForegroundColor White
Write-Host "   Types de triggers: $($Results.summary.trigger_types_found)" -ForegroundColor White
Write-Host "   Niveaux complexité: $($Results.summary.complexity_levels_used)" -ForegroundColor White
Write-Host "   Providers email: $($Results.summary.email_providers_detected)" -ForegroundColor White
Write-Host "   Types workflows: $($Results.summary.workflow_types_identified)" -ForegroundColor White
Write-Host "   Erreurs: $($Results.summary.errors_count)" -ForegroundColor White
Write-Host "   Status: $($Results.summary.status)" -ForegroundColor $(if ($Results.summary.status -eq "SUCCESS") { "Green" } else { "Yellow" })

if ($Verbose -and $Results.errors.Count -gt 0) {
   Write-Host ""
   Write-Host "⚠️ ERREURS DÉTECTÉES:" -ForegroundColor Yellow
   foreach ($errorItem in $Results.errors) {
      Write-Host "   $errorItem" -ForegroundColor Red
   }
}

Write-Host ""
Write-Host "✅ TÂCHE 010 TERMINÉE" -ForegroundColor Green

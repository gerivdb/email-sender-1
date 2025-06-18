# Task 011: Extraire Nodes Email Critiques
# Durée: 15 minutes max
# Sortie: critical-email-nodes.json

param(
   [string]$OutputDir = "output/phase1",
   [string]$InputFile = "",
   [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date

Write-Host "🚀 PHASE 1.2.1 - TÂCHE 011: Extraire Nodes Email Critiques" -ForegroundColor Cyan
Write-Host "=" * 60

# Création du répertoire de sortie
if (!(Test-Path $OutputDir)) {
   New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$Results = @{
   task                   = "011-extraire-nodes-email-critiques"
   timestamp              = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
   source_data            = @{}
   email_nodes            = @{}
   node_analysis          = @{}
   critical_patterns      = @{}
   provider_mapping       = @{}
   configuration_analysis = @{}
   migration_priorities   = @{}
   summary                = @{}
   errors                 = @()
}

# Définir les patterns de nodes email critiques
$EmailNodePatterns = @{
   smtp_nodes       = @("smtp", "email", "mail", "send", "Email Send", "SMTP")
   imap_nodes       = @("imap", "Email Trigger", "Email Read", "Mail Trigger")
   oauth_nodes      = @("oauth", "gmail", "outlook", "Google", "Microsoft")
   template_nodes   = @("template", "html", "content", "body", "subject")
   attachment_nodes = @("attachment", "file", "upload", "binary")
   auth_nodes       = @("auth", "credential", "password", "token", "key")
}

$CriticalProviders = @{
   gmail        = @{
      nodes             = @("Gmail", "Google Sheets", "Google Drive")
      auth_type         = "OAuth2"
      api_endpoints     = @("https://gmail.googleapis.com", "https://www.googleapis.com")
      critical_features = @("Send Email", "Read Email", "Labels", "Attachments")
   }
   outlook      = @{
      nodes             = @("Outlook", "Microsoft Outlook", "Office 365")
      auth_type         = "OAuth2"
      api_endpoints     = @("https://graph.microsoft.com", "https://outlook.office.com")
      critical_features = @("Send Mail", "Read Mail", "Folders", "Calendar")
   }
   smtp_generic = @{
      nodes             = @("SMTP", "Email Send", "Mail")
      auth_type         = "Basic/TLS"
      api_endpoints     = @("smtp.gmail.com", "smtp.office365.com", "smtp.sendgrid.net")
      critical_features = @("Send", "TLS", "Authentication", "Headers")
   }
   sendgrid     = @{
      nodes             = @("SendGrid", "SendGrid Email")
      auth_type         = "API Key"
      api_endpoints     = @("https://api.sendgrid.com")
      critical_features = @("Send", "Templates", "Analytics", "Webhooks")
   }
}

Write-Host "📂 Chargement des données workflows..." -ForegroundColor Yellow

# Charger les données depuis les exports précédents
try {
   $inputFiles = @()
   
   if ($InputFile -and (Test-Path $InputFile)) {
      $inputFiles += $InputFile
   }
   else {
      # Chercher les fichiers d'export des tâches précédentes
      $possibleFiles = @(
         (Join-Path $OutputDir "n8n-workflows-export.json"),
         (Join-Path $OutputDir "workflow-classification.json"),
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
            source_type     = "export_file"
         }
      }
      elseif ($content -is [Array]) {
         $allWorkflows += $content
         $Results.source_data[$file] = @{
            workflows_count = $content.Count
            source_type     = "workflow_array"
         }
      }
   }
   
   Write-Host "✅ $($allWorkflows.Count) workflows chargés pour analyse nodes" -ForegroundColor Green
   
}
catch {
   $errorMsg = "Erreur chargement données: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Extraction et analyse des nodes email
Write-Host "📧 Extraction nodes email..." -ForegroundColor Yellow
try {
   $emailNodesFound = @{}
   $criticalNodes = @()
   
   foreach ($workflow in $allWorkflows) {
      $workflowNodes = @{
         workflow_name = $workflow.name
         email_nodes   = @()
         complexity    = "unknown"
         provider      = "unknown"
      }
      
      # Analyser le contenu du workflow pour détecter les nodes email
      if ($workflow.content_preview) {
         $content = $workflow.content_preview
         
         # Rechercher les patterns de nodes email
         foreach ($nodeType in $EmailNodePatterns.Keys) {
            $patterns = $EmailNodePatterns[$nodeType]
            foreach ($pattern in $patterns) {
               if ($content -match $pattern) {
                  $nodeInfo = @{
                     type            = $nodeType
                     pattern_matched = $pattern
                     workflow        = $workflow.name
                     node_count      = $workflow.node_count
                     criticality     = "medium"
                  }
                  
                  # Déterminer la criticité
                  if ($pattern -match "oauth|auth|credential") {
                     $nodeInfo.criticality = "high"
                  }
                  elseif ($pattern -match "smtp|send|mail") {
                     $nodeInfo.criticality = "high"
                  }
                  elseif ($pattern -match "template|attachment") {
                     $nodeInfo.criticality = "medium"
                  }
                  
                  $workflowNodes.email_nodes += $nodeInfo
                  $criticalNodes += $nodeInfo
               }
            }
         }
         
         # Détecter le provider
         foreach ($provider in $CriticalProviders.Keys) {
            $providerInfo = $CriticalProviders[$provider]
            foreach ($providerNode in $providerInfo.nodes) {
               if ($content -match $providerNode) {
                  $workflowNodes.provider = $provider
                  break
               }
            }
            if ($workflowNodes.provider -ne "unknown") { break }
         }
         
         # Déterminer la complexité basée sur le nombre de nodes email
         $emailNodeCount = $workflowNodes.email_nodes.Count
         if ($emailNodeCount -ge 5) {
            $workflowNodes.complexity = "high"
         }
         elseif ($emailNodeCount -ge 2) {
            $workflowNodes.complexity = "medium"
         }
         elseif ($emailNodeCount -eq 1) {
            $workflowNodes.complexity = "low"
         }
      }
      
      if ($workflowNodes.email_nodes.Count -gt 0) {
         $emailNodesFound[$workflow.name] = $workflowNodes
      }
   }
   
   $Results.email_nodes = $emailNodesFound
   $Results.node_analysis.total_critical_nodes = $criticalNodes.Count
   $Results.node_analysis.workflows_with_email = $emailNodesFound.Count
   
   Write-Host "✅ $($criticalNodes.Count) nodes email critiques trouvés dans $($emailNodesFound.Count) workflows" -ForegroundColor Green
   
}
catch {
   $errorMsg = "Erreur extraction nodes: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Analyse des patterns critiques
Write-Host "🔍 Analyse patterns critiques..." -ForegroundColor Yellow
try {
   $patternStats = @{}
   
   foreach ($nodeType in $EmailNodePatterns.Keys) {
      $patternStats[$nodeType] = @{
         count                    = 0
         workflows                = @()
         criticality_distribution = @{ high = 0; medium = 0; low = 0 }
      }
   }
   
   foreach ($workflowName in $Results.email_nodes.Keys) {
      $workflowData = $Results.email_nodes[$workflowName]
      foreach ($node in $workflowData.email_nodes) {
         $nodeType = $node.type
         if ($patternStats[$nodeType]) {
            $patternStats[$nodeType].count++
            if ($patternStats[$nodeType].workflows -notcontains $workflowName) {
               $patternStats[$nodeType].workflows += $workflowName
            }
            $patternStats[$nodeType].criticality_distribution[$node.criticality]++
         }
      }
   }
   
   $Results.critical_patterns = $patternStats
   Write-Host "✅ Analyse patterns complétée" -ForegroundColor Green
   
}
catch {
   $errorMsg = "Erreur analyse patterns: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Mapping des providers
Write-Host "🌐 Mapping providers email..." -ForegroundColor Yellow
try {
   $providerStats = @{}
   
   foreach ($provider in $CriticalProviders.Keys) {
      $providerStats[$provider] = @{
         workflows          = @()
         nodes_count        = 0
         auth_complexity    = $CriticalProviders[$provider].auth_type
         migration_priority = "medium"
      }
   }
   
   foreach ($workflowName in $Results.email_nodes.Keys) {
      $workflowData = $Results.email_nodes[$workflowName]
      $provider = $workflowData.provider
      
      if ($provider -ne "unknown" -and $providerStats[$provider]) {
         $providerStats[$provider].workflows += $workflowName
         $providerStats[$provider].nodes_count += $workflowData.email_nodes.Count
         
         # Ajuster priorité selon complexité
         if ($workflowData.complexity -eq "high") {
            $providerStats[$provider].migration_priority = "high"
         }
      }
   }
   
   $Results.provider_mapping = $providerStats
   Write-Host "✅ Mapping providers complété" -ForegroundColor Green
   
}
catch {
   $errorMsg = "Erreur mapping providers: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Analyse des configurations critiques
Write-Host "⚙️ Analyse configurations critiques..." -ForegroundColor Yellow
try {
   $configAnalysis = @{
      authentication_methods  = @{}
      encryption_requirements = @{}
      api_endpoints           = @{}
      critical_settings       = @{}
   }
   
   # Analyser les méthodes d'authentification
   foreach ($provider in $CriticalProviders.Keys) {
      $authType = $CriticalProviders[$provider].auth_type
      if (-not $configAnalysis.authentication_methods[$authType]) {
         $configAnalysis.authentication_methods[$authType] = @{
            providers        = @()
            complexity       = "medium"
            migration_effort = "medium"
         }
      }
      $configAnalysis.authentication_methods[$authType].providers += $provider
      
      # OAuth2 est plus complexe à migrer
      if ($authType -match "OAuth") {
         $configAnalysis.authentication_methods[$authType].complexity = "high"
         $configAnalysis.authentication_methods[$authType].migration_effort = "high"
      }
   }
   
   # Analyser les endpoints API
   foreach ($provider in $CriticalProviders.Keys) {
      $endpoints = $CriticalProviders[$provider].api_endpoints
      foreach ($endpoint in $endpoints) {
         if (-not $configAnalysis.api_endpoints[$endpoint]) {
            $configAnalysis.api_endpoints[$endpoint] = @{
               provider        = $provider
               usage_count     = 0
               requires_bridge = $true
            }
         }
         # Compter l'utilisation basée sur les workflows
         if ($Results.provider_mapping[$provider]) {
            $configAnalysis.api_endpoints[$endpoint].usage_count = $Results.provider_mapping[$provider].workflows.Count
         }
      }
   }
   
   # Identifier les settings critiques
   $configAnalysis.critical_settings = @{
      tls_encryption      = @{ required = $true; affected_nodes = @("smtp_nodes") }
      oauth_tokens        = @{ required = $true; affected_nodes = @("oauth_nodes") }
      api_rate_limits     = @{ required = $true; affected_nodes = @("smtp_nodes", "oauth_nodes") }
      template_engines    = @{ required = $false; affected_nodes = @("template_nodes") }
      attachment_handling = @{ required = $false; affected_nodes = @("attachment_nodes") }
   }
   
   $Results.configuration_analysis = $configAnalysis
   Write-Host "✅ Analyse configurations complétée" -ForegroundColor Green
   
}
catch {
   $errorMsg = "Erreur analyse configurations: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Établir les priorités de migration
Write-Host "🎯 Établissement priorités migration..." -ForegroundColor Yellow
try {
   $migrationPriorities = @{
      critical = @{ workflows = @(); reason = "High-volume email operations, OAuth complexity" }
      high     = @{ workflows = @(); reason = "Multiple email providers, complex auth" }
      medium   = @{ workflows = @(); reason = "Standard email operations" }
      low      = @{ workflows = @(); reason = "Simple email workflows" }
   }
   
   foreach ($workflowName in $Results.email_nodes.Keys) {
      $workflowData = $Results.email_nodes[$workflowName]
      $priority = "medium"
      
      # Déterminer la priorité basée sur plusieurs facteurs
      $highCriticalityNodes = ($workflowData.email_nodes | Where-Object { $_.criticality -eq "high" }).Count
      $totalEmailNodes = $workflowData.email_nodes.Count
      $isOAuthProvider = $workflowData.provider -in @("gmail", "outlook")
      
      if ($highCriticalityNodes -ge 3 -or ($isOAuthProvider -and $totalEmailNodes -ge 2)) {
         $priority = "critical"
      }
      elseif ($highCriticalityNodes -ge 2 -or $isOAuthProvider) {
         $priority = "high"
      }
      elseif ($totalEmailNodes -ge 3) {
         $priority = "high"
      }
      elseif ($totalEmailNodes -eq 1) {
         $priority = "low"
      }
      
      $migrationPriorities[$priority].workflows += @{
         name                   = $workflowName
         provider               = $workflowData.provider
         complexity             = $workflowData.complexity
         email_nodes_count      = $totalEmailNodes
         high_criticality_nodes = $highCriticalityNodes
      }
   }
   
   $Results.migration_priorities = $migrationPriorities
   Write-Host "✅ Priorités migration établies" -ForegroundColor Green
   
}
catch {
   $errorMsg = "Erreur priorités migration: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Calcul du résumé
$EndTime = Get-Date
$TotalDuration = ($EndTime - $StartTime).TotalSeconds

$Results.summary = @{
   total_duration_seconds  = $TotalDuration
   workflows_analyzed      = $allWorkflows.Count
   workflows_with_email    = $Results.node_analysis.workflows_with_email
   total_critical_nodes    = $Results.node_analysis.total_critical_nodes
   unique_providers        = $Results.provider_mapping.Keys.Count
   authentication_methods  = $Results.configuration_analysis.authentication_methods.Keys.Count
   api_endpoints           = $Results.configuration_analysis.api_endpoints.Keys.Count
   critical_workflows      = $Results.migration_priorities.critical.workflows.Count
   high_priority_workflows = $Results.migration_priorities.high.workflows.Count
   errors_count            = $Results.errors.Count
   status                  = if ($Results.node_analysis.total_critical_nodes -gt 0) { "SUCCESS" } else { "NO_EMAIL_NODES" }
}

# Sauvegarde des résultats
$outputFile = Join-Path $OutputDir "critical-email-nodes.json"
$Results | ConvertTo-Json -Depth 10 | Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "📋 RÉSUMÉ TÂCHE 011:" -ForegroundColor Cyan
Write-Host "   Durée totale: $([math]::Round($TotalDuration, 2))s" -ForegroundColor White
Write-Host "   Workflows analysés: $($Results.summary.workflows_analyzed)" -ForegroundColor White
Write-Host "   Workflows avec email: $($Results.summary.workflows_with_email)" -ForegroundColor White
Write-Host "   Nodes critiques trouvés: $($Results.summary.total_critical_nodes)" -ForegroundColor White
Write-Host "   Providers uniques: $($Results.summary.unique_providers)" -ForegroundColor White
Write-Host "   Méthodes auth: $($Results.summary.authentication_methods)" -ForegroundColor White
Write-Host "   Endpoints API: $($Results.summary.api_endpoints)" -ForegroundColor White
Write-Host "   Workflows critiques: $($Results.summary.critical_workflows)" -ForegroundColor White
Write-Host "   Workflows priorité haute: $($Results.summary.high_priority_workflows)" -ForegroundColor White
Write-Host "   Erreurs: $($Results.summary.errors_count)" -ForegroundColor White
Write-Host "   Status: $($Results.summary.status)" -ForegroundColor $(if ($Results.summary.status -eq "SUCCESS") { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "💾 Résultats sauvés: $outputFile" -ForegroundColor Green

# Afficher le top des patterns critiques
if ($Results.critical_patterns -and $Verbose) {
   Write-Host ""
   Write-Host "🔥 TOP PATTERNS CRITIQUES:" -ForegroundColor Yellow
   $sortedPatterns = $Results.critical_patterns.GetEnumerator() | Sort-Object { $_.Value.count } -Descending | Select-Object -First 5
   foreach ($pattern in $sortedPatterns) {
      if ($pattern.Value.count -gt 0) {
         Write-Host "   $($pattern.Key): $($pattern.Value.count) occurrences" -ForegroundColor White
      }
   }
}

if ($Verbose -and $Results.errors.Count -gt 0) {
   Write-Host ""
   Write-Host "⚠️ ERREURS DÉTECTÉES:" -ForegroundColor Yellow
   foreach ($errorItem in $Results.errors) {
      Write-Host "   $errorItem" -ForegroundColor Red
   }
}

Write-Host ""
Write-Host "✅ TÂCHE 011 TERMINÉE" -ForegroundColor Green

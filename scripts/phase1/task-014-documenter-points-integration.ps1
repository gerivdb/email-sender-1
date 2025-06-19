#!/usr/bin/env pwsh
# Script pour documenter les points d'intégration des workflows N8N
# Tâche Atomique 014: Documenter Points Intégration
# Durée: 15 minutes max

param(
    [string]$WorkflowsFile = "output/phase1/n8n-workflows-export.json",
    [string]$OutputFile = "output/phase1/integration-endpoints.yaml"
)

Write-Host "🔍 TÂCHE 014: Documenter Points Intégration" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green

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

# Analyser les points d'intégration
$integrations = @{
    "databases" = @{}
    "apis_externes" = @{}
    "services_email" = @{}
    "webhooks" = @{}
    "stockage_fichiers" = @{}
    "services_auth" = @{}
}

foreach ($workflow in $workflows.workflows) {
    foreach ($node in $workflow.nodes) {
        # Bases de données
        if ($node.type -like "*postgres*" -or $node.type -like "*mysql*" -or $node.type -like "*mongo*") {
            $dbKey = "$($node.parameters.host):$($node.parameters.port)/$($node.parameters.database)"
            if (-not $integrations.databases.ContainsKey($dbKey)) {
                $integrations.databases[$dbKey] = @{
                    "type" = $node.type
                    "host" = $node.parameters.host
                    "port" = $node.parameters.port
                    "database" = $node.parameters.database
                    "workflows" = @()
                    "operations" = @()
                }
            }
            $integrations.databases[$dbKey].workflows += "$($workflow.name) ($($workflow.id))"
            if ($node.parameters.query) {
                $integrations.databases[$dbKey].operations += $node.parameters.query
            }
        }
        
        # APIs externes
        if ($node.type -like "*httpRequest*" -and $node.parameters.url) {
            $url = $node.parameters.url
            $domain = ([System.Uri]$url).Host
            if (-not $integrations.apis_externes.ContainsKey($domain)) {
                $integrations.apis_externes[$domain] = @{
                    "endpoints" = @()
                    "methods" = @()
                    "workflows" = @()
                }
            }
            $integrations.apis_externes[$domain].endpoints += $url
            $integrations.apis_externes[$domain].methods += $node.parameters.method
            $integrations.apis_externes[$domain].workflows += "$($workflow.name) ($($workflow.id))"
        }
        
        # Services email
        if ($node.type -like "*email*" -or $node.type -like "*smtp*" -or $node.type -like "*imap*") {
            $emailKey = $node.parameters.host -or "default"
            if (-not $integrations.services_email.ContainsKey($emailKey)) {
                $integrations.services_email[$emailKey] = @{
                    "type" = $node.type
                    "host" = $node.parameters.host
                    "port" = $node.parameters.port
                    "secure" = $node.parameters.secure
                    "workflows" = @()
                }
            }
            $integrations.services_email[$emailKey].workflows += "$($workflow.name) ($($workflow.id))"
        }
        
        # Webhooks
        if ($node.type -like "*webhook*") {
            $webhookPath = $node.parameters.path -or "default"
            if (-not $integrations.webhooks.ContainsKey($webhookPath)) {
                $integrations.webhooks[$webhookPath] = @{
                    "method" = $node.parameters.httpMethod
                    "path" = $node.parameters.path
                    "workflows" = @()
                    "authentication" = $node.parameters.authentication
                }
            }
            $integrations.webhooks[$webhookPath].workflows += "$($workflow.name) ($($workflow.id))"
        }
        
        # Services d'authentification
        if ($node.type -like "*oauth*" -or $node.type -like "*auth*" -or $node.type -like "*jwt*") {
            $authKey = $node.parameters.authUrl -or $node.type
            if (-not $integrations.services_auth.ContainsKey($authKey)) {
                $integrations.services_auth[$authKey] = @{
                    "type" = $node.type
                    "provider" = $node.parameters.provider
                    "workflows" = @()
                }
            }
            $integrations.services_auth[$authKey].workflows += "$($workflow.name) ($($workflow.id))"
        }
    }
}

# Générer le fichier YAML
$yamlContent = @"
# 🔗 POINTS D'INTÉGRATION WORKFLOWS N8N
# Généré automatiquement le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

metadata:
  source_file: "$WorkflowsFile"
  total_workflows: $($workflows.workflows.Count)
  analysis_date: "$(Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")"

"@

# Bases de données
if ($integrations.databases.Count -gt 0) {
    $yamlContent += @"
databases:
"@
    foreach ($dbKey in $integrations.databases.Keys) {
        $db = $integrations.databases[$dbKey]
        $yamlContent += @"
  "$dbKey":
    type: "$($db.type)"
    host: "$($db.host)"
    port: $($db.port)
    database: "$($db.database)"
    workflows:
"@
        foreach ($workflow in ($db.workflows | Select-Object -Unique)) {
            $yamlContent += @"
      - "$workflow"
"@
        }
        $yamlContent += @"
    operations:
"@
        foreach ($op in ($db.operations | Select-Object -Unique)) {
            $yamlContent += @"
      - |
        $($op -replace '"', '\"')
"@
        }
        $yamlContent += "`n"
    }
}

# APIs externes
if ($integrations.apis_externes.Count -gt 0) {
    $yamlContent += @"
apis_externes:
"@
    foreach ($domain in $integrations.apis_externes.Keys) {
        $api = $integrations.apis_externes[$domain]
        $yamlContent += @"
  "$domain":
    endpoints:
"@
        foreach ($endpoint in ($api.endpoints | Select-Object -Unique)) {
            $yamlContent += @"
      - "$endpoint"
"@
        }
        $yamlContent += @"
    methods:
"@
        foreach ($method in ($api.methods | Select-Object -Unique)) {
            $yamlContent += @"
      - "$method"
"@
        }
        $yamlContent += @"
    workflows:
"@
        foreach ($workflow in ($api.workflows | Select-Object -Unique)) {
            $yamlContent += @"
      - "$workflow"
"@
        }
        $yamlContent += "`n"
    }
}

# Services email
if ($integrations.services_email.Count -gt 0) {
    $yamlContent += @"
services_email:
"@
    foreach ($emailKey in $integrations.services_email.Keys) {
        $email = $integrations.services_email[$emailKey]
        $yamlContent += @"
  "$emailKey":
    type: "$($email.type)"
    host: "$($email.host)"
    port: $($email.port)
    secure: $($email.secure)
    workflows:
"@
        foreach ($workflow in ($email.workflows | Select-Object -Unique)) {
            $yamlContent += @"
      - "$workflow"
"@
        }
        $yamlContent += "`n"
    }
}

# Webhooks
if ($integrations.webhooks.Count -gt 0) {
    $yamlContent += @"
webhooks:
"@
    foreach ($webhookPath in $integrations.webhooks.Keys) {
        $webhook = $integrations.webhooks[$webhookPath]
        $yamlContent += @"
  "$webhookPath":
    method: "$($webhook.method)"
    path: "$($webhook.path)"
    authentication: "$($webhook.authentication)"
    workflows:
"@
        foreach ($workflow in ($webhook.workflows | Select-Object -Unique)) {
            $yamlContent += @"
      - "$workflow"
"@
        }
        $yamlContent += "`n"
    }
}

# Services d'authentification
if ($integrations.services_auth.Count -gt 0) {
    $yamlContent += @"
services_auth:
"@
    foreach ($authKey in $integrations.services_auth.Keys) {
        $auth = $integrations.services_auth[$authKey]
        $yamlContent += @"
  "$authKey":
    type: "$($auth.type)"
    provider: "$($auth.provider)"
    workflows:
"@
        foreach ($workflow in ($auth.workflows | Select-Object -Unique)) {
            $yamlContent += @"
      - "$workflow"
"@
        }
        $yamlContent += "`n"
    }
}

# Résumé des intégrations
$yamlContent += @"

# Résumé
integration_summary:
  total_databases: $($integrations.databases.Count)
  total_apis_externes: $($integrations.apis_externes.Count)
  total_services_email: $($integrations.services_email.Count)
  total_webhooks: $($integrations.webhooks.Count)
  total_services_auth: $($integrations.services_auth.Count)

# Points critiques pour migration
migration_considerations:
  databases:
    - "Vérifier connectivité et permissions"
    - "Planifier migration des schémas si nécessaire"
    - "Tester performances avec charge Go"
  
  apis_externes:
    - "Valider rate limits et quotas"
    - "Vérifier compatibilité versions API"
    - "Implémenter retry logic"
  
  services_email:
    - "Configurer authentification SMTP/IMAP"
    - "Tester deliverability"
    - "Planifier basculement progressif"
  
  webhooks:
    - "Maintenir endpoints pendant transition"
    - "Implémenter forwarding si nécessaire"
    - "Documenter nouvelles URLs"
"@

# Sauvegarder le fichier YAML
$yamlContent | Out-File -FilePath $OutputFile -Encoding UTF8

Write-Host "✅ Documentation des points d'intégration terminée" -ForegroundColor Green
Write-Host "📁 Fichier: $OutputFile" -ForegroundColor Cyan

# Afficher un résumé
Write-Host "`n📋 RÉSUMÉ DES INTÉGRATIONS:" -ForegroundColor Yellow
Write-Host "  - Bases de données: $($integrations.databases.Count)" -ForegroundColor White
Write-Host "  - APIs externes: $($integrations.apis_externes.Count)" -ForegroundColor White
Write-Host "  - Services email: $($integrations.services_email.Count)" -ForegroundColor White
Write-Host "  - Webhooks: $($integrations.webhooks.Count)" -ForegroundColor White
Write-Host "  - Services auth: $($integrations.services_auth.Count)" -ForegroundColor White

Write-Host "`n🎯 TÂCHE 014 TERMINÉE avec succès!" -ForegroundColor Green

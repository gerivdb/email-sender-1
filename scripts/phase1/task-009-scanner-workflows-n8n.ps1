# Task 009: Scanner Workflows N8N
# Durée: 20 minutes max
# Sortie: n8n-workflows-export.json

param(
   [string]$OutputDir = "output/phase1",
   [string]$N8nDir = ".",
   [switch]$Verbose
)

$ErrorActionPreference = "Continue"
$StartTime = Get-Date

Write-Host "🚀 PHASE 1.2.1 - TÂCHE 009: Scanner Workflows N8N" -ForegroundColor Cyan
Write-Host "=" * 60

# Création du répertoire de sortie
if (!(Test-Path $OutputDir)) {
   New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$Results = @{
   task            = "009-scanner-workflows-n8n"
   timestamp       = $StartTime.ToString("yyyy-MM-dd HH:mm:ss")
   scan_locations  = @()
   workflows_found = @()
   n8n_config      = @{}
   database_scan   = @{}
   file_scan       = @{}
   export_methods  = @{}
   summary         = @{}
   errors          = @()
}

Write-Host "🔍 Recherche des workflows N8N..." -ForegroundColor Yellow

# 1. Rechercher les fichiers de configuration N8N
Write-Host "📋 Scan configuration N8N..." -ForegroundColor Yellow
try {
   $configFiles = @()
   
   # Rechercher fichiers config N8N typiques
   $configPatterns = @(
      "*.env",
      ".n8n*",
      "n8n.config.*",
      "config.json",
      "settings.json"
   )
   
   foreach ($pattern in $configPatterns) {
      $found = Get-ChildItem -Recurse -Include $pattern -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -notmatch "node_modules|\.git|vendor" } |
      Select-Object -First 10
      
      if ($found) {
         $configFiles += $found
      }
   }
   
   if ($configFiles) {
      Write-Host "✅ Fichiers config trouvés:" -ForegroundColor Green
      foreach ($file in $configFiles) {
         $relativePath = $file.FullName.Replace((Get-Location).Path, "").TrimStart('\')
         Write-Host "   📄 $relativePath" -ForegroundColor White
         
         $Results.n8n_config[$relativePath] = @{
            full_path     = $file.FullName
            size_bytes    = $file.Length
            last_modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            type          = $file.Extension
         }
      }
   }
   else {
      Write-Host "⚠️ Aucun fichier config N8N trouvé" -ForegroundColor Yellow
   }
}
catch {
   $errorMsg = "Erreur scan config: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# 2. Rechercher base de données N8N
Write-Host "🗄️ Scan base de données N8N..." -ForegroundColor Yellow
try {
   $dbFiles = @()
   
   # Rechercher fichiers DB N8N
   $dbPatterns = @(
      "*.db",
      "*.sqlite",
      "*.sqlite3",
      "database.sqlite*",
      "n8n.db*"
   )
   
   foreach ($pattern in $dbPatterns) {
      $found = Get-ChildItem -Recurse -Include $pattern -ErrorAction SilentlyContinue |
      Where-Object { 
         $_.FullName -notmatch "node_modules|\.git|vendor" -and
         $_.Length -gt 1KB
      } |
      Select-Object -First 5
      
      if ($found) {
         $dbFiles += $found
      }
   }
   
   if ($dbFiles) {
      Write-Host "✅ Bases de données trouvées:" -ForegroundColor Green
      foreach ($db in $dbFiles) {
         $relativePath = $db.FullName.Replace((Get-Location).Path, "").TrimStart('\')
         $sizeMB = [math]::Round($db.Length / 1MB, 2)
         Write-Host "   🗄️ $relativePath ($sizeMB MB)" -ForegroundColor White
         
         $Results.database_scan[$relativePath] = @{
            full_path     = $db.FullName
            size_mb       = $sizeMB
            last_modified = $db.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            type          = "database"
         }
      }
   }
   else {
      Write-Host "⚠️ Aucune base de données N8N trouvée" -ForegroundColor Yellow
   }
}
catch {
   $errorMsg = "Erreur scan DB: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# 3. Rechercher fichiers workflows JSON
Write-Host "📁 Scan fichiers workflows..." -ForegroundColor Yellow
try {
   $workflowFiles = @()
   
   # Rechercher fichiers JSON potentiels de workflows
   $workflowPatterns = @(
      "*workflow*.json",
      "*n8n*.json",
      "*.n8n",
      "*automation*.json"
   )
   
   foreach ($pattern in $workflowPatterns) {
      $found = Get-ChildItem -Recurse -Include $pattern -ErrorAction SilentlyContinue |
      Where-Object { 
         $_.FullName -notmatch "node_modules|\.git|vendor|package" -and
         $_.Length -gt 100
      } |
      Select-Object -First 20
      
      if ($found) {
         $workflowFiles += $found
      }
   }
   
   # Analyser contenu des fichiers JSON pour détecter des workflows N8N
   $validWorkflows = @()
   foreach ($file in $workflowFiles) {
      try {
         $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
         if ($content) {
            $json = $content | ConvertFrom-Json -ErrorAction SilentlyContinue
            
            # Vérifier si c'est un workflow N8N (présence de nodes, connections, etc.)
            if ($json.nodes -or $json.connections -or $json.name -or $json.settings) {
               $validWorkflows += @{
                  file            = $file
                  content         = $json
                  node_count      = if ($json.nodes) { $json.nodes.Count } else { 0 }
                  has_connections = [bool]$json.connections
                  workflow_name   = if ($json.name) { $json.name } else { "Unnamed" }
               }
            }
         }
      }
      catch {
         # Ignorer les erreurs de parsing JSON
      }
   }
   
   if ($validWorkflows) {
      Write-Host "✅ Workflows N8N détectés:" -ForegroundColor Green
      foreach ($wf in $validWorkflows) {
         $relativePath = $wf.file.FullName.Replace((Get-Location).Path, "").TrimStart('\')
         Write-Host "   📊 $($wf.workflow_name) - $relativePath ($($wf.node_count) nodes)" -ForegroundColor White
         
         $Results.workflows_found += @{
            name            = $wf.workflow_name
            file_path       = $relativePath
            full_path       = $wf.file.FullName
            node_count      = $wf.node_count
            has_connections = $wf.has_connections
            size_bytes      = $wf.file.Length
            last_modified   = $wf.file.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")
            content_preview = if ($wf.content) { $wf.content | ConvertTo-Json -Depth 2 -Compress } else { "" }
         }
      }
   }
   else {
      Write-Host "⚠️ Aucun workflow N8N trouvé dans les fichiers" -ForegroundColor Yellow
   }
   
   $Results.file_scan = @{
      total_json_files  = $workflowFiles.Count
      valid_workflows   = $validWorkflows.Count
      patterns_searched = $workflowPatterns
   }
   
}
catch {
   $errorMsg = "Erreur scan workflows: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# 4. Vérifier si N8N CLI est disponible
Write-Host "🛠️ Vérification N8N CLI..." -ForegroundColor Yellow
try {
   $n8nVersion = n8n --version 2>&1
   if ($LASTEXITCODE -eq 0) {
      Write-Host "✅ N8N CLI disponible: $n8nVersion" -ForegroundColor Green
      $Results.export_methods.cli_available = $true
      $Results.export_methods.cli_version = $n8nVersion.ToString()
      
      # Tenter export via CLI si disponible
      Write-Host "📤 Tentative export via N8N CLI..." -ForegroundColor Yellow
      $exportFile = Join-Path $OutputDir "n8n-cli-export.json"
      
      try {
         $exportResult = n8n export --all --output=$exportFile 2>&1
         if ($LASTEXITCODE -eq 0 -and (Test-Path $exportFile)) {
            Write-Host "✅ Export CLI réussi: $exportFile" -ForegroundColor Green
            $Results.export_methods.cli_export = @{
               success    = $true
               file       = $exportFile
               size_bytes = (Get-Item $exportFile).Length
            }
         }
         else {
            Write-Host "⚠️ Export CLI échoué: $exportResult" -ForegroundColor Yellow
            $Results.export_methods.cli_export = @{
               success = $false
               error   = $exportResult.ToString()
            }
         }
      }
      catch {
         $Results.export_methods.cli_export = @{
            success = $false
            error   = $_.Exception.Message
         }
      }
   }
   else {
      Write-Host "⚠️ N8N CLI non disponible" -ForegroundColor Yellow
      $Results.export_methods.cli_available = $false
   }
}
catch {
   $Results.export_methods.cli_available = $false
   $Results.export_methods.error = $_.Exception.Message
}

# 5. Rechercher API N8N active
Write-Host "🌐 Vérification API N8N..." -ForegroundColor Yellow
try {
   $commonPorts = @(5678, 3000, 8080, 8000)
   $apiFound = $false
   
   foreach ($port in $commonPorts) {
      try {
         $response = Invoke-RestMethod -Uri "http://localhost:$port/healthz" -Method GET -TimeoutSec 2 -ErrorAction SilentlyContinue
         if ($response) {
            Write-Host "✅ API N8N trouvée sur port $port" -ForegroundColor Green
            $Results.export_methods.api_available = $true
            $Results.export_methods.api_port = $port
            $Results.export_methods.api_endpoint = "http://localhost:$port"
            $apiFound = $true
            break
         }
      }
      catch {
         # Continuer à chercher sur d'autres ports
      }
   }
   
   if (-not $apiFound) {
      Write-Host "⚠️ API N8N non accessible" -ForegroundColor Yellow
      $Results.export_methods.api_available = $false
   }
}
catch {
   $Results.export_methods.api_available = $false
   $Results.export_methods.api_error = $_.Exception.Message
}

# 6. Rechercher dossiers N8N typiques
Write-Host "📂 Scan dossiers N8N..." -ForegroundColor Yellow
try {
   $n8nDirs = @()
   $typicalDirs = @(
      ".n8n",
      "n8n",
      ".n8n-data",
      "workflows",
      "automations"
   )
   
   foreach ($dir in $typicalDirs) {
      $found = Get-ChildItem -Recurse -Directory -Name $dir -ErrorAction SilentlyContinue |
      Where-Object { $_ -notmatch "node_modules|\.git" } |
      Select-Object -First 5
      
      if ($found) {
         foreach ($f in $found) {
            $fullPath = Join-Path (Get-Location) $f
            if (Test-Path $fullPath) {
               $itemCount = (Get-ChildItem $fullPath -ErrorAction SilentlyContinue).Count
               $n8nDirs += @{
                  name       = $dir
                  path       = $f
                  full_path  = $fullPath
                  item_count = $itemCount
               }
               Write-Host "   📂 $f ($itemCount items)" -ForegroundColor White
            }
         }
      }
   }
   
   $Results.scan_locations = $n8nDirs
   
}
catch {
   $errorMsg = "Erreur scan dossiers: $($_.Exception.Message)"
   $Results.errors += $errorMsg
   Write-Host "❌ $errorMsg" -ForegroundColor Red
}

# Calcul du résumé
$EndTime = Get-Date
$TotalDuration = ($EndTime - $StartTime).TotalSeconds

$Results.summary = @{
   total_duration_seconds = $TotalDuration
   config_files_found     = $Results.n8n_config.Count
   databases_found        = $Results.database_scan.Count
   workflows_found        = $Results.workflows_found.Count
   n8n_directories        = $Results.scan_locations.Count
   cli_available          = $Results.export_methods.cli_available
   api_available          = $Results.export_methods.api_available
   errors_count           = $Results.errors.Count
   status                 = if ($Results.workflows_found.Count -gt 0 -or $Results.export_methods.cli_available -or $Results.export_methods.api_available) { "SUCCESS" } else { "PARTIAL" }
}

# Sauvegarde des résultats
$outputFile = Join-Path $OutputDir "n8n-workflows-export.json"
$Results | ConvertTo-Json -Depth 10 | Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "📋 RÉSUMÉ TÂCHE 009:" -ForegroundColor Cyan
Write-Host "   Durée totale: $([math]::Round($TotalDuration, 2))s" -ForegroundColor White
Write-Host "   Fichiers config: $($Results.summary.config_files_found)" -ForegroundColor White
Write-Host "   Bases de données: $($Results.summary.databases_found)" -ForegroundColor White
Write-Host "   Workflows trouvés: $($Results.summary.workflows_found)" -ForegroundColor White
Write-Host "   Dossiers N8N: $($Results.summary.n8n_directories)" -ForegroundColor White
Write-Host "   CLI disponible: $($Results.summary.cli_available)" -ForegroundColor White
Write-Host "   API disponible: $($Results.summary.api_available)" -ForegroundColor White
Write-Host "   Erreurs: $($Results.summary.errors_count)" -ForegroundColor White
Write-Host "   Status: $($Results.summary.status)" -ForegroundColor $(if ($Results.summary.status -eq "SUCCESS") { "Green" } else { "Yellow" })
Write-Host ""
Write-Host "💾 Export sauvé: $outputFile" -ForegroundColor Green

if ($Verbose -and $Results.errors.Count -gt 0) {
   Write-Host ""
   Write-Host "⚠️ ERREURS DÉTECTÉES:" -ForegroundColor Yellow
   foreach ($errorItem in $Results.errors) {
      Write-Host "   $errorItem" -ForegroundColor Red
   }
}

Write-Host ""
Write-Host "✅ TÂCHE 009 TERMINÉE" -ForegroundColor Green

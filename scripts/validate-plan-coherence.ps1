# ========================================
# Script de Validation Cohérence Plans
# Phase 6.1.2 - Scripts PowerShell d'Administration
# ========================================

param(
   [string]$PlanPath = "./projet/roadmaps/plans/",
   [switch]$Fix,
   [switch]$Verbose,
   [switch]$DetailedReport,
   [string]$OutputFormat = "console", # console, json, html
   [string]$ReportPath = "./validation-report.json"
)

# Configuration des couleurs et styles
$ErrorColor = "Red"
$WarningColor = "Yellow" 
$SuccessColor = "Green"
$InfoColor = "Cyan"

function Write-StatusMessage {
   param([string]$Message, [string]$Color = "White")
   Write-Host $Message -ForegroundColor $Color
}

function Initialize-ValidationEnvironment {
   Write-StatusMessage "🔧 Initialisation environnement de validation..." $InfoColor
    
   # Vérifier la présence des outils requis
   $requiredTools = @(
      @{Name = "go"; Command = "go version"; Description = "Go compiler" }
      @{Name = "git"; Command = "git --version"; Description = "Git version control" }
   )
    
   foreach ($tool in $requiredTools) {
      try {
         $null = Invoke-Expression $tool.Command
         Write-StatusMessage "✅ $($tool.Description) disponible" $SuccessColor
      }
      catch {
         Write-StatusMessage "❌ $($tool.Description) non trouvé" $ErrorColor
         return $false
      }
   }
    
   # Créer répertoires de travail si nécessaire
   $workDirs = @("./logs", "./reports", "./backups")
   foreach ($dir in $workDirs) {
      if (-not (Test-Path $dir)) {
         New-Item -ItemType Directory -Path $dir -Force | Out-Null
         Write-StatusMessage "📁 Créé répertoire: $dir" $InfoColor
      }
   }
    
   return $true
}

function Get-PlanFiles {
   param([string]$Path)
    
   Write-StatusMessage "🔍 Recherche des fichiers de plans dans: $Path" $InfoColor
    
   if (-not (Test-Path $Path)) {
      Write-StatusMessage "❌ Chemin non trouvé: $Path" $ErrorColor
      return @()
   }
    
   $planFiles = Get-ChildItem -Path $Path -Filter "*.md" -Recurse | 
   Where-Object { $_.Name -match "plan-dev-v\d+" }
    
   Write-StatusMessage "📋 Trouvé $($planFiles.Count) fichiers de plans" $InfoColor
   return $planFiles
}

function Test-PlanStructure {
   param([System.IO.FileInfo]$PlanFile)
    
   $issues = @()
   $content = Get-Content $PlanFile.FullName -Raw
    
   # Vérification métadonnées de base
   if ($content -notmatch "# Plan de développement v\d+") {
      $issues += @{
         Type        = "structure"
         Severity    = "error"
         Message     = "Titre de plan manquant ou malformé"
         Location    = "Ligne 1"
         Suggestion  = "Ajouter un titre avec format '# Plan de développement vXX'"
         AutoFixable = $false
      }
   }
    
   # Vérification progression
   if ($content -notmatch "Progression:\s*\d+%") {
      $issues += @{
         Type        = "metadata"
         Severity    = "warning"
         Message     = "Indicateur de progression manquant"
         Location    = "En-tête"
         Suggestion  = "Ajouter 'Progression: XX%' dans l'en-tête"
         AutoFixable = $true
      }
   }
    
   # Vérification structure phases
   $phaseMatches = [regex]::Matches($content, "##\s+Phase\s+\d+:")
   if ($phaseMatches.Count -eq 0) {
      $issues += @{
         Type        = "structure"
         Severity    = "error"
         Message     = "Aucune phase détectée"
         Location    = "Structure générale"
         Suggestion  = "Organiser le contenu en phases avec '## Phase X:'"
         AutoFixable = $false
      }
   }
    
   # Vérification tâches
   $taskMatches = [regex]::Matches($content, "- \[[x ]\]")
   if ($taskMatches.Count -eq 0) {
      $issues += @{
         Type        = "content"
         Severity    = "warning"
         Message     = "Aucune tâche avec checkbox détectée"
         Location    = "Contenu"
         Suggestion  = "Utiliser format '- [ ]' ou '- [x]' pour les tâches"
         AutoFixable = $false
      }
   }
    
   return $issues
}

function Invoke-GoValidation {
   param([string]$PlanPath)
    
   Write-StatusMessage "🔍 Lancement validation Go..." $InfoColor
    
   try {
      # Utiliser le validateur Go existant si disponible
      $validationCmd = "go run tools/validation-engine.go -path `"$PlanPath`""
        
      if ($Verbose) {
         Write-StatusMessage "Commande: $validationCmd" $InfoColor
      }
        
      $result = Invoke-Expression $validationCmd 2>&1
        
      if ($LASTEXITCODE -eq 0) {
         Write-StatusMessage "✅ Validation Go réussie" $SuccessColor
         return @{
            Success = $true
            Output  = $result
            Issues  = @()
         }
      }
      else {
         Write-StatusMessage "⚠️ Validation Go avec avertissements" $WarningColor
         return @{
            Success = $false
            Output  = $result
            Issues  = @(@{
                  Type        = "validation"
                  Severity    = "error"
                  Message     = "Échec validation Go: $result"
                  Location    = "Validation engine"
                  Suggestion  = "Vérifier la structure et syntaxe du plan"
                  AutoFixable = $false
               })
         }
      }
   }
   catch {
      Write-StatusMessage "❌ Erreur lors de la validation Go: $($_.Exception.Message)" $ErrorColor
      return @{
         Success = $false
         Output  = ""
         Issues  = @(@{
               Type        = "system"
               Severity    = "error"
               Message     = "Validation Go non disponible: $($_.Exception.Message)"
               Location    = "Système"
               Suggestion  = "Vérifier l'installation Go et les outils de validation"
               AutoFixable = $false
            })
      }
   }
}

function Invoke-AutoFix {
   param([System.IO.FileInfo]$PlanFile, [array]$Issues)
    
   $fixedIssues = 0
   $content = Get-Content $PlanFile.FullName -Raw
   $originalContent = $content
    
   Write-StatusMessage "🔧 Tentative de correction automatique pour: $($PlanFile.Name)" $InfoColor
    
   foreach ($issue in $Issues) {
      if ($issue.AutoFixable) {
         switch ($issue.Type) {
            "metadata" {
               if ($issue.Message -match "progression") {
                  # Calculer progression basée sur les tâches
                  $totalTasks = ([regex]::Matches($content, "- \[[x ]\]")).Count
                  $completedTasks = ([regex]::Matches($content, "- \[x\]")).Count
                        
                  if ($totalTasks -gt 0) {
                     $progression = [math]::Round(($completedTasks / $totalTasks) * 100)
                            
                     # Ajouter ou mettre à jour la progression
                     if ($content -match "Progression:\s*\d+%") {
                        $content = $content -replace "Progression:\s*\d+%", "Progression: $progression%"
                     }
                     else {
                        # Ajouter après le titre
                        $content = $content -replace "(# Plan de développement v\d+[^\n]*\n)", "`$1`n**Progression: $progression%**`n"
                     }
                            
                     $fixedIssues++
                     Write-StatusMessage "✅ Progression mise à jour: $progression%" $SuccessColor
                  }
               }
            }
         }
      }
   }
    
   # Sauvegarder si des modifications ont été apportées
   if ($content -ne $originalContent) {
      # Créer backup
      $backupPath = "./backups/$($PlanFile.BaseName)_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
      Copy-Item $PlanFile.FullName $backupPath
      Write-StatusMessage "💾 Backup créé: $backupPath" $InfoColor
        
      # Sauvegarder fichier modifié
      Set-Content -Path $PlanFile.FullName -Value $content -Encoding UTF8
      Write-StatusMessage "✅ $fixedIssues corrections appliquées à $($PlanFile.Name)" $SuccessColor
   }
   else {
      Write-StatusMessage "ℹ️ Aucune correction automatique applicable" $InfoColor
   }
    
   return $fixedIssues
}

function Export-ValidationReport {
   param([hashtable]$Report, [string]$Format, [string]$Path)
    
   switch ($Format.ToLower()) {
      "json" {
         $Report | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
         Write-StatusMessage "📊 Rapport JSON exporté: $Path" $InfoColor
      }
      "html" {
         $htmlPath = $Path -replace "\.json$", ".html"
         $html = Generate-HtmlReport $Report
         Set-Content -Path $htmlPath -Value $html -Encoding UTF8
         Write-StatusMessage "📊 Rapport HTML exporté: $htmlPath" $InfoColor
      }
      "console" {
         # Déjà affiché dans la console
      }
   }
}

function Generate-HtmlReport {
   param([hashtable]$Report)
    
   $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de Validation des Plans</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 40px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
        .summary { background: #ecf0f1; padding: 20px; border-radius: 5px; margin: 20px 0; }
        .issue { margin: 10px 0; padding: 15px; border-left: 4px solid #e74c3c; background: #fdf2f2; }
        .issue.warning { border-left-color: #f39c12; background: #fef9e7; }
        .issue.info { border-left-color: #3498db; background: #e8f4fd; }
        .success { color: #27ae60; }
        .error { color: #e74c3c; }
        .warning { color: #f39c12; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔍 Rapport de Validation des Plans de Développement</h1>
        <div class="summary">
            <h2>📊 Résumé</h2>
            <p><strong>Plans analysés:</strong> $($Report.Summary.TotalPlans)</p>
            <p><strong>Plans valides:</strong> <span class="success">$($Report.Summary.ValidPlans)</span></p>
            <p><strong>Plans avec problèmes:</strong> <span class="error">$($Report.Summary.InvalidPlans)</span></p>
            <p><strong>Total problèmes:</strong> $($Report.Summary.TotalIssues)</p>
            <p><strong>Corrections automatiques:</strong> $($Report.Summary.AutoFixesApplied)</p>
        </div>
        
        <h2>📋 Détails par Plan</h2>
"@
    
   foreach ($planResult in $Report.Results) {
      $statusClass = if ($planResult.Issues.Count -eq 0) { "success" } else { "error" }
      $html += @"
        <h3 class="$statusClass">📄 $($planResult.PlanName)</h3>
"@
        
      if ($planResult.Issues.Count -eq 0) {
         $html += "<p class='success'>✅ Aucun problème détecté</p>"
      }
      else {
         foreach ($issue in $planResult.Issues) {
            $issueClass = $issue.Severity
            $html += @"
        <div class="issue $issueClass">
            <strong>$($issue.Type.ToUpper()):</strong> $($issue.Message)<br>
            <small><strong>Localisation:</strong> $($issue.Location)</small><br>
            <small><strong>Suggestion:</strong> $($issue.Suggestion)</small>
        </div>
"@
         }
      }
   }
    
   $html += @"
        <div class="summary">
            <p><small>Rapport généré le $(Get-Date -Format 'dd/MM/yyyy à HH:mm:ss')</small></p>
        </div>
    </div>
</body>
</html>
"@
    
   return $html
}

# ========================================
# EXECUTION PRINCIPALE
# ========================================

Write-StatusMessage "🔍 Validation cohérence plans de développement..." $InfoColor
Write-StatusMessage "📂 Chemin d'analyse: $PlanPath" $InfoColor

# Initialisation
if (-not (Initialize-ValidationEnvironment)) {
   Write-StatusMessage "❌ Échec initialisation environnement" $ErrorColor
   exit 1
}

# Collecte des fichiers
$planFiles = Get-PlanFiles $PlanPath
if ($planFiles.Count -eq 0) {
   Write-StatusMessage "❌ Aucun fichier de plan trouvé" $ErrorColor
   exit 1
}

# Initialisation du rapport
$validationReport = @{
   Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
   Summary   = @{
      TotalPlans       = $planFiles.Count
      ValidPlans       = 0
      InvalidPlans     = 0
      TotalIssues      = 0
      AutoFixesApplied = 0
   }
   Results   = @()
}

# Validation de chaque plan
foreach ($planFile in $planFiles) {
   Write-StatusMessage "`n📄 Analyse: $($planFile.Name)" $InfoColor
    
   # Tests structurels PowerShell
   $structuralIssues = Test-PlanStructure $planFile
    
   # Validation Go si disponible
   $goValidation = Invoke-GoValidation $planFile.DirectoryName
    
   # Combiner les résultats
   $allIssues = $structuralIssues + $goValidation.Issues
    
   # Correction automatique si demandée
   $fixesApplied = 0
   if ($Fix -and $allIssues.Count -gt 0) {
      $fixesApplied = Invoke-AutoFix $planFile $allIssues
      $validationReport.Summary.AutoFixesApplied += $fixesApplied
   }
    
   # Affichage des résultats
   if ($allIssues.Count -eq 0) {
      Write-StatusMessage "✅ Plan valide" $SuccessColor
      $validationReport.Summary.ValidPlans++
   }
   else {
      Write-StatusMessage "❌ $($allIssues.Count) problème(s) détecté(s)" $ErrorColor
      $validationReport.Summary.InvalidPlans++
      $validationReport.Summary.TotalIssues += $allIssues.Count
        
      if ($Verbose -or $DetailedReport) {
         foreach ($issue in $allIssues) {
            $color = switch ($issue.Severity) {
               "error" { $ErrorColor }
               "warning" { $WarningColor }
               default { $InfoColor }
            }
            Write-StatusMessage "  ⚠️ [$($issue.Severity.ToUpper())] $($issue.Message)" $color
            if ($Verbose) {
               Write-StatusMessage "     📍 $($issue.Location)" "Gray"
               Write-StatusMessage "     💡 $($issue.Suggestion)" "Gray"
            }
         }
      }
        
      if ($fixesApplied -gt 0) {
         Write-StatusMessage "🔧 $fixesApplied correction(s) automatique(s) appliquée(s)" $SuccessColor
      }
   }
    
   # Ajouter au rapport
   $validationReport.Results += @{
      PlanName       = $planFile.Name
      PlanPath       = $planFile.FullName
      Issues         = $allIssues
      FixesApplied   = $fixesApplied
      ValidationTime = Get-Date -Format "HH:mm:ss"
   }
}

# Résumé final
Write-StatusMessage "`n📊 RÉSUMÉ DE VALIDATION" $InfoColor
Write-StatusMessage "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" $InfoColor
Write-StatusMessage "📋 Plans analysés: $($validationReport.Summary.TotalPlans)" $InfoColor
Write-StatusMessage "✅ Plans valides: $($validationReport.Summary.ValidPlans)" $SuccessColor
Write-StatusMessage "❌ Plans avec problèmes: $($validationReport.Summary.InvalidPlans)" $ErrorColor
Write-StatusMessage "⚠️ Total problèmes: $($validationReport.Summary.TotalIssues)" $WarningColor

if ($Fix) {
   Write-StatusMessage "🔧 Corrections appliquées: $($validationReport.Summary.AutoFixesApplied)" $SuccessColor
}

# Export du rapport
if ($OutputFormat -ne "console" -or $DetailedReport) {
   Export-ValidationReport $validationReport $OutputFormat $ReportPath
}

# Code de sortie
if ($validationReport.Summary.InvalidPlans -eq 0) {
   Write-StatusMessage "`n🎉 Tous les plans sont cohérents!" $SuccessColor
   exit 0
}
else {
   Write-StatusMessage "`n⚠️ Des problèmes ont été détectés dans certains plans" $WarningColor
   if (-not $Fix) {
      Write-StatusMessage "💡 Utilisez -Fix pour tenter une correction automatique" $InfoColor
   }
   exit 1
}

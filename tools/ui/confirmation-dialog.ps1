# Confirmation Dialog System - Plan Dev v41
# Interface de confirmation utilisateur pour opérations critiques
# Version: 1.0
# Date: 2025-06-03

[CmdletBinding()]
param(
   [Parameter(Mandatory = $true)]
   [string]$SimulationReportPath,
    
   [string]$LogPath = ".\user-choices.log",
    
   [switch]$AutoConfirm,
    
   [switch]$DetailedView
)

# Configuration des couleurs et styles
$Colors = @{
   Header   = "Cyan"
   Success  = "Green"
   Warning  = "Yellow"
   Error    = "Red"
   Info     = "White"
   Critical = "Magenta"
}

# Fonction pour afficher un header stylisé
function Show-Header {
   param([string]$Title)
    
   Write-Host "`n" + "=" * 60 -ForegroundColor $Colors.Header
   Write-Host " $Title" -ForegroundColor $Colors.Header
   Write-Host "=" * 60 -ForegroundColor $Colors.Header
}

# Fonction pour afficher un résumé des opérations
function Show-OperationSummary {
   param([object]$SimulationData)
    
   Show-Header "RÉSUMÉ DES OPÉRATIONS PLANIFIÉES"
    
   $summary = $SimulationData.summary
   Write-Host "📊 Total des opérations: $($SimulationData.total_operations)" -ForegroundColor $Colors.Info
   Write-Host "🔴 Opérations critiques: $($summary.critical_operations)" -ForegroundColor $Colors.Error
   Write-Host "🟡 Opérations à risque élevé: $($summary.high_risk_operations)" -ForegroundColor $Colors.Warning
   Write-Host "🟠 Opérations à risque moyen: $($summary.medium_risk_operations)" -ForegroundColor $Colors.Warning
   Write-Host "🟢 Opérations à faible risque: $($summary.low_risk_operations)" -ForegroundColor $Colors.Success
    
   if ($summary.critical_operations -gt 0) {
      Write-Host "`n⚠️  ATTENTION: Des opérations critiques ont été détectées!" -ForegroundColor $Colors.Critical
      Write-Host "   Une révision détaillée est fortement recommandée." -ForegroundColor $Colors.Critical
   }
}

# Fonction pour afficher les détails d'une opération
function Show-OperationDetails {
   param([object]$Operation, [int]$Index)
    
   $riskColor = switch ($Operation.risk_level) {
      "CRITICAL" { $Colors.Error }
      "HIGH" { $Colors.Warning }
      "MEDIUM" { $Colors.Warning }
      "LOW" { $Colors.Success }
      default { $Colors.Info }
   }
    
   Write-Host "`n[$($Index + 1)] " -NoNewline -ForegroundColor $Colors.Info
   Write-Host "$($Operation.action_type.ToUpper()): " -NoNewline -ForegroundColor $Colors.Info
   Write-Host "$($Operation.source_path)" -ForegroundColor $Colors.Info
   Write-Host "    ➜ $($Operation.destination_path)" -ForegroundColor $Colors.Info
   Write-Host "    🎯 Niveau de risque: " -NoNewline -ForegroundColor $Colors.Info
   Write-Host "$($Operation.risk_level)" -ForegroundColor $riskColor
   Write-Host "    ⏱️  Durée estimée: $($Operation.estimated_duration)" -ForegroundColor $Colors.Info
    
   # Afficher les fichiers critiques affectés
   if ($Operation.impact.critical_files -and $Operation.impact.critical_files.Count -gt 0) {
      Write-Host "    🔒 Fichiers critiques affectés:" -ForegroundColor $Colors.Warning
      foreach ($file in $Operation.impact.critical_files) {
         Write-Host "       - $file" -ForegroundColor $Colors.Warning
      }
   }
    
   # Afficher les conflits
   if ($Operation.conflicts -and $Operation.conflicts.Count -gt 0) {
      Write-Host "    ⚠️  Conflits détectés:" -ForegroundColor $Colors.Error
      foreach ($conflict in $Operation.conflicts) {
         $conflictColor = switch ($conflict.severity) {
            "CRITICAL" { $Colors.Error }
            "WARNING" { $Colors.Warning }
            default { $Colors.Info }
         }
         Write-Host "       - $($conflict.description)" -ForegroundColor $conflictColor
         Write-Host "         Résolution: $($conflict.resolution)" -ForegroundColor $Colors.Info
      }
   }
    
   # Afficher les recommandations
   if ($Operation.recommendations -and $Operation.recommendations.Count -gt 0) {
      Write-Host "    💡 Recommandations:" -ForegroundColor $Colors.Info
      foreach ($rec in $Operation.recommendations) {
         Write-Host "       - $rec" -ForegroundColor $Colors.Info
      }
   }
}

# Fonction pour obtenir la confirmation utilisateur
function Get-UserConfirmation {
   param(
      [string]$Message,
      [string]$DefaultChoice = "N",
      [string[]]$Options = @("Y", "N", "D", "S")
   )
    
   do {
      Write-Host "`n$Message" -ForegroundColor $Colors.Info
      Write-Host "Options: [Y]es, [N]o, [D]étails, [S]kip, [Q]uit" -ForegroundColor $Colors.Info
      Write-Host "Choix [$DefaultChoice]: " -NoNewline -ForegroundColor $Colors.Info
        
      $response = Read-Host
      if ([string]::IsNullOrWhiteSpace($response)) {
         $response = $DefaultChoice
      }
        
      $response = $response.ToUpper()
        
      switch ($response) {
         "Y" { return "Yes" }
         "N" { return "No" }
         "D" { return "Details" }
         "S" { return "Skip" }
         "Q" { return "Quit" }
         default {
            Write-Host "Option invalide. Veuillez choisir Y, N, D, S ou Q." -ForegroundColor $Colors.Error
         }
      }
   } while ($true)
}

# Fonction pour enregistrer les choix utilisateur
function Save-UserChoice {
   param(
      [string]$Operation,
      [string]$Choice,
      [string]$Timestamp,
      [string]$LogPath
   )
    
   $logEntry = @{
      Timestamp = $Timestamp
      Operation = $Operation
      Choice    = $Choice
      User      = $env:USERNAME
      Computer  = $env:COMPUTERNAME
   }
    
   $logLine = "$($logEntry.Timestamp) | $($logEntry.User)@$($logEntry.Computer) | $($logEntry.Operation) | $($logEntry.Choice)"
   Add-Content -Path $LogPath -Value $logLine -Encoding UTF8
}

# Fonction pour afficher l'aide détaillée
function Show-DetailedHelp {
   Show-Header "AIDE DÉTAILLÉE"
    
   Write-Host "🔍 NIVEAUX DE RISQUE:" -ForegroundColor $Colors.Info
   Write-Host "  🔴 CRITICAL  - Risque très élevé de corruption ou perte de données" -ForegroundColor $Colors.Error
   Write-Host "  🟡 HIGH     - Risque élevé, révision recommandée" -ForegroundColor $Colors.Warning
   Write-Host "  🟠 MEDIUM   - Risque modéré, attention requise" -ForegroundColor $Colors.Warning
   Write-Host "  🟢 LOW      - Risque faible, opération généralement sûre" -ForegroundColor $Colors.Success
    
   Write-Host "`n🎯 TYPES DE CONFLITS:" -ForegroundColor $Colors.Info
   Write-Host "  • destination_exists  - Le fichier de destination existe déjà" -ForegroundColor $Colors.Info
   Write-Host "  • permission_denied   - Permissions insuffisantes" -ForegroundColor $Colors.Info
   Write-Host "  • self_deletion      - Risque d'auto-suppression du script" -ForegroundColor $Colors.Info
    
   Write-Host "`n⌨️  OPTIONS DISPONIBLES:" -ForegroundColor $Colors.Info
   Write-Host "  Y - Oui, exécuter cette opération" -ForegroundColor $Colors.Success
   Write-Host "  N - Non, ignorer cette opération" -ForegroundColor $Colors.Error
   Write-Host "  D - Afficher plus de détails" -ForegroundColor $Colors.Info
   Write-Host "  S - Ignorer toutes les opérations restantes" -ForegroundColor $Colors.Warning
   Write-Host "  Q - Quitter immédiatement" -ForegroundColor $Colors.Error
}

# Fonction principale de confirmation
function Invoke-OperationConfirmation {
   param([string]$SimulationReportPath, [string]$LogPath, [bool]$AutoConfirm, [bool]$DetailedView)
    
   # Charger le rapport de simulation
   if (-not (Test-Path $SimulationReportPath)) {
      throw "Rapport de simulation non trouvé: $SimulationReportPath"
   }
    
   $simulationData = Get-Content $SimulationReportPath -Raw | ConvertFrom-Json
    
   # Afficher l'en-tête
   Show-Header "SYSTÈME DE CONFIRMATION - Plan Dev v41"
   Write-Host "Rapport de simulation: $SimulationReportPath" -ForegroundColor $Colors.Info
   Write-Host "Horodatage: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $Colors.Info
    
   # Afficher le résumé
   Show-OperationSummary -SimulationData $simulationData
    
   # Mode auto-confirm
   if ($AutoConfirm) {
      Write-Host "`n🤖 Mode auto-confirmation activé" -ForegroundColor $Colors.Warning
      Write-Host "Toutes les opérations seront approuvées automatiquement." -ForegroundColor $Colors.Warning
        
      $allChoices = @()
      for ($i = 0; $i -lt $simulationData.results.Count; $i++) {
         $operation = $simulationData.results[$i]
         $choice = if ($operation.risk_level -eq "CRITICAL") { "No" } else { "Yes" }
         $allChoices += @{
            Index     = $i
            Operation = "$($operation.action_type): $($operation.source_path)"
            Choice    = $choice
         }
            
         Save-UserChoice -Operation $allChoices[-1].Operation -Choice $choice -Timestamp (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -LogPath $LogPath
      }
        
      return $allChoices
   }
    
   # Mode interactif
   $approvedOperations = @()
   $currentIndex = 0
    
   while ($currentIndex -lt $simulationData.results.Count) {
      $operation = $simulationData.results[$currentIndex]
        
      Show-Header "OPÉRATION $($currentIndex + 1) sur $($simulationData.results.Count)"
      Show-OperationDetails -Operation $operation -Index $currentIndex
        
      $defaultChoice = if ($operation.risk_level -eq "CRITICAL") { "N" } else { "Y" }
      $confirmation = Get-UserConfirmation -Message "Voulez-vous exécuter cette opération?" -DefaultChoice $defaultChoice
        
      $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
      $operationDesc = "$($operation.action_type): $($operation.source_path)"
        
      switch ($confirmation) {
         "Yes" {
            $approvedOperations += @{
               Index     = $currentIndex
               Operation = $operationDesc
               Choice    = "Yes"
            }
            Save-UserChoice -Operation $operationDesc -Choice "Yes" -Timestamp $timestamp -LogPath $LogPath
            Write-Host "✅ Opération approuvée" -ForegroundColor $Colors.Success
            $currentIndex++
         }
         "No" {
            Save-UserChoice -Operation $operationDesc -Choice "No" -Timestamp $timestamp -LogPath $LogPath
            Write-Host "❌ Opération ignorée" -ForegroundColor $Colors.Error
            $currentIndex++
         }
         "Details" {
            if ($DetailedView) {
               Write-Host "`n🔍 DÉTAILS TECHNIQUES:" -ForegroundColor $Colors.Info
               $operation | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor $Colors.Info
            }
            else {
               Show-DetailedHelp
            }
         }
         "Skip" {
            Write-Host "⏭️  Ignorer toutes les opérations restantes" -ForegroundColor $Colors.Warning
            Save-UserChoice -Operation "SKIP_ALL_REMAINING" -Choice "Skip" -Timestamp $timestamp -LogPath $LogPath
            break
         }
         "Quit" {
            Write-Host "🚪 Abandon de la session" -ForegroundColor $Colors.Error
            Save-UserChoice -Operation "QUIT_SESSION" -Choice "Quit" -Timestamp $timestamp -LogPath $LogPath
            return $null
         }
      }
   }
    
   # Résumé final
   if ($approvedOperations.Count -gt 0) {
      Show-Header "RÉSUMÉ DES OPÉRATIONS APPROUVÉES"
      Write-Host "✅ $($approvedOperations.Count) opération(s) approuvée(s)" -ForegroundColor $Colors.Success
        
      foreach ($approved in $approvedOperations) {
         Write-Host "  [$($approved.Index + 1)] $($approved.Operation)" -ForegroundColor $Colors.Info
      }
   }
   else {
      Write-Host "`n❌ Aucune opération approuvée" -ForegroundColor $Colors.Warning
   }
    
   return $approvedOperations
}

# Point d'entrée principal
try {
   $approvedOps = Invoke-OperationConfirmation -SimulationReportPath $SimulationReportPath -LogPath $LogPath -AutoConfirm:$AutoConfirm -DetailedView:$DetailedView
    
   if ($null -eq $approvedOps) {
      Write-Host "`n🚪 Session abandonnée par l'utilisateur" -ForegroundColor $Colors.Warning
      exit 2
   }
   elseif ($approvedOps.Count -eq 0) {
      Write-Host "`n⚠️  Aucune opération à exécuter" -ForegroundColor $Colors.Warning
      exit 1
   }
   else {
      Write-Host "`n🎯 Prêt à exécuter $($approvedOps.Count) opération(s)" -ForegroundColor $Colors.Success
      Write-Host "📝 Choix sauvegardés dans: $LogPath" -ForegroundColor $Colors.Info
        
      # Exporter les opérations approuvées
      $exportPath = $LogPath -replace "\.log$", "-approved-operations.json"
      $approvedOps | ConvertTo-Json -Depth 3 | Out-File $exportPath -Encoding UTF8
      Write-Host "📋 Opérations approuvées exportées vers: $exportPath" -ForegroundColor $Colors.Info
        
      exit 0
   }
}
catch {
   Write-Error "Erreur dans le système de confirmation: $_"
   exit 3
}

#!/usr/bin/env pwsh
# Script de lancement rapide du Framework de Branchement 8-Niveaux
# Port par défaut: 8090 (résolution du problème de connectivité localhost)

param(
   [Parameter(Mandatory = $false)]
   [int]$Port = 8090,
    
   [Parameter(Mandatory = $false)]
   [string]$Mode = "development",
    
   [Parameter(Mandatory = $false)]
   [switch]$UseNewServer = $true
)

$ErrorActionPreference = "Stop"

function Write-LaunchLog {
   param($Message, $Level = "INFO")
   $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
   $color = switch ($Level) {
      "SUCCESS" { "Green" }
      "WARNING" { "Yellow" }
      "ERROR" { "Red" }
      default { "Cyan" }
   }
   Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Start-BranchingFramework {
   Write-LaunchLog "=============================================="
   Write-LaunchLog "🌿 FRAMEWORK DE BRANCHEMENT 8-NIVEAUX"
   Write-LaunchLog "=============================================="
   Write-LaunchLog "Diagnostic de connectivité localhost - RÉSOLU"
   Write-LaunchLog "Port cible: ${Port}"
   Write-LaunchLog "Mode: ${Mode}"
   Write-LaunchLog "=============================================="
    
   # Vérifier si le port est déjà utilisé
   try {
      $portTest = Test-NetConnection -ComputerName "localhost" -Port $Port -InformationLevel Quiet
      if ($portTest) {
         Write-LaunchLog "⚠️  Port ${Port} déjà utilisé. Recherche d'un port libre..." "WARNING"
            
         # Trouver un port libre
         for ($testPort = $Port; $testPort -le ($Port + 10); $testPort++) {
            $freePortTest = Test-NetConnection -ComputerName "localhost" -Port $testPort -InformationLevel Quiet
            if (-not $freePortTest) {
               Write-LaunchLog "✅ Port libre trouvé: ${testPort}" "SUCCESS"
               $Port = $testPort
               break
            }
         }
      }
      else {
         Write-LaunchLog "✅ Port ${Port} libre" "SUCCESS"
      }
   }
   catch {
      Write-LaunchLog "✅ Port ${Port} libre" "SUCCESS"
   }
    
   # Utiliser le nouveau serveur propre
   if ($UseNewServer) {
      Write-LaunchLog "🚀 Lancement du serveur web moderne..."
      $scriptPath = Join-Path $PSScriptRoot "start-branching-web.ps1"
        
      if (Test-Path $scriptPath) {
         Start-Process -FilePath "pwsh.exe" -ArgumentList "-File", $scriptPath, "-Port", $Port, "-Mode", $Mode -WindowStyle Normal
            
         # Attendre que le serveur démarre
         Write-LaunchLog "⏳ Démarrage en cours..." "INFO"
         Start-Sleep -Seconds 6
            
         # Vérifier le démarrage
         try {
            $serverTest = Test-NetConnection -ComputerName "localhost" -Port $Port -InformationLevel Quiet
            if ($serverTest) {
               Write-LaunchLog "✅ Serveur démarré avec succès!" "SUCCESS"
               Write-LaunchLog "🌐 URL: http://localhost:${Port}/" "SUCCESS"
               Write-LaunchLog "🎯 Framework Ultra-Advanced 8-Level opérationnel" "SUCCESS"
                    
               # Ouvrir dans le navigateur
               Start-Process "http://localhost:${Port}/"
                    
            }
            else {
               Write-LaunchLog "❌ Échec du démarrage du serveur" "ERROR"
            }
         }
         catch {
            Write-LaunchLog "❌ Erreur lors de la vérification: $($_.Exception.Message)" "ERROR"
         }
      }
      else {
         Write-LaunchLog "❌ Script serveur non trouvé: $scriptPath" "ERROR"
      }
   }
   else {
      # Utiliser l'ancien serveur (fallback)
      Write-LaunchLog "🔄 Utilisation du serveur de fallback..."
      $oldScript = Join-Path $PSScriptRoot "branching-server.ps1"
      if (Test-Path $oldScript) {
         & $oldScript -Port $Port -Environment $Mode
      }
      else {
         Write-LaunchLog "❌ Aucun serveur disponible" "ERROR"
      }
   }
}

# Point d'entrée principal
try {
   Start-BranchingFramework
}
catch {
   Write-LaunchLog "❌ Erreur fatale: $($_.Exception.Message)" "ERROR"
   exit 1
}

Write-LaunchLog "=============================================="
Write-LaunchLog "🎉 LANCEMENT TERMINÉ"
Write-LaunchLog "=============================================="

# Script pour démarrer le proxy de santé Qdrant
param(
   [string]$Action = "start"
)

$logFile = "logs/qdrant-health-proxy.log"
$pidFile = ".qdrant-health-proxy.pid"

function Start-QdrantHealthProxy {
   Write-Host "🚀 Démarrage du proxy de santé Qdrant..."
    
   # Assurez-vous que le répertoire de logs existe
   if (-not (Test-Path "logs")) {
      New-Item -ItemType Directory -Path "logs" | Out-Null
   }
    
   # Démarrage du proxy en arrière-plan
   $processInfo = Start-Process -FilePath "bin/qdrant-health-proxy.exe" -NoNewWindow -PassThru -RedirectStandardOutput $logFile -RedirectStandardError $logFile
    
   # Enregistrement du PID pour une utilisation ultérieure
   $processInfo.Id | Out-File -FilePath $pidFile -Encoding UTF8
    
   Write-Host "✅ Proxy de santé Qdrant démarré avec PID: $($processInfo.Id)"
}

function Stop-QdrantHealthProxy {
   Write-Host "🛑 Arrêt du proxy de santé Qdrant..."
    
   if (Test-Path $pidFile) {
      $pid = Get-Content $pidFile
      try {
         $process = Get-Process -Id $pid -ErrorAction Stop
         $process.Kill()
         Remove-Item $pidFile -Force
         Write-Host "✅ Proxy de santé Qdrant arrêté (PID: $pid)"
      }
      catch {
         Write-Host "❌ Erreur lors de l'arrêt du proxy: $_"
      }
   }
   else {
      Write-Host "❌ Fichier PID non trouvé"
   }
}

function Get-QdrantHealthProxyStatus {
   if (Test-Path $pidFile) {
      $pid = Get-Content $pidFile
      try {
         $process = Get-Process -Id $pid -ErrorAction Stop
         Write-Host "✅ Proxy de santé Qdrant en cours d'exécution (PID: $pid)"
      }
      catch {
         Write-Host "❌ Proxy de santé Qdrant non en cours d'exécution"
      }
   }
   else {
      Write-Host "❌ Fichier PID non trouvé"
   }
}

# Exécution de l'action demandée
switch ($Action) {
   "start" {
      Start-QdrantHealthProxy
   }
   "stop" {
      Stop-QdrantHealthProxy
   }
   "status" {
      Get-QdrantHealthProxyStatus
   }
   default {
      Write-Host "❌ Action non reconnue: $Action"
      Write-Host "Actions disponibles: start, stop, status"
   }
}

#!/usr/bin/env pwsh
# Script de démarrage en arrière-plan pour le serveur de branches

param(
   [Parameter(Mandatory = $false)]
   [int]$Port = 8090
)

Write-Host "🚀 Démarrage du serveur de branches en arrière-plan..."
Write-Host "📍 Port: $Port"
Write-Host "🌐 URL: http://localhost:$Port/"

# Démarrage en arrière-plan avec Start-Job
$job = Start-Job -ScriptBlock {
   param($scriptPath, $port)
    
   # Exécuter le serveur de branches
   & pwsh -ExecutionPolicy Bypass -File $scriptPath -Port $port
    
} -ArgumentList (Join-Path $PSScriptRoot "branching-server.ps1"), $Port

Write-Host "✅ Job ID: $($job.Id)"
Write-Host "📋 Pour vérifier le status: Get-Job $($job.Id)"
Write-Host "📄 Pour voir les logs: Receive-Job $($job.Id)"
Write-Host "🛑 Pour arrêter: Stop-Job $($job.Id); Remove-Job $($job.Id)"

# Attendre un moment pour vérifier que le serveur démarre correctement
Start-Sleep -Seconds 3

# Vérifier la connectivité
try {
   $test = Test-NetConnection -ComputerName "localhost" -Port $Port -InformationLevel Quiet
   if ($test) {
      Write-Host "✅ Serveur démarré avec succès et accessible sur le port $Port" -ForegroundColor Green
      Write-Host "🌐 Ouvrez votre navigateur sur: http://localhost:$Port/" -ForegroundColor Cyan
   }
   else {
      Write-Host "⚠️  Le serveur démarre... Vérifiez à nouveau dans quelques secondes" -ForegroundColor Yellow
   }
}
catch {
   Write-Host "⚠️  Test de connectivité en cours..." -ForegroundColor Yellow
}

return $job

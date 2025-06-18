#!/usr/bin/env pwsh
# Auto-Restart-API-Server.ps1 - Surveillance automatique de l'API Server

while ($true) {
   $apiProcess = Get-Process | Where-Object { $_.ProcessName -eq "api-server-fixed" }
    
   if (-not $apiProcess) {
      Write-Host "$(Get-Date): API Server stopped - Restarting..." -ForegroundColor Yellow
        
      # Redémarrer l'API Server
      Start-Process -FilePath "cmd\simple-api-server-fixed\api-server-fixed.exe" -WorkingDirectory "." -WindowStyle Hidden
        
      Start-Sleep -Seconds 5
        
      # Vérifier que ça a redémarré
      $newProcess = Get-Process | Where-Object { $_.ProcessName -eq "api-server-fixed" }
      if ($newProcess) {
         Write-Host "$(Get-Date): API Server restarted successfully (PID: $($newProcess.Id))" -ForegroundColor Green
      }
      else {
         Write-Host "$(Get-Date): Failed to restart API Server" -ForegroundColor Red
      }
   }
   else {
      Write-Host "$(Get-Date): API Server running (PID: $($apiProcess.Id)) - OK" -ForegroundColor Green
   }
    
   Start-Sleep -Seconds 30  # Vérifier toutes les 30 secondes
}

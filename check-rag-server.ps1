# Script pour vérifier l'état du serveur RAG
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$outputFile = "rag-server-status.txt"

Write-Host "Vérification du serveur RAG à $timestamp" -ForegroundColor Cyan

# Test du health endpoint
try {
   Write-Host "Vérification du endpoint /health..." -ForegroundColor Yellow
   $healthResponse = Invoke-WebRequest -Uri "http://localhost:8080/health" -UseBasicParsing
   $healthStatus = "Code: $($healthResponse.StatusCode), Description: $($healthResponse.StatusDescription)"
   Write-Host "Health endpoint: $healthStatus" -ForegroundColor Green
   Add-Content -Path $outputFile -Value "Health endpoint: $healthStatus"
}
catch {
   $errorMessage = "Erreur health endpoint: $($_.Exception.Message)"
   Write-Host $errorMessage -ForegroundColor Red
   Add-Content -Path $outputFile -Value $errorMessage
}

# Test du monitoring endpoint
try {
   Write-Host "Vérification du endpoint /api/v1/monitoring/status..." -ForegroundColor Yellow
   $monitoringResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/monitoring/status" -UseBasicParsing
   $monitoringStatus = "Code: $($monitoringResponse.StatusCode), Description: $($monitoringResponse.StatusDescription)"
   Write-Host "Monitoring endpoint: $monitoringStatus" -ForegroundColor Green
   Add-Content -Path $outputFile -Value "Monitoring endpoint: $monitoringStatus"
    
   if ($monitoringResponse.StatusCode -eq 200) {
      $content = $monitoringResponse.Content
      Add-Content -Path $outputFile -Value "Content: $content"
      Write-Host "Contenu: $content" -ForegroundColor Cyan
   }
}
catch {
   $errorMessage = "Erreur monitoring endpoint: $($_.Exception.Message)"
   Write-Host $errorMessage -ForegroundColor Red
   Add-Content -Path $outputFile -Value $errorMessage
}

# Test de l'infrastructure endpoint
try {
   Write-Host "Vérification du endpoint /api/v1/infrastructure/status..." -ForegroundColor Yellow
   $infraResponse = Invoke-WebRequest -Uri "http://localhost:8080/api/v1/infrastructure/status" -UseBasicParsing
   $infraStatus = "Code: $($infraResponse.StatusCode), Description: $($infraResponse.StatusDescription)"
   Write-Host "Infrastructure endpoint: $infraStatus" -ForegroundColor Green
   Add-Content -Path $outputFile -Value "Infrastructure endpoint: $infraStatus"
    
   if ($infraResponse.StatusCode -eq 200) {
      $content = $infraResponse.Content
      Add-Content -Path $outputFile -Value "Content: $content"
      Write-Host "Contenu: $content" -ForegroundColor Cyan
   }
}
catch {
   $errorMessage = "Erreur infrastructure endpoint: $($_.Exception.Message)"
   Write-Host $errorMessage -ForegroundColor Red
   Add-Content -Path $outputFile -Value $errorMessage
}

Write-Host "Résultats enregistrés dans le fichier $outputFile" -ForegroundColor Green

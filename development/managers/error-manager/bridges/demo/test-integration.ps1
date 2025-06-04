# Quick integration test for Section 8.2 - Real-time Bridge
# This script tests the end-to-end PowerShell-Go integration

Write-Host "🚀 Section 8.2 - Test d'Intégration Rapide" -ForegroundColor Cyan
Write-Host "Optimisation Surveillance Temps Réel" -ForegroundColor Gray
Write-Host ""

$bridgeUrl = "http://localhost:8080"

# Test de connectivité
try {
   $response = Invoke-RestMethod -Uri "$bridgeUrl/health" -Method GET -TimeoutSec 5
   Write-Host "✅ Bridge Go détecté: $($response.status)" -ForegroundColor Green
   Write-Host "   Uptime: $($response.uptime)" -ForegroundColor Gray
}
catch {
   Write-Host "❌ Bridge non disponible. Démarrez-le avec:" -ForegroundColor Red
   Write-Host "   .\persistent_bridge.exe" -ForegroundColor Yellow
   exit 1
}

# Envoi d'un événement de test via HTTP
$testEvent = @{
   type        = "duplication_alert"
   source      = "test-powershell-integration.ps1"
   severity    = "medium"
   message     = "Test PowerShell integration with Go bridge"
   metadata    = @{
      test_mode         = $true
      integration_phase = "8.2"
   }
   script_type = "powershell"
} | ConvertTo-Json

try {
   $response = Invoke-RestMethod -Uri "$bridgeUrl/events" -Method POST -Body $testEvent -ContentType "application/json"
   Write-Host "✅ Événement envoyé avec succès" -ForegroundColor Green
   Write-Host "   ID: $($response.id)" -ForegroundColor Gray
}
catch {
   Write-Host "❌ Erreur envoi événement: $($_.Exception.Message)" -ForegroundColor Red
}

Start-Sleep -Seconds 2

# Vérification du statut
try {
   $status = Invoke-RestMethod -Uri "$bridgeUrl/status" -Method GET
   Write-Host "📊 Statut du Bridge:" -ForegroundColor Cyan
   Write-Host "   Événements traités: $($status.events_processed)" -ForegroundColor Gray
   Write-Host "   Buffer size: $($status.buffer_size)" -ForegroundColor Gray
}
catch {
   Write-Host "⚠️ Impossible de récupérer le statut" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✅ Test d'intégration Section 8.2 terminé" -ForegroundColor Green

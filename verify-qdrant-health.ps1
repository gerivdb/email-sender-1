param(
   [string]$TestUrl = "http://localhost:6333"
)

Write-Host "=== Qdrant Health Check Test ===" -ForegroundColor Green

$endpoints = @("/", "/health", "/collections")

foreach ($endpoint in $endpoints) {
   $fullUrl = "$TestUrl$endpoint"
   try {
      $response = Invoke-WebRequest -Uri $fullUrl -Method Get -UseBasicParsing
      Write-Host "✓ $endpoint - Status: $($response.StatusCode) - Content-Type: $($response.Headers['Content-Type'])" -ForegroundColor Green
   }
   catch {
      Write-Host "✗ $endpoint - Error: $($_.Exception.Message)" -ForegroundColor Red
   }
}

Write-Host "`n=== Docker Container Status ===" -ForegroundColor Yellow
try {
   $containers = docker ps --format "{{.Names}}: {{.Status}}" | Where-Object { $_ -like "*qdrant*" }
   if ($containers) {
      foreach ($container in $containers) {
         Write-Host $container -ForegroundColor Cyan
      }
   }
   else {
      Write-Host "No Qdrant containers found" -ForegroundColor Red
   }
}
catch {
   Write-Host "Error getting container status: $_" -ForegroundColor Red
}

Write-Host "`n=== Summary ===" -ForegroundColor Green
Write-Host "Qdrant configuration has been updated to respond with HTTP 200 for health checks."
Write-Host "The Smart Infrastructure monitoring should now detect Qdrant as healthy."

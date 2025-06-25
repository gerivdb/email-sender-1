# Script de démarrage pour EMAIL_SENDER_1
param(
    [string]$Environment = "development",
    [int]$Port = 8080
)

Write-Host "================================================" -ForegroundColor Green
Write-Host "   EMAIL_SENDER_1 - Installation Complete" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""

# Vérifier si l'exécutable existe
if (-Not (Test-Path "email-sender.exe")) {
    Write-Host "Compilation de l'application..." -ForegroundColor Yellow
    $env:GOTOOLCHAIN = 'local'
    go build -o email-sender.exe main.go
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Erreur lors de la compilation!" -ForegroundColor Red
        exit 1
    }
    Write-Host "Compilation terminée avec succès!" -ForegroundColor Green
}

Write-Host "Démarrage de l'application EMAIL_SENDER_1..." -ForegroundColor Cyan
Write-Host "Environnement: $Environment" -ForegroundColor Gray
Write-Host "Port: $Port" -ForegroundColor Gray
Write-Host ""
Write-Host "L'application sera accessible sur: http://localhost:$Port" -ForegroundColor Yellow
Write-Host "Endpoints disponibles:" -ForegroundColor Yellow
Write-Host "  - GET / : Informations de l'application" -ForegroundColor Gray
Write-Host "  - GET /health : État de santé" -ForegroundColor Gray
Write-Host ""
Write-Host "Appuyez sur Ctrl+C pour arrêter l'application" -ForegroundColor Yellow
Write-Host ""

# Démarrer l'application
& ".\email-sender.exe"

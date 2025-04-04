# Script pour lister les workflows existants dans n8n

# Configuration
$n8nUrl = "http://localhost:5678"
$apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw" # Jeton API AUGMENT

# Vérifier la connexion à n8n
Write-Host "Verification de la connexion a n8n ($n8nUrl)..." -NoNewline
try {
    $headers = @{
        "X-N8N-API-KEY" = $apiToken
    }
    $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers
    Write-Host " Connecte!" -ForegroundColor Green
}
catch {
    Write-Host " Echec de connexion!" -ForegroundColor Red
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Récupérer tous les workflows existants
Write-Host "`nListe des workflows dans n8n:"
Write-Host "================================="
try {
    $headers = @{
        "X-N8N-API-KEY" = $apiToken
    }
    $workflows = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers
    
    if ($workflows.Count -eq 0) {
        Write-Host "Aucun workflow trouve dans n8n." -ForegroundColor Yellow
        exit
    }
    
    # Afficher la liste des workflows
    foreach ($workflow in $workflows) {
        Write-Host "- $($workflow.name) (ID: $($workflow.id))"
        Write-Host "  Cree le: $($workflow.createdAt)"
        Write-Host "  Mis a jour le: $($workflow.updatedAt)"
        Write-Host "  Actif: $($workflow.active)"
        Write-Host "  ---------------------------------"
    }
    
    Write-Host "`nTotal: $($workflows.Count) workflows"
}
catch {
    Write-Host "Erreur lors de la recuperation des workflows: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

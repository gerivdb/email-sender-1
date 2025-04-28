# Script pour supprimer automatiquement tous les workflows existants dans n8n

# Configuration
$n8nUrl = "http://localhost:5678"
$apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw" # Jeton API AUGMENT

# VÃ©rifier la connexion Ã  n8n
Write-Host "VÃ©rification de la connexion Ã  n8n ($n8nUrl)..." -NoNewline
try {
    $headers = @{
        "X-N8N-API-KEY" = $apiToken
    }
    Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers | Out-Null
    Write-Host " ConnectÃ©!" -ForegroundColor Green
}
catch {
    Write-Host " Ã‰chec de connexion!" -ForegroundColor Red
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# RÃ©cupÃ©rer tous les workflows existants
Write-Host "`nRÃ©cupÃ©ration des workflows existants..."
try {
    $headers = @{
        "X-N8N-API-KEY" = $apiToken
    }
    $workflows = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers

    if ($workflows.Count -eq 0) {
        Write-Host "Aucun workflow trouvÃ© dans n8n." -ForegroundColor Yellow
        exit
    }

    Write-Host "TrouvÃ© $($workflows.Count) workflows.`n"

    # Supprimer tous les workflows sans demander de confirmation
    Write-Host "Suppression de tous les workflows existants..."

    $successCount = 0
    foreach ($workflow in $workflows) {
        Write-Host "Suppression du workflow: $($workflow.name)" -NoNewline

        try {
            Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows/$($workflow.id)" -Method Delete -Headers $headers | Out-Null
            Write-Host " - SuccÃ¨s!" -ForegroundColor Green
            $successCount++
        }
        catch {
            Write-Host " - Ã‰chec!" -ForegroundColor Red
            Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host "`nSuppression terminÃ©e: $successCount/$($workflows.Count) workflows supprimÃ©s avec succÃ¨s."
}
catch {
    Write-Host "Erreur lors de la rÃ©cupÃ©ration des workflows: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

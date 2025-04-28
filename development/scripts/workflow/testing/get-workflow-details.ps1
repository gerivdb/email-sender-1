# Script pour obtenir les dÃ©tails des workflows existants dans n8n

# Configuration
$n8nUrl = "http://localhost:5678"
$apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw" # Jeton API AUGMENT

# VÃ©rifier la connexion Ã  n8n
Write-Host "VÃ©rification de la connexion Ã  n8n ($n8nUrl)..." -NoNewline
try {
    $headers = @{
        "X-N8N-API-KEY" = $apiToken
    }
    $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers
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
    
    # Afficher les dÃ©tails de chaque workflow
    foreach ($workflow in $workflows) {
        Write-Host "=== DÃ©tails du workflow ==="
        Write-Host "ID: $($workflow.id)"
        Write-Host "Nom: $($workflow.name)"
        Write-Host "CrÃ©Ã© le: $($workflow.createdAt)"
        Write-Host "Mis Ã  jour le: $($workflow.updatedAt)"
        Write-Host "Actif: $($workflow.active)"
        
        # RÃ©cupÃ©rer les dÃ©tails complets du workflow
        try {
            $workflowDetails = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows/$($workflow.id)" -Method Get -Headers $headers
            
            Write-Host "Nombre de nÅ“uds: $($workflowDetails.nodes.Count)"
            Write-Host "NÅ“uds:"
            foreach ($node in $workflowDetails.nodes) {
                Write-Host "  - $($node.name) (Type: $($node.type))"
            }
        }
        catch {
            Write-Host "Erreur lors de la rÃ©cupÃ©ration des dÃ©tails du workflow: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "=========================="
    }
}
catch {
    Write-Host "Erreur lors de la rÃ©cupÃ©ration des workflows: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

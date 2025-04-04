# Script pour obtenir les détails des workflows existants dans n8n

# Configuration
$n8nUrl = "http://localhost:5678"
$apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw" # Jeton API AUGMENT

# Vérifier la connexion à n8n
Write-Host "Vérification de la connexion à n8n ($n8nUrl)..." -NoNewline
try {
    $headers = @{
        "X-N8N-API-KEY" = $apiToken
    }
    $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers
    Write-Host " Connecté!" -ForegroundColor Green
}
catch {
    Write-Host " Échec de connexion!" -ForegroundColor Red
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

# Récupérer tous les workflows existants
Write-Host "`nRécupération des workflows existants..."
try {
    $headers = @{
        "X-N8N-API-KEY" = $apiToken
    }
    $workflows = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers
    
    if ($workflows.Count -eq 0) {
        Write-Host "Aucun workflow trouvé dans n8n." -ForegroundColor Yellow
        exit
    }
    
    Write-Host "Trouvé $($workflows.Count) workflows.`n"
    
    # Afficher les détails de chaque workflow
    foreach ($workflow in $workflows) {
        Write-Host "=== Détails du workflow ==="
        Write-Host "ID: $($workflow.id)"
        Write-Host "Nom: $($workflow.name)"
        Write-Host "Créé le: $($workflow.createdAt)"
        Write-Host "Mis à jour le: $($workflow.updatedAt)"
        Write-Host "Actif: $($workflow.active)"
        
        # Récupérer les détails complets du workflow
        try {
            $workflowDetails = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows/$($workflow.id)" -Method Get -Headers $headers
            
            Write-Host "Nombre de nœuds: $($workflowDetails.nodes.Count)"
            Write-Host "Nœuds:"
            foreach ($node in $workflowDetails.nodes) {
                Write-Host "  - $($node.name) (Type: $($node.type))"
            }
        }
        catch {
            Write-Host "Erreur lors de la récupération des détails du workflow: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "=========================="
    }
}
catch {
    Write-Host "Erreur lors de la récupération des workflows: $($_.Exception.Message)" -ForegroundColor Red
    exit
}

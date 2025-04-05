# Script pour supprimer tous les workflows dans n8n
# Ce script utilise l'API n8n pour supprimer tous les workflows existants

# Configuration
$n8nUrl = "http://localhost:5678"
$apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw" # Jeton API AUGMENT

# Créer les en-têtes pour l'authentification
$headers = @{
    "X-N8N-API-KEY" = $apiToken
}

# Récupérer tous les workflows
try {
    # Utiliser Out-Null au lieu d'assigner à une variable non utilisée
    Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers | Out-Null
    
    # Récupérer les workflows
    $workflows = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers
    
    # Vérifier s'il y a des workflows
    if ($workflows.Count -eq 0) {
        Write-Host "Aucun workflow trouvé."
        exit
    }
    
    # Afficher les workflows
    Write-Host "Workflows trouvés: $($workflows.Count)"
    $workflows | Format-Table -Property id, name, active
    
    # Demander confirmation
    $confirmation = Read-Host "Voulez-vous supprimer tous ces workflows? (O/N)"
    
    if ($confirmation -eq "O" -or $confirmation -eq "o") {
        # Supprimer chaque workflow
        foreach ($workflow in $workflows) {
            Write-Host "Suppression du workflow: $($workflow.name) (ID: $($workflow.id))"
            
            try {
                # Utiliser Out-Null au lieu d'assigner à une variable non utilisée
                Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows/$($workflow.id)" -Method Delete -Headers $headers | Out-Null
                Write-Host "  Workflow supprimé avec succès." -ForegroundColor Green
            }
            catch {
                Write-Host "  Erreur lors de la suppression du workflow: $_" -ForegroundColor Red
            }
        }
        
        Write-Host "Tous les workflows ont été supprimés." -ForegroundColor Green
    }
    else {
        Write-Host "Opération annulée."
    }
}
catch {
    Write-Host "Erreur lors de la récupération des workflows: $_" -ForegroundColor Red
}

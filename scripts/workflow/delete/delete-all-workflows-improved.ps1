# Script amélioré pour supprimer les workflows dans n8n
# Basé sur la documentation officielle de l'API n8n

# Configuration
$n8nUrl = "http://localhost:5678"
$apiToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmNzI5MDhiZC0wYmViLTQ3YzQtOTgzMy0zOGM1ZmRmNjZlZGQiLCJpc3MiOiJuOG4iLCJhdWQiOiJwdWJsaWMtYXBpIiwiaWF0IjoxNzQzNzkzMzA0fQ.EfYMSbUmk6OLDw70wXNYPl0B-ont0B1WbAnowIQdJbw" # Jeton API AUGMENT

# Paramètres
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [string]$Tag,
    
    [Parameter(Mandatory = $false)]
    [switch]$ActiveOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$InactiveOnly,
    
    [Parameter(Mandatory = $false)]
    [string]$NameFilter
)

# Fonction pour créer les en-têtes d'authentification
function Get-AuthHeaders {
    return @{
        "X-N8N-API-KEY" = $apiToken
        "Accept" = "application/json"
        "Content-Type" = "application/json"
    }
}

# Fonction pour vérifier la connexion à n8n
function Test-N8nConnection {
    Write-Host "Vérification de la connexion à n8n ($n8nUrl)..." -NoNewline
    try {
        $headers = Get-AuthHeaders
        Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers -TimeoutSec 10 | Out-Null
        Write-Host " Connecté!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " Échec de connexion!" -ForegroundColor Red
        Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction pour récupérer tous les workflows
function Get-N8nWorkflows {
    Write-Host "`nRécupération des workflows existants..."
    try {
        $headers = Get-AuthHeaders
        $workflows = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers
        
        # Filtrer les workflows selon les paramètres
        if ($Tag) {
            $workflows = $workflows | Where-Object { $_.tags -and ($_.tags | Where-Object { $_.name -eq $Tag }) }
            Write-Host "Filtrage par tag: $Tag - $($workflows.Count) workflows trouvés"
        }
        
        if ($ActiveOnly) {
            $workflows = $workflows | Where-Object { $_.active -eq $true }
            Write-Host "Filtrage des workflows actifs uniquement - $($workflows.Count) workflows trouvés"
        }
        
        if ($InactiveOnly) {
            $workflows = $workflows | Where-Object { $_.active -eq $false }
            Write-Host "Filtrage des workflows inactifs uniquement - $($workflows.Count) workflows trouvés"
        }
        
        if ($NameFilter) {
            $workflows = $workflows | Where-Object { $_.name -like "*$NameFilter*" }
            Write-Host "Filtrage par nom contenant '$NameFilter' - $($workflows.Count) workflows trouvés"
        }
        
        return $workflows
    }
    catch {
        Write-Host "Erreur lors de la récupération des workflows: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Fonction pour supprimer un workflow
function Remove-N8nWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Workflow
    )
    
    Write-Host "Suppression du workflow: $($Workflow.name) (ID: $($Workflow.id))" -NoNewline
    
    try {
        $headers = Get-AuthHeaders
        Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows/$($Workflow.id)" -Method Delete -Headers $headers | Out-Null
        Write-Host " - Succès!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host " - Échec!" -ForegroundColor Red
        Write-Host "  Erreur: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Fonction principale
function Start-WorkflowDeletion {
    # Vérifier la connexion
    if (-not (Test-N8nConnection)) {
        exit 1
    }
    
    # Récupérer les workflows
    $workflows = Get-N8nWorkflows
    
    if (-not $workflows -or $workflows.Count -eq 0) {
        Write-Host "Aucun workflow trouvé correspondant aux critères." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "`nTrouvé $($workflows.Count) workflows correspondant aux critères."
    
    # Afficher les workflows qui seront supprimés
    Write-Host "`nWorkflows qui seront supprimés:" -ForegroundColor Cyan
    foreach ($workflow in $workflows) {
        $status = if ($workflow.active) { "Actif" } else { "Inactif" }
        $tagNames = if ($workflow.tags) { ($workflow.tags | ForEach-Object { $_.name }) -join ", " } else { "Aucun" }
        
        Write-Host "- $($workflow.name) (ID: $($workflow.id))" -ForegroundColor White
        Write-Host "  Status: $status | Tags: $tagNames" -ForegroundColor Gray
    }
    
    # Demander confirmation sauf si -Force est spécifié
    if (-not $Force) {
        Write-Host "`nAttention: Cette action va supprimer $($workflows.Count) workflows. Cette opération est irréversible." -ForegroundColor Yellow
        $confirmation = Read-Host "Voulez-vous continuer? (O/N)"
        
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Host "Opération annulée par l'utilisateur." -ForegroundColor Yellow
            exit 0
        }
    }
    
    # Supprimer les workflows
    Write-Host "`nSuppression des workflows..."
    $successCount = 0
    
    foreach ($workflow in $workflows) {
        $success = Remove-N8nWorkflow -Workflow $workflow
        if ($success) {
            $successCount++
        }
    }
    
    # Afficher le résumé
    Write-Host "`nSuppression terminée: $successCount/$($workflows.Count) workflows supprimés avec succès."
    
    if ($successCount -lt $workflows.Count) {
        Write-Host "Certains workflows n'ont pas pu être supprimés. Vérifiez les erreurs ci-dessus." -ForegroundColor Yellow
    }
    else {
        Write-Host "Tous les workflows ont été supprimés avec succès!" -ForegroundColor Green
    }
}

# Exécuter le script
Start-WorkflowDeletion

# Afficher l'aide
function Show-Help {
    Write-Host "`nUtilisation: .\delete-all-workflows-improved.ps1 [options]" -ForegroundColor Cyan
    Write-Host "`nOptions:" -ForegroundColor Cyan
    Write-Host "  -Force           Supprimer sans demander de confirmation" -ForegroundColor Cyan
    Write-Host "  -Tag <nom>       Supprimer uniquement les workflows avec ce tag" -ForegroundColor Cyan
    Write-Host "  -ActiveOnly      Supprimer uniquement les workflows actifs" -ForegroundColor Cyan
    Write-Host "  -InactiveOnly    Supprimer uniquement les workflows inactifs" -ForegroundColor Cyan
    Write-Host "  -NameFilter <texte>  Supprimer uniquement les workflows dont le nom contient ce texte" -ForegroundColor Cyan
    Write-Host "`nExemples:" -ForegroundColor Cyan
    Write-Host "  .\delete-all-workflows-improved.ps1 -Force" -ForegroundColor Cyan
    Write-Host "  .\delete-all-workflows-improved.ps1 -Tag 'Production'" -ForegroundColor Cyan
    Write-Host "  .\delete-all-workflows-improved.ps1 -InactiveOnly -NameFilter 'Test'" -ForegroundColor Cyan
}

if ($args -contains "-help" -or $args -contains "--help" -or $args -contains "/?") {
    Show-Help
}

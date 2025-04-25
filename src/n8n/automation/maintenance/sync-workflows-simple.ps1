<#
.SYNOPSIS
    Script simplifié pour synchroniser les workflows n8n.

.DESCRIPTION
    Ce script synchronise les workflows entre n8n et les fichiers locaux dans la nouvelle structure.

.PARAMETER Direction
    Direction de la synchronisation: "to-n8n", "from-n8n" ou "both".

.PARAMETER Environment
    Environnement à synchroniser: "local", "ide" ou "all".

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("to-n8n", "from-n8n", "both")]
    [string]$Direction = "both",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("local", "ide", "all")]
    [string]$Environment = "all"
)

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$workflowsPath = Join-Path -Path $n8nPath -ChildPath "core\workflows"

# Définir les chemins des workflows
$workflowsPaths = @()
if ($Environment -eq "all" -or $Environment -eq "local") {
    $workflowsPaths += Join-Path -Path $workflowsPath -ChildPath "local"
}
if ($Environment -eq "all" -or $Environment -eq "ide") {
    $workflowsPaths += Join-Path -Path $workflowsPath -ChildPath "ide"
}

# Configuration de l'API n8n
$n8nUrl = "http://localhost:5678"
$apiToken = ""  # Laisser vide si l'authentification est désactivée

# Vérifier si n8n est en cours d'exécution
try {
    $response = Invoke-RestMethod -Uri "$n8nUrl/healthz" -Method Get -ErrorAction Stop
    Write-Host "n8n est en cours d'exécution." -ForegroundColor Green
} catch {
    Write-Error "n8n n'est pas en cours d'exécution. Veuillez démarrer n8n avant d'exécuter ce script."
    Write-Host "Vous pouvez démarrer n8n avec la commande: .\start-n8n-new.cmd" -ForegroundColor Yellow
    exit 1
}

# Fonction pour synchroniser les workflows vers n8n
function Sync-WorkflowsToN8n {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowsPath
    )
    
    Write-Host "Synchronisation des workflows vers n8n: $WorkflowsPath" -ForegroundColor Cyan
    
    # Vérifier si le dossier des workflows existe
    if (-not (Test-Path -Path $WorkflowsPath)) {
        Write-Error "Le dossier des workflows n'existe pas: $WorkflowsPath"
        return
    }
    
    # Obtenir la liste des fichiers de workflow
    $workflowFiles = Get-ChildItem -Path $WorkflowsPath -Filter "*.json" -File | Where-Object { $_.Name -notmatch "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.json$" }
    
    if ($workflowFiles.Count -eq 0) {
        Write-Host "Aucun workflow à synchroniser dans $WorkflowsPath." -ForegroundColor Yellow
        return
    }
    
    # Importer les workflows dans n8n
    foreach ($file in $workflowFiles) {
        Write-Host "Importation du workflow: $($file.Name)" -ForegroundColor Green
        
        try {
            $workflowJson = Get-Content -Path $file.FullName -Raw
            $headers = @{
                "Content-Type" = "application/json"
            }
            
            if (-not [string]::IsNullOrEmpty($apiToken)) {
                $headers["X-N8N-API-KEY"] = $apiToken
            }
            
            $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows/import" -Method Post -Headers $headers -Body $workflowJson
            Write-Host "  Workflow importé avec succès: $($response.name) (ID: $($response.id))" -ForegroundColor Green
        } catch {
            Write-Host "  Erreur lors de l'importation du workflow $($file.Name): $_" -ForegroundColor Red
        }
    }
}

# Fonction pour synchroniser les workflows depuis n8n
function Sync-WorkflowsFromN8n {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowsPath
    )
    
    Write-Host "Synchronisation des workflows depuis n8n: $WorkflowsPath" -ForegroundColor Cyan
    
    # Vérifier si le dossier des workflows existe
    if (-not (Test-Path -Path $WorkflowsPath)) {
        New-Item -Path $WorkflowsPath -ItemType Directory -Force | Out-Null
        Write-Host "Dossier des workflows créé: $WorkflowsPath" -ForegroundColor Green
    }
    
    # Récupérer tous les workflows de n8n
    try {
        $headers = @{}
        
        if (-not [string]::IsNullOrEmpty($apiToken)) {
            $headers["X-N8N-API-KEY"] = $apiToken
        }
        
        $workflows = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows" -Method Get -Headers $headers
        
        if ($workflows.Count -eq 0) {
            Write-Host "Aucun workflow trouvé dans n8n." -ForegroundColor Yellow
            return
        }
        
        # Exporter les workflows
        foreach ($workflow in $workflows) {
            Write-Host "Exportation du workflow: $($workflow.name) (ID: $($workflow.id))" -ForegroundColor Green
            
            try {
                $workflowData = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows/$($workflow.id)" -Method Get -Headers $headers
                $workflowJson = $workflowData | ConvertTo-Json -Depth 100
                
                # Déterminer le nom du fichier
                $fileName = "$($workflow.name).json"
                $fileName = $fileName -replace '[\\/:*?"<>|]', '_'  # Remplacer les caractères invalides
                
                # Enregistrer le workflow
                $filePath = Join-Path -Path $WorkflowsPath -ChildPath $fileName
                Set-Content -Path $filePath -Value $workflowJson -Encoding UTF8
                Write-Host "  Workflow exporté: $filePath" -ForegroundColor Green
            } catch {
                Write-Host "  Erreur lors de l'exportation du workflow $($workflow.name): $_" -ForegroundColor Red
            }
        }
    } catch {
        Write-Host "Erreur lors de la récupération des workflows: $_" -ForegroundColor Red
    }
}

# Exécuter la synchronisation
foreach ($workflowsPath in $workflowsPaths) {
    Write-Host "`nTraitement du dossier: $workflowsPath" -ForegroundColor Cyan
    
    if ($Direction -eq "to-n8n" -or $Direction -eq "both") {
        Sync-WorkflowsToN8n -WorkflowsPath $workflowsPath
    }
    
    if ($Direction -eq "from-n8n" -or $Direction -eq "both") {
        Sync-WorkflowsFromN8n -WorkflowsPath $workflowsPath
    }
}

Write-Host "`nSynchronisation terminée." -ForegroundColor Green

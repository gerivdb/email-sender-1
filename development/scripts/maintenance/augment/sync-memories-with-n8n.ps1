<#
.SYNOPSIS
    Synchronise les Memories d'Augment avec n8n.

.DESCRIPTION
    Ce script synchronise les Memories d'Augment avec n8n, permettant d'utiliser
    les workflows n8n pour gérer et enrichir les Memories.

.PARAMETER N8nUrl
    URL de l'API n8n. Par défaut : "http://localhost:5678/api/v1".

.PARAMETER MemoriesPath
    Chemin vers le fichier des Memories. Par défaut : ".augment\memories\journal_memories.json".

.PARAMETER WorkflowName
    Nom du workflow n8n à utiliser. Par défaut : "augment-memories-sync".

.EXAMPLE
    .\sync-memories-with-n8n.ps1
    # Synchronise les Memories avec n8n en utilisant les paramètres par défaut

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param (
    [Parameter()]
    [string]$N8nUrl = "http://localhost:5678/api/v1",
    
    [Parameter()]
    [string]$MemoriesPath = ".augment\memories\journal_memories.json",
    
    [Parameter()]
    [string]$WorkflowName = "augment-memories-sync"
)

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Chemin complet vers le fichier des Memories
$memoriesPath = Join-Path -Path $projectRoot -ChildPath $MemoriesPath

# Vérifier si le fichier des Memories existe
if (-not (Test-Path -Path $memoriesPath)) {
    Write-Error "Fichier des Memories introuvable : $memoriesPath"
    exit 1
}

# Fonction pour obtenir l'ID du workflow par son nom
function Get-WorkflowId {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$N8nUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$WorkflowName
    )
    
    try {
        $response = Invoke-RestMethod -Uri "$N8nUrl/workflows" -Method Get
        $workflow = $response.data | Where-Object { $_.name -eq $WorkflowName }
        
        if ($workflow) {
            return $workflow.id
        } else {
            return $null
        }
    } catch {
        Write-Error "Erreur lors de la récupération du workflow : $_"
        return $null
    }
}

# Fonction pour exécuter un workflow
function Invoke-Workflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$N8nUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        
        [Parameter(Mandatory = $true)]
        [object]$Data
    )
    
    try {
        $body = @{
            data = $Data
        } | ConvertTo-Json -Depth 10
        
        $response = Invoke-RestMethod -Uri "$N8nUrl/workflows/$WorkflowId/execute" -Method Post -Body $body -ContentType "application/json"
        return $response
    } catch {
        Write-Error "Erreur lors de l'exécution du workflow : $_"
        return $null
    }
}

# Fonction pour vérifier si n8n est en cours d'exécution
function Test-N8nConnection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$N8nUrl
    )
    
    try {
        $response = Invoke-RestMethod -Uri "$N8nUrl/health" -Method Get -TimeoutSec 5
        return $true
    } catch {
        return $false
    }
}

# Vérifier si n8n est en cours d'exécution
Write-Host "Vérification de la connexion à n8n..." -ForegroundColor Cyan
if (-not (Test-N8nConnection -N8nUrl $N8nUrl)) {
    Write-Error "Impossible de se connecter à n8n. Assurez-vous que n8n est en cours d'exécution sur $N8nUrl."
    exit 1
}

# Obtenir l'ID du workflow
Write-Host "Recherche du workflow '$WorkflowName'..." -ForegroundColor Cyan
$workflowId = Get-WorkflowId -N8nUrl $N8nUrl -WorkflowName $WorkflowName
if (-not $workflowId) {
    Write-Error "Workflow '$WorkflowName' introuvable."
    exit 1
}

# Lire le fichier des Memories
Write-Host "Lecture du fichier des Memories : $memoriesPath" -ForegroundColor Cyan
try {
    $memories = Get-Content -Path $memoriesPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors de la lecture du fichier des Memories : $_"
    exit 1
}

# Exécuter le workflow
Write-Host "Exécution du workflow '$WorkflowName'..." -ForegroundColor Cyan
$result = Invoke-Workflow -N8nUrl $N8nUrl -WorkflowId $workflowId -Data $memories
if (-not $result) {
    Write-Error "Erreur lors de l'exécution du workflow."
    exit 1
}

# Vérifier si le workflow a retourné des Memories mises à jour
if ($result.data -and $result.data.memories) {
    # Sauvegarder les Memories mises à jour
    Write-Host "Sauvegarde des Memories mises à jour..." -ForegroundColor Cyan
    $result.data.memories | ConvertTo-Json -Depth 10 | Out-File -FilePath $memoriesPath -Encoding UTF8
    Write-Host "Memories mises à jour avec succès." -ForegroundColor Green
} else {
    Write-Warning "Le workflow n'a pas retourné de Memories mises à jour."
}

# Afficher un résumé
Write-Host "`nRésumé de la synchronisation :" -ForegroundColor Green
Write-Host "Workflow : $WorkflowName (ID: $workflowId)" -ForegroundColor Gray
Write-Host "Fichier des Memories : $memoriesPath" -ForegroundColor Gray
Write-Host "Statut de l'exécution : $($result.status)" -ForegroundColor Gray
if ($result.data -and $result.data.sections) {
    Write-Host "Nombre de sections : $($result.data.sections.Count)" -ForegroundColor Gray
}
Write-Host "`nSynchronisation terminée." -ForegroundColor Green

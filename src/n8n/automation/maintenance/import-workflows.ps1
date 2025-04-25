<#
.SYNOPSIS
    Script pour importer les workflows dans n8n.

.DESCRIPTION
    Ce script importe les workflows depuis les fichiers JSON vers n8n.

.PARAMETER Environment
    Environnement à importer: "local", "ide" ou "all".

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

param (
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

# Fonction pour importer les workflows dans n8n
function Import-Workflows {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowsPath
    )

    Write-Host "Importation des workflows depuis: $WorkflowsPath" -ForegroundColor Cyan

    # Vérifier si le dossier des workflows existe
    if (-not (Test-Path -Path $WorkflowsPath)) {
        Write-Error "Le dossier des workflows n'existe pas: $WorkflowsPath"
        return
    }

    # Obtenir la liste des fichiers de workflow
    $workflowFiles = Get-ChildItem -Path $WorkflowsPath -Filter "*.json" -File

    if ($workflowFiles.Count -eq 0) {
        Write-Host "Aucun workflow à importer dans $WorkflowsPath." -ForegroundColor Yellow
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

            $response = Invoke-RestMethod -Uri "$n8nUrl/api/v1/workflows/import" -Method Post -Headers $headers -Body $workflowJson
            Write-Host "  Workflow importé avec succès: $($response.name) (ID: $($response.id))" -ForegroundColor Green
        } catch {
            Write-Host "  Erreur lors de l'importation du workflow $($file.Name): $_" -ForegroundColor Red
        }
    }
}

# Vérifier si n8n est en cours d'exécution
try {
    $health = Invoke-RestMethod -Uri "$n8nUrl/healthz" -Method Get -ErrorAction Stop
    Write-Host "n8n est en cours d'exécution. Statut: $($health.status)" -ForegroundColor Green
} catch {
    Write-Host "n8n n'est pas en cours d'exécution ou n'est pas accessible." -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
    exit 1
}

# Importer les workflows
foreach ($workflowsPath in $workflowsPaths) {
    Import-Workflows -WorkflowsPath $workflowsPath
}

Write-Host "`nImportation terminée." -ForegroundColor Green

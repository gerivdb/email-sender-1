<#
.SYNOPSIS
    Script d'intégration entre n8n et Augment.

.DESCRIPTION
    Ce script facilite l'intégration entre n8n et Augment en permettant à Augment
    de créer et de modifier des workflows n8n directement depuis l'IDE.

.PARAMETER Action
    Action à effectuer : "create-workflow", "update-workflow", "list-workflows", "get-workflow".

.PARAMETER WorkflowName
    Nom du workflow à créer ou à mettre à jour.

.PARAMETER WorkflowId
    ID du workflow à récupérer ou à mettre à jour.

.PARAMETER WorkflowData
    Données du workflow au format JSON.

.PARAMETER OutputPath
    Chemin où enregistrer la sortie.

.EXAMPLE
    .\augment-integration.ps1 -Action "list-workflows"
    .\augment-integration.ps1 -Action "create-workflow" -WorkflowName "Mon workflow" -WorkflowData '{"nodes":[],"connections":{}}'
    .\augment-integration.ps1 -Action "update-workflow" -WorkflowId "123" -WorkflowData '{"nodes":[],"connections":{}}'
    .\augment-integration.ps1 -Action "get-workflow" -WorkflowId "123" -OutputPath "workflow.json"
#>

param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("create-workflow", "update-workflow", "list-workflows", "get-workflow")]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [string]$WorkflowName,
    
    [Parameter(Mandatory = $false)]
    [string]$WorkflowId,
    
    [Parameter(Mandatory = $false)]
    [string]$WorkflowData,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

# Importer les modules nécessaires
$rootPath = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
$utilsPath = Join-Path -Path $rootPath -ChildPath "scripts\utils"
$n8nApiPath = Join-Path -Path $utilsPath -ChildPath "n8n-api.ps1"
$workflowUtilsPath = Join-Path -Path $utilsPath -ChildPath "workflow-utils.ps1"

# Vérifier si les modules existent
if (-not (Test-Path -Path $n8nApiPath)) {
    Write-Error "Le module n8n-api.ps1 n'existe pas."
    exit 1
}

if (-not (Test-Path -Path $workflowUtilsPath)) {
    Write-Error "Le module workflow-utils.ps1 n'existe pas."
    exit 1
}

# Importer les modules
. $n8nApiPath
. $workflowUtilsPath

# Charger la configuration
$configPath = Join-Path -Path $rootPath -ChildPath "config\n8n-config.json"
if (-not (Test-Path -Path $configPath)) {
    Write-Error "Le fichier de configuration n8n-config.json n'existe pas."
    exit 1
}

$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
$port = $config.port

# Charger le jeton d'API si disponible
$apiKey = $null
$apiKeyPath = Join-Path -Path $rootPath -ChildPath "config\api-key.json"
if (Test-Path -Path $apiKeyPath) {
    $apiKeyObject = Get-Content -Path $apiKeyPath -Raw | ConvertFrom-Json
    $apiKey = $apiKeyObject.apiKey
}

# Vérifier si n8n est en cours d'exécution
if (-not (Test-N8nRunning -Port $port)) {
    Write-Error "n8n n'est pas en cours d'exécution. Veuillez démarrer n8n avant d'utiliser ce script."
    exit 1
}

# Exécuter l'action demandée
switch ($Action) {
    "list-workflows" {
        $workflows = Get-N8nWorkflows -Port $port -ApiKey $apiKey
        
        if ($workflows) {
            if ($OutputPath) {
                $workflows | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
                Write-Host "Liste des workflows enregistrée dans $OutputPath."
            } else {
                $workflows | ConvertTo-Json -Depth 10
            }
        } else {
            Write-Error "Aucun workflow trouvé."
            exit 1
        }
    }
    
    "get-workflow" {
        if (-not $WorkflowId) {
            Write-Error "L'ID du workflow est requis pour l'action 'get-workflow'."
            exit 1
        }
        
        $workflow = Get-N8nWorkflow -WorkflowId $WorkflowId -Port $port -ApiKey $apiKey
        
        if ($workflow) {
            if ($OutputPath) {
                $workflow | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
                Write-Host "Workflow enregistré dans $OutputPath."
            } else {
                $workflow | ConvertTo-Json -Depth 10
            }
        } else {
            Write-Error "Workflow non trouvé."
            exit 1
        }
    }
    
    "create-workflow" {
        if (-not $WorkflowName) {
            Write-Error "Le nom du workflow est requis pour l'action 'create-workflow'."
            exit 1
        }
        
        if (-not $WorkflowData) {
            Write-Error "Les données du workflow sont requises pour l'action 'create-workflow'."
            exit 1
        }
        
        try {
            $workflowObject = $WorkflowData | ConvertFrom-Json
            
            # Ajouter les propriétés nécessaires
            $workflowObject | Add-Member -MemberType NoteProperty -Name "name" -Value $WorkflowName -Force
            $workflowObject | Add-Member -MemberType NoteProperty -Name "active" -Value $false -Force
            
            # Ajouter un tag pour identifier les workflows créés par Augment
            $tags = @(
                @{
                    "name" = "augment"
                },
                @{
                    "name" = "ide"
                }
            )
            $workflowObject | Add-Member -MemberType NoteProperty -Name "tags" -Value $tags -Force
            
            # Créer le workflow
            $newWorkflow = New-N8nWorkflow -Workflow $workflowObject -Port $port -ApiKey $apiKey
            
            if ($newWorkflow) {
                if ($OutputPath) {
                    $newWorkflow | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Host "Nouveau workflow enregistré dans $OutputPath."
                } else {
                    $newWorkflow | ConvertTo-Json -Depth 10
                }
            } else {
                Write-Error "Erreur lors de la création du workflow."
                exit 1
            }
        } catch {
            Write-Error "Erreur lors de la création du workflow : $_"
            exit 1
        }
    }
    
    "update-workflow" {
        if (-not $WorkflowId) {
            Write-Error "L'ID du workflow est requis pour l'action 'update-workflow'."
            exit 1
        }
        
        if (-not $WorkflowData) {
            Write-Error "Les données du workflow sont requises pour l'action 'update-workflow'."
            exit 1
        }
        
        try {
            # Récupérer le workflow existant
            $existingWorkflow = Get-N8nWorkflow -WorkflowId $WorkflowId -Port $port -ApiKey $apiKey
            
            if (-not $existingWorkflow) {
                Write-Error "Workflow non trouvé."
                exit 1
            }
            
            # Fusionner les données
            $workflowObject = $WorkflowData | ConvertFrom-Json
            
            # Conserver les propriétés importantes
            $workflowObject | Add-Member -MemberType NoteProperty -Name "id" -Value $existingWorkflow.id -Force
            $workflowObject | Add-Member -MemberType NoteProperty -Name "name" -Value $existingWorkflow.name -Force
            $workflowObject | Add-Member -MemberType NoteProperty -Name "active" -Value $existingWorkflow.active -Force
            
            # Mettre à jour le workflow
            $updatedWorkflow = Update-N8nWorkflow -WorkflowId $WorkflowId -Workflow $workflowObject -Port $port -ApiKey $apiKey
            
            if ($updatedWorkflow) {
                if ($OutputPath) {
                    $updatedWorkflow | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
                    Write-Host "Workflow mis à jour enregistré dans $OutputPath."
                } else {
                    $updatedWorkflow | ConvertTo-Json -Depth 10
                }
            } else {
                Write-Error "Erreur lors de la mise à jour du workflow."
                exit 1
            }
        } catch {
            Write-Error "Erreur lors de la mise à jour du workflow : $_"
            exit 1
        }
    }
}

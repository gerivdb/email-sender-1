<#
.SYNOPSIS
    Utilitaires pour interagir avec l'API n8n.

.DESCRIPTION
    Ce script contient des fonctions pour interagir avec l'API n8n.
    Il est utilisé par les scripts de synchronisation.
#>

# Fonction pour vérifier si n8n est en cours d'exécution
function Test-N8nRunning {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter(Mandatory = $false)]
        [string]$Hostname = "localhost"
    )
    
    try {
        $response = Invoke-WebRequest -Uri "http://$Hostname:$Port/healthz" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
        return ($response.StatusCode -eq 200)
    } catch {
        return $false
    }
}

# Fonction pour obtenir tous les workflows depuis n8n
function Get-N8nWorkflows {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter(Mandatory = $false)]
        [string]$Hostname = "localhost",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = $null
    )
    
    $uri = "http://$Hostname:$Port/rest/workflows"
    $headers = @{}
    
    if ($ApiKey) {
        $headers.Add("X-N8N-API-KEY", $ApiKey)
    }
    
    try {
        $workflows = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
        return $workflows
    } catch {
        Write-Error "Erreur lors de la récupération des workflows depuis n8n : $_"
        return $null
    }
}

# Fonction pour obtenir un workflow spécifique depuis n8n
function Get-N8nWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter(Mandatory = $false)]
        [string]$Hostname = "localhost",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = $null
    )
    
    $uri = "http://$Hostname:$Port/rest/workflows/$WorkflowId"
    $headers = @{}
    
    if ($ApiKey) {
        $headers.Add("X-N8N-API-KEY", $ApiKey)
    }
    
    try {
        $workflow = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers -ErrorAction Stop
        return $workflow
    } catch {
        Write-Error "Erreur lors de la récupération du workflow $WorkflowId depuis n8n : $_"
        return $null
    }
}

# Fonction pour créer un workflow dans n8n
function New-N8nWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Workflow,
        
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter(Mandatory = $false)]
        [string]$Hostname = "localhost",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = $null
    )
    
    $uri = "http://$Hostname:$Port/rest/workflows"
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ($ApiKey) {
        $headers.Add("X-N8N-API-KEY", $ApiKey)
    }
    
    $body = $Workflow | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ErrorAction Stop
        return $response
    } catch {
        Write-Error "Erreur lors de la création du workflow dans n8n : $_"
        return $null
    }
}

# Fonction pour mettre à jour un workflow dans n8n
function Update-N8nWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Workflow,
        
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter(Mandatory = $false)]
        [string]$Hostname = "localhost",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = $null
    )
    
    $uri = "http://$Hostname:$Port/rest/workflows/$WorkflowId"
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ($ApiKey) {
        $headers.Add("X-N8N-API-KEY", $ApiKey)
    }
    
    $body = $Workflow | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Put -Headers $headers -Body $body -ErrorAction Stop
        return $response
    } catch {
        Write-Error "Erreur lors de la mise à jour du workflow $WorkflowId dans n8n : $_"
        return $null
    }
}

# Fonction pour supprimer un workflow dans n8n
function Remove-N8nWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter(Mandatory = $false)]
        [string]$Hostname = "localhost",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = $null
    )
    
    $uri = "http://$Hostname:$Port/rest/workflows/$WorkflowId"
    $headers = @{}
    
    if ($ApiKey) {
        $headers.Add("X-N8N-API-KEY", $ApiKey)
    }
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Delete -Headers $headers -ErrorAction Stop
        return $response
    } catch {
        Write-Error "Erreur lors de la suppression du workflow $WorkflowId dans n8n : $_"
        return $null
    }
}

# Fonction pour activer un workflow dans n8n
function Enable-N8nWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter(Mandatory = $false)]
        [string]$Hostname = "localhost",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = $null
    )
    
    $uri = "http://$Hostname:$Port/rest/workflows/$WorkflowId/activate"
    $headers = @{}
    
    if ($ApiKey) {
        $headers.Add("X-N8N-API-KEY", $ApiKey)
    }
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -ErrorAction Stop
        return $response
    } catch {
        Write-Error "Erreur lors de l'activation du workflow $WorkflowId dans n8n : $_"
        return $null
    }
}

# Fonction pour désactiver un workflow dans n8n
function Disable-N8nWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter(Mandatory = $false)]
        [string]$Hostname = "localhost",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = $null
    )
    
    $uri = "http://$Hostname:$Port/rest/workflows/$WorkflowId/deactivate"
    $headers = @{}
    
    if ($ApiKey) {
        $headers.Add("X-N8N-API-KEY", $ApiKey)
    }
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -ErrorAction Stop
        return $response
    } catch {
        Write-Error "Erreur lors de la désactivation du workflow $WorkflowId dans n8n : $_"
        return $null
    }
}

# Fonction pour exécuter un workflow dans n8n
function Invoke-N8nWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Data = $null,
        
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter(Mandatory = $false)]
        [string]$Hostname = "localhost",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = $null
    )
    
    $uri = "http://$Hostname:$Port/rest/workflows/$WorkflowId/execute"
    $headers = @{
        "Content-Type" = "application/json"
    }
    
    if ($ApiKey) {
        $headers.Add("X-N8N-API-KEY", $ApiKey)
    }
    
    $body = $null
    if ($Data) {
        $body = $Data | ConvertTo-Json -Depth 10
    } else {
        $body = "{}"
    }
    
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ErrorAction Stop
        return $response
    } catch {
        Write-Error "Erreur lors de l'exécution du workflow $WorkflowId dans n8n : $_"
        return $null
    }
}

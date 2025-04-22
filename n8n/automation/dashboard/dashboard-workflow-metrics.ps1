<#
.SYNOPSIS
    Collecte les métriques liées aux workflows n8n.

.DESCRIPTION
    Ce script collecte les métriques liées aux workflows n8n, comme le nombre total de workflows,
    le nombre de workflows actifs, inactifs et avec des erreurs.

.PARAMETER DefaultPort
    Port par défaut utilisé par n8n.

.PARAMETER DefaultProtocol
    Protocole par défaut utilisé par n8n (http ou https).

.PARAMETER DefaultHostname
    Nom d'hôte par défaut utilisé par n8n.

.PARAMETER WorkflowFolder
    Dossier contenant les workflows n8n.

.PARAMETER MetricsConfig
    Configuration des métriques à collecter.

.EXAMPLE
    .\dashboard-workflow-metrics.ps1 -DefaultPort 5678 -DefaultProtocol "http" -DefaultHostname "localhost" -WorkflowFolder "n8n/data/.n8n/workflows"

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  26/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [int]$DefaultPort = 5678,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("http", "https")]
    [string]$DefaultProtocol = "http",
    
    [Parameter(Mandatory=$false)]
    [string]$DefaultHostname = "localhost",
    
    [Parameter(Mandatory=$false)]
    [string]$WorkflowFolder = "n8n/data/.n8n/workflows",
    
    [Parameter(Mandatory=$false)]
    [object]$MetricsConfig = $null
)

# Fonction pour obtenir les workflows via l'API n8n
function Get-WorkflowsViaApi {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Protocol,
        
        [Parameter(Mandatory=$true)]
        [string]$Hostname,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 5000
    )
    
    $url = "${Protocol}://${Hostname}:${Port}/rest/workflows"
    
    try {
        $response = Invoke-WebRequest -Uri $url -TimeoutSec ($Timeout / 1000) -UseBasicParsing
        $workflows = $response.Content | ConvertFrom-Json
        
        return @{
            Success = $true
            Workflows = $workflows
            Error = $null
        }
    } catch {
        return @{
            Success = $false
            Workflows = @()
            Error = $_.Exception.Message
        }
    }
}

# Fonction pour obtenir les workflows à partir des fichiers
function Get-WorkflowsFromFiles {
    param (
        [Parameter(Mandatory=$true)]
        [string]$WorkflowFolder
    )
    
    if (-not (Test-Path -Path $WorkflowFolder)) {
        return @{
            Success = $false
            Workflows = @()
            Error = "Dossier de workflows non trouvé: $WorkflowFolder"
        }
    }
    
    try {
        $workflowFiles = Get-ChildItem -Path $WorkflowFolder -Filter "*.json" -File
        $workflows = @()
        
        foreach ($file in $workflowFiles) {
            try {
                $content = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                
                $workflow = @{
                    id = if ($content.id) { $content.id } else { [System.IO.Path]::GetFileNameWithoutExtension($file.Name) }
                    name = if ($content.name) { $content.name } else { [System.IO.Path]::GetFileNameWithoutExtension($file.Name) }
                    active = if ($content.active -ne $null) { $content.active } else { $false }
                    createdAt = if ($content.createdAt) { $content.createdAt } else { $file.CreationTime }
                    updatedAt = if ($content.updatedAt) { $content.updatedAt } else { $file.LastWriteTime }
                    fileName = $file.Name
                }
                
                $workflows += $workflow
            } catch {
                # Ignorer les fichiers invalides
            }
        }
        
        return @{
            Success = $true
            Workflows = $workflows
            Error = $null
        }
    } catch {
        return @{
            Success = $false
            Workflows = @()
            Error = $_.Exception.Message
        }
    }
}

# Fonction principale pour collecter les métriques des workflows
function Get-WorkflowMetrics {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Protocol,
        
        [Parameter(Mandatory=$true)]
        [string]$Hostname,
        
        [Parameter(Mandatory=$true)]
        [int]$Port,
        
        [Parameter(Mandatory=$true)]
        [string]$WorkflowFolder,
        
        [Parameter(Mandatory=$false)]
        [object]$MetricsConfig = $null
    )
    
    # Essayer d'obtenir les workflows via l'API
    $apiResult = Get-WorkflowsViaApi -Protocol $Protocol -Hostname $Hostname -Port $Port
    
    # Si l'API échoue, essayer d'obtenir les workflows à partir des fichiers
    if (-not $apiResult.Success) {
        $fileResult = Get-WorkflowsFromFiles -WorkflowFolder $WorkflowFolder
        
        if (-not $fileResult.Success) {
            # Les deux méthodes ont échoué
            return @{
                Metrics = @{
                    TotalWorkflows = @{
                        Value = 0
                        DisplayValue = "0"
                        Status = "danger"
                        Description = "Nombre total de workflows"
                        Details = "Impossible d'obtenir les workflows: $($apiResult.Error), $($fileResult.Error)"
                    }
                    ActiveWorkflows = @{
                        Value = 0
                        DisplayValue = "0"
                        Status = "danger"
                        Description = "Nombre de workflows actifs"
                        Details = "Impossible d'obtenir les workflows: $($apiResult.Error), $($fileResult.Error)"
                    }
                    InactiveWorkflows = @{
                        Value = 0
                        DisplayValue = "0"
                        Status = "danger"
                        Description = "Nombre de workflows inactifs"
                        Details = "Impossible d'obtenir les workflows: $($apiResult.Error), $($fileResult.Error)"
                    }
                    WorkflowsWithErrors = @{
                        Value = 0
                        DisplayValue = "0"
                        Status = "danger"
                        Description = "Nombre de workflows avec des erreurs"
                        Details = "Impossible d'obtenir les workflows: $($apiResult.Error), $($fileResult.Error)"
                    }
                }
                Workflows = @()
                Source = "none"
                CollectedAt = Get-Date
            }
        }
        
        # Utiliser les workflows des fichiers
        $workflows = $fileResult.Workflows
        $source = "files"
    } else {
        # Utiliser les workflows de l'API
        $workflows = $apiResult.Workflows
        $source = "api"
    }
    
    # Calculer les métriques
    $totalWorkflows = $workflows.Count
    $activeWorkflows = ($workflows | Where-Object { $_.active -eq $true }).Count
    $inactiveWorkflows = $totalWorkflows - $activeWorkflows
    
    # Pour les erreurs, nous ne pouvons pas les détecter à partir des fichiers
    # Nous supposons qu'il n'y a pas d'erreurs si nous utilisons les fichiers
    $workflowsWithErrors = if ($source -eq "api") {
        ($workflows | Where-Object { $_.active -eq $true -and $_.status -eq "error" }).Count
    } else {
        0
    }
    
    # Préparer les métriques
    $metrics = @{
        TotalWorkflows = @{
            Value = $totalWorkflows
            DisplayValue = $totalWorkflows.ToString()
            Status = if ($totalWorkflows -gt 0) { "success" } else { "warning" }
            Description = "Nombre total de workflows"
            Details = "Source: $source"
        }
        ActiveWorkflows = @{
            Value = $activeWorkflows
            DisplayValue = $activeWorkflows.ToString()
            Status = if ($activeWorkflows -gt 0) { "success" } else { "warning" }
            Description = "Nombre de workflows actifs"
            Details = "Source: $source"
        }
        InactiveWorkflows = @{
            Value = $inactiveWorkflows
            DisplayValue = $inactiveWorkflows.ToString()
            Status = "info"
            Description = "Nombre de workflows inactifs"
            Details = "Source: $source"
        }
        WorkflowsWithErrors = @{
            Value = $workflowsWithErrors
            DisplayValue = $workflowsWithErrors.ToString()
            Status = if ($workflowsWithErrors -eq 0) { "success" } else { "danger" }
            Description = "Nombre de workflows avec des erreurs"
            Details = "Source: $source"
        }
    }
    
    # Retourner les métriques
    return @{
        Metrics = $metrics
        Workflows = $workflows
        Source = $source
        CollectedAt = Get-Date
    }
}

# Si le script est exécuté directement, collecter et retourner les métriques
if ($MyInvocation.InvocationName -ne ".") {
    Get-WorkflowMetrics -Protocol $DefaultProtocol -Hostname $DefaultHostname -Port $DefaultPort -WorkflowFolder $WorkflowFolder -MetricsConfig $MetricsConfig
}

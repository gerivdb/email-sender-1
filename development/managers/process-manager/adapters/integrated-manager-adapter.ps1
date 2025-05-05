<#
.SYNOPSIS
    Adaptateur pour l'Integrated Manager.

.DESCRIPTION
    Cet adaptateur permet d'intÃ©grer l'Integrated Manager avec le Process Manager.
    Il fournit une interface standardisÃ©e pour interagir avec l'Integrated Manager.

.PARAMETER Command
    La commande Ã  exÃ©cuter. Les commandes disponibles sont :
    - ExecuteWorkflow : ExÃ©cute un workflow intÃ©grÃ©
    - GetStatus : Obtient le statut d'un workflow
    - ListWorkflows : Liste tous les workflows disponibles
    - GetWorkflowInfo : Obtient des informations sur un workflow spÃ©cifique

.PARAMETER WorkflowName
    Le nom du workflow Ã  utiliser pour la commande.

.PARAMETER Parameters
    Les paramÃ¨tres supplÃ©mentaires Ã  passer Ã  la commande.

.EXAMPLE
    .\integrated-manager-adapter.ps1 -Command ListWorkflows
    Liste tous les workflows disponibles.

.EXAMPLE
    .\integrated-manager-adapter.ps1 -Command ExecuteWorkflow -WorkflowName "ProcessEmail"
    ExÃ©cute le workflow "ProcessEmail".

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-03
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("ExecuteWorkflow", "GetStatus", "ListWorkflows", "GetWorkflowInfo")]
    [string]$Command,

    [Parameter(Mandatory = $false)]
    [string]$WorkflowName,

    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{}
)

# DÃ©finir le chemin vers l'Integrated Manager
$integratedManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) -ChildPath "integrated-manager\scripts\integrated-manager.ps1"

# VÃ©rifier que l'Integrated Manager existe
if (-not (Test-Path -Path $integratedManagerPath)) {
    Write-Error "L'Integrated Manager est introuvable Ã  l'emplacement : $integratedManagerPath"
    exit 1
}

# Fonction pour exÃ©cuter une commande sur l'Integrated Manager
function Invoke-IntegratedManagerCommand {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    # Construire la commande
    $commandParams = @{
        FilePath = $integratedManagerPath
        ArgumentList = "-Command $Command"
    }

    # Ajouter les paramÃ¨tres
    foreach ($param in $Parameters.Keys) {
        $value = $Parameters[$param]
        
        # GÃ©rer les types de paramÃ¨tres
        if ($value -is [switch]) {
            if ($value) {
                $commandParams.ArgumentList += " -$param"
            }
        } elseif ($value -is [array]) {
            $valueStr = $value -join ","
            $commandParams.ArgumentList += " -$param '$valueStr'"
        } else {
            $commandParams.ArgumentList += " -$param '$value'"
        }
    }

    # ExÃ©cuter la commande
    if ($PSCmdlet.ShouldProcess("Integrated Manager", "ExÃ©cuter la commande $Command")) {
        try {
            $result = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $($commandParams.FilePath) $($commandParams.ArgumentList)" -Wait -PassThru -NoNewWindow
            
            if ($result.ExitCode -eq 0) {
                return $true
            } else {
                Write-Error "Erreur lors de l'exÃ©cution de la commande. Code de sortie : $($result.ExitCode)"
                return $false
            }
        } catch {
            Write-Error "Erreur lors de l'exÃ©cution de la commande : $_"
            return $false
        }
    }

    return $false
}

# ExÃ©cuter la commande spÃ©cifiÃ©e
switch ($Command) {
    "ExecuteWorkflow" {
        # VÃ©rifier que le nom du workflow est spÃ©cifiÃ©
        if (-not $WorkflowName) {
            Write-Error "Le paramÃ¨tre WorkflowName est requis pour la commande ExecuteWorkflow."
            exit 1
        }
        
        # ExÃ©cuter le workflow
        $params = @{
            WorkflowName = $WorkflowName
        }
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-IntegratedManagerCommand -Command "ExecuteWorkflow" -Parameters $params
        return $result
    }
    
    "GetStatus" {
        # VÃ©rifier que le nom du workflow est spÃ©cifiÃ©
        if (-not $WorkflowName) {
            Write-Error "Le paramÃ¨tre WorkflowName est requis pour la commande GetStatus."
            exit 1
        }
        
        # Obtenir le statut du workflow
        $params = @{
            WorkflowName = $WorkflowName
        }
        
        $result = Invoke-IntegratedManagerCommand -Command "GetStatus" -Parameters $params
        return $result
    }
    
    "ListWorkflows" {
        # Lister tous les workflows disponibles
        $result = Invoke-IntegratedManagerCommand -Command "ListWorkflows"
        return $result
    }
    
    "GetWorkflowInfo" {
        # VÃ©rifier que le nom du workflow est spÃ©cifiÃ©
        if (-not $WorkflowName) {
            Write-Error "Le paramÃ¨tre WorkflowName est requis pour la commande GetWorkflowInfo."
            exit 1
        }
        
        # Obtenir des informations sur le workflow
        $params = @{
            WorkflowName = $WorkflowName
        }
        
        $result = Invoke-IntegratedManagerCommand -Command "GetWorkflowInfo" -Parameters $params
        return $result
    }
}

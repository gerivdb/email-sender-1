<#
.SYNOPSIS
    Script pour exécuter un workflow n8n.

.DESCRIPTION
    Ce script exécute un workflow n8n existant avec les données spécifiées.

.PARAMETER WorkflowId
    ID du workflow à exécuter.

.PARAMETER Data
    Données à passer au workflow.

.PARAMETER DataFile
    Fichier JSON contenant les données à passer au workflow.

.EXAMPLE
    .\execute-workflow.ps1 -WorkflowId "123456" -Data @{ "param1" = "valeur1" }

.EXAMPLE
    .\execute-workflow.ps1 -WorkflowId "123456" -DataFile "data.json"
#>

#Requires -Version 5.1

# Paramètres
param (
    [Parameter(Mandatory = $true)]
    [string]$WorkflowId,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Data,
    
    [Parameter(Mandatory = $false)]
    [string]$DataFile
)

# Variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ModuleFile = Join-Path -Path $ScriptPath -ChildPath "IdeN8nIntegration.ps1"

# Importer le module
if (-not (Test-Path -Path $ModuleFile)) {
    Write-Error "Le fichier module IdeN8nIntegration.ps1 n'existe pas."
    exit 1
}

Import-Module $ModuleFile -Force

# Charger les données depuis le fichier si spécifié
if (-not [string]::IsNullOrEmpty($DataFile)) {
    if (Test-Path -Path $DataFile) {
        $Data = Get-Content -Path $DataFile -Raw | ConvertFrom-Json -AsHashtable
    }
    else {
        Write-Error "Le fichier de données $DataFile n'existe pas."
        exit 1
    }
}

# Exécuter le workflow
try {
    $Execution = Invoke-N8nWorkflow -WorkflowId $WorkflowId -Data $Data
    
    if ($Execution) {
        Write-Host "Workflow exécuté avec succès :" -ForegroundColor Green
        Write-Host "  - ID d'exécution : $($Execution.id)" -ForegroundColor White
        Write-Host "  - Statut : $($Execution.status)" -ForegroundColor White
        
        # Afficher les résultats
        if ($Execution.data) {
            Write-Host "  - Résultats :" -ForegroundColor White
            $Execution.data | ConvertTo-Json -Depth 10 | Write-Host
        }
    }
    else {
        Write-Host "Erreur lors de l'exécution du workflow." -ForegroundColor Red
    }
}
catch {
    Write-Host "Erreur lors de l'exécution du workflow : $_" -ForegroundColor Red
}

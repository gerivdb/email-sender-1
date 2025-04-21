<#
.SYNOPSIS
    Script d'intégration entre n8n et Augment.

.DESCRIPTION
    Ce script fournit des fonctions pour intégrer n8n avec Augment, permettant
    de créer, exécuter et gérer des workflows n8n depuis Augment.

.NOTES
    Nom du fichier : AugmentN8nIntegration.ps1
    Auteur : Augment Agent
    Date de création : 21/04/2025
    Version : 1.0
#>

#Requires -Version 5.1

# Paramètres globaux
param (
    [Parameter(Mandatory = $false)]
    [string]$N8nUrl = "http://localhost:5678",

    [Parameter(Mandatory = $false)]
    [string]$ApiKey = "",

    [Parameter(Mandatory = $false)]
    [switch]$EnableDebug
)

# Variables globales
$script:N8nBaseUrl = $N8nUrl
$script:N8nApiKey = $ApiKey
$script:LogFile = Join-Path -Path $PSScriptRoot -ChildPath "logs\augment-n8n-integration.log"
$script:ConfigFile = Join-Path -Path $PSScriptRoot -ChildPath "config\augment-n8n-config.json"

# Création des dossiers nécessaires
$LogDir = Split-Path -Path $script:LogFile -Parent
if (-not (Test-Path -Path $LogDir)) {
    New-Item -Path $LogDir -ItemType Directory -Force | Out-Null
}

$ConfigDir = Split-Path -Path $script:ConfigFile -Parent
if (-not (Test-Path -Path $ConfigDir)) {
    New-Item -Path $ConfigDir -ItemType Directory -Force | Out-Null
}

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )

    # Ne pas écrire les messages DEBUG si le mode debug n'est pas activé
    if ($Level -eq "DEBUG" -and -not $EnableDebug) {
        return
    }

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"

    # Écrire dans le fichier journal
    Add-Content -Path $script:LogFile -Value $LogMessage -Encoding UTF8

    # Afficher dans la console avec une couleur différente selon le niveau
    switch ($Level) {
        "INFO" { Write-Host $LogMessage -ForegroundColor White }
        "WARNING" { Write-Host $LogMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $LogMessage -ForegroundColor Red }
        "DEBUG" { Write-Host $LogMessage -ForegroundColor Gray }
    }
}

# Fonction pour charger la configuration
function Get-N8nConfig {
    [CmdletBinding()]
    param ()

    try {
        if (Test-Path -Path $script:ConfigFile) {
            $Config = Get-Content -Path $script:ConfigFile -Raw | ConvertFrom-Json
            Write-Log -Message "Configuration chargée avec succès" -Level DEBUG
            return $Config
        } else {
            # Créer une configuration par défaut
            $Config = @{
                N8nUrl    = $script:N8nBaseUrl
                ApiKey    = $script:N8nApiKey
                LastSync  = $null
                Workflows = @()
            }

            # Sauvegarder la configuration
            $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile -Encoding UTF8
            Write-Log -Message "Configuration par défaut créée" -Level INFO
            return $Config
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement de la configuration : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour sauvegarder la configuration
function Save-N8nConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile -Encoding UTF8
        Write-Log -Message "Configuration sauvegardée avec succès" -Level DEBUG
    } catch {
        Write-Log -Message "Erreur lors de la sauvegarde de la configuration : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour tester la connexion à n8n
function Test-N8nConnection {
    [CmdletBinding()]
    param ()

    try {
        $Config = Get-N8nConfig
        $Headers = @{
            "Accept" = "application/json"
        }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/healthz" -Method Get -Headers $Headers

        if ($Response.status -eq "ok") {
            Write-Log -Message "Connexion à n8n réussie" -Level INFO
            return $true
        } else {
            Write-Log -Message "Connexion à n8n échouée : $($Response.status)" -Level ERROR
            return $false
        }
    } catch {
        Write-Log -Message "Erreur lors de la connexion à n8n : $_" -Level ERROR
        return $false
    }
}

# Fonction pour récupérer les workflows n8n
function Get-N8nWorkflows {
    [CmdletBinding()]
    param ()

    try {
        $Config = Get-N8nConfig
        $Headers = @{
            "Accept" = "application/json"
        }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows" -Method Get -Headers $Headers

        Write-Log -Message "Récupération de $($Response.Count) workflows" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de la récupération des workflows : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour récupérer un workflow n8n par son ID
function Get-N8nWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId
    )

    try {
        $Config = Get-N8nConfig
        $Headers = @{
            "Accept" = "application/json"
        }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows/$WorkflowId" -Method Get -Headers $Headers

        Write-Log -Message "Récupération du workflow $WorkflowId réussie" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de la récupération du workflow $WorkflowId : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour exécuter un workflow n8n
function Invoke-N8nWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Data
    )

    try {
        $Config = Get-N8nConfig
        $Headers = @{
            "Accept"       = "application/json"
            "Content-Type" = "application/json"
        }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Body = $null
        if ($Data) {
            $Body = $Data | ConvertTo-Json -Depth 10
        }

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows/$WorkflowId/execute" -Method Post -Headers $Headers -Body $Body

        Write-Log -Message "Exécution du workflow $WorkflowId réussie" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de l'exécution du workflow $WorkflowId : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour créer un workflow n8n
function New-N8nWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Nodes,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Connections,

        [Parameter(Mandatory = $false)]
        [bool]$Active = $false
    )

    try {
        $Config = Get-N8nConfig
        $Headers = @{
            "Accept"       = "application/json"
            "Content-Type" = "application/json"
        }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        # Créer le workflow
        $Workflow = @{
            name        = $Name
            active      = $Active
            nodes       = $Nodes
            connections = $Connections
        }

        $Body = $Workflow | ConvertTo-Json -Depth 10

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows" -Method Post -Headers $Headers -Body $Body

        Write-Log -Message "Création du workflow $Name réussie (ID: $($Response.id))" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de la création du workflow $Name : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour mettre à jour un workflow n8n
function Update-N8nWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,

        [Parameter(Mandatory = $false)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Nodes,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Connections,

        [Parameter(Mandatory = $false)]
        [bool]$Active
    )

    try {
        $Config = Get-N8nConfig
        $Headers = @{
            "Accept"       = "application/json"
            "Content-Type" = "application/json"
        }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        # Récupérer le workflow existant
        $ExistingWorkflow = Get-N8nWorkflow -WorkflowId $WorkflowId

        # Mettre à jour les propriétés
        if ($Name) {
            $ExistingWorkflow.name = $Name
        }

        if ($Nodes) {
            $ExistingWorkflow.nodes = $Nodes
        }

        if ($Connections) {
            $ExistingWorkflow.connections = $Connections
        }

        if ($PSBoundParameters.ContainsKey('Active')) {
            $ExistingWorkflow.active = $Active
        }

        $Body = $ExistingWorkflow | ConvertTo-Json -Depth 10

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows/$WorkflowId" -Method Put -Headers $Headers -Body $Body

        Write-Log -Message "Mise à jour du workflow $WorkflowId réussie" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de la mise à jour du workflow $WorkflowId : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour supprimer un workflow n8n
function Remove-N8nWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId
    )

    try {
        $Config = Get-N8nConfig
        $Headers = @{
            "Accept" = "application/json"
        }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/workflows/$WorkflowId" -Method Delete -Headers $Headers

        Write-Log -Message "Suppression du workflow $WorkflowId réussie" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de la suppression du workflow $WorkflowId : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour récupérer les exécutions d'un workflow n8n
function Get-N8nWorkflowExecutions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId
    )

    try {
        $Config = Get-N8nConfig
        $Headers = @{
            "Accept" = "application/json"
        }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/executions?workflowId=$WorkflowId" -Method Get -Headers $Headers

        Write-Log -Message "Récupération des exécutions du workflow $WorkflowId réussie" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de la récupération des exécutions du workflow $WorkflowId : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour récupérer une exécution spécifique d'un workflow n8n
function Get-N8nExecution {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ExecutionId
    )

    try {
        $Config = Get-N8nConfig
        $Headers = @{
            "Accept" = "application/json"
        }

        if (-not [string]::IsNullOrEmpty($Config.ApiKey)) {
            $Headers["X-N8N-API-KEY"] = $Config.ApiKey
        }

        $Response = Invoke-RestMethod -Uri "$($Config.N8nUrl)/api/v1/executions/$ExecutionId" -Method Get -Headers $Headers

        Write-Log -Message "Récupération de l'exécution $ExecutionId réussie" -Level INFO
        return $Response
    } catch {
        Write-Log -Message "Erreur lors de la récupération de l'exécution $ExecutionId : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour synchroniser les workflows n8n avec Augment
function Sync-N8nWorkflowsWithAugment {
    [CmdletBinding()]
    param ()

    try {
        # Récupérer les workflows n8n
        $Workflows = Get-N8nWorkflows

        # Récupérer la configuration
        $Config = Get-N8nConfig

        # Mettre à jour la liste des workflows dans la configuration
        $Config.Workflows = $Workflows | Select-Object id, name, active, createdAt, updatedAt
        $Config.LastSync = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        # Sauvegarder la configuration
        Save-N8nConfig -Config $Config

        Write-Log -Message "Synchronisation des workflows avec Augment réussie" -Level INFO
        return $Config.Workflows
    } catch {
        Write-Log -Message "Erreur lors de la synchronisation des workflows avec Augment : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour créer un workflow n8n à partir d'une description Augment
function New-N8nWorkflowFromAugmentDescription {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Description
    )

    try {
        # Créer un workflow simple avec un nœud Schedule Trigger
        $Nodes = @(
            @{
                parameters  = @{
                    rule = @{
                        interval = @(
                            @{
                                field           = "hours"
                                minutesInterval = 1
                                hoursInterval   = 1
                            }
                        )
                    }
                }
                name        = "Schedule Trigger"
                type        = "n8n-nodes-base.scheduleTrigger"
                typeVersion = 1
                position    = @(250, 300)
            },
            @{
                parameters  = @{
                    keepOnlySet = $true
                    values      = @{
                        string = @(
                            @{
                                name  = "description"
                                value = $Description
                            }
                        )
                    }
                }
                name        = "Set Description"
                type        = "n8n-nodes-base.set"
                typeVersion = 1
                position    = @(450, 300)
            }
        )

        $Connections = @{
            Schedule_Trigger = @(
                @{
                    node  = "Set Description"
                    type  = "main"
                    index = 0
                }
            )
        }

        # Créer le workflow
        $Workflow = New-N8nWorkflow -Name $Name -Nodes $Nodes -Connections $Connections -Active $false

        Write-Log -Message "Création du workflow à partir de la description Augment réussie (ID: $($Workflow.id))" -Level INFO
        return $Workflow
    } catch {
        Write-Log -Message "Erreur lors de la création du workflow à partir de la description Augment : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour exporter les données n8n vers Augment Memories
function Export-N8nDataToAugmentMemories {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputFile = (Join-Path -Path $PSScriptRoot -ChildPath "memories\n8n_workflows.json")
    )

    try {
        # Récupérer les workflows n8n
        $Workflows = Get-N8nWorkflows

        # Créer le dossier de sortie s'il n'existe pas
        $OutputDir = Split-Path -Path $OutputFile -Parent
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }

        # Formater les données pour Augment Memories
        $Memories = $Workflows | ForEach-Object {
            @{
                id          = $_.id
                name        = $_.name
                active      = $_.active
                createdAt   = $_.createdAt
                updatedAt   = $_.updatedAt
                type        = "n8n_workflow"
                description = "Workflow n8n: $($_.name)"
                content     = "ID: $($_.id)`nNom: $($_.name)`nActif: $($_.active)`nCréé le: $($_.createdAt)`nMis à jour le: $($_.updatedAt)"
            }
        }

        # Sauvegarder les données
        $Memories | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputFile -Encoding UTF8

        Write-Log -Message "Exportation des données n8n vers Augment Memories réussie ($($Memories.Count) workflows)" -Level INFO
        return $Memories
    } catch {
        Write-Log -Message "Erreur lors de l'exportation des données n8n vers Augment Memories : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour importer des données Augment Memories vers n8n
function Import-AugmentMemoriesToN8n {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$InputFile = (Join-Path -Path $PSScriptRoot -ChildPath "memories\augment_memories.json")
    )

    try {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $InputFile)) {
            Write-Log -Message "Fichier d'entrée non trouvé : $InputFile" -Level ERROR
            return $false
        }

        # Charger les données
        $Memories = Get-Content -Path $InputFile -Raw | ConvertFrom-Json

        # Traiter les données
        $ProcessedMemories = 0
        foreach ($Memory in $Memories) {
            # Vérifier si la mémoire contient une description de workflow
            if ($Memory.content -match "workflow n8n" -or $Memory.content -match "automatisation" -or $Memory.content -match "n8n workflow") {
                $Name = "Workflow from Augment Memory: $($Memory.id)"
                $Description = $Memory.content

                # Créer un workflow à partir de la description
                $null = New-N8nWorkflowFromAugmentDescription -Name $Name -Description $Description

                $ProcessedMemories++
            }
        }

        Write-Log -Message "Importation des données Augment Memories vers n8n réussie ($ProcessedMemories mémoires traitées)" -Level INFO
        return $true
    } catch {
        Write-Log -Message "Erreur lors de l'importation des données Augment Memories vers n8n : $_" -Level ERROR
        throw $_
    }
}

# Fonction principale
function Start-AugmentN8nIntegration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Test", "Sync", "Export", "Import")]
        [string]$Action = "Test"
    )

    try {
        Write-Log -Message "Démarrage de l'intégration Augment-n8n (Action: $Action)" -Level INFO

        # Tester la connexion à n8n
        $Connected = Test-N8nConnection
        if (-not $Connected) {
            Write-Log -Message "Impossible de se connecter à n8n. Vérifiez que n8n est en cours d'exécution et accessible." -Level ERROR
            return $false
        }

        # Exécuter l'action demandée
        switch ($Action) {
            "Test" {
                # Récupérer les workflows n8n
                $Workflows = Get-N8nWorkflows
                Write-Log -Message "Test réussi. $($Workflows.Count) workflows trouvés." -Level INFO
                return $Workflows
            }
            "Sync" {
                # Synchroniser les workflows n8n avec Augment
                $Workflows = Sync-N8nWorkflowsWithAugment
                Write-Log -Message "Synchronisation réussie. $($Workflows.Count) workflows synchronisés." -Level INFO
                return $Workflows
            }
            "Export" {
                # Exporter les données n8n vers Augment Memories
                $Memories = Export-N8nDataToAugmentMemories
                Write-Log -Message "Exportation réussie. $($Memories.Count) workflows exportés." -Level INFO
                return $Memories
            }
            "Import" {
                # Importer des données Augment Memories vers n8n
                $Result = Import-AugmentMemoriesToN8n
                Write-Log -Message "Importation terminée." -Level INFO
                return $Result
            }
        }
    } catch {
        Write-Log -Message "Erreur lors de l'exécution de l'action $Action : $_" -Level ERROR
        throw $_
    }
}

# Exporter les fonctions (décommenter si utilisé comme module)
# Export-ModuleMember -Function Get-N8nConfig, Save-N8nConfig, Test-N8nConnection, Get-N8nWorkflows, Get-N8nWorkflow, Invoke-N8nWorkflow, New-N8nWorkflow, Update-N8nWorkflow, Remove-N8nWorkflow, Get-N8nWorkflowExecutions, Get-N8nExecution, Sync-N8nWorkflowsWithAugment, New-N8nWorkflowFromAugmentDescription, Export-N8nDataToAugmentMemories, Import-AugmentMemoriesToN8n, Start-AugmentN8nIntegration

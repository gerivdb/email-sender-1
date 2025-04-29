<#
.SYNOPSIS
    Adaptateur pour le Roadmap Manager.

.DESCRIPTION
    Cet adaptateur permet d'intégrer le Roadmap Manager avec le Process Manager.
    Il fournit une interface standardisée pour interagir avec le Roadmap Manager.

.PARAMETER Command
    La commande à exécuter. Les commandes disponibles sont :
    - ParseRoadmap : Analyse une roadmap
    - GetTaskInfo : Obtient des informations sur une tâche spécifique
    - UpdateTaskStatus : Met à jour le statut d'une tâche
    - GenerateReport : Génère un rapport sur la roadmap

.PARAMETER FilePath
    Le chemin vers le fichier de roadmap à utiliser pour la commande.

.PARAMETER TaskIdentifier
    L'identifiant de la tâche à utiliser pour la commande.

.PARAMETER Status
    Le statut à définir pour la tâche.

.PARAMETER Parameters
    Les paramètres supplémentaires à passer à la commande.

.EXAMPLE
    .\roadmap-manager-adapter.ps1 -Command ParseRoadmap -FilePath "projet\roadmaps\roadmap_complete_converted.md"
    Analyse la roadmap spécifiée.

.EXAMPLE
    .\roadmap-manager-adapter.ps1 -Command GetTaskInfo -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "2.3"
    Obtient des informations sur la tâche 2.3.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2025-05-03
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("ParseRoadmap", "GetTaskInfo", "UpdateTaskStatus", "GenerateReport")]
    [string]$Command,

    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$Status,

    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{}
)

# Définir le chemin vers le Roadmap Manager
$roadmapManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) -ChildPath "roadmap-manager\scripts\roadmap-manager.ps1"

# Si le Roadmap Manager n'existe pas, essayer un autre chemin
if (-not (Test-Path -Path $roadmapManagerPath)) {
    $roadmapManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) -ChildPath "roadmap\parser\module\Functions\Public\Invoke-RoadmapCheck.ps1"
}

# Vérifier que le Roadmap Manager existe
if (-not (Test-Path -Path $roadmapManagerPath)) {
    Write-Error "Le Roadmap Manager est introuvable à l'emplacement : $roadmapManagerPath"
    exit 1
}

# Fonction pour exécuter une commande sur le Roadmap Manager
function Invoke-RoadmapManagerCommand {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    # Construire la commande
    $commandParams = @{
        FilePath = $roadmapManagerPath
        ArgumentList = "-Command $Command"
    }

    # Ajouter les paramètres
    foreach ($param in $Parameters.Keys) {
        $value = $Parameters[$param]
        
        # Gérer les types de paramètres
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

    # Exécuter la commande
    if ($PSCmdlet.ShouldProcess("Roadmap Manager", "Exécuter la commande $Command")) {
        try {
            $result = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $($commandParams.FilePath) $($commandParams.ArgumentList)" -Wait -PassThru -NoNewWindow
            
            if ($result.ExitCode -eq 0) {
                return $true
            } else {
                Write-Error "Erreur lors de l'exécution de la commande. Code de sortie : $($result.ExitCode)"
                return $false
            }
        } catch {
            Write-Error "Erreur lors de l'exécution de la commande : $_"
            return $false
        }
    }

    return $false
}

# Exécuter la commande spécifiée
switch ($Command) {
    "ParseRoadmap" {
        # Vérifier que le chemin du fichier est spécifié
        if (-not $FilePath) {
            Write-Error "Le paramètre FilePath est requis pour la commande ParseRoadmap."
            exit 1
        }
        
        # Analyser la roadmap
        $params = @{
            FilePath = $FilePath
        }
        
        # Ajouter les paramètres supplémentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-RoadmapManagerCommand -Command "ParseRoadmap" -Parameters $params
        return $result
    }
    
    "GetTaskInfo" {
        # Vérifier que le chemin du fichier et l'identifiant de la tâche sont spécifiés
        if (-not $FilePath -or -not $TaskIdentifier) {
            Write-Error "Les paramètres FilePath et TaskIdentifier sont requis pour la commande GetTaskInfo."
            exit 1
        }
        
        # Obtenir des informations sur la tâche
        $params = @{
            FilePath = $FilePath
            TaskIdentifier = $TaskIdentifier
        }
        
        # Ajouter les paramètres supplémentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-RoadmapManagerCommand -Command "GetTaskInfo" -Parameters $params
        return $result
    }
    
    "UpdateTaskStatus" {
        # Vérifier que le chemin du fichier, l'identifiant de la tâche et le statut sont spécifiés
        if (-not $FilePath -or -not $TaskIdentifier -or -not $Status) {
            Write-Error "Les paramètres FilePath, TaskIdentifier et Status sont requis pour la commande UpdateTaskStatus."
            exit 1
        }
        
        # Mettre à jour le statut de la tâche
        $params = @{
            FilePath = $FilePath
            TaskIdentifier = $TaskIdentifier
            Status = $Status
        }
        
        # Ajouter les paramètres supplémentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-RoadmapManagerCommand -Command "UpdateTaskStatus" -Parameters $params
        return $result
    }
    
    "GenerateReport" {
        # Vérifier que le chemin du fichier est spécifié
        if (-not $FilePath) {
            Write-Error "Le paramètre FilePath est requis pour la commande GenerateReport."
            exit 1
        }
        
        # Générer un rapport sur la roadmap
        $params = @{
            FilePath = $FilePath
        }
        
        # Ajouter l'identifiant de la tâche si spécifié
        if ($TaskIdentifier) {
            $params.TaskIdentifier = $TaskIdentifier
        }
        
        # Ajouter les paramètres supplémentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-RoadmapManagerCommand -Command "GenerateReport" -Parameters $params
        return $result
    }
}

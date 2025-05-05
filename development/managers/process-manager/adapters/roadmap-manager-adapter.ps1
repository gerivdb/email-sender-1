<#
.SYNOPSIS
    Adaptateur pour le Roadmap Manager.

.DESCRIPTION
    Cet adaptateur permet d'intÃ©grer le Roadmap Manager avec le Process Manager.
    Il fournit une interface standardisÃ©e pour interagir avec le Roadmap Manager.

.PARAMETER Command
    La commande Ã  exÃ©cuter. Les commandes disponibles sont :
    - ParseRoadmap : Analyse une roadmap
    - GetTaskInfo : Obtient des informations sur une tÃ¢che spÃ©cifique
    - UpdateTaskStatus : Met Ã  jour le statut d'une tÃ¢che
    - GenerateReport : GÃ©nÃ¨re un rapport sur la roadmap

.PARAMETER FilePath
    Le chemin vers le fichier de roadmap Ã  utiliser pour la commande.

.PARAMETER TaskIdentifier
    L'identifiant de la tÃ¢che Ã  utiliser pour la commande.

.PARAMETER Status
    Le statut Ã  dÃ©finir pour la tÃ¢che.

.PARAMETER Parameters
    Les paramÃ¨tres supplÃ©mentaires Ã  passer Ã  la commande.

.EXAMPLE
    .\roadmap-manager-adapter.ps1 -Command ParseRoadmap -FilePath "projet\roadmaps\roadmap_complete_converted.md"
    Analyse la roadmap spÃ©cifiÃ©e.

.EXAMPLE
    .\roadmap-manager-adapter.ps1 -Command GetTaskInfo -FilePath "projet\roadmaps\roadmap_complete_converted.md" -TaskIdentifier "2.3"
    Obtient des informations sur la tÃ¢che 2.3.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-03
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

# DÃ©finir le chemin vers le Roadmap Manager
$roadmapManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) -ChildPath "roadmap-manager\scripts\roadmap-manager.ps1"

# Si le Roadmap Manager n'existe pas, essayer un autre chemin
if (-not (Test-Path -Path $roadmapManagerPath)) {
    $roadmapManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) -ChildPath "roadmap\parser\module\Functions\Public\Invoke-RoadmapCheck.ps1"
}

# VÃ©rifier que le Roadmap Manager existe
if (-not (Test-Path -Path $roadmapManagerPath)) {
    Write-Error "Le Roadmap Manager est introuvable Ã  l'emplacement : $roadmapManagerPath"
    exit 1
}

# Fonction pour exÃ©cuter une commande sur le Roadmap Manager
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
    if ($PSCmdlet.ShouldProcess("Roadmap Manager", "ExÃ©cuter la commande $Command")) {
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
    "ParseRoadmap" {
        # VÃ©rifier que le chemin du fichier est spÃ©cifiÃ©
        if (-not $FilePath) {
            Write-Error "Le paramÃ¨tre FilePath est requis pour la commande ParseRoadmap."
            exit 1
        }
        
        # Analyser la roadmap
        $params = @{
            FilePath = $FilePath
        }
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-RoadmapManagerCommand -Command "ParseRoadmap" -Parameters $params
        return $result
    }
    
    "GetTaskInfo" {
        # VÃ©rifier que le chemin du fichier et l'identifiant de la tÃ¢che sont spÃ©cifiÃ©s
        if (-not $FilePath -or -not $TaskIdentifier) {
            Write-Error "Les paramÃ¨tres FilePath et TaskIdentifier sont requis pour la commande GetTaskInfo."
            exit 1
        }
        
        # Obtenir des informations sur la tÃ¢che
        $params = @{
            FilePath = $FilePath
            TaskIdentifier = $TaskIdentifier
        }
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-RoadmapManagerCommand -Command "GetTaskInfo" -Parameters $params
        return $result
    }
    
    "UpdateTaskStatus" {
        # VÃ©rifier que le chemin du fichier, l'identifiant de la tÃ¢che et le statut sont spÃ©cifiÃ©s
        if (-not $FilePath -or -not $TaskIdentifier -or -not $Status) {
            Write-Error "Les paramÃ¨tres FilePath, TaskIdentifier et Status sont requis pour la commande UpdateTaskStatus."
            exit 1
        }
        
        # Mettre Ã  jour le statut de la tÃ¢che
        $params = @{
            FilePath = $FilePath
            TaskIdentifier = $TaskIdentifier
            Status = $Status
        }
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-RoadmapManagerCommand -Command "UpdateTaskStatus" -Parameters $params
        return $result
    }
    
    "GenerateReport" {
        # VÃ©rifier que le chemin du fichier est spÃ©cifiÃ©
        if (-not $FilePath) {
            Write-Error "Le paramÃ¨tre FilePath est requis pour la commande GenerateReport."
            exit 1
        }
        
        # GÃ©nÃ©rer un rapport sur la roadmap
        $params = @{
            FilePath = $FilePath
        }
        
        # Ajouter l'identifiant de la tÃ¢che si spÃ©cifiÃ©
        if ($TaskIdentifier) {
            $params.TaskIdentifier = $TaskIdentifier
        }
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-RoadmapManagerCommand -Command "GenerateReport" -Parameters $params
        return $result
    }
}

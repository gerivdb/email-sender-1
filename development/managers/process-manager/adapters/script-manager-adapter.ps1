<#
.SYNOPSIS
    Adaptateur pour le Script Manager.

.DESCRIPTION
    Cet adaptateur permet d'intÃ©grer le Script Manager avec le Process Manager.
    Il fournit une interface standardisÃ©e pour interagir avec le Script Manager.

.PARAMETER Command
    La commande Ã  exÃ©cuter. Les commandes disponibles sont :
    - ExecuteScript : ExÃ©cute un script
    - ListScripts : Liste tous les scripts disponibles
    - GetScriptInfo : Obtient des informations sur un script spÃ©cifique
    - OrganizeScripts : Organise les scripts dans le rÃ©pertoire appropriÃ©

.PARAMETER ScriptName
    Le nom du script Ã  utiliser pour la commande.

.PARAMETER ScriptPath
    Le chemin vers le script Ã  utiliser pour la commande.

.PARAMETER Parameters
    Les paramÃ¨tres supplÃ©mentaires Ã  passer Ã  la commande.

.EXAMPLE
    .\script-manager-adapter.ps1 -Command ListScripts
    Liste tous les scripts disponibles.

.EXAMPLE
    .\script-manager-adapter.ps1 -Command ExecuteScript -ScriptName "update-roadmap-checkboxes.ps1" -Parameters @{RoadmapPath = "projet\roadmaps\roadmap_complete_converted.md"; Force = $true}
    ExÃ©cute le script "update-roadmap-checkboxes.ps1" avec les paramÃ¨tres spÃ©cifiÃ©s.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-03
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("ExecuteScript", "ListScripts", "GetScriptInfo", "OrganizeScripts")]
    [string]$Command,

    [Parameter(Mandatory = $false)]
    [string]$ScriptName,

    [Parameter(Mandatory = $false)]
    [string]$ScriptPath,

    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{}
)

# DÃ©finir le chemin vers le Script Manager
$scriptManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) -ChildPath "script-manager\scripts\script-manager.ps1"

# VÃ©rifier que le Script Manager existe
if (-not (Test-Path -Path $scriptManagerPath)) {
    Write-Error "Le Script Manager est introuvable Ã  l'emplacement : $scriptManagerPath"
    exit 1
}

# Fonction pour exÃ©cuter une commande sur le Script Manager
function Invoke-ScriptManagerCommand {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    # Construire la commande
    $commandParams = @{
        FilePath = $scriptManagerPath
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
    if ($PSCmdlet.ShouldProcess("Script Manager", "ExÃ©cuter la commande $Command")) {
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
    "ExecuteScript" {
        # VÃ©rifier que le nom du script ou le chemin du script est spÃ©cifiÃ©
        if (-not $ScriptName -and -not $ScriptPath) {
            Write-Error "Le paramÃ¨tre ScriptName ou ScriptPath est requis pour la commande ExecuteScript."
            exit 1
        }
        
        # ExÃ©cuter le script
        $params = @{}
        
        if ($ScriptName) {
            $params.ScriptName = $ScriptName
        }
        
        if ($ScriptPath) {
            $params.ScriptPath = $ScriptPath
        }
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-ScriptManagerCommand -Command "ExecuteScript" -Parameters $params
        return $result
    }
    
    "ListScripts" {
        # Lister tous les scripts disponibles
        $result = Invoke-ScriptManagerCommand -Command "ListScripts"
        return $result
    }
    
    "GetScriptInfo" {
        # VÃ©rifier que le nom du script ou le chemin du script est spÃ©cifiÃ©
        if (-not $ScriptName -and -not $ScriptPath) {
            Write-Error "Le paramÃ¨tre ScriptName ou ScriptPath est requis pour la commande GetScriptInfo."
            exit 1
        }
        
        # Obtenir des informations sur le script
        $params = @{}
        
        if ($ScriptName) {
            $params.ScriptName = $ScriptName
        }
        
        if ($ScriptPath) {
            $params.ScriptPath = $ScriptPath
        }
        
        $result = Invoke-ScriptManagerCommand -Command "GetScriptInfo" -Parameters $params
        return $result
    }
    
    "OrganizeScripts" {
        # Organiser les scripts
        $params = @{}
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-ScriptManagerCommand -Command "OrganizeScripts" -Parameters $params
        return $result
    }
}

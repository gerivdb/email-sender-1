<#
.SYNOPSIS
    Adaptateur pour le Script Manager.

.DESCRIPTION
    Cet adaptateur permet d'intégrer le Script Manager avec le Process Manager.
    Il fournit une interface standardisée pour interagir avec le Script Manager.

.PARAMETER Command
    La commande à exécuter. Les commandes disponibles sont :
    - ExecuteScript : Exécute un script
    - ListScripts : Liste tous les scripts disponibles
    - GetScriptInfo : Obtient des informations sur un script spécifique
    - OrganizeScripts : Organise les scripts dans le répertoire approprié

.PARAMETER ScriptName
    Le nom du script à utiliser pour la commande.

.PARAMETER ScriptPath
    Le chemin vers le script à utiliser pour la commande.

.PARAMETER Parameters
    Les paramètres supplémentaires à passer à la commande.

.EXAMPLE
    .\script-manager-adapter.ps1 -Command ListScripts
    Liste tous les scripts disponibles.

.EXAMPLE
    .\script-manager-adapter.ps1 -Command ExecuteScript -ScriptName "update-roadmap-checkboxes.ps1" -Parameters @{RoadmapPath = "projet\roadmaps\roadmap_complete_converted.md"; Force = $true}
    Exécute le script "update-roadmap-checkboxes.ps1" avec les paramètres spécifiés.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2025-05-03
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

# Définir le chemin vers le Script Manager
$scriptManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) -ChildPath "script-manager\scripts\script-manager.ps1"

# Vérifier que le Script Manager existe
if (-not (Test-Path -Path $scriptManagerPath)) {
    Write-Error "Le Script Manager est introuvable à l'emplacement : $scriptManagerPath"
    exit 1
}

# Fonction pour exécuter une commande sur le Script Manager
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
    if ($PSCmdlet.ShouldProcess("Script Manager", "Exécuter la commande $Command")) {
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
    "ExecuteScript" {
        # Vérifier que le nom du script ou le chemin du script est spécifié
        if (-not $ScriptName -and -not $ScriptPath) {
            Write-Error "Le paramètre ScriptName ou ScriptPath est requis pour la commande ExecuteScript."
            exit 1
        }
        
        # Exécuter le script
        $params = @{}
        
        if ($ScriptName) {
            $params.ScriptName = $ScriptName
        }
        
        if ($ScriptPath) {
            $params.ScriptPath = $ScriptPath
        }
        
        # Ajouter les paramètres supplémentaires
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
        # Vérifier que le nom du script ou le chemin du script est spécifié
        if (-not $ScriptName -and -not $ScriptPath) {
            Write-Error "Le paramètre ScriptName ou ScriptPath est requis pour la commande GetScriptInfo."
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
        
        # Ajouter les paramètres supplémentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-ScriptManagerCommand -Command "OrganizeScripts" -Parameters $params
        return $result
    }
}

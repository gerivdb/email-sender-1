<#
.SYNOPSIS
    Adaptateur pour le Mode Manager.

.DESCRIPTION
    Cet adaptateur permet d'intégrer le Mode Manager avec le Process Manager.
    Il fournit une interface standardisée pour interagir avec le Mode Manager.

.PARAMETER Command
    La commande à exécuter. Les commandes disponibles sont :
    - GetMode : Obtient le mode actuel
    - SetMode : Définit le mode actuel
    - ListModes : Liste tous les modes disponibles
    - GetModeInfo : Obtient des informations sur un mode spécifique

.PARAMETER Mode
    Le mode à utiliser pour la commande.

.PARAMETER FilePath
    Le chemin vers le fichier à utiliser pour la commande.

.PARAMETER Parameters
    Les paramètres supplémentaires à passer à la commande.

.EXAMPLE
    .\mode-manager-adapter.ps1 -Command GetMode
    Obtient le mode actuel.

.EXAMPLE
    .\mode-manager-adapter.ps1 -Command SetMode -Mode "CHECK"
    Définit le mode actuel sur "CHECK".

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2025-05-03
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("GetMode", "SetMode", "ListModes", "GetModeInfo")]
    [string]$Command,

    [Parameter(Mandatory = $false)]
    [string]$Mode,

    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{}
)

# Définir le chemin vers le Mode Manager
$modeManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) -ChildPath "mode-manager\scripts\mode-manager.ps1"

# Vérifier que le Mode Manager existe
if (-not (Test-Path -Path $modeManagerPath)) {
    Write-Error "Le Mode Manager est introuvable à l'emplacement : $modeManagerPath"
    exit 1
}

# Fonction pour exécuter une commande sur le Mode Manager
function Invoke-ModeManagerCommand {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    # Construire la commande
    $commandParams = @{
        FilePath = $modeManagerPath
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
    if ($PSCmdlet.ShouldProcess("Mode Manager", "Exécuter la commande $Command")) {
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
    "GetMode" {
        # Obtenir le mode actuel
        $result = Invoke-ModeManagerCommand -Command "GetMode"
        return $result
    }
    
    "SetMode" {
        # Vérifier que le mode est spécifié
        if (-not $Mode) {
            Write-Error "Le paramètre Mode est requis pour la commande SetMode."
            exit 1
        }
        
        # Définir le mode
        $params = @{
            Mode = $Mode
        }
        
        # Ajouter le chemin du fichier si spécifié
        if ($FilePath) {
            $params.FilePath = $FilePath
        }
        
        # Ajouter les paramètres supplémentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-ModeManagerCommand -Command "SetMode" -Parameters $params
        return $result
    }
    
    "ListModes" {
        # Lister tous les modes disponibles
        $result = Invoke-ModeManagerCommand -Command "ListModes"
        return $result
    }
    
    "GetModeInfo" {
        # Vérifier que le mode est spécifié
        if (-not $Mode) {
            Write-Error "Le paramètre Mode est requis pour la commande GetModeInfo."
            exit 1
        }
        
        # Obtenir des informations sur le mode
        $params = @{
            Mode = $Mode
        }
        
        $result = Invoke-ModeManagerCommand -Command "GetModeInfo" -Parameters $params
        return $result
    }
}

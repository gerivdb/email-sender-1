<#
.SYNOPSIS
    Adaptateur pour l'Error Manager.

.DESCRIPTION
    Cet adaptateur permet d'intégrer l'Error Manager avec le Process Manager.
    Il fournit une interface standardisée pour interagir avec l'Error Manager.

.PARAMETER Command
    La commande à exécuter. Les commandes disponibles sont :
    - LogError : Enregistre une erreur
    - GetErrors : Obtient les erreurs enregistrées
    - ClearErrors : Efface les erreurs enregistrées
    - AnalyzeErrors : Analyse les erreurs enregistrées

.PARAMETER ErrorMessage
    Le message d'erreur à enregistrer.

.PARAMETER ErrorSource
    La source de l'erreur à enregistrer.

.PARAMETER ErrorCode
    Le code d'erreur à enregistrer.

.PARAMETER Parameters
    Les paramètres supplémentaires à passer à la commande.

.EXAMPLE
    .\error-manager-adapter.ps1 -Command LogError -ErrorMessage "Une erreur est survenue" -ErrorSource "Process Manager" -ErrorCode "PM001"
    Enregistre une erreur avec le message, la source et le code spécifiés.

.EXAMPLE
    .\error-manager-adapter.ps1 -Command GetErrors
    Obtient toutes les erreurs enregistrées.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de création: 2025-05-03
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("LogError", "GetErrors", "ClearErrors", "AnalyzeErrors")]
    [string]$Command,

    [Parameter(Mandatory = $false)]
    [string]$ErrorMessage,

    [Parameter(Mandatory = $false)]
    [string]$ErrorSource,

    [Parameter(Mandatory = $false)]
    [string]$ErrorCode,

    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{}
)

# Définir le chemin vers l'Error Manager
$errorManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) -ChildPath "error-manager\scripts\error-manager.ps1"

# Vérifier que l'Error Manager existe
if (-not (Test-Path -Path $errorManagerPath)) {
    Write-Error "L'Error Manager est introuvable à l'emplacement : $errorManagerPath"
    exit 1
}

# Fonction pour exécuter une commande sur l'Error Manager
function Invoke-ErrorManagerCommand {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,

        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{}
    )

    # Construire la commande
    $commandParams = @{
        FilePath = $errorManagerPath
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
    if ($PSCmdlet.ShouldProcess("Error Manager", "Exécuter la commande $Command")) {
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
    "LogError" {
        # Vérifier que le message d'erreur est spécifié
        if (-not $ErrorMessage) {
            Write-Error "Le paramètre ErrorMessage est requis pour la commande LogError."
            exit 1
        }
        
        # Enregistrer l'erreur
        $params = @{
            ErrorMessage = $ErrorMessage
        }
        
        # Ajouter la source de l'erreur si spécifiée
        if ($ErrorSource) {
            $params.ErrorSource = $ErrorSource
        }
        
        # Ajouter le code d'erreur si spécifié
        if ($ErrorCode) {
            $params.ErrorCode = $ErrorCode
        }
        
        # Ajouter les paramètres supplémentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-ErrorManagerCommand -Command "LogError" -Parameters $params
        return $result
    }
    
    "GetErrors" {
        # Obtenir les erreurs enregistrées
        $params = @{}
        
        # Ajouter la source de l'erreur si spécifiée
        if ($ErrorSource) {
            $params.ErrorSource = $ErrorSource
        }
        
        # Ajouter le code d'erreur si spécifié
        if ($ErrorCode) {
            $params.ErrorCode = $ErrorCode
        }
        
        # Ajouter les paramètres supplémentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-ErrorManagerCommand -Command "GetErrors" -Parameters $params
        return $result
    }
    
    "ClearErrors" {
        # Effacer les erreurs enregistrées
        $params = @{}
        
        # Ajouter la source de l'erreur si spécifiée
        if ($ErrorSource) {
            $params.ErrorSource = $ErrorSource
        }
        
        # Ajouter le code d'erreur si spécifié
        if ($ErrorCode) {
            $params.ErrorCode = $ErrorCode
        }
        
        # Ajouter les paramètres supplémentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-ErrorManagerCommand -Command "ClearErrors" -Parameters $params
        return $result
    }
    
    "AnalyzeErrors" {
        # Analyser les erreurs enregistrées
        $params = @{}
        
        # Ajouter la source de l'erreur si spécifiée
        if ($ErrorSource) {
            $params.ErrorSource = $ErrorSource
        }
        
        # Ajouter le code d'erreur si spécifié
        if ($ErrorCode) {
            $params.ErrorCode = $ErrorCode
        }
        
        # Ajouter les paramètres supplémentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-ErrorManagerCommand -Command "AnalyzeErrors" -Parameters $params
        return $result
    }
}

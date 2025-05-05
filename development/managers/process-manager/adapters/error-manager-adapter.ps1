<#
.SYNOPSIS
    Adaptateur pour l'Error Manager.

.DESCRIPTION
    Cet adaptateur permet d'intÃ©grer l'Error Manager avec le Process Manager.
    Il fournit une interface standardisÃ©e pour interagir avec l'Error Manager.

.PARAMETER Command
    La commande Ã  exÃ©cuter. Les commandes disponibles sont :
    - LogError : Enregistre une erreur
    - GetErrors : Obtient les erreurs enregistrÃ©es
    - ClearErrors : Efface les erreurs enregistrÃ©es
    - AnalyzeErrors : Analyse les erreurs enregistrÃ©es

.PARAMETER ErrorMessage
    Le message d'erreur Ã  enregistrer.

.PARAMETER ErrorSource
    La source de l'erreur Ã  enregistrer.

.PARAMETER ErrorCode
    Le code d'erreur Ã  enregistrer.

.PARAMETER Parameters
    Les paramÃ¨tres supplÃ©mentaires Ã  passer Ã  la commande.

.EXAMPLE
    .\error-manager-adapter.ps1 -Command LogError -ErrorMessage "Une erreur est survenue" -ErrorSource "Process Manager" -ErrorCode "PM001"
    Enregistre une erreur avec le message, la source et le code spÃ©cifiÃ©s.

.EXAMPLE
    .\error-manager-adapter.ps1 -Command GetErrors
    Obtient toutes les erreurs enregistrÃ©es.

.NOTES
    Auteur: Process Manager Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-03
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

# DÃ©finir le chemin vers l'Error Manager
$errorManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))) -ChildPath "error-manager\scripts\error-manager.ps1"

# VÃ©rifier que l'Error Manager existe
if (-not (Test-Path -Path $errorManagerPath)) {
    Write-Error "L'Error Manager est introuvable Ã  l'emplacement : $errorManagerPath"
    exit 1
}

# Fonction pour exÃ©cuter une commande sur l'Error Manager
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
    if ($PSCmdlet.ShouldProcess("Error Manager", "ExÃ©cuter la commande $Command")) {
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
    "LogError" {
        # VÃ©rifier que le message d'erreur est spÃ©cifiÃ©
        if (-not $ErrorMessage) {
            Write-Error "Le paramÃ¨tre ErrorMessage est requis pour la commande LogError."
            exit 1
        }
        
        # Enregistrer l'erreur
        $params = @{
            ErrorMessage = $ErrorMessage
        }
        
        # Ajouter la source de l'erreur si spÃ©cifiÃ©e
        if ($ErrorSource) {
            $params.ErrorSource = $ErrorSource
        }
        
        # Ajouter le code d'erreur si spÃ©cifiÃ©
        if ($ErrorCode) {
            $params.ErrorCode = $ErrorCode
        }
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-ErrorManagerCommand -Command "LogError" -Parameters $params
        return $result
    }
    
    "GetErrors" {
        # Obtenir les erreurs enregistrÃ©es
        $params = @{}
        
        # Ajouter la source de l'erreur si spÃ©cifiÃ©e
        if ($ErrorSource) {
            $params.ErrorSource = $ErrorSource
        }
        
        # Ajouter le code d'erreur si spÃ©cifiÃ©
        if ($ErrorCode) {
            $params.ErrorCode = $ErrorCode
        }
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-ErrorManagerCommand -Command "GetErrors" -Parameters $params
        return $result
    }
    
    "ClearErrors" {
        # Effacer les erreurs enregistrÃ©es
        $params = @{}
        
        # Ajouter la source de l'erreur si spÃ©cifiÃ©e
        if ($ErrorSource) {
            $params.ErrorSource = $ErrorSource
        }
        
        # Ajouter le code d'erreur si spÃ©cifiÃ©
        if ($ErrorCode) {
            $params.ErrorCode = $ErrorCode
        }
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-ErrorManagerCommand -Command "ClearErrors" -Parameters $params
        return $result
    }
    
    "AnalyzeErrors" {
        # Analyser les erreurs enregistrÃ©es
        $params = @{}
        
        # Ajouter la source de l'erreur si spÃ©cifiÃ©e
        if ($ErrorSource) {
            $params.ErrorSource = $ErrorSource
        }
        
        # Ajouter le code d'erreur si spÃ©cifiÃ©
        if ($ErrorCode) {
            $params.ErrorCode = $ErrorCode
        }
        
        # Ajouter les paramÃ¨tres supplÃ©mentaires
        foreach ($param in $Parameters.Keys) {
            $params[$param] = $Parameters[$param]
        }
        
        $result = Invoke-ErrorManagerCommand -Command "AnalyzeErrors" -Parameters $params
        return $result
    }
}

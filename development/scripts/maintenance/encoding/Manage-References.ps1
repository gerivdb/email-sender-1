<#
.SYNOPSIS
    GÃ¨re les rÃ©fÃ©rences dans les scripts suite Ã  la rÃ©organisation.
.DESCRIPTION
    Ce script orchestre le processus de dÃ©tection et de mise Ã  jour des rÃ©fÃ©rences brisÃ©es
    dans les scripts suite Ã  la rÃ©organisation. Il permet de dÃ©tecter les rÃ©fÃ©rences brisÃ©es,
    de les analyser et de les mettre Ã  jour automatiquement ou manuellement.
.PARAMETER Action
    Action Ã  effectuer. Valeurs possibles: detect, update, all.
    - detect: DÃ©tecte les rÃ©fÃ©rences brisÃ©es.
    - update: Met Ã  jour les rÃ©fÃ©rences brisÃ©es.
    - all: Effectue les deux actions.
.PARAMETER ScriptsPath
    Chemin du dossier contenant les scripts Ã  analyser. Par dÃ©faut: scripts
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER Verbose
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Manage-References.ps1 -Action detect
    DÃ©tecte les rÃ©fÃ©rences brisÃ©es dans les scripts.
.EXAMPLE
    .\Manage-References.ps1 -Action update -AutoApply
    Met Ã  jour automatiquement les rÃ©fÃ©rences brisÃ©es.
.EXAMPLE
    .\Manage-References.ps1 -Action all -AutoApply
    DÃ©tecte et met Ã  jour automatiquement les rÃ©fÃ©rences brisÃ©es.
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("detect", "update", "all")]
    [string]$Action,
    [string]$ScriptsPath = "scripts",
    [switch]$AutoApply,
    [switch]$ShowDetails
)

# Fonction pour Ã©crire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )

    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }

    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"

    Write-Host $FormattedMessage -ForegroundColor $Color

    # Ã‰crire dans un fichier de log
    $LogFile = "..\..\D"
    Add-Content -Path $LogFile -Value $FormattedMessage
}

# Fonction pour dÃ©tecter les rÃ©fÃ©rences brisÃ©es
function Find-BrokenReferences {
    param (
        [string]$ScriptsPath
    )

    Write-Log "DÃ©marrage de la dÃ©tection des rÃ©fÃ©rences brisÃ©es..." -Level "TITLE"

    $DetectScript = "..\..\D"
    $OutputPath = "..\..\D"

    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $DetectScript)) {
        Write-Log "Le script de dÃ©tection n'existe pas: $DetectScript" -Level "ERROR"
        return $false
    }

    # ExÃ©cuter le script de dÃ©tection
    $VerboseParam = if ($ShowDetails) { "-Verbose" } else { "" }
    $Command = "& '$DetectScript' -ScriptsPath '$ScriptsPath' -OutputPath '$OutputPath' $VerboseParam"

    Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"

    try {
        Invoke-Expression $Command

        # VÃ©rifier si le fichier de sortie a Ã©tÃ© crÃ©Ã©
        if (Test-Path -Path $OutputPath) {
            $Report = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json
            $BrokenCount = $Report.BrokenReferences.Count

            Write-Log "DÃ©tection terminÃ©e avec succÃ¨s" -Level "SUCCESS"
            Write-Log "Nombre de rÃ©fÃ©rences brisÃ©es trouvÃ©es: $BrokenCount" -Level "INFO"

            return $true
        } else {
            Write-Log "Le fichier de sortie n'a pas Ã©tÃ© crÃ©Ã©: $OutputPath" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution du script de dÃ©tection: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour mettre Ã  jour les rÃ©fÃ©rences brisÃ©es
function Update-BrokenReferences {
    param (
        [switch]$AutoApply
    )

    Write-Log "DÃ©marrage de la mise Ã  jour des rÃ©fÃ©rences brisÃ©es..." -Level "TITLE"

    $UpdateScript = "..\..\D"
    $InputPath = "..\..\D"
    $OutputPath = "..\..\D"

    # VÃ©rifier si le script existe
    if (-not (Test-Path -Path $UpdateScript)) {
        Write-Log "Le script de mise Ã  jour n'existe pas: $UpdateScript" -Level "ERROR"
        return $false
    }

    # VÃ©rifier si le fichier d'entrÃ©e existe
    if (-not (Test-Path -Path $InputPath)) {
        Write-Log "Le fichier d'entrÃ©e n'existe pas: $InputPath" -Level "ERROR"
        Write-Log "ExÃ©cutez d'abord l'action 'detect' pour gÃ©nÃ©rer le rapport." -Level "ERROR"
        return $false
    }

    # ExÃ©cuter le script de mise Ã  jour
    $AutoApplyParam = if ($AutoApply) { "-AutoApply" } else { "" }
    $VerboseParam = if ($ShowDetails) { "-Verbose" } else { "" }
    $Command = "& '$UpdateScript' -InputPath '$InputPath' -OutputPath '$OutputPath' $AutoApplyParam $VerboseParam"

    Write-Log "ExÃ©cution de la commande: $Command" -Level "INFO"

    try {
        Invoke-Expression $Command

        # VÃ©rifier si le fichier de sortie a Ã©tÃ© crÃ©Ã©
        if (Test-Path -Path $OutputPath) {
            $Report = Get-Content -Path $OutputPath -Raw | ConvertFrom-Json
            $UpdateCount = ($Report.Updates | Where-Object { $_.Applied } | Measure-Object).Count
            $TotalUpdates = $Report.Updates.Count

            Write-Log "Mise Ã  jour terminÃ©e avec succÃ¨s" -Level "SUCCESS"
            Write-Log "Nombre de mises Ã  jour proposÃ©es: $TotalUpdates" -Level "INFO"
            if ($AutoApply) {
                Write-Log "Nombre de mises Ã  jour appliquÃ©es: $UpdateCount" -Level "SUCCESS"
            } else {
                Write-Log "Pour appliquer les mises Ã  jour, exÃ©cutez la commande avec -AutoApply" -Level "WARNING"
            }

            return $true
        } else {
            Write-Log "Le fichier de sortie n'a pas Ã©tÃ© crÃ©Ã©: $OutputPath" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exÃ©cution du script de mise Ã  jour: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale
function Start-ReferenceManagement {
    param (
        [string]$Action,
        [string]$ScriptsPath,
        [switch]$AutoApply,
        [switch]$Verbose
    )

    Write-Log "=== Gestion des rÃ©fÃ©rences ===" -Level "TITLE"
    Write-Log "Action: $Action" -Level "INFO"
    Write-Log "Dossier des scripts: $ScriptsPath" -Level "INFO"
    Write-Log "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -Level "INFO"

    $Success = $true

    # ExÃ©cuter l'action demandÃ©e
    switch ($Action) {
        "detect" {
            $Success = Find-BrokenReferences -ScriptsPath $ScriptsPath
        }
        "update" {
            $Success = Update-BrokenReferences -AutoApply:$AutoApply
        }
        "all" {
            $Success = Find-BrokenReferences -ScriptsPath $ScriptsPath
            if ($Success) {
                $Success = Update-BrokenReferences -AutoApply:$AutoApply
            }
        }
    }

    # Afficher un message de rÃ©sultat
    if ($Success) {
        Write-Log "OpÃ©ration terminÃ©e avec succÃ¨s" -Level "SUCCESS"
    } else {
        Write-Log "OpÃ©ration terminÃ©e avec des erreurs" -Level "ERROR"
    }

    return $Success
}

# ExÃ©cuter la fonction principale
Start-ReferenceManagement -Action $Action -ScriptsPath $ScriptsPath -AutoApply:$AutoApply -ShowDetails:$ShowDetails


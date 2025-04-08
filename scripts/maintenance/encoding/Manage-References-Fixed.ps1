<#
.SYNOPSIS
    Gère les références dans les scripts suite à la réorganisation.
.DESCRIPTION
    Ce script orchestre le processus de détection et de mise à jour des références brisées
    dans les scripts suite à la réorganisation. Il permet de détecter les références brisées,
    de les analyser et de les mettre à jour automatiquement ou manuellement.
.PARAMETER Action
    Action à effectuer. Valeurs possibles: detect, update, all.
    - detect: Détecte les références brisées.
    - update: Met à jour les références brisées.
    - all: Effectue les deux actions.
.PARAMETER ScriptsPath
    Chemin du dossier contenant les scripts à analyser. Par défaut: scripts
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER ShowDetails
    Affiche des informations détaillées pendant l'exécution.
.EXAMPLE
    .\Manage-References-Fixed.ps1 -Action detect
    Détecte les références brisées dans les scripts.
.EXAMPLE
    .\Manage-References-Fixed.ps1 -Action update -AutoApply
    Met à jour automatiquement les références brisées.
.EXAMPLE
    .\Manage-References-Fixed.ps1 -Action all -AutoApply
    Détecte et met à jour automatiquement les références brisées.
#>

param (
    [Parameter(Mandatory=$true)]
    [ValidateSet("detect", "update", "all")]
    [string]$Action,
    [string]$ScriptsPath = "scripts",
    [switch]$AutoApply,
    [switch]$ShowDetails
)

# Fonction pour écrire des messages de log
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
    
    # Écrire dans un fichier de log
    $LogFile = "..\..\D"
    Add-Content -Path $LogFile -Value $FormattedMessage
}

# Fonction pour détecter les références brisées
function Find-BrokenReferences {
    param (
        [string]$ScriptsPath
    )
    
    Write-Log "Démarrage de la détection des références brisées..." -Level "TITLE"
    
    $DetectScript = "..\..\D"
    $OutputPath = "..\..\D"
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $DetectScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script de détection n'existe pas: $DetectScript" -Level "ERROR"
        return $false
    }
    
    # Exécuter le script de détection
    $VerboseParam = if ($ShowDetails) { "-Verbose" } else { "" }
    $Command = "& '$DetectScript' -ScriptsPath '$ScriptsPath' -OutputPath '$OutputPath' $VerboseParam"
    
    Write-Log "Exécution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # Vérifier si le fichier de sortie a été créé
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $BrokenCount = $Report.BrokenReferences.Count
            
            Write-Log "Détection terminée avec succès" -Level "SUCCESS"
            Write-Log "Nombre de références brisées trouvées: $BrokenCount" -Level "INFO"
            
            return $true
        } else {
            Write-Log "Le fichier de sortie n'a pas été créé: $OutputPath" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exécution du script de détection: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour mettre à jour les références brisées
function Update-BrokenReferences {
    param (
        [switch]$AutoApply
    )
    
    Write-Log "Démarrage de la mise à jour des références brisées..." -Level "TITLE"
    
    $UpdateScript = "..\..\D"
    $InputPath = "..\..\D"
    $OutputPath = "..\..\D"
    
    # Vérifier si le script existe
    if (-not (Test-Path -Path $UpdateScript -ErrorAction SilentlyContinue)) {
        Write-Log "Le script de mise à jour n'existe pas: $UpdateScript" -Level "ERROR"
        return $false
    }
    
    # Vérifier si le fichier d'entrée existe
    if (-not (Test-Path -Path $InputPath -ErrorAction SilentlyContinue)) {
        Write-Log "Le fichier d'entrée n'existe pas: $InputPath" -Level "ERROR"
        Write-Log "Exécutez d'abord l'action 'detect' pour générer le rapport." -Level "ERROR"
        return $false
    }
    
    # Exécuter le script de mise à jour
    $AutoApplyParam = if ($AutoApply) { "-AutoApply" } else { "" }
    $VerboseParam = if ($ShowDetails) { "-ShowDetails" } else { "" }
    $Command = "& '$UpdateScript' -InputPath '$InputPath' -OutputPath '$OutputPath' $AutoApplyParam $VerboseParam"
    
    Write-Log "Exécution de la commande: $Command" -Level "INFO"
    
    try {
        Invoke-Expression $Command
        
        # Vérifier si le fichier de sortie a été créé
        if (Test-Path -Path $OutputPath -ErrorAction SilentlyContinue) {
            $Report = Get-Content -Path $OutputPath -Raw -ErrorAction Stop | ConvertFrom-Json
            $UpdateCount = ($Report.Updates | Where-Object { $_.Applied } | Measure-Object).Count
            $TotalUpdates = $Report.Updates.Count
            
            Write-Log "Mise à jour terminée avec succès" -Level "SUCCESS"
            Write-Log "Nombre de mises à jour proposées: $TotalUpdates" -Level "INFO"
            if ($AutoApply) {
                Write-Log "Nombre de mises à jour appliquées: $UpdateCount" -Level "SUCCESS"
            } else {
                Write-Log "Pour appliquer les mises à jour, exécutez la commande avec -AutoApply" -Level "WARNING"
            }
            
            return $true
        } else {
            Write-Log "Le fichier de sortie n'a pas été créé: $OutputPath" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exécution du script de mise à jour: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale
function Start-ReferenceManagement {
    param (
        [string]$Action,
        [string]$ScriptsPath,
        [switch]$AutoApply,
        [switch]$ShowDetails
    )
    
    Write-Log "=== Gestion des références ===" -Level "TITLE"
    Write-Log "Action: $Action" -Level "INFO"
    Write-Log "Dossier des scripts: $ScriptsPath" -Level "INFO"
    Write-Log "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -Level "INFO"
    
    $Success = $true
    
    # Exécuter l'action demandée
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
    
    # Afficher un message de résultat
    if ($Success) {
        Write-Log "Opération terminée avec succès" -Level "SUCCESS"
    } else {
        Write-Log "Opération terminée avec des erreurs" -Level "ERROR"
    }
    
    return $Success
}

# Exécuter la fonction principale
Start-ReferenceManagement -Action $Action -ScriptsPath $ScriptsPath -AutoApply:$AutoApply -ShowDetails:$ShowDetails


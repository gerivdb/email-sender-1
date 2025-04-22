<#
.SYNOPSIS
    Script principal de maintenance n8n.

.DESCRIPTION
    Ce script exécute toutes les tâches de maintenance n8n, comme la rotation des logs,
    la sauvegarde des workflows et le nettoyage des fichiers temporaires.

.PARAMETER N8nRootFolder
    Dossier racine de n8n (par défaut: n8n).

.PARAMETER WorkflowFolder
    Dossier contenant les workflows n8n (par défaut: n8n/data/.n8n/workflows).

.PARAMETER LogFolder
    Dossier contenant les logs n8n (par défaut: n8n/logs).

.PARAMETER BackupFolder
    Dossier où stocker les sauvegardes (par défaut: n8n/backups).

.PARAMETER NoInteractive
    Exécute le script en mode non interactif (sans demander de confirmation).

.EXAMPLE
    .\maintenance.ps1
    Exécute toutes les tâches de maintenance avec les paramètres par défaut.

.EXAMPLE
    .\maintenance.ps1 -N8nRootFolder "C:\n8n" -NoInteractive
    Exécute toutes les tâches de maintenance dans le dossier spécifié sans demander de confirmation.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  27/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$N8nRootFolder = "n8n",
    
    [Parameter(Mandatory=$false)]
    [string]$WorkflowFolder = "n8n/data/.n8n/workflows",
    
    [Parameter(Mandatory=$false)]
    [string]$LogFolder = "n8n/logs",
    
    [Parameter(Mandatory=$false)]
    [string]$BackupFolder = "n8n/backups",
    
    [Parameter(Mandatory=$false)]
    [switch]$NoInteractive
)

# Fonction pour écrire dans le log
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec la couleur appropriée
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
    
    # Écrire dans le fichier de log de maintenance
    $maintenanceLogFile = Join-Path -Path $LogFolder -ChildPath "maintenance.log"
    
    # Créer le dossier de log s'il n'existe pas
    if (-not (Test-Path -Path $LogFolder)) {
        New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
    }
    
    Add-Content -Path $maintenanceLogFile -Value $logMessage
}

# Fonction pour exécuter un script de maintenance
function Invoke-MaintenanceScript {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory=$true)]
        [string]$ScriptName,
        
        [Parameter(Mandatory=$true)]
        [string]$Arguments
    )
    
    Write-Log "Exécution de $ScriptName..." -Level "INFO"
    
    try {
        # Vérifier si le script existe
        if (-not (Test-Path -Path $ScriptPath)) {
            Write-Log "Script non trouvé: $ScriptPath" -Level "ERROR"
            return $false
        }
        
        # Exécuter le script
        $scriptBlock = [ScriptBlock]::Create("& '$ScriptPath' $Arguments")
        $result = Invoke-Command -ScriptBlock $scriptBlock
        
        # Vérifier le code de retour
        if ($LASTEXITCODE -eq 0) {
            Write-Log "$ScriptName terminé avec succès" -Level "SUCCESS"
            return $true
        } else {
            Write-Log "$ScriptName terminé avec des erreurs (code: $LASTEXITCODE)" -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de l'exécution de $ScriptName: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale pour exécuter toutes les tâches de maintenance
function Invoke-Maintenance {
    param (
        [Parameter(Mandatory=$true)]
        [string]$N8nRootFolder,
        
        [Parameter(Mandatory=$true)]
        [string]$WorkflowFolder,
        
        [Parameter(Mandatory=$true)]
        [string]$LogFolder,
        
        [Parameter(Mandatory=$true)]
        [string]$BackupFolder,
        
        [Parameter(Mandatory=$true)]
        [bool]$NoInteractive
    )
    
    # Vérifier si les dossiers existent
    if (-not (Test-Path -Path $N8nRootFolder)) {
        Write-Log "Dossier racine n8n non trouvé: $N8nRootFolder" -Level "ERROR"
        return $false
    }
    
    # Créer les dossiers s'ils n'existent pas
    if (-not (Test-Path -Path $LogFolder)) {
        New-Item -Path $LogFolder -ItemType Directory -Force | Out-Null
        Write-Log "Dossier de logs créé: $LogFolder" -Level "SUCCESS"
    }
    
    if (-not (Test-Path -Path $BackupFolder)) {
        New-Item -Path $BackupFolder -ItemType Directory -Force | Out-Null
        Write-Log "Dossier de sauvegardes créé: $BackupFolder" -Level "SUCCESS"
    }
    
    # Chemin des scripts de maintenance
    $maintenancePath = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath ""
    
    # Définir les scripts de maintenance à exécuter
    $maintenanceScripts = @(
        @{
            Path = Join-Path -Path $maintenancePath -ChildPath "rotate-logs.ps1"
            Name = "Rotation des logs"
            Arguments = "-LogFolder `"$LogFolder`" -HistoryFolder `"$LogFolder/history`" -NoInteractive"
        },
        @{
            Path = Join-Path -Path $maintenancePath -ChildPath "backup-workflows.ps1"
            Name = "Sauvegarde des workflows"
            Arguments = "-WorkflowFolder `"$WorkflowFolder`" -BackupFolder `"$BackupFolder`" -NoInteractive"
        },
        @{
            Path = Join-Path -Path $maintenancePath -ChildPath "cleanup-temp.ps1"
            Name = "Nettoyage des fichiers temporaires"
            Arguments = "-N8nRootFolder `"$N8nRootFolder`" -NoInteractive"
        }
    )
    
    Write-Log "Début de la maintenance n8n" -Level "INFO"
    
    $successCount = 0
    $errorCount = 0
    
    # Exécuter chaque script de maintenance
    foreach ($script in $maintenanceScripts) {
        $success = Invoke-MaintenanceScript -ScriptPath $script.Path -ScriptName $script.Name -Arguments $script.Arguments
        
        if ($success) {
            $successCount++
        } else {
            $errorCount++
        }
    }
    
    Write-Log "Fin de la maintenance n8n" -Level "INFO"
    Write-Log "Résultat: $successCount tâches réussies, $errorCount tâches échouées" -Level $(if ($errorCount -eq 0) { "SUCCESS" } else { "WARNING" })
    
    return $errorCount -eq 0
}

# Exécuter la fonction principale
if ($MyInvocation.InvocationName -ne ".") {
    # Afficher les paramètres
    Write-Log "Paramètres:" -Level "INFO"
    Write-Log "  N8nRootFolder: $N8nRootFolder" -Level "INFO"
    Write-Log "  WorkflowFolder: $WorkflowFolder" -Level "INFO"
    Write-Log "  LogFolder: $LogFolder" -Level "INFO"
    Write-Log "  BackupFolder: $BackupFolder" -Level "INFO"
    
    # Demander confirmation si mode interactif
    if (-not $NoInteractive) {
        $confirmation = Read-Host "Voulez-vous exécuter toutes les tâches de maintenance? (O/N)"
        
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Log "Opération annulée par l'utilisateur" -Level "WARNING"
            exit
        }
    }
    
    # Exécuter la maintenance
    $success = Invoke-Maintenance -N8nRootFolder $N8nRootFolder -WorkflowFolder $WorkflowFolder -LogFolder $LogFolder -BackupFolder $BackupFolder -NoInteractive $NoInteractive
    
    if ($success) {
        exit 0
    } else {
        exit 1
    }
}

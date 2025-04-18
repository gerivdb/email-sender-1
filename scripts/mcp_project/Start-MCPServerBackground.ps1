#Requires -Version 5.1
<#
.SYNOPSIS
    Démarre le serveur MCP en arrière-plan.
.DESCRIPTION
    Ce script démarre le serveur MCP en arrière-plan et retourne le processus.
.EXAMPLE
    .\Start-MCPServerBackground.ps1
    Démarre le serveur MCP en arrière-plan.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-18
#>
[CmdletBinding()]
param ()

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
}

# Fonction principale
function Start-MCPServerBackground {
    [CmdletBinding()]
    param ()
    
    try {
        # Chemin vers le script du serveur MCP
        $serverPath = Join-Path -Path $PSScriptRoot -ChildPath "server.py"
        
        # Vérifier si le script du serveur MCP existe
        if (-not (Test-Path $serverPath)) {
            Write-Log "Script du serveur MCP introuvable à $serverPath" -Level "ERROR"
            return
        }
        
        # Vérifier si Python est installé
        if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
            Write-Log "Python n'est pas installé ou n'est pas dans le PATH" -Level "ERROR"
            return
        }
        
        # Vérifier si le port 8000 est déjà utilisé
        $portInUse = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
        if ($portInUse) {
            Write-Log "Le port 8000 est déjà utilisé par un autre processus" -Level "WARNING"
            Write-Log "Tentative d'arrêt du processus existant..." -Level "INFO"
            
            # Essayer de trouver le processus qui utilise le port 8000
            $process = Get-Process -Id $portInUse.OwningProcess -ErrorAction SilentlyContinue
            if ($process) {
                Write-Log "Processus trouvé : $($process.Name) (PID: $($process.Id))" -Level "INFO"
                
                # Demander confirmation avant d'arrêter le processus
                $confirmation = Read-Host "Voulez-vous arrêter ce processus ? (O/N)"
                if ($confirmation -eq "O") {
                    Stop-Process -Id $process.Id -Force
                    Write-Log "Processus arrêté" -Level "SUCCESS"
                }
                else {
                    Write-Log "Opération annulée" -Level "WARNING"
                    return
                }
            }
        }
        
        # Démarrer le serveur MCP en arrière-plan
        Write-Log "Démarrage du serveur MCP en arrière-plan..." -Level "INFO"
        
        # Créer un fichier de log pour le serveur
        $logPath = Join-Path -Path $PSScriptRoot -ChildPath "server.log"
        
        # Démarrer le processus en arrière-plan
        $process = Start-Process -FilePath "python" -ArgumentList $serverPath -NoNewWindow -PassThru -RedirectStandardOutput $logPath -RedirectStandardError $logPath
        
        # Vérifier si le processus a démarré
        if ($process) {
            Write-Log "Serveur MCP démarré avec succès (PID: $($process.Id))" -Level "SUCCESS"
            Write-Log "Logs disponibles dans $logPath" -Level "INFO"
            Write-Log "Serveur MCP accessible à l'adresse http://localhost:8000" -Level "INFO"
            Write-Log "Pour arrêter le serveur, exécutez : Stop-Process -Id $($process.Id)" -Level "INFO"
            
            # Retourner le processus
            return $process
        }
        else {
            Write-Log "Erreur lors du démarrage du serveur MCP" -Level "ERROR"
        }
    }
    catch {
        Write-Log "Erreur lors du démarrage du serveur MCP : $($_.Exception.Message)" -Level "ERROR"
    }
}

# Exécuter la fonction principale
Start-MCPServerBackground -Verbose

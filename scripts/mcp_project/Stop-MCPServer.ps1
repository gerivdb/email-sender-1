#Requires -Version 5.1
<#
.SYNOPSIS
    Arrête le serveur MCP.
.DESCRIPTION
    Ce script arrête le serveur MCP en trouvant le processus qui utilise le port 8000.
.EXAMPLE
    .\Stop-MCPServer.ps1
    Arrête le serveur MCP.
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
function Stop-MCPServer {
    [CmdletBinding()]
    param ()
    
    try {
        # Vérifier si le port 8000 est utilisé
        $portInUse = Get-NetTCPConnection -LocalPort 8000 -ErrorAction SilentlyContinue
        if ($portInUse) {
            # Trouver le processus qui utilise le port 8000
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
                }
            }
            else {
                Write-Log "Impossible de trouver le processus qui utilise le port 8000" -Level "ERROR"
            }
        }
        else {
            Write-Log "Aucun processus n'utilise le port 8000" -Level "WARNING"
            
            # Essayer de trouver un processus Python qui pourrait être le serveur MCP
            $pythonProcesses = Get-Process -Name python -ErrorAction SilentlyContinue
            if ($pythonProcesses) {
                Write-Log "Processus Python trouvés :" -Level "INFO"
                $pythonProcesses | ForEach-Object {
                    Write-Log "  - $($_.Name) (PID: $($_.Id))" -Level "INFO"
                }
                
                # Demander confirmation avant d'arrêter les processus
                $confirmation = Read-Host "Voulez-vous arrêter tous ces processus Python ? (O/N)"
                if ($confirmation -eq "O") {
                    $pythonProcesses | ForEach-Object {
                        Stop-Process -Id $_.Id -Force
                        Write-Log "Processus $($_.Name) (PID: $($_.Id)) arrêté" -Level "SUCCESS"
                    }
                }
                else {
                    Write-Log "Opération annulée" -Level "WARNING"
                }
            }
            else {
                Write-Log "Aucun processus Python trouvé" -Level "WARNING"
            }
        }
    }
    catch {
        Write-Log "Erreur lors de l'arrêt du serveur MCP : $($_.Exception.Message)" -Level "ERROR"
    }
}

# Exécuter la fonction principale
Stop-MCPServer -Verbose

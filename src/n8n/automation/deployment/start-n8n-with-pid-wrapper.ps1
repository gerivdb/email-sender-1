<#
.SYNOPSIS
    Script wrapper pour démarrer n8n avec gestion du PID.

.DESCRIPTION
    Ce script utilise le script de démarrage n8n existant et ajoute la gestion du PID.

.PARAMETER PidFile
    Chemin du fichier où le PID sera enregistré (par défaut: n8n.pid).

.PARAMETER LogFile
    Chemin du fichier de log (par défaut: n8n.log).

.PARAMETER ErrorLogFile
    Chemin du fichier de log d'erreurs (par défaut: n8nError.log).

.EXAMPLE
    .\start-n8n-with-pid-wrapper.ps1 -PidFile "custom.pid"

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$PidFile = "n8n.pid",
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile = "n8n.log",
    
    [Parameter(Mandatory=$false)]
    [string]$ErrorLogFile = "n8nError.log"
)

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$startScriptPath = Join-Path -Path $rootPath -ChildPath "start-n8n-no-auth.cmd"

# Définir les chemins des fichiers PID et logs
$PidFile = Join-Path -Path $n8nPath -ChildPath $PidFile
$LogFile = Join-Path -Path $n8nPath -ChildPath $LogFile
$ErrorLogFile = Join-Path -Path $n8nPath -ChildPath $ErrorLogFile

# Fonction pour nettoyer les ressources en cas d'erreur
function Clear-Resources {
    param (
        [Parameter(Mandatory=$false)]
        [int]$ProcessId = $null
    )
    
    # Arrêter le processus si spécifié
    if ($null -ne $ProcessId) {
        try {
            Stop-Process -Id $ProcessId -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Warning "Impossible d'arrêter le processus $ProcessId : $_"
        }
    }
    
    # Supprimer le fichier PID s'il existe
    if (Test-Path -Path $PidFile) {
        Remove-Item -Path $PidFile -Force -ErrorAction SilentlyContinue
    }
}

# Vérifier si le fichier PID existe
if (Test-Path -Path $PidFile) {
    $pidValue = Get-Content -Path $PidFile
    
    # Vérifier si le processus existe
    try {
        $process = Get-Process -Id $pidValue -ErrorAction SilentlyContinue
        if ($null -ne $process) {
            Write-Error "n8n est déjà en cours d'exécution avec le PID $pidValue. Utilisez stop-n8n.ps1 pour l'arrêter d'abord."
            exit 1
        }
    } catch {
        # Le processus n'existe pas, supprimer le fichier PID obsolète
        Remove-Item -Path $PidFile -Force
    }
}

# Afficher les informations de démarrage
Write-Host "`nDémarrage de n8n avec gestion du PID..." -ForegroundColor Cyan
Write-Host "Script de démarrage: $startScriptPath"
Write-Host "Fichier PID: $PidFile"
Write-Host "Fichier log: $LogFile"
Write-Host "Fichier log d'erreurs: $ErrorLogFile"
Write-Host "`nAppuyez sur Ctrl+C pour arrêter n8n`n"

try {
    # Démarrer n8n en arrière-plan
    $process = Start-Process -FilePath $startScriptPath -NoNewWindow -PassThru -RedirectStandardOutput $LogFile -RedirectStandardError $ErrorLogFile
    
    # Enregistrer le PID
    $process.Id | Out-File -FilePath $PidFile -Encoding utf8 -Force
    Write-Host "n8n démarré avec le PID: $($process.Id)" -ForegroundColor Green
    
    # Attendre que n8n soit accessible
    $maxRetries = 30
    $retryCount = 0
    $n8nReady = $false
    
    Write-Host "Attente du démarrage de n8n..." -ForegroundColor Yellow
    
    while (-not $n8nReady -and $retryCount -lt $maxRetries) {
        Start-Sleep -Seconds 1
        $retryCount++
        
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:5678/healthz" -Method Get -ErrorAction SilentlyContinue
            if ($response.status -eq "ok") {
                $n8nReady = $true
                Write-Host "n8n est prêt et accessible!" -ForegroundColor Green
            }
        } catch {
            # n8n n'est pas encore prêt
            Write-Host "." -NoNewline
        }
        
        # Vérifier si le processus est toujours en cours d'exécution
        if ($process.HasExited) {
            Write-Error "n8n s'est arrêté de manière inattendue. Consultez les logs pour plus d'informations."
            Clear-Resources
            exit 1
        }
    }
    
    if (-not $n8nReady) {
        Write-Error "n8n n'a pas démarré correctement après $maxRetries tentatives."
        Clear-Resources -ProcessId $process.Id
        exit 1
    }
    
    # Afficher l'URL d'accès
    Write-Host "`nn8n est maintenant accessible à l'adresse: http://localhost:5678" -ForegroundColor Green
    Write-Host "PID: $($process.Id) (enregistré dans $PidFile)"
    Write-Host "Logs: $LogFile"
    Write-Host "Logs d'erreurs: $ErrorLogFile"
    Write-Host "`nPour arrêter n8n, exécutez: .\stop-n8n.ps1"
    
    # Attendre que le processus se termine
    $process.WaitForExit()
    
    # Nettoyer les ressources
    Clear-Resources
    
    Write-Host "n8n s'est arrêté." -ForegroundColor Yellow
} catch {
    Write-Error "Erreur lors du démarrage de n8n: $_"
    Clear-Resources -ProcessId $process.Id
    exit 1
}

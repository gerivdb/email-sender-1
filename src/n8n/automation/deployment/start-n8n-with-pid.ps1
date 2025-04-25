<#
.SYNOPSIS
    Script de démarrage n8n avec gestion du PID.

.DESCRIPTION
    Ce script démarre n8n et enregistre son PID dans un fichier pour permettre
    un arrêt propre ultérieur. Il gère également les erreurs de démarrage.

.PARAMETER Port
    Port sur lequel n8n sera accessible (par défaut: 5678).

.PARAMETER PidFile
    Chemin du fichier où le PID sera enregistré (par défaut: n8n.pid).

.PARAMETER LogFile
    Chemin du fichier de log (par défaut: n8n.log).

.PARAMETER ErrorLogFile
    Chemin du fichier de log d'erreurs (par défaut: n8nError.log).

.EXAMPLE
    .\start-n8n-with-pid.ps1 -Port 5679 -PidFile "custom.pid"

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [int]$Port = 5678,

    [Parameter(Mandatory = $false)]
    [string]$PidFile = "n8n.pid",

    [Parameter(Mandatory = $false)]
    [string]$LogFile = "n8n.log",

    [Parameter(Mandatory = $false)]
    [string]$ErrorLogFile = "n8nError.log"
)

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$dataPath = Join-Path -Path $n8nPath -ChildPath "data"
$databasePath = Join-Path -Path $dataPath -ChildPath ".n8n"
$databaseFile = Join-Path -Path $databasePath -ChildPath "database.sqlite"
$envPath = Join-Path -Path $n8nPath -ChildPath ".env"

# Définir les chemins des fichiers PID et logs
$PidFile = Join-Path -Path $n8nPath -ChildPath $PidFile
$LogFile = Join-Path -Path $n8nPath -ChildPath $LogFile
$ErrorLogFile = Join-Path -Path $n8nPath -ChildPath $ErrorLogFile

# Fonction pour vérifier si le port est disponible
function Test-PortAvailable {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Port
    )

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $result = $tcpClient.BeginConnect("127.0.0.1", $Port, $null, $null)
        $success = $result.AsyncWaitHandle.WaitOne(100)

        if ($success) {
            $tcpClient.EndConnect($result)
            $tcpClient.Close()
            return $false  # Port est utilisé
        } else {
            $tcpClient.Close()
            return $true   # Port est disponible
        }
    } catch {
        return $true  # En cas d'erreur, on suppose que le port est disponible
    }
}

# Fonction pour vérifier si n8n est déjà en cours d'exécution
function Test-N8nRunning {
    # Vérifier si le fichier PID existe
    if (Test-Path -Path $PidFile) {
        $pidValue = Get-Content -Path $PidFile

        # Vérifier si le processus existe
        try {
            $process = Get-Process -Id $pidValue -ErrorAction SilentlyContinue
            if ($null -ne $process) {
                return $true
            }
        } catch {
            # Le processus n'existe pas
        }

        # Supprimer le fichier PID obsolète
        Remove-Item -Path $PidFile -Force
    }

    # Vérifier si le port est utilisé
    return -not (Test-PortAvailable -Port $Port)
}

# Fonction pour nettoyer les ressources en cas d'erreur
function Clear-Resources {
    param (
        [Parameter(Mandatory = $false)]
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

# Vérifier si n8n est déjà en cours d'exécution
if (Test-N8nRunning) {
    Write-Error "n8n est déjà en cours d'exécution. Utilisez stop-n8n.ps1 pour l'arrêter d'abord."
    exit 1
}

# Vérifier si le port est disponible
if (-not (Test-PortAvailable -Port $Port)) {
    Write-Error "Le port $Port est déjà utilisé. Veuillez spécifier un autre port."
    exit 1
}

# Vérifier si le dossier de base de données existe
if (-not (Test-Path -Path $databasePath)) {
    Write-Host "Création du dossier de base de données: $databasePath" -ForegroundColor Yellow
    New-Item -Path $databasePath -ItemType Directory -Force | Out-Null
}

# Vérifier si le fichier .env existe
if (-not (Test-Path -Path $envPath)) {
    Write-Error "Le fichier .env n'existe pas: $envPath"
    exit 1
}

# Charger les variables d'environnement
$envContent = Get-Content -Path $envPath
foreach ($line in $envContent) {
    if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.StartsWith("#")) {
        $key, $value = $line.Split("=", 2)
        [Environment]::SetEnvironmentVariable($key, $value, "Process")
    }
}

# Ajouter des variables d'environnement supplémentaires
[Environment]::SetEnvironmentVariable("N8N_PORT", $Port, "Process")
[Environment]::SetEnvironmentVariable("N8N_DATABASE_SQLITE_PATH", $databaseFile, "Process")
[Environment]::SetEnvironmentVariable("N8N_USER_FOLDER", $dataPath, "Process")
[Environment]::SetEnvironmentVariable("N8N_BASIC_AUTH_ACTIVE", "false", "Process")
[Environment]::SetEnvironmentVariable("N8N_USER_MANAGEMENT_DISABLED", "true", "Process")
[Environment]::SetEnvironmentVariable("N8N_AUTH_DISABLED", "true", "Process")
[Environment]::SetEnvironmentVariable("N8N_DIAGNOSTICS_ENABLED", "false", "Process")
[Environment]::SetEnvironmentVariable("N8N_DIAGNOSTICS_CONFIG_ENABLED", "false", "Process")
[Environment]::SetEnvironmentVariable("N8N_LOG_LEVEL", "debug", "Process")

# Afficher les informations de démarrage
Write-Host "`nDémarrage de n8n avec gestion du PID..." -ForegroundColor Cyan
Write-Host "URL: $($env:N8N_PROTOCOL)://$($env:N8N_HOST):$Port$($env:N8N_PATH)"
Write-Host "Dossier des workflows: $($env:N8N_WORKFLOW_IMPORT_PATH)"
Write-Host "Dossier des données: $dataPath"
Write-Host "Base de données: $databaseFile"
Write-Host "Fichier PID: $PidFile"
Write-Host "Fichier log: $LogFile"
Write-Host "Fichier log d'erreurs: $ErrorLogFile"
Write-Host "`nAppuyez sur Ctrl+C pour arrêter n8n`n"

try {
    # Démarrer n8n en arrière-plan
    $process = Start-Process -FilePath "npx" -ArgumentList "n8n", "start" -NoNewWindow -PassThru -RedirectStandardOutput $LogFile -RedirectStandardError $ErrorLogFile

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
            $response = Invoke-RestMethod -Uri "http://localhost:$Port/healthz" -Method Get -ErrorAction SilentlyContinue
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
    Write-Host "`nn8n est maintenant accessible à l'adresse: http://localhost:$Port" -ForegroundColor Green
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

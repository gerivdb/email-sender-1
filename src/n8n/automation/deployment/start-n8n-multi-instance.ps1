<#
.SYNOPSIS
    Script de démarrage n8n avec gestion de multi-instances et contrôle de port.

.DESCRIPTION
    Ce script permet de démarrer plusieurs instances de n8n sur différents ports,
    avec gestion du PID et vérification de la disponibilité des ports.

.PARAMETER InstanceName
    Nom de l'instance n8n (par défaut: "default").

.PARAMETER Port
    Port sur lequel n8n sera accessible (par défaut: 5678).

.PARAMETER BaseFolder
    Dossier de base pour les données de l'instance (par défaut: dossier data standard).

.PARAMETER PidFile
    Chemin du fichier où le PID sera enregistré (par défaut: n8n-{InstanceName}.pid).

.PARAMETER LogFile
    Chemin du fichier de log (par défaut: n8n-{InstanceName}.log).

.PARAMETER ErrorLogFile
    Chemin du fichier de log d'erreurs (par défaut: n8n-{InstanceName}-error.log).

.EXAMPLE
    .\start-n8n-multi-instance.ps1 -InstanceName "dev" -Port 5679

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  21/04/2025
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$InstanceName = "default",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 5678,
    
    [Parameter(Mandatory=$false)]
    [string]$BaseFolder = "",
    
    [Parameter(Mandatory=$false)]
    [string]$PidFile = "",
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ErrorLogFile = ""
)

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$instancesPath = Join-Path -Path $n8nPath -ChildPath "instances"

# Créer le dossier instances s'il n'existe pas
if (-not (Test-Path -Path $instancesPath)) {
    New-Item -Path $instancesPath -ItemType Directory -Force | Out-Null
}

# Définir les chemins spécifiques à l'instance
$instancePath = Join-Path -Path $instancesPath -ChildPath $InstanceName
if (-not (Test-Path -Path $instancePath)) {
    New-Item -Path $instancePath -ItemType Directory -Force | Out-Null
}

# Définir les chemins des fichiers PID et logs
if ([string]::IsNullOrEmpty($PidFile)) {
    $PidFile = Join-Path -Path $instancePath -ChildPath "n8n-$InstanceName.pid"
}

if ([string]::IsNullOrEmpty($LogFile)) {
    $LogFile = Join-Path -Path $instancePath -ChildPath "n8n-$InstanceName.log"
}

if ([string]::IsNullOrEmpty($ErrorLogFile)) {
    $ErrorLogFile = Join-Path -Path $instancePath -ChildPath "n8n-$InstanceName-error.log"
}

# Définir le dossier de base pour les données de l'instance
if ([string]::IsNullOrEmpty($BaseFolder)) {
    $BaseFolder = Join-Path -Path $instancePath -ChildPath "data"
}

if (-not (Test-Path -Path $BaseFolder)) {
    New-Item -Path $BaseFolder -ItemType Directory -Force | Out-Null
}

# Créer les sous-dossiers nécessaires
$databasePath = Join-Path -Path $BaseFolder -ChildPath ".n8n"
if (-not (Test-Path -Path $databasePath)) {
    New-Item -Path $databasePath -ItemType Directory -Force | Out-Null
}

$workflowsPath = Join-Path -Path $BaseFolder -ChildPath "workflows"
if (-not (Test-Path -Path $workflowsPath)) {
    New-Item -Path $workflowsPath -ItemType Directory -Force | Out-Null
}

# Définir le chemin de la base de données
$databaseFile = Join-Path -Path $databasePath -ChildPath "database.sqlite"

# Fonction pour vérifier si le port est disponible
function Test-PortAvailable {
    param (
        [Parameter(Mandatory=$true)]
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

# Fonction pour trouver un port disponible
function Find-AvailablePort {
    param (
        [Parameter(Mandatory=$true)]
        [int]$StartPort,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxPort = 5700
    )
    
    $currentPort = $StartPort
    
    while ($currentPort -le $MaxPort) {
        if (Test-PortAvailable -Port $currentPort) {
            return $currentPort
        }
        
        $currentPort++
    }
    
    return 0  # Aucun port disponible
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

# Vérifier si n8n est déjà en cours d'exécution
if (Test-N8nRunning) {
    Write-Error "n8n est déjà en cours d'exécution pour l'instance $InstanceName. Utilisez stop-n8n-instance.ps1 pour l'arrêter d'abord."
    exit 1
}

# Vérifier si le port est disponible
if (-not (Test-PortAvailable -Port $Port)) {
    $newPort = Find-AvailablePort -StartPort ($Port + 1)
    
    if ($newPort -eq 0) {
        Write-Error "Aucun port disponible entre $Port et 5700. Veuillez spécifier un autre port."
        exit 1
    }
    
    Write-Warning "Le port $Port est déjà utilisé. Utilisation du port $newPort à la place."
    $Port = $newPort
}

# Créer le fichier .env pour l'instance
$envPath = Join-Path -Path $instancePath -ChildPath ".env"
$envContent = @"
# Configuration n8n pour l'instance $InstanceName
N8N_PORT=$Port
N8N_PROTOCOL=http
N8N_HOST=localhost
N8N_PATH=/

# Dossiers de données
N8N_USER_FOLDER=$BaseFolder
N8N_DATABASE_SQLITE_PATH=$databaseFile
N8N_DIAGNOSTICS_ENABLED=false
N8N_DIAGNOSTICS_CONFIG_ENABLED=false

# Authentification
N8N_BASIC_AUTH_ACTIVE=false
N8N_USER_MANAGEMENT_DISABLED=true
N8N_AUTH_DISABLED=true

# Workflows
N8N_WORKFLOW_IMPORT_PATH=$workflowsPath
N8N_IMPORT_WORKFLOW_AUTO_ENABLE=true
N8N_IMPORT_WORKFLOW_AUTO_UPDATE=true

# Autres paramètres
GENERIC_TIMEZONE=Europe/Paris
N8N_DEFAULT_LOCALE=fr
N8N_LOG_LEVEL=debug
N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true
"@

Set-Content -Path $envPath -Value $envContent -Encoding UTF8

# Afficher les informations de démarrage
Write-Host "`nDémarrage de n8n (instance: $InstanceName)..." -ForegroundColor Cyan
Write-Host "URL: http://localhost:$Port/"
Write-Host "Dossier des données: $BaseFolder"
Write-Host "Base de données: $databaseFile"
Write-Host "Fichier PID: $PidFile"
Write-Host "Fichier log: $LogFile"
Write-Host "Fichier log d'erreurs: $ErrorLogFile"
Write-Host "`nAppuyez sur Ctrl+C pour arrêter n8n`n"

try {
    # Charger les variables d'environnement
    $envContent = Get-Content -Path $envPath
    foreach ($line in $envContent) {
        if (-not [string]::IsNullOrWhiteSpace($line) -and -not $line.StartsWith("#")) {
            $key, $value = $line.Split("=", 2)
            [Environment]::SetEnvironmentVariable($key, $value, "Process")
        }
    }
    
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
    Write-Host "`nn8n (instance: $InstanceName) est maintenant accessible à l'adresse: http://localhost:$Port" -ForegroundColor Green
    Write-Host "PID: $($process.Id) (enregistré dans $PidFile)"
    Write-Host "Logs: $LogFile"
    Write-Host "Logs d'erreurs: $ErrorLogFile"
    Write-Host "`nPour arrêter n8n, exécutez: .\stop-n8n-instance.ps1 -InstanceName `"$InstanceName`""
    
    # Attendre que le processus se termine
    $process.WaitForExit()
    
    # Nettoyer les ressources
    Clear-Resources
    
    Write-Host "n8n (instance: $InstanceName) s'est arrêté." -ForegroundColor Yellow
} catch {
    Write-Error "Erreur lors du démarrage de n8n: $_"
    Clear-Resources -ProcessId $process.Id
    exit 1
}

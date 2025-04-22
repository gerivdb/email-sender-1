<#
.SYNOPSIS
    Script pour démarrer n8n avec synchronisation IDE.

.DESCRIPTION
    Ce script démarre n8n et configure la synchronisation automatique des workflows avec l'IDE.
    Il utilise les scripts de synchronisation existants pour maintenir les workflows à jour.

.PARAMETER NoAuth
    Désactive l'authentification n8n.

.PARAMETER Port
    Port sur lequel n8n sera accessible (par défaut: 5678).

.PARAMETER SyncInterval
    Intervalle de synchronisation en secondes (par défaut: 60).

.EXAMPLE
    .\start-n8n-with-ide-sync.ps1
    .\start-n8n-with-ide-sync.ps1 -NoAuth
    .\start-n8n-with-ide-sync.ps1 -Port 8080 -SyncInterval 30
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$NoAuth,
    
    [Parameter(Mandatory = $false)]
    [int]$Port = 5678,
    
    [Parameter(Mandatory = $false)]
    [int]$SyncInterval = 60
)

# Définir les chemins
$rootPath = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$n8nConfigPath = Join-Path -Path $configPath -ChildPath "n8n-config.json"
$syncScriptPath = Join-Path -Path $rootPath -ChildPath "scripts\sync\sync-workflows.ps1"

# Vérifier si le fichier de configuration existe
if (-not (Test-Path -Path $n8nConfigPath)) {
    Write-Error "Le fichier de configuration n8n-config.json n'existe pas."
    exit 1
}

# Lire la configuration
$config = Get-Content -Path $n8nConfigPath -Raw | ConvertFrom-Json

# Mettre à jour le port dans la configuration
$config.port = $Port

# Enregistrer la configuration mise à jour
$configJson = $config | ConvertTo-Json -Depth 10
Set-Content -Path $n8nConfigPath -Value $configJson -Encoding UTF8

# Fonction pour vérifier si n8n est en cours d'exécution
function Test-N8nRunning {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter(Mandatory = $false)]
        [string]$Hostname = "localhost"
    )
    
    try {
        $response = Invoke-WebRequest -Uri "http://$Hostname:$Port/healthz" -Method Get -TimeoutSec 2 -ErrorAction SilentlyContinue
        return ($response.StatusCode -eq 200)
    } catch {
        return $false
    }
}

# Fonction pour démarrer n8n
function Start-N8n {
    param (
        [Parameter(Mandatory = $false)]
        [switch]$NoAuth
    )
    
    $startScriptPath = Join-Path -Path $rootPath -ChildPath "scripts\start-n8n.ps1"
    
    if ($NoAuth) {
        & $startScriptPath -NoAuth -Port $Port
    } else {
        & $startScriptPath -Port $Port
    }
}

# Fonction pour synchroniser les workflows
function Sync-Workflows {
    & $syncScriptPath -Direction "both" -Environment "all"
}

# Démarrer n8n
Write-Host "Démarrage de n8n sur le port $Port..."
if ($NoAuth) {
    Start-N8n -NoAuth
} else {
    Start-N8n
}

# Attendre que n8n soit prêt
$maxWaitTime = 60 # secondes
$waitTime = 0
$interval = 5 # secondes
$ready = $false

Write-Host "Attente du démarrage de n8n..."
while (-not $ready -and $waitTime -lt $maxWaitTime) {
    if (Test-N8nRunning -Port $Port) {
        $ready = $true
    } else {
        Start-Sleep -Seconds $interval
        $waitTime += $interval
        Write-Host "En attente... ($waitTime/$maxWaitTime secondes)"
    }
}

if (-not $ready) {
    Write-Error "n8n n'a pas démarré dans le délai imparti."
    exit 1
}

Write-Host "n8n est prêt! Accessible à l'adresse: http://localhost:$Port"

# Synchroniser les workflows initialement
Write-Host "Synchronisation initiale des workflows..."
Sync-Workflows

# Configurer la synchronisation périodique
Write-Host "Configuration de la synchronisation périodique des workflows (toutes les $SyncInterval secondes)..."

try {
    while ($true) {
        Start-Sleep -Seconds $SyncInterval
        
        # Vérifier si n8n est toujours en cours d'exécution
        if (-not (Test-N8nRunning -Port $Port)) {
            Write-Warning "n8n n'est plus en cours d'exécution. Redémarrage..."
            if ($NoAuth) {
                Start-N8n -NoAuth
            } else {
                Start-N8n
            }
            
            # Attendre que n8n soit prêt
            $waitTime = 0
            $ready = $false
            
            while (-not $ready -and $waitTime -lt $maxWaitTime) {
                if (Test-N8nRunning -Port $Port) {
                    $ready = $true
                } else {
                    Start-Sleep -Seconds $interval
                    $waitTime += $interval
                }
            }
            
            if (-not $ready) {
                Write-Error "n8n n'a pas redémarré dans le délai imparti."
                exit 1
            }
            
            Write-Host "n8n a été redémarré."
        }
        
        # Synchroniser les workflows
        Write-Host "Synchronisation périodique des workflows..."
        Sync-Workflows
    }
} catch {
    Write-Error "Erreur lors de la synchronisation des workflows : $_"
} finally {
    Write-Host "Arrêt de la synchronisation des workflows."
}

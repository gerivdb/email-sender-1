# Start-BackgroundCleanup.ps1
# Script pour démarrer le processus de nettoyage en arrière-plan des points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigName = "default",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "TimeBasedRetention", "VersionBasedRetention", "ImportanceBasedRetention", "UsageBasedRetention", "CompositeRetention")]
    [string[]]$PolicyTypes = @("All"),
    
    [Parameter(Mandatory = $false)]
    [int]$IntervalMinutes = 60,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxRunTimeMinutes = 1440,
    
    [Parameter(Mandatory = $false)]
    [switch]$RunOnce,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Importer le script d'invocation des politiques de rétention
$retentionPoliciesPath = Join-Path -Path $parentPath -ChildPath "retention\Invoke-RetentionPolicies.ps1"

if (Test-Path -Path $retentionPoliciesPath) {
    . $retentionPoliciesPath
} else {
    Write-Log "Required script not found: Invoke-RetentionPolicies.ps1" -Level "Error"
    exit 1
}

# Fonction pour obtenir le chemin du fichier de verrouillage
function Get-LockFilePath {
    [CmdletBinding()]
    param()
    
    $lockPath = Join-Path -Path $parentPath -ChildPath "locks"
    
    if (-not (Test-Path -Path $lockPath)) {
        New-Item -Path $lockPath -ItemType Directory -Force | Out-Null
    }
    
    return Join-Path -Path $lockPath -ChildPath "cleanup.lock"
}

# Fonction pour vérifier si un processus de nettoyage est déjà en cours
function Test-CleanupRunning {
    [CmdletBinding()]
    param()
    
    $lockFilePath = Get-LockFilePath
    
    if (Test-Path -Path $lockFilePath) {
        try {
            $lockInfo = Get-Content -Path $lockFilePath -Raw | ConvertFrom-Json
            
            # Vérifier si le processus existe toujours
            $process = Get-Process -Id $lockInfo.process_id -ErrorAction SilentlyContinue
            
            if ($null -ne $process) {
                # Vérifier si le processus est toujours en cours d'exécution
                $startTime = [DateTime]::Parse($lockInfo.start_time)
                $runTime = (Get-Date) - $startTime
                
                if ($runTime.TotalMinutes -lt $lockInfo.max_run_time_minutes) {
                    return $true
                } else {
                    Write-Log "Cleanup process exceeded maximum run time. Considering it as stalled." -Level "Warning"
                    return $false
                }
            } else {
                Write-Log "Cleanup process no longer exists. Lock file is stale." -Level "Warning"
                return $false
            }
        } catch {
            Write-Log "Error checking cleanup lock: $_" -Level "Error"
            return $false
        }
    }
    
    return $false
}

# Fonction pour créer un fichier de verrouillage
function New-LockFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [int]$MaxRunTimeMinutes
    )
    
    $lockFilePath = Get-LockFilePath
    
    try {
        $lockInfo = @{
            process_id = $PID
            start_time = (Get-Date).ToString("o")
            max_run_time_minutes = $MaxRunTimeMinutes
            hostname = [Environment]::MachineName
            username = [Environment]::UserName
        }
        
        $lockInfo | ConvertTo-Json | Out-File -FilePath $lockFilePath -Encoding UTF8
        Write-Log "Created cleanup lock file: $lockFilePath" -Level "Debug"
        return $true
    } catch {
        Write-Log "Error creating cleanup lock file: $_" -Level "Error"
        return $false
    }
}

# Fonction pour supprimer le fichier de verrouillage
function Remove-LockFile {
    [CmdletBinding()]
    param()
    
    $lockFilePath = Get-LockFilePath
    
    if (Test-Path -Path $lockFilePath) {
        try {
            Remove-Item -Path $lockFilePath -Force
            Write-Log "Removed cleanup lock file: $lockFilePath" -Level "Debug"
            return $true
        } catch {
            Write-Log "Error removing cleanup lock file: $_" -Level "Error"
            return $false
        }
    }
    
    return $true
}

# Fonction pour exécuter le nettoyage
function Invoke-Cleanup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "TimeBasedRetention", "VersionBasedRetention", "ImportanceBasedRetention", "UsageBasedRetention", "CompositeRetention")]
        [string[]]$PolicyTypes = @("All"),
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    Write-Log "Starting cleanup process" -Level "Info"
    
    # Exécuter les politiques de rétention
    try {
        $result = Invoke-RetentionPolicies -ConfigName $ConfigName -PolicyTypes $PolicyTypes -Force:$Force
        
        if ($result) {
            Write-Log "Cleanup completed successfully" -Level "Info"
            return $true
        } else {
            Write-Log "Cleanup completed with errors" -Level "Warning"
            return $false
        }
    } catch {
        Write-Log "Error during cleanup: $_" -Level "Error"
        return $false
    }
}

# Fonction pour démarrer le processus de nettoyage en arrière-plan
function Start-BackgroundCleanup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "TimeBasedRetention", "VersionBasedRetention", "ImportanceBasedRetention", "UsageBasedRetention", "CompositeRetention")]
        [string[]]$PolicyTypes = @("All"),
        
        [Parameter(Mandatory = $false)]
        [int]$IntervalMinutes = 60,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRunTimeMinutes = 1440,
        
        [Parameter(Mandatory = $false)]
        [switch]$RunOnce,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si un processus de nettoyage est déjà en cours
    if (Test-CleanupRunning) {
        if (-not $Force) {
            Write-Log "Cleanup process is already running. Use -Force to override." -Level "Warning"
            return $false
        } else {
            Write-Log "Forcing cleanup despite another process running" -Level "Warning"
            Remove-LockFile
        }
    }
    
    # Créer le fichier de verrouillage
    $lockCreated = New-LockFile -MaxRunTimeMinutes $MaxRunTimeMinutes
    
    if (-not $lockCreated) {
        Write-Log "Failed to create lock file. Aborting cleanup." -Level "Error"
        return $false
    }
    
    # Initialiser les compteurs
    $successCount = 0
    $errorCount = 0
    $iterationCount = 0
    $startTime = Get-Date
    
    try {
        # Boucle principale
        do {
            $iterationCount++
            $iterationStart = Get-Date
            
            Write-Log "Starting cleanup iteration $iterationCount" -Level "Info"
            
            # Exécuter le nettoyage
            $result = Invoke-Cleanup -ConfigName $ConfigName -PolicyTypes $PolicyTypes -Force:$Force
            
            if ($result) {
                $successCount++
            } else {
                $errorCount++
            }
            
            # Calculer le temps écoulé
            $iterationEnd = Get-Date
            $iterationDuration = $iterationEnd - $iterationStart
            $totalDuration = $iterationEnd - $startTime
            
            Write-Log "Cleanup iteration $iterationCount completed in $($iterationDuration.TotalSeconds) seconds" -Level "Info"
            
            # Vérifier si nous devons continuer
            if ($RunOnce) {
                break
            }
            
            if ($totalDuration.TotalMinutes -ge $MaxRunTimeMinutes) {
                Write-Log "Maximum run time reached. Stopping cleanup process." -Level "Info"
                break
            }
            
            # Attendre l'intervalle spécifié
            $sleepSeconds = [Math]::Max(1, $IntervalMinutes * 60 - $iterationDuration.TotalSeconds)
            Write-Log "Waiting $sleepSeconds seconds until next cleanup iteration" -Level "Debug"
            Start-Sleep -Seconds $sleepSeconds
            
        } while ($true)
    } finally {
        # Supprimer le fichier de verrouillage
        Remove-LockFile
    }
    
    # Afficher le résumé
    Write-Log "Background cleanup process completed: $successCount successful iterations, $errorCount errors" -Level "Info"
    
    return $errorCount -eq 0
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Start-BackgroundCleanup -ConfigName $ConfigName -PolicyTypes $PolicyTypes -IntervalMinutes $IntervalMinutes -MaxRunTimeMinutes $MaxRunTimeMinutes -RunOnce:$RunOnce -Force:$Force
}

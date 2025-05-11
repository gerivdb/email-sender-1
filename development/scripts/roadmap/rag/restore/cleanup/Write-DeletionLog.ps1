# Write-DeletionLog.ps1
# Script pour journaliser les suppressions de points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$RestorePointId,
    
    [Parameter(Mandatory = $false)]
    [string]$RestorePointName = "",
    
    [Parameter(Mandatory = $false)]
    [string]$RestorePointType = "",
    
    [Parameter(Mandatory = $false)]
    [string]$DeletionReason = "Retention policy",
    
    [Parameter(Mandatory = $false)]
    [string]$PolicyName = "",
    
    [Parameter(Mandatory = $false)]
    [hashtable]$AdditionalInfo = @{},
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "Both")]
    [string]$LogFormat = "Both",
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeContent,
    
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

# Fonction pour obtenir le chemin du répertoire des journaux
function Get-LogsPath {
    [CmdletBinding()]
    param()
    
    $logsPath = Join-Path -Path $rootPath -ChildPath "logs"
    
    if (-not (Test-Path -Path $logsPath)) {
        New-Item -Path $logsPath -ItemType Directory -Force | Out-Null
    }
    
    $deletionLogsPath = Join-Path -Path $logsPath -ChildPath "deletions"
    
    if (-not (Test-Path -Path $deletionLogsPath)) {
        New-Item -Path $deletionLogsPath -ItemType Directory -Force | Out-Null
    }
    
    return $deletionLogsPath
}

# Fonction pour obtenir le chemin du fichier de journal JSON
function Get-JsonLogPath {
    [CmdletBinding()]
    param()
    
    $logsPath = Get-LogsPath
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    return Join-Path -Path $logsPath -ChildPath "deletion_log_$currentDate.json"
}

# Fonction pour obtenir le chemin du fichier de journal CSV
function Get-CsvLogPath {
    [CmdletBinding()]
    param()
    
    $logsPath = Get-LogsPath
    $currentDate = Get-Date -Format "yyyy-MM-dd"
    return Join-Path -Path $logsPath -ChildPath "deletion_log_$currentDate.csv"
}

# Fonction pour créer un objet de journal
function New-LogEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RestorePointId,
        
        [Parameter(Mandatory = $false)]
        [string]$RestorePointName = "",
        
        [Parameter(Mandatory = $false)]
        [string]$RestorePointType = "",
        
        [Parameter(Mandatory = $false)]
        [string]$DeletionReason = "Retention policy",
        
        [Parameter(Mandatory = $false)]
        [string]$PolicyName = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalInfo = @{},
        
        [Parameter(Mandatory = $false)]
        [object]$Content = $null
    )
    
    $entry = @{
        id = [Guid]::NewGuid().ToString()
        timestamp = (Get-Date).ToString("o")
        restore_point = @{
            id = $RestorePointId
            name = $RestorePointName
            type = $RestorePointType
        }
        deletion = @{
            reason = $DeletionReason
            policy = $PolicyName
            deleted_by = [Environment]::UserName
            hostname = [Environment]::MachineName
        }
        additional_info = $AdditionalInfo
    }
    
    if ($null -ne $Content) {
        $entry.content = $Content
    }
    
    return $entry
}

# Fonction pour écrire un journal au format JSON
function Write-JsonLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$LogEntry
    )
    
    $jsonLogPath = Get-JsonLogPath
    
    # Charger le journal existant ou créer un nouveau
    if (Test-Path -Path $jsonLogPath) {
        try {
            $log = Get-Content -Path $jsonLogPath -Raw | ConvertFrom-Json
            
            # Vérifier si le journal est un tableau
            if (-not ($log -is [array])) {
                $log = @($log)
            }
        } catch {
            Write-Log "Error loading JSON log: $($_.Exception.Message). Creating new log." -Level "Warning"
            $log = @()
        }
    } else {
        $log = @()
    }
    
    # Ajouter la nouvelle entrée
    $log += $LogEntry
    
    # Sauvegarder le journal
    try {
        $log | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonLogPath -Encoding UTF8
        Write-Log "Added entry to JSON log: $jsonLogPath" -Level "Debug"
        return $true
    } catch {
        Write-Log "Error writing to JSON log: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Fonction pour écrire un journal au format CSV
function Write-CsvLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$LogEntry
    )
    
    $csvLogPath = Get-CsvLogPath
    
    # Créer un objet CSV à partir de l'entrée de journal
    $csvEntry = [PSCustomObject]@{
        LogId = $LogEntry.id
        Timestamp = $LogEntry.timestamp
        RestorePointId = $LogEntry.restore_point.id
        RestorePointName = $LogEntry.restore_point.name
        RestorePointType = $LogEntry.restore_point.type
        DeletionReason = $LogEntry.deletion.reason
        PolicyName = $LogEntry.deletion.policy
        DeletedBy = $LogEntry.deletion.deleted_by
        Hostname = $LogEntry.deletion.hostname
        AdditionalInfo = ($LogEntry.additional_info | ConvertTo-Json -Compress)
    }
    
    # Vérifier si le fichier existe
    $fileExists = Test-Path -Path $csvLogPath
    
    # Écrire l'entrée dans le fichier CSV
    try {
        $csvEntry | Export-Csv -Path $csvLogPath -Append -NoTypeInformation -Encoding UTF8 -Force -ErrorAction Stop
        
        if (-not $fileExists) {
            Write-Log "Created new CSV log: $csvLogPath" -Level "Debug"
        } else {
            Write-Log "Added entry to CSV log: $csvLogPath" -Level "Debug"
        }
        
        return $true
    } catch {
        Write-Log "Error writing to CSV log: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Fonction principale pour journaliser une suppression
function Write-DeletionLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RestorePointId,
        
        [Parameter(Mandatory = $false)]
        [string]$RestorePointName = "",
        
        [Parameter(Mandatory = $false)]
        [string]$RestorePointType = "",
        
        [Parameter(Mandatory = $false)]
        [string]$DeletionReason = "Retention policy",
        
        [Parameter(Mandatory = $false)]
        [string]$PolicyName = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalInfo = @{},
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "CSV", "Both")]
        [string]$LogFormat = "Both",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeContent
    )
    
    # Vérifier si le point de restauration existe encore
    $restorePointsPath = Join-Path -Path $rootPath -ChildPath "points"
    $restorePointPath = Join-Path -Path $restorePointsPath -ChildPath "$RestorePointId.json"
    
    $content = $null
    
    if (Test-Path -Path $restorePointPath -and $IncludeContent) {
        try {
            $restorePoint = Get-Content -Path $restorePointPath -Raw | ConvertFrom-Json
            $content = $restorePoint
        } catch {
            Write-Log "Error loading restore point content: $($_.Exception.Message)" -Level "Warning"
        }
    }
    
    # Créer l'entrée de journal
    $logEntry = New-LogEntry -RestorePointId $RestorePointId -RestorePointName $RestorePointName -RestorePointType $RestorePointType -DeletionReason $DeletionReason -PolicyName $PolicyName -AdditionalInfo $AdditionalInfo -Content $content
    
    # Écrire les journaux selon le format spécifié
    $success = $true
    
    if ($LogFormat -in @("JSON", "Both")) {
        $jsonSuccess = Write-JsonLog -LogEntry $logEntry
        $success = $success -and $jsonSuccess
    }
    
    if ($LogFormat -in @("CSV", "Both")) {
        $csvSuccess = Write-CsvLog -LogEntry $logEntry
        $success = $success -and $csvSuccess
    }
    
    # Journaliser le résultat
    if ($success) {
        Write-Log "Successfully logged deletion of restore point $RestorePointId" -Level "Info"
    } else {
        Write-Log "Errors occurred while logging deletion of restore point $RestorePointId" -Level "Warning"
    }
    
    return $success
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Write-DeletionLog -RestorePointId $RestorePointId -RestorePointName $RestorePointName -RestorePointType $RestorePointType -DeletionReason $DeletionReason -PolicyName $PolicyName -AdditionalInfo $AdditionalInfo -LogFormat $LogFormat -IncludeContent:$IncludeContent
}

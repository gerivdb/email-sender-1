# Invoke-EmergencyRecovery.ps1
# Script pour récupérer des points de restauration supprimés en cas d'urgence
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RestorePointId = "",
    
    [Parameter(Mandatory = $false)]
    [DateTime]$StartDate,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$EndDate,
    
    [Parameter(Mandatory = $false)]
    [string]$DeletionReason = "",
    
    [Parameter(Mandatory = $false)]
    [string]$PolicyName = "",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "",
    
    [Parameter(Mandatory = $false)]
    [switch]$RestoreAll,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
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

# Fonction pour obtenir le chemin du répertoire des points de restauration
function Get-RestorePointsPath {
    [CmdletBinding()]
    param()
    
    $pointsPath = Join-Path -Path $rootPath -ChildPath "points"
    
    if (-not (Test-Path -Path $pointsPath)) {
        New-Item -Path $pointsPath -ItemType Directory -Force | Out-Null
    }
    
    return $pointsPath
}

# Fonction pour obtenir tous les journaux de suppression
function Get-DeletionLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate
    )
    
    $logsPath = Get-LogsPath
    $logFiles = @()
    
    # Si les dates sont spécifiées, filtrer les fichiers de journal par date
    if ($PSBoundParameters.ContainsKey("StartDate") -or $PSBoundParameters.ContainsKey("EndDate")) {
        $datePattern = "deletion_log_(\d{4}-\d{2}-\d{2})\.json"
        
        $allLogFiles = Get-ChildItem -Path $logsPath -Filter "deletion_log_*.json"
        
        foreach ($file in $allLogFiles) {
            if ($file.Name -match $datePattern) {
                $fileDate = [DateTime]::ParseExact($matches[1], "yyyy-MM-dd", $null)
                
                $includeFile = $true
                
                if ($PSBoundParameters.ContainsKey("StartDate") -and $fileDate -lt $StartDate) {
                    $includeFile = $false
                }
                
                if ($PSBoundParameters.ContainsKey("EndDate") -and $fileDate -gt $EndDate) {
                    $includeFile = $false
                }
                
                if ($includeFile) {
                    $logFiles += $file
                }
            }
        }
    } else {
        # Sinon, obtenir tous les fichiers de journal
        $logFiles = Get-ChildItem -Path $logsPath -Filter "deletion_log_*.json"
    }
    
    return $logFiles
}

# Fonction pour rechercher des entrées de journal de suppression
function Find-DeletionLogEntries {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RestorePointId = "",
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate,
        
        [Parameter(Mandatory = $false)]
        [string]$DeletionReason = "",
        
        [Parameter(Mandatory = $false)]
        [string]$PolicyName = ""
    )
    
    $logFiles = Get-DeletionLogs -StartDate $StartDate -EndDate $EndDate
    $matchingEntries = @()
    
    foreach ($file in $logFiles) {
        try {
            $logEntries = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            # Vérifier si le journal est un tableau
            if (-not ($logEntries -is [array])) {
                $logEntries = @($logEntries)
            }
            
            foreach ($entry in $logEntries) {
                $matches = $true
                
                # Filtrer par ID de point de restauration
                if (-not [string]::IsNullOrEmpty($RestorePointId) -and $entry.restore_point.id -ne $RestorePointId) {
                    $matches = $false
                }
                
                # Filtrer par date de suppression
                if ($PSBoundParameters.ContainsKey("StartDate") -or $PSBoundParameters.ContainsKey("EndDate")) {
                    $entryDate = [DateTime]::Parse($entry.timestamp)
                    
                    if ($PSBoundParameters.ContainsKey("StartDate") -and $entryDate -lt $StartDate) {
                        $matches = $false
                    }
                    
                    if ($PSBoundParameters.ContainsKey("EndDate") -and $entryDate -gt $EndDate) {
                        $matches = $false
                    }
                }
                
                # Filtrer par raison de suppression
                if (-not [string]::IsNullOrEmpty($DeletionReason) -and $entry.deletion.reason -ne $DeletionReason) {
                    $matches = $false
                }
                
                # Filtrer par nom de politique
                if (-not [string]::IsNullOrEmpty($PolicyName) -and $entry.deletion.policy -ne $PolicyName) {
                    $matches = $false
                }
                
                if ($matches) {
                    $matchingEntries += $entry
                }
            }
        } catch {
            Write-Log "Error processing log file $($file.FullName): $($_.Exception.Message)" -Level "Warning"
        }
    }
    
    return $matchingEntries
}

# Fonction pour restaurer un point de restauration à partir d'une entrée de journal
function Restore-FromLogEntry {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$LogEntry,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputDirectory = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Vérifier si l'entrée de journal contient le contenu du point de restauration
    if (-not $LogEntry.PSObject.Properties.Name.Contains("content") -or $null -eq $LogEntry.content) {
        Write-Log "Log entry does not contain restore point content: $($LogEntry.id)" -Level "Error"
        return $false
    }
    
    # Déterminer le répertoire de sortie
    $targetDirectory = if ([string]::IsNullOrEmpty($OutputDirectory)) {
        Get-RestorePointsPath
    } else {
        if (-not (Test-Path -Path $OutputDirectory)) {
            New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
        }
        $OutputDirectory
    }
    
    # Construire le chemin du fichier de sortie
    $restorePointId = $LogEntry.restore_point.id
    $outputPath = Join-Path -Path $targetDirectory -ChildPath "$restorePointId.json"
    
    # Vérifier si le fichier existe déjà
    if (Test-Path -Path $outputPath) {
        Write-Log "Restore point file already exists: $outputPath" -Level "Warning"
        return $false
    }
    
    # Restaurer le point de restauration
    if (-not $WhatIf) {
        try {
            $LogEntry.content | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputPath -Encoding UTF8
            Write-Log "Restored restore point to: $outputPath" -Level "Info"
            return $true
        } catch {
            Write-Log "Error restoring restore point: $($_.Exception.Message)" -Level "Error"
            return $false
        }
    } else {
        Write-Log "WhatIf: Would restore restore point to: $outputPath" -Level "Info"
        return $true
    }
}

# Fonction principale pour la récupération d'urgence
function Invoke-EmergencyRecovery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RestorePointId = "",
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate,
        
        [Parameter(Mandatory = $false)]
        [string]$DeletionReason = "",
        
        [Parameter(Mandatory = $false)]
        [string]$PolicyName = "",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputDirectory = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$RestoreAll,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Rechercher les entrées de journal correspondantes
    $logEntries = Find-DeletionLogEntries -RestorePointId $RestorePointId -StartDate $StartDate -EndDate $EndDate -DeletionReason $DeletionReason -PolicyName $PolicyName
    
    if ($logEntries.Count -eq 0) {
        Write-Log "No matching deletion log entries found" -Level "Warning"
        return $false
    }
    
    Write-Log "Found $($logEntries.Count) matching deletion log entries" -Level "Info"
    
    # Demander confirmation si plusieurs entrées sont trouvées et que RestoreAll n'est pas spécifié
    if ($logEntries.Count -gt 1 -and -not $RestoreAll -and -not $WhatIf) {
        Write-Log "Multiple restore points found. Use -RestoreAll to restore all or specify more filters." -Level "Warning"
        
        # Afficher les entrées trouvées
        for ($i = 0; $i -lt [Math]::Min(10, $logEntries.Count); $i++) {
            $entry = $logEntries[$i]
            Write-Log "  $($i + 1). $($entry.restore_point.id) - $($entry.restore_point.name) - $($entry.timestamp)" -Level "Info"
        }
        
        if ($logEntries.Count -gt 10) {
            Write-Log "  ... and $($logEntries.Count - 10) more" -Level "Info"
        }
        
        return $false
    }
    
    # Restaurer les points de restauration
    $successCount = 0
    $errorCount = 0
    
    foreach ($entry in $logEntries) {
        $result = Restore-FromLogEntry -LogEntry $entry -OutputDirectory $OutputDirectory -WhatIf:$WhatIf
        
        if ($result) {
            $successCount++
        } else {
            $errorCount++
        }
    }
    
    # Afficher le résumé
    if ($WhatIf) {
        Write-Log "WhatIf: Would restore $successCount restore points" -Level "Info"
    } else {
        Write-Log "Emergency recovery completed: $successCount restore points restored, $errorCount errors" -Level "Info"
    }
    
    return $errorCount -eq 0
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-EmergencyRecovery -RestorePointId $RestorePointId -StartDate $StartDate -EndDate $EndDate -DeletionReason $DeletionReason -PolicyName $PolicyName -OutputDirectory $OutputDirectory -RestoreAll:$RestoreAll -WhatIf:$WhatIf
}

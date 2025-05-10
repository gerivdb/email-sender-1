# Get-TemporalReference.ps1
# Script pour gérer le référencement temporel des points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ReferencePoint,
    
    [Parameter(Mandatory = $false)]
    [string]$ReferenceType = "absolute",
    
    [Parameter(Mandatory = $false)]
    [int]$TimeOffset = 0,
    
    [Parameter(Mandatory = $false)]
    [string]$TimeUnit = "minutes",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$AsObject,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $rootPath)) -ChildPath "utils"
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

# Fonction pour obtenir une référence temporelle absolue
function Get-AbsoluteTimeReference {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ReferencePoint
    )
    
    # Si aucun point de référence n'est fourni, utiliser la date et l'heure actuelles
    if ([string]::IsNullOrEmpty($ReferencePoint)) {
        $dateTime = Get-Date
    } else {
        # Essayer de parser le point de référence
        try {
            $dateTime = [DateTime]::Parse($ReferencePoint)
        } catch {
            Write-Log "Invalid reference point format: $ReferencePoint. Using current date and time." -Level "Warning"
            $dateTime = Get-Date
        }
    }
    
    # Créer la référence temporelle
    $reference = @{
        type = "absolute"
        datetime = $dateTime.ToString("o") # Format ISO 8601
        timestamp = [int][double]::Parse((Get-Date -Date $dateTime -UFormat %s))
        timezone = [TimeZoneInfo]::Local.Id
        timezone_offset = [TimeZoneInfo]::Local.GetUtcOffset($dateTime).TotalMinutes
        is_dst = [TimeZoneInfo]::Local.IsDaylightSavingTime($dateTime)
    }
    
    return $reference
}

# Fonction pour obtenir une référence temporelle relative
function Get-RelativeTimeReference {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ReferencePoint,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeOffset = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$TimeUnit = "minutes"
    )
    
    # Obtenir la référence absolue
    $absoluteReference = Get-AbsoluteTimeReference -ReferencePoint $ReferencePoint
    
    # Calculer la date et l'heure relatives
    $dateTime = [DateTime]::Parse($absoluteReference.datetime)
    
    switch ($TimeUnit) {
        "seconds" {
            $relativeDateTime = $dateTime.AddSeconds($TimeOffset)
        }
        "minutes" {
            $relativeDateTime = $dateTime.AddMinutes($TimeOffset)
        }
        "hours" {
            $relativeDateTime = $dateTime.AddHours($TimeOffset)
        }
        "days" {
            $relativeDateTime = $dateTime.AddDays($TimeOffset)
        }
        "weeks" {
            $relativeDateTime = $dateTime.AddDays($TimeOffset * 7)
        }
        "months" {
            $relativeDateTime = $dateTime.AddMonths($TimeOffset)
        }
        "years" {
            $relativeDateTime = $dateTime.AddYears($TimeOffset)
        }
        default {
            Write-Log "Invalid time unit: $TimeUnit. Using minutes." -Level "Warning"
            $relativeDateTime = $dateTime.AddMinutes($TimeOffset)
        }
    }
    
    # Créer la référence temporelle
    $reference = @{
        type = "relative"
        base_reference = $absoluteReference
        offset = $TimeOffset
        unit = $TimeUnit
        datetime = $relativeDateTime.ToString("o") # Format ISO 8601
        timestamp = [int][double]::Parse((Get-Date -Date $relativeDateTime -UFormat %s))
        timezone = [TimeZoneInfo]::Local.Id
        timezone_offset = [TimeZoneInfo]::Local.GetUtcOffset($relativeDateTime).TotalMinutes
        is_dst = [TimeZoneInfo]::Local.IsDaylightSavingTime($relativeDateTime)
    }
    
    return $reference
}

# Fonction pour obtenir une référence temporelle basée sur un événement
function Get-EventTimeReference {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$EventType,
        
        [Parameter(Mandatory = $false)]
        [string]$EventId,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeOffset = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$TimeUnit = "minutes"
    )
    
    # Déterminer la date et l'heure de l'événement
    $eventDateTime = $null
    
    switch ($EventType) {
        "git_commit" {
            if ([string]::IsNullOrEmpty($EventId)) {
                Write-Log "No commit ID provided for git_commit event" -Level "Error"
                return $null
            }
            
            try {
                # Obtenir la date du commit
                $commitDate = git show -s --format=%ci $EventId
                $eventDateTime = [DateTime]::Parse($commitDate)
            } catch {
                Write-Log "Error getting commit date: $_" -Level "Error"
                return $null
            }
        }
        "system_start" {
            try {
                # Obtenir la date de démarrage du système
                $os = Get-WmiObject -Class Win32_OperatingSystem
                $eventDateTime = $os.ConvertToDateTime($os.LastBootUpTime)
            } catch {
                Write-Log "Error getting system start time: $_" -Level "Error"
                return $null
            }
        }
        "restore_point" {
            if ([string]::IsNullOrEmpty($EventId)) {
                Write-Log "No restore point ID provided for restore_point event" -Level "Error"
                return $null
            }
            
            # Obtenir la date du point de restauration
            $restorePointsPath = Join-Path -Path $scriptPath -ChildPath "points"
            $restorePointFile = Join-Path -Path $restorePointsPath -ChildPath "$EventId.json"
            
            if (-not (Test-Path -Path $restorePointFile)) {
                Write-Log "Restore point file not found: $restorePointFile" -Level "Error"
                return $null
            }
            
            try {
                $restorePoint = Get-Content -Path $restorePointFile -Raw | ConvertFrom-Json
                $eventDateTime = [DateTime]::Parse($restorePoint.metadata.created_at)
            } catch {
                Write-Log "Error getting restore point date: $_" -Level "Error"
                return $null
            }
        }
        "configuration_update" {
            if ([string]::IsNullOrEmpty($EventId)) {
                Write-Log "No configuration ID provided for configuration_update event" -Level "Error"
                return $null
            }
            
            # Obtenir la date de mise à jour de la configuration
            $statesPath = Join-Path -Path $scriptPath -ChildPath "states"
            $configFiles = Get-ChildItem -Path $statesPath -Filter "*$EventId*_state.json"
            
            if ($configFiles.Count -eq 0) {
                Write-Log "No configuration state files found for ID: $EventId" -Level "Error"
                return $null
            }
            
            try {
                $configState = Get-Content -Path $configFiles[0].FullName -Raw | ConvertFrom-Json
                $eventDateTime = [DateTime]::Parse($configState.saved_at)
            } catch {
                Write-Log "Error getting configuration update date: $_" -Level "Error"
                return $null
            }
        }
        default {
            Write-Log "Invalid event type: $EventType" -Level "Error"
            return $null
        }
    }
    
    if ($null -eq $eventDateTime) {
        Write-Log "Could not determine event date and time" -Level "Error"
        return $null
    }
    
    # Appliquer le décalage temporel
    switch ($TimeUnit) {
        "seconds" {
            $relativeDateTime = $eventDateTime.AddSeconds($TimeOffset)
        }
        "minutes" {
            $relativeDateTime = $eventDateTime.AddMinutes($TimeOffset)
        }
        "hours" {
            $relativeDateTime = $eventDateTime.AddHours($TimeOffset)
        }
        "days" {
            $relativeDateTime = $eventDateTime.AddDays($TimeOffset)
        }
        "weeks" {
            $relativeDateTime = $eventDateTime.AddDays($TimeOffset * 7)
        }
        "months" {
            $relativeDateTime = $eventDateTime.AddMonths($TimeOffset)
        }
        "years" {
            $relativeDateTime = $eventDateTime.AddYears($TimeOffset)
        }
        default {
            Write-Log "Invalid time unit: $TimeUnit. Using minutes." -Level "Warning"
            $relativeDateTime = $eventDateTime.AddMinutes($TimeOffset)
        }
    }
    
    # Créer la référence temporelle
    $reference = @{
        type = "event"
        event_type = $EventType
        event_id = $EventId
        event_datetime = $eventDateTime.ToString("o")
        offset = $TimeOffset
        unit = $TimeUnit
        datetime = $relativeDateTime.ToString("o")
        timestamp = [int][double]::Parse((Get-Date -Date $relativeDateTime -UFormat %s))
        timezone = [TimeZoneInfo]::Local.Id
        timezone_offset = [TimeZoneInfo]::Local.GetUtcOffset($relativeDateTime).TotalMinutes
        is_dst = [TimeZoneInfo]::Local.IsDaylightSavingTime($relativeDateTime)
    }
    
    return $reference
}

# Fonction pour convertir une référence temporelle en chaîne lisible
function ConvertTo-ReadableTimeReference {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Reference
    )
    
    $dateTime = [DateTime]::Parse($Reference.datetime)
    
    switch ($Reference.type) {
        "absolute" {
            return "Absolute time: $($dateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        }
        "relative" {
            $baseDateTime = [DateTime]::Parse($Reference.base_reference.datetime)
            $direction = if ($Reference.offset -ge 0) { "after" } else { "before" }
            $absOffset = [Math]::Abs($Reference.offset)
            
            return "$absOffset $($Reference.unit) $direction $($baseDateTime.ToString('yyyy-MM-dd HH:mm:ss')): $($dateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        }
        "event" {
            $eventDateTime = [DateTime]::Parse($Reference.event_datetime)
            $direction = if ($Reference.offset -ge 0) { "after" } else { "before" }
            $absOffset = [Math]::Abs($Reference.offset)
            
            return "$absOffset $($Reference.unit) $direction $($Reference.event_type) ($($eventDateTime.ToString('yyyy-MM-dd HH:mm:ss'))): $($dateTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        }
        default {
            return "Unknown reference type: $($Reference.type)"
        }
    }
}

# Fonction principale
function Get-TemporalReference {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ReferencePoint,
        
        [Parameter(Mandatory = $false)]
        [string]$ReferenceType = "absolute",
        
        [Parameter(Mandatory = $false)]
        [int]$TimeOffset = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$TimeUnit = "minutes",
        
        [Parameter(Mandatory = $false)]
        [string]$EventType,
        
        [Parameter(Mandatory = $false)]
        [string]$EventId,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$AsObject
    )
    
    # Obtenir la référence temporelle en fonction du type
    $reference = $null
    
    switch ($ReferenceType) {
        "absolute" {
            $reference = Get-AbsoluteTimeReference -ReferencePoint $ReferencePoint
        }
        "relative" {
            $reference = Get-RelativeTimeReference -ReferencePoint $ReferencePoint -TimeOffset $TimeOffset -TimeUnit $TimeUnit
        }
        "event" {
            if ([string]::IsNullOrEmpty($EventType)) {
                Write-Log "Event type must be provided for event reference" -Level "Error"
                return $null
            }
            
            $reference = Get-EventTimeReference -EventType $EventType -EventId $EventId -TimeOffset $TimeOffset -TimeUnit $TimeUnit
        }
        default {
            Write-Log "Invalid reference type: $ReferenceType" -Level "Error"
            return $null
        }
    }
    
    if ($null -eq $reference) {
        Write-Log "Failed to create temporal reference" -Level "Error"
        return $null
    }
    
    # Ajouter une représentation lisible
    $reference.readable = ConvertTo-ReadableTimeReference -Reference $reference
    
    # Sauvegarder la référence si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            # Créer le répertoire de sortie s'il n'existe pas
            if (-not (Test-Path -Path $OutputPath)) {
                New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            }
            
            # Générer un nom de fichier
            $fileName = "temporal_reference_$([DateTime]::Now.ToString('yyyyMMdd_HHmmss')).json"
            $filePath = Join-Path -Path $OutputPath -ChildPath $fileName
            
            # Sauvegarder la référence
            $reference | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8
            Write-Log "Temporal reference saved to: $filePath" -Level "Info"
        } catch {
            Write-Log "Error saving temporal reference: $_" -Level "Error"
        }
    }
    
    # Retourner la référence selon le format demandé
    if ($AsObject) {
        return $reference
    } else {
        return $reference | ConvertTo-Json -Depth 10
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    if ($ReferenceType -eq "event") {
        Get-TemporalReference -ReferenceType $ReferenceType -EventType $EventType -EventId $EventId -TimeOffset $TimeOffset -TimeUnit $TimeUnit -OutputPath $OutputPath -AsObject:$AsObject
    } else {
        Get-TemporalReference -ReferencePoint $ReferencePoint -ReferenceType $ReferenceType -TimeOffset $TimeOffset -TimeUnit $TimeUnit -OutputPath $OutputPath -AsObject:$AsObject
    }
}

<#
.SYNOPSIS
    Collecte les événements récents de n8n.

.DESCRIPTION
    Ce script collecte les événements récents de n8n à partir des logs.

.PARAMETER LogFolder
    Dossier contenant les logs de n8n.

.PARAMETER MaxEvents
    Nombre maximum d'événements à collecter.

.PARAMETER MetricsConfig
    Configuration des métriques à collecter.

.EXAMPLE
    .\dashboard-events.ps1 -LogFolder "n8n/logs" -MaxEvents 10

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  26/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$LogFolder = "n8n/logs",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxEvents = 10,
    
    [Parameter(Mandatory=$false)]
    [object]$MetricsConfig = $null
)

# Fonction pour obtenir les événements récents
function Get-RecentEvents {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogFolder,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxEvents = 10
    )
    
    $logFile = Join-Path -Path $LogFolder -ChildPath "n8n.log"
    
    if (-not (Test-Path -Path $logFile)) {
        return @{
            Success = $false
            Events = @()
            Error = "Fichier de log non trouvé: $logFile"
        }
    }
    
    try {
        # Lire les dernières lignes du fichier de log
        $lines = Get-Content -Path $logFile -Tail 100
        
        $events = @()
        $count = 0
        
        foreach ($line in $lines) {
            # Extraire la date, le niveau et le message
            if ($line -match "\[(.*?)\] \[(.*?)\] (.*)") {
                $date = [DateTime]::Parse($matches[1])
                $level = $matches[2]
                $message = $matches[3]
                
                # Déterminer le type d'événement
                $type = switch -Regex ($level) {
                    "ERROR" { "error" }
                    "WARN" { "warning" }
                    "INFO" { "info" }
                    default { "info" }
                }
                
                # Créer l'événement
                $event = @{
                    Date = $date
                    Level = $level
                    Message = $message
                    Type = $type
                }
                
                $events += $event
                $count++
                
                if ($count -ge $MaxEvents) {
                    break
                }
            }
        }
        
        # Trier les événements par date (du plus récent au plus ancien)
        $events = $events | Sort-Object -Property Date -Descending
        
        return @{
            Success = $true
            Events = $events
            Error = $null
        }
    } catch {
        return @{
            Success = $false
            Events = @()
            Error = $_.Exception.Message
        }
    }
}

# Fonction principale pour collecter les événements récents
function Get-EventsMetrics {
    param (
        [Parameter(Mandatory=$true)]
        [string]$LogFolder,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxEvents = 10,
        
        [Parameter(Mandatory=$false)]
        [object]$MetricsConfig = $null
    )
    
    # Obtenir les événements récents
    $eventsResult = Get-RecentEvents -LogFolder $LogFolder -MaxEvents $MaxEvents
    
    if (-not $eventsResult.Success) {
        return @{
            Events = @()
            EventsHtml = "<div class='event-item'><div class='event-description'>Erreur lors de la collecte des événements: $($eventsResult.Error)</div></div>"
            CollectedAt = Get-Date
        }
    }
    
    # Générer le HTML pour les événements
    $eventsHtml = ""
    
    foreach ($event in $eventsResult.Events) {
        $dateString = $event.Date.ToString("yyyy-MM-dd HH:mm:ss")
        $typeClass = $event.Type
        $typeText = switch ($event.Type) {
            "error" { "Erreur" }
            "warning" { "Avertissement" }
            "info" { "Info" }
            default { "Info" }
        }
        
        $eventsHtml += @"
<div class="event-item">
    <div class="event-time">$dateString</div>
    <div class="event-description">
        <span class="event-type $typeClass">$typeText</span>
        $($event.Message)
    </div>
</div>
"@
    }
    
    if ($eventsResult.Events.Count -eq 0) {
        $eventsHtml = "<div class='event-item'><div class='event-description'>Aucun événement récent</div></div>"
    }
    
    # Retourner les événements
    return @{
        Events = $eventsResult.Events
        EventsHtml = $eventsHtml
        CollectedAt = Get-Date
    }
}

# Si le script est exécuté directement, collecter et retourner les événements
if ($MyInvocation.InvocationName -ne ".") {
    Get-EventsMetrics -LogFolder $LogFolder -MaxEvents $MaxEvents -MetricsConfig $MetricsConfig
}

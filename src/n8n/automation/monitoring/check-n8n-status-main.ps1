<#
.SYNOPSIS
    Script de surveillance du port et de l'API n8n.

.DESCRIPTION
    Ce script vérifie si le port n8n est accessible et si l'API n8n répond correctement.
    Il peut envoyer des alertes en cas de problème et générer des rapports sur l'état de n8n.

.PARAMETER Hostname
    Nom d'hôte ou adresse IP du serveur n8n (par défaut: localhost).

.PARAMETER Port
    Port utilisé par n8n (par défaut: 5678).

.PARAMETER Protocol
    Protocole utilisé par n8n (http ou https) (par défaut: http).

.PARAMETER ApiKey
    API Key à utiliser pour les requêtes API. Si non spécifiée, elle sera récupérée depuis les fichiers de configuration.

.PARAMETER Endpoints
    Liste des endpoints à tester (par défaut: /, /healthz, /api/v1/executions).

.PARAMETER Timeout
    Timeout en secondes pour les requêtes (par défaut: 10).

.PARAMETER RetryCount
    Nombre de tentatives en cas d'échec (par défaut: 3).

.PARAMETER RetryDelay
    Délai en secondes entre les tentatives (par défaut: 2).

.PARAMETER LogFile
    Fichier de log pour la surveillance (par défaut: n8n/logs/n8n-status.log).

.PARAMETER ReportFile
    Fichier de rapport JSON pour la surveillance (par défaut: n8n/logs/n8n-status-report.json).

.PARAMETER HtmlReportFile
    Fichier de rapport HTML pour la surveillance (par défaut: n8n/logs/n8n-status-report.html).

.PARAMETER NotificationEnabled
    Indique si les notifications doivent être envoyées (par défaut: $true).

.PARAMETER NotificationScript
    Script à utiliser pour envoyer les notifications (par défaut: n8n/automation/notification/send-notification.ps1).

.PARAMETER NotificationLevel
    Niveau minimum pour envoyer une notification (INFO, WARNING, ERROR) (par défaut: WARNING).

.PARAMETER HistoryLength
    Nombre d'historiques à conserver (par défaut: 10).

.PARAMETER HistoryFolder
    Dossier pour stocker l'historique des résultats (par défaut: n8n/logs/history).

.PARAMETER AutoRestart
    Indique si n8n doit être redémarré automatiquement en cas de problème (par défaut: $false).

.PARAMETER RestartScript
    Script à utiliser pour redémarrer n8n (par défaut: n8n/automation/deployment/restart-n8n.ps1).

.PARAMETER RestartThreshold
    Nombre d'échecs consécutifs avant redémarrage (par défaut: 3).

.EXAMPLE
    .\check-n8n-status-main.ps1 -Hostname "localhost" -Port 5678 -Protocol "http"

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  22/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$Hostname = "localhost",
    
    [Parameter(Mandatory=$false)]
    [int]$Port = 5678,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("http", "https")]
    [string]$Protocol = "http",
    
    [Parameter(Mandatory=$false)]
    [string]$ApiKey = "",
    
    [Parameter(Mandatory=$false)]
    [array]$Endpoints = @("/", "/healthz", "/api/v1/executions"),
    
    [Parameter(Mandatory=$false)]
    [int]$Timeout = 10,
    
    [Parameter(Mandatory=$false)]
    [int]$RetryCount = 3,
    
    [Parameter(Mandatory=$false)]
    [int]$RetryDelay = 2,
    
    [Parameter(Mandatory=$false)]
    [string]$LogFile = "n8n/logs/n8n-status.log",
    
    [Parameter(Mandatory=$false)]
    [string]$ReportFile = "n8n/logs/n8n-status-report.json",
    
    [Parameter(Mandatory=$false)]
    [string]$HtmlReportFile = "n8n/logs/n8n-status-report.html",
    
    [Parameter(Mandatory=$false)]
    [bool]$NotificationEnabled = $true,
    
    [Parameter(Mandatory=$false)]
    [string]$NotificationScript = "n8n/automation/notification/send-notification.ps1",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("INFO", "WARNING", "ERROR")]
    [string]$NotificationLevel = "WARNING",
    
    [Parameter(Mandatory=$false)]
    [int]$HistoryLength = 10,
    
    [Parameter(Mandatory=$false)]
    [string]$HistoryFolder = "n8n/logs/history",
    
    [Parameter(Mandatory=$false)]
    [bool]$AutoRestart = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$RestartScript = "n8n/automation/deployment/restart-n8n.ps1",
    
    [Parameter(Mandatory=$false)]
    [int]$RestartThreshold = 3
)

# Importer les fonctions des parties précédentes
. "$PSScriptRoot\check-n8n-status-part1.ps1"
. "$PSScriptRoot\check-n8n-status-part2.ps1"
. "$PSScriptRoot\check-n8n-status-part3.ps1"

# Mettre à jour les paramètres communs
$script:CommonParams.Hostname = $Hostname
$script:CommonParams.Port = $Port
$script:CommonParams.Protocol = $Protocol
$script:CommonParams.ApiKey = $ApiKey
$script:CommonParams.Endpoints = $Endpoints
$script:CommonParams.Timeout = $Timeout
$script:CommonParams.RetryCount = $RetryCount
$script:CommonParams.RetryDelay = $RetryDelay
$script:CommonParams.LogFile = $LogFile
$script:CommonParams.ReportFile = $ReportFile
$script:CommonParams.HtmlReportFile = $HtmlReportFile
$script:CommonParams.NotificationEnabled = $NotificationEnabled
$script:CommonParams.NotificationScript = $NotificationScript
$script:CommonParams.NotificationLevel = $NotificationLevel
$script:CommonParams.HistoryLength = $HistoryLength
$script:CommonParams.HistoryFolder = $HistoryFolder
$script:CommonParams.AutoRestart = $AutoRestart
$script:CommonParams.RestartScript = $RestartScript
$script:CommonParams.RestartThreshold = $RestartThreshold

# Vérifier si le dossier de log existe
$logFolder = Split-Path -Path $LogFile -Parent
Ensure-FolderExists -FolderPath $logFolder | Out-Null

# Afficher les informations de démarrage
Write-Log "=== Surveillance du port et de l'API n8n ===" -Level "INFO"
Write-Log "Hôte: $Hostname" -Level "INFO"
Write-Log "Port: $Port" -Level "INFO"
Write-Log "Protocole: $Protocol" -Level "INFO"
Write-Log "Endpoints à tester: $($Endpoints -join ', ')" -Level "INFO"
Write-Log "Timeout: $Timeout secondes" -Level "INFO"
Write-Log "Nombre de tentatives: $RetryCount" -Level "INFO"
Write-Log "Délai entre les tentatives: $RetryDelay secondes" -Level "INFO"
Write-Log "Redémarrage automatique: $AutoRestart" -Level "INFO"

# Récupérer l'API Key si nécessaire
if ([string]::IsNullOrEmpty($ApiKey)) {
    $ApiKey = Get-ApiKeyFromConfig
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        Write-Log "API Key récupérée depuis la configuration" -Level "INFO"
    } else {
        Write-Log "Aucune API Key trouvée. Les endpoints nécessitant une authentification échoueront." -Level "WARNING"
    }
}

# Charger l'historique des résultats
$history = Get-ResultsHistory -HistoryFolder $HistoryFolder -HistoryLength $HistoryLength

# Vérifier si n8n doit être redémarré en fonction de l'historique
$consecutiveFailures = 0

if ($AutoRestart -and $history.Count -gt 0) {
    # Compter le nombre d'échecs consécutifs
    for ($i = 0; $i -lt [Math]::Min($RestartThreshold, $history.Count); $i++) {
        if (-not $history[$i].OverallSuccess) {
            $consecutiveFailures++
        } else {
            break
        }
    }
    
    Write-Log "Nombre d'échecs consécutifs: $consecutiveFailures" -Level "INFO"
    
    # Redémarrer n8n si le seuil est atteint
    if ($consecutiveFailures -ge $RestartThreshold) {
        Write-Log "Seuil d'échecs consécutifs atteint ($consecutiveFailures). Redémarrage de n8n..." -Level "WARNING"
        
        $restartSuccess = Restart-N8n -RestartScript $RestartScript
        
        if ($restartSuccess) {
            # Attendre que n8n redémarre
            Write-Log "Attente de 30 secondes pour le redémarrage de n8n..." -Level "INFO"
            Start-Sleep -Seconds 30
            
            # Envoyer une notification
            $subject = "n8n redémarré automatiquement"
            $message = "n8n a été redémarré automatiquement après $consecutiveFailures échecs consécutifs."
            Send-StatusNotification -Subject $subject -Message $message -Level "WARNING"
        }
    }
}

# Tester l'API n8n
$results = Test-N8nApi -Hostname $Hostname -Port $Port -Protocol $Protocol -Endpoints $Endpoints -ApiKey $ApiKey -Timeout $Timeout -RetryCount $RetryCount -RetryDelay $RetryDelay

# Sauvegarder les résultats
Save-ResultsToJson -Results $results -FilePath $ReportFile
Save-ResultsToHistory -Results $results -HistoryFolder $HistoryFolder -HistoryLength $HistoryLength

# Mettre à jour l'historique avec les nouveaux résultats
$history = Get-ResultsHistory -HistoryFolder $HistoryFolder -HistoryLength $HistoryLength

# Générer le rapport HTML
Generate-HtmlReport -Results $results -FilePath $HtmlReportFile -History $history

# Envoyer une notification si nécessaire
if (-not $results.OverallSuccess) {
    $subject = "Problème détecté avec n8n"
    $message = "La surveillance a détecté un problème avec n8n sur $Hostname:$Port.`n`n"
    
    if (-not $results.PortTest.Success) {
        $message += "Le port $Port n'est pas accessible: $($results.PortTest.Error)`n"
    } else {
        $message += "Le port $Port est accessible, mais certains endpoints ne répondent pas correctement:`n"
        
        foreach ($endpoint in $results.EndpointTests.Keys) {
            $endpointResult = $results.EndpointTests[$endpoint]
            
            if (-not $endpointResult.Success) {
                $message += "- $endpoint : $($endpointResult.Error)`n"
            }
        }
    }
    
    $level = if ($consecutiveFailures -ge $RestartThreshold) { "ERROR" } else { "WARNING" }
    Send-StatusNotification -Subject $subject -Message $message -Level $level
} else {
    # Si le test précédent a échoué mais que celui-ci réussit, envoyer une notification de rétablissement
    if ($history.Count -gt 1 -and -not $history[1].OverallSuccess) {
        $subject = "n8n est de nouveau opérationnel"
        $message = "La surveillance a détecté que n8n sur $Hostname:$Port est de nouveau opérationnel."
        Send-StatusNotification -Subject $subject -Message $message -Level "INFO"
    }
}

# Afficher le résumé
Write-Log "`n=== Résumé de la surveillance ===" -Level "INFO"
Write-Log "Statut global: $($results.OverallSuccess ? "Opérationnel" : "Non opérationnel")" -Level $($results.OverallSuccess ? "SUCCESS" : "ERROR")
Write-Log "Port $Port: $($results.PortTest.Success ? "Accessible" : "Non accessible")" -Level $($results.PortTest.Success ? "SUCCESS" : "ERROR")

foreach ($endpoint in $results.EndpointTests.Keys) {
    $endpointResult = $results.EndpointTests[$endpoint]
    Write-Log "Endpoint $endpoint: $($endpointResult.Success ? "Accessible" : "Non accessible")" -Level $($endpointResult.Success ? "SUCCESS" : "ERROR")
}

Write-Log "Temps total du test: $($results.TotalTime) ms" -Level "INFO"
Write-Log "Rapport JSON: $ReportFile" -Level "INFO"
Write-Log "Rapport HTML: $HtmlReportFile" -Level "INFO"

# Retourner les résultats
return $results

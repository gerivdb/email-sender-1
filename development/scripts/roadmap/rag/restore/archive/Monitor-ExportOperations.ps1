# Watch-ExportOperations.ps1
# Script pour surveiller et gérer les opérations d'exportation d'archives
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Status", "Errors", "Retry", "Alert", "Report")]
    [string]$Action = "Status",
    
    [Parameter(Mandatory = $false)]
    [string]$ExportId = "",
    
    [Parameter(Mandatory = $false)]
    [DateTime]$StartDate,
    
    [Parameter(Mandatory = $false)]
    [DateTime]$EndDate,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Console", "Email", "Teams", "Slack", "File")]
    [string[]]$AlertChannels = @("Console"),
    
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

# Fonction pour obtenir le chemin du répertoire des journaux d'exportation
function Get-ExportLogsPath {
    [CmdletBinding()]
    param()
    
    $logsPath = Join-Path -Path $rootPath -ChildPath "logs"
    
    if (-not (Test-Path -Path $logsPath)) {
        New-Item -Path $logsPath -ItemType Directory -Force | Out-Null
    }
    
    $exportLogsPath = Join-Path -Path $logsPath -ChildPath "exports"
    
    if (-not (Test-Path -Path $exportLogsPath)) {
        New-Item -Path $exportLogsPath -ItemType Directory -Force | Out-Null
    }
    
    return $exportLogsPath
}

# Fonction pour obtenir les journaux d'exportation
function Get-ExportLogs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ExportId = "",
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate,
        
        [Parameter(Mandatory = $false)]
        [bool]$SuccessOnly = $false,
        
        [Parameter(Mandatory = $false)]
        [bool]$ErrorsOnly = $false
    )
    
    $logsPath = Get-ExportLogsPath
    $logFiles = Get-ChildItem -Path $logsPath -Filter "export_log_*.json"
    $allLogs = @()
    
    foreach ($file in $logFiles) {
        try {
            $logs = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            # Vérifier si le journal est un tableau
            if (-not ($logs -is [array])) {
                $logs = @($logs)
            }
            
            $allLogs += $logs
        } catch {
            Write-Log "Error reading log file $($file.Name): $($_.Exception.Message)" -Level "Warning"
        }
    }
    
    # Filtrer les journaux
    $filteredLogs = $allLogs
    
    # Filtrer par ID d'exportation
    if (-not [string]::IsNullOrEmpty($ExportId)) {
        $filteredLogs = $filteredLogs | Where-Object { $_.id -eq $ExportId }
    }
    
    # Filtrer par date
    if ($PSBoundParameters.ContainsKey("StartDate")) {
        $filteredLogs = $filteredLogs | Where-Object {
            try {
                $logDate = [DateTime]::Parse($_.timestamp)
                return $logDate -ge $StartDate
            } catch {
                return $false
            }
        }
    }
    
    if ($PSBoundParameters.ContainsKey("EndDate")) {
        $filteredLogs = $filteredLogs | Where-Object {
            try {
                $logDate = [DateTime]::Parse($_.timestamp)
                return $logDate -le $EndDate
            } catch {
                return $false
            }
        }
    }
    
    # Filtrer par résultat
    if ($SuccessOnly) {
        $filteredLogs = $filteredLogs | Where-Object { $_.result.success -eq $true }
    }
    
    if ($ErrorsOnly) {
        $filteredLogs = $filteredLogs | Where-Object { $_.result.success -eq $false }
    }
    
    return $filteredLogs
}

# Fonction pour obtenir les erreurs d'exportation
function Get-ExportErrors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate
    )
    
    $logs = Get-ExportLogs -StartDate $StartDate -EndDate $EndDate -ErrorsOnly $true
    
    return $logs | Sort-Object -Property { [DateTime]::Parse($_.timestamp) } -Descending
}

# Fonction pour réessayer une exportation échouée
function Restart-FailedExport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ExportId
    )
    
    # Obtenir le journal d'exportation
    $log = Get-ExportLogs -ExportId $ExportId
    
    if ($null -eq $log -or $log.Count -eq 0) {
        Write-Log "Export log not found: $ExportId" -Level "Error"
        return $false
    }
    
    $log = $log[0]  # Prendre le premier journal si plusieurs correspondent
    
    # Vérifier si l'exportation a échoué
    if ($log.result.success -eq $true) {
        Write-Log "Export was successful, no need to retry: $ExportId" -Level "Warning"
        return $true
    }
    
    # Vérifier si le fichier source existe toujours
    $archivePath = $log.archive.path
    
    if (-not (Test-Path -Path $archivePath)) {
        Write-Log "Source archive no longer exists: $archivePath" -Level "Error"
        return $false
    }
    
    # Importer le script d'exportation
    $exportScriptPath = Join-Path -Path $scriptPath -ChildPath "Export-ToExternalStorage.ps1"
    
    if (-not (Test-Path -Path $exportScriptPath)) {
        Write-Log "Export script not found: $exportScriptPath" -Level "Error"
        return $false
    }
    
    . $exportScriptPath
    
    # Préparer les paramètres d'exportation
    $exportParams = @{
        ArchivePath = $archivePath
        StorageType = $log.destination.type
        DestinationPath = $log.destination.path
        CreateLogFile = $true
    }
    
    # Ajouter les paramètres de connexion
    if ($log.PSObject.Properties.Name.Contains("connection") -and $log.connection.PSObject.Properties.Count -gt 0) {
        $connectionParams = @{}
        
        foreach ($prop in $log.connection.PSObject.Properties) {
            if ($prop.Value -ne "********") {
                $connectionParams[$prop.Name] = $prop.Value
            }
        }
        
        if ($connectionParams.Count -gt 0) {
            $exportParams.ConnectionParams = $connectionParams
        }
    }
    
    # Exécuter l'exportation
    Write-Log "Retrying export: $ExportId" -Level "Info"
    $result = Export-ToExternalStorage @exportParams
    
    if ($result) {
        Write-Log "Export retry successful: $ExportId" -Level "Info"
    } else {
        Write-Log "Export retry failed: $ExportId" -Level "Error"
    }
    
    return $result
}

# Fonction pour générer un rapport d'exportation
function New-ExportReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )
    
    # Obtenir les journaux d'exportation
    $logs = Get-ExportLogs -StartDate $StartDate -EndDate $EndDate
    
    if ($logs.Count -eq 0) {
        Write-Log "No export logs found for the specified period" -Level "Warning"
        return $false
    }
    
    # Calculer les statistiques
    $totalExports = $logs.Count
    $successfulExports = ($logs | Where-Object { $_.result.success -eq $true }).Count
    $failedExports = $totalExports - $successfulExports
    $successRate = if ($totalExports -gt 0) { [Math]::Round(($successfulExports / $totalExports) * 100, 2) } else { 0 }
    
    $totalSize = ($logs | Measure-Object -Property { $_.archive.size } -Sum).Sum
    $totalSizeMB = [Math]::Round($totalSize / 1MB, 2)
    
    $storageTypes = $logs | Group-Object -Property { $_.destination.type } | Select-Object -Property Name, Count
    
    $startDateStr = if ($PSBoundParameters.ContainsKey("StartDate")) { $StartDate.ToString("yyyy-MM-dd") } else { "All time" }
    $endDateStr = if ($PSBoundParameters.ContainsKey("EndDate")) { $EndDate.ToString("yyyy-MM-dd") } else { "Present" }
    
    # Créer le rapport
    $report = @"
# Export Operations Report
## Period: $startDateStr to $endDateStr

### Summary
- Total exports: $totalExports
- Successful exports: $successfulExports
- Failed exports: $failedExports
- Success rate: $successRate%
- Total size: $totalSizeMB MB

### Storage Types
| Type | Count |
|------|-------|
$(foreach ($type in $storageTypes) {
    "| $($type.Name) | $($type.Count) |"
})

### Recent Errors
| Timestamp | Archive | Destination | Error |
|-----------|---------|-------------|-------|
$(
    $recentErrors = $logs | Where-Object { $_.result.success -eq $false } | Sort-Object -Property { [DateTime]::Parse($_.timestamp) } -Descending | Select-Object -First 10
    foreach ($error in $recentErrors) {
        $timestamp = [DateTime]::Parse($error.timestamp).ToString("yyyy-MM-dd HH:mm:ss")
        $archive = [System.IO.Path]::GetFileName($error.archive.path)
        $destination = "$($error.destination.type):$($error.destination.path)"
        $errorMessage = $error.result.error_message -replace "\|", "\|"
        "| $timestamp | $archive | $destination | $errorMessage |"
    }
)

### Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@
    
    # Sauvegarder le rapport
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $reportsPath = Join-Path -Path $rootPath -ChildPath "reports"
        
        if (-not (Test-Path -Path $reportsPath)) {
            New-Item -Path $reportsPath -ItemType Directory -Force | Out-Null
        }
        
        $OutputPath = Join-Path -Path $reportsPath -ChildPath "export_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    }
    
    try {
        $report | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Log "Export report saved to: $OutputPath" -Level "Info"
        return $OutputPath
    } catch {
        Write-Log "Error saving export report: $($_.Exception.Message)" -Level "Error"
        return $false
    }
}

# Fonction pour envoyer une alerte
function Send-ExportAlert {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Subject,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Console", "Email", "Teams", "Slack", "File")]
        [string[]]$Channels = @("Console")
    )
    
    # Envoyer l'alerte à la console
    if ($Channels -contains "Console") {
        Write-Log "ALERT: $Subject" -Level "Error"
        Write-Log $Message -Level "Error"
    }
    
    # Envoyer l'alerte par email
    if ($Channels -contains "Email") {
        # Charger la configuration d'alerte
        $configPath = Join-Path -Path $parentPath -ChildPath "config\alerts\email.json"
        
        if (Test-Path -Path $configPath) {
            try {
                $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                
                $smtpServer = $config.smtp_server
                $smtpPort = $config.smtp_port
                $useSSL = $config.use_ssl
                $username = $config.username
                $password = $config.password
                $fromAddress = $config.from_address
                $toAddresses = $config.to_addresses
                
                $mailParams = @{
                    SmtpServer = $smtpServer
                    Port = $smtpPort
                    UseSsl = $useSSL
                    From = $fromAddress
                    To = $toAddresses
                    Subject = "Export Alert: $Subject"
                    Body = $Message
                    BodyAsHtml = $true
                }
                
                if (-not [string]::IsNullOrEmpty($username) -and -not [string]::IsNullOrEmpty($password)) {
                    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
                    $credentials = New-Object System.Management.Automation.PSCredential($username, $securePassword)
                    $mailParams.Credential = $credentials
                }
                
                Send-MailMessage @mailParams
                Write-Log "Alert email sent to $($toAddresses -join ', ')" -Level "Info"
            } catch {
                Write-Log "Error sending alert email: $($_.Exception.Message)" -Level "Error"
            }
        } else {
            Write-Log "Email alert configuration not found: $configPath" -Level "Warning"
        }
    }
    
    # Envoyer l'alerte à Microsoft Teams
    if ($Channels -contains "Teams") {
        # Charger la configuration d'alerte
        $configPath = Join-Path -Path $parentPath -ChildPath "config\alerts\teams.json"
        
        if (Test-Path -Path $configPath) {
            try {
                $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                
                $webhookUrl = $config.webhook_url
                
                $body = @{
                    "@type" = "MessageCard"
                    "@context" = "http://schema.org/extensions"
                    themeColor = "FF0000"
                    summary = $Subject
                    sections = @(
                        @{
                            activityTitle = $Subject
                            activitySubtitle = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                            activityImage = "https://raw.githubusercontent.com/microsoft/vscode-codicons/main/src/icons/alert.svg"
                            text = $Message
                        }
                    )
                }
                
                $bodyJson = $body | ConvertTo-Json -Depth 10
                
                Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $bodyJson -ContentType "application/json"
                Write-Log "Alert sent to Microsoft Teams" -Level "Info"
            } catch {
                Write-Log "Error sending alert to Microsoft Teams: $($_.Exception.Message)" -Level "Error"
            }
        } else {
            Write-Log "Teams alert configuration not found: $configPath" -Level "Warning"
        }
    }
    
    # Envoyer l'alerte à Slack
    if ($Channels -contains "Slack") {
        # Charger la configuration d'alerte
        $configPath = Join-Path -Path $parentPath -ChildPath "config\alerts\slack.json"
        
        if (Test-Path -Path $configPath) {
            try {
                $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
                
                $webhookUrl = $config.webhook_url
                $channel = $config.channel
                
                $body = @{
                    channel = $channel
                    username = "Export Monitor"
                    icon_emoji = ":warning:"
                    attachments = @(
                        @{
                            fallback = $Subject
                            color = "#FF0000"
                            pretext = "Export Alert"
                            author_name = "Export Monitor"
                            title = $Subject
                            text = $Message
                            footer = "Export Monitor"
                            footer_icon = "https://platform.slack-edge.com/img/default_application_icon.png"
                            ts = [Math]::Floor([decimal](Get-Date -UFormat "%s"))
                        }
                    )
                }
                
                $bodyJson = $body | ConvertTo-Json -Depth 10
                
                Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $bodyJson -ContentType "application/json"
                Write-Log "Alert sent to Slack channel $channel" -Level "Info"
            } catch {
                Write-Log "Error sending alert to Slack: $($_.Exception.Message)" -Level "Error"
            }
        } else {
            Write-Log "Slack alert configuration not found: $configPath" -Level "Warning"
        }
    }
    
    # Envoyer l'alerte à un fichier
    if ($Channels -contains "File") {
        $alertsPath = Join-Path -Path $rootPath -ChildPath "logs\alerts"
        
        if (-not (Test-Path -Path $alertsPath)) {
            New-Item -Path $alertsPath -ItemType Directory -Force | Out-Null
        }
        
        $alertFilePath = Join-Path -Path $alertsPath -ChildPath "export_alert_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        
        try {
            "ALERT: $Subject`r`n`r`n$Message`r`n`r`nTimestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Out-File -FilePath $alertFilePath -Encoding UTF8
            Write-Log "Alert saved to file: $alertFilePath" -Level "Info"
        } catch {
            Write-Log "Error saving alert to file: $($_.Exception.Message)" -Level "Error"
        }
    }
}

# Fonction pour vérifier les erreurs récentes et envoyer des alertes
function Test-RecentExportErrors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$HoursToCheck = 24,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Console", "Email", "Teams", "Slack", "File")]
        [string[]]$AlertChannels = @("Console")
    )
    
    $startDate = (Get-Date).AddHours(-$HoursToCheck)
    $errors = Get-ExportErrors -StartDate $startDate
    
    if ($errors.Count -eq 0) {
        Write-Log "No export errors found in the last $HoursToCheck hours" -Level "Info"
        return $true
    }
    
    # Regrouper les erreurs par type de stockage
    $errorsByType = $errors | Group-Object -Property { $_.destination.type }
    
    # Créer le message d'alerte
    $subject = "$($errors.Count) export errors in the last $HoursToCheck hours"
    
    $message = @"
<h2>Export Errors Summary</h2>
<p>The following export errors occurred in the last $HoursToCheck hours:</p>

<h3>Errors by Storage Type</h3>
<ul>
$(foreach ($type in $errorsByType) {
    "<li><strong>$($type.Name):</strong> $($type.Count) errors</li>"
})
</ul>

<h3>Recent Errors</h3>
<table border="1" cellpadding="5" cellspacing="0">
<tr>
    <th>Timestamp</th>
    <th>Archive</th>
    <th>Destination</th>
    <th>Error</th>
</tr>
$(
    $recentErrors = $errors | Select-Object -First 10
    foreach ($error in $recentErrors) {
        $timestamp = [DateTime]::Parse($error.timestamp).ToString("yyyy-MM-dd HH:mm:ss")
        $archive = [System.IO.Path]::GetFileName($error.archive.path)
        $destination = "$($error.destination.type):$($error.destination.path)"
        $errorMessage = $error.result.error_message
        "<tr><td>$timestamp</td><td>$archive</td><td>$destination</td><td>$errorMessage</td></tr>"
    }
)
</table>

<p>Please check the export logs for more details.</p>
"@
    
    # Envoyer l'alerte
    Send-ExportAlert -Subject $subject -Message $message -Channels $AlertChannels
    
    return $true
}

# Fonction principale pour surveiller les opérations d'exportation
function Watch-ExportOperations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Status", "Errors", "Retry", "Alert", "Report")]
        [string]$Action = "Status",
        
        [Parameter(Mandatory = $false)]
        [string]$ExportId = "",
        
        [Parameter(Mandatory = $false)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory = $false)]
        [DateTime]$EndDate,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Console", "Email", "Teams", "Slack", "File")]
        [string[]]$AlertChannels = @("Console")
    )
    
    switch ($Action) {
        "Status" {
            # Obtenir les statistiques d'exportation
            $logs = Get-ExportLogs -StartDate $StartDate -EndDate $EndDate
            
            if ($logs.Count -eq 0) {
                Write-Log "No export logs found for the specified period" -Level "Info"
                return @{
                    TotalExports = 0
                    SuccessfulExports = 0
                    FailedExports = 0
                    SuccessRate = 0
                    TotalSize = 0
                }
            }
            
            $totalExports = $logs.Count
            $successfulExports = ($logs | Where-Object { $_.result.success -eq $true }).Count
            $failedExports = $totalExports - $successfulExports
            $successRate = if ($totalExports -gt 0) { [Math]::Round(($successfulExports / $totalExports) * 100, 2) } else { 0 }
            
            $totalSize = ($logs | Measure-Object -Property { $_.archive.size } -Sum).Sum
            $totalSizeMB = [Math]::Round($totalSize / 1MB, 2)
            
            Write-Log "Export Status:" -Level "Info"
            Write-Log "  Total exports: $totalExports" -Level "Info"
            Write-Log "  Successful exports: $successfulExports" -Level "Info"
            Write-Log "  Failed exports: $failedExports" -Level "Info"
            Write-Log "  Success rate: $successRate%" -Level "Info"
            Write-Log "  Total size: $totalSizeMB MB" -Level "Info"
            
            return @{
                TotalExports = $totalExports
                SuccessfulExports = $successfulExports
                FailedExports = $failedExports
                SuccessRate = $successRate
                TotalSize = $totalSize
            }
        }
        "Errors" {
            # Obtenir les erreurs d'exportation
            $errors = Get-ExportErrors -StartDate $StartDate -EndDate $EndDate
            
            if ($errors.Count -eq 0) {
                Write-Log "No export errors found for the specified period" -Level "Info"
                return @()
            }
            
            Write-Log "Export Errors ($($errors.Count)):" -Level "Info"
            
            foreach ($error in $errors) {
                $timestamp = [DateTime]::Parse($error.timestamp).ToString("yyyy-MM-dd HH:mm:ss")
                $archive = [System.IO.Path]::GetFileName($error.archive.path)
                $destination = "$($error.destination.type):$($error.destination.path)"
                $errorMessage = $error.result.error_message
                
                Write-Log "  - [$timestamp] $archive -> $destination: $errorMessage" -Level "Error"
            }
            
            return $errors
        }
        "Retry" {
            # Réessayer une exportation échouée
            if ([string]::IsNullOrEmpty($ExportId)) {
                Write-Log "Export ID is required for retry" -Level "Error"
                return $false
            }
            
            return Restart-FailedExport -ExportId $ExportId
        }
        "Alert" {
            # Vérifier les erreurs récentes et envoyer des alertes
            return Test-RecentExportErrors -HoursToCheck 24 -AlertChannels $AlertChannels
        }
        "Report" {
            # Générer un rapport d'exportation
            return New-ExportReport -StartDate $StartDate -EndDate $EndDate -OutputPath $OutputPath
        }
        default {
            Write-Log "Invalid action: $Action" -Level "Error"
            return $false
        }
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Watch-ExportOperations -Action $Action -ExportId $ExportId -StartDate $StartDate -EndDate $EndDate -OutputPath $OutputPath -AlertChannels $AlertChannels
}



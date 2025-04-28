# Script pour gÃ©nÃ©rer des rapports d'erreurs

# Importer le module de collecte de donnÃ©es
$collectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "ErrorDataCollector.ps1"
if (Test-Path -Path $collectorPath) {
    . $collectorPath
}
else {
    Write-Error "Le module de collecte de donnÃ©es est introuvable: $collectorPath"
    return
}

# Configuration des rapports
$ReportConfig = @{
    # Dossier de sortie des rapports
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorReports"
    
    # Format de sortie par dÃ©faut
    DefaultFormat = "HTML"
    
    # PÃ©riode par dÃ©faut (en jours)
    DefaultPeriod = 7
}

# Fonction pour initialiser le systÃ¨me de rapports
function Initialize-ErrorReports {
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("HTML", "CSV", "JSON", "PDF", "Text")]
        [string]$DefaultFormat = "",
        
        [Parameter(Mandatory = $false)]
        [int]$DefaultPeriod = 0
    )
    
    # Mettre Ã  jour la configuration
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $ReportConfig.OutputFolder = $OutputFolder
    }
    
    if (-not [string]::IsNullOrEmpty($DefaultFormat)) {
        $ReportConfig.DefaultFormat = $DefaultFormat
    }
    
    if ($DefaultPeriod -gt 0) {
        $ReportConfig.DefaultPeriod = $DefaultPeriod
    }
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $ReportConfig.OutputFolder)) {
        New-Item -Path $ReportConfig.OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Initialiser le collecteur de donnÃ©es
    Initialize-ErrorDataCollector
    
    return $ReportConfig
}

# Fonction pour gÃ©nÃ©rer un rapport d'erreurs
function New-ErrorReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport d'erreurs",
        
        [Parameter(Mandatory = $false)]
        [int]$Days = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Severity = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("HTML", "CSV", "JSON", "PDF", "Text")]
        [string]$Format = "",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Utiliser les valeurs par dÃ©faut si non spÃ©cifiÃ©es
    if ($Days -le 0) {
        $Days = $ReportConfig.DefaultPeriod
    }
    
    if ([string]::IsNullOrEmpty($Format)) {
        $Format = $ReportConfig.DefaultFormat
    }
    
    # Obtenir les donnÃ©es
    $errors = Get-ErrorData -Days $Days -Category $Category -Severity $Severity -Source $Source
    $stats = Get-ErrorStatistics
    
    # DÃ©terminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "ErrorReport-$timestamp.$($Format.ToLower())"
        $OutputPath = Join-Path -Path $ReportConfig.OutputFolder -ChildPath $fileName
    }
    
    # GÃ©nÃ©rer le rapport selon le format
    switch ($Format) {
        "HTML" {
            $html = New-ErrorReportHtml -Title $Title -Errors $errors -Stats $stats -Days $Days
            $html | Set-Content -Path $OutputPath -Encoding UTF8
        }
        "CSV" {
            $errors | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        }
        "JSON" {
            $report = @{
                Title = $Title
                GeneratedAt = Get-Date -Format "o"
                Period = $Days
                Filters = @{
                    Category = $Category
                    Severity = $Severity
                    Source = $Source
                }
                Statistics = $stats
                Errors = $errors
            }
            
            $report | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
        }
        "PDF" {
            # GÃ©nÃ©rer d'abord en HTML
            $html = New-ErrorReportHtml -Title $Title -Errors $errors -Stats $stats -Days $Days
            $htmlPath = [System.IO.Path]::ChangeExtension($OutputPath, "html")
            $html | Set-Content -Path $htmlPath -Encoding UTF8
            
            # Convertir en PDF si wkhtmltopdf est disponible
            $wkhtmltopdf = Get-Command "wkhtmltopdf" -ErrorAction SilentlyContinue
            
            if ($wkhtmltopdf) {
                & $wkhtmltopdf $htmlPath $OutputPath
                Remove-Item -Path $htmlPath -Force
            }
            else {
                Write-Warning "wkhtmltopdf n'est pas installÃ©. Le rapport a Ã©tÃ© gÃ©nÃ©rÃ© en HTML Ã  la place."
                $OutputPath = $htmlPath
            }
        }
        "Text" {
            $text = New-ErrorReportText -Title $Title -Errors $errors -Stats $stats -Days $Days
            $text | Set-Content -Path $OutputPath -Encoding UTF8
        }
    }
    
    # Ouvrir le rapport si demandÃ©
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Fonction pour gÃ©nÃ©rer un rapport HTML
function New-ErrorReportHtml {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [object[]]$Errors,
        
        [Parameter(Mandatory = $true)]
        [object]$Stats,
        
        [Parameter(Mandatory = $true)]
        [int]$Days
    )
    
    # PrÃ©parer les donnÃ©es pour les graphiques
    $dailyErrorsData = @()
    $daysToShow = [Math]::Min($Days, 30)  # Limiter Ã  30 jours pour le graphique
    
    for ($i = $daysToShow - 1; $i -ge 0; $i--) {
        $day = (Get-Date).AddDays(-$i).ToString("yyyy-MM-dd")
        $count = if ($Stats.DailyErrors.$day) { $Stats.DailyErrors.$day } else { 0 }
        
        $dailyErrorsData += @{
            day = $day
            count = $count
        }
    }
    
    # GÃ©nÃ©rer le HTML
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$Title</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .summary {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        .summary-card {
            background-color: #f8f9fa;
            border-radius: 8px;
            padding: 15px;
            flex: 1;
            min-width: 200px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .summary-card h3 {
            margin-top: 0;
            margin-bottom: 10px;
            font-size: 16px;
        }
        
        .summary-value {
            font-size: 24px;
            font-weight: bold;
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        
        th, td {
            padding: 12px 15px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        
        th {
            background-color: #4caf50;
            color: white;
        }
        
        tr:hover {
            background-color: #f5f5f5;
        }
        
        .severity-error {
            color: #f44336;
            font-weight: bold;
        }
        
        .severity-warning {
            color: #ff9800;
            font-weight: bold;
        }
        
        .severity-info {
            color: #2196f3;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <div>
                <span>GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <h3>Total des erreurs</h3>
                <div class="summary-value">$($Errors.Count)</div>
            </div>
            
            <div class="summary-card">
                <h3>PÃ©riode</h3>
                <div class="summary-value">$Days jours</div>
            </div>
            
            <div class="summary-card">
                <h3>Erreurs par jour (moyenne)</h3>
                <div class="summary-value">$(if ($Days -gt 0) { [Math]::Round($Errors.Count / $Days, 1) } else { "N/A" })</div>
            </div>
        </div>
        
        <h2>RÃ©partition des erreurs</h2>
        
        <div class="summary">
            <div class="summary-card">
                <h3>Par sÃ©vÃ©ritÃ©</h3>
                <ul>
                $(foreach ($severity in $Stats.ErrorsBySeverity.PSObject.Properties) {
                    "<li><strong>$($severity.Name):</strong> $($severity.Value)</li>"
                })
                </ul>
            </div>
            
            <div class="summary-card">
                <h3>Par catÃ©gorie</h3>
                <ul>
                $(foreach ($category in $Stats.ErrorsByCategory.PSObject.Properties) {
                    "<li><strong>$($category.Name):</strong> $($category.Value)</li>"
                })
                </ul>
            </div>
            
            <div class="summary-card">
                <h3>Par source</h3>
                <ul>
                $(foreach ($source in $Stats.ErrorsBySource.PSObject.Properties) {
                    "<li><strong>$($source.Name):</strong> $($source.Value)</li>"
                })
                </ul>
            </div>
        </div>
        
        <h2>Liste des erreurs</h2>
        
        <table>
            <thead>
                <tr>
                    <th>Date</th>
                    <th>SÃ©vÃ©ritÃ©</th>
                    <th>CatÃ©gorie</th>
                    <th>Source</th>
                    <th>Message</th>
                </tr>
            </thead>
            <tbody>
                $(foreach ($error in ($Errors | Sort-Object -Property Timestamp -Descending)) {
                    $severityClass = switch ($error.Severity) {
                        "Error" { "severity-error" }
                        "Warning" { "severity-warning" }
                        "Info" { "severity-info" }
                        default { "" }
                    }
                    
                    $timestamp = [DateTime]::Parse($error.Timestamp).ToString("yyyy-MM-dd HH:mm:ss")
                    
                    "<tr>
                        <td>$timestamp</td>
                        <td class='$severityClass'>$($error.Severity)</td>
                        <td>$($error.Category)</td>
                        <td>$($error.Source)</td>
                        <td>$($error.Message)</td>
                    </tr>"
                })
            </tbody>
        </table>
        
        <div class="footer">
            <p>Rapport gÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | PÃ©riode: $Days jours</p>
        </div>
    </div>
</body>
</html>
"@
    
    return $html
}

# Fonction pour gÃ©nÃ©rer un rapport texte
function New-ErrorReportText {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [object[]]$Errors,
        
        [Parameter(Mandatory = $true)]
        [object]$Stats,
        
        [Parameter(Mandatory = $true)]
        [int]$Days
    )
    
    $text = @"
$Title
$("=" * $Title.Length)

GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
PÃ©riode: $Days jours

RÃ‰SUMÃ‰
------
Total des erreurs: $($Errors.Count)
Moyenne par jour: $(if ($Days -gt 0) { [Math]::Round($Errors.Count / $Days, 1) } else { "N/A" })

RÃ‰PARTITION PAR SÃ‰VÃ‰RITÃ‰
------------------------
$(foreach ($severity in $Stats.ErrorsBySeverity.PSObject.Properties) {
    "$($severity.Name): $($severity.Value)"
})

RÃ‰PARTITION PAR CATÃ‰GORIE
-------------------------
$(foreach ($category in $Stats.ErrorsByCategory.PSObject.Properties) {
    "$($category.Name): $($category.Value)"
})

RÃ‰PARTITION PAR SOURCE
---------------------
$(foreach ($source in $Stats.ErrorsBySource.PSObject.Properties) {
    "$($source.Name): $($source.Value)"
})

LISTE DES ERREURS
----------------
$(foreach ($error in ($Errors | Sort-Object -Property Timestamp -Descending)) {
    $timestamp = [DateTime]::Parse($error.Timestamp).ToString("yyyy-MM-dd HH:mm:ss")
    
    "[$timestamp] [$($error.Severity)] [$($error.Category)] [$($error.Source)]`n$($error.Message)`n"
})

"@
    
    return $text
}

# Fonction pour planifier des rapports automatiques
function Register-ErrorReportSchedule {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Daily", "Weekly", "Monthly")]
        [string]$Frequency,
        
        [Parameter(Mandatory = $false)]
        [int]$Days = 0,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("HTML", "CSV", "JSON", "PDF", "Text")]
        [string]$Format = "",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = "",
        
        [Parameter(Mandatory = $false)]
        [string[]]$EmailRecipients = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Utiliser les valeurs par dÃ©faut si non spÃ©cifiÃ©es
    if ($Days -le 0) {
        $Days = $ReportConfig.DefaultPeriod
    }
    
    if ([string]::IsNullOrEmpty($Format)) {
        $Format = $ReportConfig.DefaultFormat
    }
    
    if ([string]::IsNullOrEmpty($OutputFolder)) {
        $OutputFolder = $ReportConfig.OutputFolder
    }
    
    # CrÃ©er le dossier de tÃ¢ches planifiÃ©es s'il n'existe pas
    $scheduledTasksFolder = Join-Path -Path $OutputFolder -ChildPath "ScheduledTasks"
    if (-not (Test-Path -Path $scheduledTasksFolder)) {
        New-Item -Path $scheduledTasksFolder -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er le script de tÃ¢che planifiÃ©e
    $scriptName = "ErrorReport-$Frequency.ps1"
    $scriptPath = Join-Path -Path $scheduledTasksFolder -ChildPath $scriptName
    
    $scriptContent = @"
# Script de gÃ©nÃ©ration de rapport automatique
# FrÃ©quence: $Frequency
# GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Importer le module de rapports
`$reportModulePath = "$PSCommandPath"
if (Test-Path -Path `$reportModulePath) {
    . `$reportModulePath
}
else {
    Write-Error "Le module de rapports est introuvable: `$reportModulePath"
    exit 1
}

# GÃ©nÃ©rer le rapport
`$title = "Rapport d'erreurs $Frequency"
`$outputPath = New-ErrorReport -Title `$title -Days $Days -Format "$Format" -OutputPath ""

# Envoyer par email si des destinataires sont spÃ©cifiÃ©s
`$emailRecipients = @('$($EmailRecipients -join "', '")')
if (`$emailRecipients.Count -gt 0 -and `$emailRecipients[0] -ne '') {
    # VÃ©rifier si le module de notifications est disponible
    `$notificationModulePath = Join-Path -Path (Split-Path -Parent `$reportModulePath) -ChildPath "ErrorNotifications.ps1"
    if (Test-Path -Path `$notificationModulePath) {
        . `$notificationModulePath
        
        # Configurer les notifications par email
        Set-ErrorEmailNotifications -SmtpServer "smtp.example.com" -Port 587 -From "reports@example.com" -To `$emailRecipients -Enable
        
        # Envoyer le rapport par email
        `$emailParams = @{
            SmtpServer = `$NotificationConfig.Email.SmtpServer
            Port = `$NotificationConfig.Email.Port
            UseSsl = `$NotificationConfig.Email.UseSsl
            From = `$NotificationConfig.Email.From
            To = `$emailRecipients
            Subject = `$title
            Body = "Veuillez trouver ci-joint le rapport d'erreurs $Frequency."
            Attachments = `$outputPath
        }
        
        if (`$null -ne `$NotificationConfig.Email.Credentials) {
            `$emailParams.Credential = `$NotificationConfig.Email.Credentials
        }
        
        try {
            Send-MailMessage @emailParams
            Write-Host "Rapport envoyÃ© par email Ã  `$(`$emailRecipients -join ', ')"
        }
        catch {
            Write-Error "Erreur lors de l'envoi du rapport par email: `$_"
        }
    }
    else {
        Write-Warning "Le module de notifications est introuvable. Le rapport n'a pas Ã©tÃ© envoyÃ© par email."
    }
}

Write-Host "Rapport gÃ©nÃ©rÃ©: `$outputPath"
"@
    
    $scriptContent | Set-Content -Path $scriptPath -Encoding UTF8
    
    # CrÃ©er la tÃ¢che planifiÃ©e
    $taskName = "ErrorReport-$Frequency"
    $taskDescription = "GÃ©nÃ©ration automatique de rapport d'erreurs ($Frequency)"
    
    # DÃ©terminer le dÃ©clencheur
    $trigger = switch ($Frequency) {
        "Daily" { New-ScheduledTaskTrigger -Daily -At "08:00" }
        "Weekly" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "08:00" }
        "Monthly" { New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At "08:00" }
    }
    
    # CrÃ©er l'action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    
    # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingTask -and -not $Force) {
        Write-Warning "La tÃ¢che planifiÃ©e '$taskName' existe dÃ©jÃ . Utilisez -Force pour la remplacer."
        return $false
    }
    
    # Supprimer la tÃ¢che existante si nÃ©cessaire
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    # CrÃ©er la tÃ¢che
    $task = Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Trigger $trigger -Action $action -RunLevel Highest
    
    if ($task) {
        Write-Host "TÃ¢che planifiÃ©e '$taskName' crÃ©Ã©e avec succÃ¨s."
        return $true
    }
    else {
        Write-Error "Erreur lors de la crÃ©ation de la tÃ¢che planifiÃ©e '$taskName'."
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorReports, New-ErrorReport, Register-ErrorReportSchedule

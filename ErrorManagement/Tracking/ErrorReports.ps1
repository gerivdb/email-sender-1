# Script pour générer des rapports d'erreurs

# Importer le module de collecte de données
$collectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "ErrorDataCollector.ps1"
if (Test-Path -Path $collectorPath) {
    . $collectorPath
}
else {
    Write-Error "Le module de collecte de données est introuvable: $collectorPath"
    return
}

# Configuration des rapports
$ReportConfig = @{
    # Dossier de sortie des rapports
    OutputFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorReports"
    
    # Format de sortie par défaut
    DefaultFormat = "HTML"
    
    # Période par défaut (en jours)
    DefaultPeriod = 7
}

# Fonction pour initialiser le système de rapports
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
    
    # Mettre à jour la configuration
    if (-not [string]::IsNullOrEmpty($OutputFolder)) {
        $ReportConfig.OutputFolder = $OutputFolder
    }
    
    if (-not [string]::IsNullOrEmpty($DefaultFormat)) {
        $ReportConfig.DefaultFormat = $DefaultFormat
    }
    
    if ($DefaultPeriod -gt 0) {
        $ReportConfig.DefaultPeriod = $DefaultPeriod
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $ReportConfig.OutputFolder)) {
        New-Item -Path $ReportConfig.OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Initialiser le collecteur de données
    Initialize-ErrorDataCollector
    
    return $ReportConfig
}

# Fonction pour générer un rapport d'erreurs
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
    
    # Utiliser les valeurs par défaut si non spécifiées
    if ($Days -le 0) {
        $Days = $ReportConfig.DefaultPeriod
    }
    
    if ([string]::IsNullOrEmpty($Format)) {
        $Format = $ReportConfig.DefaultFormat
    }
    
    # Obtenir les données
    $errors = Get-ErrorData -Days $Days -Category $Category -Severity $Severity -Source $Source
    $stats = Get-ErrorStatistics
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "ErrorReport-$timestamp.$($Format.ToLower())"
        $OutputPath = Join-Path -Path $ReportConfig.OutputFolder -ChildPath $fileName
    }
    
    # Générer le rapport selon le format
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
            # Générer d'abord en HTML
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
                Write-Warning "wkhtmltopdf n'est pas installé. Le rapport a été généré en HTML à la place."
                $OutputPath = $htmlPath
            }
        }
        "Text" {
            $text = New-ErrorReportText -Title $Title -Errors $errors -Stats $stats -Days $Days
            $text | Set-Content -Path $OutputPath -Encoding UTF8
        }
    }
    
    # Ouvrir le rapport si demandé
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Fonction pour générer un rapport HTML
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
    
    # Préparer les données pour les graphiques
    $dailyErrorsData = @()
    $daysToShow = [Math]::Min($Days, 30)  # Limiter à 30 jours pour le graphique
    
    for ($i = $daysToShow - 1; $i -ge 0; $i--) {
        $day = (Get-Date).AddDays(-$i).ToString("yyyy-MM-dd")
        $count = if ($Stats.DailyErrors.$day) { $Stats.DailyErrors.$day } else { 0 }
        
        $dailyErrorsData += @{
            day = $day
            count = $count
        }
    }
    
    # Générer le HTML
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
                <span>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="summary">
            <div class="summary-card">
                <h3>Total des erreurs</h3>
                <div class="summary-value">$($Errors.Count)</div>
            </div>
            
            <div class="summary-card">
                <h3>Période</h3>
                <div class="summary-value">$Days jours</div>
            </div>
            
            <div class="summary-card">
                <h3>Erreurs par jour (moyenne)</h3>
                <div class="summary-value">$(if ($Days -gt 0) { [Math]::Round($Errors.Count / $Days, 1) } else { "N/A" })</div>
            </div>
        </div>
        
        <h2>Répartition des erreurs</h2>
        
        <div class="summary">
            <div class="summary-card">
                <h3>Par sévérité</h3>
                <ul>
                $(foreach ($severity in $Stats.ErrorsBySeverity.PSObject.Properties) {
                    "<li><strong>$($severity.Name):</strong> $($severity.Value)</li>"
                })
                </ul>
            </div>
            
            <div class="summary-card">
                <h3>Par catégorie</h3>
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
                    <th>Sévérité</th>
                    <th>Catégorie</th>
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
            <p>Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") | Période: $Days jours</p>
        </div>
    </div>
</body>
</html>
"@
    
    return $html
}

# Fonction pour générer un rapport texte
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

Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Période: $Days jours

RÉSUMÉ
------
Total des erreurs: $($Errors.Count)
Moyenne par jour: $(if ($Days -gt 0) { [Math]::Round($Errors.Count / $Days, 1) } else { "N/A" })

RÉPARTITION PAR SÉVÉRITÉ
------------------------
$(foreach ($severity in $Stats.ErrorsBySeverity.PSObject.Properties) {
    "$($severity.Name): $($severity.Value)"
})

RÉPARTITION PAR CATÉGORIE
-------------------------
$(foreach ($category in $Stats.ErrorsByCategory.PSObject.Properties) {
    "$($category.Name): $($category.Value)"
})

RÉPARTITION PAR SOURCE
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
    
    # Utiliser les valeurs par défaut si non spécifiées
    if ($Days -le 0) {
        $Days = $ReportConfig.DefaultPeriod
    }
    
    if ([string]::IsNullOrEmpty($Format)) {
        $Format = $ReportConfig.DefaultFormat
    }
    
    if ([string]::IsNullOrEmpty($OutputFolder)) {
        $OutputFolder = $ReportConfig.OutputFolder
    }
    
    # Créer le dossier de tâches planifiées s'il n'existe pas
    $scheduledTasksFolder = Join-Path -Path $OutputFolder -ChildPath "ScheduledTasks"
    if (-not (Test-Path -Path $scheduledTasksFolder)) {
        New-Item -Path $scheduledTasksFolder -ItemType Directory -Force | Out-Null
    }
    
    # Créer le script de tâche planifiée
    $scriptName = "ErrorReport-$Frequency.ps1"
    $scriptPath = Join-Path -Path $scheduledTasksFolder -ChildPath $scriptName
    
    $scriptContent = @"
# Script de génération de rapport automatique
# Fréquence: $Frequency
# Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Importer le module de rapports
`$reportModulePath = "$PSCommandPath"
if (Test-Path -Path `$reportModulePath) {
    . `$reportModulePath
}
else {
    Write-Error "Le module de rapports est introuvable: `$reportModulePath"
    exit 1
}

# Générer le rapport
`$title = "Rapport d'erreurs $Frequency"
`$outputPath = New-ErrorReport -Title `$title -Days $Days -Format "$Format" -OutputPath ""

# Envoyer par email si des destinataires sont spécifiés
`$emailRecipients = @('$($EmailRecipients -join "', '")')
if (`$emailRecipients.Count -gt 0 -and `$emailRecipients[0] -ne '') {
    # Vérifier si le module de notifications est disponible
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
            Write-Host "Rapport envoyé par email à `$(`$emailRecipients -join ', ')"
        }
        catch {
            Write-Error "Erreur lors de l'envoi du rapport par email: `$_"
        }
    }
    else {
        Write-Warning "Le module de notifications est introuvable. Le rapport n'a pas été envoyé par email."
    }
}

Write-Host "Rapport généré: `$outputPath"
"@
    
    $scriptContent | Set-Content -Path $scriptPath -Encoding UTF8
    
    # Créer la tâche planifiée
    $taskName = "ErrorReport-$Frequency"
    $taskDescription = "Génération automatique de rapport d'erreurs ($Frequency)"
    
    # Déterminer le déclencheur
    $trigger = switch ($Frequency) {
        "Daily" { New-ScheduledTaskTrigger -Daily -At "08:00" }
        "Weekly" { New-ScheduledTaskTrigger -Weekly -DaysOfWeek Monday -At "08:00" }
        "Monthly" { New-ScheduledTaskTrigger -Monthly -DaysOfMonth 1 -At "08:00" }
    }
    
    # Créer l'action
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""
    
    # Vérifier si la tâche existe déjà
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingTask -and -not $Force) {
        Write-Warning "La tâche planifiée '$taskName' existe déjà. Utilisez -Force pour la remplacer."
        return $false
    }
    
    # Supprimer la tâche existante si nécessaire
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    # Créer la tâche
    $task = Register-ScheduledTask -TaskName $taskName -Description $taskDescription -Trigger $trigger -Action $action -RunLevel Highest
    
    if ($task) {
        Write-Host "Tâche planifiée '$taskName' créée avec succès."
        return $true
    }
    else {
        Write-Error "Erreur lors de la création de la tâche planifiée '$taskName'."
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ErrorReports, New-ErrorReport, Register-ErrorReportSchedule

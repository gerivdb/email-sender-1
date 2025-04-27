# Generate-SqlPermissionComplianceReport.ps1
# Script pour générer un rapport de conformité des permissions SQL Server

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "SqlPermissionComplianceReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html",

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeDatabases = @("tempdb", "model"),

    [Parameter(Mandatory = $false)]
    [string]$Severity = "All",

    [Parameter(Mandatory = $false)]
    [switch]$IncludeObjectLevel,

    [Parameter(Mandatory = $false)]
    [switch]$SendEmail,

    [Parameter(Mandatory = $false)]
    [string]$SmtpServer,

    [Parameter(Mandatory = $false)]
    [string]$FromAddress,

    [Parameter(Mandatory = $false)]
    [string[]]$ToAddress,

    [Parameter(Mandatory = $false)]
    [string]$Subject = "Rapport de conformité des permissions SQL Server - $ServerInstance"
)

begin {
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\module" -Resolve
    Import-Module $modulePath -Force

    # Paramètres de connexion SQL Server
    $sqlParams = @{
        ServerInstance = $ServerInstance
        Database = "master"
    }

    if ($Credential) {
        $sqlParams.Credential = $Credential
    }

    # Créer le dossier de sortie si nécessaire
    $outputFolder = Split-Path -Path $OutputPath -Parent
    if ($outputFolder -and -not (Test-Path -Path $outputFolder)) {
        New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
    }

    # Définir les règles critiques (qui nécessitent une attention immédiate)
    $criticalRules = @("SVR-002", "SVR-005", "DB-003", "DB-004", "OBJ-003")

    # Définir les seuils d'alerte
    $thresholds = @{
        Critical = 0    # Aucune anomalie critique n'est acceptable
        High = 5        # Jusqu'à 5 anomalies de sévérité élevée sont tolérées
        Medium = 10     # Jusqu'à 10 anomalies de sévérité moyenne sont tolérées
        Low = 20        # Jusqu'à 20 anomalies de sévérité faible sont tolérées
    }

    # Fonction pour déterminer le statut global
    function Get-ComplianceStatus {
        param (
            [int]$CriticalCount,
            [int]$HighCount,
            [int]$MediumCount,
            [int]$LowCount
        )

        if ($CriticalCount -gt $thresholds.Critical) {
            return "Non conforme"
        }
        elseif ($HighCount -gt $thresholds.High) {
            return "Partiellement conforme"
        }
        elseif ($MediumCount -gt $thresholds.Medium) {
            return "Majoritairement conforme"
        }
        elseif ($LowCount -gt $thresholds.Low) {
            return "Presque conforme"
        }
        else {
            return "Conforme"
        }
    }

    # Fonction pour générer un graphique de conformité
    function Get-ComplianceChart {
        param (
            [int]$CriticalCount,
            [int]$HighCount,
            [int]$MediumCount,
            [int]$LowCount,
            [string]$Status
        )

        $statusColor = switch ($Status) {
            "Conforme" { "green" }
            "Presque conforme" { "lightgreen" }
            "Majoritairement conforme" { "yellow" }
            "Partiellement conforme" { "orange" }
            "Non conforme" { "red" }
            default { "gray" }
        }

        $totalIssues = $CriticalCount + $HighCount + $MediumCount + $LowCount
        $chartHtml = @"
<div style="width: 100%; margin: 20px 0;">
    <h3>Statut de conformité: <span style="color: $statusColor;">$Status</span></h3>
    <div style="display: flex; height: 30px; width: 100%; border-radius: 5px; overflow: hidden;">
"@

        if ($totalIssues -gt 0) {
            $criticalWidth = [math]::Round(($CriticalCount / $totalIssues) * 100)
            $highWidth = [math]::Round(($HighCount / $totalIssues) * 100)
            $mediumWidth = [math]::Round(($MediumCount / $totalIssues) * 100)
            $lowWidth = [math]::Round(($LowCount / $totalIssues) * 100)

            if ($criticalWidth -gt 0) {
                $chartHtml += "<div style='width: $($criticalWidth)%; background-color: red;' title='Critique: $CriticalCount'></div>"
            }
            if ($highWidth -gt 0) {
                $chartHtml += "<div style='width: $($highWidth)%; background-color: orange;' title='Élevée: $HighCount'></div>"
            }
            if ($mediumWidth -gt 0) {
                $chartHtml += "<div style='width: $($mediumWidth)%; background-color: yellow;' title='Moyenne: $MediumCount'></div>"
            }
            if ($lowWidth -gt 0) {
                $chartHtml += "<div style='width: $($lowWidth)%; background-color: lightgreen;' title='Faible: $LowCount'></div>"
            }
        }
        else {
            $chartHtml += "<div style='width: 100%; background-color: green;' title='Aucune anomalie'></div>"
        }

        $chartHtml += @"
    </div>
    <div style="display: flex; justify-content: space-between; margin-top: 5px; font-size: 12px;">
        <div><span style="display: inline-block; width: 10px; height: 10px; background-color: red;"></span> Critique: $CriticalCount</div>
        <div><span style="display: inline-block; width: 10px; height: 10px; background-color: orange;"></span> Élevée: $HighCount</div>
        <div><span style="display: inline-block; width: 10px; height: 10px; background-color: yellow;"></span> Moyenne: $MediumCount</div>
        <div><span style="display: inline-block; width: 10px; height: 10px; background-color: lightgreen;"></span> Faible: $LowCount</div>
    </div>
</div>
"@

        return $chartHtml
    }
}

process {
    try {
        Write-Verbose "Génération du rapport de conformité des permissions SQL Server pour l'instance: $ServerInstance"

        # Analyser les permissions SQL Server
        $analyzeParams = $sqlParams.Clone()
        $analyzeParams.IncludeObjectLevel = $IncludeObjectLevel
        $analyzeParams.ExcludeDatabases = $ExcludeDatabases
        $analyzeParams.OutputFormat = "JSON"
        $analyzeParams.Severity = $Severity

        $result = Analyze-SqlServerPermission @analyzeParams

        # Compter les anomalies par sévérité et par règle critique
        $criticalCount = 0
        $highCount = 0
        $mediumCount = 0
        $lowCount = 0
        $ruleStats = @{}

        # Compter les anomalies au niveau serveur
        foreach ($anomaly in $result.ServerAnomalies) {
            if ($criticalRules -contains $anomaly.RuleId) {
                $criticalCount++
            }
            elseif ($anomaly.Severity -eq "Élevée") {
                $highCount++
            }
            elseif ($anomaly.Severity -eq "Moyenne") {
                $mediumCount++
            }
            else {
                $lowCount++
            }

            if (-not $ruleStats.ContainsKey($anomaly.RuleId)) {
                $ruleStats[$anomaly.RuleId] = @{
                    Count = 0
                    Name = $anomaly.AnomalyType
                    Severity = $anomaly.Severity
                }
            }
            $ruleStats[$anomaly.RuleId].Count++
        }

        # Compter les anomalies au niveau base de données
        foreach ($anomaly in $result.DatabaseAnomalies) {
            if ($criticalRules -contains $anomaly.RuleId) {
                $criticalCount++
            }
            elseif ($anomaly.Severity -eq "Élevée") {
                $highCount++
            }
            elseif ($anomaly.Severity -eq "Moyenne") {
                $mediumCount++
            }
            else {
                $lowCount++
            }

            if (-not $ruleStats.ContainsKey($anomaly.RuleId)) {
                $ruleStats[$anomaly.RuleId] = @{
                    Count = 0
                    Name = $anomaly.AnomalyType
                    Severity = $anomaly.Severity
                }
            }
            $ruleStats[$anomaly.RuleId].Count++
        }

        # Compter les anomalies au niveau objet
        foreach ($anomaly in $result.ObjectAnomalies) {
            if ($criticalRules -contains $anomaly.RuleId) {
                $criticalCount++
            }
            elseif ($anomaly.Severity -eq "Élevée") {
                $highCount++
            }
            elseif ($anomaly.Severity -eq "Moyenne") {
                $mediumCount++
            }
            else {
                $lowCount++
            }

            if (-not $ruleStats.ContainsKey($anomaly.RuleId)) {
                $ruleStats[$anomaly.RuleId] = @{
                    Count = 0
                    Name = $anomaly.AnomalyType
                    Severity = $anomaly.Severity
                }
            }
            $ruleStats[$anomaly.RuleId].Count++
        }

        # Déterminer le statut global de conformité
        $status = Get-ComplianceStatus -CriticalCount $criticalCount -HighCount $highCount -MediumCount $mediumCount -LowCount $lowCount

        # Générer le rapport HTML
        $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $totalAnomalies = $result.TotalAnomalies
        $complianceChart = Get-ComplianceChart -CriticalCount $criticalCount -HighCount $highCount -MediumCount $mediumCount -LowCount $lowCount -Status $status

        $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de conformité des permissions SQL Server - $ServerInstance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .critical { background-color: #ffdddd; }
        .high { background-color: #ffe6cc; }
        .medium { background-color: #ffffcc; }
        .low { background-color: #e6ffe6; }
        .summary { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .chart-container { margin: 20px 0; }
    </style>
</head>
<body>
    <h1>Rapport de conformité des permissions SQL Server</h1>
    <p><strong>Instance:</strong> $ServerInstance</p>
    <p><strong>Date du rapport:</strong> $reportDate</p>

    <div class="summary">
        <h2>Résumé</h2>
        <p><strong>Nombre total d'anomalies:</strong> $totalAnomalies</p>
        <p><strong>Anomalies critiques:</strong> $criticalCount</p>
        <p><strong>Anomalies de sévérité élevée:</strong> $highCount</p>
        <p><strong>Anomalies de sévérité moyenne:</strong> $mediumCount</p>
        <p><strong>Anomalies de sévérité faible:</strong> $lowCount</p>
    </div>

    <div class="chart-container">
        $complianceChart
    </div>

    <h2>Statistiques par règle</h2>
    <table>
        <tr>
            <th>ID de règle</th>
            <th>Nom</th>
            <th>Sévérité</th>
            <th>Nombre d'anomalies</th>
        </tr>
"@

        # Ajouter les statistiques par règle
        foreach ($ruleId in $ruleStats.Keys | Sort-Object) {
            $ruleSeverityClass = switch ($ruleStats[$ruleId].Severity) {
                "Élevée" { "high" }
                "Moyenne" { "medium" }
                "Faible" { "low" }
                default { "" }
            }
            
            # Marquer les règles critiques
            if ($criticalRules -contains $ruleId) {
                $ruleSeverityClass = "critical"
            }

            $htmlReport += @"
        <tr class="$ruleSeverityClass">
            <td>$ruleId</td>
            <td>$($ruleStats[$ruleId].Name)</td>
            <td>$($ruleStats[$ruleId].Severity)</td>
            <td>$($ruleStats[$ruleId].Count)</td>
        </tr>
"@
        }

        $htmlReport += @"
    </table>

    <h2>Détails des anomalies</h2>
"@

        # Ajouter les détails des anomalies au niveau serveur
        if ($result.ServerAnomalies.Count -gt 0) {
            $htmlReport += @"
    <h3>Anomalies au niveau serveur</h3>
    <table>
        <tr>
            <th>ID de règle</th>
            <th>Type d'anomalie</th>
            <th>Login</th>
            <th>Description</th>
            <th>Sévérité</th>
            <th>Action recommandée</th>
        </tr>
"@

            foreach ($anomaly in $result.ServerAnomalies) {
                $anomalySeverityClass = switch ($anomaly.Severity) {
                    "Élevée" { "high" }
                    "Moyenne" { "medium" }
                    "Faible" { "low" }
                    default { "" }
                }
                
                # Marquer les règles critiques
                if ($criticalRules -contains $anomaly.RuleId) {
                    $anomalySeverityClass = "critical"
                }

                $htmlReport += @"
        <tr class="$anomalySeverityClass">
            <td>$($anomaly.RuleId)</td>
            <td>$($anomaly.AnomalyType)</td>
            <td>$($anomaly.LoginName)</td>
            <td>$($anomaly.Description)</td>
            <td>$($anomaly.Severity)</td>
            <td>$($anomaly.RecommendedAction)</td>
        </tr>
"@
            }

            $htmlReport += @"
    </table>
"@
        }

        # Ajouter les détails des anomalies au niveau base de données
        if ($result.DatabaseAnomalies.Count -gt 0) {
            $htmlReport += @"
    <h3>Anomalies au niveau base de données</h3>
    <table>
        <tr>
            <th>ID de règle</th>
            <th>Type d'anomalie</th>
            <th>Base de données</th>
            <th>Utilisateur</th>
            <th>Description</th>
            <th>Sévérité</th>
            <th>Action recommandée</th>
        </tr>
"@

            foreach ($anomaly in $result.DatabaseAnomalies) {
                $anomalySeverityClass = switch ($anomaly.Severity) {
                    "Élevée" { "high" }
                    "Moyenne" { "medium" }
                    "Faible" { "low" }
                    default { "" }
                }
                
                # Marquer les règles critiques
                if ($criticalRules -contains $anomaly.RuleId) {
                    $anomalySeverityClass = "critical"
                }

                $htmlReport += @"
        <tr class="$anomalySeverityClass">
            <td>$($anomaly.RuleId)</td>
            <td>$($anomaly.AnomalyType)</td>
            <td>$($anomaly.DatabaseName)</td>
            <td>$($anomaly.UserName)</td>
            <td>$($anomaly.Description)</td>
            <td>$($anomaly.Severity)</td>
            <td>$($anomaly.RecommendedAction)</td>
        </tr>
"@
            }

            $htmlReport += @"
    </table>
"@
        }

        # Ajouter les détails des anomalies au niveau objet
        if ($result.ObjectAnomalies.Count -gt 0) {
            $htmlReport += @"
    <h3>Anomalies au niveau objet</h3>
    <table>
        <tr>
            <th>ID de règle</th>
            <th>Type d'anomalie</th>
            <th>Base de données</th>
            <th>Utilisateur</th>
            <th>Description</th>
            <th>Sévérité</th>
            <th>Action recommandée</th>
            <th>Objets affectés</th>
        </tr>
"@

            foreach ($anomaly in $result.ObjectAnomalies) {
                $anomalySeverityClass = switch ($anomaly.Severity) {
                    "Élevée" { "high" }
                    "Moyenne" { "medium" }
                    "Faible" { "low" }
                    default { "" }
                }
                
                # Marquer les règles critiques
                if ($criticalRules -contains $anomaly.RuleId) {
                    $anomalySeverityClass = "critical"
                }

                $affectedObjects = if ($anomaly.AffectedObjects) {
                    $anomaly.AffectedObjects -join ", "
                } else {
                    "N/A"
                }

                $htmlReport += @"
        <tr class="$anomalySeverityClass">
            <td>$($anomaly.RuleId)</td>
            <td>$($anomaly.AnomalyType)</td>
            <td>$($anomaly.DatabaseName)</td>
            <td>$($anomaly.UserName)</td>
            <td>$($anomaly.Description)</td>
            <td>$($anomaly.Severity)</td>
            <td>$($anomaly.RecommendedAction)</td>
            <td>$affectedObjects</td>
        </tr>
"@
            }

            $htmlReport += @"
    </table>
"@
        }

        $htmlReport += @"
    <h2>Recommandations</h2>
    <ul>
"@

        # Ajouter des recommandations en fonction du statut
        switch ($status) {
            "Non conforme" {
                $htmlReport += @"
        <li><strong>Critique:</strong> Résoudre immédiatement les anomalies critiques.</li>
        <li>Mettre en place un plan d'action pour résoudre les anomalies de sévérité élevée.</li>
        <li>Planifier la résolution des anomalies de sévérité moyenne et faible.</li>
"@
            }
            "Partiellement conforme" {
                $htmlReport += @"
        <li><strong>Important:</strong> Résoudre les anomalies de sévérité élevée dans les plus brefs délais.</li>
        <li>Planifier la résolution des anomalies de sévérité moyenne.</li>
        <li>Évaluer l'impact des anomalies de sévérité faible.</li>
"@
            }
            "Majoritairement conforme" {
                $htmlReport += @"
        <li>Planifier la résolution des anomalies de sévérité moyenne.</li>
        <li>Évaluer l'impact des anomalies de sévérité faible.</li>
        <li>Mettre en place des contrôles pour éviter l'apparition de nouvelles anomalies.</li>
"@
            }
            "Presque conforme" {
                $htmlReport += @"
        <li>Résoudre les anomalies de sévérité faible lors des prochaines opérations de maintenance.</li>
        <li>Mettre en place des contrôles pour éviter l'apparition de nouvelles anomalies.</li>
        <li>Planifier des audits réguliers pour maintenir la conformité.</li>
"@
            }
            "Conforme" {
                $htmlReport += @"
        <li>Félicitations ! Votre instance SQL Server est conforme aux bonnes pratiques de sécurité.</li>
        <li>Continuer à effectuer des audits réguliers pour maintenir la conformité.</li>
        <li>Envisager d'ajouter des règles supplémentaires pour renforcer la sécurité.</li>
"@
            }
        }

        $htmlReport += @"
    </ul>

    <div style="margin-top: 30px; border-top: 1px solid #ddd; padding-top: 10px; font-size: 12px; color: #666;">
        <p>Rapport généré le $reportDate par le module RoadmapParser.</p>
    </div>
</body>
</html>
"@

        # Enregistrer le rapport HTML
        $htmlReport | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Verbose "Rapport de conformité enregistré: $OutputPath"

        # Envoyer le rapport par email si demandé
        if ($SendEmail) {
            if (-not $SmtpServer -or -not $FromAddress -or -not $ToAddress) {
                Write-Warning "Paramètres d'email manquants. Le rapport n'a pas été envoyé par email."
            }
            else {
                $emailParams = @{
                    SmtpServer = $SmtpServer
                    From = $FromAddress
                    To = $ToAddress
                    Subject = $Subject
                    Body = $htmlReport
                    BodyAsHtml = $true
                }

                Send-MailMessage @emailParams
                Write-Verbose "Rapport de conformité envoyé par email à: $($ToAddress -join ', ')"
            }
        }

        # Retourner un objet avec les informations de conformité
        return [PSCustomObject]@{
            ServerInstance = $ServerInstance
            ReportDate = $reportDate
            Status = $status
            TotalAnomalies = $totalAnomalies
            CriticalCount = $criticalCount
            HighCount = $highCount
            MediumCount = $mediumCount
            LowCount = $lowCount
            ReportPath = $OutputPath
        }
    }
    catch {
        Write-Error "Erreur lors de la génération du rapport de conformité: $_"
    }
}

# Run-AllSqlPermissionRules.ps1
# Script pour exécuter toutes les règles de détection d'anomalies SQL Server et générer un rapport complet

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "SqlPermissionAnomaliesReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').html",

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeDatabases = @("tempdb", "model"),

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
    [string]$Subject = "Rapport d'anomalies de permissions SQL Server - $ServerInstance"
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

    # Fonction pour générer un rapport HTML
    function Generate-HtmlReport {
        param (
            [Parameter(Mandatory = $true)]
            [PSCustomObject]$AnalysisResult,

            [Parameter(Mandatory = $true)]
            [string]$OutputPath
        )

        $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $totalAnomalies = $AnalysisResult.TotalAnomalies

        $htmlReport = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport d'anomalies de permissions SQL Server - $ServerInstance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .high { background-color: #ffe6cc; }
        .medium { background-color: #ffffcc; }
        .low { background-color: #e6ffe6; }
        .summary { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .rule-summary { margin: 20px 0; }
    </style>
</head>
<body>
    <h1>Rapport d'anomalies de permissions SQL Server</h1>
    <p><strong>Instance:</strong> $ServerInstance</p>
    <p><strong>Date du rapport:</strong> $reportDate</p>

    <div class="summary">
        <h2>Résumé</h2>
        <p><strong>Nombre total d'anomalies:</strong> $totalAnomalies</p>
"@

        # Compter les anomalies par sévérité
        $severityCounts = @{
            "Élevée" = 0
            "Moyenne" = 0
            "Faible" = 0
        }

        # Compter les anomalies par règle
        $ruleCounts = @{}

        # Compter les anomalies au niveau serveur
        foreach ($anomaly in $AnalysisResult.ServerAnomalies) {
            $severityCounts[$anomaly.Severity]++

            if (-not $ruleCounts.ContainsKey($anomaly.RuleId)) {
                $ruleCounts[$anomaly.RuleId] = @{
                    Count = 0
                    Name = $anomaly.AnomalyType
                    Severity = $anomaly.Severity
                }
            }
            $ruleCounts[$anomaly.RuleId].Count++
        }

        # Compter les anomalies au niveau base de données
        foreach ($anomaly in $AnalysisResult.DatabaseAnomalies) {
            $severityCounts[$anomaly.Severity]++

            if (-not $ruleCounts.ContainsKey($anomaly.RuleId)) {
                $ruleCounts[$anomaly.RuleId] = @{
                    Count = 0
                    Name = $anomaly.AnomalyType
                    Severity = $anomaly.Severity
                }
            }
            $ruleCounts[$anomaly.RuleId].Count++
        }

        # Compter les anomalies au niveau objet
        foreach ($anomaly in $AnalysisResult.ObjectAnomalies) {
            $severityCounts[$anomaly.Severity]++

            if (-not $ruleCounts.ContainsKey($anomaly.RuleId)) {
                $ruleCounts[$anomaly.RuleId] = @{
                    Count = 0
                    Name = $anomaly.AnomalyType
                    Severity = $anomaly.Severity
                }
            }
            $ruleCounts[$anomaly.RuleId].Count++
        }

        # Ajouter les compteurs par sévérité au rapport
        $htmlReport += @"
        <p><strong>Anomalies de sévérité élevée:</strong> $($severityCounts["Élevée"])</p>
        <p><strong>Anomalies de sévérité moyenne:</strong> $($severityCounts["Moyenne"])</p>
        <p><strong>Anomalies de sévérité faible:</strong> $($severityCounts["Faible"])</p>
    </div>

    <div class="rule-summary">
        <h2>Résumé par règle</h2>
        <table>
            <tr>
                <th>ID de règle</th>
                <th>Nom</th>
                <th>Sévérité</th>
                <th>Nombre d'anomalies</th>
            </tr>
"@

        # Ajouter les compteurs par règle au rapport
        foreach ($ruleId in $ruleCounts.Keys | Sort-Object) {
            $ruleSeverityClass = switch ($ruleCounts[$ruleId].Severity) {
                "Élevée" { "high" }
                "Moyenne" { "medium" }
                "Faible" { "low" }
                default { "" }
            }

            $htmlReport += @"
            <tr class="$ruleSeverityClass">
                <td>$ruleId</td>
                <td>$($ruleCounts[$ruleId].Name)</td>
                <td>$($ruleCounts[$ruleId].Severity)</td>
                <td>$($ruleCounts[$ruleId].Count)</td>
            </tr>
"@
        }

        $htmlReport += @"
        </table>
    </div>

    <h2>Détails des anomalies</h2>
"@

        # Ajouter les détails des anomalies au niveau serveur
        if ($AnalysisResult.ServerAnomalies.Count -gt 0) {
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

            foreach ($anomaly in $AnalysisResult.ServerAnomalies) {
                $anomalySeverityClass = switch ($anomaly.Severity) {
                    "Élevée" { "high" }
                    "Moyenne" { "medium" }
                    "Faible" { "low" }
                    default { "" }
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
        if ($AnalysisResult.DatabaseAnomalies.Count -gt 0) {
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

            foreach ($anomaly in $AnalysisResult.DatabaseAnomalies) {
                $anomalySeverityClass = switch ($anomaly.Severity) {
                    "Élevée" { "high" }
                    "Moyenne" { "medium" }
                    "Faible" { "low" }
                    default { "" }
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
        if ($AnalysisResult.ObjectAnomalies.Count -gt 0) {
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

            foreach ($anomaly in $AnalysisResult.ObjectAnomalies) {
                $anomalySeverityClass = switch ($anomaly.Severity) {
                    "Élevée" { "high" }
                    "Moyenne" { "medium" }
                    "Faible" { "low" }
                    default { "" }
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
    <div style="margin-top: 30px; border-top: 1px solid #ddd; padding-top: 10px; font-size: 12px; color: #666;">
        <p>Rapport généré le $reportDate par le module RoadmapParser.</p>
    </div>
</body>
</html>
"@

        # Enregistrer le rapport HTML
        $htmlReport | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Verbose "Rapport d'anomalies enregistré: $OutputPath"

        return $OutputPath
    }
}

process {
    try {
        Write-Verbose "Exécution de toutes les règles de détection d'anomalies SQL Server pour l'instance: $ServerInstance"

        # Obtenir toutes les règles disponibles
        $serverRules = Get-SqlPermissionRules -RuleType "Server"
        $databaseRules = Get-SqlPermissionRules -RuleType "Database"
        $objectRules = Get-SqlPermissionRules -RuleType "Object"

        Write-Verbose "Nombre de règles disponibles: $($serverRules.Count + $databaseRules.Count + $objectRules.Count)"
        Write-Verbose "  - Règles au niveau serveur: $($serverRules.Count)"
        Write-Verbose "  - Règles au niveau base de données: $($databaseRules.Count)"
        Write-Verbose "  - Règles au niveau objet: $($objectRules.Count)"

        # Extraire les IDs de règles
        $serverRuleIds = $serverRules | ForEach-Object { $_.RuleId }
        $databaseRuleIds = $databaseRules | ForEach-Object { $_.RuleId }
        $objectRuleIds = $objectRules | ForEach-Object { $_.RuleId }

        # Analyser les permissions SQL Server avec toutes les règles
        $analyzeParams = $sqlParams.Clone()
        $analyzeParams.IncludeObjectLevel = $IncludeObjectLevel
        $analyzeParams.ExcludeDatabases = $ExcludeDatabases
        $analyzeParams.OutputFormat = "JSON"
        $analyzeParams.RuleIds = $serverRuleIds + $databaseRuleIds + $objectRuleIds

        Write-Verbose "Exécution de l'analyse avec $($analyzeParams.RuleIds.Count) règles..."
        $result = Analyze-SqlServerPermission @analyzeParams

        Write-Verbose "Analyse terminée. Nombre total d'anomalies détectées: $($result.TotalAnomalies)"
        Write-Verbose "  - Anomalies au niveau serveur: $($result.ServerAnomalies.Count)"
        Write-Verbose "  - Anomalies au niveau base de données: $($result.DatabaseAnomalies.Count)"
        Write-Verbose "  - Anomalies au niveau objet: $($result.ObjectAnomalies.Count)"

        # Générer le rapport HTML
        $reportPath = Generate-HtmlReport -AnalysisResult $result -OutputPath $OutputPath
        Write-Verbose "Rapport HTML généré: $reportPath"

        # Envoyer le rapport par email si demandé
        if ($SendEmail) {
            if (-not $SmtpServer -or -not $FromAddress -or -not $ToAddress) {
                Write-Warning "Paramètres d'email manquants. Le rapport n'a pas été envoyé par email."
            }
            else {
                $htmlContent = Get-Content -Path $reportPath -Raw
                $emailParams = @{
                    SmtpServer = $SmtpServer
                    From = $FromAddress
                    To = $ToAddress
                    Subject = $Subject
                    Body = $htmlContent
                    BodyAsHtml = $true
                }

                Send-MailMessage @emailParams
                Write-Verbose "Rapport d'anomalies envoyé par email à: $($ToAddress -join ', ')"
            }
        }

        # Retourner un objet avec les informations d'analyse
        return [PSCustomObject]@{
            ServerInstance = $ServerInstance
            ReportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            TotalAnomalies = $result.TotalAnomalies
            ServerAnomalies = $result.ServerAnomalies.Count
            DatabaseAnomalies = $result.DatabaseAnomalies.Count
            ObjectAnomalies = $result.ObjectAnomalies.Count
            ReportPath = $reportPath
        }
    }
    catch {
        Write-Error "Erreur lors de l'exécution des règles de détection d'anomalies: $_"
    }
}

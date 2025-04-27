# Run-AllSqlPermissionRules.ps1
# Script pour exÃ©cuter toutes les rÃ¨gles de dÃ©tection d'anomalies SQL Server et gÃ©nÃ©rer un rapport complet

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

    # ParamÃ¨tres de connexion SQL Server
    $sqlParams = @{
        ServerInstance = $ServerInstance
        Database = "master"
    }

    if ($Credential) {
        $sqlParams.Credential = $Credential
    }

    # CrÃ©er le dossier de sortie si nÃ©cessaire
    $outputFolder = Split-Path -Path $OutputPath -Parent
    if ($outputFolder -and -not (Test-Path -Path $outputFolder)) {
        New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
    }

    # Fonction pour gÃ©nÃ©rer un rapport HTML
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
        <h2>RÃ©sumÃ©</h2>
        <p><strong>Nombre total d'anomalies:</strong> $totalAnomalies</p>
"@

        # Compter les anomalies par sÃ©vÃ©ritÃ©
        $severityCounts = @{
            "Ã‰levÃ©e" = 0
            "Moyenne" = 0
            "Faible" = 0
        }

        # Compter les anomalies par rÃ¨gle
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

        # Compter les anomalies au niveau base de donnÃ©es
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

        # Ajouter les compteurs par sÃ©vÃ©ritÃ© au rapport
        $htmlReport += @"
        <p><strong>Anomalies de sÃ©vÃ©ritÃ© Ã©levÃ©e:</strong> $($severityCounts["Ã‰levÃ©e"])</p>
        <p><strong>Anomalies de sÃ©vÃ©ritÃ© moyenne:</strong> $($severityCounts["Moyenne"])</p>
        <p><strong>Anomalies de sÃ©vÃ©ritÃ© faible:</strong> $($severityCounts["Faible"])</p>
    </div>

    <div class="rule-summary">
        <h2>RÃ©sumÃ© par rÃ¨gle</h2>
        <table>
            <tr>
                <th>ID de rÃ¨gle</th>
                <th>Nom</th>
                <th>SÃ©vÃ©ritÃ©</th>
                <th>Nombre d'anomalies</th>
            </tr>
"@

        # Ajouter les compteurs par rÃ¨gle au rapport
        foreach ($ruleId in $ruleCounts.Keys | Sort-Object) {
            $ruleSeverityClass = switch ($ruleCounts[$ruleId].Severity) {
                "Ã‰levÃ©e" { "high" }
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

    <h2>DÃ©tails des anomalies</h2>
"@

        # Ajouter les dÃ©tails des anomalies au niveau serveur
        if ($AnalysisResult.ServerAnomalies.Count -gt 0) {
            $htmlReport += @"
    <h3>Anomalies au niveau serveur</h3>
    <table>
        <tr>
            <th>ID de rÃ¨gle</th>
            <th>Type d'anomalie</th>
            <th>Login</th>
            <th>Description</th>
            <th>SÃ©vÃ©ritÃ©</th>
            <th>Action recommandÃ©e</th>
        </tr>
"@

            foreach ($anomaly in $AnalysisResult.ServerAnomalies) {
                $anomalySeverityClass = switch ($anomaly.Severity) {
                    "Ã‰levÃ©e" { "high" }
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

        # Ajouter les dÃ©tails des anomalies au niveau base de donnÃ©es
        if ($AnalysisResult.DatabaseAnomalies.Count -gt 0) {
            $htmlReport += @"
    <h3>Anomalies au niveau base de donnÃ©es</h3>
    <table>
        <tr>
            <th>ID de rÃ¨gle</th>
            <th>Type d'anomalie</th>
            <th>Base de donnÃ©es</th>
            <th>Utilisateur</th>
            <th>Description</th>
            <th>SÃ©vÃ©ritÃ©</th>
            <th>Action recommandÃ©e</th>
        </tr>
"@

            foreach ($anomaly in $AnalysisResult.DatabaseAnomalies) {
                $anomalySeverityClass = switch ($anomaly.Severity) {
                    "Ã‰levÃ©e" { "high" }
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

        # Ajouter les dÃ©tails des anomalies au niveau objet
        if ($AnalysisResult.ObjectAnomalies.Count -gt 0) {
            $htmlReport += @"
    <h3>Anomalies au niveau objet</h3>
    <table>
        <tr>
            <th>ID de rÃ¨gle</th>
            <th>Type d'anomalie</th>
            <th>Base de donnÃ©es</th>
            <th>Utilisateur</th>
            <th>Description</th>
            <th>SÃ©vÃ©ritÃ©</th>
            <th>Action recommandÃ©e</th>
            <th>Objets affectÃ©s</th>
        </tr>
"@

            foreach ($anomaly in $AnalysisResult.ObjectAnomalies) {
                $anomalySeverityClass = switch ($anomaly.Severity) {
                    "Ã‰levÃ©e" { "high" }
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
        <p>Rapport gÃ©nÃ©rÃ© le $reportDate par le module RoadmapParser.</p>
    </div>
</body>
</html>
"@

        # Enregistrer le rapport HTML
        $htmlReport | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Verbose "Rapport d'anomalies enregistrÃ©: $OutputPath"

        return $OutputPath
    }
}

process {
    try {
        Write-Verbose "ExÃ©cution de toutes les rÃ¨gles de dÃ©tection d'anomalies SQL Server pour l'instance: $ServerInstance"

        # Obtenir toutes les rÃ¨gles disponibles
        $serverRules = Get-SqlPermissionRules -RuleType "Server"
        $databaseRules = Get-SqlPermissionRules -RuleType "Database"
        $objectRules = Get-SqlPermissionRules -RuleType "Object"

        Write-Verbose "Nombre de rÃ¨gles disponibles: $($serverRules.Count + $databaseRules.Count + $objectRules.Count)"
        Write-Verbose "  - RÃ¨gles au niveau serveur: $($serverRules.Count)"
        Write-Verbose "  - RÃ¨gles au niveau base de donnÃ©es: $($databaseRules.Count)"
        Write-Verbose "  - RÃ¨gles au niveau objet: $($objectRules.Count)"

        # Extraire les IDs de rÃ¨gles
        $serverRuleIds = $serverRules | ForEach-Object { $_.RuleId }
        $databaseRuleIds = $databaseRules | ForEach-Object { $_.RuleId }
        $objectRuleIds = $objectRules | ForEach-Object { $_.RuleId }

        # Analyser les permissions SQL Server avec toutes les rÃ¨gles
        $analyzeParams = $sqlParams.Clone()
        $analyzeParams.IncludeObjectLevel = $IncludeObjectLevel
        $analyzeParams.ExcludeDatabases = $ExcludeDatabases
        $analyzeParams.OutputFormat = "JSON"
        $analyzeParams.RuleIds = $serverRuleIds + $databaseRuleIds + $objectRuleIds

        Write-Verbose "ExÃ©cution de l'analyse avec $($analyzeParams.RuleIds.Count) rÃ¨gles..."
        $result = Analyze-SqlServerPermission @analyzeParams

        Write-Verbose "Analyse terminÃ©e. Nombre total d'anomalies dÃ©tectÃ©es: $($result.TotalAnomalies)"
        Write-Verbose "  - Anomalies au niveau serveur: $($result.ServerAnomalies.Count)"
        Write-Verbose "  - Anomalies au niveau base de donnÃ©es: $($result.DatabaseAnomalies.Count)"
        Write-Verbose "  - Anomalies au niveau objet: $($result.ObjectAnomalies.Count)"

        # GÃ©nÃ©rer le rapport HTML
        $reportPath = Generate-HtmlReport -AnalysisResult $result -OutputPath $OutputPath
        Write-Verbose "Rapport HTML gÃ©nÃ©rÃ©: $reportPath"

        # Envoyer le rapport par email si demandÃ©
        if ($SendEmail) {
            if (-not $SmtpServer -or -not $FromAddress -or -not $ToAddress) {
                Write-Warning "ParamÃ¨tres d'email manquants. Le rapport n'a pas Ã©tÃ© envoyÃ© par email."
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
                Write-Verbose "Rapport d'anomalies envoyÃ© par email Ã : $($ToAddress -join ', ')"
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
        Write-Error "Erreur lors de l'exÃ©cution des rÃ¨gles de dÃ©tection d'anomalies: $_"
    }
}

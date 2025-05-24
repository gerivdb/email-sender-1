# Export-SqlPermissionsToPowerBI.ps1
# Script pour exporter les donnÃ©es d'anomalies de permissions SQL Server vers Power BI

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $false)]
    [System.Management.Automation.PSCredential]$Credential,

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "C:\Reports\SqlPermissionAnomalies\PowerBI",

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeDatabases = @("tempdb", "model"),

    [Parameter(Mandatory = $false)]
    [switch]$IncludeObjectLevel,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateTemplate
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
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
        Write-Verbose "Dossier de sortie crÃ©Ã©: $OutputFolder"
    }

    # Fonction pour gÃ©nÃ©rer un modÃ¨le Power BI
    function New-PowerBITemplate {
        param (
            [Parameter(Mandatory = $true)]
            [string]$OutputPath
        )

        $templateJson = @"
{
    "version": "1.0",
    "datasetReference": {
        "byPath": null,
        "byConnection": {
            "connectionString": "Data Source=.\\Data\\SqlPermissionAnomalies.json;JsonFormat=List",
            "pbiServiceModelId": null,
            "pbiModelVirtualServerName": null,
            "pbiModelDatabaseName": null,
            "connectionType": "JSON",
            "connectionName": "SqlPermissionAnomalies",
            "sourceConnectionType": null,
            "sourceConnectionName": null
        }
    },
    "objects": {
        "pages": [
            {
                "name": "ReportSection",
                "displayName": "Anomalies de permissions SQL Server",
                "filters": [],
                "height": 720,
                "width": 1280,
                "config": "{\"version\":\"5.35\",\"themeCollection\":{\"baseTheme\":{\"name\":\"CY23SU04\",\"version\":\"5.35\",\"type\":2}}}",
                "objects": {
                    "visualContainers": [
                        {
                            "x": 0,
                            "y": 0,
                            "z": 0,
                            "width": 640,
                            "height": 360,
                            "config": "{\"name\":\"a731e50c9ddf7c5c2905\",\"layouts\":[{\"id\":0,\"position\":{\"x\":0,\"y\":0,\"width\":640,\"height\":360,\"z\":0}}],\"singleVisual\":{\"visualType\":\"lineChart\",\"projections\":{\"Y\":[{\"queryRef\":\"Sum(TotalAnomalies)\"}],\"Series\":[{\"queryRef\":\"Severity\"}],\"XAxis\":[{\"queryRef\":\"ReportDate\"}]},\"prototypeQuery\":{\"Version\":2,\"From\":[{\"Name\":\"a\",\"Entity\":\"Anomalies\"}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"a\"}},\"Property\":\"ReportDate\"},\"Name\":\"ReportDate\"},{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"a\"}},\"Property\":\"Severity\"},\"Name\":\"Severity\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"a\"}},\"Property\":\"TotalAnomalies\"}},\"Function\":0},\"Name\":\"Sum(TotalAnomalies)\"}]},\"vcObjects\":{\"title\":[{\"properties\":{\"text\":{\"expr\":{\"Literal\":{\"Value\":\"'Ã‰volution des anomalies par sÃ©vÃ©ritÃ©'\"}}}}}]}}}",
                            "filters": []
                        },
                        {
                            "x": 640,
                            "y": 0,
                            "z": 1,
                            "width": 640,
                            "height": 360,
                            "config": "{\"name\":\"b731e50c9ddf7c5c2905\",\"layouts\":[{\"id\":0,\"position\":{\"x\":640,\"y\":0,\"width\":640,\"height\":360,\"z\":1}}],\"singleVisual\":{\"visualType\":\"pieChart\",\"projections\":{\"Values\":[{\"queryRef\":\"Sum(TotalAnomalies)\"}],\"Legend\":[{\"queryRef\":\"Severity\"}]},\"prototypeQuery\":{\"Version\":2,\"From\":[{\"Name\":\"a\",\"Entity\":\"Anomalies\"}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"a\"}},\"Property\":\"Severity\"},\"Name\":\"Severity\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"a\"}},\"Property\":\"TotalAnomalies\"}},\"Function\":0},\"Name\":\"Sum(TotalAnomalies)\"}]},\"vcObjects\":{\"title\":[{\"properties\":{\"text\":{\"expr\":{\"Literal\":{\"Value\":\"'RÃ©partition des anomalies par sÃ©vÃ©ritÃ©'\"}}}}}]}}}",
                            "filters": []
                        },
                        {
                            "x": 0,
                            "y": 360,
                            "z": 2,
                            "width": 640,
                            "height": 360,
                            "config": "{\"name\":\"c731e50c9ddf7c5c2905\",\"layouts\":[{\"id\":0,\"position\":{\"x\":0,\"y\":360,\"width\":640,\"height\":360,\"z\":2}}],\"singleVisual\":{\"visualType\":\"barChart\",\"projections\":{\"Y\":[{\"queryRef\":\"Sum(Count)\"}],\"Category\":[{\"queryRef\":\"RuleId\"}]},\"prototypeQuery\":{\"Version\":2,\"From\":[{\"Name\":\"r\",\"Entity\":\"Rules\"}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"RuleId\"},\"Name\":\"RuleId\"},{\"Aggregation\":{\"Expression\":{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"Count\"}},\"Function\":0},\"Name\":\"Sum(Count)\"}]},\"vcObjects\":{\"title\":[{\"properties\":{\"text\":{\"expr\":{\"Literal\":{\"Value\":\"'Nombre d\\'anomalies par rÃ¨gle'\"}}}}}]}}}",
                            "filters": []
                        },
                        {
                            "x": 640,
                            "y": 360,
                            "z": 3,
                            "width": 640,
                            "height": 360,
                            "config": "{\"name\":\"d731e50c9ddf7c5c2905\",\"layouts\":[{\"id\":0,\"position\":{\"x\":640,\"y\":360,\"width\":640,\"height\":360,\"z\":3}}],\"singleVisual\":{\"visualType\":\"tableEx\",\"projections\":{\"Values\":[{\"queryRef\":\"RuleId\"},{\"queryRef\":\"Name\"},{\"queryRef\":\"Severity\"},{\"queryRef\":\"Count\"}]},\"prototypeQuery\":{\"Version\":2,\"From\":[{\"Name\":\"r\",\"Entity\":\"Rules\"}],\"Select\":[{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"RuleId\"},\"Name\":\"RuleId\"},{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"Name\"},\"Name\":\"Name\"},{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"Severity\"},\"Name\":\"Severity\"},{\"Column\":{\"Expression\":{\"SourceRef\":{\"Source\":\"r\"}},\"Property\":\"Count\"},\"Name\":\"Count\"}]},\"vcObjects\":{\"title\":[{\"properties\":{\"text\":{\"expr\":{\"Literal\":{\"Value\":\"'DÃ©tails des rÃ¨gles'\"}}}}}]}}}",
                            "filters": []
                        }
                    ]
                }
            }
        ]
    }
}
"@

        $templateJson | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Verbose "ModÃ¨le Power BI gÃ©nÃ©rÃ©: $OutputPath"
    }
}

process {
    try {
        Write-Verbose "Exportation des donnÃ©es d'anomalies SQL Server pour l'instance: $ServerInstance"

        # Analyser les permissions SQL Server avec toutes les rÃ¨gles
        $analyzeParams = $sqlParams.Clone()
        $analyzeParams.IncludeObjectLevel = $IncludeObjectLevel
        $analyzeParams.ExcludeDatabases = $ExcludeDatabases
        $analyzeParams.OutputFormat = "JSON"

        Write-Verbose "ExÃ©cution de l'analyse des permissions..."
        $result = Analyze-SqlServerPermission @analyzeParams

        Write-Verbose "Analyse terminÃ©e. Nombre total d'anomalies dÃ©tectÃ©es: $($result.TotalAnomalies)"

        # PrÃ©parer les donnÃ©es pour l'exportation
        $reportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # DonnÃ©es des anomalies par sÃ©vÃ©ritÃ©
        $anomaliesBySeverity = @(
            [PSCustomObject]@{
                ReportDate = $reportDate
                Severity = "Ã‰levÃ©e"
                TotalAnomalies = ($result.ServerAnomalies + $result.DatabaseAnomalies + $result.ObjectAnomalies | 
                                 Where-Object { $_.Severity -eq "Ã‰levÃ©e" }).Count
            },
            [PSCustomObject]@{
                ReportDate = $reportDate
                Severity = "Moyenne"
                TotalAnomalies = ($result.ServerAnomalies + $result.DatabaseAnomalies + $result.ObjectAnomalies | 
                                 Where-Object { $_.Severity -eq "Moyenne" }).Count
            },
            [PSCustomObject]@{
                ReportDate = $reportDate
                Severity = "Faible"
                TotalAnomalies = ($result.ServerAnomalies + $result.DatabaseAnomalies + $result.ObjectAnomalies | 
                                 Where-Object { $_.Severity -eq "Faible" }).Count
            }
        )

        # DonnÃ©es des anomalies par rÃ¨gle
        $ruleStats = @{}
        
        # Compter les anomalies au niveau serveur
        foreach ($anomaly in $result.ServerAnomalies) {
            if (-not $ruleStats.ContainsKey($anomaly.RuleId)) {
                $ruleStats[$anomaly.RuleId] = @{
                    RuleId = $anomaly.RuleId
                    Name = $anomaly.AnomalyType
                    Severity = $anomaly.Severity
                    Count = 0
                }
            }
            $ruleStats[$anomaly.RuleId].Count++
        }

        # Compter les anomalies au niveau base de donnÃ©es
        foreach ($anomaly in $result.DatabaseAnomalies) {
            if (-not $ruleStats.ContainsKey($anomaly.RuleId)) {
                $ruleStats[$anomaly.RuleId] = @{
                    RuleId = $anomaly.RuleId
                    Name = $anomaly.AnomalyType
                    Severity = $anomaly.Severity
                    Count = 0
                }
            }
            $ruleStats[$anomaly.RuleId].Count++
        }

        # Compter les anomalies au niveau objet
        foreach ($anomaly in $result.ObjectAnomalies) {
            if (-not $ruleStats.ContainsKey($anomaly.RuleId)) {
                $ruleStats[$anomaly.RuleId] = @{
                    RuleId = $anomaly.RuleId
                    Name = $anomaly.AnomalyType
                    Severity = $anomaly.Severity
                    Count = 0
                }
            }
            $ruleStats[$anomaly.RuleId].Count++
        }

        $ruleData = $ruleStats.Values | Sort-Object -Property Count -Descending

        # DÃ©tails des anomalies
        $anomalyDetails = @()
        
        foreach ($anomaly in $result.ServerAnomalies) {
            $anomalyDetails += [PSCustomObject]@{
                ReportDate = $reportDate
                RuleId = $anomaly.RuleId
                AnomalyType = $anomaly.AnomalyType
                Severity = $anomaly.Severity
                Level = "Server"
                LoginName = $anomaly.LoginName
                DatabaseName = $null
                UserName = $null
                Description = $anomaly.Description
                RecommendedAction = $anomaly.RecommendedAction
            }
        }
        
        foreach ($anomaly in $result.DatabaseAnomalies) {
            $anomalyDetails += [PSCustomObject]@{
                ReportDate = $reportDate
                RuleId = $anomaly.RuleId
                AnomalyType = $anomaly.AnomalyType
                Severity = $anomaly.Severity
                Level = "Database"
                LoginName = $null
                DatabaseName = $anomaly.DatabaseName
                UserName = $anomaly.UserName
                Description = $anomaly.Description
                RecommendedAction = $anomaly.RecommendedAction
            }
        }
        
        foreach ($anomaly in $result.ObjectAnomalies) {
            $anomalyDetails += [PSCustomObject]@{
                ReportDate = $reportDate
                RuleId = $anomaly.RuleId
                AnomalyType = $anomaly.AnomalyType
                Severity = $anomaly.Severity
                Level = "Object"
                LoginName = $null
                DatabaseName = $anomaly.DatabaseName
                UserName = $anomaly.UserName
                Description = $anomaly.Description
                RecommendedAction = $anomaly.RecommendedAction
                AffectedObjects = $anomaly.AffectedObjects -join ", "
            }
        }

        # CrÃ©er le dossier de donnÃ©es si nÃ©cessaire
        $dataFolder = Join-Path -Path $OutputFolder -ChildPath "Data"
        if (-not (Test-Path -Path $dataFolder)) {
            New-Item -Path $dataFolder -ItemType Directory -Force | Out-Null
            Write-Verbose "Dossier de donnÃ©es crÃ©Ã©: $dataFolder"
        }

        # Exporter les donnÃ©es au format JSON
        $anomaliesBySeverity | ConvertTo-Json -Depth 3 | 
            Out-File -FilePath (Join-Path -Path $dataFolder -ChildPath "Anomalies.json") -Encoding UTF8
        
        $ruleData | ConvertTo-Json -Depth 3 | 
            Out-File -FilePath (Join-Path -Path $dataFolder -ChildPath "Rules.json") -Encoding UTF8
        
        $anomalyDetails | ConvertTo-Json -Depth 3 | 
            Out-File -FilePath (Join-Path -Path $dataFolder -ChildPath "AnomalyDetails.json") -Encoding UTF8

        # GÃ©nÃ©rer un fichier de donnÃ©es combinÃ© pour Power BI
        $combinedData = [PSCustomObject]@{
            ServerInstance = $ServerInstance
            ReportDate = $reportDate
            TotalAnomalies = $result.TotalAnomalies
            Anomalies = $anomaliesBySeverity
            Rules = $ruleData
            Details = $anomalyDetails
        }

        $combinedData | ConvertTo-Json -Depth 5 | 
            Out-File -FilePath (Join-Path -Path $dataFolder -ChildPath "SqlPermissionAnomalies.json") -Encoding UTF8

        # GÃ©nÃ©rer un modÃ¨le Power BI si demandÃ©
        if ($GenerateTemplate) {
            $templatePath = Join-Path -Path $OutputFolder -ChildPath "SqlPermissionAnomalies.pbit"
            New-PowerBITemplate -OutputPath $templatePath
        }

        # Retourner un objet avec les informations d'exportation
        return [PSCustomObject]@{
            ServerInstance = $ServerInstance
            ExportDate = $reportDate
            OutputFolder = $OutputFolder
            TotalAnomalies = $result.TotalAnomalies
            RuleCount = $ruleData.Count
            DetailsCount = $anomalyDetails.Count
        }
    }
    catch {
        Write-Error "Erreur lors de l'exportation des donnÃ©es d'anomalies: $_"
    }
}


# Generate-SqlPermissionDashboard.ps1
# Script pour gÃ©nÃ©rer un tableau de bord HTML interactif pour suivre l'Ã©volution des anomalies SQL Server

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ServerInstance,

    [Parameter(Mandatory = $false)]
    [string]$ReportsFolder = "C:\Reports\SqlPermissionAnomalies",

    [Parameter(Mandatory = $false)]
    [string]$DashboardPath = "C:\Reports\SqlPermissionDashboard.html",

    [Parameter(Mandatory = $false)]
    [int]$HistoryDays = 30
)

begin {
    # VÃ©rifier que le dossier de rapports existe
    if (-not (Test-Path -Path $ReportsFolder)) {
        throw "Le dossier de rapports n'existe pas: $ReportsFolder"
    }

    # CrÃ©er le dossier parent du tableau de bord si nÃ©cessaire
    $dashboardFolder = Split-Path -Path $DashboardPath -Parent
    if ($dashboardFolder -and -not (Test-Path -Path $dashboardFolder)) {
        New-Item -Path $dashboardFolder -ItemType Directory -Force | Out-Null
    }

    # Fonction pour extraire les donnÃ©es d'anomalies d'un rapport HTML
    function Export-AnomalyData {
        param (
            [Parameter(Mandatory = $true)]
            [string]$ReportPath
        )

        try {
            # Lire le contenu du rapport
            $content = Get-Content -Path $ReportPath -Raw -ErrorAction Stop

            # Extraire la date du rapport
            $dateMatch = [regex]::Match($content, '<p><strong>Date du rapport:</strong>\s*(.*?)</p>')
            $reportDate = if ($dateMatch.Success) {
                try {
                    [datetime]::ParseExact($dateMatch.Groups[1].Value, "yyyy-MM-dd HH:mm:ss", $null)
                } catch {
                    (Get-Item -Path $ReportPath).CreationTime
                }
            } else {
                (Get-Item -Path $ReportPath).CreationTime
            }

            # Extraire le nombre total d'anomalies
            $totalMatch = [regex]::Match($content, '<p><strong>Nombre total d''anomalies:</strong>\s*(\d+)</p>')
            $totalAnomalies = if ($totalMatch.Success) {
                [int]::Parse($totalMatch.Groups[1].Value)
            } else {
                0
            }

            # Extraire les compteurs par sÃ©vÃ©ritÃ©
            $highMatch = [regex]::Match($content, '<p><strong>Anomalies de sÃ©vÃ©ritÃ© Ã©levÃ©e:</strong>\s*(\d+)</p>')
            $mediumMatch = [regex]::Match($content, '<p><strong>Anomalies de sÃ©vÃ©ritÃ© moyenne:</strong>\s*(\d+)</p>')
            $lowMatch = [regex]::Match($content, '<p><strong>Anomalies de sÃ©vÃ©ritÃ© faible:</strong>\s*(\d+)</p>')

            $highCount = if ($highMatch.Success) { [int]::Parse($highMatch.Groups[1].Value) } else { 0 }
            $mediumCount = if ($mediumMatch.Success) { [int]::Parse($mediumMatch.Groups[1].Value) } else { 0 }
            $lowCount = if ($lowMatch.Success) { [int]::Parse($lowMatch.Groups[1].Value) } else { 0 }

            # Extraire les compteurs par rÃ¨gle
            $ruleCounts = @{}
            $ruleTableMatch = [regex]::Match($content, '<h2>RÃ©sumÃ© par rÃ¨gle</h2>.*?<table>(.*?)</table>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
            
            if ($ruleTableMatch.Success) {
                $ruleTableContent = $ruleTableMatch.Groups[1].Value
                $ruleRowMatches = [regex]::Matches($ruleTableContent, '<tr.*?>(.*?)</tr>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
                
                # Ignorer la premiÃ¨re ligne (en-tÃªtes)
                for ($i = 1; $i -lt $ruleRowMatches.Count; $i++) {
                    $rowContent = $ruleRowMatches[$i].Groups[1].Value
                    $cellMatches = [regex]::Matches($rowContent, '<td.*?>(.*?)</td>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
                    
                    if ($cellMatches.Count -ge 4) {
                        $ruleId = $cellMatches[0].Groups[1].Value.Trim()
                        $ruleName = $cellMatches[1].Groups[1].Value.Trim()
                        $ruleSeverity = $cellMatches[2].Groups[1].Value.Trim()
                        $ruleCount = [int]::Parse($cellMatches[3].Groups[1].Value.Trim())
                        
                        $ruleCounts[$ruleId] = @{
                            Name = $ruleName
                            Severity = $ruleSeverity
                            Count = $ruleCount
                        }
                    }
                }
            }

            # Retourner les donnÃ©es extraites
            return [PSCustomObject]@{
                ReportDate = $reportDate
                TotalAnomalies = $totalAnomalies
                HighCount = $highCount
                MediumCount = $mediumCount
                LowCount = $lowCount
                RuleCounts = $ruleCounts
            }
        }
        catch {
            Write-Warning "Erreur lors de l'extraction des donnÃ©es du rapport $ReportPath : $_"
            return $null
        }
    }
}

process {
    try {
        Write-Verbose "GÃ©nÃ©ration du tableau de bord pour l'instance SQL Server: $ServerInstance"

        # Obtenir la date limite pour l'historique
        $cutoffDate = (Get-Date).AddDays(-$HistoryDays)

        # Obtenir tous les rapports HTML dans le dossier
        $reportFiles = Get-ChildItem -Path $ReportsFolder -Filter "*.html" | 
                       Where-Object { $_.CreationTime -ge $cutoffDate } |
                       Sort-Object -Property CreationTime

        if ($reportFiles.Count -eq 0) {
            Write-Warning "Aucun rapport trouvÃ© dans le dossier $ReportsFolder pour les $HistoryDays derniers jours."
            return
        }

        Write-Verbose "Nombre de rapports trouvÃ©s: $($reportFiles.Count)"

        # Extraire les donnÃ©es de chaque rapport
        $reportData = @()
        foreach ($file in $reportFiles) {
            $data = Export-AnomalyData -ReportPath $file.FullName
            if ($data) {
                $reportData += $data
            }
        }

        Write-Verbose "Nombre de rapports analysÃ©s avec succÃ¨s: $($reportData.Count)"

        # PrÃ©parer les donnÃ©es pour les graphiques
        $dates = $reportData | ForEach-Object { $_.ReportDate.ToString("yyyy-MM-dd") } | ConvertTo-Json
        $totalAnomalies = $reportData | ForEach-Object { $_.TotalAnomalies } | ConvertTo-Json
        $highCounts = $reportData | ForEach-Object { $_.HighCount } | ConvertTo-Json
        $mediumCounts = $reportData | ForEach-Object { $_.MediumCount } | ConvertTo-Json
        $lowCounts = $reportData | ForEach-Object { $_.LowCount } | ConvertTo-Json

        # PrÃ©parer les donnÃ©es pour le graphique par rÃ¨gle
        $allRuleIds = $reportData | ForEach-Object { $_.RuleCounts.Keys } | Select-Object -Unique
        $ruleData = @{}

        foreach ($ruleId in $allRuleIds) {
            $ruleData[$ruleId] = @{
                Name = ""
                Severity = ""
                Counts = @()
            }

            foreach ($report in $reportData) {
                if ($report.RuleCounts.ContainsKey($ruleId)) {
                    $ruleData[$ruleId].Name = $report.RuleCounts[$ruleId].Name
                    $ruleData[$ruleId].Severity = $report.RuleCounts[$ruleId].Severity
                    $ruleData[$ruleId].Counts += $report.RuleCounts[$ruleId].Count
                } else {
                    $ruleData[$ruleId].Counts += 0
                }
            }
        }

        $ruleDataJson = $ruleData | ConvertTo-Json -Depth 3

        # GÃ©nÃ©rer le tableau de bord HTML
        $dashboardHtml = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Tableau de bord des anomalies de permissions SQL Server - $ServerInstance</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2, h3 { color: #333; }
        .dashboard-container { display: flex; flex-wrap: wrap; }
        .chart-container { width: 100%; margin-bottom: 30px; }
        .chart-container.half { width: 48%; margin-right: 2%; }
        .summary { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .rule-selector { margin: 20px 0; }
        .severity-high { color: #ff6384; }
        .severity-medium { color: #ffcd56; }
        .severity-low { color: #4bc0c0; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
    </style>
</head>
<body>
    <h1>Tableau de bord des anomalies de permissions SQL Server</h1>
    <p><strong>Instance:</strong> $ServerInstance</p>
    <p><strong>PÃ©riode:</strong> Derniers $HistoryDays jours</p>
    <p><strong>Nombre de rapports analysÃ©s:</strong> $($reportData.Count)</p>

    <div class="summary">
        <h2>RÃ©sumÃ©</h2>
        <p><strong>DerniÃ¨re analyse:</strong> $($reportData[-1].ReportDate.ToString("yyyy-MM-dd HH:mm:ss"))</p>
        <p><strong>Nombre total d'anomalies:</strong> $($reportData[-1].TotalAnomalies)</p>
        <p><strong>Anomalies de sÃ©vÃ©ritÃ© Ã©levÃ©e:</strong> <span class="severity-high">$($reportData[-1].HighCount)</span></p>
        <p><strong>Anomalies de sÃ©vÃ©ritÃ© moyenne:</strong> <span class="severity-medium">$($reportData[-1].MediumCount)</span></p>
        <p><strong>Anomalies de sÃ©vÃ©ritÃ© faible:</strong> <span class="severity-low">$($reportData[-1].LowCount)</span></p>
    </div>

    <div class="dashboard-container">
        <div class="chart-container">
            <h2>Ã‰volution du nombre total d'anomalies</h2>
            <canvas id="totalAnomaliesChart"></canvas>
        </div>

        <div class="chart-container">
            <h2>Ã‰volution des anomalies par sÃ©vÃ©ritÃ©</h2>
            <canvas id="severityChart"></canvas>
        </div>

        <div class="chart-container">
            <h2>Ã‰volution des anomalies par rÃ¨gle</h2>
            <div class="rule-selector">
                <label for="ruleSelect">SÃ©lectionner une rÃ¨gle:</label>
                <select id="ruleSelect" onchange="updateRuleChart()"></select>
            </div>
            <canvas id="ruleChart"></canvas>
        </div>

        <div class="chart-container half">
            <h2>RÃ©partition des anomalies par sÃ©vÃ©ritÃ©</h2>
            <canvas id="severityPieChart"></canvas>
        </div>

        <div class="chart-container half">
            <h2>Top 5 des rÃ¨gles avec le plus d'anomalies</h2>
            <canvas id="topRulesChart"></canvas>
        </div>
    </div>

    <div>
        <h2>DerniÃ¨res anomalies par rÃ¨gle</h2>
        <table id="ruleTable">
            <tr>
                <th>ID de rÃ¨gle</th>
                <th>Nom</th>
                <th>SÃ©vÃ©ritÃ©</th>
                <th>Nombre d'anomalies</th>
                <th>Tendance</th>
            </tr>
        </table>
    </div>

    <script>
        // DonnÃ©es des rapports
        const dates = $dates;
        const totalAnomalies = $totalAnomalies;
        const highCounts = $highCounts;
        const mediumCounts = $mediumCounts;
        const lowCounts = $lowCounts;
        const ruleData = $ruleDataJson;

        // Graphique d'Ã©volution du nombre total d'anomalies
        const totalCtx = document.getElementById('totalAnomaliesChart').getContext('2d');
        const totalChart = new Chart(totalCtx, {
            type: 'line',
            data: {
                labels: dates,
                datasets: [{
                    label: 'Nombre total d\'anomalies',
                    data: totalAnomalies,
                    borderColor: '#36a2eb',
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    tension: 0.1,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'Ã‰volution du nombre total d\'anomalies'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });

        // Graphique d'Ã©volution des anomalies par sÃ©vÃ©ritÃ©
        const severityCtx = document.getElementById('severityChart').getContext('2d');
        const severityChart = new Chart(severityCtx, {
            type: 'line',
            data: {
                labels: dates,
                datasets: [
                    {
                        label: 'Ã‰levÃ©e',
                        data: highCounts,
                        borderColor: '#ff6384',
                        backgroundColor: 'rgba(255, 99, 132, 0.2)',
                        tension: 0.1,
                        fill: true
                    },
                    {
                        label: 'Moyenne',
                        data: mediumCounts,
                        borderColor: '#ffcd56',
                        backgroundColor: 'rgba(255, 205, 86, 0.2)',
                        tension: 0.1,
                        fill: true
                    },
                    {
                        label: 'Faible',
                        data: lowCounts,
                        borderColor: '#4bc0c0',
                        backgroundColor: 'rgba(75, 192, 192, 0.2)',
                        tension: 0.1,
                        fill: true
                    }
                ]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'Ã‰volution des anomalies par sÃ©vÃ©ritÃ©'
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });

        // Graphique de rÃ©partition des anomalies par sÃ©vÃ©ritÃ©
        const pieSeverityCtx = document.getElementById('severityPieChart').getContext('2d');
        const pieSeverityChart = new Chart(pieSeverityCtx, {
            type: 'pie',
            data: {
                labels: ['Ã‰levÃ©e', 'Moyenne', 'Faible'],
                datasets: [{
                    data: [
                        highCounts[highCounts.length - 1],
                        mediumCounts[mediumCounts.length - 1],
                        lowCounts[lowCounts.length - 1]
                    ],
                    backgroundColor: [
                        'rgba(255, 99, 132, 0.7)',
                        'rgba(255, 205, 86, 0.7)',
                        'rgba(75, 192, 192, 0.7)'
                    ],
                    borderColor: [
                        'rgb(255, 99, 132)',
                        'rgb(255, 205, 86)',
                        'rgb(75, 192, 192)'
                    ],
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'RÃ©partition des anomalies par sÃ©vÃ©ritÃ©'
                    }
                }
            }
        });

        // Remplir le sÃ©lecteur de rÃ¨gles
        const ruleSelect = document.getElementById('ruleSelect');
        for (const ruleId in ruleData) {
            const option = document.createElement('option');
            option.value = ruleId;
            option.textContent = `${ruleId} - ${ruleData[ruleId].Name}`;
            ruleSelect.appendChild(option);
        }

        // Graphique d'Ã©volution des anomalies par rÃ¨gle
        const ruleCtx = document.getElementById('ruleChart').getContext('2d');
        let ruleChart = null;

        function updateRuleChart() {
            const selectedRuleId = ruleSelect.value;
            if (!selectedRuleId) return;

            const selectedRule = ruleData[selectedRuleId];
            const color = selectedRule.Severity === 'Ã‰levÃ©e' ? '#ff6384' : 
                          selectedRule.Severity === 'Moyenne' ? '#ffcd56' : '#4bc0c0';
            const bgColor = selectedRule.Severity === 'Ã‰levÃ©e' ? 'rgba(255, 99, 132, 0.2)' : 
                            selectedRule.Severity === 'Moyenne' ? 'rgba(255, 205, 86, 0.2)' : 'rgba(75, 192, 192, 0.2)';

            if (ruleChart) {
                ruleChart.destroy();
            }

            ruleChart = new Chart(ruleCtx, {
                type: 'line',
                data: {
                    labels: dates,
                    datasets: [{
                        label: `${selectedRuleId} - ${selectedRule.Name}`,
                        data: selectedRule.Counts,
                        borderColor: color,
                        backgroundColor: bgColor,
                        tension: 0.1,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        title: {
                            display: true,
                            text: `Ã‰volution des anomalies pour la rÃ¨gle ${selectedRuleId}`
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true
                        }
                    }
                }
            });
        }

        // Initialiser le graphique de rÃ¨gle avec la premiÃ¨re rÃ¨gle
        if (Object.keys(ruleData).length > 0) {
            ruleSelect.value = Object.keys(ruleData)[0];
            updateRuleChart();
        }

        // Top 5 des rÃ¨gles avec le plus d'anomalies
        const topRules = Object.keys(ruleData)
            .map(ruleId => ({
                id: ruleId,
                name: ruleData[ruleId].Name,
                severity: ruleData[ruleId].Severity,
                count: ruleData[ruleId].Counts[ruleData[ruleId].Counts.length - 1]
            }))
            .sort((a, b) => b.count - a.count)
            .slice(0, 5);

        const topRulesCtx = document.getElementById('topRulesChart').getContext('2d');
        const topRulesChart = new Chart(topRulesCtx, {
            type: 'bar',
            data: {
                labels: topRules.map(rule => rule.id),
                datasets: [{
                    label: 'Nombre d\'anomalies',
                    data: topRules.map(rule => rule.count),
                    backgroundColor: topRules.map(rule => 
                        rule.severity === 'Ã‰levÃ©e' ? 'rgba(255, 99, 132, 0.7)' : 
                        rule.severity === 'Moyenne' ? 'rgba(255, 205, 86, 0.7)' : 'rgba(75, 192, 192, 0.7)'
                    ),
                    borderColor: topRules.map(rule => 
                        rule.severity === 'Ã‰levÃ©e' ? 'rgb(255, 99, 132)' : 
                        rule.severity === 'Moyenne' ? 'rgb(255, 205, 86)' : 'rgb(75, 192, 192)'
                    ),
                    borderWidth: 1
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    title: {
                        display: true,
                        text: 'Top 5 des rÃ¨gles avec le plus d\'anomalies'
                    },
                    tooltip: {
                        callbacks: {
                            label: function(context) {
                                const rule = topRules[context.dataIndex];
                                return `${rule.name}: ${rule.count} anomalies`;
                            }
                        }
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true
                    }
                }
            }
        });

        // Remplir le tableau des rÃ¨gles
        const ruleTable = document.getElementById('ruleTable');
        const sortedRules = Object.keys(ruleData)
            .map(ruleId => ({
                id: ruleId,
                name: ruleData[ruleId].Name,
                severity: ruleData[ruleId].Severity,
                count: ruleData[ruleId].Counts[ruleData[ruleId].Counts.length - 1],
                trend: ruleData[ruleId].Counts.length > 1 ? 
                       ruleData[ruleId].Counts[ruleData[ruleId].Counts.length - 1] - 
                       ruleData[ruleId].Counts[ruleData[ruleId].Counts.length - 2] : 0
            }))
            .sort((a, b) => b.count - a.count);

        for (const rule of sortedRules) {
            const row = document.createElement('tr');
            
            const idCell = document.createElement('td');
            idCell.textContent = rule.id;
            row.appendChild(idCell);
            
            const nameCell = document.createElement('td');
            nameCell.textContent = rule.name;
            row.appendChild(nameCell);
            
            const severityCell = document.createElement('td');
            severityCell.textContent = rule.severity;
            severityCell.className = `severity-${rule.severity.toLowerCase()}`;
            row.appendChild(severityCell);
            
            const countCell = document.createElement('td');
            countCell.textContent = rule.count;
            row.appendChild(countCell);
            
            const trendCell = document.createElement('td');
            if (rule.trend > 0) {
                trendCell.textContent = `â†‘ +${rule.trend}`;
                trendCell.style.color = 'red';
            } else if (rule.trend < 0) {
                trendCell.textContent = `â†“ ${rule.trend}`;
                trendCell.style.color = 'green';
            } else {
                trendCell.textContent = 'â†’ 0';
                trendCell.style.color = 'gray';
            }
            row.appendChild(trendCell);
            
            ruleTable.appendChild(row);
        }
    </script>
</body>
</html>
"@

        # Enregistrer le tableau de bord HTML
        $dashboardHtml | Out-File -FilePath $DashboardPath -Encoding UTF8
        Write-Verbose "Tableau de bord gÃ©nÃ©rÃ©: $DashboardPath"

        # Retourner un objet avec les informations du tableau de bord
        return [PSCustomObject]@{
            ServerInstance = $ServerInstance
            DashboardPath = $DashboardPath
            ReportsAnalyzed = $reportData.Count
            HistoryDays = $HistoryDays
            LastReportDate = $reportData[-1].ReportDate
            TotalAnomalies = $reportData[-1].TotalAnomalies
        }
    }
    catch {
        Write-Error "Erreur lors de la gÃ©nÃ©ration du tableau de bord: $_"
    }
}


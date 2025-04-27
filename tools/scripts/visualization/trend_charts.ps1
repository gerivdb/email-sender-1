<#
.SYNOPSIS
    Script de gÃ©nÃ©ration de graphiques de tendances pour les donnÃ©es de performance.
.DESCRIPTION
    Ce script gÃ©nÃ¨re des graphiques de tendances pour visualiser les donnÃ©es de performance
    du systÃ¨me, des applications et des mÃ©triques mÃ©tier.
.PARAMETER DataPath
    Chemin vers les donnÃ©es de performance.
.PARAMETER OutputPath
    Chemin oÃ¹ les graphiques seront sauvegardÃ©s.
.PARAMETER TemplatesPath
    Chemin vers les templates de graphiques.
.PARAMETER ChartType
    Type de graphique Ã  gÃ©nÃ©rer (line, area, bar, scatter).
.PARAMETER MetricType
    Type de mÃ©trique (system, application, business).
.PARAMETER StartDate
    Date de dÃ©but pour les donnÃ©es Ã  visualiser.
.PARAMETER EndDate
    Date de fin pour les donnÃ©es Ã  visualiser.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$DataPath = "data/performance",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "output/charts",
    
    [Parameter(Mandatory=$false)]
    [string]$TemplatesPath = "templates/charts/chart_templates.json",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("line", "area", "bar", "scatter", "all")]
    [string]$ChartType = "all",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("system", "application", "business", "all")]
    [string]$MetricType = "all",
    
    [Parameter(Mandatory=$false)]
    [DateTime]$StartDate = (Get-Date).AddDays(-7),
    
    [Parameter(Mandatory=$false)]
    [DateTime]$EndDate = (Get-Date)
)

# Fonction pour la journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [ValidateSet("Verbose", "Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    switch ($Level) {
        "Verbose" { Write-Verbose $LogMessage }
        "Info" { Write-Host $LogMessage -ForegroundColor Cyan }
        "Warning" { Write-Host $LogMessage -ForegroundColor Yellow }
        "Error" { Write-Host $LogMessage -ForegroundColor Red }
    }
}

# Fonction pour charger les templates de graphiques
function Import-ChartTemplates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TemplatesPath
    )
    
    Write-Log -Message "Chargement des templates de graphiques depuis $TemplatesPath" -Level "Info"
    
    try {
        if (Test-Path -Path $TemplatesPath) {
            $Templates = Get-Content -Path $TemplatesPath -Raw | ConvertFrom-Json
            Write-Log -Message "Templates chargÃ©s avec succÃ¨s: $($Templates.templates.Count) templates disponibles" -Level "Info"
            return $Templates.templates
        } else {
            Write-Log -Message "Fichier de templates non trouvÃ©: $TemplatesPath" -Level "Error"
            return $null
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement des templates: $_" -Level "Error"
        return $null
    }
}

# Fonction pour charger les donnÃ©es de performance
function Import-PerformanceData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DataPath,
        
        [Parameter(Mandatory=$true)]
        [string]$MetricType,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$EndDate
    )
    
    Write-Log -Message "Chargement des donnÃ©es de performance de type $MetricType" -Level "Info"
    
    try {
        $DataFile = Join-Path -Path $DataPath -ChildPath "$($MetricType)_metrics.csv"
        
        if (Test-Path -Path $DataFile) {
            $Data = Import-Csv -Path $DataFile
            
            # Convertir les timestamps en objets DateTime
            $Data = $Data | ForEach-Object {
                $_ | Add-Member -MemberType NoteProperty -Name "DateTime" -Value ([DateTime]::Parse($_.Timestamp)) -Force
                $_
            }
            
            # Filtrer par plage de dates
            $FilteredData = $Data | Where-Object { $_.DateTime -ge $StartDate -and $_.DateTime -le $EndDate }
            
            Write-Log -Message "DonnÃ©es chargÃ©es avec succÃ¨s: $($FilteredData.Count) entrÃ©es" -Level "Info"
            return $FilteredData
        } else {
            Write-Log -Message "Fichier de donnÃ©es non trouvÃ©: $DataFile" -Level "Warning"
            return $null
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement des donnÃ©es: $_" -Level "Error"
        return $null
    }
}

# Fonction pour gÃ©nÃ©rer un graphique de tendance
function New-TrendChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [object]$Template,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$MetricName,
        
        [Parameter(Mandatory=$false)]
        [string]$Title = "",
        
        [Parameter(Mandatory=$false)]
        [hashtable]$AdditionalOptions = @{}
    )
    
    Write-Log -Message "GÃ©nÃ©ration d'un graphique de type $($Template.type) pour la mÃ©trique $MetricName" -Level "Info"
    
    try {
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        $OutputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        
        # PrÃ©parer les donnÃ©es pour le graphique
        $ChartData = @{
            type = $Template.type
            data = @{
                labels = @($Data | ForEach-Object { $_.DateTime.ToString("yyyy-MM-dd HH:mm:ss") })
                datasets = @(
                    @{
                        label = $MetricName
                        data = @($Data | ForEach-Object { [double]$_.Value })
                        backgroundColor = $Template.options.colors[0]
                        borderColor = $Template.options.colors[0]
                        fill = $Template.type -eq "area"
                    }
                )
            }
            options = @{
                responsive = $true
                title = @{
                    display = $Title -ne ""
                    text = $Title
                }
                scales = @{
                    xAxes = @(
                        @{
                            type = $Template.options.xAxis.type
                            scaleLabel = @{
                                display = $true
                                labelString = $Template.options.xAxis.title
                            }
                        }
                    )
                    yAxes = @(
                        @{
                            scaleLabel = @{
                                display = $true
                                labelString = $Template.options.yAxis.title
                            }
                        }
                    )
                }
                tooltips = @{
                    enabled = $Template.options.tooltip.show
                }
                legend = @{
                    position = $Template.options.legend.position
                }
            }
        }
        
        # Ajouter les options supplÃ©mentaires
        foreach ($Key in $AdditionalOptions.Keys) {
            $ChartData.options[$Key] = $AdditionalOptions[$Key]
        }
        
        # Convertir en JSON
        $ChartJson = $ChartData | ConvertTo-Json -Depth 10
        
        # Sauvegarder le fichier de configuration du graphique
        $ChartJson | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Log -Message "Graphique gÃ©nÃ©rÃ© avec succÃ¨s: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la gÃ©nÃ©ration du graphique: $_" -Level "Error"
        return $false
    }
}

# Fonction pour gÃ©nÃ©rer un graphique HTML
function New-HtmlChart {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ChartConfigPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [string]$Title = "Graphique de tendance"
    )
    
    Write-Log -Message "GÃ©nÃ©ration du fichier HTML pour le graphique: $OutputPath" -Level "Info"
    
    try {
        # Lire la configuration du graphique
        $ChartConfig = Get-Content -Path $ChartConfigPath -Raw
        
        # CrÃ©er le contenu HTML
        $HtmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>$Title</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@2.9.4/dist/Chart.min.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
        }
        .chart-container {
            width: 80%;
            margin: 0 auto;
        }
    </style>
</head>
<body>
    <div class="chart-container">
        <canvas id="chart"></canvas>
    </div>
    <script>
        // Configuration du graphique
        var config = $ChartConfig;
        
        // CrÃ©er le graphique
        var ctx = document.getElementById('chart').getContext('2d');
        var chart = new Chart(ctx, config);
    </script>
</body>
</html>
"@
        
        # Sauvegarder le fichier HTML
        $HtmlContent | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Log -Message "Fichier HTML gÃ©nÃ©rÃ© avec succÃ¨s: $OutputPath" -Level "Info"
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la gÃ©nÃ©ration du fichier HTML: $_" -Level "Error"
        return $false
    }
}

# Fonction principale pour gÃ©nÃ©rer les graphiques de tendances
function Start-TrendChartGeneration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$DataPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [object[]]$Templates,
        
        [Parameter(Mandatory=$true)]
        [string]$ChartType,
        
        [Parameter(Mandatory=$true)]
        [string]$MetricType,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$EndDate
    )
    
    Write-Log -Message "DÃ©but de la gÃ©nÃ©ration des graphiques de tendances" -Level "Info"
    
    # DÃ©terminer les types de mÃ©triques Ã  traiter
    $MetricTypes = @()
    if ($MetricType -eq "all") {
        $MetricTypes = @("system", "application", "business")
    } else {
        $MetricTypes = @($MetricType)
    }
    
    # DÃ©terminer les types de graphiques Ã  gÃ©nÃ©rer
    $ChartTypes = @()
    if ($ChartType -eq "all") {
        $ChartTypes = @("line", "area", "bar", "scatter")
    } else {
        $ChartTypes = @($ChartType)
    }
    
    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # GÃ©nÃ©rer les graphiques pour chaque type de mÃ©trique
    foreach ($Type in $MetricTypes) {
        Write-Log -Message "Traitement des mÃ©triques de type: $Type" -Level "Info"
        
        # Charger les donnÃ©es
        $Data = Import-PerformanceData -DataPath $DataPath -MetricType $Type -StartDate $StartDate -EndDate $EndDate
        
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e disponible pour le type: $Type" -Level "Warning"
            continue
        }
        
        # Obtenir la liste des mÃ©triques uniques
        $Metrics = $Data | Select-Object -Property Metric -Unique
        
        foreach ($Metric in $Metrics) {
            $MetricName = $Metric.Metric
            Write-Log -Message "Traitement de la mÃ©trique: $MetricName" -Level "Info"
            
            # Filtrer les donnÃ©es pour cette mÃ©trique
            $MetricData = $Data | Where-Object { $_.Metric -eq $MetricName }
            
            foreach ($CType in $ChartTypes) {
                # Trouver le template correspondant
                $Template = $Templates | Where-Object { $_.type -eq $CType } | Select-Object -First 1
                
                if ($null -eq $Template) {
                    Write-Log -Message "Aucun template trouvÃ© pour le type de graphique: $CType" -Level "Warning"
                    continue
                }
                
                # GÃ©nÃ©rer le graphique
                $ChartOutputPath = Join-Path -Path $OutputPath -ChildPath "${Type}_${MetricName}_${CType}.json"
                $Success = New-TrendChart -Data $MetricData -Template $Template -OutputPath $ChartOutputPath -MetricName $MetricName -Title "$MetricName ($Type)"
                
                if ($Success) {
                    # GÃ©nÃ©rer le fichier HTML
                    $HtmlOutputPath = Join-Path -Path $OutputPath -ChildPath "${Type}_${MetricName}_${CType}.html"
                    New-HtmlChart -ChartConfigPath $ChartOutputPath -OutputPath $HtmlOutputPath -Title "$MetricName ($Type)"
                }
            }
        }
    }
    
    Write-Log -Message "GÃ©nÃ©ration des graphiques de tendances terminÃ©e" -Level "Info"
    return $true
}

# Point d'entrÃ©e principal
try {
    # Charger les templates de graphiques
    $Templates = Import-ChartTemplates -TemplatesPath $TemplatesPath
    
    if ($null -eq $Templates) {
        Write-Log -Message "Impossible de continuer sans templates de graphiques" -Level "Error"
        exit 1
    }
    
    # GÃ©nÃ©rer les graphiques
    $Result = Start-TrendChartGeneration -DataPath $DataPath -OutputPath $OutputPath -Templates $Templates -ChartType $ChartType -MetricType $MetricType -StartDate $StartDate -EndDate $EndDate
    
    if ($Result) {
        Write-Log -Message "GÃ©nÃ©ration des graphiques rÃ©ussie" -Level "Info"
        exit 0
    } else {
        Write-Log -Message "Ã‰chec de la gÃ©nÃ©ration des graphiques" -Level "Error"
        exit 1
    }
} catch {
    Write-Log -Message "Erreur non gÃ©rÃ©e: $_" -Level "Error"
    exit 1
}

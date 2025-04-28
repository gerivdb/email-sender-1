<#
.SYNOPSIS
    Script de gÃ©nÃ©ration de rapports automatiques.
.DESCRIPTION
    Ce script gÃ©nÃ¨re des rapports automatiques basÃ©s sur des templates
    et des donnÃ©es de performance.
.PARAMETER TemplateId
    ID du template de rapport Ã  utiliser.
.PARAMETER OutputPath
    Chemin oÃ¹ le rapport sera sauvegardÃ©.
.PARAMETER DataPath
    Chemin vers les donnÃ©es de performance.
.PARAMETER StartDate
    Date de dÃ©but pour les donnÃ©es Ã  inclure dans le rapport.
.PARAMETER EndDate
    Date de fin pour les donnÃ©es Ã  inclure dans le rapport.
.PARAMETER Format
    Format de sortie du rapport (html, pdf, excel).
.PARAMETER NotifyRecipients
    Indique si les destinataires doivent Ãªtre notifiÃ©s.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$TemplateId,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "output/reports",
    
    [Parameter(Mandatory=$false)]
    [string]$DataPath = "data/performance",
    
    [Parameter(Mandatory=$false)]
    [DateTime]$StartDate = (Get-Date).AddDays(-1),
    
    [Parameter(Mandatory=$false)]
    [DateTime]$EndDate = (Get-Date),
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("html", "pdf", "excel")]
    [string]$Format = "html",
    
    [Parameter(Mandatory=$false)]
    [switch]$NotifyRecipients
)

# Importer les modules nÃ©cessaires
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplateLoaderPath = Join-Path -Path $ScriptPath -ChildPath "report_template_loader.ps1"

# VÃ©rifier si le module existe
if (-not (Test-Path -Path $TemplateLoaderPath)) {
    Write-Error "Module de chargement des templates non trouvÃ©: $TemplateLoaderPath"
    exit 1
}

# Importer le module
. $TemplateLoaderPath

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
            
            # Filtrer par plage de temps
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

# Fonction pour calculer les statistiques
function Get-MetricStatistics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$Metric,
        
        [Parameter(Mandatory=$true)]
        [string]$Function,
        
        [Parameter(Mandatory=$false)]
        [double]$Percentile = 95
    )
    
    try {
        # Filtrer les donnÃ©es pour la mÃ©trique spÃ©cifiÃ©e
        $MetricData = $Data | Where-Object { $_.Metric -eq $Metric }
        
        if ($null -eq $MetricData -or $MetricData.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e trouvÃ©e pour la mÃ©trique: $Metric" -Level "Warning"
            return $null
        }
        
        # Convertir les valeurs en nombres
        $Values = $MetricData | ForEach-Object { [double]$_.Value }
        
        # Calculer la statistique demandÃ©e
        switch ($Function) {
            "avg" {
                $Result = ($Values | Measure-Object -Average).Average
            }
            "max" {
                $Result = ($Values | Measure-Object -Maximum).Maximum
            }
            "min" {
                $Result = ($Values | Measure-Object -Minimum).Minimum
            }
            "sum" {
                $Result = ($Values | Measure-Object -Sum).Sum
            }
            "count" {
                $Result = ($Values | Measure-Object).Count
            }
            "median" {
                $SortedValues = $Values | Sort-Object
                $Count = $SortedValues.Count
                if ($Count -eq 0) {
                    $Result = $null
                } elseif ($Count % 2 -eq 0) {
                    $Result = ($SortedValues[($Count / 2) - 1] + $SortedValues[$Count / 2]) / 2
                } else {
                    $Result = $SortedValues[($Count - 1) / 2]
                }
            }
            "percentile" {
                $SortedValues = $Values | Sort-Object
                $Count = $SortedValues.Count
                if ($Count -eq 0) {
                    $Result = $null
                } else {
                    $Index = [Math]::Ceiling(($Percentile / 100) * $Count) - 1
                    $Result = $SortedValues[$Index]
                }
            }
            "stddev" {
                $Avg = ($Values | Measure-Object -Average).Average
                $SumOfSquares = $Values | ForEach-Object { [Math]::Pow($_ - $Avg, 2) } | Measure-Object -Sum
                $Result = [Math]::Sqrt($SumOfSquares.Sum / $Values.Count)
            }
            default {
                Write-Log -Message "Fonction non prise en charge: $Function" -Level "Error"
                $Result = $null
            }
        }
        
        return $Result
    } catch {
        Write-Log -Message "Erreur lors du calcul des statistiques: $_" -Level "Error"
        return $null
    }
}

# Fonction pour dÃ©tecter les anomalies
function Get-MetricAnomalies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string]$Metric,
        
        [Parameter(Mandatory=$false)]
        [double]$Threshold = 2.0,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxAnomalies = 5
    )
    
    try {
        # Filtrer les donnÃ©es pour la mÃ©trique spÃ©cifiÃ©e
        $MetricData = $Data | Where-Object { $_.Metric -eq $Metric }
        
        if ($null -eq $MetricData -or $MetricData.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e trouvÃ©e pour la mÃ©trique: $Metric" -Level "Warning"
            return @()
        }
        
        # Convertir les valeurs en nombres
        $Values = $MetricData | ForEach-Object { 
            [PSCustomObject]@{
                DateTime = $_.DateTime
                Value = [double]$_.Value
            }
        }
        
        # Calculer la moyenne et l'Ã©cart-type
        $Avg = ($Values.Value | Measure-Object -Average).Average
        $SumOfSquares = $Values.Value | ForEach-Object { [Math]::Pow($_ - $Avg, 2) } | Measure-Object -Sum
        $StdDev = [Math]::Sqrt($SumOfSquares.Sum / $Values.Count)
        
        # DÃ©tecter les anomalies (valeurs en dehors de la plage moyenne +/- threshold * Ã©cart-type)
        $LowerBound = $Avg - ($Threshold * $StdDev)
        $UpperBound = $Avg + ($Threshold * $StdDev)
        
        $Anomalies = $Values | Where-Object { $_.Value -lt $LowerBound -or $_.Value -gt $UpperBound } | Sort-Object -Property { [Math]::Abs($_.Value - $Avg) } -Descending | Select-Object -First $MaxAnomalies
        
        # CrÃ©er des objets d'anomalie
        $AnomalyObjects = $Anomalies | ForEach-Object {
            $Deviation = [Math]::Abs(($_.Value - $Avg) / $StdDev)
            $Direction = if ($_.Value -gt $Avg) { "above" } else { "below" }
            
            [PSCustomObject]@{
                Metric = $Metric
                DateTime = $_.DateTime
                Value = $_.Value
                Average = $Avg
                Deviation = $Deviation
                Direction = $Direction
                Description = "Value $($_.Value) is $([Math]::Round($Deviation, 2)) standard deviations $Direction average ($([Math]::Round($Avg, 2)))"
            }
        }
        
        return $AnomalyObjects
    } catch {
        Write-Log -Message "Erreur lors de la dÃ©tection des anomalies: $_" -Level "Error"
        return @()
    }
}

# Fonction pour gÃ©nÃ©rer des recommandations
function Get-MetricRecommendations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Metrics
    )
    
    try {
        $Recommendations = @()
        
        foreach ($Metric in $Metrics) {
            # Filtrer les donnÃ©es pour la mÃ©trique spÃ©cifiÃ©e
            $MetricData = $Data | Where-Object { $_.Metric -eq $Metric }
            
            if ($null -eq $MetricData -or $MetricData.Count -eq 0) {
                Write-Log -Message "Aucune donnÃ©e trouvÃ©e pour la mÃ©trique: $Metric" -Level "Warning"
                continue
            }
            
            # Convertir les valeurs en nombres
            $Values = $MetricData | ForEach-Object { [double]$_.Value }
            
            # Calculer les statistiques
            $Avg = ($Values | Measure-Object -Average).Average
            $Max = ($Values | Measure-Object -Maximum).Maximum
            $Min = ($Values | Measure-Object -Minimum).Minimum
            
            # Analyser les tendances
            $SortedData = $MetricData | Sort-Object -Property DateTime
            $FirstHalf = $SortedData[0..([Math]::Floor($SortedData.Count / 2) - 1)]
            $SecondHalf = $SortedData[[Math]::Floor($SortedData.Count / 2)..($SortedData.Count - 1)]
            
            $FirstHalfAvg = ($FirstHalf | ForEach-Object { [double]$_.Value } | Measure-Object -Average).Average
            $SecondHalfAvg = ($SecondHalf | ForEach-Object { [double]$_.Value } | Measure-Object -Average).Average
            
            $Trend = $SecondHalfAvg - $FirstHalfAvg
            $TrendPercent = if ($FirstHalfAvg -ne 0) { ($Trend / $FirstHalfAvg) * 100 } else { 0 }
            
            # GÃ©nÃ©rer des recommandations basÃ©es sur l'analyse
            switch ($Metric) {
                "CPU" {
                    if ($Max -gt 90) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "L'utilisation CPU a atteint un pic de $([Math]::Round($Max, 2))%. Envisagez d'augmenter les ressources CPU ou d'optimiser les processus consommateurs."
                            Impact = "AmÃ©lioration des performances et rÃ©duction des temps de rÃ©ponse"
                            Effort = "Moyen"
                        }
                    }
                    
                    if ($TrendPercent -gt 10) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "medium"
                            Description = "L'utilisation CPU montre une tendance Ã  la hausse de $([Math]::Round($TrendPercent, 2))%. Surveillez cette mÃ©trique et planifiez une augmentation des ressources si la tendance se poursuit."
                            Impact = "PrÃ©vention des problÃ¨mes de performance futurs"
                            Effort = "Faible"
                        }
                    }
                }
                "Memory" {
                    if ($Max -gt 90) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "L'utilisation mÃ©moire a atteint un pic de $([Math]::Round($Max, 2))%. Envisagez d'augmenter la mÃ©moire disponible ou d'optimiser l'utilisation mÃ©moire des applications."
                            Impact = "RÃ©duction des risques de swapping et amÃ©lioration des performances"
                            Effort = "Moyen"
                        }
                    }
                    
                    if ($TrendPercent -gt 10) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "medium"
                            Description = "L'utilisation mÃ©moire montre une tendance Ã  la hausse de $([Math]::Round($TrendPercent, 2))%. Surveillez cette mÃ©trique et recherchez d'Ã©ventuelles fuites mÃ©moire."
                            Impact = "PrÃ©vention des problÃ¨mes de performance et de stabilitÃ©"
                            Effort = "Moyen"
                        }
                    }
                }
                "Disk" {
                    if ($Max -gt 85) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "L'utilisation disque a atteint $([Math]::Round($Max, 2))%. Envisagez d'augmenter l'espace disque ou de nettoyer les fichiers inutilisÃ©s."
                            Impact = "PrÃ©vention des problÃ¨mes de manque d'espace disque"
                            Effort = "Faible"
                        }
                    }
                    
                    if ($TrendPercent -gt 5) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "medium"
                            Description = "L'utilisation disque montre une tendance Ã  la hausse de $([Math]::Round($TrendPercent, 2))%. Mettez en place une politique de rotation des logs et d'archivage."
                            Impact = "Gestion proactive de l'espace disque"
                            Effort = "Moyen"
                        }
                    }
                }
                "ResponseTime" {
                    if ($Avg -gt 1000) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "Le temps de rÃ©ponse moyen est de $([Math]::Round($Avg, 2)) ms, ce qui est Ã©levÃ©. Optimisez les requÃªtes de base de donnÃ©es et le code applicatif."
                            Impact = "AmÃ©lioration de l'expÃ©rience utilisateur et des performances"
                            Effort = "Ã‰levÃ©"
                        }
                    }
                    
                    if ($TrendPercent -gt 10) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "medium"
                            Description = "Le temps de rÃ©ponse montre une tendance Ã  la hausse de $([Math]::Round($TrendPercent, 2))%. Analysez les causes de cette dÃ©gradation."
                            Impact = "PrÃ©vention de la dÃ©gradation de l'expÃ©rience utilisateur"
                            Effort = "Moyen"
                        }
                    }
                }
                "ErrorRate" {
                    if ($Avg -gt 1) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "Le taux d'erreur moyen est de $([Math]::Round($Avg, 2))%, ce qui est Ã©levÃ©. Analysez les logs d'erreur et corrigez les problÃ¨mes identifiÃ©s."
                            Impact = "AmÃ©lioration de la fiabilitÃ© et de l'expÃ©rience utilisateur"
                            Effort = "Ã‰levÃ©"
                        }
                    }
                    
                    if ($Max -gt 5) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "Le taux d'erreur a atteint un pic de $([Math]::Round($Max, 2))%. Mettez en place un systÃ¨me de dÃ©tection et d'alerte pour les pics d'erreurs."
                            Impact = "DÃ©tection rapide des problÃ¨mes"
                            Effort = "Moyen"
                        }
                    }
                }
                "EMAIL_DELIVERY_RATE" {
                    if ($Avg -lt 95) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "Le taux de livraison des emails est de $([Math]::Round($Avg, 2))%, ce qui est infÃ©rieur Ã  l'objectif de 95%. VÃ©rifiez la configuration SMTP et la rÃ©putation de l'expÃ©diteur."
                            Impact = "AmÃ©lioration de la dÃ©livrabilitÃ© des emails"
                            Effort = "Moyen"
                        }
                    }
                }
                "EMAIL_OPEN_RATE" {
                    if ($Avg -lt 10) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "medium"
                            Description = "Le taux d'ouverture des emails est de $([Math]::Round($Avg, 2))%, ce qui est faible. AmÃ©liorez les lignes d'objet et le contenu des emails."
                            Impact = "Augmentation de l'engagement des destinataires"
                            Effort = "Moyen"
                        }
                    }
                }
                "CONVERSION_RATE" {
                    if ($Avg -lt 1) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "Le taux de conversion est de $([Math]::Round($Avg, 2))%, ce qui est faible. Optimisez les pages de destination et les appels Ã  l'action."
                            Impact = "Augmentation des conversions et du ROI"
                            Effort = "Ã‰levÃ©"
                        }
                    }
                }
            }
        }
        
        # Trier les recommandations par prioritÃ©
        $PriorityOrder = @{
            "high" = 1
            "medium" = 2
            "low" = 3
        }
        
        $SortedRecommendations = $Recommendations | Sort-Object -Property { $PriorityOrder[$_.Priority] }
        
        return $SortedRecommendations
    } catch {
        Write-Log -Message "Erreur lors de la gÃ©nÃ©ration des recommandations: $_" -Level "Error"
        return @()
    }
}

# Fonction principale pour gÃ©nÃ©rer un rapport
function New-Report {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TemplateId,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$true)]
        [string]$DataPath,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$StartDate,
        
        [Parameter(Mandatory=$true)]
        [DateTime]$EndDate,
        
        [Parameter(Mandatory=$true)]
        [string]$Format
    )
    
    try {
        # Charger le template
        Write-Log -Message "Chargement du template: $TemplateId" -Level "Info"
        $Template = Get-ReportTemplate -TemplateId $TemplateId
        
        if ($null -eq $Template) {
            Write-Log -Message "Template non trouvÃ©: $TemplateId" -Level "Error"
            return $false
        }
        
        # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
        $OutputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        
        # Charger les donnÃ©es selon le type de rapport
        $Data = Import-PerformanceData -DataPath $DataPath -MetricType $Template.type -StartDate $StartDate -EndDate $EndDate
        
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnÃ©e disponible pour le type: $($Template.type)" -Level "Warning"
            return $false
        }
        
        # PrÃ©parer la structure du rapport
        $Report = @{
            id = $Template.id
            name = $Template.name
            description = $Template.description
            type = $Template.type
            generated_at = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            period = @{
                start_date = $StartDate.ToString("yyyy-MM-dd HH:mm:ss")
                end_date = $EndDate.ToString("yyyy-MM-dd HH:mm:ss")
            }
            sections = @()
        }
        
        # GÃ©nÃ©rer chaque section du rapport
        foreach ($Section in $Template.sections) {
            Write-Log -Message "GÃ©nÃ©ration de la section: $($Section.id)" -Level "Verbose"
            
            $SectionData = @{
                id = $Section.id
                title = $Section.title
                type = $Section.type
            }
            
            # Traiter la section selon son type
            switch ($Section.type) {
                "text" {
                    # Remplacer les variables dans le contenu
                    $Content = $Section.content
                    $Content = $Content.Replace("{start_date}", $StartDate.ToString("yyyy-MM-dd"))
                    $Content = $Content.Replace("{end_date}", $EndDate.ToString("yyyy-MM-dd"))
                    
                    $SectionData.content = $Content
                }
                "metrics_summary" {
                    $Metrics = @()
                    
                    foreach ($Metric in $Section.metrics) {
                        $Value = Get-MetricStatistics -Data $Data -Metric $Metric.metric -Function $Metric.function -Percentile ($Metric.percentile ?? 95)
                        
                        if ($null -ne $Value) {
                            # Formater la valeur
                            $FormattedValue = if ($Metric.format) {
                                $Metric.format.Replace("{value}", [Math]::Round($Value, 2))
                            } else {
                                [Math]::Round($Value, 2).ToString()
                            }
                            
                            $Metrics += @{
                                id = $Metric.id
                                name = $Metric.name
                                value = $Value
                                formatted_value = $FormattedValue
                            }
                        }
                    }
                    
                    $SectionData.metrics = $Metrics
                }
                "chart" {
                    # Pour l'instant, nous stockons simplement les donnÃ©es pour le graphique
                    # La gÃ©nÃ©ration rÃ©elle du graphique sera effectuÃ©e par le module d'export
                    
                    if ($Section.PSObject.Properties.Name -contains "metrics") {
                        # Graphique multi-mÃ©triques
                        $ChartData = @()
                        
                        foreach ($Metric in $Section.metrics) {
                            $MetricData = $Data | Where-Object { $_.Metric -eq $Metric } | Sort-Object -Property DateTime
                            
                            $Series = @{
                                name = $Metric
                                data = @($MetricData | ForEach-Object {
                                    @{
                                        x = $_.DateTime.ToString("yyyy-MM-dd HH:mm:ss")
                                        y = [double]$_.Value
                                    }
                                })
                            }
                            
                            $ChartData += $Series
                        }
                        
                        $SectionData.chart_data = $ChartData
                    } else {
                        # Graphique simple mÃ©trique
                        $MetricData = $Data | Where-Object { $_.Metric -eq $Section.metric } | Sort-Object -Property DateTime
                        
                        $Series = @{
                            name = $Section.metric
                            data = @($MetricData | ForEach-Object {
                                @{
                                    x = $_.DateTime.ToString("yyyy-MM-dd HH:mm:ss")
                                    y = [double]$_.Value
                                }
                            })
                        }
                        
                        $SectionData.chart_data = @($Series)
                    }
                    
                    $SectionData.chart_type = $Section.chart_type
                    $SectionData.options = $Section.options
                }
                "anomalies" {
                    $AllAnomalies = @()
                    
                    foreach ($Metric in $Section.metrics) {
                        $Anomalies = Get-MetricAnomalies -Data $Data -Metric $Metric -Threshold $Section.threshold -MaxAnomalies $Section.max_anomalies
                        $AllAnomalies += $Anomalies
                    }
                    
                    # Trier par dÃ©viation
                    $SortedAnomalies = $AllAnomalies | Sort-Object -Property Deviation -Descending | Select-Object -First $Section.max_anomalies
                    
                    $SectionData.anomalies = $SortedAnomalies
                }
                "recommendations" {
                    $Recommendations = Get-MetricRecommendations -Data $Data -Metrics $Section.based_on
                    
                    $SectionData.recommendations = $Recommendations
                }
            }
            
            $Report.sections += $SectionData
        }
        
        # Sauvegarder le rapport au format JSON (intermÃ©diaire)
        $ReportJson = $Report | ConvertTo-Json -Depth 10
        $JsonPath = [System.IO.Path]::ChangeExtension($OutputPath, "json")
        $ReportJson | Out-File -FilePath $JsonPath -Encoding UTF8
        
        Write-Log -Message "Rapport gÃ©nÃ©rÃ© avec succÃ¨s: $JsonPath" -Level "Info"
        
        # TODO: Appeler le module d'export pour convertir le rapport au format demandÃ©
        # Cette partie sera implÃ©mentÃ©e dans le module report_exporter.ps1
        
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la gÃ©nÃ©ration du rapport: $_" -Level "Error"
        return $false
    }
}

# Point d'entrÃ©e principal
try {
    # GÃ©nÃ©rer le rapport
    $Result = New-Report -TemplateId $TemplateId -OutputPath $OutputPath -DataPath $DataPath -StartDate $StartDate -EndDate $EndDate -Format $Format
    
    if ($Result) {
        Write-Log -Message "GÃ©nÃ©ration du rapport rÃ©ussie" -Level "Info"
        
        # TODO: Notifier les destinataires si demandÃ©
        # Cette partie sera implÃ©mentÃ©e dans le module report_distributor.ps1
        
        exit 0
    } else {
        Write-Log -Message "Ã‰chec de la gÃ©nÃ©ration du rapport" -Level "Error"
        exit 1
    }
} catch {
    Write-Log -Message "Erreur non gÃ©rÃ©e: $_" -Level "Error"
    exit 1
}

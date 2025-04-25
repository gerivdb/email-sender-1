<#
.SYNOPSIS
    Script de génération de rapports automatiques.
.DESCRIPTION
    Ce script génère des rapports automatiques basés sur des templates
    et des données de performance.
.PARAMETER TemplateId
    ID du template de rapport à utiliser.
.PARAMETER OutputPath
    Chemin où le rapport sera sauvegardé.
.PARAMETER DataPath
    Chemin vers les données de performance.
.PARAMETER StartDate
    Date de début pour les données à inclure dans le rapport.
.PARAMETER EndDate
    Date de fin pour les données à inclure dans le rapport.
.PARAMETER Format
    Format de sortie du rapport (html, pdf, excel).
.PARAMETER NotifyRecipients
    Indique si les destinataires doivent être notifiés.
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

# Importer les modules nécessaires
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$TemplateLoaderPath = Join-Path -Path $ScriptPath -ChildPath "report_template_loader.ps1"

# Vérifier si le module existe
if (-not (Test-Path -Path $TemplateLoaderPath)) {
    Write-Error "Module de chargement des templates non trouvé: $TemplateLoaderPath"
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

# Fonction pour charger les données de performance
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
    
    Write-Log -Message "Chargement des données de performance de type $MetricType" -Level "Info"
    
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
            
            Write-Log -Message "Données chargées avec succès: $($FilteredData.Count) entrées" -Level "Info"
            return $FilteredData
        } else {
            Write-Log -Message "Fichier de données non trouvé: $DataFile" -Level "Warning"
            return $null
        }
    } catch {
        Write-Log -Message "Erreur lors du chargement des données: $_" -Level "Error"
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
        # Filtrer les données pour la métrique spécifiée
        $MetricData = $Data | Where-Object { $_.Metric -eq $Metric }
        
        if ($null -eq $MetricData -or $MetricData.Count -eq 0) {
            Write-Log -Message "Aucune donnée trouvée pour la métrique: $Metric" -Level "Warning"
            return $null
        }
        
        # Convertir les valeurs en nombres
        $Values = $MetricData | ForEach-Object { [double]$_.Value }
        
        # Calculer la statistique demandée
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

# Fonction pour détecter les anomalies
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
        # Filtrer les données pour la métrique spécifiée
        $MetricData = $Data | Where-Object { $_.Metric -eq $Metric }
        
        if ($null -eq $MetricData -or $MetricData.Count -eq 0) {
            Write-Log -Message "Aucune donnée trouvée pour la métrique: $Metric" -Level "Warning"
            return @()
        }
        
        # Convertir les valeurs en nombres
        $Values = $MetricData | ForEach-Object { 
            [PSCustomObject]@{
                DateTime = $_.DateTime
                Value = [double]$_.Value
            }
        }
        
        # Calculer la moyenne et l'écart-type
        $Avg = ($Values.Value | Measure-Object -Average).Average
        $SumOfSquares = $Values.Value | ForEach-Object { [Math]::Pow($_ - $Avg, 2) } | Measure-Object -Sum
        $StdDev = [Math]::Sqrt($SumOfSquares.Sum / $Values.Count)
        
        # Détecter les anomalies (valeurs en dehors de la plage moyenne +/- threshold * écart-type)
        $LowerBound = $Avg - ($Threshold * $StdDev)
        $UpperBound = $Avg + ($Threshold * $StdDev)
        
        $Anomalies = $Values | Where-Object { $_.Value -lt $LowerBound -or $_.Value -gt $UpperBound } | Sort-Object -Property { [Math]::Abs($_.Value - $Avg) } -Descending | Select-Object -First $MaxAnomalies
        
        # Créer des objets d'anomalie
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
        Write-Log -Message "Erreur lors de la détection des anomalies: $_" -Level "Error"
        return @()
    }
}

# Fonction pour générer des recommandations
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
            # Filtrer les données pour la métrique spécifiée
            $MetricData = $Data | Where-Object { $_.Metric -eq $Metric }
            
            if ($null -eq $MetricData -or $MetricData.Count -eq 0) {
                Write-Log -Message "Aucune donnée trouvée pour la métrique: $Metric" -Level "Warning"
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
            
            # Générer des recommandations basées sur l'analyse
            switch ($Metric) {
                "CPU" {
                    if ($Max -gt 90) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "L'utilisation CPU a atteint un pic de $([Math]::Round($Max, 2))%. Envisagez d'augmenter les ressources CPU ou d'optimiser les processus consommateurs."
                            Impact = "Amélioration des performances et réduction des temps de réponse"
                            Effort = "Moyen"
                        }
                    }
                    
                    if ($TrendPercent -gt 10) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "medium"
                            Description = "L'utilisation CPU montre une tendance à la hausse de $([Math]::Round($TrendPercent, 2))%. Surveillez cette métrique et planifiez une augmentation des ressources si la tendance se poursuit."
                            Impact = "Prévention des problèmes de performance futurs"
                            Effort = "Faible"
                        }
                    }
                }
                "Memory" {
                    if ($Max -gt 90) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "L'utilisation mémoire a atteint un pic de $([Math]::Round($Max, 2))%. Envisagez d'augmenter la mémoire disponible ou d'optimiser l'utilisation mémoire des applications."
                            Impact = "Réduction des risques de swapping et amélioration des performances"
                            Effort = "Moyen"
                        }
                    }
                    
                    if ($TrendPercent -gt 10) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "medium"
                            Description = "L'utilisation mémoire montre une tendance à la hausse de $([Math]::Round($TrendPercent, 2))%. Surveillez cette métrique et recherchez d'éventuelles fuites mémoire."
                            Impact = "Prévention des problèmes de performance et de stabilité"
                            Effort = "Moyen"
                        }
                    }
                }
                "Disk" {
                    if ($Max -gt 85) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "L'utilisation disque a atteint $([Math]::Round($Max, 2))%. Envisagez d'augmenter l'espace disque ou de nettoyer les fichiers inutilisés."
                            Impact = "Prévention des problèmes de manque d'espace disque"
                            Effort = "Faible"
                        }
                    }
                    
                    if ($TrendPercent -gt 5) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "medium"
                            Description = "L'utilisation disque montre une tendance à la hausse de $([Math]::Round($TrendPercent, 2))%. Mettez en place une politique de rotation des logs et d'archivage."
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
                            Description = "Le temps de réponse moyen est de $([Math]::Round($Avg, 2)) ms, ce qui est élevé. Optimisez les requêtes de base de données et le code applicatif."
                            Impact = "Amélioration de l'expérience utilisateur et des performances"
                            Effort = "Élevé"
                        }
                    }
                    
                    if ($TrendPercent -gt 10) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "medium"
                            Description = "Le temps de réponse montre une tendance à la hausse de $([Math]::Round($TrendPercent, 2))%. Analysez les causes de cette dégradation."
                            Impact = "Prévention de la dégradation de l'expérience utilisateur"
                            Effort = "Moyen"
                        }
                    }
                }
                "ErrorRate" {
                    if ($Avg -gt 1) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "Le taux d'erreur moyen est de $([Math]::Round($Avg, 2))%, ce qui est élevé. Analysez les logs d'erreur et corrigez les problèmes identifiés."
                            Impact = "Amélioration de la fiabilité et de l'expérience utilisateur"
                            Effort = "Élevé"
                        }
                    }
                    
                    if ($Max -gt 5) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "Le taux d'erreur a atteint un pic de $([Math]::Round($Max, 2))%. Mettez en place un système de détection et d'alerte pour les pics d'erreurs."
                            Impact = "Détection rapide des problèmes"
                            Effort = "Moyen"
                        }
                    }
                }
                "EMAIL_DELIVERY_RATE" {
                    if ($Avg -lt 95) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "high"
                            Description = "Le taux de livraison des emails est de $([Math]::Round($Avg, 2))%, ce qui est inférieur à l'objectif de 95%. Vérifiez la configuration SMTP et la réputation de l'expéditeur."
                            Impact = "Amélioration de la délivrabilité des emails"
                            Effort = "Moyen"
                        }
                    }
                }
                "EMAIL_OPEN_RATE" {
                    if ($Avg -lt 10) {
                        $Recommendations += [PSCustomObject]@{
                            Metric = $Metric
                            Priority = "medium"
                            Description = "Le taux d'ouverture des emails est de $([Math]::Round($Avg, 2))%, ce qui est faible. Améliorez les lignes d'objet et le contenu des emails."
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
                            Description = "Le taux de conversion est de $([Math]::Round($Avg, 2))%, ce qui est faible. Optimisez les pages de destination et les appels à l'action."
                            Impact = "Augmentation des conversions et du ROI"
                            Effort = "Élevé"
                        }
                    }
                }
            }
        }
        
        # Trier les recommandations par priorité
        $PriorityOrder = @{
            "high" = 1
            "medium" = 2
            "low" = 3
        }
        
        $SortedRecommendations = $Recommendations | Sort-Object -Property { $PriorityOrder[$_.Priority] }
        
        return $SortedRecommendations
    } catch {
        Write-Log -Message "Erreur lors de la génération des recommandations: $_" -Level "Error"
        return @()
    }
}

# Fonction principale pour générer un rapport
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
            Write-Log -Message "Template non trouvé: $TemplateId" -Level "Error"
            return $false
        }
        
        # Créer le répertoire de sortie s'il n'existe pas
        $OutputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        
        # Charger les données selon le type de rapport
        $Data = Import-PerformanceData -DataPath $DataPath -MetricType $Template.type -StartDate $StartDate -EndDate $EndDate
        
        if ($null -eq $Data -or $Data.Count -eq 0) {
            Write-Log -Message "Aucune donnée disponible pour le type: $($Template.type)" -Level "Warning"
            return $false
        }
        
        # Préparer la structure du rapport
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
        
        # Générer chaque section du rapport
        foreach ($Section in $Template.sections) {
            Write-Log -Message "Génération de la section: $($Section.id)" -Level "Verbose"
            
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
                    # Pour l'instant, nous stockons simplement les données pour le graphique
                    # La génération réelle du graphique sera effectuée par le module d'export
                    
                    if ($Section.PSObject.Properties.Name -contains "metrics") {
                        # Graphique multi-métriques
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
                        # Graphique simple métrique
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
                    
                    # Trier par déviation
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
        
        # Sauvegarder le rapport au format JSON (intermédiaire)
        $ReportJson = $Report | ConvertTo-Json -Depth 10
        $JsonPath = [System.IO.Path]::ChangeExtension($OutputPath, "json")
        $ReportJson | Out-File -FilePath $JsonPath -Encoding UTF8
        
        Write-Log -Message "Rapport généré avec succès: $JsonPath" -Level "Info"
        
        # TODO: Appeler le module d'export pour convertir le rapport au format demandé
        # Cette partie sera implémentée dans le module report_exporter.ps1
        
        return $true
    } catch {
        Write-Log -Message "Erreur lors de la génération du rapport: $_" -Level "Error"
        return $false
    }
}

# Point d'entrée principal
try {
    # Générer le rapport
    $Result = New-Report -TemplateId $TemplateId -OutputPath $OutputPath -DataPath $DataPath -StartDate $StartDate -EndDate $EndDate -Format $Format
    
    if ($Result) {
        Write-Log -Message "Génération du rapport réussie" -Level "Info"
        
        # TODO: Notifier les destinataires si demandé
        # Cette partie sera implémentée dans le module report_distributor.ps1
        
        exit 0
    } else {
        Write-Log -Message "Échec de la génération du rapport" -Level "Error"
        exit 1
    }
} catch {
    Write-Log -Message "Erreur non gérée: $_" -Level "Error"
    exit 1
}

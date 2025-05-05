﻿<#
.SYNOPSIS
    Module d'export de rapports au format HTML.
.DESCRIPTION
    Ce module fournit des fonctions pour exporter des rapports au format HTML
    en utilisant des templates prÃƒÂ©dÃƒÂ©finis.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de crÃƒÂ©ation: 2025-04-23
#>

# DÃƒÂ©finition des chemins par dÃƒÂ©faut
$script:DefaultTemplatesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\templates\reports\html"
$script:BaseTemplatePath = Join-Path -Path $script:DefaultTemplatesPath -ChildPath "base_template.html"
$script:SectionTemplatesPath = Join-Path -Path $script:DefaultTemplatesPath -ChildPath "sectiondevelopment/templates.html"

# Cache pour les templates
$script:TemplatesCache = @{}

<#
.SYNOPSIS
    Charge un template HTML depuis un fichier.
.DESCRIPTION
    Cette fonction charge un template HTML depuis un fichier et le met en cache
    pour optimiser les accÃƒÂ¨s rÃƒÂ©pÃƒÂ©tÃƒÂ©s.
.PARAMETER TemplatePath
    Chemin vers le fichier de template HTML.
.PARAMETER TemplateKey
    ClÃƒÂ© pour identifier le template dans le cache.
.PARAMETER ForceReload
    Force le rechargement du template mÃƒÂªme s'il est en cache.
.EXAMPLE
    $Template = Get-HtmlTemplate -TemplatePath "templates/reports/html/base_template.html" -TemplateKey "base"
.OUTPUTS
    System.String - Le contenu du template HTML.
#>
function Get-HtmlTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TemplatePath,
        
        [Parameter(Mandatory=$true)]
        [string]$TemplateKey,
        
        [Parameter(Mandatory=$false)]
        [switch]$ForceReload
    )
    
    try {
        # VÃƒÂ©rifier si le template est dÃƒÂ©jÃƒÂ  en cache
        if (-not $ForceReload -and $script:TemplatesCache.ContainsKey($TemplateKey)) {
            Write-Verbose "Utilisation du template en cache pour $TemplateKey"
            return $script:TemplatesCache[$TemplateKey]
        }
        
        # VÃƒÂ©rifier si le fichier existe
        if (-not (Test-Path -Path $TemplatePath)) {
            Write-Error "Le fichier de template n'existe pas: $TemplatePath"
            return $null
        }
        
        # Charger le fichier
        Write-Verbose "Chargement du template depuis $TemplatePath"
        $TemplateContent = Get-Content -Path $TemplatePath -Raw -Encoding UTF8
        
        # Mettre en cache le template
        $script:TemplatesCache[$TemplateKey] = $TemplateContent
        
        return $TemplateContent
    }
    catch {
        Write-Error "Erreur lors du chargement du template: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Extrait une section spÃƒÂ©cifique d'un template HTML.
.DESCRIPTION
    Cette fonction extrait une section spÃƒÂ©cifique d'un template HTML
    en utilisant des marqueurs de dÃƒÂ©but et de fin.
.PARAMETER TemplateContent
    Contenu du template HTML.
.PARAMETER SectionName
    Nom de la section ÃƒÂ  extraire.
.PARAMETER StartMarker
    Marqueur de dÃƒÂ©but de la section (par dÃƒÂ©faut: "<!-- Template pour une section de").
.PARAMETER EndMarker
    Marqueur de fin de la section (par dÃƒÂ©faut: "<!-- Template pour").
.EXAMPLE
    $SectionTemplate = Get-HtmlTemplateSection -TemplateContent $SectionTemplates -SectionName "texte"
.OUTPUTS
    System.String - Le contenu de la section de template.
#>
function Get-HtmlTemplateSection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TemplateContent,
        
        [Parameter(Mandatory=$true)]
        [string]$SectionName,
        
        [Parameter(Mandatory=$false)]
        [string]$StartMarker = "<!-- Template pour une section de",
        
        [Parameter(Mandatory=$false)]
        [string]$EndMarker = "<!-- Template pour"
    )
    
    try {
        # Construire le marqueur de dÃƒÂ©but complet
        $FullStartMarker = "$StartMarker $SectionName -->"
        
        # Trouver la position du marqueur de dÃƒÂ©but
        $StartPos = $TemplateContent.IndexOf($FullStartMarker)
        
        if ($StartPos -eq -1) {
            Write-Error "Section de template non trouvÃƒÂ©e: $SectionName"
            return $null
        }
        
        # Trouver la position du prochain marqueur de dÃƒÂ©but (qui sera la fin de notre section)
        $EndPos = $TemplateContent.IndexOf($EndMarker, $StartPos + $FullStartMarker.Length)
        
        # Si aucun autre marqueur n'est trouvÃƒÂ©, prendre jusqu'ÃƒÂ  la fin du template
        if ($EndPos -eq -1) {
            $SectionContent = $TemplateContent.Substring($StartPos)
        }
        else {
            $SectionContent = $TemplateContent.Substring($StartPos, $EndPos - $StartPos)
        }
        
        return $SectionContent
    }
    catch {
        Write-Error "Erreur lors de l'extraction de la section de template: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Remplace les variables dans un template HTML.
.DESCRIPTION
    Cette fonction remplace les variables dans un template HTML
    en utilisant un dictionnaire de valeurs.
.PARAMETER TemplateContent
    Contenu du template HTML.
.PARAMETER Variables
    Dictionnaire de variables ÃƒÂ  remplacer.
.EXAMPLE
    $ProcessedTemplate = Replace-HtmlTemplateVariables -TemplateContent $Template -Variables @{ "report_title" = "Rapport de performance" }
.OUTPUTS
    System.String - Le contenu du template avec les variables remplacÃƒÂ©es.
#>
function Replace-HtmlTemplateVariables {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TemplateContent,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Variables
    )
    
    try {
        $Result = $TemplateContent
        
        # Remplacer chaque variable
        foreach ($Key in $Variables.Keys) {
            $Value = $Variables[$Key]
            $Result = $Result.Replace("{{$Key}}", $Value)
        }
        
        return $Result
    }
    catch {
        Write-Error "Erreur lors du remplacement des variables: $_"
        return $TemplateContent
    }
}

<#
.SYNOPSIS
    GÃƒÂ©nÃƒÂ¨re le code JavaScript pour initialiser les graphiques.
.DESCRIPTION
    Cette fonction gÃƒÂ©nÃƒÂ¨re le code JavaScript pour initialiser les graphiques
    dans un rapport HTML.
.PARAMETER Charts
    Liste des configurations de graphiques.
.EXAMPLE
    $ChartJs = New-ChartInitializationScript -Charts $ReportData.charts
.OUTPUTS
    System.String - Le code JavaScript pour initialiser les graphiques.
#>
function New-ChartInitializationScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Charts
    )
    
    try {
        $ChartScripts = @()
        
        foreach ($Chart in $Charts) {
            $ChartId = "chart-$($Chart.id)"
            $ChartType = $Chart.chart_type
            $ChartData = $Chart.chart_data | ConvertTo-Json -Depth 10
            $ChartOptions = $Chart.options | ConvertTo-Json -Depth 10
            
            $Script = @"
// Initialisation du graphique $($Chart.id)
(function() {
    const ctx = document.getElementById('$ChartId').getContext('2d');
    const chartData = $ChartData;
    const chartOptions = $ChartOptions;
    
    new Chart(ctx, {
        type: '$ChartType',
        data: {
            datasets: chartData
        },
        options: chartOptions
    });
})();
"@
            
            $ChartScripts += $Script
        }
        
        return $ChartScripts -join "`n`n"
    }
    catch {
        Write-Error "Erreur lors de la gÃƒÂ©nÃƒÂ©ration du script d'initialisation des graphiques: $_"
        return "// Erreur lors de la gÃƒÂ©nÃƒÂ©ration du script d'initialisation des graphiques"
    }
}

<#
.SYNOPSIS
    GÃƒÂ©nÃƒÂ¨re une section de rapport HTML.
.DESCRIPTION
    Cette fonction gÃƒÂ©nÃƒÂ¨re une section de rapport HTML
    en utilisant un template et des donnÃƒÂ©es.
.PARAMETER SectionData
    DonnÃƒÂ©es de la section.
.PARAMETER SectionTemplates
    Contenu des templates de sections.
.EXAMPLE
    $SectionHtml = New-ReportSection -SectionData $Section -SectionTemplates $SectionTemplates
.OUTPUTS
    System.String - Le HTML de la section.
#>
function New-ReportSection {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$SectionData,
        
        [Parameter(Mandatory=$true)]
        [string]$SectionTemplates
    )
    
    try {
        # DÃƒÂ©terminer le type de section
        $SectionType = $SectionData.type
        
        # Extraire le template de section appropriÃƒÂ©
        $SectionTemplate = Get-HtmlTemplateSection -TemplateContent $SectionTemplates -SectionName $SectionType
        
        if ($null -eq $SectionTemplate) {
            Write-Error "Template non trouvÃƒÂ© pour le type de section: $SectionType"
            return ""
        }
        
        # PrÃƒÂ©parer les variables pour le template
        $Variables = @{
            "section_id" = $SectionData.id
            "section_title" = $SectionData.title
        }
        
        # Ajouter des variables spÃƒÂ©cifiques selon le type de section
        switch ($SectionType) {
            "texte" {
                $Variables["section_content"] = $SectionData.content
            }
            "metrics_summary" {
                # Pour les mÃƒÂ©triques, nous devons gÃƒÂ©nÃƒÂ©rer le HTML pour chaque mÃƒÂ©trique
                $MetricsHtml = @()
                
                foreach ($Metric in $SectionData.metrics) {
                    $TrendHtml = ""
                    if ($Metric.PSObject.Properties.Name -contains "trend") {
                        $TrendClass = if ($Metric.trend -gt 0) { "trend-up" } else { "trend-down" }
                        $TrendIcon = if ($Metric.trend -gt 0) { "Ã¢â€ â€˜" } else { "Ã¢â€ â€œ" }
                        $TrendValue = "$([Math]::Abs($Metric.trend).ToString("0.00"))%"
                        
                        $TrendHtml = @"
<div class="metric-trend $TrendClass">
    <span class="trend-icon">$TrendIcon</span>
    <span class="trend-value">$TrendValue</span>
</div>
"@
                    }
                    
                    $MetricHtml = @"
<div class="metric-card">
    <h3 class="metric-name">$($Metric.name)</h3>
    <p class="metric-value">$($Metric.formatted_value)</p>
    $TrendHtml
</div>
"@
                    
                    $MetricsHtml += $MetricHtml
                }
                
                $Variables["metrics"] = ($MetricsHtml -join "`n")
            }
            "chart" {
                if ($SectionData.PSObject.Properties.Name -contains "chart_description") {
                    $Variables["chart_description"] = $SectionData.chart_description
                }
            }
            "table" {
                # Pour les tableaux, nous devons gÃƒÂ©nÃƒÂ©rer le HTML pour les en-tÃƒÂªtes et les lignes
                $HeadersHtml = @()
                foreach ($Column in $SectionData.columns) {
                    $HeadersHtml += "<th>$Column</th>"
                }
                
                $RowsHtml = @()
                foreach ($Row in $SectionData.rows) {
                    $CellsHtml = @()
                    foreach ($Cell in $Row) {
                        $CellsHtml += "<td>$Cell</td>"
                    }
                    
                    $RowsHtml += "<tr>$($CellsHtml -join "`n")</tr>"
                }
                
                $Variables["columns"] = ($HeadersHtml -join "`n")
                $Variables["rows"] = ($RowsHtml -join "`n")
            }
            "anomalies" {
                # Pour les anomalies, nous devons gÃƒÂ©nÃƒÂ©rer le HTML pour chaque anomalie
                $AnomaliesHtml = @()
                
                if ($SectionData.anomalies.Count -gt 0) {
                    foreach ($Anomaly in $SectionData.anomalies) {
                        $AnomalyHtml = @"
<li class="anomaly-item">
    <h3 class="anomaly-metric">$($Anomaly.metric)</h3>
    <p class="anomaly-description">$($Anomaly.description)</p>
    <p class="anomaly-time">DÃƒÂ©tectÃƒÂ© le $($Anomaly.datetime)</p>
</li>
"@
                        
                        $AnomaliesHtml += $AnomalyHtml
                    }
                    
                    $Variables["anomalies"] = ($AnomaliesHtml -join "`n")
                }
                else {
                    $Variables["anomalies"] = "<p>Aucune anomalie dÃƒÂ©tectÃƒÂ©e pendant la pÃƒÂ©riode analysÃƒÂ©e.</p>"
                }
            }
            "recommendations" {
                # Pour les recommandations, nous devons gÃƒÂ©nÃƒÂ©rer le HTML pour chaque recommandation
                $RecommendationsHtml = @()
                
                if ($SectionData.recommendations.Count -gt 0) {
                    foreach ($Recommendation in $SectionData.recommendations) {
                        $RecommendationHtml = @"
<li class="recommendation-item priority-$($Recommendation.priority)">
    <h3 class="recommendation-title">$($Recommendation.title)</h3>
    <p class="recommendation-description">$($Recommendation.description)</p>
    <div class="recommendation-meta">
        <span class="recommendation-impact">Impact: $($Recommendation.impact)</span>
        <span class="recommendation-effort">Effort: $($Recommendation.effort)</span>
    </div>
</li>
"@
                        
                        $RecommendationsHtml += $RecommendationHtml
                    }
                    
                    $Variables["recommendations"] = ($RecommendationsHtml -join "`n")
                }
                else {
                    $Variables["recommendations"] = "<p>Aucune recommandation pour la pÃƒÂ©riode analysÃƒÂ©e.</p>"
                }
            }
        }
        
        # Remplacer les variables dans le template
        $SectionHtml = Replace-HtmlTemplateVariables -TemplateContent $SectionTemplate -Variables $Variables
        
        return $SectionHtml
    }
    catch {
        Write-Error "Erreur lors de la gÃƒÂ©nÃƒÂ©ration de la section de rapport: $_"
        return ""
    }
}

<#
.SYNOPSIS
    GÃƒÂ©nÃƒÂ¨re la table des matiÃƒÂ¨res d'un rapport HTML.
.DESCRIPTION
    Cette fonction gÃƒÂ©nÃƒÂ¨re la table des matiÃƒÂ¨res d'un rapport HTML
    en utilisant les sections du rapport.
.PARAMETER Sections
    Liste des sections du rapport.
.PARAMETER SectionTemplates
    Contenu des templates de sections.
.EXAMPLE
    $TocHtml = New-TableOfContents -Sections $ReportData.sections -SectionTemplates $SectionTemplates
.OUTPUTS
    System.String - Le HTML de la table des matiÃƒÂ¨res.
#>
function New-TableOfContents {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$Sections,
        
        [Parameter(Mandatory=$true)]
        [string]$SectionTemplates
    )
    
    try {
        # Extraire le template d'ÃƒÂ©lÃƒÂ©ment de table des matiÃƒÂ¨res
        $TocItemTemplate = Get-HtmlTemplateSection -TemplateContent $SectionTemplates -SectionName "toc-item" -StartMarker "<!-- Template pour un ÃƒÂ©lÃƒÂ©ment de la table des matiÃƒÂ¨res" -EndMarker "</li>"
        
        if ($null -eq $TocItemTemplate) {
            Write-Error "Template non trouvÃƒÂ© pour l'ÃƒÂ©lÃƒÂ©ment de table des matiÃƒÂ¨res"
            return ""
        }
        
        # GÃƒÂ©nÃƒÂ©rer les ÃƒÂ©lÃƒÂ©ments de la table des matiÃƒÂ¨res
        $TocItems = @()
        
        foreach ($Section in $Sections) {
            $Variables = @{
                "section_id" = $Section.id
                "section_title" = $Section.title
            }
            
            $TocItemHtml = Replace-HtmlTemplateVariables -TemplateContent $TocItemTemplate -Variables $Variables
            $TocItems += $TocItemHtml
        }
        
        return $TocItems -join "`n"
    }
    catch {
        Write-Error "Erreur lors de la gÃƒÂ©nÃƒÂ©ration de la table des matiÃƒÂ¨res: $_"
        return ""
    }
}

<#
.SYNOPSIS
    Exporte un rapport au format HTML.
.DESCRIPTION
    Cette fonction exporte un rapport au format HTML
    en utilisant des templates prÃƒÂ©dÃƒÂ©finis.
.PARAMETER ReportData
    DonnÃƒÂ©es du rapport ÃƒÂ  exporter.
.PARAMETER OutputPath
    Chemin oÃƒÂ¹ le fichier HTML sera sauvegardÃƒÂ©.
.PARAMETER BaseTemplatePath
    Chemin vers le template HTML de base.
.PARAMETER SectionTemplatesPath
    Chemin vers les templates de sections.
.EXAMPLE
    $Result = Export-ReportToHtml -ReportData $ReportData -OutputPath "output/reports/report.html"
.OUTPUTS
    System.Boolean - True si l'export a rÃƒÂ©ussi, False sinon.
#>
function Export-ReportToHtml {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$ReportData,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory=$false)]
        [string]$BaseTemplatePath = $script:BaseTemplatePath,
        
        [Parameter(Mandatory=$false)]
        [string]$SectionTemplatesPath = $script:SectionTemplatesPath
    )
    
    try {
        # Charger les templates
        $BaseTemplate = Get-HtmlTemplate -TemplatePath $BaseTemplatePath -TemplateKey "base"
        $SectionTemplates = Get-HtmlTemplate -TemplatePath $SectionTemplatesPath -TemplateKey "sections"
        
        if ($null -eq $BaseTemplate -or $null -eq $SectionTemplates) {
            Write-Error "Impossible de charger les templates HTML"
            return $false
        }
        
        # GÃƒÂ©nÃƒÂ©rer la table des matiÃƒÂ¨res
        $TocHtml = New-TableOfContents -Sections $ReportData.sections -SectionTemplates $SectionTemplates
        
        # GÃƒÂ©nÃƒÂ©rer les sections du rapport
        $SectionsHtml = @()
        $Charts = @()
        
        foreach ($Section in $ReportData.sections) {
            $SectionHtml = New-ReportSection -SectionData $Section -SectionTemplates $SectionTemplates
            $SectionsHtml += $SectionHtml
            
            # Collecter les configurations de graphiques
            if ($Section.type -eq "chart") {
                $Charts += @{
                    id = $Section.id
                    chart_type = $Section.chart_type
                    chart_data = $Section.chart_data
                    options = $Section.options
                }
            }
        }
        
        # GÃƒÂ©nÃƒÂ©rer le script d'initialisation des graphiques
        $ChartInitScript = New-ChartInitializationScript -Charts $Charts
        
        # PrÃƒÂ©parer les variables pour le template de base
        $Variables = @{
            "report_title" = $ReportData.name
            "report_description" = $ReportData.description
            "report_period_start" = $ReportData.period.start_date
            "report_period_end" = $ReportData.period.end_date
            "report_generated_at" = $ReportData.generated_at
            "current_year" = (Get-Date).Year.ToString()
            "toc_items" = $TocHtml
            "report_sections" = ($SectionsHtml -join "`n")
            "chart_initialization" = $ChartInitScript
        }
        
        # Remplacer les variables dans le template de base
        $ReportHtml = Replace-HtmlTemplateVariables -TemplateContent $BaseTemplate -Variables $Variables
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de sortie s'il n'existe pas
        $OutputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }
        
        # Sauvegarder le fichier HTML
        $ReportHtml | Out-File -FilePath $OutputPath -Encoding UTF8
        
        Write-Verbose "Rapport HTML gÃƒÂ©nÃƒÂ©rÃƒÂ© avec succÃƒÂ¨s: $OutputPath"
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'export du rapport en HTML: $_"
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Export-ReportToHtml

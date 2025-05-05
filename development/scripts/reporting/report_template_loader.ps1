<#
.SYNOPSIS
    Module de chargement des templates de rapports.
.DESCRIPTION
    Ce module fournit des fonctions pour charger et valider les templates de rapports
    ÃƒÂ  partir de fichiers JSON.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de crÃƒÂ©ation: 2025-04-22
#>

# DÃƒÂ©finition des chemins par dÃƒÂ©faut
$script:DefaultTemplatesPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\templates\reports\reportdevelopment/templates.json"
$script:DefaultSchemaPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\docs\reporting\report_schema.json"

# Cache pour les templates chargÃƒÂ©s
$script:TemplatesCache = @{}
$script:LastCacheUpdate = $null
$script:CacheExpirationMinutes = 10

<#
.SYNOPSIS
    Charge les templates de rapports ÃƒÂ  partir d'un fichier JSON.
.DESCRIPTION
    Cette fonction charge les templates de rapports ÃƒÂ  partir d'un fichier JSON
    et les met en cache pour optimiser les accÃƒÂ¨s rÃƒÂ©pÃƒÂ©tÃƒÂ©s.
.PARAMETER TemplatesPath
    Chemin vers le fichier JSON contenant les templates de rapports.
.PARAMETER ForceReload
    Force le rechargement des templates mÃƒÂªme s'ils sont en cache.
.EXAMPLE
    $Templates = Import-ReportTemplates -TemplatesPath "templates/reports/reportdevelopment/templates.json"
.OUTPUTS
    System.Object[] - Les templates de rapports chargÃƒÂ©s.
#>
function Import-ReportTemplates {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$TemplatesPath = $script:DefaultTemplatesPath,
        
        [Parameter(Mandatory=$false)]
        [switch]$ForceReload
    )
    
    try {
        # VÃƒÂ©rifier si les templates sont dÃƒÂ©jÃƒÂ  en cache et si le cache est valide
        $CacheKey = $TemplatesPath
        $CurrentTime = Get-Date
        
        if (-not $ForceReload -and 
            $script:TemplatesCache.ContainsKey($CacheKey) -and 
            $script:LastCacheUpdate -ne $null -and 
            ($CurrentTime - $script:LastCacheUpdate).TotalMinutes -lt $script:CacheExpirationMinutes) {
            Write-Verbose "Utilisation des templates en cache pour $TemplatesPath"
            return $script:TemplatesCache[$CacheKey]
        }
        
        # VÃƒÂ©rifier si le fichier existe
        if (-not (Test-Path -Path $TemplatesPath)) {
            Write-Error "Le fichier de templates n'existe pas: $TemplatesPath"
            return $null
        }
        
        # Charger le fichier JSON
        Write-Verbose "Chargement des templates depuis $TemplatesPath"
        $TemplatesJson = Get-Content -Path $TemplatesPath -Raw -Encoding UTF8
        
        # DÃƒÂ©sÃƒÂ©rialiser le JSON
        $Templates = ConvertFrom-Json -InputObject $TemplatesJson -ErrorAction Stop
        
        # VÃƒÂ©rifier la structure de base
        if (-not (Get-Member -InputObject $Templates -Name "templates" -MemberType Properties)) {
            Write-Error "Le fichier de templates ne contient pas la propriÃƒÂ©tÃƒÂ© 'templates'"
            return $null
        }
        
        # Mettre en cache les templates
        $script:TemplatesCache[$CacheKey] = $Templates.templates
        $script:LastCacheUpdate = $CurrentTime
        
        Write-Verbose "Templates chargÃƒÂ©s avec succÃƒÂ¨s: $($Templates.templates.Count) templates"
        return $Templates.templates
    }
    catch {
        Write-Error "Erreur lors du chargement des templates: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Valide un template de rapport par rapport au schÃƒÂ©ma JSON.
.DESCRIPTION
    Cette fonction valide un template de rapport par rapport au schÃƒÂ©ma JSON
    pour s'assurer qu'il est conforme aux spÃƒÂ©cifications.
.PARAMETER Template
    Le template de rapport ÃƒÂ  valider.
.PARAMETER SchemaPath
    Chemin vers le fichier JSON contenant le schÃƒÂ©ma de validation.
.EXAMPLE
    $IsValid = Test-ReportTemplate -Template $Template -SchemaPath "docs/reporting/report_schema.json"
.OUTPUTS
    System.Boolean - True si le template est valide, False sinon.
#>
function Test-ReportTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [object]$Template,
        
        [Parameter(Mandatory=$false)]
        [string]$SchemaPath = $script:DefaultSchemaPath
    )
    
    try {
        # VÃƒÂ©rifier si le fichier de schÃƒÂ©ma existe
        if (-not (Test-Path -Path $SchemaPath)) {
            Write-Error "Le fichier de schÃƒÂ©ma n'existe pas: $SchemaPath"
            return $false
        }
        
        # VÃƒÂ©rifier les champs obligatoires de base
        $RequiredFields = @("id", "name", "description", "type", "format", "sections")
        foreach ($Field in $RequiredFields) {
            if (-not (Get-Member -InputObject $Template -Name $Field -MemberType Properties)) {
                Write-Error "Le template ne contient pas le champ obligatoire '$Field'"
                return $false
            }
        }
        
        # VÃƒÂ©rifier le type de rapport
        $ValidTypes = @("system", "application", "business")
        if ($ValidTypes -notcontains $Template.type) {
            Write-Error "Type de rapport invalide: $($Template.type). Valeurs valides: $($ValidTypes -join ', ')"
            return $false
        }
        
        # VÃƒÂ©rifier le format de rapport
        $ValidFormats = @("html", "pdf", "excel")
        if ($ValidFormats -notcontains $Template.format) {
            Write-Error "Format de rapport invalide: $($Template.format). Valeurs valides: $($ValidFormats -join ', ')"
            return $false
        }
        
        # VÃƒÂ©rifier les sections
        if ($Template.sections -isnot [array] -or $Template.sections.Count -eq 0) {
            Write-Error "Le template doit contenir au moins une section"
            return $false
        }
        
        # VÃƒÂ©rifier chaque section
        foreach ($Section in $Template.sections) {
            $SectionRequiredFields = @("id", "title", "type")
            foreach ($Field in $SectionRequiredFields) {
                if (-not (Get-Member -InputObject $Section -Name $Field -MemberType Properties)) {
                    Write-Error "La section ne contient pas le champ obligatoire '$Field'"
                    return $false
                }
            }
            
            # VÃƒÂ©rifier le type de section
            $ValidSectionTypes = @("text", "metrics_summary", "chart", "table", "anomalies", "recommendations")
            if ($ValidSectionTypes -notcontains $Section.type) {
                Write-Error "Type de section invalide: $($Section.type). Valeurs valides: $($ValidSectionTypes -join ', ')"
                return $false
            }
            
            # VÃƒÂ©rifications spÃƒÂ©cifiques selon le type de section
            switch ($Section.type) {
                "text" {
                    if (-not (Get-Member -InputObject $Section -Name "content" -MemberType Properties)) {
                        Write-Error "La section de type 'text' doit contenir le champ 'content'"
                        return $false
                    }
                }
                "metrics_summary" {
                    if (-not (Get-Member -InputObject $Section -Name "metrics" -MemberType Properties) -or 
                        $Section.metrics -isnot [array] -or 
                        $Section.metrics.Count -eq 0) {
                        Write-Error "La section de type 'metrics_summary' doit contenir un tableau 'metrics' non vide"
                        return $false
                    }
                    
                    foreach ($Metric in $Section.metrics) {
                        $MetricRequiredFields = @("id", "name", "metric", "function")
                        foreach ($Field in $MetricRequiredFields) {
                            if (-not (Get-Member -InputObject $Metric -Name $Field -MemberType Properties)) {
                                Write-Error "La mÃƒÂ©trique ne contient pas le champ obligatoire '$Field'"
                                return $false
                            }
                        }
                        
                        # VÃƒÂ©rifier la fonction
                        $ValidFunctions = @("avg", "max", "min", "sum", "count", "percentile", "median", "stddev")
                        if ($ValidFunctions -notcontains $Metric.function) {
                            Write-Error "Fonction de mÃƒÂ©trique invalide: $($Metric.function). Valeurs valides: $($ValidFunctions -join ', ')"
                            return $false
                        }
                        
                        # VÃƒÂ©rifier le percentile si nÃƒÂ©cessaire
                        if ($Metric.function -eq "percentile" -and 
                            (-not (Get-Member -InputObject $Metric -Name "percentile" -MemberType Properties) -or 
                             $Metric.percentile -lt 0 -or 
                             $Metric.percentile -gt 100)) {
                            Write-Error "La fonction 'percentile' nÃƒÂ©cessite un champ 'percentile' valide (0-100)"
                            return $false
                        }
                    }
                }
                "chart" {
                    if (-not (Get-Member -InputObject $Section -Name "chart_type" -MemberType Properties)) {
                        Write-Error "La section de type 'chart' doit contenir le champ 'chart_type'"
                        return $false
                    }
                    
                    $ValidChartTypes = @("line", "bar", "pie", "area", "scatter", "heatmap")
                    if ($ValidChartTypes -notcontains $Section.chart_type) {
                        Write-Error "Type de graphique invalide: $($Section.chart_type). Valeurs valides: $($ValidChartTypes -join ', ')"
                        return $false
                    }
                    
                    # VÃƒÂ©rifier la mÃƒÂ©trique ou les mÃƒÂ©triques
                    if (-not ((Get-Member -InputObject $Section -Name "metric" -MemberType Properties) -or 
                              (Get-Member -InputObject $Section -Name "metrics" -MemberType Properties))) {
                        Write-Error "La section de type 'chart' doit contenir le champ 'metric' ou 'metrics'"
                        return $false
                    }
                }
                "anomalies" {
                    if (-not (Get-Member -InputObject $Section -Name "metrics" -MemberType Properties) -or 
                        $Section.metrics -isnot [array] -or 
                        $Section.metrics.Count -eq 0) {
                        Write-Error "La section de type 'anomalies' doit contenir un tableau 'metrics' non vide"
                        return $false
                    }
                    
                    if (-not (Get-Member -InputObject $Section -Name "threshold" -MemberType Properties)) {
                        Write-Error "La section de type 'anomalies' doit contenir le champ 'threshold'"
                        return $false
                    }
                }
                "recommendations" {
                    if (-not (Get-Member -InputObject $Section -Name "based_on" -MemberType Properties) -or 
                        $Section.based_on -isnot [array] -or 
                        $Section.based_on.Count -eq 0) {
                        Write-Error "La section de type 'recommendations' doit contenir un tableau 'based_on' non vide"
                        return $false
                    }
                }
            }
        }
        
        Write-Verbose "Le template '$($Template.id)' est valide"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la validation du template: $_"
        return $false
    }
}

<#
.SYNOPSIS
    RÃƒÂ©cupÃƒÂ¨re un template de rapport spÃƒÂ©cifique par son ID.
.DESCRIPTION
    Cette fonction rÃƒÂ©cupÃƒÂ¨re un template de rapport spÃƒÂ©cifique par son ID
    ÃƒÂ  partir des templates chargÃƒÂ©s.
.PARAMETER TemplateId
    L'ID du template ÃƒÂ  rÃƒÂ©cupÃƒÂ©rer.
.PARAMETER TemplatesPath
    Chemin vers le fichier JSON contenant les templates de rapports.
.EXAMPLE
    $Template = Get-ReportTemplate -TemplateId "system_performance_report"
.OUTPUTS
    System.Object - Le template de rapport correspondant ÃƒÂ  l'ID spÃƒÂ©cifiÃƒÂ©.
#>
function Get-ReportTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TemplateId,
        
        [Parameter(Mandatory=$false)]
        [string]$TemplatesPath = $script:DefaultTemplatesPath
    )
    
    try {
        # Charger les templates
        $Templates = Import-ReportTemplates -TemplatesPath $TemplatesPath
        
        if ($null -eq $Templates) {
            Write-Error "Impossible de charger les templates"
            return $null
        }
        
        # Rechercher le template par ID
        $Template = $Templates | Where-Object { $_.id -eq $TemplateId } | Select-Object -First 1
        
        if ($null -eq $Template) {
            Write-Error "Aucun template trouvÃƒÂ© avec l'ID: $TemplateId"
            return $null
        }
        
        # Valider le template
        $IsValid = Test-ReportTemplate -Template $Template
        
        if (-not $IsValid) {
            Write-Error "Le template avec l'ID '$TemplateId' n'est pas valide"
            return $null
        }
        
        Write-Verbose "Template '$TemplateId' rÃƒÂ©cupÃƒÂ©rÃƒÂ© avec succÃƒÂ¨s"
        return $Template
    }
    catch {
        Write-Error "Erreur lors de la rÃƒÂ©cupÃƒÂ©ration du template: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Liste tous les templates de rapports disponibles.
.DESCRIPTION
    Cette fonction liste tous les templates de rapports disponibles
    avec leurs informations de base.
.PARAMETER TemplatesPath
    Chemin vers le fichier JSON contenant les templates de rapports.
.PARAMETER Type
    Filtre les templates par type (system, application, business).
.EXAMPLE
    $TemplatesList = Get-ReportTemplatesList -Type "system"
.OUTPUTS
    System.Object[] - Liste des templates de rapports disponibles.
#>
function Get-ReportTemplatesList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false)]
        [string]$TemplatesPath = $script:DefaultTemplatesPath,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("system", "application", "business")]
        [string]$Type
    )
    
    try {
        # Charger les templates
        $Templates = Import-ReportTemplates -TemplatesPath $TemplatesPath
        
        if ($null -eq $Templates) {
            Write-Error "Impossible de charger les templates"
            return $null
        }
        
        # Filtrer par type si spÃƒÂ©cifiÃƒÂ©
        if (-not [string]::IsNullOrEmpty($Type)) {
            $Templates = $Templates | Where-Object { $_.type -eq $Type }
        }
        
        # CrÃƒÂ©er une liste simplifiÃƒÂ©e
        $TemplatesList = $Templates | ForEach-Object {
            [PSCustomObject]@{
                Id = $_.id
                Name = $_.name
                Description = $_.description
                Type = $_.type
                Format = $_.format
                SectionsCount = $_.sections.Count
            }
        }
        
        Write-Verbose "Liste des templates rÃƒÂ©cupÃƒÂ©rÃƒÂ©e avec succÃƒÂ¨s: $($TemplatesList.Count) templates"
        return $TemplatesList
    }
    catch {
        Write-Error "Erreur lors de la rÃƒÂ©cupÃƒÂ©ration de la liste des templates: $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Import-ReportTemplates, Test-ReportTemplate, Get-ReportTemplate, Get-ReportTemplatesList

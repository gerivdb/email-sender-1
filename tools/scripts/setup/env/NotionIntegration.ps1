# Script d'intÃ©gration avec Notion

# Configuration de l'intÃ©gration Notion
$script:NotionConfig = @{
    # ClÃ© d'API Notion
    ApiKey = ""
    
    # URL de base de l'API Notion
    BaseUrl = "https://api.notion.com/v1"
    
    # Version de l'API Notion
    ApiVersion = "2022-06-28"
    
    # ID de la base de donnÃ©es pour les erreurs
    ErrorDatabaseId = ""
    
    # ID de la base de donnÃ©es pour les rapports
    ReportDatabaseId = ""
    
    # Mappage des propriÃ©tÃ©s
    PropertyMapping = @{
        Error = @{
            Title = "Titre"
            Severity = "SÃ©vÃ©ritÃ©"
            Category = "CatÃ©gorie"
            Source = "Source"
            Timestamp = "Date"
            Status = "Statut"
            Description = "Description"
            Solution = "Solution"
            ScriptPath = "Chemin du script"
            LineNumber = "NumÃ©ro de ligne"
        }
        Report = @{
            Title = "Titre"
            Date = "Date"
            Summary = "RÃ©sumÃ©"
            Details = "DÃ©tails"
            Status = "Statut"
            Source = "Source"
        }
    }
}

# Fonction pour initialiser la configuration Notion
function Initialize-NotionIntegration {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorDatabaseId = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ReportDatabaseId = ""
    )
    
    # Charger la configuration depuis un fichier si spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($ConfigPath) -and (Test-Path -Path $ConfigPath)) {
        try {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            
            # Mettre Ã  jour la clÃ© d'API
            if ($config.ApiKey) {
                $script:NotionConfig.ApiKey = $config.ApiKey
            }
            
            # Mettre Ã  jour l'URL de base
            if ($config.BaseUrl) {
                $script:NotionConfig.BaseUrl = $config.BaseUrl
            }
            
            # Mettre Ã  jour la version de l'API
            if ($config.ApiVersion) {
                $script:NotionConfig.ApiVersion = $config.ApiVersion
            }
            
            # Mettre Ã  jour les IDs de base de donnÃ©es
            if ($config.ErrorDatabaseId) {
                $script:NotionConfig.ErrorDatabaseId = $config.ErrorDatabaseId
            }
            
            if ($config.ReportDatabaseId) {
                $script:NotionConfig.ReportDatabaseId = $config.ReportDatabaseId
            }
            
            # Mettre Ã  jour le mappage des propriÃ©tÃ©s
            if ($config.PropertyMapping) {
                $script:NotionConfig.PropertyMapping = $config.PropertyMapping
            }
            
            Write-Verbose "Configuration Notion chargÃ©e depuis $ConfigPath"
        }
        catch {
            Write-Error "Erreur lors du chargement de la configuration Notion: $_"
        }
    }
    
    # Mettre Ã  jour la clÃ© d'API si spÃ©cifiÃ©e
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $script:NotionConfig.ApiKey = $ApiKey
    }
    
    # Mettre Ã  jour l'ID de la base de donnÃ©es des erreurs si spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($ErrorDatabaseId)) {
        $script:NotionConfig.ErrorDatabaseId = $ErrorDatabaseId
    }
    
    # Mettre Ã  jour l'ID de la base de donnÃ©es des rapports si spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($ReportDatabaseId)) {
        $script:NotionConfig.ReportDatabaseId = $ReportDatabaseId
    }
    
    # VÃ©rifier si la clÃ© d'API est dÃ©finie
    if ([string]::IsNullOrEmpty($script:NotionConfig.ApiKey)) {
        Write-Warning "La clÃ© d'API Notion n'est pas dÃ©finie"
        return $false
    }
    
    # Tester la connexion Ã  Notion
    $connected = Test-NotionConnection
    
    if ($connected) {
        Write-Verbose "Connexion Ã  Notion Ã©tablie avec succÃ¨s"
        
        # VÃ©rifier les bases de donnÃ©es
        if (-not [string]::IsNullOrEmpty($script:NotionConfig.ErrorDatabaseId)) {
            $errorDatabase = Get-NotionDatabase -DatabaseId $script:NotionConfig.ErrorDatabaseId
            
            if ($errorDatabase) {
                Write-Verbose "Base de donnÃ©es des erreurs Notion vÃ©rifiÃ©e avec succÃ¨s"
            }
            else {
                Write-Warning "La base de donnÃ©es des erreurs Notion n'a pas pu Ãªtre vÃ©rifiÃ©e"
            }
        }
        
        if (-not [string]::IsNullOrEmpty($script:NotionConfig.ReportDatabaseId)) {
            $reportDatabase = Get-NotionDatabase -DatabaseId $script:NotionConfig.ReportDatabaseId
            
            if ($reportDatabase) {
                Write-Verbose "Base de donnÃ©es des rapports Notion vÃ©rifiÃ©e avec succÃ¨s"
            }
            else {
                Write-Warning "La base de donnÃ©es des rapports Notion n'a pas pu Ãªtre vÃ©rifiÃ©e"
            }
        }
    }
    
    return $script:NotionConfig
}

# Fonction pour tester la connexion Ã  Notion
function Test-NotionConnection {
    try {
        $response = Invoke-NotionApiRequest -Endpoint "/users/me"
        
        if ($response.object -eq "user") {
            return $true
        }
        else {
            Write-Warning "La connexion Ã  Notion a Ã©chouÃ©"
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors du test de connexion Ã  Notion: $_"
        return $false
    }
}

# Fonction pour effectuer une requÃªte Ã  l'API Notion
function Invoke-NotionApiRequest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("GET", "POST", "PATCH", "DELETE")]
        [string]$Method = "GET",
        
        [Parameter(Mandatory = $false)]
        [object]$Body = $null
    )
    
    # VÃ©rifier si la clÃ© d'API est dÃ©finie
    if ([string]::IsNullOrEmpty($script:NotionConfig.ApiKey)) {
        throw "La clÃ© d'API Notion n'est pas dÃ©finie"
    }
    
    # Construire l'URL complÃ¨te
    $url = "$($script:NotionConfig.BaseUrl)$Endpoint"
    
    # PrÃ©parer les en-tÃªtes
    $headers = @{
        "Authorization" = "Bearer $($script:NotionConfig.ApiKey)"
        "Notion-Version" = $script:NotionConfig.ApiVersion
        "Content-Type" = "application/json"
    }
    
    # ParamÃ¨tres de la requÃªte
    $params = @{
        Uri = $url
        Method = $Method
        Headers = $headers
    }
    
    # Ajouter le corps si spÃ©cifiÃ©
    if ($null -ne $Body) {
        $params.Body = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 10 }
    }
    
    # Effectuer la requÃªte
    try {
        $response = Invoke-RestMethod @params -ErrorAction Stop
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $statusDescription = $_.Exception.Response.StatusDescription
        
        Write-Error "Erreur lors de la requÃªte Ã  l'API Notion: $Method $url - Code d'Ã©tat: $statusCode - Description: $statusDescription"
        throw $_
    }
}

# Fonction pour rÃ©cupÃ©rer une base de donnÃ©es Notion
function Get-NotionDatabase {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DatabaseId
    )
    
    try {
        $response = Invoke-NotionApiRequest -Endpoint "/databases/$DatabaseId"
        return $response
    }
    catch {
        Write-Error "Erreur lors de la rÃ©cupÃ©ration de la base de donnÃ©es Notion: $_"
        return $null
    }
}

# Fonction pour crÃ©er une page dans une base de donnÃ©es Notion
function New-NotionPage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DatabaseId,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Properties,
        
        [Parameter(Mandatory = $false)]
        [object]$Content = $null
    )
    
    # PrÃ©parer le corps de la requÃªte
    $body = @{
        parent = @{
            database_id = $DatabaseId
        }
        properties = $Properties
    }
    
    # Ajouter le contenu si spÃ©cifiÃ©
    if ($null -ne $Content) {
        $body.children = $Content
    }
    
    try {
        $response = Invoke-NotionApiRequest -Endpoint "/pages" -Method "POST" -Body $body
        return $response
    }
    catch {
        Write-Error "Erreur lors de la crÃ©ation de la page Notion: $_"
        return $null
    }
}

# Fonction pour mettre Ã  jour une page Notion
function Update-NotionPage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PageId,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Properties,
        
        [Parameter(Mandatory = $false)]
        [object]$Content = $null
    )
    
    # Mettre Ã  jour les propriÃ©tÃ©s
    try {
        $propertiesResponse = Invoke-NotionApiRequest -Endpoint "/pages/$PageId" -Method "PATCH" -Body @{
            properties = $Properties
        }
        
        # Mettre Ã  jour le contenu si spÃ©cifiÃ©
        if ($null -ne $Content) {
            $contentResponse = Invoke-NotionApiRequest -Endpoint "/blocks/$PageId/children" -Method "PATCH" -Body @{
                children = $Content
            }
        }
        
        return $propertiesResponse
    }
    catch {
        Write-Error "Erreur lors de la mise Ã  jour de la page Notion: $_"
        return $null
    }
}

# Fonction pour rechercher des pages dans une base de donnÃ©es Notion
function Search-NotionDatabase {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DatabaseId,
        
        [Parameter(Mandatory = $false)]
        [object]$Filter = $null,
        
        [Parameter(Mandatory = $false)]
        [object]$Sorts = $null,
        
        [Parameter(Mandatory = $false)]
        [int]$PageSize = 100,
        
        [Parameter(Mandatory = $false)]
        [string]$StartCursor = $null
    )
    
    # PrÃ©parer le corps de la requÃªte
    $body = @{
        filter = @{
            property = "object"
            value = "page"
        }
        page_size = $PageSize
    }
    
    # Ajouter le filtre de base de donnÃ©es
    $body.filter = @{
        and = @(
            @{
                property = "parent"
                database_id = @{
                    equals = $DatabaseId
                }
            }
        )
    }
    
    # Ajouter le filtre personnalisÃ© si spÃ©cifiÃ©
    if ($null -ne $Filter) {
        $body.filter.and += $Filter
    }
    
    # Ajouter le tri si spÃ©cifiÃ©
    if ($null -ne $Sorts) {
        $body.sorts = $Sorts
    }
    
    # Ajouter le curseur de dÃ©part si spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($StartCursor)) {
        $body.start_cursor = $StartCursor
    }
    
    try {
        $response = Invoke-NotionApiRequest -Endpoint "/databases/$DatabaseId/query" -Method "POST" -Body $body
        return $response
    }
    catch {
        Write-Error "Erreur lors de la recherche dans la base de donnÃ©es Notion: $_"
        return $null
    }
}

# Fonction pour crÃ©er une entrÃ©e d'erreur dans Notion
function New-NotionErrorEntry {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Error,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "PowerShell",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # VÃ©rifier si la base de donnÃ©es des erreurs est configurÃ©e
    if ([string]::IsNullOrEmpty($script:NotionConfig.ErrorDatabaseId)) {
        Write-Error "La base de donnÃ©es des erreurs Notion n'est pas configurÃ©e"
        return $null
    }
    
    # PrÃ©parer les propriÃ©tÃ©s
    $properties = @{}
    
    # Titre
    $title = if ($Error.RuleName) { $Error.RuleName } else { $Error.Description }
    $properties[$script:NotionConfig.PropertyMapping.Error.Title] = @{
        title = @(
            @{
                text = @{
                    content = $title
                }
            }
        )
    }
    
    # SÃ©vÃ©ritÃ©
    $properties[$script:NotionConfig.PropertyMapping.Error.Severity] = @{
        select = @{
            name = $Error.Severity
        }
    }
    
    # CatÃ©gorie
    if ($Error.Category) {
        $properties[$script:NotionConfig.PropertyMapping.Error.Category] = @{
            select = @{
                name = $Error.Category
            }
        }
    }
    
    # Source
    $properties[$script:NotionConfig.PropertyMapping.Error.Source] = @{
        select = @{
            name = $Source
        }
    }
    
    # Date
    $properties[$script:NotionConfig.PropertyMapping.Error.Timestamp] = @{
        date = @{
            start = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        }
    }
    
    # Statut
    $properties[$script:NotionConfig.PropertyMapping.Error.Status] = @{
        status = @{
            name = "Nouveau"
        }
    }
    
    # Description
    $description = if ($Error.Message) { $Error.Message } else { $Error.Description }
    $properties[$script:NotionConfig.PropertyMapping.Error.Description] = @{
        rich_text = @(
            @{
                text = @{
                    content = $description
                }
            }
        )
    }
    
    # Solution
    if ($Error.Suggestion) {
        $properties[$script:NotionConfig.PropertyMapping.Error.Solution] = @{
            rich_text = @(
                @{
                    text = @{
                        content = $Error.Suggestion
                    }
                }
            )
        }
    }
    
    # Chemin du script
    if ($Error.ScriptPath) {
        $properties[$script:NotionConfig.PropertyMapping.Error.ScriptPath] = @{
            rich_text = @(
                @{
                    text = @{
                        content = $Error.ScriptPath
                    }
                }
            )
        }
    }
    
    # NumÃ©ro de ligne
    if ($Error.Line -or $Error.LineNumber) {
        $lineNumber = if ($Error.Line) { $Error.Line } else { $Error.LineNumber }
        $properties[$script:NotionConfig.PropertyMapping.Error.LineNumber] = @{
            number = $lineNumber
        }
    }
    
    # PrÃ©parer le contenu
    $content = @(
        @{
            object = "block"
            type = "heading_2"
            heading_2 = @{
                rich_text = @(
                    @{
                        text = @{
                            content = "DÃ©tails de l'erreur"
                        }
                    }
                )
            }
        },
        @{
            object = "block"
            type = "paragraph"
            paragraph = @{
                rich_text = @(
                    @{
                        text = @{
                            content = "Source: $Source"
                        }
                    }
                )
            }
        }
    )
    
    # Ajouter les mÃ©tadonnÃ©es
    if ($Metadata.Count -gt 0) {
        $content += @{
            object = "block"
            type = "heading_3"
            heading_3 = @{
                rich_text = @(
                    @{
                        text = @{
                            content = "MÃ©tadonnÃ©es"
                        }
                    }
                )
            }
        }
        
        foreach ($key in $Metadata.Keys) {
            $content += @{
                object = "block"
                type = "paragraph"
                paragraph = @{
                    rich_text = @(
                        @{
                            text = @{
                                content = "$key: $($Metadata[$key])"
                            }
                        }
                    )
                }
            }
        }
    }
    
    # CrÃ©er la page
    $page = New-NotionPage -DatabaseId $script:NotionConfig.ErrorDatabaseId -Properties $properties -Content $content
    
    return $page
}

# Fonction pour crÃ©er un rapport d'erreur dans Notion
function New-NotionErrorReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Summary,
        
        [Parameter(Mandatory = $true)]
        [object[]]$Errors,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "PowerShell",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # VÃ©rifier si la base de donnÃ©es des rapports est configurÃ©e
    if ([string]::IsNullOrEmpty($script:NotionConfig.ReportDatabaseId)) {
        Write-Error "La base de donnÃ©es des rapports Notion n'est pas configurÃ©e"
        return $null
    }
    
    # PrÃ©parer les propriÃ©tÃ©s
    $properties = @{}
    
    # Titre
    $properties[$script:NotionConfig.PropertyMapping.Report.Title] = @{
        title = @(
            @{
                text = @{
                    content = $Title
                }
            }
        )
    }
    
    # Date
    $properties[$script:NotionConfig.PropertyMapping.Report.Date] = @{
        date = @{
            start = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ")
        }
    }
    
    # RÃ©sumÃ©
    $properties[$script:NotionConfig.PropertyMapping.Report.Summary] = @{
        rich_text = @(
            @{
                text = @{
                    content = $Summary
                }
            }
        )
    }
    
    # Statut
    $properties[$script:NotionConfig.PropertyMapping.Report.Status] = @{
        status = @{
            name = "Nouveau"
        }
    }
    
    # Source
    $properties[$script:NotionConfig.PropertyMapping.Report.Source] = @{
        select = @{
            name = $Source
        }
    }
    
    # PrÃ©parer le contenu
    $content = @(
        @{
            object = "block"
            type = "heading_2"
            heading_2 = @{
                rich_text = @(
                    @{
                        text = @{
                            content = "RÃ©sumÃ©"
                        }
                    }
                )
            }
        },
        @{
            object = "block"
            type = "paragraph"
            paragraph = @{
                rich_text = @(
                    @{
                        text = @{
                            content = $Summary
                        }
                    }
                )
            }
        },
        @{
            object = "block"
            type = "heading_2"
            heading_2 = @{
                rich_text = @(
                    @{
                        text = @{
                            content = "Erreurs dÃ©tectÃ©es"
                        }
                    }
                )
            }
        }
    )
    
    # Ajouter les erreurs
    foreach ($error in $Errors) {
        $errorTitle = if ($error.RuleName) { $error.RuleName } else { $error.Description }
        $errorDescription = if ($error.Message) { $error.Message } else { $error.Description }
        $errorSeverity = $error.Severity
        
        $content += @{
            object = "block"
            type = "heading_3"
            heading_3 = @{
                rich_text = @(
                    @{
                        text = @{
                            content = $errorTitle
                        }
                    }
                )
            }
        }
        
        $content += @{
            object = "block"
            type = "paragraph"
            paragraph = @{
                rich_text = @(
                    @{
                        text = @{
                            content = "SÃ©vÃ©ritÃ©: $errorSeverity"
                        }
                    }
                )
            }
        }
        
        $content += @{
            object = "block"
            type = "paragraph"
            paragraph = @{
                rich_text = @(
                    @{
                        text = @{
                            content = "Description: $errorDescription"
                        }
                    }
                )
            }
        }
        
        if ($error.ScriptPath) {
            $content += @{
                object = "block"
                type = "paragraph"
                paragraph = @{
                    rich_text = @(
                        @{
                            text = @{
                                content = "Fichier: $($error.ScriptPath)"
                            }
                        }
                    )
                }
            }
        }
        
        if ($error.Line -or $error.LineNumber) {
            $lineNumber = if ($error.Line) { $error.Line } else { $error.LineNumber }
            $content += @{
                object = "block"
                type = "paragraph"
                paragraph = @{
                    rich_text = @(
                        @{
                            text = @{
                                content = "Ligne: $lineNumber"
                            }
                        }
                    )
                }
            }
        }
        
        if ($error.Suggestion) {
            $content += @{
                object = "block"
                type = "paragraph"
                paragraph = @{
                    rich_text = @(
                        @{
                            text = @{
                                content = "Suggestion: $($error.Suggestion)"
                            }
                        }
                    )
                }
            }
        }
    }
    
    # Ajouter les mÃ©tadonnÃ©es
    if ($Metadata.Count -gt 0) {
        $content += @{
            object = "block"
            type = "heading_2"
            heading_2 = @{
                rich_text = @(
                    @{
                        text = @{
                            content = "MÃ©tadonnÃ©es"
                        }
                    }
                )
            }
        }
        
        foreach ($key in $Metadata.Keys) {
            $content += @{
                object = "block"
                type = "paragraph"
                paragraph = @{
                    rich_text = @(
                        @{
                            text = @{
                                content = "$key: $($Metadata[$key])"
                            }
                        }
                    )
                }
            }
        }
    }
    
    # CrÃ©er la page
    $page = New-NotionPage -DatabaseId $script:NotionConfig.ReportDatabaseId -Properties $properties -Content $content
    
    return $page
}

# Fonction pour configurer l'intÃ©gration Notion
function Set-NotionConfiguration {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorDatabaseId = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ReportDatabaseId = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$PropertyMapping = @{}
    )
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $script:NotionConfig.ApiKey = $ApiKey
    }
    
    if (-not [string]::IsNullOrEmpty($ErrorDatabaseId)) {
        $script:NotionConfig.ErrorDatabaseId = $ErrorDatabaseId
    }
    
    if (-not [string]::IsNullOrEmpty($ReportDatabaseId)) {
        $script:NotionConfig.ReportDatabaseId = $ReportDatabaseId
    }
    
    if ($PropertyMapping.Count -gt 0) {
        $script:NotionConfig.PropertyMapping = $PropertyMapping
    }
    
    return $script:NotionConfig
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-NotionIntegration, Test-NotionConnection, Invoke-NotionApiRequest
Export-ModuleMember -Function Get-NotionDatabase, New-NotionPage, Update-NotionPage, Search-NotionDatabase
Export-ModuleMember -Function New-NotionErrorEntry, New-NotionErrorReport, Set-NotionConfiguration

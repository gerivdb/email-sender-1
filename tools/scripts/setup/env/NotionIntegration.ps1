# Script d'intégration avec Notion

# Configuration de l'intégration Notion
$script:NotionConfig = @{
    # Clé d'API Notion
    ApiKey = ""
    
    # URL de base de l'API Notion
    BaseUrl = "https://api.notion.com/v1"
    
    # Version de l'API Notion
    ApiVersion = "2022-06-28"
    
    # ID de la base de données pour les erreurs
    ErrorDatabaseId = ""
    
    # ID de la base de données pour les rapports
    ReportDatabaseId = ""
    
    # Mappage des propriétés
    PropertyMapping = @{
        Error = @{
            Title = "Titre"
            Severity = "Sévérité"
            Category = "Catégorie"
            Source = "Source"
            Timestamp = "Date"
            Status = "Statut"
            Description = "Description"
            Solution = "Solution"
            ScriptPath = "Chemin du script"
            LineNumber = "Numéro de ligne"
        }
        Report = @{
            Title = "Titre"
            Date = "Date"
            Summary = "Résumé"
            Details = "Détails"
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
    
    # Charger la configuration depuis un fichier si spécifié
    if (-not [string]::IsNullOrEmpty($ConfigPath) -and (Test-Path -Path $ConfigPath)) {
        try {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            
            # Mettre à jour la clé d'API
            if ($config.ApiKey) {
                $script:NotionConfig.ApiKey = $config.ApiKey
            }
            
            # Mettre à jour l'URL de base
            if ($config.BaseUrl) {
                $script:NotionConfig.BaseUrl = $config.BaseUrl
            }
            
            # Mettre à jour la version de l'API
            if ($config.ApiVersion) {
                $script:NotionConfig.ApiVersion = $config.ApiVersion
            }
            
            # Mettre à jour les IDs de base de données
            if ($config.ErrorDatabaseId) {
                $script:NotionConfig.ErrorDatabaseId = $config.ErrorDatabaseId
            }
            
            if ($config.ReportDatabaseId) {
                $script:NotionConfig.ReportDatabaseId = $config.ReportDatabaseId
            }
            
            # Mettre à jour le mappage des propriétés
            if ($config.PropertyMapping) {
                $script:NotionConfig.PropertyMapping = $config.PropertyMapping
            }
            
            Write-Verbose "Configuration Notion chargée depuis $ConfigPath"
        }
        catch {
            Write-Error "Erreur lors du chargement de la configuration Notion: $_"
        }
    }
    
    # Mettre à jour la clé d'API si spécifiée
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $script:NotionConfig.ApiKey = $ApiKey
    }
    
    # Mettre à jour l'ID de la base de données des erreurs si spécifié
    if (-not [string]::IsNullOrEmpty($ErrorDatabaseId)) {
        $script:NotionConfig.ErrorDatabaseId = $ErrorDatabaseId
    }
    
    # Mettre à jour l'ID de la base de données des rapports si spécifié
    if (-not [string]::IsNullOrEmpty($ReportDatabaseId)) {
        $script:NotionConfig.ReportDatabaseId = $ReportDatabaseId
    }
    
    # Vérifier si la clé d'API est définie
    if ([string]::IsNullOrEmpty($script:NotionConfig.ApiKey)) {
        Write-Warning "La clé d'API Notion n'est pas définie"
        return $false
    }
    
    # Tester la connexion à Notion
    $connected = Test-NotionConnection
    
    if ($connected) {
        Write-Verbose "Connexion à Notion établie avec succès"
        
        # Vérifier les bases de données
        if (-not [string]::IsNullOrEmpty($script:NotionConfig.ErrorDatabaseId)) {
            $errorDatabase = Get-NotionDatabase -DatabaseId $script:NotionConfig.ErrorDatabaseId
            
            if ($errorDatabase) {
                Write-Verbose "Base de données des erreurs Notion vérifiée avec succès"
            }
            else {
                Write-Warning "La base de données des erreurs Notion n'a pas pu être vérifiée"
            }
        }
        
        if (-not [string]::IsNullOrEmpty($script:NotionConfig.ReportDatabaseId)) {
            $reportDatabase = Get-NotionDatabase -DatabaseId $script:NotionConfig.ReportDatabaseId
            
            if ($reportDatabase) {
                Write-Verbose "Base de données des rapports Notion vérifiée avec succès"
            }
            else {
                Write-Warning "La base de données des rapports Notion n'a pas pu être vérifiée"
            }
        }
    }
    
    return $script:NotionConfig
}

# Fonction pour tester la connexion à Notion
function Test-NotionConnection {
    try {
        $response = Invoke-NotionApiRequest -Endpoint "/users/me"
        
        if ($response.object -eq "user") {
            return $true
        }
        else {
            Write-Warning "La connexion à Notion a échoué"
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors du test de connexion à Notion: $_"
        return $false
    }
}

# Fonction pour effectuer une requête à l'API Notion
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
    
    # Vérifier si la clé d'API est définie
    if ([string]::IsNullOrEmpty($script:NotionConfig.ApiKey)) {
        throw "La clé d'API Notion n'est pas définie"
    }
    
    # Construire l'URL complète
    $url = "$($script:NotionConfig.BaseUrl)$Endpoint"
    
    # Préparer les en-têtes
    $headers = @{
        "Authorization" = "Bearer $($script:NotionConfig.ApiKey)"
        "Notion-Version" = $script:NotionConfig.ApiVersion
        "Content-Type" = "application/json"
    }
    
    # Paramètres de la requête
    $params = @{
        Uri = $url
        Method = $Method
        Headers = $headers
    }
    
    # Ajouter le corps si spécifié
    if ($null -ne $Body) {
        $params.Body = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 10 }
    }
    
    # Effectuer la requête
    try {
        $response = Invoke-RestMethod @params -ErrorAction Stop
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__
        $statusDescription = $_.Exception.Response.StatusDescription
        
        Write-Error "Erreur lors de la requête à l'API Notion: $Method $url - Code d'état: $statusCode - Description: $statusDescription"
        throw $_
    }
}

# Fonction pour récupérer une base de données Notion
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
        Write-Error "Erreur lors de la récupération de la base de données Notion: $_"
        return $null
    }
}

# Fonction pour créer une page dans une base de données Notion
function New-NotionPage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DatabaseId,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Properties,
        
        [Parameter(Mandatory = $false)]
        [object]$Content = $null
    )
    
    # Préparer le corps de la requête
    $body = @{
        parent = @{
            database_id = $DatabaseId
        }
        properties = $Properties
    }
    
    # Ajouter le contenu si spécifié
    if ($null -ne $Content) {
        $body.children = $Content
    }
    
    try {
        $response = Invoke-NotionApiRequest -Endpoint "/pages" -Method "POST" -Body $body
        return $response
    }
    catch {
        Write-Error "Erreur lors de la création de la page Notion: $_"
        return $null
    }
}

# Fonction pour mettre à jour une page Notion
function Update-NotionPage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PageId,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Properties,
        
        [Parameter(Mandatory = $false)]
        [object]$Content = $null
    )
    
    # Mettre à jour les propriétés
    try {
        $propertiesResponse = Invoke-NotionApiRequest -Endpoint "/pages/$PageId" -Method "PATCH" -Body @{
            properties = $Properties
        }
        
        # Mettre à jour le contenu si spécifié
        if ($null -ne $Content) {
            $contentResponse = Invoke-NotionApiRequest -Endpoint "/blocks/$PageId/children" -Method "PATCH" -Body @{
                children = $Content
            }
        }
        
        return $propertiesResponse
    }
    catch {
        Write-Error "Erreur lors de la mise à jour de la page Notion: $_"
        return $null
    }
}

# Fonction pour rechercher des pages dans une base de données Notion
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
    
    # Préparer le corps de la requête
    $body = @{
        filter = @{
            property = "object"
            value = "page"
        }
        page_size = $PageSize
    }
    
    # Ajouter le filtre de base de données
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
    
    # Ajouter le filtre personnalisé si spécifié
    if ($null -ne $Filter) {
        $body.filter.and += $Filter
    }
    
    # Ajouter le tri si spécifié
    if ($null -ne $Sorts) {
        $body.sorts = $Sorts
    }
    
    # Ajouter le curseur de départ si spécifié
    if (-not [string]::IsNullOrEmpty($StartCursor)) {
        $body.start_cursor = $StartCursor
    }
    
    try {
        $response = Invoke-NotionApiRequest -Endpoint "/databases/$DatabaseId/query" -Method "POST" -Body $body
        return $response
    }
    catch {
        Write-Error "Erreur lors de la recherche dans la base de données Notion: $_"
        return $null
    }
}

# Fonction pour créer une entrée d'erreur dans Notion
function New-NotionErrorEntry {
    param (
        [Parameter(Mandatory = $true)]
        [object]$Error,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "PowerShell",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Vérifier si la base de données des erreurs est configurée
    if ([string]::IsNullOrEmpty($script:NotionConfig.ErrorDatabaseId)) {
        Write-Error "La base de données des erreurs Notion n'est pas configurée"
        return $null
    }
    
    # Préparer les propriétés
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
    
    # Sévérité
    $properties[$script:NotionConfig.PropertyMapping.Error.Severity] = @{
        select = @{
            name = $Error.Severity
        }
    }
    
    # Catégorie
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
    
    # Numéro de ligne
    if ($Error.Line -or $Error.LineNumber) {
        $lineNumber = if ($Error.Line) { $Error.Line } else { $Error.LineNumber }
        $properties[$script:NotionConfig.PropertyMapping.Error.LineNumber] = @{
            number = $lineNumber
        }
    }
    
    # Préparer le contenu
    $content = @(
        @{
            object = "block"
            type = "heading_2"
            heading_2 = @{
                rich_text = @(
                    @{
                        text = @{
                            content = "Détails de l'erreur"
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
    
    # Ajouter les métadonnées
    if ($Metadata.Count -gt 0) {
        $content += @{
            object = "block"
            type = "heading_3"
            heading_3 = @{
                rich_text = @(
                    @{
                        text = @{
                            content = "Métadonnées"
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
    
    # Créer la page
    $page = New-NotionPage -DatabaseId $script:NotionConfig.ErrorDatabaseId -Properties $properties -Content $content
    
    return $page
}

# Fonction pour créer un rapport d'erreur dans Notion
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
    
    # Vérifier si la base de données des rapports est configurée
    if ([string]::IsNullOrEmpty($script:NotionConfig.ReportDatabaseId)) {
        Write-Error "La base de données des rapports Notion n'est pas configurée"
        return $null
    }
    
    # Préparer les propriétés
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
    
    # Résumé
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
    
    # Préparer le contenu
    $content = @(
        @{
            object = "block"
            type = "heading_2"
            heading_2 = @{
                rich_text = @(
                    @{
                        text = @{
                            content = "Résumé"
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
                            content = "Erreurs détectées"
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
                            content = "Sévérité: $errorSeverity"
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
    
    # Ajouter les métadonnées
    if ($Metadata.Count -gt 0) {
        $content += @{
            object = "block"
            type = "heading_2"
            heading_2 = @{
                rich_text = @(
                    @{
                        text = @{
                            content = "Métadonnées"
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
    
    # Créer la page
    $page = New-NotionPage -DatabaseId $script:NotionConfig.ReportDatabaseId -Properties $properties -Content $content
    
    return $page
}

# Fonction pour configurer l'intégration Notion
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

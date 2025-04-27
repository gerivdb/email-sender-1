# Script d'intÃ©gration avec n8n

# Configuration de l'intÃ©gration n8n
$script:N8nConfig = @{
    # URL de base de l'API n8n
    BaseUrl = "http://localhost:5678"
    
    # Informations d'authentification
    Auth = @{
        Type = "None"  # None, Basic, ApiKey, OAuth2
        Username = ""
        Password = ""
        ApiKey = ""
        ApiKeyHeader = "X-N8N-API-KEY"
        OAuthToken = ""
    }
    
    # Workflows
    Workflows = @{
        ErrorNotification = ""  # ID du workflow de notification d'erreur
        ErrorAnalysis = ""      # ID du workflow d'analyse d'erreur
        ErrorReporting = ""     # ID du workflow de rapport d'erreur
    }
    
    # Webhook URLs
    Webhooks = @{
        ErrorReport = ""        # URL du webhook pour les rapports d'erreur
        ErrorAlert = ""         # URL du webhook pour les alertes d'erreur
    }
}

# Fonction pour initialiser la configuration n8n
function Initialize-N8nIntegration {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$BaseUrl = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("None", "Basic", "ApiKey", "OAuth2")]
        [string]$AuthType = "None"
    )
    
    # Charger la configuration depuis un fichier si spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($ConfigPath) -and (Test-Path -Path $ConfigPath)) {
        try {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            
            # Mettre Ã  jour l'URL de base
            if ($config.BaseUrl) {
                $script:N8nConfig.BaseUrl = $config.BaseUrl
            }
            
            # Mettre Ã  jour l'authentification
            if ($config.Auth) {
                $script:N8nConfig.Auth.Type = $config.Auth.Type
                $script:N8nConfig.Auth.Username = $config.Auth.Username
                $script:N8nConfig.Auth.Password = $config.Auth.Password
                $script:N8nConfig.Auth.ApiKey = $config.Auth.ApiKey
                $script:N8nConfig.Auth.ApiKeyHeader = $config.Auth.ApiKeyHeader
                $script:N8nConfig.Auth.OAuthToken = $config.Auth.OAuthToken
            }
            
            # Mettre Ã  jour les workflows
            if ($config.Workflows) {
                $script:N8nConfig.Workflows.ErrorNotification = $config.Workflows.ErrorNotification
                $script:N8nConfig.Workflows.ErrorAnalysis = $config.Workflows.ErrorAnalysis
                $script:N8nConfig.Workflows.ErrorReporting = $config.Workflows.ErrorReporting
            }
            
            # Mettre Ã  jour les webhooks
            if ($config.Webhooks) {
                $script:N8nConfig.Webhooks.ErrorReport = $config.Webhooks.ErrorReport
                $script:N8nConfig.Webhooks.ErrorAlert = $config.Webhooks.ErrorAlert
            }
            
            Write-Verbose "Configuration n8n chargÃ©e depuis $ConfigPath"
        }
        catch {
            Write-Error "Erreur lors du chargement de la configuration n8n: $_"
        }
    }
    
    # Mettre Ã  jour l'URL de base si spÃ©cifiÃ©e
    if (-not [string]::IsNullOrEmpty($BaseUrl)) {
        $script:N8nConfig.BaseUrl = $BaseUrl
    }
    
    # Mettre Ã  jour le type d'authentification si spÃ©cifiÃ©
    if (-not [string]::IsNullOrEmpty($AuthType)) {
        $script:N8nConfig.Auth.Type = $AuthType
    }
    
    # Tester la connexion Ã  n8n
    $connected = Test-N8nConnection
    
    if ($connected) {
        Write-Verbose "Connexion Ã  n8n Ã©tablie avec succÃ¨s"
        
        # RÃ©cupÃ©rer les workflows disponibles
        $workflows = Get-N8nWorkflows
        
        if ($workflows) {
            Write-Verbose "Workflows n8n rÃ©cupÃ©rÃ©s avec succÃ¨s"
        }
    }
    
    return $script:N8nConfig
}

# Fonction pour tester la connexion Ã  n8n
function Test-N8nConnection {
    try {
        $response = Invoke-N8nApiRequest -Endpoint "/healthz"
        
        if ($response.StatusCode -eq 200) {
            return $true
        }
        else {
            Write-Warning "La connexion Ã  n8n a Ã©chouÃ© avec le code d'Ã©tat $($response.StatusCode)"
            return $false
        }
    }
    catch {
        Write-Error "Erreur lors du test de connexion Ã  n8n: $_"
        return $false
    }
}

# Fonction pour effectuer une requÃªte Ã  l'API n8n
function Invoke-N8nApiRequest {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]$Method = "GET",
        
        [Parameter(Mandatory = $false)]
        [object]$Body = $null,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{}
    )
    
    # Construire l'URL complÃ¨te
    $url = "$($script:N8nConfig.BaseUrl)$Endpoint"
    
    # Ajouter les en-tÃªtes d'authentification
    $authHeaders = @{}
    
    switch ($script:N8nConfig.Auth.Type) {
        "Basic" {
            $base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($script:N8nConfig.Auth.Username):$($script:N8nConfig.Auth.Password)"))
            $authHeaders["Authorization"] = "Basic $base64Auth"
        }
        "ApiKey" {
            $authHeaders[$script:N8nConfig.Auth.ApiKeyHeader] = $script:N8nConfig.Auth.ApiKey
        }
        "OAuth2" {
            $authHeaders["Authorization"] = "Bearer $($script:N8nConfig.Auth.OAuthToken)"
        }
    }
    
    # Fusionner les en-tÃªtes
    $allHeaders = $Headers + $authHeaders
    
    # ParamÃ¨tres de la requÃªte
    $params = @{
        Uri = $url
        Method = $Method
        Headers = $allHeaders
        ContentType = "application/json"
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
        
        Write-Error "Erreur lors de la requÃªte Ã  l'API n8n: $Method $url - Code d'Ã©tat: $statusCode - Description: $statusDescription"
        throw $_
    }
}

# Fonction pour rÃ©cupÃ©rer les workflows n8n
function Get-N8nWorkflows {
    try {
        $response = Invoke-N8nApiRequest -Endpoint "/workflows"
        return $response
    }
    catch {
        Write-Error "Erreur lors de la rÃ©cupÃ©ration des workflows n8n: $_"
        return $null
    }
}

# Fonction pour exÃ©cuter un workflow n8n
function Invoke-N8nWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        
        [Parameter(Mandatory = $false)]
        [object]$Data = $null
    )
    
    try {
        $endpoint = "/workflows/$WorkflowId/execute"
        $response = Invoke-N8nApiRequest -Endpoint $endpoint -Method "POST" -Body @{ data = $Data }
        return $response
    }
    catch {
        Write-Error "Erreur lors de l'exÃ©cution du workflow n8n: $_"
        return $null
    }
}

# Fonction pour envoyer un rapport d'erreur Ã  n8n
function Send-ErrorReportToN8n {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Errors,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "PowerShell",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # VÃ©rifier si un webhook ou un workflow est configurÃ©
    if ([string]::IsNullOrEmpty($script:N8nConfig.Webhooks.ErrorReport) -and [string]::IsNullOrEmpty($script:N8nConfig.Workflows.ErrorReporting)) {
        Write-Error "Aucun webhook ou workflow n'est configurÃ© pour les rapports d'erreur"
        return $false
    }
    
    # PrÃ©parer les donnÃ©es
    $data = @{
        errors = $Errors
        source = $Source
        timestamp = Get-Date -Format "o"
        metadata = $Metadata
    }
    
    # Envoyer au webhook si configurÃ©
    if (-not [string]::IsNullOrEmpty($script:N8nConfig.Webhooks.ErrorReport)) {
        try {
            $params = @{
                Uri = $script:N8nConfig.Webhooks.ErrorReport
                Method = "POST"
                Body = $data | ConvertTo-Json -Depth 10
                ContentType = "application/json"
            }
            
            $response = Invoke-RestMethod @params
            Write-Verbose "Rapport d'erreur envoyÃ© au webhook n8n"
            return $true
        }
        catch {
            Write-Error "Erreur lors de l'envoi du rapport d'erreur au webhook n8n: $_"
            
            # Essayer le workflow si disponible
            if (-not [string]::IsNullOrEmpty($script:N8nConfig.Workflows.ErrorReporting)) {
                return Invoke-N8nWorkflow -WorkflowId $script:N8nConfig.Workflows.ErrorReporting -Data $data
            }
            
            return $false
        }
    }
    # Sinon, exÃ©cuter le workflow
    else {
        return Invoke-N8nWorkflow -WorkflowId $script:N8nConfig.Workflows.ErrorReporting -Data $data
    }
}

# Fonction pour envoyer une alerte d'erreur Ã  n8n
function Send-ErrorAlertToN8n {
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Alerts,
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "PowerShell",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # VÃ©rifier si un webhook ou un workflow est configurÃ©
    if ([string]::IsNullOrEmpty($script:N8nConfig.Webhooks.ErrorAlert) -and [string]::IsNullOrEmpty($script:N8nConfig.Workflows.ErrorNotification)) {
        Write-Error "Aucun webhook ou workflow n'est configurÃ© pour les alertes d'erreur"
        return $false
    }
    
    # PrÃ©parer les donnÃ©es
    $data = @{
        alerts = $Alerts
        source = $Source
        timestamp = Get-Date -Format "o"
        metadata = $Metadata
    }
    
    # Envoyer au webhook si configurÃ©
    if (-not [string]::IsNullOrEmpty($script:N8nConfig.Webhooks.ErrorAlert)) {
        try {
            $params = @{
                Uri = $script:N8nConfig.Webhooks.ErrorAlert
                Method = "POST"
                Body = $data | ConvertTo-Json -Depth 10
                ContentType = "application/json"
            }
            
            $response = Invoke-RestMethod @params
            Write-Verbose "Alerte d'erreur envoyÃ©e au webhook n8n"
            return $true
        }
        catch {
            Write-Error "Erreur lors de l'envoi de l'alerte d'erreur au webhook n8n: $_"
            
            # Essayer le workflow si disponible
            if (-not [string]::IsNullOrEmpty($script:N8nConfig.Workflows.ErrorNotification)) {
                return Invoke-N8nWorkflow -WorkflowId $script:N8nConfig.Workflows.ErrorNotification -Data $data
            }
            
            return $false
        }
    }
    # Sinon, exÃ©cuter le workflow
    else {
        return Invoke-N8nWorkflow -WorkflowId $script:N8nConfig.Workflows.ErrorNotification -Data $data
    }
}

# Fonction pour configurer les webhooks n8n
function Set-N8nWebhooks {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ErrorReportWebhook = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorAlertWebhook = ""
    )
    
    if (-not [string]::IsNullOrEmpty($ErrorReportWebhook)) {
        $script:N8nConfig.Webhooks.ErrorReport = $ErrorReportWebhook
    }
    
    if (-not [string]::IsNullOrEmpty($ErrorAlertWebhook)) {
        $script:N8nConfig.Webhooks.ErrorAlert = $ErrorAlertWebhook
    }
    
    return $script:N8nConfig.Webhooks
}

# Fonction pour configurer les workflows n8n
function Set-N8nWorkflows {
    param (
        [Parameter(Mandatory = $false)]
        [string]$ErrorNotificationWorkflow = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorAnalysisWorkflow = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorReportingWorkflow = ""
    )
    
    if (-not [string]::IsNullOrEmpty($ErrorNotificationWorkflow)) {
        $script:N8nConfig.Workflows.ErrorNotification = $ErrorNotificationWorkflow
    }
    
    if (-not [string]::IsNullOrEmpty($ErrorAnalysisWorkflow)) {
        $script:N8nConfig.Workflows.ErrorAnalysis = $ErrorAnalysisWorkflow
    }
    
    if (-not [string]::IsNullOrEmpty($ErrorReportingWorkflow)) {
        $script:N8nConfig.Workflows.ErrorReporting = $ErrorReportingWorkflow
    }
    
    return $script:N8nConfig.Workflows
}

# Fonction pour configurer l'authentification n8n
function Set-N8nAuthentication {
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("None", "Basic", "ApiKey", "OAuth2")]
        [string]$Type,
        
        [Parameter(Mandatory = $false)]
        [string]$Username = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Password = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ApiKeyHeader = "X-N8N-API-KEY",
        
        [Parameter(Mandatory = $false)]
        [string]$OAuthToken = ""
    )
    
    $script:N8nConfig.Auth.Type = $Type
    
    if (-not [string]::IsNullOrEmpty($Username)) {
        $script:N8nConfig.Auth.Username = $Username
    }
    
    if (-not [string]::IsNullOrEmpty($Password)) {
        $script:N8nConfig.Auth.Password = $Password
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKey)) {
        $script:N8nConfig.Auth.ApiKey = $ApiKey
    }
    
    if (-not [string]::IsNullOrEmpty($ApiKeyHeader)) {
        $script:N8nConfig.Auth.ApiKeyHeader = $ApiKeyHeader
    }
    
    if (-not [string]::IsNullOrEmpty($OAuthToken)) {
        $script:N8nConfig.Auth.OAuthToken = $OAuthToken
    }
    
    return $script:N8nConfig.Auth
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-N8nIntegration, Test-N8nConnection, Invoke-N8nApiRequest
Export-ModuleMember -Function Get-N8nWorkflows, Invoke-N8nWorkflow
Export-ModuleMember -Function Send-ErrorReportToN8n, Send-ErrorAlertToN8n
Export-ModuleMember -Function Set-N8nWebhooks, Set-N8nWorkflows, Set-N8nAuthentication

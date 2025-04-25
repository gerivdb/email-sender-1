<#
.SYNOPSIS
    Module d'utilitaires API pour MCP

.DESCRIPTION
    Module d'utilitaires API pour MCP fournissant des fonctions pour interagir avec les API

.EXAMPLE
    Import-Module -Name MCPApiUtils
    Importe le module MCPApiUtils

.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>

# Variables globales
$script:ApiConfig = @{
    BaseUrl = "http://localhost:8000"
    Timeout = 30
    ApiKey = ""
    UserAgent = "MCP API Utils/1.0"
    EnableCompression = $true
}

<#
.SYNOPSIS
    Initialise la configuration API

.DESCRIPTION
    Initialise la configuration API avec les paramètres spécifiés

.PARAMETER BaseUrl
    URL de base de l'API

.PARAMETER Timeout
    Délai d'attente en secondes

.PARAMETER ApiKey
    Clé API pour l'authentification

.EXAMPLE
    Initialize-ApiConfig -BaseUrl "http://localhost:8000" -Timeout 30 -ApiKey "your-api-key"
    Initialise la configuration API avec les paramètres spécifiés

.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>
function Initialize-ApiConfig {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$false)]
        [string]$BaseUrl = "http://localhost:8000",
        
        [Parameter(Mandatory=$false)]
        [int]$Timeout = 30,
        
        [Parameter(Mandatory=$false)]
        [string]$ApiKey = ""
    )
    
    if ($PSCmdlet.ShouldProcess("API Config", "Initialize")) {
        $script:ApiConfig.BaseUrl = $BaseUrl
        $script:ApiConfig.Timeout = $Timeout
        $script:ApiConfig.ApiKey = $ApiKey
        
        Write-Verbose "Configuration API initialisée avec succès"
    }
}

<#
.SYNOPSIS
    Envoie une requête API

.DESCRIPTION
    Envoie une requête API avec les paramètres spécifiés

.PARAMETER Method
    Méthode HTTP (GET, POST, PUT, DELETE)

.PARAMETER Endpoint
    Point de terminaison de l'API

.PARAMETER Body
    Corps de la requête (pour POST et PUT)

.PARAMETER Headers
    En-têtes supplémentaires

.EXAMPLE
    Invoke-ApiRequest -Method "GET" -Endpoint "/api/users"
    Envoie une requête GET à /api/users

.EXAMPLE
    Invoke-ApiRequest -Method "POST" -Endpoint "/api/users" -Body @{name="John"; email="john@example.com"}
    Envoie une requête POST à /api/users avec un corps JSON

.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>
function Invoke-ApiRequest {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("GET", "POST", "PUT", "DELETE")]
        [string]$Method,
        
        [Parameter(Mandatory=$true)]
        [string]$Endpoint,
        
        [Parameter(Mandatory=$false)]
        [object]$Body = $null,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Headers = @{}
    )
    
    # Construire l'URL complète
    $url = $script:ApiConfig.BaseUrl.TrimEnd('/') + '/' + $Endpoint.TrimStart('/')
    
    # Préparer les en-têtes
    $headers = $Headers.Clone()
    $headers["User-Agent"] = $script:ApiConfig.UserAgent
    
    if (-not [string]::IsNullOrEmpty($script:ApiConfig.ApiKey)) {
        $headers["X-API-Key"] = $script:ApiConfig.ApiKey
    }
    
    # Préparer les paramètres de la requête
    $params = @{
        Method = $Method
        Uri = $url
        Headers = $headers
        TimeoutSec = $script:ApiConfig.Timeout
        UseBasicParsing = $true
    }
    
    # Ajouter le corps pour POST et PUT
    if ($Method -in @("POST", "PUT") -and $Body -ne $null) {
        $params["ContentType"] = "application/json"
        $params["Body"] = if ($Body -is [string]) { $Body } else { $Body | ConvertTo-Json -Depth 10 }
    }
    
    if ($PSCmdlet.ShouldProcess($url, $Method)) {
        try {
            # Simuler une requête API
            Write-Verbose "Envoi d'une requête $Method à $url"
            
            # Simuler un délai de réseau
            Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
            
            # Simuler une réponse
            $response = switch ($Endpoint) {
                "/api/users" {
                    if ($Method -eq "GET") {
                        @{
                            StatusCode = 200
                            Content = @{
                                users = @(
                                    @{
                                        id = 1
                                        name = "John Doe"
                                        email = "john@example.com"
                                    },
                                    @{
                                        id = 2
                                        name = "Jane Smith"
                                        email = "jane@example.com"
                                    }
                                )
                            } | ConvertTo-Json -Depth 10
                        }
                    }
                    elseif ($Method -eq "POST") {
                        @{
                            StatusCode = 201
                            Content = @{
                                id = 3
                                name = "New User"
                                email = "new@example.com"
                            } | ConvertTo-Json -Depth 10
                        }
                    }
                    else {
                        @{
                            StatusCode = 405
                            Content = @{
                                error = "Method Not Allowed"
                            } | ConvertTo-Json -Depth 10
                        }
                    }
                }
                "/api/products" {
                    if ($Method -eq "GET") {
                        @{
                            StatusCode = 200
                            Content = @{
                                products = @(
                                    @{
                                        id = 1
                                        name = "Product 1"
                                        price = 9.99
                                    },
                                    @{
                                        id = 2
                                        name = "Product 2"
                                        price = 19.99
                                    }
                                )
                            } | ConvertTo-Json -Depth 10
                        }
                    }
                    else {
                        @{
                            StatusCode = 405
                            Content = @{
                                error = "Method Not Allowed"
                            } | ConvertTo-Json -Depth 10
                        }
                    }
                }
                default {
                    @{
                        StatusCode = 404
                        Content = @{
                            error = "Not Found"
                        } | ConvertTo-Json -Depth 10
                    }
                }
            }
            
            # Créer un objet de réponse
            $result = [PSCustomObject]@{
                StatusCode = $response.StatusCode
                Content = $response.Content
                Headers = @{
                    "Content-Type" = "application/json"
                    "Date" = Get-Date -Format "r"
                }
                Success = $response.StatusCode -ge 200 -and $response.StatusCode -lt 300
            }
            
            return $result
        }
        catch {
            Write-Error "Erreur lors de l'envoi de la requête API : $_"
            
            return [PSCustomObject]@{
                StatusCode = 500
                Content = @{
                    error = $_.Exception.Message
                } | ConvertTo-Json -Depth 10
                Headers = @{}
                Success = $false
            }
        }
    }
}

<#
.SYNOPSIS
    Obtient des utilisateurs

.DESCRIPTION
    Obtient la liste des utilisateurs

.EXAMPLE
    Get-Users
    Obtient tous les utilisateurs

.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>
function Get-Users {
    [CmdletBinding()]
    param()
    
    $response = Invoke-ApiRequest -Method "GET" -Endpoint "/api/users"
    
    if ($response.Success) {
        $content = $response.Content | ConvertFrom-Json
        return $content.users
    }
    else {
        Write-Error "Erreur lors de la récupération des utilisateurs : $($response.Content)"
        return $null
    }
}

<#
.SYNOPSIS
    Obtient des produits

.DESCRIPTION
    Obtient la liste des produits

.EXAMPLE
    Get-Products
    Obtient tous les produits

.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>
function Get-Products {
    [CmdletBinding()]
    param()
    
    $response = Invoke-ApiRequest -Method "GET" -Endpoint "/api/products"
    
    if ($response.Success) {
        $content = $response.Content | ConvertFrom-Json
        return $content.products
    }
    else {
        Write-Error "Erreur lors de la récupération des produits : $($response.Content)"
        return $null
    }
}

<#
.SYNOPSIS
    Crée un utilisateur

.DESCRIPTION
    Crée un nouvel utilisateur

.PARAMETER Name
    Nom de l'utilisateur

.PARAMETER Email
    Email de l'utilisateur

.EXAMPLE
    New-User -Name "John Doe" -Email "john@example.com"
    Crée un nouvel utilisateur

.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>
function New-User {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Email
    )
    
    $body = @{
        name = $Name
        email = $Email
    }
    
    if ($PSCmdlet.ShouldProcess("User", "Create")) {
        $response = Invoke-ApiRequest -Method "POST" -Endpoint "/api/users" -Body $body
        
        if ($response.Success) {
            $content = $response.Content | ConvertFrom-Json
            return $content
        }
        else {
            Write-Error "Erreur lors de la création de l'utilisateur : $($response.Content)"
            return $null
        }
    }
}

<#
.SYNOPSIS
    Teste la connexion API

.DESCRIPTION
    Teste la connexion à l'API

.EXAMPLE
    Test-ApiConnection
    Teste la connexion à l'API

.NOTES
    Version: 1.0.0
    Auteur: MCP Team
    Date de création: 2023-05-15
#>
function Test-ApiConnection {
    [CmdletBinding()]
    param()
    
    try {
        $response = Invoke-ApiRequest -Method "GET" -Endpoint "/api/health"
        
        return [PSCustomObject]@{
            Success = $response.Success
            Message = if ($response.Success) { "Connexion établie avec succès" } else { "Échec de la connexion" }
            StatusCode = $response.StatusCode
        }
    }
    catch {
        return [PSCustomObject]@{
            Success = $false
            Message = "Erreur lors du test de connexion : $($_.Exception.Message)"
            StatusCode = 500
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ApiConfig, Invoke-ApiRequest, Get-Users, Get-Products, New-User, Test-ApiConnection

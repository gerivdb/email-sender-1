# Connect-N8nRoadmap.ps1
# Module pour intégrer les fonctionnalités de roadmap avec n8n
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Intègre les fonctionnalités de roadmap avec n8n.

.DESCRIPTION
    Ce module fournit des fonctions pour intégrer les fonctionnalités de roadmap avec n8n,
    permettant d'automatiser la génération, l'analyse et la gestion des roadmaps.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$generationPath = Join-Path -Path $parentPath -ChildPath "generation"
$analysisPath = Join-Path -Path $parentPath -ChildPath "analysis"
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"

$generateRealisticRoadmapPath = Join-Path -Path $generationPath -ChildPath "Generate-RealisticRoadmap.ps1"
$analyzeRoadmapPath = Join-Path -Path $analysisPath -ChildPath "Analyze-RoadmapStructure.ps1"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"
$generateRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Generate-Roadmap.ps1"

if (Test-Path $generateRealisticRoadmapPath) {
    . $generateRealisticRoadmapPath
} else {
    Write-Error "Module Generate-RealisticRoadmap.ps1 introuvable à l'emplacement: $generateRealisticRoadmapPath"
    exit
}

if (Test-Path $analyzeRoadmapPath) {
    . $analyzeRoadmapPath
} else {
    Write-Error "Module Analyze-RoadmapStructure.ps1 introuvable à l'emplacement: $analyzeRoadmapPath"
    exit
}

if (Test-Path $parseRoadmapPath) {
    . $parseRoadmapPath
} else {
    Write-Error "Module Parse-Roadmap.ps1 introuvable à l'emplacement: $parseRoadmapPath"
    exit
}

if (Test-Path $generateRoadmapPath) {
    . $generateRoadmapPath
} else {
    Write-Error "Module Generate-Roadmap.ps1 introuvable à l'emplacement: $generateRoadmapPath"
    exit
}

# Fonction pour créer un endpoint API pour n8n
function New-N8nRoadmapEndpoint {
    <#
    .SYNOPSIS
        Crée un endpoint API pour n8n.

    .DESCRIPTION
        Cette fonction crée un endpoint API pour n8n, permettant d'exposer les fonctionnalités
        de roadmap via une API REST que n8n peut consommer.

    .PARAMETER Port
        Le port sur lequel l'API doit écouter.

    .PARAMETER BasePath
        Le chemin de base de l'API.

    .PARAMETER EnableCors
        Indique si CORS doit être activé.

    .EXAMPLE
        New-N8nRoadmapEndpoint -Port 3000 -BasePath "/api/roadmap" -EnableCors
        Crée un endpoint API sur le port 3000 avec le chemin de base /api/roadmap et CORS activé.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Port = 3000,

        [Parameter(Mandatory = $false)]
        [string]$BasePath = "/api/roadmap",

        [Parameter(Mandatory = $false)]
        [switch]$EnableCors
    )

    # Vérifier si le module HttpListener est disponible
    if (-not ([System.Net.HttpListener]::IsSupported)) {
        Write-Error "HttpListener n'est pas pris en charge sur ce système."
        return $null
    }
    
    # Créer l'URL d'écoute
    $url = "http://localhost:$Port$BasePath/"
    
    # Créer le listener HTTP
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add($url)
    
    # Configurer CORS si nécessaire
    if ($EnableCors) {
        $listener.IgnoreWriteExceptions = $true
    }
    
    # Démarrer le listener
    try {
        $listener.Start()
        Write-Host "API démarrée sur $url"
    } catch {
        Write-Error "Impossible de démarrer l'API: $_"
        return $null
    }
    
    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        Listener = $listener
        Url = $url
        Port = $Port
        BasePath = $BasePath
        EnableCors = $EnableCors
    }
    
    return $result
}

# Fonction pour traiter les requêtes API
function Start-N8nRoadmapApiListener {
    <#
    .SYNOPSIS
        Démarre l'écoute des requêtes API.

    .DESCRIPTION
        Cette fonction démarre l'écoute des requêtes API et les traite en fonction des routes définies.

    .PARAMETER ApiEndpoint
        L'endpoint API créé par New-N8nRoadmapEndpoint.

    .PARAMETER Routes
        Les routes à exposer via l'API.

    .EXAMPLE
        Start-N8nRoadmapApiListener -ApiEndpoint $endpoint -Routes $routes
        Démarre l'écoute des requêtes API sur l'endpoint spécifié avec les routes définies.

    .OUTPUTS
        None
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$ApiEndpoint,

        [Parameter(Mandatory = $true)]
        [hashtable]$Routes
    )

    $listener = $ApiEndpoint.Listener
    $enableCors = $ApiEndpoint.EnableCors
    
    # Démarrer la boucle d'écoute
    Write-Host "Démarrage de l'écoute des requêtes API..."
    
    while ($listener.IsListening) {
        try {
            # Attendre une requête
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            # Configurer CORS si nécessaire
            if ($enableCors) {
                $response.Headers.Add("Access-Control-Allow-Origin", "*")
                $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
                $response.Headers.Add("Access-Control-Allow-Headers", "Content-Type, Accept, X-Requested-With")
                
                # Répondre immédiatement aux requêtes OPTIONS (preflight)
                if ($request.HttpMethod -eq "OPTIONS") {
                    $response.StatusCode = 200
                    $response.Close()
                    continue
                }
            }
            
            # Extraire le chemin de la requête
            $path = $request.Url.LocalPath
            $path = $path.TrimEnd('/')
            
            # Extraire les paramètres de la requête
            $parameters = @{}
            foreach ($key in $request.QueryString.AllKeys) {
                $parameters[$key] = $request.QueryString[$key]
            }
            
            # Lire le corps de la requête si nécessaire
            $body = $null
            if ($request.HasEntityBody) {
                $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $body = $reader.ReadToEnd()
                $reader.Close()
                
                # Convertir le corps JSON en objet PowerShell si nécessaire
                if ($request.ContentType -match "application/json") {
                    try {
                        $body = $body | ConvertFrom-Json
                    } catch {
                        Write-Warning "Impossible de parser le corps JSON: $_"
                    }
                }
            }
            
            # Trouver la route correspondante
            $route = $null
            $routeParams = @{}
            
            foreach ($routeKey in $Routes.Keys) {
                $pattern = "^$($ApiEndpoint.BasePath)$routeKey$"
                if ($path -match $pattern) {
                    $route = $Routes[$routeKey]
                    
                    # Extraire les paramètres de route
                    if ($routeKey -match "{([^}]+)}") {
                        $paramName = $matches[1]
                        $paramValue = $path -replace $pattern.Replace("{$paramName}", "([^/]+)"), '$1'
                        $routeParams[$paramName] = $paramValue
                    }
                    
                    break
                }
            }
            
            # Traiter la requête
            if ($null -ne $route) {
                $method = $request.HttpMethod.ToUpper()
                
                if ($route.ContainsKey($method)) {
                    $handler = $route[$method]
                    
                    # Préparer les paramètres pour le handler
                    $handlerParams = @{
                        Parameters = $parameters
                        RouteParams = $routeParams
                        Body = $body
                        Request = $request
                        Response = $response
                    }
                    
                    # Appeler le handler
                    try {
                        $result = & $handler @handlerParams
                        
                        # Configurer la réponse
                        $response.StatusCode = 200
                        $response.ContentType = "application/json"
                        
                        # Convertir le résultat en JSON
                        $jsonResult = $result | ConvertTo-Json -Depth 10
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResult)
                        
                        # Envoyer la réponse
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    } catch {
                        # Gérer les erreurs
                        $response.StatusCode = 500
                        $response.ContentType = "application/json"
                        
                        $errorResult = @{
                            error = $_.Exception.Message
                            stackTrace = $_.ScriptStackTrace
                        }
                        
                        $jsonError = $errorResult | ConvertTo-Json
                        $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonError)
                        
                        $response.ContentLength64 = $buffer.Length
                        $response.OutputStream.Write($buffer, 0, $buffer.Length)
                    }
                } else {
                    # Méthode non supportée
                    $response.StatusCode = 405
                    $response.StatusDescription = "Method Not Allowed"
                }
            } else {
                # Route non trouvée
                $response.StatusCode = 404
                $response.StatusDescription = "Not Found"
            }
            
            # Fermer la réponse
            $response.Close()
        } catch {
            Write-Error "Erreur lors du traitement de la requête: $_"
        }
    }
}

# Fonction pour arrêter l'API
function Stop-N8nRoadmapApiListener {
    <#
    .SYNOPSIS
        Arrête l'écoute des requêtes API.

    .DESCRIPTION
        Cette fonction arrête l'écoute des requêtes API et libère les ressources associées.

    .PARAMETER ApiEndpoint
        L'endpoint API créé par New-N8nRoadmapEndpoint.

    .EXAMPLE
        Stop-N8nRoadmapApiListener -ApiEndpoint $endpoint
        Arrête l'écoute des requêtes API sur l'endpoint spécifié.

    .OUTPUTS
        None
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$ApiEndpoint
    )

    $listener = $ApiEndpoint.Listener
    
    if ($listener.IsListening) {
        $listener.Stop()
        $listener.Close()
        Write-Host "API arrêtée."
    }
}

# Fonction pour définir les routes de l'API
function New-N8nRoadmapApiRoutes {
    <#
    .SYNOPSIS
        Définit les routes de l'API.

    .DESCRIPTION
        Cette fonction définit les routes de l'API et les handlers associés.

    .PARAMETER RoadmapsPath
        Le chemin vers le dossier contenant les roadmaps.

    .PARAMETER ModelsPath
        Le chemin vers le dossier contenant les modèles statistiques.

    .EXAMPLE
        New-N8nRoadmapApiRoutes -RoadmapsPath "C:\Roadmaps" -ModelsPath "C:\Models"
        Définit les routes de l'API avec les chemins spécifiés.

    .OUTPUTS
        Hashtable
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapsPath,

        [Parameter(Mandatory = $true)]
        [string]$ModelsPath
    )

    # Vérifier que les dossiers existent
    if (-not (Test-Path $RoadmapsPath)) {
        New-Item -Path $RoadmapsPath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-Path $ModelsPath)) {
        New-Item -Path $ModelsPath -ItemType Directory -Force | Out-Null
    }
    
    # Définir les routes
    $routes = @{
        # Route pour lister toutes les roadmaps
        "/roadmaps" = @{
            "GET" = {
                param($Parameters, $RouteParams, $Body, $Request, $Response)
                
                $roadmaps = Get-ChildItem -Path $RoadmapsPath -Filter "*.md" | ForEach-Object {
                    $metadata = Get-RoadmapMetadata -FilePath $_.FullName
                    
                    [PSCustomObject]@{
                        Name = $_.BaseName
                        Path = $_.FullName
                        Title = $metadata.Title
                        Version = $metadata.Version
                        Date = $metadata.Date
                        Author = $metadata.Author
                        Tags = $metadata.Tags
                    }
                }
                
                return @{
                    roadmaps = $roadmaps
                }
            }
            
            # Route pour créer une nouvelle roadmap
            "POST" = {
                param($Parameters, $RouteParams, $Body, $Request, $Response)
                
                if ($null -eq $Body) {
                    throw "Corps de requête manquant."
                }
                
                $title = $Body.title
                $description = $Body.description
                $author = $Body.author
                $tags = $Body.tags
                $modelName = $Body.modelName
                $thematicContext = $Body.thematicContext
                
                if ([string]::IsNullOrEmpty($title)) {
                    throw "Titre manquant."
                }
                
                # Générer un nom de fichier à partir du titre
                $fileName = $title -replace "[^\w\d]", "-"
                $fileName = $fileName -replace "-+", "-"
                $fileName = $fileName.ToLower()
                
                $outputPath = Join-Path -Path $RoadmapsPath -ChildPath "$fileName.md"
                
                # Vérifier si un modèle est spécifié
                if (-not [string]::IsNullOrEmpty($modelName)) {
                    # Trouver le modèle
                    $modelFiles = Get-ChildItem -Path $ModelsPath -Filter "*$modelName*.clixml"
                    
                    if ($modelFiles.Count -gt 0) {
                        $modelPath = $modelFiles[0].FullName
                        
                        # Générer une roadmap réaliste
                        $result = New-RealisticRoadmap -ModelPath $modelPath -Title $title -OutputPath $outputPath -ThematicContext $thematicContext
                    } else {
                        throw "Modèle non trouvé: $modelName"
                    }
                } else {
                    # Générer une roadmap vide
                    $result = New-EmptyRoadmap -Title $title -Description $description -Author $author -Tags $tags -OutputPath $outputPath
                }
                
                return @{
                    success = $true
                    path = $outputPath
                    fileName = (Split-Path -Leaf $outputPath)
                }
            }
        }
        
        # Route pour obtenir une roadmap spécifique
        "/roadmaps/{name}" = @{
            "GET" = {
                param($Parameters, $RouteParams, $Body, $Request, $Response)
                
                $name = $RouteParams.name
                $filePath = Join-Path -Path $RoadmapsPath -ChildPath "$name.md"
                
                if (-not (Test-Path $filePath)) {
                    $Response.StatusCode = 404
                    return @{
                        error = "Roadmap non trouvée: $name"
                    }
                }
                
                $roadmap = Parse-RoadmapFile -FilePath $filePath -IncludeContent
                
                return @{
                    roadmap = $roadmap
                }
            }
            
            # Route pour mettre à jour une roadmap
            "PUT" = {
                param($Parameters, $RouteParams, $Body, $Request, $Response)
                
                $name = $RouteParams.name
                $filePath = Join-Path -Path $RoadmapsPath -ChildPath "$name.md"
                
                if (-not (Test-Path $filePath)) {
                    $Response.StatusCode = 404
                    return @{
                        error = "Roadmap non trouvée: $name"
                    }
                }
                
                if ($null -eq $Body) {
                    throw "Corps de requête manquant."
                }
                
                $taskUpdates = $Body.taskUpdates
                
                if ($null -ne $taskUpdates -and $taskUpdates.Count -gt 0) {
                    # Mettre à jour le statut des tâches
                    $result = Update-RoadmapTaskStatus -FilePath $filePath -TaskUpdates $taskUpdates
                    
                    return @{
                        success = $true
                        path = $filePath
                        fileName = $name
                    }
                } else {
                    throw "Aucune mise à jour spécifiée."
                }
            }
            
            # Route pour supprimer une roadmap
            "DELETE" = {
                param($Parameters, $RouteParams, $Body, $Request, $Response)
                
                $name = $RouteParams.name
                $filePath = Join-Path -Path $RoadmapsPath -ChildPath "$name.md"
                
                if (-not (Test-Path $filePath)) {
                    $Response.StatusCode = 404
                    return @{
                        error = "Roadmap non trouvée: $name"
                    }
                }
                
                Remove-Item -Path $filePath -Force
                
                return @{
                    success = $true
                    fileName = $name
                }
            }
        }
        
        # Route pour analyser une roadmap
        "/analyze/{name}" = @{
            "GET" = {
                param($Parameters, $RouteParams, $Body, $Request, $Response)
                
                $name = $RouteParams.name
                $filePath = Join-Path -Path $RoadmapsPath -ChildPath "$name.md"
                
                if (-not (Test-Path $filePath)) {
                    $Response.StatusCode = 404
                    return @{
                        error = "Roadmap non trouvée: $name"
                    }
                }
                
                $analysis = Invoke-RoadmapAnalysis -RoadmapPath $filePath
                
                return @{
                    analysis = $analysis
                }
            }
        }
        
        # Route pour lister les modèles statistiques
        "/models" = @{
            "GET" = {
                param($Parameters, $RouteParams, $Body, $Request, $Response)
                
                $models = Get-ChildItem -Path $ModelsPath -Filter "*.clixml" | ForEach-Object {
                    $model = Import-Clixml -Path $_.FullName
                    
                    [PSCustomObject]@{
                        Name = $model.ModelName
                        Path = $_.FullName
                        AverageTaskCount = $model.StructuralParameters.AverageTaskCount
                        AverageMaxDepth = $model.StructuralParameters.AverageMaxDepth
                    }
                }
                
                return @{
                    models = $models
                }
            }
            
            # Route pour créer un nouveau modèle statistique
            "POST" = {
                param($Parameters, $RouteParams, $Body, $Request, $Response)
                
                if ($null -eq $Body) {
                    throw "Corps de requête manquant."
                }
                
                $modelName = $Body.modelName
                $roadmapNames = $Body.roadmapNames
                
                if ([string]::IsNullOrEmpty($modelName)) {
                    throw "Nom du modèle manquant."
                }
                
                if ($null -eq $roadmapNames -or $roadmapNames.Count -eq 0) {
                    throw "Noms des roadmaps manquants."
                }
                
                # Trouver les roadmaps
                $roadmapPaths = @()
                foreach ($name in $roadmapNames) {
                    $filePath = Join-Path -Path $RoadmapsPath -ChildPath "$name.md"
                    
                    if (Test-Path $filePath) {
                        $roadmapPaths += $filePath
                    } else {
                        throw "Roadmap non trouvée: $name"
                    }
                }
                
                # Créer le modèle statistique
                $model = New-RoadmapStatisticalModel -RoadmapPaths $roadmapPaths -ModelName $modelName -OutputPath $ModelsPath
                
                return @{
                    success = $true
                    modelName = $modelName
                    roadmapCount = $roadmapPaths.Count
                }
            }
        }
    }
    
    return $routes
}

# Fonction principale pour démarrer l'API
function Start-N8nRoadmapApi {
    <#
    .SYNOPSIS
        Démarre l'API pour n8n.

    .DESCRIPTION
        Cette fonction démarre l'API pour n8n, permettant d'exposer les fonctionnalités
        de roadmap via une API REST que n8n peut consommer.

    .PARAMETER Port
        Le port sur lequel l'API doit écouter.

    .PARAMETER RoadmapsPath
        Le chemin vers le dossier contenant les roadmaps.

    .PARAMETER ModelsPath
        Le chemin vers le dossier contenant les modèles statistiques.

    .PARAMETER EnableCors
        Indique si CORS doit être activé.

    .EXAMPLE
        Start-N8nRoadmapApi -Port 3000 -RoadmapsPath "C:\Roadmaps" -ModelsPath "C:\Models" -EnableCors
        Démarre l'API sur le port 3000 avec les chemins spécifiés et CORS activé.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$Port = 3000,

        [Parameter(Mandatory = $true)]
        [string]$RoadmapsPath,

        [Parameter(Mandatory = $true)]
        [string]$ModelsPath,

        [Parameter(Mandatory = $false)]
        [switch]$EnableCors
    )

    # Créer l'endpoint API
    $endpoint = New-N8nRoadmapEndpoint -Port $Port -BasePath "/api/roadmap" -EnableCors:$EnableCors
    
    if ($null -eq $endpoint) {
        return $null
    }
    
    # Définir les routes
    $routes = New-N8nRoadmapApiRoutes -RoadmapsPath $RoadmapsPath -ModelsPath $ModelsPath
    
    # Démarrer l'écoute des requêtes API dans un job en arrière-plan
    $job = Start-Job -ScriptBlock {
        param($Endpoint, $Routes)
        
        # Importer les fonctions nécessaires
        . $using:PSCommandPath
        
        # Démarrer l'écoute
        Start-N8nRoadmapApiListener -ApiEndpoint $Endpoint -Routes $Routes
    } -ArgumentList $endpoint, $routes
    
    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        Endpoint = $endpoint
        Job = $job
        RoadmapsPath = $RoadmapsPath
        ModelsPath = $ModelsPath
    }
    
    return $result
}

# Fonction pour arrêter l'API
function Stop-N8nRoadmapApi {
    <#
    .SYNOPSIS
        Arrête l'API pour n8n.

    .DESCRIPTION
        Cette fonction arrête l'API pour n8n et libère les ressources associées.

    .PARAMETER Api
        L'API créée par Start-N8nRoadmapApi.

    .EXAMPLE
        Stop-N8nRoadmapApi -Api $api
        Arrête l'API spécifiée.

    .OUTPUTS
        None
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Api
    )

    # Arrêter le job en arrière-plan
    if ($null -ne $Api.Job) {
        Stop-Job -Job $Api.Job
        Remove-Job -Job $Api.Job -Force
    }
    
    # Arrêter l'endpoint API
    if ($null -ne $Api.Endpoint) {
        Stop-N8nRoadmapApiListener -ApiEndpoint $Api.Endpoint
    }
    
    Write-Host "API arrêtée."
}

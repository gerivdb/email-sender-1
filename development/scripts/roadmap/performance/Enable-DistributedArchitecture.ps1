# Enable-DistributedArchitecture.ps1
# Module pour l'architecture distribuée des roadmaps
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Fournit des fonctions pour l'architecture distribuée des roadmaps.

.DESCRIPTION
    Ce module fournit des fonctions pour l'architecture distribuée des roadmaps,
    notamment le traitement parallèle des tâches, la mise en cache distribuée et le clustering Qdrant.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"

if (Test-Path $parseRoadmapPath) {
    . $parseRoadmapPath
    Write-Verbose "Module Parse-Roadmap.ps1 chargé."
} else {
    Write-Error "Module Parse-Roadmap.ps1 introuvable à l'emplacement: $parseRoadmapPath"
    exit
}

# Fonction pour implémenter le traitement parallèle des tâches
function Enable-ParallelTaskProcessing {
    <#
    .SYNOPSIS
        Active le traitement parallèle des tâches pour les roadmaps.

    .DESCRIPTION
        Cette fonction active le traitement parallèle des tâches pour les roadmaps,
        permettant de traiter plusieurs tâches simultanément pour améliorer les performances.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats du traitement.
        Si non spécifié, un dossier temporaire est utilisé.

    .PARAMETER MaxThreads
        Le nombre maximum de threads à utiliser pour le traitement parallèle.
        Par défaut, le nombre de processeurs logiques disponibles.

    .PARAMETER TaskBatchSize
        Le nombre de tâches à traiter par lot.
        Par défaut, 100 tâches par lot.

    .PARAMETER ProcessingFunction
        La fonction à exécuter pour chaque tâche.
        Si non spécifiée, une fonction de traitement par défaut est utilisée.

    .EXAMPLE
        Enable-ParallelTaskProcessing -RoadmapPath "C:\Roadmaps\large-roadmap.md" -MaxThreads 4 -TaskBatchSize 200
        Active le traitement parallèle des tâches pour une roadmap avec 4 threads et des lots de 200 tâches.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0,

        [Parameter(Mandatory = $false)]
        [int]$TaskBatchSize = 100,

        [Parameter(Mandatory = $false)]
        [scriptblock]$ProcessingFunction = $null
    )

    try {
        # Vérifier que le fichier de roadmap existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path $env:TEMP -ChildPath "ParallelTaskProcessing"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Déterminer le nombre de threads si non spécifié
        if ($MaxThreads -le 0) {
            $MaxThreads = [Environment]::ProcessorCount
        }
        
        # Définir la fonction de traitement par défaut si non spécifiée
        if ($null -eq $ProcessingFunction) {
            $ProcessingFunction = {
                param($Task)
                
                # Fonction de traitement par défaut
                $processedTask = $Task | Select-Object *
                
                # Ajouter des propriétés supplémentaires
                $processedTask | Add-Member -MemberType NoteProperty -Name "ProcessedDate" -Value (Get-Date)
                $processedTask | Add-Member -MemberType NoteProperty -Name "ProcessedBy" -Value $env:COMPUTERNAME
                
                return $processedTask
            }
        }
        
        # Générer un identifiant unique pour cette exécution
        $executionId = [Guid]::NewGuid().ToString()
        $executionPath = Join-Path -Path $OutputPath -ChildPath $executionId
        
        # Créer le dossier d'exécution
        if (-not (Test-Path $executionPath)) {
            New-Item -Path $executionPath -ItemType Directory -Force | Out-Null
        }
        
        # Analyser la roadmap pour extraire les tâches
        Write-Verbose "Extraction des tâches de la roadmap..."
        $roadmapContent = Get-Content -Path $RoadmapPath
        $parsedRoadmap = Parse-RoadmapContent -Content $roadmapContent
        $tasks = $parsedRoadmap.Tasks
        
        Write-Verbose "Nombre total de tâches: $($tasks.Count)"
        
        # Diviser les tâches en lots
        $taskBatches = @()
        $batchCount = [Math]::Ceiling($tasks.Count / $TaskBatchSize)
        
        for ($i = 0; $i -lt $batchCount; $i++) {
            $startIndex = $i * $TaskBatchSize
            $endIndex = [Math]::Min(($i + 1) * $TaskBatchSize - 1, $tasks.Count - 1)
            $batchTasks = $tasks[$startIndex..$endIndex]
            
            $taskBatches += [PSCustomObject]@{
                BatchId = $i
                StartIndex = $startIndex
                EndIndex = $endIndex
                Tasks = $batchTasks
            }
        }
        
        Write-Verbose "Nombre de lots: $($taskBatches.Count)"
        
        # Traiter les lots en parallèle
        $processedTasks = @()
        
        # Utiliser ForEach-Object -Parallel si PowerShell 7+, sinon utiliser des runspaces
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $processedBatches = $taskBatches | ForEach-Object -Parallel {
                $batch = $_
                $processingFunction = $using:ProcessingFunction
                
                # Traiter chaque tâche du lot
                $processedBatchTasks = @()
                
                foreach ($task in $batch.Tasks) {
                    $processedTask = & $processingFunction $task
                    $processedBatchTasks += $processedTask
                }
                
                return [PSCustomObject]@{
                    BatchId = $batch.BatchId
                    ProcessedTasks = $processedBatchTasks
                }
            } -ThrottleLimit $MaxThreads
            
            # Fusionner les résultats
            foreach ($batch in ($processedBatches | Sort-Object -Property BatchId)) {
                $processedTasks += $batch.ProcessedTasks
            }
        } else {
            # Utiliser des runspaces pour PowerShell 5.1
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
            $runspacePool.Open()
            
            $runspaces = @()
            
            foreach ($batch in $taskBatches) {
                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $runspacePool
                
                [void]$powershell.AddScript({
                    param($Batch, $ProcessingFunction)
                    
                    # Traiter chaque tâche du lot
                    $processedBatchTasks = @()
                    
                    foreach ($task in $Batch.Tasks) {
                        $processedTask = & $ProcessingFunction $task
                        $processedBatchTasks += $processedTask
                    }
                    
                    return [PSCustomObject]@{
                        BatchId = $Batch.BatchId
                        ProcessedTasks = $processedBatchTasks
                    }
                })
                
                [void]$powershell.AddParameter("Batch", $batch)
                [void]$powershell.AddParameter("ProcessingFunction", $ProcessingFunction)
                
                $runspaces += [PSCustomObject]@{
                    Powershell = $powershell
                    AsyncResult = $powershell.BeginInvoke()
                    BatchId = $batch.BatchId
                }
            }
            
            # Récupérer les résultats
            foreach ($runspace in ($runspaces | Sort-Object -Property BatchId)) {
                $batchResult = $runspace.Powershell.EndInvoke($runspace.AsyncResult)
                $processedTasks += $batchResult.ProcessedTasks
                $runspace.Powershell.Dispose()
            }
            
            $runspacePool.Close()
            $runspacePool.Dispose()
        }
        
        # Sauvegarder les résultats
        $resultFilePath = Join-Path -Path $executionPath -ChildPath "processed-tasks.json"
        $processedTasks | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFilePath -Encoding UTF8
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            ExecutionId = $executionId
            RoadmapPath = $RoadmapPath
            OutputPath = $executionPath
            ResultFilePath = $resultFilePath
            TotalTasks = $tasks.Count
            ProcessedTasks = $processedTasks.Count
            BatchCount = $taskBatches.Count
            MaxThreads = $MaxThreads
            TaskBatchSize = $TaskBatchSize
            StartTime = $startTime
            EndTime = Get-Date
            Duration = (Get-Date) - $startTime
        }
        
        return $result
    } catch {
        Write-Error "Échec du traitement parallèle des tâches: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour implémenter la mise en cache distribuée
function Enable-DistributedCaching {
    <#
    .SYNOPSIS
        Active la mise en cache distribuée pour les roadmaps.

    .DESCRIPTION
        Cette fonction active la mise en cache distribuée pour les roadmaps,
        permettant de partager le cache entre plusieurs instances de l'application.

    .PARAMETER CacheServer
        L'adresse du serveur de cache.
        Par défaut, localhost.

    .PARAMETER CachePort
        Le port du serveur de cache.
        Par défaut, 6379 (port Redis par défaut).

    .PARAMETER CachePassword
        Le mot de passe du serveur de cache.
        Si non spécifié, aucun mot de passe n'est utilisé.

    .PARAMETER CacheKeyPrefix
        Le préfixe à utiliser pour les clés de cache.
        Par défaut, "roadmap:".

    .PARAMETER CacheExpiration
        La durée d'expiration du cache en secondes.
        Par défaut, 3600 secondes (1 heure).

    .PARAMETER UseSsl
        Indique si la connexion au serveur de cache doit utiliser SSL.
        Par défaut, $false.

    .EXAMPLE
        Enable-DistributedCaching -CacheServer "redis.example.com" -CachePort 6380 -CachePassword "password123" -CacheExpiration 7200
        Active la mise en cache distribuée avec un serveur Redis personnalisé et une expiration de 2 heures.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$CacheServer = "localhost",

        [Parameter(Mandatory = $false)]
        [int]$CachePort = 6379,

        [Parameter(Mandatory = $false)]
        [string]$CachePassword = "",

        [Parameter(Mandatory = $false)]
        [string]$CacheKeyPrefix = "roadmap:",

        [Parameter(Mandatory = $false)]
        [int]$CacheExpiration = 3600,

        [Parameter(Mandatory = $false)]
        [switch]$UseSsl = $false
    )

    try {
        # Vérifier si le module StackExchange.Redis est installé
        $redisModule = Get-Module -ListAvailable -Name "StackExchange.Redis"
        
        if ($null -eq $redisModule) {
            Write-Error "Le module StackExchange.Redis n'est pas installé. Veuillez l'installer avec 'Install-Module StackExchange.Redis'."
            return $null
        }
        
        # Créer la configuration Redis
        $configOptions = [StackExchange.Redis.ConfigurationOptions]::new()
        $configOptions.EndPoints.Add($CacheServer, $CachePort)
        
        if (-not [string]::IsNullOrEmpty($CachePassword)) {
            $configOptions.Password = $CachePassword
        }
        
        $configOptions.Ssl = $UseSsl
        $configOptions.AbortOnConnectFail = $false
        
        # Se connecter au serveur Redis
        $connection = [StackExchange.Redis.ConnectionMultiplexer]::Connect($configOptions)
        $database = $connection.GetDatabase()
        
        # Tester la connexion
        $pingResult = $database.Ping()
        
        if ($pingResult.TotalMilliseconds -eq 0) {
            Write-Error "Impossible de se connecter au serveur de cache."
            return $null
        }
        
        # Créer l'objet de configuration du cache
        $cacheConfig = [PSCustomObject]@{
            CacheServer = $CacheServer
            CachePort = $CachePort
            CacheKeyPrefix = $CacheKeyPrefix
            CacheExpiration = $CacheExpiration
            UseSsl = $UseSsl
            Connection = $connection
            Database = $database
            PingResult = $pingResult
        }
        
        # Définir les fonctions de cache
        $Global:DistributedCache = [PSCustomObject]@{
            Config = $cacheConfig
            
            # Fonction pour obtenir une valeur du cache
            Get = {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Key
                )
                
                $fullKey = $this.Config.CacheKeyPrefix + $Key
                $value = $this.Config.Database.StringGet($fullKey)
                
                if ($value.IsNull) {
                    return $null
                }
                
                return [System.Text.Encoding]::UTF8.GetString($value)
            }
            
            # Fonction pour définir une valeur dans le cache
            Set = {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Key,
                    
                    [Parameter(Mandatory = $true)]
                    [string]$Value,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$ExpirationSeconds = 0
                )
                
                $fullKey = $this.Config.CacheKeyPrefix + $Key
                $expiration = if ($ExpirationSeconds -gt 0) { [TimeSpan]::FromSeconds($ExpirationSeconds) } else { [TimeSpan]::FromSeconds($this.Config.CacheExpiration) }
                
                return $this.Config.Database.StringSet($fullKey, $Value, $expiration)
            }
            
            # Fonction pour supprimer une valeur du cache
            Remove = {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Key
                )
                
                $fullKey = $this.Config.CacheKeyPrefix + $Key
                return $this.Config.Database.KeyDelete($fullKey)
            }
            
            # Fonction pour vérifier si une clé existe dans le cache
            Exists = {
                param(
                    [Parameter(Mandatory = $true)]
                    [string]$Key
                )
                
                $fullKey = $this.Config.CacheKeyPrefix + $Key
                return $this.Config.Database.KeyExists($fullKey)
            }
            
            # Fonction pour obtenir toutes les clés correspondant à un modèle
            GetKeys = {
                param(
                    [Parameter(Mandatory = $false)]
                    [string]$Pattern = "*"
                )
                
                $fullPattern = $this.Config.CacheKeyPrefix + $Pattern
                $server = $this.Config.Connection.GetServer($this.Config.CacheServer, $this.Config.CachePort)
                
                return $server.Keys(pattern: $fullPattern)
            }
            
            # Fonction pour vider le cache
            Clear = {
                param(
                    [Parameter(Mandatory = $false)]
                    [string]$Pattern = "*"
                )
                
                $keys = $this.GetKeys($Pattern)
                $count = 0
                
                foreach ($key in $keys) {
                    if ($this.Config.Database.KeyDelete($key)) {
                        $count++
                    }
                }
                
                return $count
            }
            
            # Fonction pour fermer la connexion
            Close = {
                $this.Config.Connection.Close()
            }
        }
        
        return $Global:DistributedCache
    } catch {
        Write-Error "Échec de l'activation de la mise en cache distribuée: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour implémenter le clustering Qdrant
function Enable-QdrantClustering {
    <#
    .SYNOPSIS
        Active le clustering Qdrant pour les roadmaps.

    .DESCRIPTION
        Cette fonction active le clustering Qdrant pour les roadmaps,
        permettant de distribuer les requêtes vectorielles sur plusieurs nœuds Qdrant.

    .PARAMETER ClusterNodes
        Les adresses des nœuds du cluster Qdrant.
        Par défaut, un seul nœud sur localhost.

    .PARAMETER ApiKey
        La clé API pour l'authentification.
        Si non spécifiée, aucune authentification n'est utilisée.

    .PARAMETER CollectionName
        Le nom de la collection Qdrant.
        Par défaut, "roadmaps".

    .PARAMETER VectorSize
        La taille des vecteurs.
        Par défaut, 1536 (taille des vecteurs OpenAI).

    .PARAMETER Distance
        La métrique de distance à utiliser.
        Par défaut, "Cosine".

    .PARAMETER ReplicationFactor
        Le facteur de réplication pour la collection.
        Par défaut, 2.

    .PARAMETER WriteConsistencyFactor
        Le facteur de cohérence en écriture.
        Par défaut, 1.

    .EXAMPLE
        Enable-QdrantClustering -ClusterNodes @("qdrant1.example.com:6333", "qdrant2.example.com:6333") -ApiKey "api-key-123" -ReplicationFactor 3
        Active le clustering Qdrant avec deux nœuds et un facteur de réplication de 3.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$ClusterNodes = @("http://localhost:6333"),

        [Parameter(Mandatory = $false)]
        [string]$ApiKey = "",

        [Parameter(Mandatory = $false)]
        [string]$CollectionName = "roadmaps",

        [Parameter(Mandatory = $false)]
        [int]$VectorSize = 1536,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Cosine", "Euclid", "Dot")]
        [string]$Distance = "Cosine",

        [Parameter(Mandatory = $false)]
        [int]$ReplicationFactor = 2,

        [Parameter(Mandatory = $false)]
        [int]$WriteConsistencyFactor = 1
    )

    try {
        # Vérifier la connectivité avec les nœuds du cluster
        $connectedNodes = @()
        
        foreach ($node in $ClusterNodes) {
            $healthEndpoint = "$node/health"
            
            try {
                $headers = @{}
                
                if (-not [string]::IsNullOrEmpty($ApiKey)) {
                    $headers["api-key"] = $ApiKey
                }
                
                $response = Invoke-RestMethod -Uri $healthEndpoint -Method Get -Headers $headers
                
                if ($response.status -eq "ok") {
                    $connectedNodes += $node
                    Write-Verbose "Connexion réussie au nœud Qdrant: $node"
                } else {
                    Write-Warning "Le nœud Qdrant $node a répondu avec un statut non-ok: $($response.status)"
                }
            } catch {
                Write-Warning "Impossible de se connecter au nœud Qdrant $node: $($_.Exception.Message)"
            }
        }
        
        if ($connectedNodes.Count -eq 0) {
            Write-Error "Aucun nœud Qdrant n'est accessible. Veuillez vérifier les adresses et la connectivité."
            return $null
        }
        
        Write-Verbose "Nombre de nœuds connectés: $($connectedNodes.Count)"
        
        # Vérifier si la collection existe
        $primaryNode = $connectedNodes[0]
        $collectionEndpoint = "$primaryNode/collections/$CollectionName"
        
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        if (-not [string]::IsNullOrEmpty($ApiKey)) {
            $headers["api-key"] = $ApiKey
        }
        
        try {
            $collectionResponse = Invoke-RestMethod -Uri $collectionEndpoint -Method Get -Headers $headers
            $collectionExists = $true
            Write-Verbose "Collection $CollectionName existe déjà."
        } catch {
            $collectionExists = $false
            Write-Verbose "Collection $CollectionName n'existe pas encore."
        }
        
        # Créer la collection si elle n'existe pas
        if (-not $collectionExists) {
            $createCollectionEndpoint = "$primaryNode/collections/$CollectionName"
            
            $createCollectionBody = @{
                vectors = @{
                    size = $VectorSize
                    distance = $Distance.ToLower()
                }
                replication_factor = $ReplicationFactor
                write_consistency_factor = $WriteConsistencyFactor
            } | ConvertTo-Json
            
            try {
                $createResponse = Invoke-RestMethod -Uri $createCollectionEndpoint -Method Put -Headers $headers -Body $createCollectionBody
                Write-Verbose "Collection $CollectionName créée avec succès."
            } catch {
                Write-Error "Échec de la création de la collection $CollectionName: $($_.Exception.Message)"
                return $null
            }
        }
        
        # Créer l'objet de configuration du cluster
        $clusterConfig = [PSCustomObject]@{
            ClusterNodes = $connectedNodes
            PrimaryNode = $primaryNode
            ApiKey = $ApiKey
            CollectionName = $CollectionName
            VectorSize = $VectorSize
            Distance = $Distance
            ReplicationFactor = $ReplicationFactor
            WriteConsistencyFactor = $WriteConsistencyFactor
        }
        
        # Définir les fonctions du cluster
        $Global:QdrantCluster = [PSCustomObject]@{
            Config = $clusterConfig
            
            # Fonction pour obtenir les informations sur le cluster
            GetClusterInfo = {
                $headers = @{
                    "Content-Type" = "application/json"
                }
                
                if (-not [string]::IsNullOrEmpty($this.Config.ApiKey)) {
                    $headers["api-key"] = $this.Config.ApiKey
                }
                
                $clusterInfo = @()
                
                foreach ($node in $this.Config.ClusterNodes) {
                    try {
                        $response = Invoke-RestMethod -Uri "$node/cluster" -Method Get -Headers $headers
                        $clusterInfo += [PSCustomObject]@{
                            Node = $node
                            Status = "Connected"
                            Info = $response
                        }
                    } catch {
                        $clusterInfo += [PSCustomObject]@{
                            Node = $node
                            Status = "Error"
                            Error = $_.Exception.Message
                        }
                    }
                }
                
                return $clusterInfo
            }
            
            # Fonction pour obtenir les informations sur la collection
            GetCollectionInfo = {
                $headers = @{
                    "Content-Type" = "application/json"
                }
                
                if (-not [string]::IsNullOrEmpty($this.Config.ApiKey)) {
                    $headers["api-key"] = $this.Config.ApiKey
                }
                
                try {
                    $response = Invoke-RestMethod -Uri "$($this.Config.PrimaryNode)/collections/$($this.Config.CollectionName)" -Method Get -Headers $headers
                    return $response
                } catch {
                    Write-Error "Échec de l'obtention des informations sur la collection: $($_.Exception.Message)"
                    return $null
                }
            }
            
            # Fonction pour ajouter des points à la collection
            UpsertPoints = {
                param(
                    [Parameter(Mandatory = $true)]
                    [array]$Points
                )
                
                $headers = @{
                    "Content-Type" = "application/json"
                }
                
                if (-not [string]::IsNullOrEmpty($this.Config.ApiKey)) {
                    $headers["api-key"] = $this.Config.ApiKey
                }
                
                $body = @{
                    points = $Points
                } | ConvertTo-Json -Depth 10
                
                try {
                    $response = Invoke-RestMethod -Uri "$($this.Config.PrimaryNode)/collections/$($this.Config.CollectionName)/points" -Method Put -Headers $headers -Body $body
                    return $response
                } catch {
                    Write-Error "Échec de l'ajout des points à la collection: $($_.Exception.Message)"
                    return $null
                }
            }
            
            # Fonction pour rechercher des points similaires
            SearchPoints = {
                param(
                    [Parameter(Mandatory = $true)]
                    [array]$Vector,
                    
                    [Parameter(Mandatory = $false)]
                    [int]$Limit = 10,
                    
                    [Parameter(Mandatory = $false)]
                    [hashtable]$Filter = $null
                )
                
                $headers = @{
                    "Content-Type" = "application/json"
                }
                
                if (-not [string]::IsNullOrEmpty($this.Config.ApiKey)) {
                    $headers["api-key"] = $this.Config.ApiKey
                }
                
                $body = @{
                    vector = $Vector
                    limit = $Limit
                }
                
                if ($null -ne $Filter) {
                    $body.filter = $Filter
                }
                
                $bodyJson = $body | ConvertTo-Json -Depth 10
                
                try {
                    $response = Invoke-RestMethod -Uri "$($this.Config.PrimaryNode)/collections/$($this.Config.CollectionName)/points/search" -Method Post -Headers $headers -Body $bodyJson
                    return $response
                } catch {
                    Write-Error "Échec de la recherche de points similaires: $($_.Exception.Message)"
                    return $null
                }
            }
            
            # Fonction pour supprimer des points
            DeletePoints = {
                param(
                    [Parameter(Mandatory = $true)]
                    [array]$PointIds
                )
                
                $headers = @{
                    "Content-Type" = "application/json"
                }
                
                if (-not [string]::IsNullOrEmpty($this.Config.ApiKey)) {
                    $headers["api-key"] = $this.Config.ApiKey
                }
                
                $body = @{
                    points = $PointIds
                } | ConvertTo-Json
                
                try {
                    $response = Invoke-RestMethod -Uri "$($this.Config.PrimaryNode)/collections/$($this.Config.CollectionName)/points/delete" -Method Post -Headers $headers -Body $body
                    return $response
                } catch {
                    Write-Error "Échec de la suppression des points: $($_.Exception.Message)"
                    return $null
                }
            }
        }
        
        return $Global:QdrantCluster
    } catch {
        Write-Error "Échec de l'activation du clustering Qdrant: $($_.Exception.Message)"
        return $null
    }
}

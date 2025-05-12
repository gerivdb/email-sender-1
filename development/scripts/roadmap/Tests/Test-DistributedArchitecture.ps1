# Test-DistributedArchitecture.ps1
# Script de test pour l'architecture distribuée
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste les fonctionnalités de l'architecture distribuée.

.DESCRIPTION
    Ce script teste les fonctionnalités de l'architecture distribuée,
    notamment le traitement parallèle des tâches, la mise en cache distribuée et le clustering Qdrant.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$performancePath = Join-Path -Path $parentPath -ChildPath "performance"
$enableDistributedArchitecturePath = Join-Path -Path $performancePath -ChildPath "Enable-DistributedArchitecture.ps1"

if (Test-Path $enableDistributedArchitecturePath) {
    . $enableDistributedArchitecturePath
    Write-Host "Module Enable-DistributedArchitecture.ps1 chargé." -ForegroundColor Green
} else {
    Write-Error "Module Enable-DistributedArchitecture.ps1 introuvable à l'emplacement: $enableDistributedArchitecturePath"
    exit
}

# Fonction pour tester le traitement parallèle des tâches
function Test-ParallelTaskProcessing {
    <#
    .SYNOPSIS
        Teste le traitement parallèle des tâches.

    .DESCRIPTION
        Cette fonction teste le traitement parallèle des tâches en créant une roadmap de test
        et en mesurant les performances du traitement parallèle par rapport au traitement séquentiel.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap à tester.
        Si non spécifié, un fichier de test est généré.

    .PARAMETER TaskCount
        Le nombre de tâches à générer pour le fichier de test.
        Par défaut, 1000 tâches.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats des tests.
        Si non spécifié, un dossier temporaire est utilisé.

    .PARAMETER MaxThreads
        Le nombre maximum de threads à utiliser pour le traitement parallèle.
        Par défaut, le nombre de processeurs logiques disponibles.

    .EXAMPLE
        Test-ParallelTaskProcessing -TaskCount 5000 -MaxThreads 4
        Teste le traitement parallèle des tâches avec un fichier de test de 5000 tâches et 4 threads.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath = "",

        [Parameter(Mandatory = $false)]
        [int]$TaskCount = 1000,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0
    )

    try {
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path $env:TEMP -ChildPath "ParallelTaskProcessingTest"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Générer un fichier de test si nécessaire
        if ([string]::IsNullOrEmpty($RoadmapPath)) {
            $testRoadmapPath = Join-Path -Path $OutputPath -ChildPath "test-roadmap-$TaskCount.md"
            
            # Créer le contenu de la roadmap
            $content = @()
            $content += "# Roadmap de test"
            $content += ""
            $content += "Cette roadmap est générée automatiquement pour les tests de performance."
            $content += ""
            
            # Générer les tâches
            for ($i = 1; $i -le $TaskCount; $i++) {
                $status = if ($i % 3 -eq 0) { "[x]" } else { "[ ]" }
                $priority = switch ($i % 3) {
                    0 { "high" }
                    1 { "medium" }
                    2 { "low" }
                }
                $domain = switch ($i % 5) {
                    0 { "frontend" }
                    1 { "backend" }
                    2 { "database" }
                    3 { "security" }
                    4 { "performance" }
                }
                
                $content += "- $status **$i** Tâche de test $i (#priority:$priority #domain:$domain)"
                
                # Ajouter des sous-tâches pour certaines tâches
                if ($i % 10 -eq 0) {
                    for ($j = 1; $j -le 5; $j++) {
                        $subStatus = if ($j % 2 -eq 0) { "[x]" } else { "[ ]" }
                        $content += "  - $subStatus **$i.$j** Sous-tâche $j de la tâche $i"
                    }
                }
            }
            
            # Écrire le contenu dans le fichier
            $content | Out-File -FilePath $testRoadmapPath -Encoding UTF8
            $RoadmapPath = $testRoadmapPath
            
            Write-Host "Fichier de test généré: $RoadmapPath" -ForegroundColor Green
        }
        
        # Vérifier que le fichier existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }
        
        # Définir la fonction de traitement
        $processingFunction = {
            param($Task)
            
            # Simuler un traitement
            Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 50)
            
            # Traiter la tâche
            $processedTask = $Task | Select-Object *
            
            # Ajouter des propriétés supplémentaires
            $processedTask | Add-Member -MemberType NoteProperty -Name "ProcessedDate" -Value (Get-Date)
            $processedTask | Add-Member -MemberType NoteProperty -Name "ProcessedBy" -Value $env:COMPUTERNAME
            $processedTask | Add-Member -MemberType NoteProperty -Name "ProcessingTime" -Value (Get-Random -Minimum 10 -Maximum 50)
            
            return $processedTask
        }
        
        # Tester le traitement parallèle
        Write-Host "Test du traitement parallèle..." -ForegroundColor Cyan
        $startTimeParallel = Get-Date
        
        $parallelResult = Enable-ParallelTaskProcessing -RoadmapPath $RoadmapPath -OutputPath $OutputPath -MaxThreads $MaxThreads -ProcessingFunction $processingFunction
        
        $endTimeParallel = Get-Date
        $durationParallel = $endTimeParallel - $startTimeParallel
        
        Write-Host "Traitement parallèle terminé en $($durationParallel.TotalSeconds) secondes." -ForegroundColor Green
        Write-Host "Nombre de tâches traitées: $($parallelResult.ProcessedTasks)" -ForegroundColor Green
        
        # Tester le traitement séquentiel
        Write-Host "Test du traitement séquentiel..." -ForegroundColor Cyan
        $startTimeSequential = Get-Date
        
        # Analyser la roadmap pour extraire les tâches
        $roadmapContent = Get-Content -Path $RoadmapPath
        $parsedRoadmap = Parse-RoadmapContent -Content $roadmapContent
        $tasks = $parsedRoadmap.Tasks
        
        # Traiter les tâches séquentiellement
        $processedTasksSequential = @()
        
        foreach ($task in $tasks) {
            $processedTask = & $processingFunction $task
            $processedTasksSequential += $processedTask
        }
        
        $endTimeSequential = Get-Date
        $durationSequential = $endTimeSequential - $startTimeSequential
        
        Write-Host "Traitement séquentiel terminé en $($durationSequential.TotalSeconds) secondes." -ForegroundColor Green
        Write-Host "Nombre de tâches traitées: $($processedTasksSequential.Count)" -ForegroundColor Green
        
        # Calculer l'accélération
        $speedup = $durationSequential.TotalSeconds / $durationParallel.TotalSeconds
        
        Write-Host "Accélération: $speedup x" -ForegroundColor Cyan
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            RoadmapPath = $RoadmapPath
            TaskCount = $tasks.Count
            MaxThreads = $parallelResult.MaxThreads
            ParallelDuration = $durationParallel.TotalSeconds
            SequentialDuration = $durationSequential.TotalSeconds
            Speedup = $speedup
            ParallelResult = $parallelResult
            TestDate = Get-Date
        }
        
        # Sauvegarder les résultats
        $resultFilePath = Join-Path -Path $OutputPath -ChildPath "parallel-test-results.json"
        $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFilePath -Encoding UTF8
        
        return $result
    } catch {
        Write-Error "Échec du test de traitement parallèle: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour tester la mise en cache distribuée
function Test-DistributedCaching {
    <#
    .SYNOPSIS
        Teste la mise en cache distribuée.

    .DESCRIPTION
        Cette fonction teste la mise en cache distribuée en mesurant les performances
        des opérations de lecture et d'écriture avec et sans cache.

    .PARAMETER CacheServer
        L'adresse du serveur de cache.
        Par défaut, localhost.

    .PARAMETER CachePort
        Le port du serveur de cache.
        Par défaut, 6379 (port Redis par défaut).

    .PARAMETER IterationCount
        Le nombre d'itérations pour les tests.
        Par défaut, 1000 itérations.

    .PARAMETER DataSize
        La taille des données à mettre en cache en octets.
        Par défaut, 10240 octets (10 Ko).

    .EXAMPLE
        Test-DistributedCaching -CacheServer "redis.example.com" -CachePort 6380 -IterationCount 5000 -DataSize 102400
        Teste la mise en cache distribuée avec un serveur Redis personnalisé, 5000 itérations et des données de 100 Ko.

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
        [int]$IterationCount = 1000,

        [Parameter(Mandatory = $false)]
        [int]$DataSize = 10240
    )

    try {
        # Vérifier si Redis est accessible
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect($CacheServer, $CachePort)
            $tcpClient.Close()
        } catch {
            Write-Error "Impossible de se connecter au serveur Redis à l'adresse $CacheServer:$CachePort. Veuillez vérifier que Redis est en cours d'exécution."
            return $null
        }
        
        # Activer la mise en cache distribuée
        $cache = Enable-DistributedCaching -CacheServer $CacheServer -CachePort $CachePort -CacheKeyPrefix "test:"
        
        if ($null -eq $cache) {
            Write-Error "Échec de l'activation de la mise en cache distribuée."
            return $null
        }
        
        Write-Host "Mise en cache distribuée activée." -ForegroundColor Green
        Write-Host "Serveur: $($cache.Config.CacheServer):$($cache.Config.CachePort)" -ForegroundColor Green
        Write-Host "Ping: $($cache.Config.PingResult.TotalMilliseconds) ms" -ForegroundColor Green
        
        # Générer des données de test
        $testData = "X" * $DataSize
        
        # Tester les performances d'écriture dans le cache
        Write-Host "Test des performances d'écriture dans le cache..." -ForegroundColor Cyan
        $startTimeWrite = Get-Date
        
        for ($i = 1; $i -le $IterationCount; $i++) {
            $key = "test-key-$i"
            $cache.Set.Invoke($key, $testData)
        }
        
        $endTimeWrite = Get-Date
        $durationWrite = $endTimeWrite - $startTimeWrite
        $writePerSecond = $IterationCount / $durationWrite.TotalSeconds
        
        Write-Host "Écriture de $IterationCount éléments terminée en $($durationWrite.TotalSeconds) secondes." -ForegroundColor Green
        Write-Host "Vitesse d'écriture: $writePerSecond éléments/seconde" -ForegroundColor Green
        
        # Tester les performances de lecture depuis le cache
        Write-Host "Test des performances de lecture depuis le cache..." -ForegroundColor Cyan
        $startTimeRead = Get-Date
        
        for ($i = 1; $i -le $IterationCount; $i++) {
            $key = "test-key-$i"
            $value = $cache.Get.Invoke($key)
        }
        
        $endTimeRead = Get-Date
        $durationRead = $endTimeRead - $startTimeRead
        $readPerSecond = $IterationCount / $durationRead.TotalSeconds
        
        Write-Host "Lecture de $IterationCount éléments terminée en $($durationRead.TotalSeconds) secondes." -ForegroundColor Green
        Write-Host "Vitesse de lecture: $readPerSecond éléments/seconde" -ForegroundColor Green
        
        # Tester les performances sans cache
        Write-Host "Test des performances sans cache..." -ForegroundColor Cyan
        $startTimeNoCache = Get-Date
        
        $noCache = @{}
        
        for ($i = 1; $i -le $IterationCount; $i++) {
            $key = "test-key-$i"
            $noCache[$key] = $testData
        }
        
        for ($i = 1; $i -le $IterationCount; $i++) {
            $key = "test-key-$i"
            $value = $noCache[$key]
        }
        
        $endTimeNoCache = Get-Date
        $durationNoCache = $endTimeNoCache - $startTimeNoCache
        $noCachePerSecond = ($IterationCount * 2) / $durationNoCache.TotalSeconds
        
        Write-Host "Opérations sans cache terminées en $($durationNoCache.TotalSeconds) secondes." -ForegroundColor Green
        Write-Host "Vitesse sans cache: $noCachePerSecond opérations/seconde" -ForegroundColor Green
        
        # Nettoyer le cache
        $keysDeleted = $cache.Clear.Invoke("test-key-*")
        Write-Host "$keysDeleted clés supprimées du cache." -ForegroundColor Green
        
        # Fermer la connexion
        $cache.Close.Invoke()
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            CacheServer = $cache.Config.CacheServer
            CachePort = $cache.Config.CachePort
            IterationCount = $IterationCount
            DataSize = $DataSize
            WriteTime = $durationWrite.TotalSeconds
            ReadTime = $durationRead.TotalSeconds
            NoCacheTime = $durationNoCache.TotalSeconds
            WritePerSecond = $writePerSecond
            ReadPerSecond = $readPerSecond
            NoCachePerSecond = $noCachePerSecond
            TestDate = Get-Date
        }
        
        return $result
    } catch {
        Write-Error "Échec du test de mise en cache distribuée: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour tester le clustering Qdrant
function Test-QdrantClustering {
    <#
    .SYNOPSIS
        Teste le clustering Qdrant.

    .DESCRIPTION
        Cette fonction teste le clustering Qdrant en mesurant les performances
        des opérations d'insertion et de recherche avec différentes configurations de cluster.

    .PARAMETER ClusterNodes
        Les adresses des nœuds du cluster Qdrant.
        Par défaut, un seul nœud sur localhost.

    .PARAMETER VectorCount
        Le nombre de vecteurs à insérer pour les tests.
        Par défaut, 1000 vecteurs.

    .PARAMETER VectorSize
        La taille des vecteurs.
        Par défaut, 1536 (taille des vecteurs OpenAI).

    .PARAMETER SearchCount
        Le nombre de recherches à effectuer pour les tests.
        Par défaut, 100 recherches.

    .EXAMPLE
        Test-QdrantClustering -ClusterNodes @("http://qdrant1:6333", "http://qdrant2:6333") -VectorCount 5000 -SearchCount 500
        Teste le clustering Qdrant avec deux nœuds, 5000 vecteurs et 500 recherches.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$ClusterNodes = @("http://localhost:6333"),

        [Parameter(Mandatory = $false)]
        [int]$VectorCount = 1000,

        [Parameter(Mandatory = $false)]
        [int]$VectorSize = 1536,

        [Parameter(Mandatory = $false)]
        [int]$SearchCount = 100
    )

    try {
        # Vérifier si Qdrant est accessible
        $qdrantAccessible = $false
        
        foreach ($node in $ClusterNodes) {
            try {
                $response = Invoke-RestMethod -Uri "$node/health" -Method Get
                
                if ($response.status -eq "ok") {
                    $qdrantAccessible = $true
                    break
                }
            } catch {
                # Continuer avec le nœud suivant
            }
        }
        
        if (-not $qdrantAccessible) {
            Write-Error "Aucun nœud Qdrant n'est accessible. Veuillez vérifier que Qdrant est en cours d'exécution."
            return $null
        }
        
        # Activer le clustering Qdrant
        $collectionName = "test-collection-" + [Guid]::NewGuid().ToString("N").Substring(0, 8)
        $cluster = Enable-QdrantClustering -ClusterNodes $ClusterNodes -CollectionName $collectionName -VectorSize $VectorSize
        
        if ($null -eq $cluster) {
            Write-Error "Échec de l'activation du clustering Qdrant."
            return $null
        }
        
        Write-Host "Clustering Qdrant activé." -ForegroundColor Green
        Write-Host "Nœuds: $($cluster.Config.ClusterNodes -join ', ')" -ForegroundColor Green
        Write-Host "Collection: $($cluster.Config.CollectionName)" -ForegroundColor Green
        
        # Générer des vecteurs de test
        Write-Host "Génération de $VectorCount vecteurs de test..." -ForegroundColor Cyan
        $vectors = @()
        
        for ($i = 1; $i -le $VectorCount; $i++) {
            $vector = @()
            
            for ($j = 1; $j -le $VectorSize; $j++) {
                $vector += [Math]::Round([Math]::Sin($i * $j * 0.01), 6)
            }
            
            $vectors += [PSCustomObject]@{
                id = $i
                vector = $vector
                payload = @{
                    text = "Texte de test $i"
                    category = "Catégorie " + ($i % 10)
                    tags = @("tag1", "tag2", "tag" + ($i % 5))
                }
            }
            
            if ($i % 100 -eq 0) {
                Write-Host "  $i vecteurs générés..." -ForegroundColor Yellow
            }
        }
        
        # Insérer les vecteurs par lots
        Write-Host "Insertion des vecteurs dans Qdrant..." -ForegroundColor Cyan
        $batchSize = 100
        $batchCount = [Math]::Ceiling($VectorCount / $batchSize)
        $startTimeInsert = Get-Date
        
        for ($i = 0; $i -lt $batchCount; $i++) {
            $startIndex = $i * $batchSize
            $endIndex = [Math]::Min(($i + 1) * $batchSize - 1, $VectorCount - 1)
            $batch = $vectors[$startIndex..$endIndex]
            
            $result = $cluster.UpsertPoints.Invoke($batch)
            
            Write-Host "  Lot $($i + 1)/$batchCount inséré." -ForegroundColor Yellow
        }
        
        $endTimeInsert = Get-Date
        $durationInsert = $endTimeInsert - $startTimeInsert
        $insertPerSecond = $VectorCount / $durationInsert.TotalSeconds
        
        Write-Host "Insertion de $VectorCount vecteurs terminée en $($durationInsert.TotalSeconds) secondes." -ForegroundColor Green
        Write-Host "Vitesse d'insertion: $insertPerSecond vecteurs/seconde" -ForegroundColor Green
        
        # Effectuer des recherches
        Write-Host "Exécution de $SearchCount recherches..." -ForegroundColor Cyan
        $startTimeSearch = Get-Date
        $searchResults = @()
        
        for ($i = 1; $i -le $SearchCount; $i++) {
            # Générer un vecteur de recherche aléatoire
            $searchVector = @()
            
            for ($j = 1; $j -le $VectorSize; $j++) {
                $searchVector += [Math]::Round([Math]::Sin($i * $j * 0.02), 6)
            }
            
            # Effectuer la recherche
            $result = $cluster.SearchPoints.Invoke($searchVector, 10)
            $searchResults += $result
            
            if ($i % 10 -eq 0) {
                Write-Host "  $i recherches effectuées..." -ForegroundColor Yellow
            }
        }
        
        $endTimeSearch = Get-Date
        $durationSearch = $endTimeSearch - $startTimeSearch
        $searchPerSecond = $SearchCount / $durationSearch.TotalSeconds
        
        Write-Host "Exécution de $SearchCount recherches terminée en $($durationSearch.TotalSeconds) secondes." -ForegroundColor Green
        Write-Host "Vitesse de recherche: $searchPerSecond recherches/seconde" -ForegroundColor Green
        
        # Supprimer la collection
        $headers = @{
            "Content-Type" = "application/json"
        }
        
        try {
            $response = Invoke-RestMethod -Uri "$($cluster.Config.PrimaryNode)/collections/$($cluster.Config.CollectionName)" -Method Delete -Headers $headers
            Write-Host "Collection supprimée." -ForegroundColor Green
        } catch {
            Write-Warning "Échec de la suppression de la collection: $($_.Exception.Message)"
        }
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            ClusterNodes = $cluster.Config.ClusterNodes
            VectorCount = $VectorCount
            VectorSize = $VectorSize
            SearchCount = $SearchCount
            InsertTime = $durationInsert.TotalSeconds
            SearchTime = $durationSearch.TotalSeconds
            InsertPerSecond = $insertPerSecond
            SearchPerSecond = $searchPerSecond
            TestDate = Get-Date
        }
        
        return $result
    } catch {
        Write-Error "Échec du test de clustering Qdrant: $($_.Exception.Message)"
        return $null
    }
}

# Exécuter les tests
Write-Host "=== TESTS DE L'ARCHITECTURE DISTRIBUÉE ===" -ForegroundColor Cyan
Write-Host

# Test du traitement parallèle des tâches
Write-Host "=== TEST DU TRAITEMENT PARALLÈLE DES TÂCHES ===" -ForegroundColor Cyan
$parallelResult = Test-ParallelTaskProcessing -TaskCount 500 -MaxThreads 4
Write-Host

# Test de la mise en cache distribuée (si Redis est disponible)
Write-Host "=== TEST DE LA MISE EN CACHE DISTRIBUÉE ===" -ForegroundColor Cyan
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect("localhost", 6379)
    $tcpClient.Close()
    
    $cacheResult = Test-DistributedCaching -IterationCount 500 -DataSize 5120
} catch {
    Write-Warning "Redis n'est pas disponible. Test de mise en cache distribuée ignoré."
}
Write-Host

# Test du clustering Qdrant (si Qdrant est disponible)
Write-Host "=== TEST DU CLUSTERING QDRANT ===" -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "http://localhost:6333/health" -Method Get
    
    if ($response.status -eq "ok") {
        $qdrantResult = Test-QdrantClustering -VectorCount 200 -SearchCount 20
    } else {
        Write-Warning "Qdrant n'est pas disponible. Test de clustering Qdrant ignoré."
    }
} catch {
    Write-Warning "Qdrant n'est pas disponible. Test de clustering Qdrant ignoré."
}

# Afficher les résultats
Write-Host "=== RÉSUMÉ DES TESTS ===" -ForegroundColor Cyan
Write-Host

if ($null -ne $parallelResult) {
    Write-Host "Traitement parallèle des tâches:" -ForegroundColor Yellow
    Write-Host "  Accélération: $($parallelResult.Speedup) x" -ForegroundColor Green
    Write-Host "  Durée parallèle: $($parallelResult.ParallelDuration) secondes" -ForegroundColor Green
    Write-Host "  Durée séquentielle: $($parallelResult.SequentialDuration) secondes" -ForegroundColor Green
    Write-Host
}

if ($null -ne $cacheResult) {
    Write-Host "Mise en cache distribuée:" -ForegroundColor Yellow
    Write-Host "  Vitesse d'écriture: $($cacheResult.WritePerSecond) éléments/seconde" -ForegroundColor Green
    Write-Host "  Vitesse de lecture: $($cacheResult.ReadPerSecond) éléments/seconde" -ForegroundColor Green
    Write-Host "  Vitesse sans cache: $($cacheResult.NoCachePerSecond) opérations/seconde" -ForegroundColor Green
    Write-Host
}

if ($null -ne $qdrantResult) {
    Write-Host "Clustering Qdrant:" -ForegroundColor Yellow
    Write-Host "  Vitesse d'insertion: $($qdrantResult.InsertPerSecond) vecteurs/seconde" -ForegroundColor Green
    Write-Host "  Vitesse de recherche: $($qdrantResult.SearchPerSecond) recherches/seconde" -ForegroundColor Green
    Write-Host
}

# Optimize-RoadmapParsing.ps1
# Module pour l'optimisation des algorithmes de parsing pour les fichiers volumineux
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Fournit des fonctions pour optimiser les algorithmes de parsing pour les fichiers volumineux.

.DESCRIPTION
    Ce module fournit des fonctions pour optimiser les algorithmes de parsing pour les fichiers volumineux,
    notamment le parsing incrémental, le parsing par flux (streaming) et le parsing parallèle.

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

# Fonction principale pour optimiser le parsing des roadmaps
function Optimize-RoadmapParsing {
    <#
    .SYNOPSIS
        Optimise le parsing des roadmaps volumineuses.

    .DESCRIPTION
        Cette fonction optimise le parsing des roadmaps volumineuses en utilisant
        des techniques avancées comme le parsing incrémental, le parsing par flux et le parsing parallèle.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats du parsing.
        Si non spécifié, un dossier temporaire est utilisé.

    .PARAMETER ParsingMode
        Le mode de parsing à utiliser (Incremental, Streaming, Parallel).
        Par défaut, le mode est déterminé automatiquement en fonction de la taille du fichier.

    .PARAMETER MaxMemoryUsageMB
        L'utilisation maximale de mémoire en mégaoctets.
        Par défaut, 1024 Mo (1 Go).

    .PARAMETER MaxThreads
        Le nombre maximum de threads à utiliser pour le parsing parallèle.
        Par défaut, le nombre de processeurs logiques disponibles.

    .PARAMETER CachePath
        Le chemin où stocker le cache des résultats de parsing.
        Si non spécifié, un dossier temporaire est utilisé.

    .EXAMPLE
        Optimize-RoadmapParsing -RoadmapPath "C:\Roadmaps\large-roadmap.md" -ParsingMode "Parallel" -MaxThreads 4
        Optimise le parsing d'une roadmap volumineuse en utilisant le mode parallèle avec 4 threads.

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
        [ValidateSet("Auto", "Incremental", "Streaming", "Parallel")]
        [string]$ParsingMode = "Auto",

        [Parameter(Mandatory = $false)]
        [int]$MaxMemoryUsageMB = 1024,

        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0,

        [Parameter(Mandatory = $false)]
        [string]$CachePath = ""
    )

    try {
        # Vérifier que le fichier de roadmap existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path $env:TEMP -ChildPath "RoadmapParsingResults"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Déterminer le chemin du cache
        if ([string]::IsNullOrEmpty($CachePath)) {
            $CachePath = Join-Path -Path $env:TEMP -ChildPath "RoadmapParsingCache"
        }
        
        # Créer le dossier de cache s'il n'existe pas
        if (-not (Test-Path $CachePath)) {
            New-Item -Path $CachePath -ItemType Directory -Force | Out-Null
        }
        
        # Obtenir les informations sur le fichier
        $fileInfo = Get-Item -Path $RoadmapPath
        $fileSize = $fileInfo.Length
        $fileSizeMB = $fileSize / 1MB
        
        # Déterminer le mode de parsing si Auto est spécifié
        if ($ParsingMode -eq "Auto") {
            if ($fileSizeMB -lt 5) {
                $ParsingMode = "Incremental"
            } elseif ($fileSizeMB -lt 20) {
                $ParsingMode = "Streaming"
            } else {
                $ParsingMode = "Parallel"
            }
        }
        
        # Déterminer le nombre de threads si non spécifié
        if ($MaxThreads -le 0) {
            $MaxThreads = [Environment]::ProcessorCount
        }
        
        # Générer un identifiant unique pour cette roadmap
        $roadmapId = [System.IO.Path]::GetFileNameWithoutExtension($RoadmapPath) + "-" + (Get-FileHash -Path $RoadmapPath -Algorithm MD5).Hash.Substring(0, 8)
        
        # Créer l'objet de configuration
        $config = [PSCustomObject]@{
            RoadmapId = $roadmapId
            RoadmapPath = $RoadmapPath
            OutputPath = $OutputPath
            ParsingMode = $ParsingMode
            MaxMemoryUsageMB = $MaxMemoryUsageMB
            MaxThreads = $MaxThreads
            CachePath = $CachePath
            FileSize = $fileSize
            FileSizeMB = $fileSizeMB
            StartTime = Get-Date
        }
        
        # Exécuter le parsing selon le mode spécifié
        $result = $null
        
        switch ($ParsingMode) {
            "Incremental" {
                $result = Invoke-IncrementalParsing -Config $config
            }
            "Streaming" {
                $result = Invoke-StreamingParsing -Config $config
            }
            "Parallel" {
                $result = Invoke-ParallelParsing -Config $config
            }
        }
        
        # Ajouter les informations de performance
        $endTime = Get-Date
        $duration = $endTime - $config.StartTime
        
        $result | Add-Member -MemberType NoteProperty -Name "Duration" -Value $duration
        $result | Add-Member -MemberType NoteProperty -Name "ProcessingSpeedMBPerSecond" -Value ($fileSizeMB / $duration.TotalSeconds)
        
        return $result
    } catch {
        Write-Error "Échec de l'optimisation du parsing: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour le parsing incrémental
function Invoke-IncrementalParsing {
    <#
    .SYNOPSIS
        Effectue le parsing incrémental d'une roadmap.

    .DESCRIPTION
        Cette fonction effectue le parsing incrémental d'une roadmap,
        en traitant le fichier par petits incréments pour minimiser l'utilisation de la mémoire.

    .PARAMETER Config
        L'objet de configuration créé par Optimize-RoadmapParsing.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Config
    )

    try {
        Write-Verbose "Démarrage du parsing incrémental pour $($Config.RoadmapPath)"
        
        # Créer le dossier de résultats spécifique à cette roadmap
        $resultPath = Join-Path -Path $Config.OutputPath -ChildPath $Config.RoadmapId
        if (-not (Test-Path $resultPath)) {
            New-Item -Path $resultPath -ItemType Directory -Force | Out-Null
        }
        
        # Créer le dossier de cache spécifique à cette roadmap
        $cachePath = Join-Path -Path $Config.CachePath -ChildPath $Config.RoadmapId
        if (-not (Test-Path $cachePath)) {
            New-Item -Path $cachePath -ItemType Directory -Force | Out-Null
        }
        
        # Initialiser les variables
        $tasks = @()
        $headers = @()
        $currentLevel = 0
        $currentTask = $null
        $lineNumber = 0
        $batchSize = 1000  # Nombre de lignes à traiter par incrément
        
        # Ouvrir le fichier en mode streaming
        $reader = [System.IO.File]::OpenText($Config.RoadmapPath)
        
        try {
            $batch = @()
            $batchNumber = 0
            
            # Lire le fichier par incréments
            while (-not $reader.EndOfStream) {
                $line = $reader.ReadLine()
                $lineNumber++
                $batch += $line
                
                # Traiter le batch lorsqu'il atteint la taille spécifiée
                if ($batch.Count -ge $batchSize -or $reader.EndOfStream) {
                    Write-Verbose "Traitement du batch $batchNumber (lignes $($lineNumber - $batch.Count + 1) à $lineNumber)"
                    
                    # Traiter le batch
                    $batchTasks = Parse-RoadmapBatch -Batch $batch -StartLineNumber ($lineNumber - $batch.Count + 1) -CurrentLevel $currentLevel -CurrentTask $currentTask
                    
                    # Mettre à jour les variables
                    $tasks += $batchTasks.Tasks
                    $headers += $batchTasks.Headers
                    $currentLevel = $batchTasks.CurrentLevel
                    $currentTask = $batchTasks.CurrentTask
                    
                    # Sauvegarder les résultats intermédiaires
                    $batchResultPath = Join-Path -Path $cachePath -ChildPath "batch-$batchNumber.json"
                    $batchTasks | ConvertTo-Json -Depth 10 | Out-File -FilePath $batchResultPath -Encoding UTF8
                    
                    # Réinitialiser le batch
                    $batch = @()
                    $batchNumber++
                    
                    # Libérer la mémoire
                    [System.GC]::Collect()
                }
            }
        } finally {
            # Fermer le fichier
            $reader.Close()
        }
        
        # Fusionner les résultats
        $result = [PSCustomObject]@{
            RoadmapId = $Config.RoadmapId
            RoadmapPath = $Config.RoadmapPath
            Tasks = $tasks
            Headers = $headers
            TotalLines = $lineNumber
            TotalTasks = $tasks.Count
            TotalHeaders = $headers.Count
            ParsingMode = "Incremental"
            BatchCount = $batchNumber
        }
        
        # Sauvegarder les résultats
        $resultFilePath = Join-Path -Path $resultPath -ChildPath "parsing-result.json"
        $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFilePath -Encoding UTF8
        
        return $result
    } catch {
        Write-Error "Échec du parsing incrémental: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour le parsing par flux (streaming)
function Invoke-StreamingParsing {
    <#
    .SYNOPSIS
        Effectue le parsing par flux (streaming) d'une roadmap.

    .DESCRIPTION
        Cette fonction effectue le parsing par flux (streaming) d'une roadmap,
        en traitant le fichier ligne par ligne sans le charger entièrement en mémoire.

    .PARAMETER Config
        L'objet de configuration créé par Optimize-RoadmapParsing.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Config
    )

    try {
        Write-Verbose "Démarrage du parsing par flux pour $($Config.RoadmapPath)"
        
        # Créer le dossier de résultats spécifique à cette roadmap
        $resultPath = Join-Path -Path $Config.OutputPath -ChildPath $Config.RoadmapId
        if (-not (Test-Path $resultPath)) {
            New-Item -Path $resultPath -ItemType Directory -Force | Out-Null
        }
        
        # Initialiser les variables
        $tasks = @()
        $headers = @()
        $taskStack = @()
        $lineNumber = 0
        
        # Créer les fichiers de sortie en streaming
        $tasksFilePath = Join-Path -Path $resultPath -ChildPath "tasks.jsonl"
        $headersFilePath = Join-Path -Path $resultPath -ChildPath "headers.jsonl"
        
        # Supprimer les fichiers s'ils existent déjà
        if (Test-Path $tasksFilePath) { Remove-Item -Path $tasksFilePath -Force }
        if (Test-Path $headersFilePath) { Remove-Item -Path $headersFilePath -Force }
        
        # Ouvrir les fichiers en écriture
        $tasksWriter = [System.IO.StreamWriter]::new($tasksFilePath, $false, [System.Text.Encoding]::UTF8)
        $headersWriter = [System.IO.StreamWriter]::new($headersFilePath, $false, [System.Text.Encoding]::UTF8)
        
        # Ouvrir le fichier en lecture
        $reader = [System.IO.File]::OpenText($Config.RoadmapPath)
        
        try {
            # Lire le fichier ligne par ligne
            while (-not $reader.EndOfStream) {
                $line = $reader.ReadLine()
                $lineNumber++
                
                # Analyser la ligne
                $lineResult = Parse-RoadmapLine -Line $line -LineNumber $lineNumber -TaskStack $taskStack
                
                # Mettre à jour les variables
                $taskStack = $lineResult.TaskStack
                
                # Écrire les tâches et les en-têtes dans les fichiers
                if ($null -ne $lineResult.Task) {
                    $taskJson = $lineResult.Task | ConvertTo-Json -Compress
                    $tasksWriter.WriteLine($taskJson)
                    $tasks += $lineResult.Task
                }
                
                if ($null -ne $lineResult.Header) {
                    $headerJson = $lineResult.Header | ConvertTo-Json -Compress
                    $headersWriter.WriteLine($headerJson)
                    $headers += $lineResult.Header
                }
                
                # Libérer la mémoire périodiquement
                if ($lineNumber % 10000 -eq 0) {
                    [System.GC]::Collect()
                }
            }
        } finally {
            # Fermer les fichiers
            $reader.Close()
            $tasksWriter.Close()
            $headersWriter.Close()
        }
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            RoadmapId = $Config.RoadmapId
            RoadmapPath = $Config.RoadmapPath
            TasksFilePath = $tasksFilePath
            HeadersFilePath = $headersFilePath
            TotalLines = $lineNumber
            TotalTasks = $tasks.Count
            TotalHeaders = $headers.Count
            ParsingMode = "Streaming"
        }
        
        # Sauvegarder les métadonnées
        $metadataFilePath = Join-Path -Path $resultPath -ChildPath "metadata.json"
        $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $metadataFilePath -Encoding UTF8
        
        return $result
    } catch {
        Write-Error "Échec du parsing par flux: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour le parsing parallèle
function Invoke-ParallelParsing {
    <#
    .SYNOPSIS
        Effectue le parsing parallèle d'une roadmap.

    .DESCRIPTION
        Cette fonction effectue le parsing parallèle d'une roadmap,
        en divisant le fichier en chunks qui sont traités en parallèle.

    .PARAMETER Config
        L'objet de configuration créé par Optimize-RoadmapParsing.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Config
    )

    try {
        Write-Verbose "Démarrage du parsing parallèle pour $($Config.RoadmapPath)"
        
        # Créer le dossier de résultats spécifique à cette roadmap
        $resultPath = Join-Path -Path $Config.OutputPath -ChildPath $Config.RoadmapId
        if (-not (Test-Path $resultPath)) {
            New-Item -Path $resultPath -ItemType Directory -Force | Out-Null
        }
        
        # Créer le dossier de chunks
        $chunksPath = Join-Path -Path $resultPath -ChildPath "chunks"
        if (-not (Test-Path $chunksPath)) {
            New-Item -Path $chunksPath -ItemType Directory -Force | Out-Null
        } else {
            # Nettoyer le dossier
            Remove-Item -Path (Join-Path -Path $chunksPath -ChildPath "*") -Force
        }
        
        # Diviser le fichier en chunks
        $chunkSize = 5000  # Nombre de lignes par chunk
        $lines = Get-Content -Path $Config.RoadmapPath
        $totalLines = $lines.Count
        $totalChunks = [Math]::Ceiling($totalLines / $chunkSize)
        
        Write-Verbose "Fichier divisé en $totalChunks chunks de $chunkSize lignes"
        
        # Créer les chunks
        for ($i = 0; $i -lt $totalChunks; $i++) {
            $startLine = $i * $chunkSize
            $endLine = [Math]::Min(($i + 1) * $chunkSize - 1, $totalLines - 1)
            $chunkLines = $lines[$startLine..$endLine]
            
            $chunkPath = Join-Path -Path $chunksPath -ChildPath "chunk-$i.md"
            $chunkLines | Out-File -FilePath $chunkPath -Encoding UTF8
        }
        
        # Traiter les chunks en parallèle
        $chunks = Get-ChildItem -Path $chunksPath -Filter "chunk-*.md"
        $results = @()
        
        # Utiliser ForEach-Object -Parallel si PowerShell 7+, sinon utiliser des runspaces
        if ($PSVersionTable.PSVersion.Major -ge 7) {
            $results = $chunks | ForEach-Object -Parallel {
                $chunkPath = $_.FullName
                $chunkId = [int]($_.BaseName -replace "chunk-", "")
                $startLine = $chunkId * 5000 + 1
                
                # Analyser le chunk
                $chunkResult = & {
                    # Importer le module de parsing
                    $scriptPath = $using:scriptPath
                    $parseRoadmapPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "utils\Parse-Roadmap.ps1"
                    . $parseRoadmapPath
                    
                    # Analyser le chunk
                    $chunkContent = Get-Content -Path $chunkPath
                    $parsedChunk = Parse-RoadmapContent -Content $chunkContent -StartLineNumber $startLine
                    
                    return [PSCustomObject]@{
                        ChunkId = $chunkId
                        StartLine = $startLine
                        EndLine = $startLine + $chunkContent.Count - 1
                        Tasks = $parsedChunk.Tasks
                        Headers = $parsedChunk.Headers
                    }
                }
                
                return $chunkResult
            } -ThrottleLimit $Config.MaxThreads
        } else {
            # Utiliser des runspaces pour PowerShell 5.1
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, $Config.MaxThreads)
            $runspacePool.Open()
            
            $runspaces = @()
            
            foreach ($chunk in $chunks) {
                $chunkPath = $chunk.FullName
                $chunkId = [int]($chunk.BaseName -replace "chunk-", "")
                $startLine = $chunkId * 5000 + 1
                
                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $runspacePool
                
                [void]$powershell.AddScript({
                    param($chunkPath, $chunkId, $startLine, $parseRoadmapPath)
                    
                    # Importer le module de parsing
                    . $parseRoadmapPath
                    
                    # Analyser le chunk
                    $chunkContent = Get-Content -Path $chunkPath
                    $parsedChunk = Parse-RoadmapContent -Content $chunkContent -StartLineNumber $startLine
                    
                    return [PSCustomObject]@{
                        ChunkId = $chunkId
                        StartLine = $startLine
                        EndLine = $startLine + $chunkContent.Count - 1
                        Tasks = $parsedChunk.Tasks
                        Headers = $parsedChunk.Headers
                    }
                })
                
                [void]$powershell.AddParameter("chunkPath", $chunkPath)
                [void]$powershell.AddParameter("chunkId", $chunkId)
                [void]$powershell.AddParameter("startLine", $startLine)
                [void]$powershell.AddParameter("parseRoadmapPath", $parseRoadmapPath)
                
                $runspaces += [PSCustomObject]@{
                    Powershell = $powershell
                    AsyncResult = $powershell.BeginInvoke()
                }
            }
            
            # Récupérer les résultats
            foreach ($runspace in $runspaces) {
                $results += $runspace.Powershell.EndInvoke($runspace.AsyncResult)
                $runspace.Powershell.Dispose()
            }
            
            $runspacePool.Close()
            $runspacePool.Dispose()
        }
        
        # Fusionner les résultats
        $tasks = @()
        $headers = @()
        
        foreach ($result in ($results | Sort-Object -Property ChunkId)) {
            $tasks += $result.Tasks
            $headers += $result.Headers
        }
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            RoadmapId = $Config.RoadmapId
            RoadmapPath = $Config.RoadmapPath
            Tasks = $tasks
            Headers = $headers
            TotalLines = $totalLines
            TotalTasks = $tasks.Count
            TotalHeaders = $headers.Count
            ParsingMode = "Parallel"
            TotalChunks = $totalChunks
            ChunkSize = $chunkSize
        }
        
        # Sauvegarder les résultats
        $resultFilePath = Join-Path -Path $resultPath -ChildPath "parsing-result.json"
        $result | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFilePath -Encoding UTF8
        
        return $result
    } catch {
        Write-Error "Échec du parsing parallèle: $($_.Exception.Message)"
        return $null
    }
}

# Optimize-RoadmapPerformance.ps1
# Module pour l'optimisation des performances des roadmaps volumineuses
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Fournit des fonctions pour optimiser les performances des roadmaps volumineuses.

.DESCRIPTION
    Ce module fournit des fonctions pour optimiser les performances des roadmaps volumineuses,
    notamment le chargement paresseux (lazy loading), le chunking adaptatif et l'optimisation des algorithmes de parsing.

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

# Fonction pour implémenter le chargement paresseux (lazy loading)
function Enable-LazyLoading {
    <#
    .SYNOPSIS
        Active le chargement paresseux pour les roadmaps volumineuses.

    .DESCRIPTION
        Cette fonction active le chargement paresseux pour les roadmaps volumineuses,
        permettant de charger uniquement les parties nécessaires de la roadmap à la demande.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER ChunkSize
        La taille des chunks en nombre de lignes.
        Par défaut, 1000 lignes par chunk.

    .PARAMETER CachePath
        Le chemin où stocker le cache des chunks.
        Si non spécifié, un dossier temporaire est utilisé.

    .PARAMETER PreloadSections
        Les sections à précharger (par exemple, les en-têtes).
        Par défaut, les 100 premières lignes sont préchargées.

    .EXAMPLE
        Enable-LazyLoading -RoadmapPath "C:\Roadmaps\large-roadmap.md" -ChunkSize 500 -PreloadSections 200
        Active le chargement paresseux pour une roadmap volumineuse avec des chunks de 500 lignes et précharge les 200 premières lignes.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [int]$ChunkSize = 1000,

        [Parameter(Mandatory = $false)]
        [string]$CachePath = "",

        [Parameter(Mandatory = $false)]
        [int]$PreloadSections = 100
    )

    try {
        # Vérifier que le fichier de roadmap existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }
        
        # Déterminer le chemin du cache
        if ([string]::IsNullOrEmpty($CachePath)) {
            $CachePath = Join-Path -Path $env:TEMP -ChildPath "RoadmapCache"
        }
        
        # Créer le dossier de cache s'il n'existe pas
        if (-not (Test-Path $CachePath)) {
            New-Item -Path $CachePath -ItemType Directory -Force | Out-Null
        }
        
        # Générer un identifiant unique pour cette roadmap
        $roadmapId = [System.IO.Path]::GetFileNameWithoutExtension($RoadmapPath) + "-" + (Get-FileHash -Path $RoadmapPath -Algorithm MD5).Hash.Substring(0, 8)
        $roadmapCachePath = Join-Path -Path $CachePath -ChildPath $roadmapId
        
        # Créer le dossier de cache spécifique à cette roadmap
        if (-not (Test-Path $roadmapCachePath)) {
            New-Item -Path $roadmapCachePath -ItemType Directory -Force | Out-Null
        }
        
        # Obtenir les informations sur le fichier
        $fileInfo = Get-Item -Path $RoadmapPath
        $fileSize = $fileInfo.Length
        $lastModified = $fileInfo.LastWriteTime
        
        # Créer le fichier d'index
        $indexPath = Join-Path -Path $roadmapCachePath -ChildPath "index.json"
        $indexExists = Test-Path $indexPath
        
        if ($indexExists) {
            # Charger l'index existant
            $index = Get-Content -Path $indexPath -Raw | ConvertFrom-Json
            
            # Vérifier si le fichier a été modifié depuis la dernière indexation
            if ($index.LastModified -ne $lastModified.ToString("o") -or $index.FileSize -ne $fileSize) {
                # Le fichier a été modifié, recréer l'index
                $indexExists = $false
            }
        }
        
        if (-not $indexExists) {
            # Compter le nombre total de lignes
            $totalLines = (Get-Content -Path $RoadmapPath).Count
            
            # Calculer le nombre de chunks
            $totalChunks = [Math]::Ceiling($totalLines / $ChunkSize)
            
            # Créer l'index
            $index = [PSCustomObject]@{
                RoadmapId = $roadmapId
                RoadmapPath = $RoadmapPath
                FileSize = $fileSize
                LastModified = $lastModified.ToString("o")
                TotalLines = $totalLines
                ChunkSize = $ChunkSize
                TotalChunks = $totalChunks
                Chunks = @()
            }
            
            # Diviser le fichier en chunks
            for ($i = 0; $i -lt $totalChunks; $i++) {
                $startLine = $i * $ChunkSize + 1
                $endLine = [Math]::Min(($i + 1) * $ChunkSize, $totalLines)
                
                $chunkInfo = [PSCustomObject]@{
                    ChunkId = $i
                    StartLine = $startLine
                    EndLine = $endLine
                    Loaded = $false
                    CachePath = Join-Path -Path $roadmapCachePath -ChildPath "chunk-$i.json"
                }
                
                $index.Chunks += $chunkInfo
            }
            
            # Sauvegarder l'index
            $index | ConvertTo-Json -Depth 10 | Out-File -FilePath $indexPath -Encoding UTF8
        }
        
        # Précharger les sections spécifiées
        $preloadChunks = $index.Chunks | Where-Object { $_.StartLine -le $PreloadSections }
        
        foreach ($chunk in $preloadChunks) {
            # Vérifier si le chunk est déjà en cache
            if (-not (Test-Path $chunk.CachePath)) {
                # Extraire les lignes du chunk
                $lines = Get-Content -Path $RoadmapPath -TotalCount $chunk.EndLine | Select-Object -Skip ($chunk.StartLine - 1)
                
                # Créer l'objet de chunk
                $chunkData = [PSCustomObject]@{
                    ChunkId = $chunk.ChunkId
                    StartLine = $chunk.StartLine
                    EndLine = $chunk.EndLine
                    Content = $lines
                }
                
                # Sauvegarder le chunk
                $chunkData | ConvertTo-Json -Depth 10 | Out-File -FilePath $chunk.CachePath -Encoding UTF8
            }
            
            # Marquer le chunk comme chargé
            $chunk.Loaded = $true
        }
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            RoadmapId = $index.RoadmapId
            RoadmapPath = $index.RoadmapPath
            TotalLines = $index.TotalLines
            ChunkSize = $index.ChunkSize
            TotalChunks = $index.TotalChunks
            CachePath = $roadmapCachePath
            IndexPath = $indexPath
            Index = $index
        }
        
        return $result
    } catch {
        Write-Error "Échec de l'activation du chargement paresseux: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour charger un chunk spécifique
function Get-RoadmapChunk {
    <#
    .SYNOPSIS
        Charge un chunk spécifique d'une roadmap.

    .DESCRIPTION
        Cette fonction charge un chunk spécifique d'une roadmap,
        permettant d'accéder à une partie de la roadmap sans charger l'intégralité du fichier.

    .PARAMETER LazyLoadingContext
        Le contexte de chargement paresseux créé par Enable-LazyLoading.

    .PARAMETER ChunkId
        L'identifiant du chunk à charger.

    .PARAMETER LineRange
        La plage de lignes à charger (par exemple, 1000-2000).
        Si spécifié, les chunks contenant ces lignes sont chargés.

    .EXAMPLE
        $context = Enable-LazyLoading -RoadmapPath "C:\Roadmaps\large-roadmap.md"
        Get-RoadmapChunk -LazyLoadingContext $context -ChunkId 2
        Charge le troisième chunk de la roadmap.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByChunkId")]
        [Parameter(Mandatory = $true, ParameterSetName = "ByLineRange")]
        [PSObject]$LazyLoadingContext,

        [Parameter(Mandatory = $true, ParameterSetName = "ByChunkId")]
        [int]$ChunkId,

        [Parameter(Mandatory = $true, ParameterSetName = "ByLineRange")]
        [int[]]$LineRange
    )

    try {
        # Déterminer les chunks à charger
        $chunksToLoad = @()
        
        if ($PSCmdlet.ParameterSetName -eq "ByChunkId") {
            # Vérifier que le chunk existe
            if ($ChunkId -lt 0 -or $ChunkId -ge $LazyLoadingContext.TotalChunks) {
                Write-Error "Chunk invalide: $ChunkId. La plage valide est 0-$($LazyLoadingContext.TotalChunks - 1)."
                return $null
            }
            
            $chunksToLoad += $LazyLoadingContext.Index.Chunks[$ChunkId]
        } else {
            # Vérifier que la plage est valide
            if ($LineRange.Count -ne 2 -or $LineRange[0] -lt 1 -or $LineRange[1] -gt $LazyLoadingContext.TotalLines -or $LineRange[0] -gt $LineRange[1]) {
                Write-Error "Plage de lignes invalide: $LineRange. La plage valide est 1-$($LazyLoadingContext.TotalLines)."
                return $null
            }
            
            # Trouver les chunks qui contiennent les lignes spécifiées
            $startLine = $LineRange[0]
            $endLine = $LineRange[1]
            
            $chunksToLoad = $LazyLoadingContext.Index.Chunks | Where-Object {
                ($_.StartLine -le $endLine) -and ($_.EndLine -ge $startLine)
            }
        }
        
        # Charger les chunks
        $result = @()
        
        foreach ($chunk in $chunksToLoad) {
            # Vérifier si le chunk est déjà en cache
            if (-not (Test-Path $chunk.CachePath)) {
                # Extraire les lignes du chunk
                $lines = Get-Content -Path $LazyLoadingContext.RoadmapPath -TotalCount $chunk.EndLine | Select-Object -Skip ($chunk.StartLine - 1)
                
                # Créer l'objet de chunk
                $chunkData = [PSCustomObject]@{
                    ChunkId = $chunk.ChunkId
                    StartLine = $chunk.StartLine
                    EndLine = $chunk.EndLine
                    Content = $lines
                }
                
                # Sauvegarder le chunk
                $chunkData | ConvertTo-Json -Depth 10 | Out-File -FilePath $chunk.CachePath -Encoding UTF8
                
                $result += $chunkData
            } else {
                # Charger le chunk depuis le cache
                $chunkData = Get-Content -Path $chunk.CachePath -Raw | ConvertFrom-Json
                $result += $chunkData
            }
            
            # Marquer le chunk comme chargé
            $chunk.Loaded = $true
        }
        
        # Si un seul chunk a été demandé, retourner ce chunk
        if ($PSCmdlet.ParameterSetName -eq "ByChunkId") {
            return $result[0]
        }
        
        # Sinon, retourner tous les chunks
        return $result
    } catch {
        Write-Error "Échec du chargement du chunk: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour implémenter le chunking adaptatif
function Invoke-AdaptiveChunking {
    <#
    .SYNOPSIS
        Implémente le chunking adaptatif pour les roadmaps volumineuses.

    .DESCRIPTION
        Cette fonction implémente le chunking adaptatif pour les roadmaps volumineuses,
        permettant de diviser la roadmap en chunks de taille variable en fonction de la structure du document.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les chunks.
        Si non spécifié, un dossier temporaire est utilisé.

    .PARAMETER MinChunkSize
        La taille minimale des chunks en nombre de lignes.
        Par défaut, 100 lignes par chunk.

    .PARAMETER MaxChunkSize
        La taille maximale des chunks en nombre de lignes.
        Par défaut, 2000 lignes par chunk.

    .PARAMETER SectionDelimiters
        Les délimiteurs de section (par exemple, les en-têtes markdown).
        Par défaut, les en-têtes markdown (## Titre).

    .EXAMPLE
        Invoke-AdaptiveChunking -RoadmapPath "C:\Roadmaps\large-roadmap.md" -OutputPath "C:\Chunks" -MinChunkSize 200 -MaxChunkSize 1000
        Divise une roadmap volumineuse en chunks adaptatifs.

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
        [int]$MinChunkSize = 100,

        [Parameter(Mandatory = $false)]
        [int]$MaxChunkSize = 2000,

        [Parameter(Mandatory = $false)]
        [string[]]$SectionDelimiters = @("^## ", "^### ", "^#### ", "^##### ", "^###### ")
    )

    try {
        # Vérifier que le fichier de roadmap existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path $env:TEMP -ChildPath "RoadmapChunks"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Générer un identifiant unique pour cette roadmap
        $roadmapId = [System.IO.Path]::GetFileNameWithoutExtension($RoadmapPath) + "-" + (Get-FileHash -Path $RoadmapPath -Algorithm MD5).Hash.Substring(0, 8)
        $roadmapChunksPath = Join-Path -Path $OutputPath -ChildPath $roadmapId
        
        # Créer le dossier de chunks spécifique à cette roadmap
        if (-not (Test-Path $roadmapChunksPath)) {
            New-Item -Path $roadmapChunksPath -ItemType Directory -Force | Out-Null
        } else {
            # Nettoyer le dossier
            Remove-Item -Path (Join-Path -Path $roadmapChunksPath -ChildPath "*") -Force
        }
        
        # Lire le contenu du fichier
        $lines = Get-Content -Path $RoadmapPath
        $totalLines = $lines.Count
        
        # Initialiser les variables
        $chunks = @()
        $currentChunk = @()
        $currentChunkSize = 0
        $chunkId = 0
        
        # Parcourir les lignes
        for ($i = 0; $i -lt $totalLines; $i++) {
            $line = $lines[$i]
            $isDelimiter = $false
            
            # Vérifier si la ligne est un délimiteur de section
            foreach ($delimiter in $SectionDelimiters) {
                if ($line -match $delimiter) {
                    $isDelimiter = $true
                    break
                }
            }
            
            # Si c'est un délimiteur et que le chunk actuel a atteint la taille minimale,
            # ou si le chunk actuel a atteint la taille maximale, créer un nouveau chunk
            if (($isDelimiter -and $currentChunkSize -ge $MinChunkSize) -or $currentChunkSize -ge $MaxChunkSize) {
                # Sauvegarder le chunk actuel
                if ($currentChunkSize -gt 0) {
                    $chunkPath = Join-Path -Path $roadmapChunksPath -ChildPath "chunk-$chunkId.md"
                    $currentChunk | Out-File -FilePath $chunkPath -Encoding UTF8
                    
                    $chunks += [PSCustomObject]@{
                        ChunkId = $chunkId
                        StartLine = $i - $currentChunkSize + 1
                        EndLine = $i
                        Size = $currentChunkSize
                        Path = $chunkPath
                    }
                    
                    $chunkId++
                    $currentChunk = @()
                    $currentChunkSize = 0
                }
            }
            
            # Ajouter la ligne au chunk actuel
            $currentChunk += $line
            $currentChunkSize++
        }
        
        # Sauvegarder le dernier chunk
        if ($currentChunkSize -gt 0) {
            $chunkPath = Join-Path -Path $roadmapChunksPath -ChildPath "chunk-$chunkId.md"
            $currentChunk | Out-File -FilePath $chunkPath -Encoding UTF8
            
            $chunks += [PSCustomObject]@{
                ChunkId = $chunkId
                StartLine = $totalLines - $currentChunkSize + 1
                EndLine = $totalLines
                Size = $currentChunkSize
                Path = $chunkPath
            }
        }
        
        # Créer l'index
        $index = [PSCustomObject]@{
            RoadmapId = $roadmapId
            RoadmapPath = $RoadmapPath
            TotalLines = $totalLines
            TotalChunks = $chunks.Count
            MinChunkSize = $MinChunkSize
            MaxChunkSize = $MaxChunkSize
            ChunksPath = $roadmapChunksPath
            Chunks = $chunks
        }
        
        # Sauvegarder l'index
        $indexPath = Join-Path -Path $roadmapChunksPath -ChildPath "index.json"
        $index | ConvertTo-Json -Depth 10 | Out-File -FilePath $indexPath -Encoding UTF8
        
        return $index
    } catch {
        Write-Error "Échec du chunking adaptatif: $($_.Exception.Message)"
        return $null
    }
}

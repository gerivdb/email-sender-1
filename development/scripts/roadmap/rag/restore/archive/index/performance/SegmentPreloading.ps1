# SegmentPreloading.ps1
# Script implémentant le préchargement intelligent des segments
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parallelPath = Join-Path -Path $scriptPath -ChildPath "ParallelExecution.ps1"

if (Test-Path -Path $parallelPath) {
    . $parallelPath
} else {
    Write-Error "Le fichier ParallelExecution.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une stratégie de préchargement
class PreloadStrategy {
    # Type de stratégie (All, OnDemand, Predictive)
    [string]$Type
    
    # Constructeur par défaut
    PreloadStrategy() {
        $this.Type = "OnDemand"
    }
    
    # Constructeur avec type
    PreloadStrategy([string]$type) {
        $this.Type = $type
    }
    
    # Méthode pour déterminer les segments à précharger
    [string[]] GetSegmentsToPreload([string[]]$allSegmentIds, [hashtable]$segmentStats) {
        switch ($this.Type) {
            "All" {
                return $allSegmentIds
            }
            "OnDemand" {
                return @()
            }
            "Predictive" {
                # Implémentation par défaut: précharger les segments les plus utilisés
                $sortedSegments = $segmentStats.GetEnumerator() | Sort-Object -Property { $_.Value.access_count } -Descending
                return $sortedSegments | Select-Object -First 3 | ForEach-Object { $_.Key }
            }
            default {
                return @()
            }
        }
    }
}

# Classe pour représenter une stratégie de préchargement prédictive
class PredictivePreloadStrategy : PreloadStrategy {
    # Nombre maximal de segments à précharger
    [int]$MaxSegments
    
    # Seuil d'accès pour précharger un segment
    [int]$AccessThreshold
    
    # Facteur de décroissance pour les accès anciens
    [double]$DecayFactor
    
    # Constructeur par défaut
    PredictivePreloadStrategy() : base("Predictive") {
        $this.MaxSegments = 3
        $this.AccessThreshold = 5
        $this.DecayFactor = 0.9
    }
    
    # Constructeur avec paramètres
    PredictivePreloadStrategy([int]$maxSegments, [int]$accessThreshold, [double]$decayFactor) : base("Predictive") {
        $this.MaxSegments = $maxSegments
        $this.AccessThreshold = $accessThreshold
        $this.DecayFactor = $decayFactor
    }
    
    # Méthode pour déterminer les segments à précharger
    [string[]] GetSegmentsToPreload([string[]]$allSegmentIds, [hashtable]$segmentStats) {
        # Calculer les scores de préchargement
        $scores = [System.Collections.Generic.Dictionary[string, double]]::new()
        
        foreach ($segmentId in $allSegmentIds) {
            if (-not $segmentStats.ContainsKey($segmentId)) {
                continue
            }
            
            $stats = $segmentStats[$segmentId]
            
            # Calculer le score en fonction du nombre d'accès et de la récence
            $accessCount = $stats.access_count
            $lastAccess = $stats.last_access
            
            if ($accessCount -lt $this.AccessThreshold) {
                continue
            }
            
            $now = Get-Date
            $ageInHours = ($now - $lastAccess).TotalHours
            $decayedScore = $accessCount * [Math]::Pow($this.DecayFactor, $ageInHours)
            
            $scores[$segmentId] = $decayedScore
        }
        
        # Trier les segments par score
        $sortedSegments = $scores.GetEnumerator() | Sort-Object -Property Value -Descending
        
        # Sélectionner les segments à précharger
        return $sortedSegments | Select-Object -First $this.MaxSegments | ForEach-Object { $_.Key }
    }
}

# Classe pour représenter un gestionnaire de préchargement de segments
class SegmentPreloadManager {
    # Gestionnaire de segments
    [IndexSegmentManager]$SegmentManager
    
    # Gestionnaire de fichiers
    [IndexFileManager]$FileManager
    
    # Stratégie de préchargement
    [PreloadStrategy]$Strategy
    
    # Gestionnaire de tâches parallèles
    [ParallelTaskManager]$TaskManager
    
    # Segments préchargés
    [System.Collections.Generic.Dictionary[string, IndexSegment]]$PreloadedSegments
    
    # Statistiques des segments
    [hashtable]$SegmentStats
    
    # Constructeur par défaut
    SegmentPreloadManager() {
        $this.SegmentManager = $null
        $this.FileManager = $null
        $this.Strategy = [PreloadStrategy]::new()
        $this.TaskManager = [ParallelTaskManager]::new()
        $this.PreloadedSegments = [System.Collections.Generic.Dictionary[string, IndexSegment]]::new()
        $this.SegmentStats = @{}
    }
    
    # Constructeur avec gestionnaires
    SegmentPreloadManager([IndexSegmentManager]$segmentManager, [IndexFileManager]$fileManager) {
        $this.SegmentManager = $segmentManager
        $this.FileManager = $fileManager
        $this.Strategy = [PreloadStrategy]::new()
        $this.TaskManager = [ParallelTaskManager]::new()
        $this.PreloadedSegments = [System.Collections.Generic.Dictionary[string, IndexSegment]]::new()
        $this.SegmentStats = @{}
    }
    
    # Constructeur complet
    SegmentPreloadManager([IndexSegmentManager]$segmentManager, [IndexFileManager]$fileManager, [PreloadStrategy]$strategy) {
        $this.SegmentManager = $segmentManager
        $this.FileManager = $fileManager
        $this.Strategy = $strategy
        $this.TaskManager = [ParallelTaskManager]::new()
        $this.PreloadedSegments = [System.Collections.Generic.Dictionary[string, IndexSegment]]::new()
        $this.SegmentStats = @{}
    }
    
    # Méthode pour initialiser le gestionnaire
    [void] Initialize() {
        # Charger les statistiques des segments
        $this.LoadSegmentStats()
        
        # Précharger les segments selon la stratégie
        $this.PreloadSegments()
    }
    
    # Méthode pour charger les statistiques des segments
    [void] LoadSegmentStats() {
        $statsPath = Join-Path -Path $this.FileManager.RootDirectory -ChildPath "segment_stats.json"
        
        if (Test-Path -Path $statsPath) {
            try {
                $this.SegmentStats = Get-Content -Path $statsPath -Raw | ConvertFrom-Json -AsHashtable
            } catch {
                Write-Warning "Erreur lors du chargement des statistiques des segments: $_"
                $this.SegmentStats = @{}
            }
        } else {
            $this.SegmentStats = @{}
        }
    }
    
    # Méthode pour sauvegarder les statistiques des segments
    [void] SaveSegmentStats() {
        $statsPath = Join-Path -Path $this.FileManager.RootDirectory -ChildPath "segment_stats.json"
        
        try {
            $this.SegmentStats | ConvertTo-Json -Depth 10 | Out-File -FilePath $statsPath -Encoding UTF8
        } catch {
            Write-Warning "Erreur lors de la sauvegarde des statistiques des segments: $_"
        }
    }
    
    # Méthode pour précharger les segments
    [void] PreloadSegments() {
        # Obtenir la liste des segments
        $allSegmentIds = $this.FileManager.GetSegmentIds()
        
        # Déterminer les segments à précharger
        $segmentsToPreload = $this.Strategy.GetSegmentsToPreload($allSegmentIds, $this.SegmentStats)
        
        # Précharger les segments en parallèle
        $this.TaskManager.ForEach($segmentsToPreload, {
            param($segmentId)
            
            $segment = $this.FileManager.LoadSegment($segmentId)
            
            if ($null -ne $segment) {
                $this.PreloadedSegments[$segmentId] = $segment
                
                # Mettre à jour les statistiques
                if (-not $this.SegmentStats.ContainsKey($segmentId)) {
                    $this.SegmentStats[$segmentId] = @{
                        access_count = 0
                        last_access = (Get-Date).ToString("o")
                        document_count = $segment.Documents.Count
                        term_count = $segment.InvertedIndex.Count
                    }
                }
            }
        }.GetNewClosure())
    }
    
    # Méthode pour obtenir un segment
    [IndexSegment] GetSegment([string]$segmentId) {
        # Vérifier si le segment est préchargé
        if ($this.PreloadedSegments.ContainsKey($segmentId)) {
            # Mettre à jour les statistiques
            $this.UpdateSegmentStats($segmentId)
            
            return $this.PreloadedSegments[$segmentId]
        }
        
        # Charger le segment depuis le gestionnaire de segments
        if ($this.SegmentManager.ActiveSegments.ContainsKey($segmentId)) {
            # Mettre à jour les statistiques
            $this.UpdateSegmentStats($segmentId)
            
            return $this.SegmentManager.ActiveSegments[$segmentId]
        }
        
        # Charger le segment depuis le stockage
        $segment = $this.FileManager.LoadSegment($segmentId)
        
        if ($null -ne $segment) {
            # Mettre à jour les statistiques
            $this.UpdateSegmentStats($segmentId)
            
            # Ajouter le segment aux segments préchargés
            $this.PreloadedSegments[$segmentId] = $segment
            
            return $segment
        }
        
        return $null
    }
    
    # Méthode pour mettre à jour les statistiques d'un segment
    [void] UpdateSegmentStats([string]$segmentId) {
        if (-not $this.SegmentStats.ContainsKey($segmentId)) {
            $segment = $this.GetSegment($segmentId)
            
            if ($null -ne $segment) {
                $this.SegmentStats[$segmentId] = @{
                    access_count = 1
                    last_access = (Get-Date).ToString("o")
                    document_count = $segment.Documents.Count
                    term_count = $segment.InvertedIndex.Count
                }
            }
        } else {
            $this.SegmentStats[$segmentId].access_count++
            $this.SegmentStats[$segmentId].last_access = (Get-Date).ToString("o")
        }
        
        # Sauvegarder les statistiques périodiquement
        if (Get-Random -Minimum 1 -Maximum 100 -le 5) {  # 5% de chance
            $this.SaveSegmentStats()
        }
    }
    
    # Méthode pour libérer des segments préchargés
    [void] ReleaseSegments([int]$maxSegments = 10) {
        # Si le nombre de segments préchargés est inférieur à la limite, ne rien faire
        if ($this.PreloadedSegments.Count -le $maxSegments) {
            return
        }
        
        # Trier les segments par date de dernier accès
        $sortedSegments = $this.PreloadedSegments.Keys | Sort-Object {
            if ($this.SegmentStats.ContainsKey($_)) {
                [DateTime]::Parse($this.SegmentStats[$_].last_access)
            } else {
                [DateTime]::MinValue
            }
        }
        
        # Libérer les segments les moins récemment utilisés
        $segmentsToRelease = $sortedSegments | Select-Object -First ($this.PreloadedSegments.Count - $maxSegments)
        
        foreach ($segmentId in $segmentsToRelease) {
            $this.PreloadedSegments.Remove($segmentId)
        }
    }
    
    # Méthode pour obtenir les statistiques de préchargement
    [hashtable] GetPreloadStats() {
        return @{
            preloaded_segments = $this.PreloadedSegments.Count
            active_segments = $this.SegmentManager.ActiveSegments.Count
            total_segments = $this.FileManager.GetSegmentIds().Count
            segment_stats = $this.SegmentStats
        }
    }
}

# Fonction pour créer une stratégie de préchargement
function New-PreloadStrategy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "OnDemand", "Predictive")]
        [string]$Type = "OnDemand",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxSegments = 3,
        
        [Parameter(Mandatory = $false)]
        [int]$AccessThreshold = 5,
        
        [Parameter(Mandatory = $false)]
        [double]$DecayFactor = 0.9
    )
    
    switch ($Type) {
        "All" {
            return [PreloadStrategy]::new("All")
        }
        "OnDemand" {
            return [PreloadStrategy]::new("OnDemand")
        }
        "Predictive" {
            return [PredictivePreloadStrategy]::new($MaxSegments, $AccessThreshold, $DecayFactor)
        }
        default {
            return [PreloadStrategy]::new()
        }
    }
}

# Fonction pour créer un gestionnaire de préchargement de segments
function New-SegmentPreloadManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexSegmentManager]$SegmentManager,
        
        [Parameter(Mandatory = $true)]
        [IndexFileManager]$FileManager,
        
        [Parameter(Mandatory = $false)]
        [PreloadStrategy]$Strategy = (New-PreloadStrategy)
    )
    
    $manager = [SegmentPreloadManager]::new($SegmentManager, $FileManager, $Strategy)
    $manager.Initialize()
    
    return $manager
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-PreloadStrategy, New-SegmentPreloadManager

#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion des dépendances pour le cache prédictif.
.DESCRIPTION
    Détecte et gère les dépendances entre éléments du cache pour
    assurer la cohérence et optimiser les invalidations.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Classe pour le gestionnaire de dépendances
class DependencyManager {
    [CacheManager]$BaseCache
    [hashtable]$Dependencies = @{}  # Clé -> Dépendances
    [hashtable]$Dependents = @{}    # Clé -> Dépendants
    [hashtable]$DependencyStrength = @{}  # Paire de clés -> Force de la dépendance (0.0-1.0)
    [bool]$AutoDetectDependencies = $true
    [int]$MaxDependenciesPerKey = 10
    [UsageCollector]$UsageCollector
    
    # Constructeur
    DependencyManager([CacheManager]$baseCache, [UsageCollector]$usageCollector) {
        $this.BaseCache = $baseCache
        $this.UsageCollector = $usageCollector
    }
    
    # Ajouter une dépendance
    [void] AddDependency([string]$sourceKey, [string]$targetKey, [double]$strength = 1.0) {
        # Vérifier que les clés sont différentes
        if ($sourceKey -eq $targetKey) {
            return
        }
        
        # Ajouter la dépendance
        if (-not $this.Dependencies.ContainsKey($sourceKey)) {
            $this.Dependencies[$sourceKey] = @{}
        }
        
        $this.Dependencies[$sourceKey][$targetKey] = $strength
        
        # Limiter le nombre de dépendances
        if ($this.Dependencies[$sourceKey].Count -gt $this.MaxDependenciesPerKey) {
            # Supprimer la dépendance la plus faible
            $weakestKey = $this.Dependencies[$sourceKey].GetEnumerator() |
                Sort-Object -Property Value |
                Select-Object -First 1 -ExpandProperty Key
            
            $this.Dependencies[$sourceKey].Remove($weakestKey)
        }
        
        # Ajouter le dépendant
        if (-not $this.Dependents.ContainsKey($targetKey)) {
            $this.Dependents[$targetKey] = @{}
        }
        
        $this.Dependents[$targetKey][$sourceKey] = $strength
        
        # Enregistrer la force de la dépendance
        $pairKey = "$sourceKey->$targetKey"
        $this.DependencyStrength[$pairKey] = $strength
    }
    
    # Supprimer une dépendance
    [void] RemoveDependency([string]$sourceKey, [string]$targetKey) {
        # Supprimer la dépendance
        if ($this.Dependencies.ContainsKey($sourceKey)) {
            $this.Dependencies[$sourceKey].Remove($targetKey)
            
            # Supprimer l'entrée si elle est vide
            if ($this.Dependencies[$sourceKey].Count -eq 0) {
                $this.Dependencies.Remove($sourceKey)
            }
        }
        
        # Supprimer le dépendant
        if ($this.Dependents.ContainsKey($targetKey)) {
            $this.Dependents[$targetKey].Remove($sourceKey)
            
            # Supprimer l'entrée si elle est vide
            if ($this.Dependents[$targetKey].Count -eq 0) {
                $this.Dependents.Remove($targetKey)
            }
        }
        
        # Supprimer la force de la dépendance
        $pairKey = "$sourceKey->$targetKey"
        $this.DependencyStrength.Remove($pairKey)
    }
    
    # Obtenir les dépendances d'une clé
    [hashtable] GetDependencies([string]$key) {
        if ($this.Dependencies.ContainsKey($key)) {
            return $this.Dependencies[$key]
        }
        
        return @{}
    }
    
    # Obtenir les dépendants d'une clé
    [hashtable] GetDependents([string]$key) {
        if ($this.Dependents.ContainsKey($key)) {
            return $this.Dependents[$key]
        }
        
        return @{}
    }
    
    # Détecter les dépendances automatiquement
    [void] DetectDependencies() {
        if (-not $this.AutoDetectDependencies) {
            return
        }
        
        try {
            # Récupérer les séquences d'accès fréquentes
            $sequences = $this.UsageCollector.GetFrequentSequences(30, 60)  # 30 séquences les plus fréquentes dans les 60 dernières minutes
            
            foreach ($sequence in $sequences) {
                $sourceKey = $sequence.FirstKey
                $targetKey = $sequence.SecondKey
                
                # Calculer la force de la dépendance
                $strength = $this.CalculateDependencyStrength($sequence)
                
                # Ajouter la dépendance si elle est suffisamment forte
                if ($strength -gt 0.3) {
                    $this.AddDependency($sourceKey, $targetKey, $strength)
                }
            }
        }
        catch {
            Write-Warning "Erreur lors de la détection automatique des dépendances: $_"
        }
    }
    
    # Calculer la force d'une dépendance
    [double] CalculateDependencyStrength([PSCustomObject]$sequence) {
        # Facteurs de base
        $countFactor = [Math]::Min(1.0, $sequence.SequenceCount / 20.0)  # Normalisé à 20 occurrences
        $timeFactor = [Math]::Min(1.0, 5000.0 / [Math]::Max(100, $sequence.AvgTimeDifference))  # Favorise les séquences rapides
        
        # Combinaison des facteurs
        $strength = ($countFactor * 0.7) + ($timeFactor * 0.3)
        
        return $strength
    }
    
    # Invalider les dépendants d'une clé
    [void] InvalidateDependents([string]$key) {
        $dependents = $this.GetDependents($key)
        
        foreach ($dependentKey in $dependents.Keys) {
            $strength = $dependents[$dependentKey]
            
            # Invalider seulement si la dépendance est forte
            if ($strength -gt 0.7) {
                $this.BaseCache.Remove($dependentKey)
                
                # Récursion pour invalider les dépendants des dépendants
                $this.InvalidateDependents($dependentKey)
            }
        }
    }
    
    # Précharger les dépendances d'une clé
    [void] PreloadDependencies([string]$key, [PreloadManager]$preloadManager) {
        $dependencies = $this.GetDependencies($key)
        
        foreach ($dependencyKey in $dependencies.Keys) {
            $strength = $dependencies[$dependencyKey]
            
            # Précharger seulement si la dépendance est forte
            if ($strength -gt 0.7) {
                # Vérifier si la clé est déjà dans le cache
                if (-not $this.BaseCache.Contains($dependencyKey)) {
                    # Précharger la clé
                    $preloadManager.PreloadKeys(@($dependencyKey))
                }
            }
        }
    }
    
    # Nettoyer les dépendances obsolètes
    [void] CleanupObsoleteDependencies() {
        $keysToRemove = @()
        
        # Vérifier les dépendances
        foreach ($sourceKey in $this.Dependencies.Keys) {
            $dependencies = $this.Dependencies[$sourceKey]
            $targetsToRemove = @()
            
            foreach ($targetKey in $dependencies.Keys) {
                $pairKey = "$sourceKey->$targetKey"
                $strength = $this.DependencyStrength[$pairKey]
                
                # Affaiblir les dépendances non utilisées
                $strength = $strength * 0.9
                $this.DependencyStrength[$pairKey] = $strength
                
                # Supprimer les dépendances trop faibles
                if ($strength -lt 0.1) {
                    $targetsToRemove += $targetKey
                }
            }
            
            # Supprimer les dépendances
            foreach ($targetKey in $targetsToRemove) {
                $this.RemoveDependency($sourceKey, $targetKey)
            }
            
            # Marquer la source pour suppression si elle n'a plus de dépendances
            if ($this.Dependencies[$sourceKey].Count -eq 0) {
                $keysToRemove += $sourceKey
            }
        }
        
        # Supprimer les clés vides
        foreach ($key in $keysToRemove) {
            $this.Dependencies.Remove($key)
        }
    }
    
    # Obtenir les statistiques de dépendances
    [PSCustomObject] GetDependencyStatistics() {
        $totalDependencies = 0
        foreach ($sourceKey in $this.Dependencies.Keys) {
            $totalDependencies += $this.Dependencies[$sourceKey].Count
        }
        
        $avgStrength = 0.0
        if ($this.DependencyStrength.Count -gt 0) {
            $avgStrength = ($this.DependencyStrength.Values | Measure-Object -Average).Average
        }
        
        return [PSCustomObject]@{
            TotalSources = $this.Dependencies.Count
            TotalTargets = $this.Dependents.Count
            TotalDependencies = $totalDependencies
            AverageStrength = $avgStrength
            AutoDetectEnabled = $this.AutoDetectDependencies
        }
    }
}

# Fonctions exportées

<#
.SYNOPSIS
    Crée un nouveau gestionnaire de dépendances.
.DESCRIPTION
    Crée un nouveau gestionnaire de dépendances pour le cache prédictif.
.PARAMETER BaseCache
    Cache de base à utiliser.
.PARAMETER UsageCollector
    Collecteur d'utilisation à utiliser.
.EXAMPLE
    $dependencyManager = New-DependencyManager -BaseCache $cache -UsageCollector $collector
#>
function New-DependencyManager {
    [CmdletBinding()]
    [OutputType([DependencyManager])]
    param (
        [Parameter(Mandatory = $true)]
        [CacheManager]$BaseCache,
        
        [Parameter(Mandatory = $true)]
        [UsageCollector]$UsageCollector
    )
    
    try {
        return [DependencyManager]::new($BaseCache, $UsageCollector)
    }
    catch {
        Write-Error "Erreur lors de la création du gestionnaire de dépendances: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Ajoute une dépendance entre deux clés.
.DESCRIPTION
    Ajoute une dépendance entre une clé source et une clé cible.
.PARAMETER DependencyManager
    Gestionnaire de dépendances à utiliser.
.PARAMETER SourceKey
    Clé source (dépendante).
.PARAMETER TargetKey
    Clé cible (dépendance).
.PARAMETER Strength
    Force de la dépendance (0.0-1.0).
.EXAMPLE
    Add-CacheDependency -DependencyManager $manager -SourceKey "User:Profile:123" -TargetKey "User:Data:123" -Strength 0.8
#>
function Add-CacheDependency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [DependencyManager]$DependencyManager,
        
        [Parameter(Mandatory = $true)]
        [string]$SourceKey,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetKey,
        
        [Parameter(Mandatory = $false)]
        [double]$Strength = 1.0
    )
    
    try {
        $DependencyManager.AddDependency($SourceKey, $TargetKey, $Strength)
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'ajout de la dépendance: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Supprime une dépendance entre deux clés.
.DESCRIPTION
    Supprime une dépendance entre une clé source et une clé cible.
.PARAMETER DependencyManager
    Gestionnaire de dépendances à utiliser.
.PARAMETER SourceKey
    Clé source (dépendante).
.PARAMETER TargetKey
    Clé cible (dépendance).
.EXAMPLE
    Remove-CacheDependency -DependencyManager $manager -SourceKey "User:Profile:123" -TargetKey "User:Data:123"
#>
function Remove-CacheDependency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [DependencyManager]$DependencyManager,
        
        [Parameter(Mandatory = $true)]
        [string]$SourceKey,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetKey
    )
    
    try {
        $DependencyManager.RemoveDependency($SourceKey, $TargetKey)
        return $true
    }
    catch {
        Write-Error "Erreur lors de la suppression de la dépendance: $_"
        return $false
    }
}

<#
.SYNOPSIS
    Configure les options du gestionnaire de dépendances.
.DESCRIPTION
    Configure les options du gestionnaire de dépendances comme la détection automatique.
.PARAMETER DependencyManager
    Gestionnaire de dépendances à configurer.
.PARAMETER AutoDetectDependencies
    Indique si la détection automatique des dépendances est activée.
.PARAMETER MaxDependenciesPerKey
    Nombre maximum de dépendances par clé.
.EXAMPLE
    Set-DependencyManagerOptions -DependencyManager $manager -AutoDetectDependencies $true -MaxDependenciesPerKey 20
#>
function Set-DependencyManagerOptions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [DependencyManager]$DependencyManager,
        
        [Parameter(Mandatory = $false)]
        [bool]$AutoDetectDependencies,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDependenciesPerKey
    )
    
    try {
        # Mettre à jour les options
        if ($PSBoundParameters.ContainsKey('AutoDetectDependencies')) {
            $DependencyManager.AutoDetectDependencies = $AutoDetectDependencies
        }
        
        if ($PSBoundParameters.ContainsKey('MaxDependenciesPerKey')) {
            $DependencyManager.MaxDependenciesPerKey = $MaxDependenciesPerKey
        }
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de la configuration du gestionnaire de dépendances: $_"
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-DependencyManager, Add-CacheDependency, Remove-CacheDependency, Set-DependencyManagerOptions

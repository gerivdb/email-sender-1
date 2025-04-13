#Requires -Version 5.1
<#
.SYNOPSIS
    Module de préchargement pour le cache prédictif.
.DESCRIPTION
    Gère le préchargement proactif des données susceptibles d'être utilisées.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Classe pour le gestionnaire de préchargement
class PreloadManager {
    [CacheManager]$BaseCache
    [PredictionEngine]$PredictionEngine
    [hashtable]$PreloadedKeys = @{}
    [hashtable]$PreloadGenerators = @{}
    [int]$MaxConcurrentPreloads = 3
    [int]$PreloadCooldown = 60  # Secondes
    [hashtable]$LastPreloadTimes = @{}
    [double]$ResourceThreshold = 0.7  # Seuil d'utilisation des ressources (0.0-1.0)
    [bool]$EnableResourceCheck = $true
    
    # Constructeur
    PreloadManager([CacheManager]$baseCache, [PredictionEngine]$predictionEngine) {
        $this.BaseCache = $baseCache
        $this.PredictionEngine = $predictionEngine
    }
    
    # Enregistrer un générateur de valeur pour une clé
    [void] RegisterGenerator([string]$keyPattern, [scriptblock]$generator) {
        $this.PreloadGenerators[$keyPattern] = $generator
    }
    
    # Vérifier si une clé est un candidat au préchargement
    [bool] IsPreloadCandidate([string]$key) {
        return $this.PreloadedKeys.ContainsKey($key)
    }
    
    # Précharger des clés
    [void] PreloadKeys([array]$keys) {
        # Vérifier les ressources système
        if ($this.EnableResourceCheck -and $this.IsSystemUnderHeavyLoad()) {
            Write-Verbose "Préchargement annulé: charge système élevée"
            return
        }
        
        $now = Get-Date
        $preloadCount = 0
        
        foreach ($key in $keys) {
            # Vérifier si la clé est déjà dans le cache
            if ($this.BaseCache.Contains($key)) {
                continue
            }
            
            # Vérifier le temps de refroidissement
            if ($this.LastPreloadTimes.ContainsKey($key)) {
                $lastPreload = $this.LastPreloadTimes[$key]
                if (($now - $lastPreload).TotalSeconds -lt $this.PreloadCooldown) {
                    continue
                }
            }
            
            # Trouver un générateur approprié
            $generator = $this.FindGenerator($key)
            
            if ($generator -ne $null) {
                # Limiter le nombre de préchargements concurrents
                if ($preloadCount -ge $this.MaxConcurrentPreloads) {
                    break
                }
                
                # Précharger en arrière-plan
                $this.PreloadInBackground($key, $generator)
                $preloadCount++
                
                # Mettre à jour le temps de préchargement
                $this.LastPreloadTimes[$key] = $now
            }
        }
    }
    
    # Trouver un générateur approprié pour une clé
    [scriptblock] FindGenerator([string]$key) {
        foreach ($pattern in $this.PreloadGenerators.Keys) {
            if ($key -like $pattern) {
                return $this.PreloadGenerators[$pattern]
            }
        }
        
        return $null
    }
    
    # Précharger une clé en arrière-plan
    [void] PreloadInBackground([string]$key, [scriptblock]$generator) {
        # Marquer la clé comme en cours de préchargement
        $this.PreloadedKeys[$key] = $false  # false = préchargement en cours
        
        # Créer un job en arrière-plan
        Start-ThreadJob -ScriptBlock {
            param($key, $generator, $cacheInstance)
            
            try {
                # Exécuter le générateur
                $value = & $generator
                
                # Stocker dans le cache
                if ($value -ne $null) {
                    $cacheInstance.Set($key, $value)
                    return @{ Key = $key; Success = $true }
                }
            }
            catch {
                Write-Warning "Erreur lors du préchargement de la clé '$key': $_"
                return @{ Key = $key; Success = $false; Error = $_ }
            }
            
            return @{ Key = $key; Success = $false }
        } -ArgumentList $key, $generator, $this.BaseCache -Name "Preload_$key" | Out-Null
        
        # Gérer la complétion du job en arrière-plan
        $job = Get-Job -Name "Preload_$key" -ErrorAction SilentlyContinue
        
        if ($job -ne $null) {
            Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
                $job = $Event.Sender
                $key = $job.Name -replace "^Preload_", ""
                
                if ($job.State -eq "Completed") {
                    $result = Receive-Job -Job $job
                    
                    if ($result.Success) {
                        # Marquer la clé comme préchargée avec succès
                        $this.PreloadedKeys[$key] = $true
                    }
                    else {
                        # Supprimer la clé des préchargements
                        $this.PreloadedKeys.Remove($key)
                    }
                    
                    # Nettoyer le job
                    Remove-Job -Job $job -Force
                }
            } | Out-Null
        }
    }
    
    # Vérifier si le système est sous charge élevée
    [bool] IsSystemUnderHeavyLoad() {
        try {
            # Obtenir l'utilisation du CPU
            $cpuLoad = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
            
            # Obtenir l'utilisation de la mémoire
            $os = Get-CimInstance -ClassName Win32_OperatingSystem
            $memoryUsed = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
            $memoryLoad = $memoryUsed / $os.TotalVisibleMemorySize
            
            # Vérifier si l'une des ressources dépasse le seuil
            return ($cpuLoad / 100 -gt $this.ResourceThreshold) -or ($memoryLoad -gt $this.ResourceThreshold)
        }
        catch {
            Write-Warning "Erreur lors de la vérification de la charge système: $_"
            return $false  # En cas d'erreur, supposer que le système n'est pas sous charge
        }
    }
    
    # Optimiser la stratégie de préchargement
    [void] OptimizePreloadStrategy() {
        # Ajuster les paramètres en fonction des statistiques
        $stats = $this.GetPreloadStatistics()
        
        if ($stats.SuccessRate -lt 0.3) {
            # Si le taux de succès est faible, augmenter le seuil de probabilité
            $this.ResourceThreshold = [Math]::Min(0.9, $this.ResourceThreshold + 0.05)
        }
        elseif ($stats.SuccessRate -gt 0.7) {
            # Si le taux de succès est élevé, diminuer le seuil de probabilité
            $this.ResourceThreshold = [Math]::Max(0.5, $this.ResourceThreshold - 0.05)
        }
        
        # Ajuster le nombre maximum de préchargements concurrents
        if ($stats.AveragePreloadTime -gt 1000) {  # Si le préchargement est lent (> 1s)
            $this.MaxConcurrentPreloads = [Math]::Max(1, $this.MaxConcurrentPreloads - 1)
        }
        elseif ($stats.AveragePreloadTime -lt 200) {  # Si le préchargement est rapide (< 200ms)
            $this.MaxConcurrentPreloads = [Math]::Min(10, $this.MaxConcurrentPreloads + 1)
        }
        
        # Nettoyer les anciennes entrées
        $this.CleanupOldEntries()
    }
    
    # Nettoyer les anciennes entrées
    [void] CleanupOldEntries() {
        $now = Get-Date
        $keysToRemove = @()
        
        foreach ($key in $this.LastPreloadTimes.Keys) {
            $lastPreload = $this.LastPreloadTimes[$key]
            if (($now - $lastPreload).TotalHours -gt 24) {
                $keysToRemove += $key
            }
        }
        
        foreach ($key in $keysToRemove) {
            $this.LastPreloadTimes.Remove($key)
            $this.PreloadedKeys.Remove($key)
        }
    }
    
    # Obtenir les statistiques de préchargement
    [PSCustomObject] GetPreloadStatistics() {
        $successCount = ($this.PreloadedKeys.Values | Where-Object { $_ -eq $true }).Count
        $totalCount = $this.PreloadedKeys.Count
        $successRate = if ($totalCount -gt 0) { $successCount / $totalCount } else { 0 }
        
        # Calculer le temps moyen de préchargement (simulé pour l'exemple)
        $averagePreloadTime = 500  # ms (valeur fictive)
        
        return [PSCustomObject]@{
            TotalPreloads = $totalCount
            SuccessfulPreloads = $successCount
            SuccessRate = $successRate
            AveragePreloadTime = $averagePreloadTime
            MaxConcurrentPreloads = $this.MaxConcurrentPreloads
            ResourceThreshold = $this.ResourceThreshold
        }
    }
}

# Fonctions exportées

<#
.SYNOPSIS
    Crée un nouveau gestionnaire de préchargement.
.DESCRIPTION
    Crée un nouveau gestionnaire de préchargement pour le cache prédictif.
.PARAMETER BaseCache
    Cache de base à utiliser.
.PARAMETER PredictionEngine
    Moteur de prédiction à utiliser.
.EXAMPLE
    $preloadManager = New-PreloadManager -BaseCache $cache -PredictionEngine $engine
#>
function New-PreloadManager {
    [CmdletBinding()]
    [OutputType([PreloadManager])]
    param (
        [Parameter(Mandatory = $true)]
        [CacheManager]$BaseCache,
        
        [Parameter(Mandatory = $true)]
        [PredictionEngine]$PredictionEngine
    )
    
    try {
        return [PreloadManager]::new($BaseCache, $PredictionEngine)
    }
    catch {
        Write-Error "Erreur lors de la création du gestionnaire de préchargement: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Enregistre un générateur de valeur pour le préchargement.
.DESCRIPTION
    Enregistre un générateur de valeur pour une clé ou un modèle de clé.
.PARAMETER PreloadManager
    Gestionnaire de préchargement à utiliser.
.PARAMETER KeyPattern
    Modèle de clé (peut contenir des caractères génériques).
.PARAMETER Generator
    Script de génération de la valeur.
.EXAMPLE
    Register-PreloadGenerator -PreloadManager $manager -KeyPattern "User:*" -Generator { Get-UserData }
#>
function Register-PreloadGenerator {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PreloadManager]$PreloadManager,
        
        [Parameter(Mandatory = $true)]
        [string]$KeyPattern,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Generator
    )
    
    try {
        $PreloadManager.RegisterGenerator($KeyPattern, $Generator)
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'enregistrement du générateur: $_"
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-PreloadManager, Register-PreloadGenerator

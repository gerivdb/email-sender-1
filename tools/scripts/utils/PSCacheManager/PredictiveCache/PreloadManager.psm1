#Requires -Version 5.1
<#
.SYNOPSIS
    Module de prÃ©chargement pour le cache prÃ©dictif.
.DESCRIPTION
    GÃ¨re le prÃ©chargement proactif des donnÃ©es susceptibles d'Ãªtre utilisÃ©es.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Classe pour le gestionnaire de prÃ©chargement
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
    
    # Enregistrer un gÃ©nÃ©rateur de valeur pour une clÃ©
    [void] RegisterGenerator([string]$keyPattern, [scriptblock]$generator) {
        $this.PreloadGenerators[$keyPattern] = $generator
    }
    
    # VÃ©rifier si une clÃ© est un candidat au prÃ©chargement
    [bool] IsPreloadCandidate([string]$key) {
        return $this.PreloadedKeys.ContainsKey($key)
    }
    
    # PrÃ©charger des clÃ©s
    [void] PreloadKeys([array]$keys) {
        # VÃ©rifier les ressources systÃ¨me
        if ($this.EnableResourceCheck -and $this.IsSystemUnderHeavyLoad()) {
            Write-Verbose "PrÃ©chargement annulÃ©: charge systÃ¨me Ã©levÃ©e"
            return
        }
        
        $now = Get-Date
        $preloadCount = 0
        
        foreach ($key in $keys) {
            # VÃ©rifier si la clÃ© est dÃ©jÃ  dans le cache
            if ($this.BaseCache.Contains($key)) {
                continue
            }
            
            # VÃ©rifier le temps de refroidissement
            if ($this.LastPreloadTimes.ContainsKey($key)) {
                $lastPreload = $this.LastPreloadTimes[$key]
                if (($now - $lastPreload).TotalSeconds -lt $this.PreloadCooldown) {
                    continue
                }
            }
            
            # Trouver un gÃ©nÃ©rateur appropriÃ©
            $generator = $this.FindGenerator($key)
            
            if ($generator -ne $null) {
                # Limiter le nombre de prÃ©chargements concurrents
                if ($preloadCount -ge $this.MaxConcurrentPreloads) {
                    break
                }
                
                # PrÃ©charger en arriÃ¨re-plan
                $this.PreloadInBackground($key, $generator)
                $preloadCount++
                
                # Mettre Ã  jour le temps de prÃ©chargement
                $this.LastPreloadTimes[$key] = $now
            }
        }
    }
    
    # Trouver un gÃ©nÃ©rateur appropriÃ© pour une clÃ©
    [scriptblock] FindGenerator([string]$key) {
        foreach ($pattern in $this.PreloadGenerators.Keys) {
            if ($key -like $pattern) {
                return $this.PreloadGenerators[$pattern]
            }
        }
        
        return $null
    }
    
    # PrÃ©charger une clÃ© en arriÃ¨re-plan
    [void] PreloadInBackground([string]$key, [scriptblock]$generator) {
        # Marquer la clÃ© comme en cours de prÃ©chargement
        $this.PreloadedKeys[$key] = $false  # false = prÃ©chargement en cours
        
        # CrÃ©er un job en arriÃ¨re-plan
        Start-ThreadJob -ScriptBlock {
            param($key, $generator, $cacheInstance)
            
            try {
                # ExÃ©cuter le gÃ©nÃ©rateur
                $value = & $generator
                
                # Stocker dans le cache
                if ($value -ne $null) {
                    $cacheInstance.Set($key, $value)
                    return @{ Key = $key; Success = $true }
                }
            }
            catch {
                Write-Warning "Erreur lors du prÃ©chargement de la clÃ© '$key': $_"
                return @{ Key = $key; Success = $false; Error = $_ }
            }
            
            return @{ Key = $key; Success = $false }
        } -ArgumentList $key, $generator, $this.BaseCache -Name "Preload_$key" | Out-Null
        
        # GÃ©rer la complÃ©tion du job en arriÃ¨re-plan
        $job = Get-Job -Name "Preload_$key" -ErrorAction SilentlyContinue
        
        if ($job -ne $null) {
            Register-ObjectEvent -InputObject $job -EventName StateChanged -Action {
                $job = $Event.Sender
                $key = $job.Name -replace "^Preload_", ""
                
                if ($job.State -eq "Completed") {
                    $result = Receive-Job -Job $job
                    
                    if ($result.Success) {
                        # Marquer la clÃ© comme prÃ©chargÃ©e avec succÃ¨s
                        $this.PreloadedKeys[$key] = $true
                    }
                    else {
                        # Supprimer la clÃ© des prÃ©chargements
                        $this.PreloadedKeys.Remove($key)
                    }
                    
                    # Nettoyer le job
                    Remove-Job -Job $job -Force
                }
            } | Out-Null
        }
    }
    
    # VÃ©rifier si le systÃ¨me est sous charge Ã©levÃ©e
    [bool] IsSystemUnderHeavyLoad() {
        try {
            # Obtenir l'utilisation du CPU
            $cpuLoad = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
            
            # Obtenir l'utilisation de la mÃ©moire
            $os = Get-CimInstance -ClassName Win32_OperatingSystem
            $memoryUsed = $os.TotalVisibleMemorySize - $os.FreePhysicalMemory
            $memoryLoad = $memoryUsed / $os.TotalVisibleMemorySize
            
            # VÃ©rifier si l'une des ressources dÃ©passe le seuil
            return ($cpuLoad / 100 -gt $this.ResourceThreshold) -or ($memoryLoad -gt $this.ResourceThreshold)
        }
        catch {
            Write-Warning "Erreur lors de la vÃ©rification de la charge systÃ¨me: $_"
            return $false  # En cas d'erreur, supposer que le systÃ¨me n'est pas sous charge
        }
    }
    
    # Optimiser la stratÃ©gie de prÃ©chargement
    [void] OptimizePreloadStrategy() {
        # Ajuster les paramÃ¨tres en fonction des statistiques
        $stats = $this.GetPreloadStatistics()
        
        if ($stats.SuccessRate -lt 0.3) {
            # Si le taux de succÃ¨s est faible, augmenter le seuil de probabilitÃ©
            $this.ResourceThreshold = [Math]::Min(0.9, $this.ResourceThreshold + 0.05)
        }
        elseif ($stats.SuccessRate -gt 0.7) {
            # Si le taux de succÃ¨s est Ã©levÃ©, diminuer le seuil de probabilitÃ©
            $this.ResourceThreshold = [Math]::Max(0.5, $this.ResourceThreshold - 0.05)
        }
        
        # Ajuster le nombre maximum de prÃ©chargements concurrents
        if ($stats.AveragePreloadTime -gt 1000) {  # Si le prÃ©chargement est lent (> 1s)
            $this.MaxConcurrentPreloads = [Math]::Max(1, $this.MaxConcurrentPreloads - 1)
        }
        elseif ($stats.AveragePreloadTime -lt 200) {  # Si le prÃ©chargement est rapide (< 200ms)
            $this.MaxConcurrentPreloads = [Math]::Min(10, $this.MaxConcurrentPreloads + 1)
        }
        
        # Nettoyer les anciennes entrÃ©es
        $this.CleanupOldEntries()
    }
    
    # Nettoyer les anciennes entrÃ©es
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
    
    # Obtenir les statistiques de prÃ©chargement
    [PSCustomObject] GetPreloadStatistics() {
        $successCount = ($this.PreloadedKeys.Values | Where-Object { $_ -eq $true }).Count
        $totalCount = $this.PreloadedKeys.Count
        $successRate = if ($totalCount -gt 0) { $successCount / $totalCount } else { 0 }
        
        # Calculer le temps moyen de prÃ©chargement (simulÃ© pour l'exemple)
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

# Fonctions exportÃ©es

<#
.SYNOPSIS
    CrÃ©e un nouveau gestionnaire de prÃ©chargement.
.DESCRIPTION
    CrÃ©e un nouveau gestionnaire de prÃ©chargement pour le cache prÃ©dictif.
.PARAMETER BaseCache
    Cache de base Ã  utiliser.
.PARAMETER PredictionEngine
    Moteur de prÃ©diction Ã  utiliser.
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
        Write-Error "Erreur lors de la crÃ©ation du gestionnaire de prÃ©chargement: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Enregistre un gÃ©nÃ©rateur de valeur pour le prÃ©chargement.
.DESCRIPTION
    Enregistre un gÃ©nÃ©rateur de valeur pour une clÃ© ou un modÃ¨le de clÃ©.
.PARAMETER PreloadManager
    Gestionnaire de prÃ©chargement Ã  utiliser.
.PARAMETER KeyPattern
    ModÃ¨le de clÃ© (peut contenir des caractÃ¨res gÃ©nÃ©riques).
.PARAMETER Generator
    Script de gÃ©nÃ©ration de la valeur.
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
        Write-Error "Erreur lors de l'enregistrement du gÃ©nÃ©rateur: $_"
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-PreloadManager, Register-PreloadGenerator

#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'optimisation des TTL pour le cache prédictif.
.DESCRIPTION
    Ajuste dynamiquement les durées de vie (TTL) des éléments du cache
    en fonction des patterns d'utilisation.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Classe pour l'optimiseur de TTL
class TTLOptimizer {
    [CacheManager]$BaseCache
    [UsageCollector]$UsageCollector
    [hashtable]$TTLRules = @{}
    [hashtable]$KeyAccessPatterns = @{}
    [int]$MinimumTTL = 60  # Secondes
    [int]$MaximumTTL = 86400  # Secondes (1 jour)
    [double]$FrequencyWeight = 0.5
    [double]$RecencyWeight = 0.3
    [double]$StabilityWeight = 0.2
    [datetime]$LastRuleUpdate = [datetime]::MinValue
    [int]$RuleUpdateInterval = 600  # Secondes (10 minutes)
    
    # Constructeur
    TTLOptimizer([CacheManager]$baseCache, [UsageCollector]$usageCollector) {
        $this.BaseCache = $baseCache
        $this.UsageCollector = $usageCollector
        $this.UpdateTTLRules()
    }
    
    # Optimiser le TTL pour une clé
    [int] OptimizeTTL([string]$key, [int]$currentTTL) {
        # Si nous avons une règle spécifique pour cette clé
        if ($this.TTLRules.ContainsKey($key)) {
            return $this.TTLRules[$key]
        }
        
        # Sinon, essayer de trouver une règle basée sur un pattern
        foreach ($pattern in $this.TTLRules.Keys) {
            if ($pattern.Contains("*") -and ($key -like $pattern)) {
                return $this.TTLRules[$pattern]
            }
        }
        
        # Si nous avons des données d'accès pour cette clé
        $keyStats = $this.UsageCollector.GetKeyAccessStats($key)
        if ($keyStats -ne $null) {
            return $this.CalculateOptimalTTL($keyStats, $currentTTL)
        }
        
        # Sinon, retourner le TTL actuel
        return $currentTTL
    }
    
    # Calculer le TTL optimal pour une clé
    [int] CalculateOptimalTTL([PSCustomObject]$keyStats, [int]$currentTTL) {
        # Facteurs d'optimisation
        $frequencyFactor = $this.CalculateFrequencyFactor($keyStats.TotalAccesses)
        $recencyFactor = $this.CalculateRecencyFactor($keyStats.LastAccess)
        $stabilityFactor = $this.CalculateStabilityFactor($keyStats.HitRatio)
        
        # Combiner les facteurs avec leurs poids
        $ttlFactor = ($frequencyFactor * $this.FrequencyWeight) +
                     ($recencyFactor * $this.RecencyWeight) +
                     ($stabilityFactor * $this.StabilityWeight)
        
        # Calculer le TTL optimal (entre MinimumTTL et MaximumTTL)
        $optimalTTL = $this.MinimumTTL + ($ttlFactor * ($this.MaximumTTL - $this.MinimumTTL))
        $optimalTTL = [Math]::Round($optimalTTL)
        
        # Limiter aux bornes
        $optimalTTL = [Math]::Max($this.MinimumTTL, [Math]::Min($this.MaximumTTL, $optimalTTL))
        
        # Mettre à jour le pattern d'accès
        $this.UpdateAccessPattern($keyStats.Key, $optimalTTL)
        
        return $optimalTTL
    }
    
    # Calculer le facteur de fréquence
    [double] CalculateFrequencyFactor([int]$accessCount) {
        # Normaliser le nombre d'accès (0.0-1.0)
        # Plus d'accès = TTL plus long
        return [Math]::Min(1.0, $accessCount / 100.0)
    }
    
    # Calculer le facteur de récence
    [double] CalculateRecencyFactor([datetime]$lastAccess) {
        $now = Get-Date
        $hoursSinceLastAccess = ($now - $lastAccess).TotalHours
        
        # Décroissance exponentielle: plus récent = TTL plus long
        return [Math]::Exp(-0.1 * $hoursSinceLastAccess)
    }
    
    # Calculer le facteur de stabilité
    [double] CalculateStabilityFactor([double]$hitRatio) {
        # Plus le ratio de hits est élevé, plus le TTL est long
        return $hitRatio
    }
    
    # Mettre à jour le pattern d'accès pour une clé
    [void] UpdateAccessPattern([string]$key, [int]$ttl) {
        if (-not $this.KeyAccessPatterns.ContainsKey($key)) {
            $this.KeyAccessPatterns[$key] = @{
                TTLHistory = @()
                AccessCount = 0
                FirstAccess = Get-Date
                LastAccess = Get-Date
            }
        }
        
        $pattern = $this.KeyAccessPatterns[$key]
        $pattern.TTLHistory += $ttl
        $pattern.AccessCount++
        $pattern.LastAccess = Get-Date
        
        # Limiter l'historique à 10 entrées
        if ($pattern.TTLHistory.Count -gt 10) {
            $pattern.TTLHistory = $pattern.TTLHistory | Select-Object -Last 10
        }
    }
    
    # Mettre à jour les règles de TTL
    [void] UpdateTTLRules() {
        $now = Get-Date
        
        # Vérifier si une mise à jour est nécessaire
        if (($now - $this.LastRuleUpdate).TotalSeconds -lt $this.RuleUpdateInterval) {
            return
        }
        
        try {
            # Récupérer les clés les plus accédées
            $mostAccessedKeys = $this.UsageCollector.GetMostAccessedKeys(50, 1440)  # 50 clés les plus accédées dans les dernières 24h
            
            # Analyser les patterns d'accès
            $keyGroups = $this.AnalyzeAccessPatterns($mostAccessedKeys)
            
            # Mettre à jour les règles
            foreach ($group in $keyGroups.Keys) {
                $keys = $keyGroups[$group]
                
                if ($keys.Count -gt 0) {
                    # Calculer le TTL moyen pour ce groupe
                    $totalTTL = 0
                    $validKeys = 0
                    
                    foreach ($key in $keys) {
                        $keyStats = $this.UsageCollector.GetKeyAccessStats($key)
                        if ($keyStats -ne $null) {
                            $ttl = $this.CalculateOptimalTTL($keyStats, $this.BaseCache.DefaultTTLSeconds)
                            $totalTTL += $ttl
                            $validKeys++
                        }
                    }
                    
                    if ($validKeys -gt 0) {
                        $avgTTL = [Math]::Round($totalTTL / $validKeys)
                        $this.TTLRules[$group] = $avgTTL
                    }
                }
            }
            
            $this.LastRuleUpdate = $now
        }
        catch {
            Write-Warning "Erreur lors de la mise à jour des règles de TTL: $_"
        }
    }
    
    # Analyser les patterns d'accès
    [hashtable] AnalyzeAccessPatterns([array]$keys) {
        $patterns = @{}
        
        # Regrouper les clés par pattern
        foreach ($keyStats in $keys) {
            $key = $keyStats.Key
            $pattern = $this.DetectKeyPattern($key)
            
            if (-not $patterns.ContainsKey($pattern)) {
                $patterns[$pattern] = @()
            }
            
            $patterns[$pattern] += $key
        }
        
        return $patterns
    }
    
    # Détecter le pattern d'une clé
    [string] DetectKeyPattern([string]$key) {
        # Exemples de patterns:
        # - "User:123" -> "User:*"
        # - "Config:App:Setting" -> "Config:App:*"
        # - "Data:2023-04-12:Stats" -> "Data:*:Stats"
        
        # Détecter les patterns courants
        if ($key -match "^([^:]+):(\d+)$") {
            # Pattern: Type:ID
            return "$($Matches[1]):*"
        }
        elseif ($key -match "^([^:]+):([^:]+):([^:]+)$") {
            # Pattern: Type:Subtype:ID
            return "$($Matches[1]):$($Matches[2]):*"
        }
        elseif ($key -match "^([^:]+):(\d{4}-\d{2}-\d{2}):(.+)$") {
            # Pattern: Type:Date:ID
            return "$($Matches[1]):*:$($Matches[3])"
        }
        
        # Si aucun pattern n'est détecté, retourner la clé elle-même
        return $key
    }
    
    # Obtenir le TTL optimal pour une clé et un pattern d'accès
    [int] GetOptimalTTL([string]$key, [PSCustomObject]$accessPattern) {
        # Si nous avons un pattern d'accès
        if ($accessPattern -ne $null) {
            # Calculer la moyenne des TTL récents
            $ttlHistory = $accessPattern.TTLHistory
            if ($ttlHistory.Count -gt 0) {
                $avgTTL = ($ttlHistory | Measure-Object -Average).Average
                return [Math]::Round($avgTTL)
            }
        }
        
        # Sinon, utiliser l'optimisation standard
        return $this.OptimizeTTL($key, $this.BaseCache.DefaultTTLSeconds)
    }
    
    # Obtenir les statistiques d'optimisation
    [PSCustomObject] GetOptimizationStatistics() {
        $ruleCount = $this.TTLRules.Count
        $patternCount = $this.KeyAccessPatterns.Count
        
        $ttlValues = $this.TTLRules.Values
        $avgTTL = if ($ttlValues.Count -gt 0) {
            ($ttlValues | Measure-Object -Average).Average
        } else { 0 }
        
        $minTTL = if ($ttlValues.Count -gt 0) {
            ($ttlValues | Measure-Object -Minimum).Minimum
        } else { 0 }
        
        $maxTTL = if ($ttlValues.Count -gt 0) {
            ($ttlValues | Measure-Object -Maximum).Maximum
        } else { 0 }
        
        return [PSCustomObject]@{
            RuleCount = $ruleCount
            PatternCount = $patternCount
            AverageTTL = $avgTTL
            MinimumTTL = $minTTL
            MaximumTTL = $maxTTL
            LastRuleUpdate = $this.LastRuleUpdate
        }
    }
}

# Fonctions exportées

<#
.SYNOPSIS
    Crée un nouvel optimiseur de TTL.
.DESCRIPTION
    Crée un nouvel optimiseur de TTL pour ajuster dynamiquement les durées de vie des éléments du cache.
.PARAMETER BaseCache
    Cache de base à utiliser.
.PARAMETER UsageCollector
    Collecteur d'utilisation à utiliser.
.EXAMPLE
    $optimizer = New-TTLOptimizer -BaseCache $cache -UsageCollector $collector
#>
function New-TTLOptimizer {
    [CmdletBinding()]
    [OutputType([TTLOptimizer])]
    param (
        [Parameter(Mandatory = $true)]
        [CacheManager]$BaseCache,
        
        [Parameter(Mandatory = $true)]
        [UsageCollector]$UsageCollector
    )
    
    try {
        return [TTLOptimizer]::new($BaseCache, $UsageCollector)
    }
    catch {
        Write-Error "Erreur lors de la création de l'optimiseur de TTL: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Configure les paramètres de l'optimiseur de TTL.
.DESCRIPTION
    Configure les paramètres de l'optimiseur de TTL comme les poids des facteurs et les limites de TTL.
.PARAMETER TTLOptimizer
    Optimiseur de TTL à configurer.
.PARAMETER MinimumTTL
    TTL minimum en secondes.
.PARAMETER MaximumTTL
    TTL maximum en secondes.
.PARAMETER FrequencyWeight
    Poids du facteur de fréquence.
.PARAMETER RecencyWeight
    Poids du facteur de récence.
.PARAMETER StabilityWeight
    Poids du facteur de stabilité.
.EXAMPLE
    Set-TTLOptimizerParameters -TTLOptimizer $optimizer -MinimumTTL 300 -MaximumTTL 43200
#>
function Set-TTLOptimizerParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [TTLOptimizer]$TTLOptimizer,
        
        [Parameter(Mandatory = $false)]
        [int]$MinimumTTL,
        
        [Parameter(Mandatory = $false)]
        [int]$MaximumTTL,
        
        [Parameter(Mandatory = $false)]
        [double]$FrequencyWeight,
        
        [Parameter(Mandatory = $false)]
        [double]$RecencyWeight,
        
        [Parameter(Mandatory = $false)]
        [double]$StabilityWeight
    )
    
    try {
        # Mettre à jour les paramètres
        if ($PSBoundParameters.ContainsKey('MinimumTTL')) {
            $TTLOptimizer.MinimumTTL = $MinimumTTL
        }
        
        if ($PSBoundParameters.ContainsKey('MaximumTTL')) {
            $TTLOptimizer.MaximumTTL = $MaximumTTL
        }
        
        if ($PSBoundParameters.ContainsKey('FrequencyWeight')) {
            $TTLOptimizer.FrequencyWeight = $FrequencyWeight
        }
        
        if ($PSBoundParameters.ContainsKey('RecencyWeight')) {
            $TTLOptimizer.RecencyWeight = $RecencyWeight
        }
        
        if ($PSBoundParameters.ContainsKey('StabilityWeight')) {
            $TTLOptimizer.StabilityWeight = $StabilityWeight
        }
        
        # Vérifier que les poids somment à 1
        $totalWeight = $TTLOptimizer.FrequencyWeight + $TTLOptimizer.RecencyWeight + $TTLOptimizer.StabilityWeight
        if ([Math]::Abs($totalWeight - 1.0) -gt 0.001) {
            Write-Warning "La somme des poids ($totalWeight) n'est pas égale à 1. Les résultats peuvent être incohérents."
        }
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de la configuration de l'optimiseur de TTL: $_"
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-TTLOptimizer, Set-TTLOptimizerParameters

#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'optimisation des TTL pour le cache prÃ©dictif.
.DESCRIPTION
    Ajuste dynamiquement les durÃ©es de vie (TTL) des Ã©lÃ©ments du cache
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
    
    # Optimiser le TTL pour une clÃ©
    [int] OptimizeTTL([string]$key, [int]$currentTTL) {
        # Si nous avons une rÃ¨gle spÃ©cifique pour cette clÃ©
        if ($this.TTLRules.ContainsKey($key)) {
            return $this.TTLRules[$key]
        }
        
        # Sinon, essayer de trouver une rÃ¨gle basÃ©e sur un pattern
        foreach ($pattern in $this.TTLRules.Keys) {
            if ($pattern.Contains("*") -and ($key -like $pattern)) {
                return $this.TTLRules[$pattern]
            }
        }
        
        # Si nous avons des donnÃ©es d'accÃ¨s pour cette clÃ©
        $keyStats = $this.UsageCollector.GetKeyAccessStats($key)
        if ($keyStats -ne $null) {
            return $this.CalculateOptimalTTL($keyStats, $currentTTL)
        }
        
        # Sinon, retourner le TTL actuel
        return $currentTTL
    }
    
    # Calculer le TTL optimal pour une clÃ©
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
        
        # Mettre Ã  jour le pattern d'accÃ¨s
        $this.UpdateAccessPattern($keyStats.Key, $optimalTTL)
        
        return $optimalTTL
    }
    
    # Calculer le facteur de frÃ©quence
    [double] CalculateFrequencyFactor([int]$accessCount) {
        # Normaliser le nombre d'accÃ¨s (0.0-1.0)
        # Plus d'accÃ¨s = TTL plus long
        return [Math]::Min(1.0, $accessCount / 100.0)
    }
    
    # Calculer le facteur de rÃ©cence
    [double] CalculateRecencyFactor([datetime]$lastAccess) {
        $now = Get-Date
        $hoursSinceLastAccess = ($now - $lastAccess).TotalHours
        
        # DÃ©croissance exponentielle: plus rÃ©cent = TTL plus long
        return [Math]::Exp(-0.1 * $hoursSinceLastAccess)
    }
    
    # Calculer le facteur de stabilitÃ©
    [double] CalculateStabilityFactor([double]$hitRatio) {
        # Plus le ratio de hits est Ã©levÃ©, plus le TTL est long
        return $hitRatio
    }
    
    # Mettre Ã  jour le pattern d'accÃ¨s pour une clÃ©
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
        
        # Limiter l'historique Ã  10 entrÃ©es
        if ($pattern.TTLHistory.Count -gt 10) {
            $pattern.TTLHistory = $pattern.TTLHistory | Select-Object -Last 10
        }
    }
    
    # Mettre Ã  jour les rÃ¨gles de TTL
    [void] UpdateTTLRules() {
        $now = Get-Date
        
        # VÃ©rifier si une mise Ã  jour est nÃ©cessaire
        if (($now - $this.LastRuleUpdate).TotalSeconds -lt $this.RuleUpdateInterval) {
            return
        }
        
        try {
            # RÃ©cupÃ©rer les clÃ©s les plus accÃ©dÃ©es
            $mostAccessedKeys = $this.UsageCollector.GetMostAccessedKeys(50, 1440)  # 50 clÃ©s les plus accÃ©dÃ©es dans les derniÃ¨res 24h
            
            # Analyser les patterns d'accÃ¨s
            $keyGroups = $this.AnalyzeAccessPatterns($mostAccessedKeys)
            
            # Mettre Ã  jour les rÃ¨gles
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
            Write-Warning "Erreur lors de la mise Ã  jour des rÃ¨gles de TTL: $_"
        }
    }
    
    # Analyser les patterns d'accÃ¨s
    [hashtable] AnalyzeAccessPatterns([array]$keys) {
        $patterns = @{}
        
        # Regrouper les clÃ©s par pattern
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
    
    # DÃ©tecter le pattern d'une clÃ©
    [string] DetectKeyPattern([string]$key) {
        # Exemples de patterns:
        # - "User:123" -> "User:*"
        # - "Config:App:Setting" -> "Config:App:*"
        # - "Data:2023-04-12:Stats" -> "Data:*:Stats"
        
        # DÃ©tecter les patterns courants
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
        
        # Si aucun pattern n'est dÃ©tectÃ©, retourner la clÃ© elle-mÃªme
        return $key
    }
    
    # Obtenir le TTL optimal pour une clÃ© et un pattern d'accÃ¨s
    [int] GetOptimalTTL([string]$key, [PSCustomObject]$accessPattern) {
        # Si nous avons un pattern d'accÃ¨s
        if ($accessPattern -ne $null) {
            # Calculer la moyenne des TTL rÃ©cents
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

# Fonctions exportÃ©es

<#
.SYNOPSIS
    CrÃ©e un nouvel optimiseur de TTL.
.DESCRIPTION
    CrÃ©e un nouvel optimiseur de TTL pour ajuster dynamiquement les durÃ©es de vie des Ã©lÃ©ments du cache.
.PARAMETER BaseCache
    Cache de base Ã  utiliser.
.PARAMETER UsageCollector
    Collecteur d'utilisation Ã  utiliser.
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
        Write-Error "Erreur lors de la crÃ©ation de l'optimiseur de TTL: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Configure les paramÃ¨tres de l'optimiseur de TTL.
.DESCRIPTION
    Configure les paramÃ¨tres de l'optimiseur de TTL comme les poids des facteurs et les limites de TTL.
.PARAMETER TTLOptimizer
    Optimiseur de TTL Ã  configurer.
.PARAMETER MinimumTTL
    TTL minimum en secondes.
.PARAMETER MaximumTTL
    TTL maximum en secondes.
.PARAMETER FrequencyWeight
    Poids du facteur de frÃ©quence.
.PARAMETER RecencyWeight
    Poids du facteur de rÃ©cence.
.PARAMETER StabilityWeight
    Poids du facteur de stabilitÃ©.
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
        # Mettre Ã  jour les paramÃ¨tres
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
        
        # VÃ©rifier que les poids somment Ã  1
        $totalWeight = $TTLOptimizer.FrequencyWeight + $TTLOptimizer.RecencyWeight + $TTLOptimizer.StabilityWeight
        if ([Math]::Abs($totalWeight - 1.0) -gt 0.001) {
            Write-Warning "La somme des poids ($totalWeight) n'est pas Ã©gale Ã  1. Les rÃ©sultats peuvent Ãªtre incohÃ©rents."
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

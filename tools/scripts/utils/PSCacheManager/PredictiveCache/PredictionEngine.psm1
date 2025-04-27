#Requires -Version 5.1
<#
.SYNOPSIS
    Module de prÃ©diction pour le cache prÃ©dictif.
.DESCRIPTION
    ImplÃ©mente des algorithmes de prÃ©diction pour anticiper les besoins futurs en cache.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Classe pour le moteur de prÃ©diction
class PredictionEngine {
    [UsageCollector]$UsageCollector
    [string]$CacheName
    [int]$PredictionHorizon = 3600  # Secondes
    [hashtable]$KeyProbabilities = @{}
    [hashtable]$SequencePredictions = @{}
    [datetime]$LastModelUpdate = [datetime]::MinValue
    [int]$ModelUpdateInterval = 300  # Secondes
    [int]$MinimumDataPoints = 5  # Nombre minimum de points de donnÃ©es pour faire une prÃ©diction
    
    # Constructeur
    PredictionEngine([UsageCollector]$usageCollector, [string]$cacheName) {
        $this.UsageCollector = $usageCollector
        $this.CacheName = $cacheName
        $this.UpdateModel()
    }
    
    # Mettre Ã  jour le modÃ¨le de prÃ©diction
    [void] UpdateModel() {
        $now = Get-Date
        
        # VÃ©rifier si une mise Ã  jour est nÃ©cessaire
        if (($now - $this.LastModelUpdate).TotalSeconds -lt $this.ModelUpdateInterval) {
            return
        }
        
        try {
            # RÃ©initialiser les probabilitÃ©s
            $this.KeyProbabilities = @{}
            $this.SequencePredictions = @{}
            
            # RÃ©cupÃ©rer les donnÃ©es d'utilisation
            $mostAccessedKeys = $this.UsageCollector.GetMostAccessedKeys(50, 60)  # 50 clÃ©s les plus accÃ©dÃ©es dans les 60 derniÃ¨res minutes
            $frequentSequences = $this.UsageCollector.GetFrequentSequences(30, 60)  # 30 sÃ©quences les plus frÃ©quentes dans les 60 derniÃ¨res minutes
            
            # Calculer les probabilitÃ©s pour les clÃ©s frÃ©quemment accÃ©dÃ©es
            foreach ($keyStats in $mostAccessedKeys) {
                $probability = $this.CalculateKeyProbability($keyStats)
                $this.KeyProbabilities[$keyStats.Key] = $probability
            }
            
            # Analyser les sÃ©quences pour les prÃ©dictions
            foreach ($sequence in $frequentSequences) {
                if ($sequence.SequenceCount -ge $this.MinimumDataPoints) {
                    if (-not $this.SequencePredictions.ContainsKey($sequence.FirstKey)) {
                        $this.SequencePredictions[$sequence.FirstKey] = @{}
                    }
                    
                    $confidence = $this.CalculateSequenceConfidence($sequence)
                    $this.SequencePredictions[$sequence.FirstKey][$sequence.SecondKey] = @{
                        Confidence = $confidence
                        AvgTimeDifference = $sequence.AvgTimeDifference
                        Count = $sequence.SequenceCount
                    }
                }
            }
            
            $this.LastModelUpdate = $now
        }
        catch {
            Write-Warning "Erreur lors de la mise Ã  jour du modÃ¨le de prÃ©diction: $_"
        }
    }
    
    # Calculer la probabilitÃ© d'accÃ¨s pour une clÃ©
    [double] CalculateKeyProbability([PSCustomObject]$keyStats) {
        # Facteurs de base
        $accessFactor = [Math]::Min(1.0, $keyStats.AccessCount / 100.0)  # NormalisÃ© Ã  100 accÃ¨s
        $hitRatioFactor = $keyStats.HitRatio
        $recencyFactor = $this.CalculateRecencyFactor($keyStats.LastAccess)
        
        # Combinaison des facteurs (avec pondÃ©ration)
        $probability = ($accessFactor * 0.5) + ($hitRatioFactor * 0.3) + ($recencyFactor * 0.2)
        
        return $probability
    }
    
    # Calculer le facteur de rÃ©cence
    [double] CalculateRecencyFactor([datetime]$lastAccess) {
        $now = Get-Date
        $minutesSinceLastAccess = ($now - $lastAccess).TotalMinutes
        
        # DÃ©croissance exponentielle: plus rÃ©cent = plus probable
        return [Math]::Exp(-0.05 * $minutesSinceLastAccess)
    }
    
    # Calculer la confiance dans une sÃ©quence
    [double] CalculateSequenceConfidence([PSCustomObject]$sequence) {
        # Facteurs de base
        $countFactor = [Math]::Min(1.0, $sequence.SequenceCount / 20.0)  # NormalisÃ© Ã  20 occurrences
        $timeFactor = [Math]::Min(1.0, 5000.0 / [Math]::Max(100, $sequence.AvgTimeDifference))  # Favorise les sÃ©quences rapides
        $recencyFactor = $this.CalculateRecencyFactor($sequence.LastOccurrence)
        
        # Combinaison des facteurs
        $confidence = ($countFactor * 0.6) + ($timeFactor * 0.2) + ($recencyFactor * 0.2)
        
        return $confidence
    }
    
    # PrÃ©dire les prochains accÃ¨s
    [array] PredictNextAccesses() {
        $this.UpdateModel()
        $predictions = @()
        
        try {
            # RÃ©cupÃ©rer les derniers accÃ¨s
            $recentAccesses = $this.UsageCollector.GetMostAccessedKeys(10, 5)  # 10 clÃ©s les plus accÃ©dÃ©es dans les 5 derniÃ¨res minutes
            
            # PrÃ©dictions basÃ©es sur les probabilitÃ©s gÃ©nÃ©rales
            foreach ($key in $this.KeyProbabilities.Keys) {
                $probability = $this.KeyProbabilities[$key]
                
                # Ajouter Ã  la liste des prÃ©dictions
                $predictions += [PSCustomObject]@{
                    Key = $key
                    Probability = $probability
                    Source = "FrequencyAnalysis"
                }
            }
            
            # PrÃ©dictions basÃ©es sur les sÃ©quences
            foreach ($recentKey in $recentAccesses) {
                $key = $recentKey.Key
                
                if ($this.SequencePredictions.ContainsKey($key)) {
                    $sequenceTargets = $this.SequencePredictions[$key]
                    
                    foreach ($targetKey in $sequenceTargets.Keys) {
                        $sequenceInfo = $sequenceTargets[$targetKey]
                        $confidence = $sequenceInfo.Confidence
                        
                        # VÃ©rifier si cette clÃ© est dÃ©jÃ  dans les prÃ©dictions
                        $existingPrediction = $predictions | Where-Object { $_.Key -eq $targetKey }
                        
                        if ($existingPrediction) {
                            # Mettre Ã  jour la probabilitÃ© si la confiance est plus Ã©levÃ©e
                            if ($confidence -gt $existingPrediction.Probability) {
                                $existingPrediction.Probability = $confidence
                                $existingPrediction.Source = "SequenceAnalysis"
                            }
                        }
                        else {
                            # Ajouter une nouvelle prÃ©diction
                            $predictions += [PSCustomObject]@{
                                Key = $targetKey
                                Probability = $confidence
                                Source = "SequenceAnalysis"
                            }
                        }
                    }
                }
            }
            
            # Trier par probabilitÃ© dÃ©croissante
            $predictions = $predictions | Sort-Object -Property Probability -Descending
        }
        catch {
            Write-Warning "Erreur lors de la prÃ©diction des prochains accÃ¨s: $_"
        }
        
        return $predictions
    }
    
    # Calculer la probabilitÃ© pour une clÃ© spÃ©cifique
    [double] CalculateKeyProbability([string]$key) {
        $this.UpdateModel()
        
        if ($this.KeyProbabilities.ContainsKey($key)) {
            return $this.KeyProbabilities[$key]
        }
        
        # Si la clÃ© n'est pas dans le modÃ¨le, rÃ©cupÃ©rer ses statistiques
        $keyStats = $this.UsageCollector.GetKeyAccessStats($key)
        
        if ($keyStats -ne $null) {
            return $this.CalculateKeyProbability($keyStats)
        }
        
        return 0.0
    }
    
    # Obtenir les prÃ©dictions pour une clÃ© spÃ©cifique
    [array] GetPredictionsForKey([string]$key) {
        $this.UpdateModel()
        $predictions = @()
        
        if ($this.SequencePredictions.ContainsKey($key)) {
            $sequenceTargets = $this.SequencePredictions[$key]
            
            foreach ($targetKey in $sequenceTargets.Keys) {
                $sequenceInfo = $sequenceTargets[$targetKey]
                
                $predictions += [PSCustomObject]@{
                    Key = $targetKey
                    Probability = $sequenceInfo.Confidence
                    AvgTimeDifference = $sequenceInfo.AvgTimeDifference
                    Count = $sequenceInfo.Count
                }
            }
            
            # Trier par probabilitÃ© dÃ©croissante
            $predictions = $predictions | Sort-Object -Property Probability -Descending
        }
        
        return $predictions
    }
}

# Fonctions exportÃ©es

<#
.SYNOPSIS
    CrÃ©e un nouveau moteur de prÃ©diction.
.DESCRIPTION
    CrÃ©e un nouveau moteur de prÃ©diction pour anticiper les besoins futurs en cache.
.PARAMETER UsageCollector
    Collecteur d'utilisation Ã  utiliser.
.PARAMETER CacheName
    Nom du cache.
.EXAMPLE
    $engine = New-PredictionEngine -UsageCollector $collector -CacheName "MyCache"
#>
function New-PredictionEngine {
    [CmdletBinding()]
    [OutputType([PredictionEngine])]
    param (
        [Parameter(Mandatory = $true)]
        [UsageCollector]$UsageCollector,
        
        [Parameter(Mandatory = $true)]
        [string]$CacheName
    )
    
    try {
        return [PredictionEngine]::new($UsageCollector, $CacheName)
    }
    catch {
        Write-Error "Erreur lors de la crÃ©ation du moteur de prÃ©diction: $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-PredictionEngine

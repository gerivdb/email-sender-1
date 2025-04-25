<#
.SYNOPSIS
    Optimise la mise en cache prédictive et adaptative pour les scripts PowerShell.
.DESCRIPTION
    Ce script analyse les données d'utilisation collectées par le module UsageMonitor
    et optimise la mise en cache en préchargeant les données fréquemment utilisées
    et en adaptant les stratégies d'invalidation en fonction des patterns d'utilisation.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration de cache.
.PARAMETER DatabasePath
    Chemin vers le fichier de base de données d'utilisation.
.PARAMETER Apply
    Indique si les optimisations doivent être appliquées automatiquement.
.EXAMPLE
    .\Optimize-Caching.ps1 -Apply
.NOTES
    Auteur: Augment Agent
    Date: 2025-05-15
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath "cache_config.json"),
    
    [Parameter(Mandatory = $false)]
    [string]$DatabasePath = (Join-Path -Path $env:TEMP -ChildPath "UsageMonitor\usage_data.xml"),
    
    [Parameter(Mandatory = $false)]
    [switch]$Apply
)

# Importer les modules nécessaires
$usageMonitorPath = Join-Path -Path $PSScriptRoot -ChildPath "UsageMonitor.psm1"
Import-Module $usageMonitorPath -Force

$psCacheManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "utils\PSCacheManager\PSCacheManager.psm1"
if (Test-Path -Path $psCacheManagerPath) {
    Import-Module $psCacheManagerPath -Force
}
else {
    Write-Error "Module PSCacheManager non trouvé: $psCacheManagerPath"
    exit 1
}

# Fonction pour écrire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
}

# Fonction pour analyser les patterns d'utilisation du cache
function Analyze-CacheUsagePatterns {
    param (
        [PSCustomObject]$UsageStats
    )
    
    $cachePatterns = @{}
    
    # Analyser les scripts les plus utilisés
    foreach ($scriptPath in $UsageStats.TopUsedScripts.Keys) {
        $metrics = $script:UsageDatabase.GetMetricsForScript($scriptPath)
        
        # Extraire les paramètres utilisés
        $parameterSets = @{}
        
        foreach ($metric in $metrics) {
            if ($metric.Parameters) {
                $paramKey = ($metric.Parameters.Keys | Sort-Object) -join ","
                $paramValues = ($metric.Parameters.Values | ForEach-Object { "$_" }) -join ","
                $paramHash = "$paramKey:$paramValues"
                
                if (-not $parameterSets.ContainsKey($paramHash)) {
                    $parameterSets[$paramHash] = 0
                }
                
                $parameterSets[$paramHash]++
            }
        }
        
        # Identifier les ensembles de paramètres fréquemment utilisés
        $frequentParams = $parameterSets.GetEnumerator() | 
            Where-Object { $_.Value -gt 2 } | 
            Sort-Object -Property Value -Descending
        
        if ($frequentParams.Count -gt 0) {
            $cachePatterns[$scriptPath] = @{
                FrequentParameters = $frequentParams
                ExecutionCount = $UsageStats.TopUsedScripts[$scriptPath]
                AverageDuration = 0
            }
            
            # Calculer la durée moyenne d'exécution
            $successfulExecutions = $metrics | Where-Object { $_.Success }
            if ($successfulExecutions.Count -gt 0) {
                $totalDuration = [timespan]::Zero
                foreach ($execution in $successfulExecutions) {
                    $totalDuration += $execution.Duration
                }
                $cachePatterns[$scriptPath].AverageDuration = $totalDuration.TotalMilliseconds / $successfulExecutions.Count
            }
        }
    }
    
    return $cachePatterns
}

# Fonction pour analyser les séquences d'exécution
function Analyze-ExecutionSequences {
    param (
        [PSCustomObject]$UsageStats
    )
    
    $sequences = @{}
    $allMetrics = @()
    
    # Collecter toutes les métriques triées par heure de début
    foreach ($scriptPath in $UsageStats.TopUsedScripts.Keys) {
        $metrics = $script:UsageDatabase.GetMetricsForScript($scriptPath)
        foreach ($metric in $metrics) {
            $allMetrics += [PSCustomObject]@{
                ScriptPath = $scriptPath
                StartTime = $metric.StartTime
                EndTime = $metric.EndTime
                Duration = $metric.Duration
                Success = $metric.Success
                Parameters = $metric.Parameters
            }
        }
    }
    
    # Trier les métriques par heure de début
    $sortedMetrics = $allMetrics | Sort-Object -Property StartTime
    
    # Analyser les séquences d'exécution
    for ($i = 0; $i -lt ($sortedMetrics.Count - 1); $i++) {
        $current = $sortedMetrics[$i]
        $next = $sortedMetrics[$i + 1]
        
        # Vérifier si les scripts sont exécutés dans un intervalle de temps court
        $timeDiff = ($next.StartTime - $current.EndTime).TotalSeconds
        
        if ($timeDiff -lt 60) {  # Moins d'une minute entre les exécutions
            $sequenceKey = "$($current.ScriptPath) -> $($next.ScriptPath)"
            
            if (-not $sequences.ContainsKey($sequenceKey)) {
                $sequences[$sequenceKey] = @{
                    Count = 0
                    AverageTimeDiff = 0
                    TotalTimeDiff = 0
                    FirstScript = $current.ScriptPath
                    SecondScript = $next.ScriptPath
                }
            }
            
            $sequences[$sequenceKey].Count++
            $sequences[$sequenceKey].TotalTimeDiff += $timeDiff
            $sequences[$sequenceKey].AverageTimeDiff = $sequences[$sequenceKey].TotalTimeDiff / $sequences[$sequenceKey].Count
        }
    }
    
    # Filtrer les séquences fréquentes
    $frequentSequences = $sequences.GetEnumerator() | 
        Where-Object { $_.Value.Count -gt 2 } | 
        Sort-Object -Property { $_.Value.Count } -Descending
    
    $result = @{}
    foreach ($seq in $frequentSequences) {
        $result[$seq.Key] = $seq.Value
    }
    
    return $result
}

# Fonction pour générer une configuration de cache optimisée
function Generate-CacheConfig {
    param (
        [hashtable]$CachePatterns,
        [hashtable]$ExecutionSequences
    )
    
    $config = @{
        GlobalSettings = @{
            DefaultTTLSeconds = 3600  # 1 heure par défaut
            MaxMemoryItems = 1000
            EnableDiskCache = $true
            EvictionPolicy = "LFU"  # Least Frequently Used
            ExtendTtlOnAccess = $true
        }
        ScriptSpecificSettings = @{}
        PreloadPatterns = @{}
        PredictiveSequences = @{}
    }
    
    # Configurer les paramètres spécifiques aux scripts
    foreach ($scriptPath in $CachePatterns.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $pattern = $CachePatterns[$scriptPath]
        
        # Calculer le TTL optimal en fonction de la fréquence d'utilisation et de la durée
        $executionCount = $pattern.ExecutionCount
        $avgDuration = $pattern.AverageDuration
        
        # Plus le script est utilisé fréquemment, plus le TTL est long
        $ttlFactor = [math]::Log10($executionCount + 1) * 2
        
        # Plus le script est lent, plus le TTL est long (pour éviter de recalculer des opérations coûteuses)
        $durationFactor = [math]::Log10($avgDuration + 1)
        
        # Calculer le TTL optimal (entre 10 minutes et 24 heures)
        $optimalTTL = [math]::Max(600, [math]::Min(86400, [math]::Round(3600 * ($ttlFactor + $durationFactor))))
        
        $config.ScriptSpecificSettings[$scriptPath] = @{
            TTLSeconds = $optimalTTL
            ExtendTtlOnAccess = $true
            EvictionPolicy = "LFU"
        }
        
        # Configurer les patterns de préchargement
        $frequentParams = $pattern.FrequentParameters | Select-Object -First 5
        if ($frequentParams.Count -gt 0) {
            $config.PreloadPatterns[$scriptPath] = @{
                Enabled = $true
                Parameters = @{}
            }
            
            foreach ($param in $frequentParams) {
                $paramHash = $param.Name
                $config.PreloadPatterns[$scriptPath].Parameters[$paramHash] = $param.Value
            }
        }
    }
    
    # Configurer les séquences prédictives
    foreach ($sequenceKey in $ExecutionSequences.Keys) {
        $sequence = $ExecutionSequences[$sequenceKey]
        
        if ($sequence.Count -gt 3) {  # Séquence fréquente
            $config.PredictiveSequences[$sequenceKey] = @{
                FirstScript = $sequence.FirstScript
                SecondScript = $sequence.SecondScript
                AverageTimeDiff = $sequence.AverageTimeDiff
                Count = $sequence.Count
                Enabled = $true
            }
        }
    }
    
    return $config
}

# Fonction pour générer le code de préchargement du cache
function Generate-CachePreloadCode {
    param (
        [hashtable]$Config
    )
    
    $preloadCode = @"
<#
.SYNOPSIS
    Script de préchargement du cache pour les scripts fréquemment utilisés.
.DESCRIPTION
    Ce script précharge le cache avec des données fréquemment utilisées
    pour améliorer les performances des scripts.
.NOTES
    Généré automatiquement par Optimize-Caching.ps1
    Date de génération: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#>

# Importer le module PSCacheManager
`$psCacheManagerPath = Join-Path -Path (Split-Path -Parent `$PSScriptRoot) -ChildPath "utils\PSCacheManager\PSCacheManager.psm1"
if (Test-Path -Path `$psCacheManagerPath) {
    Import-Module `$psCacheManagerPath -Force
}
else {
    Write-Error "Module PSCacheManager non trouvé: `$psCacheManagerPath"
    exit 1
}

# Fonction pour écrire des messages de log
function Write-Log {
    param (
        [string]`$Message,
        [string]`$Level = "INFO"
    )
    
    `$TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
    }
    
    `$Color = `$ColorMap[`$Level]
    `$FormattedMessage = "[`$TimeStamp] [`$Level] `$Message"
    
    Write-Host `$FormattedMessage -ForegroundColor `$Color
}

# Créer les caches
Write-Log "Création des caches..." -Level "INFO"

"@
    
    # Ajouter le code pour créer les caches
    foreach ($scriptPath in $Config.ScriptSpecificSettings.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $settings = $Config.ScriptSpecificSettings[$scriptPath]
        
        $cacheName = $scriptName -replace "\.ps1|\.psm1", ""
        $ttl = $settings.TTLSeconds
        $evictionPolicy = $settings.EvictionPolicy
        $extendTtl = $settings.ExtendTtlOnAccess.ToString().ToLower()
        
        $preloadCode += @"
`$${cacheName}Cache = New-PSCache -Name "$cacheName" -DefaultTTLSeconds $ttl -EvictionPolicy "$evictionPolicy" -ExtendTtlOnAccess:`$$extendTtl
Write-Log "Cache créé: $cacheName" -Level "SUCCESS"

"@
    }
    
    # Ajouter le code pour précharger les données
    $preloadCode += @"
# Précharger les données fréquemment utilisées
Write-Log "Préchargement des données..." -Level "INFO"

"@
    
    foreach ($scriptPath in $Config.PreloadPatterns.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $pattern = $Config.PreloadPatterns[$scriptPath]
        
        if ($pattern.Enabled -and $pattern.Parameters.Count -gt 0) {
            $cacheName = $scriptName -replace "\.ps1|\.psm1", ""
            
            $preloadCode += @"
# Préchargement pour $scriptName
Write-Log "Préchargement des données pour $scriptName..." -Level "INFO"
try {
    # Charger le script
    `$scriptPath = "$scriptPath"
    if (Test-Path -Path `$scriptPath) {
        . `$scriptPath
        
        # Précharger les données avec les paramètres fréquemment utilisés
"@
            
            foreach ($paramHash in $pattern.Parameters.Keys) {
                $count = $pattern.Parameters[$paramHash]
                
                # Extraire les paramètres du hash
                if ($paramHash -match "^(.*?):(.*?)$") {
                    $paramKeys = $matches[1] -split ","
                    $paramValues = $matches[2] -split ","
                    
                    if ($paramKeys.Count -eq $paramValues.Count) {
                        $paramCode = "@{"
                        for ($i = 0; $i -lt $paramKeys.Count; $i++) {
                            $key = $paramKeys[$i].Trim()
                            $value = $paramValues[$i].Trim()
                            
                            # Essayer de déterminer le type de la valeur
                            if ($value -match "^\d+$") {
                                # Entier
                                $paramCode += "$key = $value; "
                            }
                            elseif ($value -match "^\d+\.\d+$") {
                                # Décimal
                                $paramCode += "$key = $value; "
                            }
                            elseif ($value -eq "true" -or $value -eq "false") {
                                # Booléen
                                $paramCode += "$key = `$$value; "
                            }
                            else {
                                # Chaîne
                                $paramCode += "$key = '$value'; "
                            }
                        }
                        $paramCode += "}"
                        
                        $preloadCode += @"
        
        # Paramètres utilisés $count fois
        `$params = $paramCode
        `$cacheKey = "$(($scriptName -replace "\.ps1|\.psm1", ""))_" + ((`$params.Keys | Sort-Object) -join "_") + "_" + ((`$params.Values | ForEach-Object { "`$_" }) -join "_")
        
        Get-PSCacheItem -Cache `$${cacheName}Cache -Key `$cacheKey -GenerateValue {
            Write-Log "Génération des données pour `$cacheKey..." -Level "INFO"
            # Appeler la fonction principale du script avec les paramètres
            # Note: Ceci est une approximation, le script réel peut nécessiter des ajustements
            `$result = & `$scriptPath @params
            return `$result
        } | Out-Null
"@
                    }
                }
            }
            
            $preloadCode += @"
    }
    else {
        Write-Log "Script non trouvé: `$scriptPath" -Level "WARNING"
    }
}
catch {
    Write-Log "Erreur lors du préchargement des données pour $scriptName: `$_" -Level "ERROR"
}

"@
        }
    }
    
    # Ajouter le code pour les séquences prédictives
    if ($Config.PredictiveSequences.Count -gt 0) {
        $preloadCode += @"
# Configurer les séquences prédictives
Write-Log "Configuration des séquences prédictives..." -Level "INFO"

`$predictiveSequences = @{

"@
        
        foreach ($sequenceKey in $Config.PredictiveSequences.Keys) {
            $sequence = $Config.PredictiveSequences[$sequenceKey]
            
            if ($sequence.Enabled) {
                $firstScript = Split-Path -Path $sequence.FirstScript -Leaf
                $secondScript = Split-Path -Path $sequence.SecondScript -Leaf
                
                $preloadCode += @"
    "$sequenceKey" = @{
        FirstScript = "$($sequence.FirstScript)"
        SecondScript = "$($sequence.SecondScript)"
        AverageTimeDiff = $($sequence.AverageTimeDiff)
        Count = $($sequence.Count)
    }
    
"@
            }
        }
        
        $preloadCode += @"
}

# Enregistrer les séquences prédictives pour utilisation future
`$predictiveSequencesPath = Join-Path -Path `$PSScriptRoot -ChildPath "predictive_sequences.xml"
`$predictiveSequences | Export-Clixml -Path `$predictiveSequencesPath -Force

Write-Log "Séquences prédictives configurées et enregistrées." -Level "SUCCESS"
"@
    }
    
    $preloadCode += @"

Write-Log "Préchargement du cache terminé." -Level "SUCCESS"
"@
    
    return $preloadCode
}

# Fonction pour appliquer la configuration de cache
function Apply-CacheConfig {
    param (
        [hashtable]$Config,
        [string]$ConfigPath,
        [switch]$Apply
    )
    
    # Sauvegarder la configuration dans un fichier JSON
    $Config | ConvertTo-Json -Depth 5 | Out-File -FilePath $ConfigPath -Encoding utf8 -Force
    
    Write-Log "Configuration de cache sauvegardée: $ConfigPath" -Level "SUCCESS"
    
    # Générer le code de préchargement du cache
    $preloadCode = Generate-CachePreloadCode -Config $Config
    $preloadPath = Join-Path -Path $PSScriptRoot -ChildPath "Preload-Cache.ps1"
    
    $preloadCode | Out-File -FilePath $preloadPath -Encoding utf8 -Force
    
    Write-Log "Script de préchargement du cache généré: $preloadPath" -Level "SUCCESS"
    
    # Rechercher les scripts qui utilisent PSCacheManager
    $cacheScripts = Get-ChildItem -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -Filter "*.ps1" -Recurse |
        Where-Object { (Get-Content -Path $_.FullName -Raw) -match "PSCacheManager|New-PSCache|Get-PSCacheItem" }
    
    Write-Log "Nombre de scripts utilisant le cache trouvés: $($cacheScripts.Count)" -Level "INFO"
    
    if ($Apply) {
        foreach ($script in $cacheScripts) {
            $scriptPath = $script.FullName
            $scriptName = $script.Name
            
            # Vérifier si le script a une configuration spécifique
            if ($Config.ScriptSpecificSettings.ContainsKey($scriptPath)) {
                Write-Log "Application de la configuration à: $scriptName" -Level "INFO"
                
                $content = Get-Content -Path $scriptPath -Raw
                $settings = $Config.ScriptSpecificSettings[$scriptPath]
                
                # Rechercher les appels à New-PSCache
                if ($content -match "New-PSCache\s+(?:-Name\s+)?[\"']([^\"']+)[\"'](?:\s+-DefaultTTLSeconds\s+)?(\d+)?(?:\s+-EvictionPolicy\s+)?[\"']?(\w+)?[\"']?(?:\s+-ExtendTtlOnAccess:)?(\`$\w+|true|false)?") {
                    $currentName = $matches[1]
                    $currentTTL = $matches[2]
                    $currentPolicy = $matches[3]
                    $currentExtendTtl = $matches[4]
                    
                    # Remplacer les paramètres par ceux de la configuration
                    $newContent = $content
                    
                    if ($currentTTL) {
                        $newContent = $newContent -replace "(-DefaultTTLSeconds\s+)(\d+)", "`$1$($settings.TTLSeconds)"
                    }
                    
                    if ($currentPolicy) {
                        $newContent = $newContent -replace "(-EvictionPolicy\s+)[\"']?(\w+)[\"']?", "`$1'$($settings.EvictionPolicy)'"
                    }
                    
                    if ($currentExtendTtl) {
                        $extendTtl = $settings.ExtendTtlOnAccess.ToString().ToLower()
                        $newContent = $newContent -replace "(-ExtendTtlOnAccess:)(\`$\w+|true|false)", "`$1`$$extendTtl"
                    }
                    
                    # Sauvegarder le script modifié
                    Set-Content -Path $scriptPath -Value $newContent -Force
                    
                    Write-Log "Configuration appliquée à: $scriptName" -Level "SUCCESS"
                }
                else {
                    Write-Log "Aucun appel à New-PSCache trouvé dans: $scriptName" -Level "WARNING"
                }
            }
        }
        
        # Créer une tâche planifiée pour exécuter le script de préchargement
        $taskName = "PreloadCacheTask"
        $taskPath = "\EMAIL_SENDER_1\"
        $taskCommand = "powershell.exe"
        $taskArgs = "-ExecutionPolicy Bypass -File `"$preloadPath`""
        
        Write-Log "Création d'une tâche planifiée pour le préchargement du cache..." -Level "INFO"
        
        try {
            # Vérifier si la tâche existe déjà
            $existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
            
            if ($existingTask) {
                # Supprimer la tâche existante
                Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
            }
            
            # Créer une nouvelle tâche
            $action = New-ScheduledTaskAction -Execute $taskCommand -Argument $taskArgs
            $trigger = New-ScheduledTaskTrigger -Daily -At "3:00 AM"
            $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
            
            Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Settings $settings -Description "Préchargement du cache pour les scripts fréquemment utilisés"
            
            Write-Log "Tâche planifiée créée avec succès." -Level "SUCCESS"
        }
        catch {
            Write-Log "Erreur lors de la création de la tâche planifiée: $_" -Level "ERROR"
        }
    }
    else {
        Write-Log "Mode simulation: la configuration n'a pas été appliquée aux scripts. Utilisez -Apply pour appliquer les modifications." -Level "WARNING"
    }
}

# Point d'entrée principal
Write-Log "Démarrage de l'optimisation du cache..." -Level "TITLE"

# Vérifier si le fichier de base de données existe
if (-not (Test-Path -Path $DatabasePath)) {
    Write-Log "Le fichier de base de données spécifié n'existe pas: $DatabasePath" -Level "ERROR"
    exit 1
}

# Initialiser le moniteur d'utilisation avec la base de données spécifiée
Initialize-UsageMonitor -DatabasePath $DatabasePath
Write-Log "Base de données d'utilisation chargée: $DatabasePath" -Level "INFO"

# Récupérer les statistiques d'utilisation
$usageStats = Get-ScriptUsageStatistics
Write-Log "Statistiques d'utilisation récupérées" -Level "INFO"

# Analyser les patterns d'utilisation du cache
$cachePatterns = Analyze-CacheUsagePatterns -UsageStats $usageStats
Write-Log "Patterns d'utilisation du cache analysés: $($cachePatterns.Count) scripts avec patterns" -Level "INFO"

# Analyser les séquences d'exécution
$executionSequences = Analyze-ExecutionSequences -UsageStats $usageStats
Write-Log "Séquences d'exécution analysées: $($executionSequences.Count) séquences fréquentes" -Level "INFO"

# Générer la configuration de cache
$cacheConfig = Generate-CacheConfig -CachePatterns $cachePatterns -ExecutionSequences $executionSequences
Write-Log "Configuration de cache générée" -Level "INFO"

# Appliquer la configuration
Apply-CacheConfig -Config $cacheConfig -ConfigPath $ConfigPath -Apply:$Apply

Write-Log "Optimisation du cache terminée." -Level "TITLE"

<#
.SYNOPSIS
    Optimise la mise en cache prÃ©dictive et adaptative pour les scripts PowerShell.
.DESCRIPTION
    Ce script analyse les donnÃ©es d'utilisation collectÃ©es par le module UsageMonitor
    et optimise la mise en cache en prÃ©chargeant les donnÃ©es frÃ©quemment utilisÃ©es
    et en adaptant les stratÃ©gies d'invalidation en fonction des patterns d'utilisation.
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration de cache.
.PARAMETER DatabasePath
    Chemin vers le fichier de base de donnÃ©es d'utilisation.
.PARAMETER Apply
    Indique si les optimisations doivent Ãªtre appliquÃ©es automatiquement.
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

# Importer les modules nÃ©cessaires
$usageMonitorPath = Join-Path -Path $PSScriptRoot -ChildPath "UsageMonitor.psm1"
Import-Module $usageMonitorPath -Force

$psCacheManagerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "utils\PSCacheManager\PSCacheManager.psm1"
if (Test-Path -Path $psCacheManagerPath) {
    Import-Module $psCacheManagerPath -Force
}
else {
    Write-Error "Module PSCacheManager non trouvÃ©: $psCacheManagerPath"
    exit 1
}

# Fonction pour Ã©crire des messages de log
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
    
    # Analyser les scripts les plus utilisÃ©s
    foreach ($scriptPath in $UsageStats.TopUsedScripts.Keys) {
        $metrics = $script:UsageDatabase.GetMetricsForScript($scriptPath)
        
        # Extraire les paramÃ¨tres utilisÃ©s
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
        
        # Identifier les ensembles de paramÃ¨tres frÃ©quemment utilisÃ©s
        $frequentParams = $parameterSets.GetEnumerator() | 
            Where-Object { $_.Value -gt 2 } | 
            Sort-Object -Property Value -Descending
        
        if ($frequentParams.Count -gt 0) {
            $cachePatterns[$scriptPath] = @{
                FrequentParameters = $frequentParams
                ExecutionCount = $UsageStats.TopUsedScripts[$scriptPath]
                AverageDuration = 0
            }
            
            # Calculer la durÃ©e moyenne d'exÃ©cution
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

# Fonction pour analyser les sÃ©quences d'exÃ©cution
function Analyze-ExecutionSequences {
    param (
        [PSCustomObject]$UsageStats
    )
    
    $sequences = @{}
    $allMetrics = @()
    
    # Collecter toutes les mÃ©triques triÃ©es par heure de dÃ©but
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
    
    # Trier les mÃ©triques par heure de dÃ©but
    $sortedMetrics = $allMetrics | Sort-Object -Property StartTime
    
    # Analyser les sÃ©quences d'exÃ©cution
    for ($i = 0; $i -lt ($sortedMetrics.Count - 1); $i++) {
        $current = $sortedMetrics[$i]
        $next = $sortedMetrics[$i + 1]
        
        # VÃ©rifier si les scripts sont exÃ©cutÃ©s dans un intervalle de temps court
        $timeDiff = ($next.StartTime - $current.EndTime).TotalSeconds
        
        if ($timeDiff -lt 60) {  # Moins d'une minute entre les exÃ©cutions
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
    
    # Filtrer les sÃ©quences frÃ©quentes
    $frequentSequences = $sequences.GetEnumerator() | 
        Where-Object { $_.Value.Count -gt 2 } | 
        Sort-Object -Property { $_.Value.Count } -Descending
    
    $result = @{}
    foreach ($seq in $frequentSequences) {
        $result[$seq.Key] = $seq.Value
    }
    
    return $result
}

# Fonction pour gÃ©nÃ©rer une configuration de cache optimisÃ©e
function Generate-CacheConfig {
    param (
        [hashtable]$CachePatterns,
        [hashtable]$ExecutionSequences
    )
    
    $config = @{
        GlobalSettings = @{
            DefaultTTLSeconds = 3600  # 1 heure par dÃ©faut
            MaxMemoryItems = 1000
            EnableDiskCache = $true
            EvictionPolicy = "LFU"  # Least Frequently Used
            ExtendTtlOnAccess = $true
        }
        ScriptSpecificSettings = @{}
        PreloadPatterns = @{}
        PredictiveSequences = @{}
    }
    
    # Configurer les paramÃ¨tres spÃ©cifiques aux scripts
    foreach ($scriptPath in $CachePatterns.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $pattern = $CachePatterns[$scriptPath]
        
        # Calculer le TTL optimal en fonction de la frÃ©quence d'utilisation et de la durÃ©e
        $executionCount = $pattern.ExecutionCount
        $avgDuration = $pattern.AverageDuration
        
        # Plus le script est utilisÃ© frÃ©quemment, plus le TTL est long
        $ttlFactor = [math]::Log10($executionCount + 1) * 2
        
        # Plus le script est lent, plus le TTL est long (pour Ã©viter de recalculer des opÃ©rations coÃ»teuses)
        $durationFactor = [math]::Log10($avgDuration + 1)
        
        # Calculer le TTL optimal (entre 10 minutes et 24 heures)
        $optimalTTL = [math]::Max(600, [math]::Min(86400, [math]::Round(3600 * ($ttlFactor + $durationFactor))))
        
        $config.ScriptSpecificSettings[$scriptPath] = @{
            TTLSeconds = $optimalTTL
            ExtendTtlOnAccess = $true
            EvictionPolicy = "LFU"
        }
        
        # Configurer les patterns de prÃ©chargement
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
    
    # Configurer les sÃ©quences prÃ©dictives
    foreach ($sequenceKey in $ExecutionSequences.Keys) {
        $sequence = $ExecutionSequences[$sequenceKey]
        
        if ($sequence.Count -gt 3) {  # SÃ©quence frÃ©quente
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

# Fonction pour gÃ©nÃ©rer le code de prÃ©chargement du cache
function Generate-CachePreloadCode {
    param (
        [hashtable]$Config
    )
    
    $preloadCode = @"
<#
.SYNOPSIS
    Script de prÃ©chargement du cache pour les scripts frÃ©quemment utilisÃ©s.
.DESCRIPTION
    Ce script prÃ©charge le cache avec des donnÃ©es frÃ©quemment utilisÃ©es
    pour amÃ©liorer les performances des scripts.
.NOTES
    GÃ©nÃ©rÃ© automatiquement par Optimize-Caching.ps1
    Date de gÃ©nÃ©ration: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
#>

# Importer le module PSCacheManager
`$psCacheManagerPath = Join-Path -Path (Split-Path -Parent `$PSScriptRoot) -ChildPath "utils\PSCacheManager\PSCacheManager.psm1"
if (Test-Path -Path `$psCacheManagerPath) {
    Import-Module `$psCacheManagerPath -Force
}
else {
    Write-Error "Module PSCacheManager non trouvÃ©: `$psCacheManagerPath"
    exit 1
}

# Fonction pour Ã©crire des messages de log
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

# CrÃ©er les caches
Write-Log "CrÃ©ation des caches..." -Level "INFO"

"@
    
    # Ajouter le code pour crÃ©er les caches
    foreach ($scriptPath in $Config.ScriptSpecificSettings.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $settings = $Config.ScriptSpecificSettings[$scriptPath]
        
        $cacheName = $scriptName -replace "\.ps1|\.psm1", ""
        $ttl = $settings.TTLSeconds
        $evictionPolicy = $settings.EvictionPolicy
        $extendTtl = $settings.ExtendTtlOnAccess.ToString().ToLower()
        
        $preloadCode += @"
`$${cacheName}Cache = New-PSCache -Name "$cacheName" -DefaultTTLSeconds $ttl -EvictionPolicy "$evictionPolicy" -ExtendTtlOnAccess:`$$extendTtl
Write-Log "Cache crÃ©Ã©: $cacheName" -Level "SUCCESS"

"@
    }
    
    # Ajouter le code pour prÃ©charger les donnÃ©es
    $preloadCode += @"
# PrÃ©charger les donnÃ©es frÃ©quemment utilisÃ©es
Write-Log "PrÃ©chargement des donnÃ©es..." -Level "INFO"

"@
    
    foreach ($scriptPath in $Config.PreloadPatterns.Keys) {
        $scriptName = Split-Path -Path $scriptPath -Leaf
        $pattern = $Config.PreloadPatterns[$scriptPath]
        
        if ($pattern.Enabled -and $pattern.Parameters.Count -gt 0) {
            $cacheName = $scriptName -replace "\.ps1|\.psm1", ""
            
            $preloadCode += @"
# PrÃ©chargement pour $scriptName
Write-Log "PrÃ©chargement des donnÃ©es pour $scriptName..." -Level "INFO"
try {
    # Charger le script
    `$scriptPath = "$scriptPath"
    if (Test-Path -Path `$scriptPath) {
        . `$scriptPath
        
        # PrÃ©charger les donnÃ©es avec les paramÃ¨tres frÃ©quemment utilisÃ©s
"@
            
            foreach ($paramHash in $pattern.Parameters.Keys) {
                $count = $pattern.Parameters[$paramHash]
                
                # Extraire les paramÃ¨tres du hash
                if ($paramHash -match "^(.*?):(.*?)$") {
                    $paramKeys = $matches[1] -split ","
                    $paramValues = $matches[2] -split ","
                    
                    if ($paramKeys.Count -eq $paramValues.Count) {
                        $paramCode = "@{"
                        for ($i = 0; $i -lt $paramKeys.Count; $i++) {
                            $key = $paramKeys[$i].Trim()
                            $value = $paramValues[$i].Trim()
                            
                            # Essayer de dÃ©terminer le type de la valeur
                            if ($value -match "^\d+$") {
                                # Entier
                                $paramCode += "$key = $value; "
                            }
                            elseif ($value -match "^\d+\.\d+$") {
                                # DÃ©cimal
                                $paramCode += "$key = $value; "
                            }
                            elseif ($value -eq "true" -or $value -eq "false") {
                                # BoolÃ©en
                                $paramCode += "$key = `$$value; "
                            }
                            else {
                                # ChaÃ®ne
                                $paramCode += "$key = '$value'; "
                            }
                        }
                        $paramCode += "}"
                        
                        $preloadCode += @"
        
        # ParamÃ¨tres utilisÃ©s $count fois
        `$params = $paramCode
        `$cacheKey = "$(($scriptName -replace "\.ps1|\.psm1", ""))_" + ((`$params.Keys | Sort-Object) -join "_") + "_" + ((`$params.Values | ForEach-Object { "`$_" }) -join "_")
        
        Get-PSCacheItem -Cache `$${cacheName}Cache -Key `$cacheKey -GenerateValue {
            Write-Log "GÃ©nÃ©ration des donnÃ©es pour `$cacheKey..." -Level "INFO"
            # Appeler la fonction principale du script avec les paramÃ¨tres
            # Note: Ceci est une approximation, le script rÃ©el peut nÃ©cessiter des ajustements
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
        Write-Log "Script non trouvÃ©: `$scriptPath" -Level "WARNING"
    }
}
catch {
    Write-Log "Erreur lors du prÃ©chargement des donnÃ©es pour $scriptName: `$_" -Level "ERROR"
}

"@
        }
    }
    
    # Ajouter le code pour les sÃ©quences prÃ©dictives
    if ($Config.PredictiveSequences.Count -gt 0) {
        $preloadCode += @"
# Configurer les sÃ©quences prÃ©dictives
Write-Log "Configuration des sÃ©quences prÃ©dictives..." -Level "INFO"

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

# Enregistrer les sÃ©quences prÃ©dictives pour utilisation future
`$predictiveSequencesPath = Join-Path -Path `$PSScriptRoot -ChildPath "predictive_sequences.xml"
`$predictiveSequences | Export-Clixml -Path `$predictiveSequencesPath -Force

Write-Log "SÃ©quences prÃ©dictives configurÃ©es et enregistrÃ©es." -Level "SUCCESS"
"@
    }
    
    $preloadCode += @"

Write-Log "PrÃ©chargement du cache terminÃ©." -Level "SUCCESS"
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
    
    Write-Log "Configuration de cache sauvegardÃ©e: $ConfigPath" -Level "SUCCESS"
    
    # GÃ©nÃ©rer le code de prÃ©chargement du cache
    $preloadCode = Generate-CachePreloadCode -Config $Config
    $preloadPath = Join-Path -Path $PSScriptRoot -ChildPath "Preload-Cache.ps1"
    
    $preloadCode | Out-File -FilePath $preloadPath -Encoding utf8 -Force
    
    Write-Log "Script de prÃ©chargement du cache gÃ©nÃ©rÃ©: $preloadPath" -Level "SUCCESS"
    
    # Rechercher les scripts qui utilisent PSCacheManager
    $cacheScripts = Get-ChildItem -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -Filter "*.ps1" -Recurse |
        Where-Object { (Get-Content -Path $_.FullName -Raw) -match "PSCacheManager|New-PSCache|Get-PSCacheItem" }
    
    Write-Log "Nombre de scripts utilisant le cache trouvÃ©s: $($cacheScripts.Count)" -Level "INFO"
    
    if ($Apply) {
        foreach ($script in $cacheScripts) {
            $scriptPath = $script.FullName
            $scriptName = $script.Name
            
            # VÃ©rifier si le script a une configuration spÃ©cifique
            if ($Config.ScriptSpecificSettings.ContainsKey($scriptPath)) {
                Write-Log "Application de la configuration Ã : $scriptName" -Level "INFO"
                
                $content = Get-Content -Path $scriptPath -Raw
                $settings = $Config.ScriptSpecificSettings[$scriptPath]
                
                # Rechercher les appels Ã  New-PSCache
                if ($content -match "New-PSCache\s+(?:-Name\s+)?[\"']([^\"']+)[\"'](?:\s+-DefaultTTLSeconds\s+)?(\d+)?(?:\s+-EvictionPolicy\s+)?[\"']?(\w+)?[\"']?(?:\s+-ExtendTtlOnAccess:)?(\`$\w+|true|false)?") {
                    $currentName = $matches[1]
                    $currentTTL = $matches[2]
                    $currentPolicy = $matches[3]
                    $currentExtendTtl = $matches[4]
                    
                    # Remplacer les paramÃ¨tres par ceux de la configuration
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
                    
                    # Sauvegarder le script modifiÃ©
                    Set-Content -Path $scriptPath -Value $newContent -Force
                    
                    Write-Log "Configuration appliquÃ©e Ã : $scriptName" -Level "SUCCESS"
                }
                else {
                    Write-Log "Aucun appel Ã  New-PSCache trouvÃ© dans: $scriptName" -Level "WARNING"
                }
            }
        }
        
        # CrÃ©er une tÃ¢che planifiÃ©e pour exÃ©cuter le script de prÃ©chargement
        $taskName = "PreloadCacheTask"
        $taskPath = "\EMAIL_SENDER_1\"
        $taskCommand = "powershell.exe"
        $taskArgs = "-ExecutionPolicy Bypass -File `"$preloadPath`""
        
        Write-Log "CrÃ©ation d'une tÃ¢che planifiÃ©e pour le prÃ©chargement du cache..." -Level "INFO"
        
        try {
            # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
            $existingTask = Get-ScheduledTask -TaskName $taskName -TaskPath $taskPath -ErrorAction SilentlyContinue
            
            if ($existingTask) {
                # Supprimer la tÃ¢che existante
                Unregister-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Confirm:$false
            }
            
            # CrÃ©er une nouvelle tÃ¢che
            $action = New-ScheduledTaskAction -Execute $taskCommand -Argument $taskArgs
            $trigger = New-ScheduledTaskTrigger -Daily -At "3:00 AM"
            $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
            
            Register-ScheduledTask -TaskName $taskName -TaskPath $taskPath -Action $action -Trigger $trigger -Settings $settings -Description "PrÃ©chargement du cache pour les scripts frÃ©quemment utilisÃ©s"
            
            Write-Log "TÃ¢che planifiÃ©e crÃ©Ã©e avec succÃ¨s." -Level "SUCCESS"
        }
        catch {
            Write-Log "Erreur lors de la crÃ©ation de la tÃ¢che planifiÃ©e: $_" -Level "ERROR"
        }
    }
    else {
        Write-Log "Mode simulation: la configuration n'a pas Ã©tÃ© appliquÃ©e aux scripts. Utilisez -Apply pour appliquer les modifications." -Level "WARNING"
    }
}

# Point d'entrÃ©e principal
Write-Log "DÃ©marrage de l'optimisation du cache..." -Level "TITLE"

# VÃ©rifier si le fichier de base de donnÃ©es existe
if (-not (Test-Path -Path $DatabasePath)) {
    Write-Log "Le fichier de base de donnÃ©es spÃ©cifiÃ© n'existe pas: $DatabasePath" -Level "ERROR"
    exit 1
}

# Initialiser le moniteur d'utilisation avec la base de donnÃ©es spÃ©cifiÃ©e
Initialize-UsageMonitor -DatabasePath $DatabasePath
Write-Log "Base de donnÃ©es d'utilisation chargÃ©e: $DatabasePath" -Level "INFO"

# RÃ©cupÃ©rer les statistiques d'utilisation
$usageStats = Get-ScriptUsageStatistics
Write-Log "Statistiques d'utilisation rÃ©cupÃ©rÃ©es" -Level "INFO"

# Analyser les patterns d'utilisation du cache
$cachePatterns = Analyze-CacheUsagePatterns -UsageStats $usageStats
Write-Log "Patterns d'utilisation du cache analysÃ©s: $($cachePatterns.Count) scripts avec patterns" -Level "INFO"

# Analyser les sÃ©quences d'exÃ©cution
$executionSequences = Analyze-ExecutionSequences -UsageStats $usageStats
Write-Log "SÃ©quences d'exÃ©cution analysÃ©es: $($executionSequences.Count) sÃ©quences frÃ©quentes" -Level "INFO"

# GÃ©nÃ©rer la configuration de cache
$cacheConfig = Generate-CacheConfig -CachePatterns $cachePatterns -ExecutionSequences $executionSequences
Write-Log "Configuration de cache gÃ©nÃ©rÃ©e" -Level "INFO"

# Appliquer la configuration
Apply-CacheConfig -Config $cacheConfig -ConfigPath $ConfigPath -Apply:$Apply

Write-Log "Optimisation du cache terminÃ©e." -Level "TITLE"

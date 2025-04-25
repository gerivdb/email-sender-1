#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion robuste des compteurs de performance avec gestion d'erreurs avancée.
.DESCRIPTION
    Ce module fournit des fonctions pour obtenir des compteurs de performance de manière fiable,
    avec gestion d'erreurs intégrée, mécanismes alternatifs et valeurs par défaut intelligentes.
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-15
#>

# Variables globales pour le cache des valeurs
$script:CounterCache = @{}
$script:LastUpdateTime = @{}
$script:DefaultValues = @{}
$script:FailureCount = @{}
$script:MaxCacheAge = New-TimeSpan -Minutes 5
$script:MaxRetryCount = 3
$script:RetryDelay = New-TimeSpan -Seconds 2

<#
.SYNOPSIS
    Obtient les valeurs des compteurs de performance de manière fiable.
.DESCRIPTION
    Cette fonction est un wrapper autour de Get-Counter qui ajoute une gestion d'erreurs robuste,
    des mécanismes de retry, et des valeurs par défaut intelligentes en cas d'échec.
.PARAMETER CounterPath
    Chemin du compteur de performance à obtenir.
.PARAMETER SampleInterval
    Intervalle entre les échantillons en secondes.
.PARAMETER MaxSamples
    Nombre maximum d'échantillons à collecter.
.PARAMETER UseCache
    Indique si le cache doit être utilisé pour les valeurs récentes.
.PARAMETER CacheMaxAge
    Âge maximum des valeurs en cache en minutes.
.PARAMETER DefaultValue
    Valeur par défaut à utiliser en cas d'échec.
.PARAMETER UseAlternativeMethods
    Indique si des méthodes alternatives doivent être utilisées en cas d'échec de Get-Counter.
.PARAMETER RetryCount
    Nombre de tentatives en cas d'échec.
.PARAMETER RetryDelaySeconds
    Délai entre les tentatives en secondes.
.EXAMPLE
    Get-SafeCounter -CounterPath "\Processor(_Total)\% Processor Time"
.EXAMPLE
    Get-SafeCounter -CounterPath "\Memory\Available MBytes" -UseCache -DefaultValue 1024
#>
function Get-SafeCounter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$CounterPath,

        [Parameter(Mandatory = $false)]
        [int]$SampleInterval = 1,

        [Parameter(Mandatory = $false)]
        [int]$MaxSamples = 1,

        [Parameter(Mandatory = $false)]
        [switch]$UseCache,

        [Parameter(Mandatory = $false)]
        [int]$CacheMaxAge = 5,

        [Parameter(Mandatory = $false)]
        [double]$DefaultValue = 0,

        [Parameter(Mandatory = $false)]
        [switch]$UseAlternativeMethods,

        [Parameter(Mandatory = $false)]
        [int]$RetryCount = 3,

        [Parameter(Mandatory = $false)]
        [int]$RetryDelaySeconds = 2
    )

    # Mettre à jour les variables globales si nécessaire
    if ($CacheMaxAge -ne 5) {
        $script:MaxCacheAge = New-TimeSpan -Minutes $CacheMaxAge
    }

    if ($RetryCount -ne 3) {
        $script:MaxRetryCount = $RetryCount
    }

    if ($RetryDelaySeconds -ne 2) {
        $script:RetryDelay = New-TimeSpan -Seconds $RetryDelaySeconds
    }

    # Initialiser les résultats
    $results = @{}

    foreach ($counter in $CounterPath) {
        # Vérifier si la valeur est dans le cache et si elle est encore valide
        if ($UseCache -and $script:CounterCache.ContainsKey($counter)) {
            $lastUpdate = $script:LastUpdateTime[$counter]
            $cacheAge = (Get-Date) - $lastUpdate

            if ($cacheAge -lt $script:MaxCacheAge) {
                Write-Verbose "Utilisation de la valeur en cache pour $counter (âge: $($cacheAge.TotalMinutes) minutes)"
                $results[$counter] = $script:CounterCache[$counter]
                continue
            }
        }

        # Initialiser le compteur d'échecs si nécessaire
        if (-not $script:FailureCount.ContainsKey($counter)) {
            $script:FailureCount[$counter] = 0
        }

        # Essayer d'obtenir le compteur avec Get-Counter
        $counterValue = $null
        $success = $false
        $errorInfo = $null

        for ($retry = 0; $retry -lt $script:MaxRetryCount; $retry++) {
            try {
                Write-Verbose "Tentative d'obtention du compteur $counter (essai $($retry + 1)/$script:MaxRetryCount)"

                # Utiliser Get-Counter pour obtenir la valeur
                $counterResult = Get-Counter -Counter $counter -SampleInterval $SampleInterval -MaxSamples $MaxSamples -ErrorAction Stop

                # Extraire la valeur du compteur et la convertir en double
                $counterValue = [double]$counterResult.CounterSamples[0].CookedValue

                # Mettre à jour le cache
                $script:CounterCache[$counter] = $counterValue
                $script:LastUpdateTime[$counter] = Get-Date

                # Réinitialiser le compteur d'échecs
                $script:FailureCount[$counter] = 0

                $success = $true
                break
            } catch {
                $errorInfo = $_
                Write-Verbose "Échec de l'obtention du compteur $counter : $($_.Exception.Message)"

                # Incrémenter le compteur d'échecs
                $script:FailureCount[$counter]++

                # Attendre avant de réessayer
                if ($retry -lt $script:MaxRetryCount - 1) {
                    Start-Sleep -Seconds $script:RetryDelay.TotalSeconds
                }
            }
        }

        # Si Get-Counter a échoué et que les méthodes alternatives sont activées, essayer les méthodes alternatives
        if (-not $success -and $UseAlternativeMethods) {
            try {
                Write-Verbose "Tentative d'utilisation de méthodes alternatives pour $counter"
                $alternativeValue = Get-AlternativeMetric -CounterPath $counter

                if ($null -ne $alternativeValue) {
                    $counterValue = $alternativeValue

                    # Mettre à jour le cache
                    $script:CounterCache[$counter] = $counterValue
                    $script:LastUpdateTime[$counter] = Get-Date

                    $success = $true
                }
            } catch {
                Write-Verbose "Échec des méthodes alternatives pour $counter : $($_.Exception.Message)"
            }
        }

        # Si toutes les méthodes ont échoué, utiliser une valeur par défaut intelligente
        if (-not $success) {
            Write-Warning "Impossible d'obtenir le compteur $counter. Utilisation d'une valeur par défaut."

            # Obtenir une valeur par défaut intelligente
            $defaultValueResult = Get-IntelligentDefaultValue -CounterPath $counter -DefaultValue $DefaultValue
            $counterValue = $defaultValueResult

            # Enregistrer la valeur par défaut pour référence future
            $script:DefaultValues[$counter] = $counterValue
        }

        # Ajouter la valeur aux résultats
        $results[$counter] = $counterValue
    }

    # Retourner les résultats
    if ($CounterPath.Count -eq 1) {
        return $results[$CounterPath[0]]
    } else {
        return $results
    }
}

<#
.SYNOPSIS
    Obtient des métriques système en utilisant des méthodes alternatives à Get-Counter.
.DESCRIPTION
    Cette fonction utilise WMI/CIM ou d'autres méthodes pour obtenir des métriques système
    équivalentes aux compteurs de performance, lorsque Get-Counter échoue.
.PARAMETER CounterPath
    Chemin du compteur de performance pour lequel obtenir une métrique alternative.
.EXAMPLE
    Get-AlternativeMetric -CounterPath "\Processor(_Total)\% Processor Time"
#>
function Get-AlternativeMetric {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CounterPath
    )

    # Extraire les composants du chemin du compteur
    $counterPathParts = $CounterPath -split '\\'
    $category = $counterPathParts[1] -replace '\(.*\)', ''
    $instance = if ($counterPathParts[1] -match '\((.*)\)') { $matches[1] } else { "_Total" }
    $counter = $counterPathParts[2]

    Write-Verbose "Recherche d'une métrique alternative pour Catégorie: $category, Instance: $instance, Compteur: $counter"

    # Utiliser différentes méthodes en fonction de la catégorie et du compteur
    switch ($category) {
        "Processor" {
            switch ($counter) {
                "% Processor Time" {
                    # Utiliser CIM pour obtenir l'utilisation du processeur
                    try {
                        $cpuLoad = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average
                        return $cpuLoad.Average
                    } catch {
                        Write-Verbose "Échec de l'obtention de l'utilisation du processeur via CIM: $($_.Exception.Message)"

                        # Essayer une autre méthode (WMI)
                        try {
                            $cpuLoad = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average
                            return $cpuLoad.Average
                        } catch {
                            Write-Verbose "Échec de l'obtention de l'utilisation du processeur via WMI: $($_.Exception.Message)"
                        }
                    }
                }

                "% Idle Time" {
                    # Calculer le temps d'inactivité à partir du temps d'utilisation
                    try {
                        $cpuLoad = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average
                        return 100 - $cpuLoad.Average
                    } catch {
                        Write-Verbose "Échec du calcul du temps d'inactivité du processeur: $($_.Exception.Message)"
                    }
                }
            }
        }

        "Memory" {
            switch ($counter) {
                "Available MBytes" {
                    # Utiliser CIM pour obtenir la mémoire disponible
                    try {
                        $memory = Get-CimInstance -ClassName Win32_OperatingSystem
                        return [math]::Round($memory.FreePhysicalMemory / 1KB, 0)
                    } catch {
                        Write-Verbose "Échec de l'obtention de la mémoire disponible via CIM: $($_.Exception.Message)"

                        # Essayer une autre méthode (WMI)
                        try {
                            $memory = Get-WmiObject -Class Win32_OperatingSystem
                            return [math]::Round($memory.FreePhysicalMemory / 1KB, 0)
                        } catch {
                            Write-Verbose "Échec de l'obtention de la mémoire disponible via WMI: $($_.Exception.Message)"
                        }
                    }
                }

                "% Committed Bytes In Use" {
                    # Calculer le pourcentage de mémoire utilisée
                    try {
                        $memory = Get-CimInstance -ClassName Win32_OperatingSystem
                        $totalMemory = $memory.TotalVisibleMemorySize
                        $freeMemory = $memory.FreePhysicalMemory
                        $usedMemory = $totalMemory - $freeMemory
                        return [math]::Round(($usedMemory / $totalMemory) * 100, 2)
                    } catch {
                        Write-Verbose "Échec du calcul du pourcentage de mémoire utilisée: $($_.Exception.Message)"
                    }
                }
            }
        }

        "PhysicalDisk" {
            switch ($counter) {
                "% Disk Time" {
                    # Utiliser CIM pour obtenir l'utilisation du disque
                    try {
                        $diskStats = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfDisk_PhysicalDisk | Where-Object { $_.Name -eq $instance -or ($instance -eq "_Total" -and $_.Name -eq "_Total") }
                        return $diskStats.PercentDiskTime
                    } catch {
                        Write-Verbose "Échec de l'obtention de l'utilisation du disque via CIM: $($_.Exception.Message)"
                    }
                }

                "Avg. Disk Queue Length" {
                    # Utiliser CIM pour obtenir la longueur de la file d'attente du disque
                    try {
                        $diskStats = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfDisk_PhysicalDisk | Where-Object { $_.Name -eq $instance -or ($instance -eq "_Total" -and $_.Name -eq "_Total") }
                        return $diskStats.AvgDiskQueueLength
                    } catch {
                        Write-Verbose "Échec de l'obtention de la longueur de la file d'attente du disque via CIM: $($_.Exception.Message)"
                    }
                }
            }
        }

        "Network Interface" {
            switch ($counter) {
                "Bytes Total/sec" {
                    # Utiliser CIM pour obtenir le débit réseau
                    try {
                        $networkStats = Get-CimInstance -ClassName Win32_PerfFormattedData_Tcpip_NetworkInterface | Where-Object { $_.Name -eq $instance -or ($instance -eq "_Total" -and $_.Name -eq "_Total") }
                        return $networkStats.BytesTotalPersec
                    } catch {
                        Write-Verbose "Échec de l'obtention du débit réseau via CIM: $($_.Exception.Message)"
                    }
                }
            }
        }
    }

    # Si aucune méthode alternative n'a fonctionné, retourner null
    Write-Verbose "Aucune méthode alternative disponible pour $CounterPath"
    return $null
}

<#
.SYNOPSIS
    Obtient une valeur par défaut intelligente pour un compteur de performance.
.DESCRIPTION
    Cette fonction calcule une valeur par défaut intelligente pour un compteur de performance
    en se basant sur l'historique des valeurs, des tendances, ou des valeurs typiques.
.PARAMETER CounterPath
    Chemin du compteur de performance pour lequel obtenir une valeur par défaut.
.PARAMETER DefaultValue
    Valeur par défaut à utiliser si aucune valeur intelligente ne peut être calculée.
.EXAMPLE
    Get-IntelligentDefaultValue -CounterPath "\Processor(_Total)\% Processor Time" -DefaultValue 50
#>
function Get-IntelligentDefaultValue {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$CounterPath,

        [Parameter(Mandatory = $false)]
        [double]$DefaultValue = 0
    )

    # Extraire les composants du chemin du compteur
    $counterPathParts = $CounterPath -split '\\'
    $category = $counterPathParts[1] -replace '\(.*\)', ''
    $instance = if ($counterPathParts[1] -match '\((.*)\)') { $matches[1] } else { "_Total" }
    $counter = $counterPathParts[2]

    Write-Verbose "Calcul d'une valeur par défaut intelligente pour Catégorie: $category, Instance: $instance, Compteur: $counter"

    # Vérifier si nous avons des valeurs précédentes dans le cache
    if ($script:CounterCache.ContainsKey($CounterPath)) {
        $cachedValue = $script:CounterCache[$CounterPath]
        $lastUpdateTime = $script:LastUpdateTime[$CounterPath]
        $cacheAge = (Get-Date) - $lastUpdateTime

        # Si le cache n'est pas trop ancien, utiliser la valeur en cache
        if ($cacheAge -lt (New-TimeSpan -Hours 1)) {
            Write-Verbose "Utilisation de la dernière valeur connue pour $CounterPath (âge: $($cacheAge.TotalMinutes) minutes)"
            return $cachedValue
        }
    }

    # Utiliser des valeurs typiques en fonction de la catégorie et du compteur
    switch ($category) {
        "Processor" {
            switch ($counter) {
                "% Processor Time" { return [double]42 } # Valeur typique pour l'utilisation du processeur
                "% Idle Time" { return 70 } # Valeur typique pour le temps d'inactivité du processeur
                default { return 0 }
            }
        }

        "Memory" {
            switch ($counter) {
                "Available MBytes" {
                    # Estimer la mémoire disponible en fonction de la mémoire totale
                    try {
                        $memory = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
                        $totalMemory = $memory.TotalVisibleMemorySize / 1KB
                        return [math]::Round($totalMemory * 0.3, 0) # Estimer 30% de mémoire disponible
                    } catch {
                        return 1024 # Valeur par défaut de 1 Go
                    }
                }
                "% Committed Bytes In Use" { return 70 } # Valeur typique pour le pourcentage de mémoire utilisée
                default { return 0 }
            }
        }

        "PhysicalDisk" {
            switch ($counter) {
                "% Disk Time" { return 15 } # Valeur typique pour l'utilisation du disque
                "Avg. Disk Queue Length" { return 0.5 } # Valeur typique pour la longueur de la file d'attente du disque
                default { return 0 }
            }
        }

        "Network Interface" {
            switch ($counter) {
                "Bytes Total/sec" { return 1000 } # Valeur typique pour le débit réseau (1 Ko/s)
                default { return 0 }
            }
        }

        default {
            # Si aucune valeur typique n'est disponible, utiliser la valeur par défaut fournie
            return $DefaultValue
        }
    }
}

<#
.SYNOPSIS
    Efface le cache des compteurs de performance.
.DESCRIPTION
    Cette fonction efface le cache des compteurs de performance, forçant ainsi
    la récupération de nouvelles valeurs lors des prochains appels à Get-SafeCounter.
.PARAMETER CounterPath
    Chemin du compteur de performance à effacer du cache. Si non spécifié, tout le cache est effacé.
.EXAMPLE
    Clear-CounterCache
.EXAMPLE
    Clear-CounterCache -CounterPath "\Processor(_Total)\% Processor Time"
#>
function Clear-CounterCache {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$CounterPath
    )

    if ($CounterPath) {
        # Effacer un compteur spécifique du cache
        if ($script:CounterCache.ContainsKey($CounterPath)) {
            $script:CounterCache.Remove($CounterPath)
            $script:LastUpdateTime.Remove($CounterPath)
            $script:FailureCount.Remove($CounterPath)
            Write-Verbose "Cache effacé pour $CounterPath"
        } else {
            Write-Verbose "Aucune entrée de cache trouvée pour $CounterPath"
        }
    } else {
        # Effacer tout le cache
        $script:CounterCache.Clear()
        $script:LastUpdateTime.Clear()
        $script:FailureCount.Clear()
        Write-Verbose "Cache entièrement effacé"
    }
}

<#
.SYNOPSIS
    Obtient des statistiques sur les compteurs de performance.
.DESCRIPTION
    Cette fonction retourne des statistiques sur les compteurs de performance,
    comme le nombre de succès, d'échecs, et l'âge des valeurs en cache.
.PARAMETER CounterPath
    Chemin du compteur de performance pour lequel obtenir des statistiques.
    Si non spécifié, des statistiques pour tous les compteurs sont retournées.
.EXAMPLE
    Get-CounterStatistics
.EXAMPLE
    Get-CounterStatistics -CounterPath "\Processor(_Total)\% Processor Time"
#>
function Get-CounterStatistics {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$CounterPath
    )

    $statistics = @{}

    if ($CounterPath) {
        # Obtenir des statistiques pour un compteur spécifique
        if ($script:CounterCache.ContainsKey($CounterPath)) {
            $lastUpdateTime = $script:LastUpdateTime[$CounterPath]
            $cacheAge = (Get-Date) - $lastUpdateTime
            $failureCount = if ($script:FailureCount.ContainsKey($CounterPath)) { $script:FailureCount[$CounterPath] } else { 0 }

            $statistics[$CounterPath] = [PSCustomObject]@{
                CounterPath     = $CounterPath
                CachedValue     = $script:CounterCache[$CounterPath]
                LastUpdateTime  = $lastUpdateTime
                CacheAge        = $cacheAge
                CacheAgeMinutes = [math]::Round($cacheAge.TotalMinutes, 2)
                FailureCount    = $failureCount
                DefaultValue    = if ($script:DefaultValues.ContainsKey($CounterPath)) { $script:DefaultValues[$CounterPath] } else { $null }
            }
        } else {
            Write-Verbose "Aucune statistique disponible pour $CounterPath"
        }
    } else {
        # Obtenir des statistiques pour tous les compteurs
        foreach ($counter in $script:CounterCache.Keys) {
            $lastUpdateTime = $script:LastUpdateTime[$counter]
            $cacheAge = (Get-Date) - $lastUpdateTime
            $failureCount = if ($script:FailureCount.ContainsKey($counter)) { $script:FailureCount[$counter] } else { 0 }

            $statistics[$counter] = [PSCustomObject]@{
                CounterPath     = $counter
                CachedValue     = $script:CounterCache[$counter]
                LastUpdateTime  = $lastUpdateTime
                CacheAge        = $cacheAge
                CacheAgeMinutes = [math]::Round($cacheAge.TotalMinutes, 2)
                FailureCount    = $failureCount
                DefaultValue    = if ($script:DefaultValues.ContainsKey($counter)) { $script:DefaultValues[$counter] } else { $null }
            }
        }
    }

    return $statistics
}

# Exporter les fonctions du module
Export-ModuleMember -Function Get-SafeCounter, Get-AlternativeMetric, Get-IntelligentDefaultValue, Clear-CounterCache, Get-CounterStatistics

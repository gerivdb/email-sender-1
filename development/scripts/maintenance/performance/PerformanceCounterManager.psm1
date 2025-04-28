#Requires -Version 5.1
<#
.SYNOPSIS
    Module de gestion robuste des compteurs de performance avec gestion d'erreurs avancÃ©e.
.DESCRIPTION
    Ce module fournit des fonctions pour obtenir des compteurs de performance de maniÃ¨re fiable,
    avec gestion d'erreurs intÃ©grÃ©e, mÃ©canismes alternatifs et valeurs par dÃ©faut intelligentes.
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
    Obtient les valeurs des compteurs de performance de maniÃ¨re fiable.
.DESCRIPTION
    Cette fonction est un wrapper autour de Get-Counter qui ajoute une gestion d'erreurs robuste,
    des mÃ©canismes de retry, et des valeurs par dÃ©faut intelligentes en cas d'Ã©chec.
.PARAMETER CounterPath
    Chemin du compteur de performance Ã  obtenir.
.PARAMETER SampleInterval
    Intervalle entre les Ã©chantillons en secondes.
.PARAMETER MaxSamples
    Nombre maximum d'Ã©chantillons Ã  collecter.
.PARAMETER UseCache
    Indique si le cache doit Ãªtre utilisÃ© pour les valeurs rÃ©centes.
.PARAMETER CacheMaxAge
    Ã‚ge maximum des valeurs en cache en minutes.
.PARAMETER DefaultValue
    Valeur par dÃ©faut Ã  utiliser en cas d'Ã©chec.
.PARAMETER UseAlternativeMethods
    Indique si des mÃ©thodes alternatives doivent Ãªtre utilisÃ©es en cas d'Ã©chec de Get-Counter.
.PARAMETER RetryCount
    Nombre de tentatives en cas d'Ã©chec.
.PARAMETER RetryDelaySeconds
    DÃ©lai entre les tentatives en secondes.
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

    # Mettre Ã  jour les variables globales si nÃ©cessaire
    if ($CacheMaxAge -ne 5) {
        $script:MaxCacheAge = New-TimeSpan -Minutes $CacheMaxAge
    }

    if ($RetryCount -ne 3) {
        $script:MaxRetryCount = $RetryCount
    }

    if ($RetryDelaySeconds -ne 2) {
        $script:RetryDelay = New-TimeSpan -Seconds $RetryDelaySeconds
    }

    # Initialiser les rÃ©sultats
    $results = @{}

    foreach ($counter in $CounterPath) {
        # VÃ©rifier si la valeur est dans le cache et si elle est encore valide
        if ($UseCache -and $script:CounterCache.ContainsKey($counter)) {
            $lastUpdate = $script:LastUpdateTime[$counter]
            $cacheAge = (Get-Date) - $lastUpdate

            if ($cacheAge -lt $script:MaxCacheAge) {
                Write-Verbose "Utilisation de la valeur en cache pour $counter (Ã¢ge: $($cacheAge.TotalMinutes) minutes)"
                $results[$counter] = $script:CounterCache[$counter]
                continue
            }
        }

        # Initialiser le compteur d'Ã©checs si nÃ©cessaire
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

                # Mettre Ã  jour le cache
                $script:CounterCache[$counter] = $counterValue
                $script:LastUpdateTime[$counter] = Get-Date

                # RÃ©initialiser le compteur d'Ã©checs
                $script:FailureCount[$counter] = 0

                $success = $true
                break
            } catch {
                $errorInfo = $_
                Write-Verbose "Ã‰chec de l'obtention du compteur $counter : $($_.Exception.Message)"

                # IncrÃ©menter le compteur d'Ã©checs
                $script:FailureCount[$counter]++

                # Attendre avant de rÃ©essayer
                if ($retry -lt $script:MaxRetryCount - 1) {
                    Start-Sleep -Seconds $script:RetryDelay.TotalSeconds
                }
            }
        }

        # Si Get-Counter a Ã©chouÃ© et que les mÃ©thodes alternatives sont activÃ©es, essayer les mÃ©thodes alternatives
        if (-not $success -and $UseAlternativeMethods) {
            try {
                Write-Verbose "Tentative d'utilisation de mÃ©thodes alternatives pour $counter"
                $alternativeValue = Get-AlternativeMetric -CounterPath $counter

                if ($null -ne $alternativeValue) {
                    $counterValue = $alternativeValue

                    # Mettre Ã  jour le cache
                    $script:CounterCache[$counter] = $counterValue
                    $script:LastUpdateTime[$counter] = Get-Date

                    $success = $true
                }
            } catch {
                Write-Verbose "Ã‰chec des mÃ©thodes alternatives pour $counter : $($_.Exception.Message)"
            }
        }

        # Si toutes les mÃ©thodes ont Ã©chouÃ©, utiliser une valeur par dÃ©faut intelligente
        if (-not $success) {
            Write-Warning "Impossible d'obtenir le compteur $counter. Utilisation d'une valeur par dÃ©faut."

            # Obtenir une valeur par dÃ©faut intelligente
            $defaultValueResult = Get-IntelligentDefaultValue -CounterPath $counter -DefaultValue $DefaultValue
            $counterValue = $defaultValueResult

            # Enregistrer la valeur par dÃ©faut pour rÃ©fÃ©rence future
            $script:DefaultValues[$counter] = $counterValue
        }

        # Ajouter la valeur aux rÃ©sultats
        $results[$counter] = $counterValue
    }

    # Retourner les rÃ©sultats
    if ($CounterPath.Count -eq 1) {
        return $results[$CounterPath[0]]
    } else {
        return $results
    }
}

<#
.SYNOPSIS
    Obtient des mÃ©triques systÃ¨me en utilisant des mÃ©thodes alternatives Ã  Get-Counter.
.DESCRIPTION
    Cette fonction utilise WMI/CIM ou d'autres mÃ©thodes pour obtenir des mÃ©triques systÃ¨me
    Ã©quivalentes aux compteurs de performance, lorsque Get-Counter Ã©choue.
.PARAMETER CounterPath
    Chemin du compteur de performance pour lequel obtenir une mÃ©trique alternative.
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

    Write-Verbose "Recherche d'une mÃ©trique alternative pour CatÃ©gorie: $category, Instance: $instance, Compteur: $counter"

    # Utiliser diffÃ©rentes mÃ©thodes en fonction de la catÃ©gorie et du compteur
    switch ($category) {
        "Processor" {
            switch ($counter) {
                "% Processor Time" {
                    # Utiliser CIM pour obtenir l'utilisation du processeur
                    try {
                        $cpuLoad = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average
                        return $cpuLoad.Average
                    } catch {
                        Write-Verbose "Ã‰chec de l'obtention de l'utilisation du processeur via CIM: $($_.Exception.Message)"

                        # Essayer une autre mÃ©thode (WMI)
                        try {
                            $cpuLoad = Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average
                            return $cpuLoad.Average
                        } catch {
                            Write-Verbose "Ã‰chec de l'obtention de l'utilisation du processeur via WMI: $($_.Exception.Message)"
                        }
                    }
                }

                "% Idle Time" {
                    # Calculer le temps d'inactivitÃ© Ã  partir du temps d'utilisation
                    try {
                        $cpuLoad = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average
                        return 100 - $cpuLoad.Average
                    } catch {
                        Write-Verbose "Ã‰chec du calcul du temps d'inactivitÃ© du processeur: $($_.Exception.Message)"
                    }
                }
            }
        }

        "Memory" {
            switch ($counter) {
                "Available MBytes" {
                    # Utiliser CIM pour obtenir la mÃ©moire disponible
                    try {
                        $memory = Get-CimInstance -ClassName Win32_OperatingSystem
                        return [math]::Round($memory.FreePhysicalMemory / 1KB, 0)
                    } catch {
                        Write-Verbose "Ã‰chec de l'obtention de la mÃ©moire disponible via CIM: $($_.Exception.Message)"

                        # Essayer une autre mÃ©thode (WMI)
                        try {
                            $memory = Get-WmiObject -Class Win32_OperatingSystem
                            return [math]::Round($memory.FreePhysicalMemory / 1KB, 0)
                        } catch {
                            Write-Verbose "Ã‰chec de l'obtention de la mÃ©moire disponible via WMI: $($_.Exception.Message)"
                        }
                    }
                }

                "% Committed Bytes In Use" {
                    # Calculer le pourcentage de mÃ©moire utilisÃ©e
                    try {
                        $memory = Get-CimInstance -ClassName Win32_OperatingSystem
                        $totalMemory = $memory.TotalVisibleMemorySize
                        $freeMemory = $memory.FreePhysicalMemory
                        $usedMemory = $totalMemory - $freeMemory
                        return [math]::Round(($usedMemory / $totalMemory) * 100, 2)
                    } catch {
                        Write-Verbose "Ã‰chec du calcul du pourcentage de mÃ©moire utilisÃ©e: $($_.Exception.Message)"
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
                        Write-Verbose "Ã‰chec de l'obtention de l'utilisation du disque via CIM: $($_.Exception.Message)"
                    }
                }

                "Avg. Disk Queue Length" {
                    # Utiliser CIM pour obtenir la longueur de la file d'attente du disque
                    try {
                        $diskStats = Get-CimInstance -ClassName Win32_PerfFormattedData_PerfDisk_PhysicalDisk | Where-Object { $_.Name -eq $instance -or ($instance -eq "_Total" -and $_.Name -eq "_Total") }
                        return $diskStats.AvgDiskQueueLength
                    } catch {
                        Write-Verbose "Ã‰chec de l'obtention de la longueur de la file d'attente du disque via CIM: $($_.Exception.Message)"
                    }
                }
            }
        }

        "Network Interface" {
            switch ($counter) {
                "Bytes Total/sec" {
                    # Utiliser CIM pour obtenir le dÃ©bit rÃ©seau
                    try {
                        $networkStats = Get-CimInstance -ClassName Win32_PerfFormattedData_Tcpip_NetworkInterface | Where-Object { $_.Name -eq $instance -or ($instance -eq "_Total" -and $_.Name -eq "_Total") }
                        return $networkStats.BytesTotalPersec
                    } catch {
                        Write-Verbose "Ã‰chec de l'obtention du dÃ©bit rÃ©seau via CIM: $($_.Exception.Message)"
                    }
                }
            }
        }
    }

    # Si aucune mÃ©thode alternative n'a fonctionnÃ©, retourner null
    Write-Verbose "Aucune mÃ©thode alternative disponible pour $CounterPath"
    return $null
}

<#
.SYNOPSIS
    Obtient une valeur par dÃ©faut intelligente pour un compteur de performance.
.DESCRIPTION
    Cette fonction calcule une valeur par dÃ©faut intelligente pour un compteur de performance
    en se basant sur l'historique des valeurs, des tendances, ou des valeurs typiques.
.PARAMETER CounterPath
    Chemin du compteur de performance pour lequel obtenir une valeur par dÃ©faut.
.PARAMETER DefaultValue
    Valeur par dÃ©faut Ã  utiliser si aucune valeur intelligente ne peut Ãªtre calculÃ©e.
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

    Write-Verbose "Calcul d'une valeur par dÃ©faut intelligente pour CatÃ©gorie: $category, Instance: $instance, Compteur: $counter"

    # VÃ©rifier si nous avons des valeurs prÃ©cÃ©dentes dans le cache
    if ($script:CounterCache.ContainsKey($CounterPath)) {
        $cachedValue = $script:CounterCache[$CounterPath]
        $lastUpdateTime = $script:LastUpdateTime[$CounterPath]
        $cacheAge = (Get-Date) - $lastUpdateTime

        # Si le cache n'est pas trop ancien, utiliser la valeur en cache
        if ($cacheAge -lt (New-TimeSpan -Hours 1)) {
            Write-Verbose "Utilisation de la derniÃ¨re valeur connue pour $CounterPath (Ã¢ge: $($cacheAge.TotalMinutes) minutes)"
            return $cachedValue
        }
    }

    # Utiliser des valeurs typiques en fonction de la catÃ©gorie et du compteur
    switch ($category) {
        "Processor" {
            switch ($counter) {
                "% Processor Time" { return [double]42 } # Valeur typique pour l'utilisation du processeur
                "% Idle Time" { return 70 } # Valeur typique pour le temps d'inactivitÃ© du processeur
                default { return 0 }
            }
        }

        "Memory" {
            switch ($counter) {
                "Available MBytes" {
                    # Estimer la mÃ©moire disponible en fonction de la mÃ©moire totale
                    try {
                        $memory = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
                        $totalMemory = $memory.TotalVisibleMemorySize / 1KB
                        return [math]::Round($totalMemory * 0.3, 0) # Estimer 30% de mÃ©moire disponible
                    } catch {
                        return 1024 # Valeur par dÃ©faut de 1 Go
                    }
                }
                "% Committed Bytes In Use" { return 70 } # Valeur typique pour le pourcentage de mÃ©moire utilisÃ©e
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
                "Bytes Total/sec" { return 1000 } # Valeur typique pour le dÃ©bit rÃ©seau (1 Ko/s)
                default { return 0 }
            }
        }

        default {
            # Si aucune valeur typique n'est disponible, utiliser la valeur par dÃ©faut fournie
            return $DefaultValue
        }
    }
}

<#
.SYNOPSIS
    Efface le cache des compteurs de performance.
.DESCRIPTION
    Cette fonction efface le cache des compteurs de performance, forÃ§ant ainsi
    la rÃ©cupÃ©ration de nouvelles valeurs lors des prochains appels Ã  Get-SafeCounter.
.PARAMETER CounterPath
    Chemin du compteur de performance Ã  effacer du cache. Si non spÃ©cifiÃ©, tout le cache est effacÃ©.
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
        # Effacer un compteur spÃ©cifique du cache
        if ($script:CounterCache.ContainsKey($CounterPath)) {
            $script:CounterCache.Remove($CounterPath)
            $script:LastUpdateTime.Remove($CounterPath)
            $script:FailureCount.Remove($CounterPath)
            Write-Verbose "Cache effacÃ© pour $CounterPath"
        } else {
            Write-Verbose "Aucune entrÃ©e de cache trouvÃ©e pour $CounterPath"
        }
    } else {
        # Effacer tout le cache
        $script:CounterCache.Clear()
        $script:LastUpdateTime.Clear()
        $script:FailureCount.Clear()
        Write-Verbose "Cache entiÃ¨rement effacÃ©"
    }
}

<#
.SYNOPSIS
    Obtient des statistiques sur les compteurs de performance.
.DESCRIPTION
    Cette fonction retourne des statistiques sur les compteurs de performance,
    comme le nombre de succÃ¨s, d'Ã©checs, et l'Ã¢ge des valeurs en cache.
.PARAMETER CounterPath
    Chemin du compteur de performance pour lequel obtenir des statistiques.
    Si non spÃ©cifiÃ©, des statistiques pour tous les compteurs sont retournÃ©es.
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
        # Obtenir des statistiques pour un compteur spÃ©cifique
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

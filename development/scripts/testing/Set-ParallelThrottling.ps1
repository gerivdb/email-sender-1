#Requires -Version 5.1
<#
.SYNOPSIS
    Configure la limitation dynamique pour l'analyse parallÃ¨le.

.DESCRIPTION
    Ce script configure la limitation dynamique pour l'analyse parallÃ¨le
    des pull requests, en ajustant automatiquement le nombre de threads
    en fonction de la charge du systÃ¨me.

.PARAMETER ConfigPath
    Le chemin du fichier de configuration.
    Par dÃ©faut: "config\parallel_throttling.json"

.PARAMETER MaxThreads
    Le nombre maximum de threads Ã  utiliser.
    Par dÃ©faut: nombre de processeurs logiques

.PARAMETER MinThreads
    Le nombre minimum de threads Ã  utiliser.
    Par dÃ©faut: 1

.PARAMETER CPUThreshold
    Le seuil d'utilisation du CPU (en pourcentage) Ã  partir duquel rÃ©duire le nombre de threads.
    Par dÃ©faut: 80

.PARAMETER MemoryThreshold
    Le seuil d'utilisation de la mÃ©moire (en pourcentage) Ã  partir duquel rÃ©duire le nombre de threads.
    Par dÃ©faut: 80

.PARAMETER AdjustmentInterval
    L'intervalle (en secondes) entre les ajustements du nombre de threads.
    Par dÃ©faut: 5

.PARAMETER EnableDynamicThrottling
    Indique s'il faut activer la limitation dynamique.
    Par dÃ©faut: $true

.EXAMPLE
    .\Set-ParallelThrottling.ps1
    Configure la limitation dynamique avec les paramÃ¨tres par dÃ©faut.

.EXAMPLE
    .\Set-ParallelThrottling.ps1 -MaxThreads 16 -CPUThreshold 70 -MemoryThreshold 75
    Configure la limitation dynamique avec des paramÃ¨tres personnalisÃ©s.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$ConfigPath = "config\parallel_throttling.json",

    [Parameter()]
    [int]$MaxThreads = 0,

    [Parameter()]
    [int]$MinThreads = 1,

    [Parameter()]
    [int]$CPUThreshold = 80,

    [Parameter()]
    [int]$MemoryThreshold = 80,

    [Parameter()]
    [int]$AdjustmentInterval = 5,

    [Parameter()]
    [bool]$EnableDynamicThrottling = $true
)

# Fonction pour obtenir l'utilisation actuelle du CPU
function Get-CPUUsage {
    try {
        $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time' -ErrorAction SilentlyContinue
        if ($null -eq $cpuCounter) {
            return 0
        }
        
        return [Math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2)
    } catch {
        Write-Warning "Erreur lors de la rÃ©cupÃ©ration de l'utilisation du CPU: $_"
        return 0
    }
}

# Fonction pour obtenir l'utilisation actuelle de la mÃ©moire
function Get-MemoryUsage {
    try {
        $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($null -eq $osInfo) {
            return 0
        }
        
        $totalMemory = $osInfo.TotalVisibleMemorySize
        $freeMemory = $osInfo.FreePhysicalMemory
        $usedMemory = $totalMemory - $freeMemory
        $memoryUsage = ($usedMemory / $totalMemory) * 100
        
        return [Math]::Round($memoryUsage, 2)
    } catch {
        Write-Warning "Erreur lors de la rÃ©cupÃ©ration de l'utilisation de la mÃ©moire: $_"
        return 0
    }
}

# Fonction pour calculer le nombre optimal de threads
function Get-OptimalThreadCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$Max,
        
        [Parameter(Mandatory = $true)]
        [int]$Min,
        
        [Parameter(Mandatory = $true)]
        [double]$CPUUsage,
        
        [Parameter(Mandatory = $true)]
        [double]$MemoryUsage,
        
        [Parameter(Mandatory = $true)]
        [int]$CPULimit,
        
        [Parameter(Mandatory = $true)]
        [int]$MemoryLimit
    )

    try {
        # Calculer le facteur d'ajustement en fonction de l'utilisation du CPU
        $cpuFactor = if ($CPUUsage -ge $CPULimit) {
            # RÃ©duire le nombre de threads si l'utilisation du CPU est Ã©levÃ©e
            $reduction = ($CPUUsage - $CPULimit) / 20 # 5% de rÃ©duction pour chaque 1% au-dessus du seuil
            $reduction = [Math]::Min($reduction, 0.5) # Limiter la rÃ©duction Ã  50%
            1 - $reduction
        } else {
            # Augmenter le nombre de threads si l'utilisation du CPU est faible
            $increase = ($CPULimit - $CPUUsage) / 40 # 2.5% d'augmentation pour chaque 1% en dessous du seuil
            $increase = [Math]::Min($increase, 0.2) # Limiter l'augmentation Ã  20%
            1 + $increase
        }

        # Calculer le facteur d'ajustement en fonction de l'utilisation de la mÃ©moire
        $memoryFactor = if ($MemoryUsage -ge $MemoryLimit) {
            # RÃ©duire le nombre de threads si l'utilisation de la mÃ©moire est Ã©levÃ©e
            $reduction = ($MemoryUsage - $MemoryLimit) / 20 # 5% de rÃ©duction pour chaque 1% au-dessus du seuil
            $reduction = [Math]::Min($reduction, 0.5) # Limiter la rÃ©duction Ã  50%
            1 - $reduction
        } else {
            # Pas d'augmentation basÃ©e sur la mÃ©moire
            1
        }

        # Utiliser le facteur le plus restrictif
        $factor = [Math]::Min($cpuFactor, $memoryFactor)
        
        # Calculer le nombre optimal de threads
        $optimal = [Math]::Round($Max * $factor)
        
        # Limiter le nombre de threads
        $optimal = [Math]::Max($optimal, $Min)
        $optimal = [Math]::Min($optimal, $Max)
        
        return $optimal
    } catch {
        Write-Warning "Erreur lors du calcul du nombre optimal de threads: $_"
        return $Max
    }
}

# Point d'entrÃ©e principal
try {
    # DÃ©terminer le nombre maximum de threads
    $effectiveMaxThreads = if ($MaxThreads -gt 0) { $MaxThreads } else { [System.Environment]::ProcessorCount }
    
    # CrÃ©er l'objet de configuration
    $config = [PSCustomObject]@{
        MaxThreads = $effectiveMaxThreads
        MinThreads = $MinThreads
        CPUThreshold = $CPUThreshold
        MemoryThreshold = $MemoryThreshold
        AdjustmentInterval = $AdjustmentInterval
        EnableDynamicThrottling = $EnableDynamicThrottling
        LastUpdated = Get-Date
    }

    # CrÃ©er le rÃ©pertoire de configuration s'il n'existe pas
    $configDir = Split-Path -Path $ConfigPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($configDir) -and -not (Test-Path -Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }

    # Enregistrer la configuration
    $config | ConvertTo-Json | Set-Content -Path $ConfigPath -Encoding UTF8

    # Afficher la configuration
    Write-Host "Configuration de la limitation parallÃ¨le:" -ForegroundColor Cyan
    Write-Host "  Nombre maximum de threads: $($config.MaxThreads)" -ForegroundColor White
    Write-Host "  Nombre minimum de threads: $($config.MinThreads)" -ForegroundColor White
    Write-Host "  Seuil d'utilisation du CPU: $($config.CPUThreshold)%" -ForegroundColor White
    Write-Host "  Seuil d'utilisation de la mÃ©moire: $($config.MemoryThreshold)%" -ForegroundColor White
    Write-Host "  Intervalle d'ajustement: $($config.AdjustmentInterval) secondes" -ForegroundColor White
    Write-Host "  Limitation dynamique activÃ©e: $($config.EnableDynamicThrottling)" -ForegroundColor White
    Write-Host "  Configuration enregistrÃ©e: $ConfigPath" -ForegroundColor White

    # Tester la configuration si la limitation dynamique est activÃ©e
    if ($EnableDynamicThrottling) {
        # Obtenir l'utilisation actuelle des ressources
        $cpuUsage = Get-CPUUsage
        $memoryUsage = Get-MemoryUsage
        
        # Calculer le nombre optimal de threads
        $optimalThreads = Get-OptimalThreadCount -Max $effectiveMaxThreads -Min $MinThreads -CPUUsage $cpuUsage -MemoryUsage $memoryUsage -CPULimit $CPUThreshold -MemoryLimit $MemoryThreshold
        
        Write-Host "`nTest de la configuration:" -ForegroundColor Cyan
        Write-Host "  Utilisation actuelle du CPU: $cpuUsage%" -ForegroundColor White
        Write-Host "  Utilisation actuelle de la mÃ©moire: $memoryUsage%" -ForegroundColor White
        Write-Host "  Nombre optimal de threads: $optimalThreads" -ForegroundColor White
    }

    # Retourner la configuration
    return $config
} catch {
    Write-Error "Erreur lors de la configuration de la limitation parallÃ¨le: $_"
    exit 1
}

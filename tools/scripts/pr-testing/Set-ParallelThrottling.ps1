#Requires -Version 5.1
<#
.SYNOPSIS
    Configure la limitation dynamique pour l'analyse parallèle.

.DESCRIPTION
    Ce script configure la limitation dynamique pour l'analyse parallèle
    des pull requests, en ajustant automatiquement le nombre de threads
    en fonction de la charge du système.

.PARAMETER ConfigPath
    Le chemin du fichier de configuration.
    Par défaut: "config\parallel_throttling.json"

.PARAMETER MaxThreads
    Le nombre maximum de threads à utiliser.
    Par défaut: nombre de processeurs logiques

.PARAMETER MinThreads
    Le nombre minimum de threads à utiliser.
    Par défaut: 1

.PARAMETER CPUThreshold
    Le seuil d'utilisation du CPU (en pourcentage) à partir duquel réduire le nombre de threads.
    Par défaut: 80

.PARAMETER MemoryThreshold
    Le seuil d'utilisation de la mémoire (en pourcentage) à partir duquel réduire le nombre de threads.
    Par défaut: 80

.PARAMETER AdjustmentInterval
    L'intervalle (en secondes) entre les ajustements du nombre de threads.
    Par défaut: 5

.PARAMETER EnableDynamicThrottling
    Indique s'il faut activer la limitation dynamique.
    Par défaut: $true

.EXAMPLE
    .\Set-ParallelThrottling.ps1
    Configure la limitation dynamique avec les paramètres par défaut.

.EXAMPLE
    .\Set-ParallelThrottling.ps1 -MaxThreads 16 -CPUThreshold 70 -MemoryThreshold 75
    Configure la limitation dynamique avec des paramètres personnalisés.

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
        Write-Warning "Erreur lors de la récupération de l'utilisation du CPU: $_"
        return 0
    }
}

# Fonction pour obtenir l'utilisation actuelle de la mémoire
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
        Write-Warning "Erreur lors de la récupération de l'utilisation de la mémoire: $_"
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
            # Réduire le nombre de threads si l'utilisation du CPU est élevée
            $reduction = ($CPUUsage - $CPULimit) / 20 # 5% de réduction pour chaque 1% au-dessus du seuil
            $reduction = [Math]::Min($reduction, 0.5) # Limiter la réduction à 50%
            1 - $reduction
        } else {
            # Augmenter le nombre de threads si l'utilisation du CPU est faible
            $increase = ($CPULimit - $CPUUsage) / 40 # 2.5% d'augmentation pour chaque 1% en dessous du seuil
            $increase = [Math]::Min($increase, 0.2) # Limiter l'augmentation à 20%
            1 + $increase
        }

        # Calculer le facteur d'ajustement en fonction de l'utilisation de la mémoire
        $memoryFactor = if ($MemoryUsage -ge $MemoryLimit) {
            # Réduire le nombre de threads si l'utilisation de la mémoire est élevée
            $reduction = ($MemoryUsage - $MemoryLimit) / 20 # 5% de réduction pour chaque 1% au-dessus du seuil
            $reduction = [Math]::Min($reduction, 0.5) # Limiter la réduction à 50%
            1 - $reduction
        } else {
            # Pas d'augmentation basée sur la mémoire
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

# Point d'entrée principal
try {
    # Déterminer le nombre maximum de threads
    $effectiveMaxThreads = if ($MaxThreads -gt 0) { $MaxThreads } else { [System.Environment]::ProcessorCount }
    
    # Créer l'objet de configuration
    $config = [PSCustomObject]@{
        MaxThreads = $effectiveMaxThreads
        MinThreads = $MinThreads
        CPUThreshold = $CPUThreshold
        MemoryThreshold = $MemoryThreshold
        AdjustmentInterval = $AdjustmentInterval
        EnableDynamicThrottling = $EnableDynamicThrottling
        LastUpdated = Get-Date
    }

    # Créer le répertoire de configuration s'il n'existe pas
    $configDir = Split-Path -Path $ConfigPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($configDir) -and -not (Test-Path -Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }

    # Enregistrer la configuration
    $config | ConvertTo-Json | Set-Content -Path $ConfigPath -Encoding UTF8

    # Afficher la configuration
    Write-Host "Configuration de la limitation parallèle:" -ForegroundColor Cyan
    Write-Host "  Nombre maximum de threads: $($config.MaxThreads)" -ForegroundColor White
    Write-Host "  Nombre minimum de threads: $($config.MinThreads)" -ForegroundColor White
    Write-Host "  Seuil d'utilisation du CPU: $($config.CPUThreshold)%" -ForegroundColor White
    Write-Host "  Seuil d'utilisation de la mémoire: $($config.MemoryThreshold)%" -ForegroundColor White
    Write-Host "  Intervalle d'ajustement: $($config.AdjustmentInterval) secondes" -ForegroundColor White
    Write-Host "  Limitation dynamique activée: $($config.EnableDynamicThrottling)" -ForegroundColor White
    Write-Host "  Configuration enregistrée: $ConfigPath" -ForegroundColor White

    # Tester la configuration si la limitation dynamique est activée
    if ($EnableDynamicThrottling) {
        # Obtenir l'utilisation actuelle des ressources
        $cpuUsage = Get-CPUUsage
        $memoryUsage = Get-MemoryUsage
        
        # Calculer le nombre optimal de threads
        $optimalThreads = Get-OptimalThreadCount -Max $effectiveMaxThreads -Min $MinThreads -CPUUsage $cpuUsage -MemoryUsage $memoryUsage -CPULimit $CPUThreshold -MemoryLimit $MemoryThreshold
        
        Write-Host "`nTest de la configuration:" -ForegroundColor Cyan
        Write-Host "  Utilisation actuelle du CPU: $cpuUsage%" -ForegroundColor White
        Write-Host "  Utilisation actuelle de la mémoire: $memoryUsage%" -ForegroundColor White
        Write-Host "  Nombre optimal de threads: $optimalThreads" -ForegroundColor White
    }

    # Retourner la configuration
    return $config
} catch {
    Write-Error "Erreur lors de la configuration de la limitation parallèle: $_"
    exit 1
}

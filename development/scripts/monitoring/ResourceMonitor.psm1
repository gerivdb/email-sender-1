#Requires -Version 5.1
<#
.SYNOPSIS
    Module de surveillance des ressources système en temps réel.
.DESCRIPTION
    Ce module fournit des fonctions pour surveiller l'utilisation du CPU, de la mémoire,
    des opérations I/O et détecter les goulots d'étranglement du système.
.NOTES
    Nom: ResourceMonitor.psm1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-20
#>

# Variables globales du module
$script:MonitoringJobs = @{}
$script:MetricsHistory = @{}
$script:ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "config"
$script:DataPath = Join-Path -Path $PSScriptRoot -ChildPath "data"

# Créer les dossiers nécessaires s'ils n'existent pas
if (-not (Test-Path -Path $script:ConfigPath)) {
    New-Item -Path $script:ConfigPath -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -Path $script:DataPath)) {
    New-Item -Path $script:DataPath -ItemType Directory -Force | Out-Null
}

# Fonction pour obtenir l'utilisation CPU par cœur et globale
function Get-CpuUsage {
    <#
    .SYNOPSIS
        Obtient l'utilisation CPU actuelle par cœur et globale.
    .DESCRIPTION
        Cette fonction récupère l'utilisation CPU actuelle pour chaque cœur logique
        ainsi que l'utilisation globale du système.
    .PARAMETER SampleInterval
        Intervalle en secondes pour calculer l'utilisation CPU. Valeur par défaut: 1 seconde.
    .EXAMPLE
        Get-CpuUsage -SampleInterval 2
    .OUTPUTS
        [PSCustomObject] avec les propriétés TotalUsage et CoreUsage (tableau)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleInterval = 1
    )

    # Obtenir le nombre de cœurs logiques
    $processorCount = [Environment]::ProcessorCount

    # Obtenir l'utilisation CPU initiale
    $initialCpu = Get-Counter '\Processor(*)\% Processor Time' -ErrorAction SilentlyContinue
    
    # Attendre l'intervalle spécifié
    Start-Sleep -Seconds $SampleInterval
    
    # Obtenir l'utilisation CPU finale
    $finalCpu = Get-Counter '\Processor(*)\% Processor Time' -ErrorAction SilentlyContinue
    
    # Vérifier si les mesures ont réussi
    if ($null -eq $initialCpu -or $null -eq $finalCpu) {
        Write-Warning "Impossible d'obtenir les compteurs CPU."
        return $null
    }
    
    # Calculer l'utilisation CPU pour chaque cœur
    $coreUsage = @()
    $totalUsage = 0
    
    for ($i = 0; $i -le $processorCount; $i++) {
        $core = "_Total"
        if ($i -lt $processorCount) {
            $core = "$i"
        }
        
        $initialValue = ($initialCpu.CounterSamples | Where-Object { $_.InstanceName -eq $core }).CookedValue
        $finalValue = ($finalCpu.CounterSamples | Where-Object { $_.InstanceName -eq $core }).CookedValue
        
        if ($core -eq "_Total") {
            $totalUsage = [Math]::Round($finalValue, 2)
        } else {
            $coreUsage += [PSCustomObject]@{
                CoreId = $i
                Usage = [Math]::Round($finalValue, 2)
            }
        }
    }
    
    # Retourner les résultats
    return [PSCustomObject]@{
        TotalUsage = $totalUsage
        CoreUsage = $coreUsage
        Timestamp = Get-Date
        ProcessorCount = $processorCount
    }
}

# Fonction pour obtenir l'utilisation de la mémoire
function Get-MemoryUsage {
    <#
    .SYNOPSIS
        Obtient l'utilisation actuelle de la mémoire physique et virtuelle.
    .DESCRIPTION
        Cette fonction récupère des informations détaillées sur l'utilisation de la mémoire
        physique et virtuelle du système.
    .EXAMPLE
        Get-MemoryUsage
    .OUTPUTS
        [PSCustomObject] avec les propriétés de mémoire physique et virtuelle
    #>
    [CmdletBinding()]
    param ()
    
    # Obtenir les informations sur la mémoire
    $osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
    $computerInfo = Get-CimInstance -ClassName Win32_ComputerSystem
    
    # Calculer l'utilisation de la mémoire physique
    $totalPhysicalMemory = [Math]::Round($computerInfo.TotalPhysicalMemory / 1GB, 2)
    $freePhysicalMemory = [Math]::Round($osInfo.FreePhysicalMemory / 1MB, 2)
    $usedPhysicalMemory = [Math]::Round($totalPhysicalMemory - ($freePhysicalMemory / 1024), 2)
    $physicalMemoryUsagePercent = [Math]::Round(($usedPhysicalMemory / $totalPhysicalMemory) * 100, 2)
    
    # Calculer l'utilisation de la mémoire virtuelle
    $totalVirtualMemory = [Math]::Round(($osInfo.TotalVirtualMemorySize) / 1MB, 2)
    $freeVirtualMemory = [Math]::Round(($osInfo.FreeVirtualMemory) / 1MB, 2)
    $usedVirtualMemory = [Math]::Round($totalVirtualMemory - $freeVirtualMemory, 2)
    $virtualMemoryUsagePercent = [Math]::Round(($usedVirtualMemory / $totalVirtualMemory) * 100, 2)
    
    # Obtenir les informations sur le fichier d'échange
    $pageFileUsage = Get-CimInstance -ClassName Win32_PageFileUsage
    $pageFileTotal = 0
    $pageFileUsed = 0
    
    foreach ($pageFile in $pageFileUsage) {
        $pageFileTotal += $pageFile.AllocatedBaseSize
        $pageFileUsed += $pageFile.CurrentUsage
    }
    
    $pageFileTotal = [Math]::Round($pageFileTotal / 1024, 2)
    $pageFileUsed = [Math]::Round($pageFileUsed / 1024, 2)
    $pageFileUsagePercent = if ($pageFileTotal -gt 0) { [Math]::Round(($pageFileUsed / $pageFileTotal) * 100, 2) } else { 0 }
    
    # Retourner les résultats
    return [PSCustomObject]@{
        PhysicalMemory = [PSCustomObject]@{
            TotalGB = $totalPhysicalMemory
            UsedGB = $usedPhysicalMemory
            FreeGB = [Math]::Round($freePhysicalMemory / 1024, 2)
            UsagePercent = $physicalMemoryUsagePercent
        }
        VirtualMemory = [PSCustomObject]@{
            TotalGB = [Math]::Round($totalVirtualMemory / 1024, 2)
            UsedGB = [Math]::Round($usedVirtualMemory / 1024, 2)
            FreeGB = [Math]::Round($freeVirtualMemory / 1024, 2)
            UsagePercent = $virtualMemoryUsagePercent
        }
        PageFile = [PSCustomObject]@{
            TotalGB = $pageFileTotal
            UsedGB = $pageFileUsed
            FreeGB = [Math]::Round($pageFileTotal - $pageFileUsed, 2)
            UsagePercent = $pageFileUsagePercent
        }
        Timestamp = Get-Date
    }
}

# Fonction pour obtenir les métriques d'I/O disque
function Get-DiskIOMetrics {
    <#
    .SYNOPSIS
        Obtient les métriques d'I/O disque actuelles.
    .DESCRIPTION
        Cette fonction récupère des informations détaillées sur les opérations d'I/O disque,
        y compris les taux de lecture/écriture et les temps de réponse.
    .PARAMETER SampleInterval
        Intervalle en secondes pour calculer les métriques d'I/O. Valeur par défaut: 1 seconde.
    .EXAMPLE
        Get-DiskIOMetrics -SampleInterval 2
    .OUTPUTS
        [PSCustomObject] avec les propriétés des métriques d'I/O disque
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleInterval = 1
    )
    
    # Obtenir les compteurs de performance initiaux
    $initialDiskRead = Get-Counter '\PhysicalDisk(*)\Disk Read Bytes/sec' -ErrorAction SilentlyContinue
    $initialDiskWrite = Get-Counter '\PhysicalDisk(*)\Disk Write Bytes/sec' -ErrorAction SilentlyContinue
    
    # Attendre l'intervalle spécifié
    Start-Sleep -Seconds $SampleInterval
    
    # Obtenir les compteurs de performance finaux
    $finalDiskRead = Get-Counter '\PhysicalDisk(*)\Disk Read Bytes/sec' -ErrorAction SilentlyContinue
    $finalDiskWrite = Get-Counter '\PhysicalDisk(*)\Disk Write Bytes/sec' -ErrorAction SilentlyContinue
    
    # Obtenir les temps de réponse du disque
    $diskResponse = Get-Counter '\PhysicalDisk(*)\Avg. Disk sec/Transfer' -ErrorAction SilentlyContinue
    
    # Vérifier si les mesures ont réussi
    if ($null -eq $initialDiskRead -or $null -eq $initialDiskWrite -or $null -eq $diskResponse) {
        Write-Warning "Impossible d'obtenir les compteurs d'I/O disque."
        return $null
    }
    
    # Calculer les métriques d'I/O pour chaque disque
    $disks = @{}
    $totalReadBytesPerSec = 0
    $totalWriteBytesPerSec = 0
    $totalResponseTime = 0
    $diskCount = 0
    
    # Traiter les disques individuels
    foreach ($sample in $finalDiskRead.CounterSamples) {
        $diskName = $sample.InstanceName
        
        # Ignorer _Total pour le moment
        if ($diskName -eq "_Total") {
            continue
        }
        
        $readBytes = $sample.CookedValue
        $writeBytes = ($finalDiskWrite.CounterSamples | Where-Object { $_.InstanceName -eq $diskName }).CookedValue
        $responseTime = ($diskResponse.CounterSamples | Where-Object { $_.InstanceName -eq $diskName }).CookedValue
        
        $disks[$diskName] = [PSCustomObject]@{
            ReadMBPerSec = [Math]::Round($readBytes / 1MB, 2)
            WriteMBPerSec = [Math]::Round($writeBytes / 1MB, 2)
            TotalMBPerSec = [Math]::Round(($readBytes + $writeBytes) / 1MB, 2)
            ResponseTimeMS = [Math]::Round($responseTime * 1000, 2)
        }
        
        $totalReadBytesPerSec += $readBytes
        $totalWriteBytesPerSec += $writeBytes
        $totalResponseTime += $responseTime
        $diskCount++
    }
    
    # Calculer les totaux
    $avgResponseTime = if ($diskCount -gt 0) { $totalResponseTime / $diskCount } else { 0 }
    
    # Retourner les résultats
    return [PSCustomObject]@{
        Disks = $disks
        Total = [PSCustomObject]@{
            ReadMBPerSec = [Math]::Round($totalReadBytesPerSec / 1MB, 2)
            WriteMBPerSec = [Math]::Round($totalWriteBytesPerSec / 1MB, 2)
            TotalMBPerSec = [Math]::Round(($totalReadBytesPerSec + $totalWriteBytesPerSec) / 1MB, 2)
            AvgResponseTimeMS = [Math]::Round($avgResponseTime * 1000, 2)
        }
        Timestamp = Get-Date
    }
}

# Fonction pour démarrer la surveillance des ressources
function Start-ResourceMonitoring {
    <#
    .SYNOPSIS
        Démarre la surveillance des ressources système en arrière-plan.
    .DESCRIPTION
        Cette fonction démarre un job en arrière-plan qui surveille périodiquement
        l'utilisation des ressources système (CPU, mémoire, I/O) et stocke les métriques.
    .PARAMETER Name
        Nom unique pour cette instance de surveillance.
    .PARAMETER IntervalSeconds
        Intervalle en secondes entre chaque collecte de métriques. Valeur par défaut: 5 secondes.
    .PARAMETER MaxDataPoints
        Nombre maximum de points de données à conserver en mémoire. Valeur par défaut: 1000.
    .PARAMETER OutputPath
        Chemin où stocker les métriques collectées. Si non spécifié, les métriques sont uniquement conservées en mémoire.
    .EXAMPLE
        Start-ResourceMonitoring -Name "MainMonitor" -IntervalSeconds 10
    .OUTPUTS
        [PSCustomObject] avec les informations sur le job de surveillance
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [int]$IntervalSeconds = 5,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDataPoints = 1000,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )
    
    # Vérifier si un moniteur avec ce nom existe déjà
    if ($script:MonitoringJobs.ContainsKey($Name)) {
        Write-Warning "Un moniteur avec le nom '$Name' existe déjà. Utilisez Stop-ResourceMonitoring pour l'arrêter d'abord."
        return $null
    }
    
    # Préparer le chemin de sortie si spécifié
    $outputFile = $null
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $outputFolder = Split-Path -Path $OutputPath -Parent
        if (-not (Test-Path -Path $outputFolder)) {
            New-Item -Path $outputFolder -ItemType Directory -Force | Out-Null
        }
        $outputFile = $OutputPath
    }
    
    # Initialiser l'historique des métriques pour ce moniteur
    $script:MetricsHistory[$Name] = @{
        CPU = @()
        Memory = @()
        DiskIO = @()
        Bottlenecks = @()
        MaxDataPoints = $MaxDataPoints
    }
    
    # Créer et démarrer le job de surveillance
    $job = Start-Job -ScriptBlock {
        param($modulePath, $name, $interval, $maxPoints, $outputFile)
        
        # Importer le module
        Import-Module $modulePath
        
        # Boucle de surveillance
        while ($true) {
            try {
                # Collecter les métriques
                $cpuMetrics = Get-CpuUsage -SampleInterval 1
                $memoryMetrics = Get-MemoryUsage
                $diskIOMetrics = Get-DiskIOMetrics -SampleInterval 1
                
                # Créer l'objet de métriques
                $metrics = [PSCustomObject]@{
                    Timestamp = Get-Date
                    CPU = $cpuMetrics
                    Memory = $memoryMetrics
                    DiskIO = $diskIOMetrics
                }
                
                # Enregistrer les métriques dans un fichier si spécifié
                if (-not [string]::IsNullOrEmpty($outputFile)) {
                    $metrics | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Append
                }
                
                # Publier les métriques pour qu'elles soient accessibles depuis l'extérieur du job
                $metrics | ConvertTo-Json -Depth 10 | Out-File -FilePath "$env:TEMP\$name-latest.json"
                
                # Attendre l'intervalle spécifié
                Start-Sleep -Seconds $interval
            }
            catch {
                Write-Error "Erreur lors de la surveillance des ressources: $_"
                Start-Sleep -Seconds 5
            }
        }
    } -ArgumentList $PSScriptRoot, $Name, $IntervalSeconds, $MaxDataPoints, $outputFile
    
    # Enregistrer le job
    $script:MonitoringJobs[$Name] = [PSCustomObject]@{
        Name = $Name
        Job = $job
        StartTime = Get-Date
        IntervalSeconds = $IntervalSeconds
        MaxDataPoints = $MaxDataPoints
        OutputPath = $OutputPath
        LatestDataPath = "$env:TEMP\$Name-latest.json"
    }
    
    # Retourner les informations sur le job
    return $script:MonitoringJobs[$Name]
}

# Fonction pour arrêter la surveillance des ressources
function Stop-ResourceMonitoring {
    <#
    .SYNOPSIS
        Arrête la surveillance des ressources système.
    .DESCRIPTION
        Cette fonction arrête un job de surveillance des ressources système
        précédemment démarré avec Start-ResourceMonitoring.
    .PARAMETER Name
        Nom de l'instance de surveillance à arrêter.
    .EXAMPLE
        Stop-ResourceMonitoring -Name "MainMonitor"
    .OUTPUTS
        [bool] Indique si l'arrêt a réussi
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Vérifier si le moniteur existe
    if (-not $script:MonitoringJobs.ContainsKey($Name)) {
        Write-Warning "Aucun moniteur avec le nom '$Name' n'a été trouvé."
        return $false
    }
    
    # Récupérer le job
    $monitorJob = $script:MonitoringJobs[$Name]
    
    # Arrêter le job
    Stop-Job -Job $monitorJob.Job -ErrorAction SilentlyContinue
    Remove-Job -Job $monitorJob.Job -Force -ErrorAction SilentlyContinue
    
    # Supprimer le fichier de données temporaire
    if (Test-Path -Path $monitorJob.LatestDataPath) {
        Remove-Item -Path $monitorJob.LatestDataPath -Force -ErrorAction SilentlyContinue
    }
    
    # Supprimer le moniteur de la liste
    $script:MonitoringJobs.Remove($Name)
    
    return $true
}

# Fonction pour obtenir les métriques actuelles
function Get-CurrentResourceMetrics {
    <#
    .SYNOPSIS
        Obtient les métriques actuelles des ressources système.
    .DESCRIPTION
        Cette fonction récupère les dernières métriques collectées par un moniteur
        de ressources système spécifique.
    .PARAMETER Name
        Nom de l'instance de surveillance.
    .EXAMPLE
        Get-CurrentResourceMetrics -Name "MainMonitor"
    .OUTPUTS
        [PSCustomObject] avec les métriques actuelles
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Vérifier si le moniteur existe
    if (-not $script:MonitoringJobs.ContainsKey($Name)) {
        Write-Warning "Aucun moniteur avec le nom '$Name' n'a été trouvé."
        return $null
    }
    
    # Récupérer le chemin des dernières données
    $latestDataPath = $script:MonitoringJobs[$Name].LatestDataPath
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $latestDataPath)) {
        Write-Warning "Aucune donnée disponible pour le moniteur '$Name'."
        return $null
    }
    
    # Lire et convertir les données
    try {
        $metricsJson = Get-Content -Path $latestDataPath -Raw
        $metrics = $metricsJson | ConvertFrom-Json
        return $metrics
    }
    catch {
        Write-Error "Erreur lors de la lecture des métriques: $_"
        return $null
    }
}

# Exporter les fonctions du module
Export-ModuleMember -Function Get-CpuUsage, Get-MemoryUsage, Get-DiskIOMetrics, 
                              Start-ResourceMonitoring, Stop-ResourceMonitoring,
                              Get-CurrentResourceMetrics

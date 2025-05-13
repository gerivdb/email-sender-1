#Requires -Version 5.1
<#
.SYNOPSIS
    Orchestrateur de conteneurs légers.
.DESCRIPTION
    Ce script combine le moniteur de ressources et le gestionnaire de conteneurs légers
    pour orchestrer l'exécution de conteneurs avec une allocation intelligente des ressources.
.NOTES
    Nom: Start-ContainerOrchestrator.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de création: 2025-05-20
#>

# Importer les modules
$resourceMonitorPath = Join-Path -Path $PSScriptRoot -ChildPath "ResourceMonitor.psm1"
$containerPath = Join-Path -Path $PSScriptRoot -ChildPath "LightweightContainer.psm1"

if (-not (Test-Path -Path $resourceMonitorPath)) {
    Write-Error "Module ResourceMonitor.psm1 introuvable à l'emplacement: $resourceMonitorPath"
    exit 1
}

if (-not (Test-Path -Path $containerPath)) {
    Write-Error "Module LightweightContainer.psm1 introuvable à l'emplacement: $containerPath"
    exit 1
}

Import-Module $resourceMonitorPath -Force
Import-Module $containerPath -Force

# Paramètres de l'orchestrateur
$maxConcurrentContainers = [Environment]::ProcessorCount
$cpuThreshold = 80  # Pourcentage maximum d'utilisation CPU
$memoryThreshold = 80  # Pourcentage maximum d'utilisation mémoire
$monitorName = "ContainerOrchestratorMonitor"
$containerQueue = New-Object System.Collections.Queue
$activeContainers = @{}

# Fonction pour ajouter un conteneur à la file d'attente
function Add-ContainerToQueue {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$ImageName,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [object[]]$ArgumentList,
        
        [Parameter(Mandatory = $false)]
        [int]$Priority = 5,  # 1-10, 10 étant la priorité la plus élevée
        
        [Parameter(Mandatory = $false)]
        [hashtable]$EnvironmentVariables = @{},
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ResourceLimits = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$Persistent
    )
    
    $containerInfo = [PSCustomObject]@{
        Name = $Name
        ImageName = $ImageName
        ScriptBlock = $ScriptBlock
        ArgumentList = $ArgumentList
        Priority = $Priority
        EnvironmentVariables = $EnvironmentVariables
        ResourceLimits = $ResourceLimits
        Persistent = $Persistent
        QueueTime = Get-Date
    }
    
    $containerQueue.Enqueue($containerInfo)
    Write-Host "Conteneur '$Name' ajouté à la file d'attente (Priorité: $Priority)" -ForegroundColor Cyan
    
    return $containerInfo
}

# Fonction pour démarrer l'orchestrateur
function Start-ContainerOrchestrator {
    param (
        [Parameter(Mandatory = $false)]
        [int]$MaxConcurrentContainers = $maxConcurrentContainers,
        
        [Parameter(Mandatory = $false)]
        [int]$CpuThreshold = $cpuThreshold,
        
        [Parameter(Mandatory = $false)]
        [int]$MemoryThreshold = $memoryThreshold,
        
        [Parameter(Mandatory = $false)]
        [int]$UpdateIntervalSeconds = 2
    )
    
    # Démarrer le moniteur de ressources
    $monitor = Start-ResourceMonitoring -Name $monitorName -IntervalSeconds 1
    
    if ($null -eq $monitor) {
        Write-Error "Impossible de démarrer le moniteur de ressources."
        return
    }
    
    Write-Host "Orchestrateur de conteneurs démarré avec les paramètres suivants:" -ForegroundColor Green
    Write-Host "  Conteneurs concurrents max: $MaxConcurrentContainers" -ForegroundColor Gray
    Write-Host "  Seuil CPU: $CpuThreshold%" -ForegroundColor Gray
    Write-Host "  Seuil mémoire: $MemoryThreshold%" -ForegroundColor Gray
    Write-Host "  Intervalle de mise à jour: $UpdateIntervalSeconds secondes" -ForegroundColor Gray
    
    try {
        # Boucle principale de l'orchestrateur
        while ($true) {
            # Obtenir les métriques actuelles
            $metrics = Get-CurrentResourceMetrics -Name $monitorName
            
            if ($null -ne $metrics) {
                $cpuUsage = $metrics.CPU.TotalUsage
                $memoryUsage = $metrics.Memory.PhysicalMemory.UsagePercent
                
                # Afficher les métriques actuelles
                Write-Host "`n===== Métriques système =====" -ForegroundColor Cyan
                Write-Host "CPU: $cpuUsage% | Mémoire: $memoryUsage% | Conteneurs actifs: $($activeContainers.Count) | File d'attente: $($containerQueue.Count)" -ForegroundColor Yellow
                
                # Vérifier si nous pouvons démarrer de nouveaux conteneurs
                $canStartNewContainer = ($activeContainers.Count -lt $MaxConcurrentContainers) -and 
                                      ($cpuUsage -lt $CpuThreshold) -and 
                                      ($memoryUsage -lt $MemoryThreshold) -and
                                      ($containerQueue.Count -gt 0)
                
                if ($canStartNewContainer) {
                    # Récupérer le conteneur suivant
                    $containerInfo = $containerQueue.Dequeue()
                    
                    # Calculer les limites de ressources
                    $availableCpu = $CpuThreshold - $cpuUsage
                    $cpuLimit = [Math]::Max(10, [Math]::Min(50, $availableCpu))
                    
                    # Mettre à jour les limites de ressources
                    if (-not $containerInfo.ResourceLimits.ContainsKey("CPULimit")) {
                        $containerInfo.ResourceLimits["CPULimit"] = $cpuLimit
                    }
                    
                    # Créer le conteneur s'il n'existe pas déjà
                    $container = Get-Container -Name $containerInfo.Name
                    if ($null -eq $container) {
                        $container = New-Container -Name $containerInfo.Name -ImageName $containerInfo.ImageName -EnvironmentVariables $containerInfo.EnvironmentVariables -ResourceLimits $containerInfo.ResourceLimits -Persistent:$containerInfo.Persistent
                    }
                    
                    if ($null -ne $container) {
                        # Démarrer le conteneur
                        $startedContainer = Start-Container -Name $containerInfo.Name -ScriptBlock $containerInfo.ScriptBlock -ArgumentList $containerInfo.ArgumentList
                        
                        if ($null -ne $startedContainer) {
                            $activeContainers[$containerInfo.Name] = $startedContainer
                            Write-Host "Conteneur '$($containerInfo.Name)' démarré (PID: $($startedContainer.Process.Id), Limite CPU: $cpuLimit%)" -ForegroundColor Green
                        } else {
                            Write-Host "Échec du démarrage du conteneur '$($containerInfo.Name)'" -ForegroundColor Red
                            # Remettre le conteneur dans la file d'attente
                            $containerQueue.Enqueue($containerInfo)
                        }
                    } else {
                        Write-Host "Échec de la création du conteneur '$($containerInfo.Name)'" -ForegroundColor Red
                        # Remettre le conteneur dans la file d'attente
                        $containerQueue.Enqueue($containerInfo)
                    }
                } else {
                    if ($containerQueue.Count -gt 0) {
                        if ($activeContainers.Count -ge $MaxConcurrentContainers) {
                            Write-Host "Nombre maximum de conteneurs concurrents atteint ($MaxConcurrentContainers)" -ForegroundColor Yellow
                        } elseif ($cpuUsage -ge $CpuThreshold) {
                            Write-Host "Utilisation CPU trop élevée ($cpuUsage% >= $CpuThreshold%)" -ForegroundColor Yellow
                        } elseif ($memoryUsage -ge $MemoryThreshold) {
                            Write-Host "Utilisation mémoire trop élevée ($memoryUsage% >= $MemoryThreshold%)" -ForegroundColor Yellow
                        }
                    }
                }
                
                # Mettre à jour l'état des conteneurs actifs
                $containersToRemove = @()
                foreach ($containerName in $activeContainers.Keys) {
                    $container = Get-Container -Name $containerName
                    
                    if ($null -eq $container -or $container.Status -eq "Stopped") {
                        $containersToRemove += $containerName
                        Write-Host "Conteneur '$containerName' terminé (Statut: $($container.Status))" -ForegroundColor Cyan
                    } else {
                        Write-Host "  $containerName (PID: $($container.Process.Id), Statut: $($container.Status))" -ForegroundColor Gray
                        if ($container.PSObject.Properties.Name -contains "CPU") {
                            Write-Host "    CPU: $($container.CPU) | Mémoire: $($container.Memory) MB" -ForegroundColor Gray
                        }
                    }
                }
                
                # Supprimer les conteneurs terminés
                foreach ($containerName in $containersToRemove) {
                    $activeContainers.Remove($containerName)
                }
            } else {
                Write-Host "Aucune métrique disponible." -ForegroundColor Yellow
            }
            
            # Attendre l'intervalle de mise à jour
            Start-Sleep -Seconds $UpdateIntervalSeconds
            
            # Vérifier si l'utilisateur a appuyé sur une touche
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                
                if ($key.Key -eq "Q") {
                    Write-Host "`nArrêt de l'orchestrateur..." -ForegroundColor Yellow
                    break
                } elseif ($key.Key -eq "I") {
                    # Afficher des informations détaillées
                    Write-Host "`n===== Informations détaillées =====" -ForegroundColor Cyan
                    Write-Host "Conteneurs actifs: $($activeContainers.Count)" -ForegroundColor Yellow
                    Write-Host "Conteneurs en file d'attente: $($containerQueue.Count)" -ForegroundColor Yellow
                    Write-Host "Ressources système:" -ForegroundColor Yellow
                    Write-Host "  CPU: $cpuUsage%" -ForegroundColor Gray
                    Write-Host "  Mémoire: $memoryUsage%" -ForegroundColor Gray
                    Write-Host "Appuyez sur une touche pour continuer..." -ForegroundColor Cyan
                    [Console]::ReadKey($true) | Out-Null
                }
            }
        }
    } finally {
        # Arrêter tous les conteneurs actifs
        Write-Host "`nArrêt des conteneurs actifs..." -ForegroundColor Yellow
        foreach ($containerName in $activeContainers.Keys) {
            Stop-Container -Name $containerName -Force | Out-Null
            Write-Host "  Conteneur '$containerName' arrêté" -ForegroundColor Gray
        }
        
        # Arrêter le moniteur de ressources
        Stop-ResourceMonitoring -Name $monitorName | Out-Null
        
        Write-Host "Orchestrateur arrêté." -ForegroundColor Green
    }
}

# Exemple d'utilisation
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    # Ce code s'exécute uniquement si le script est exécuté directement (pas importé)
    
    Write-Host "===== ORCHESTRATEUR DE CONTENEURS =====" -ForegroundColor Cyan
    Write-Host "Appuyez sur 'Q' pour quitter, 'I' pour afficher des informations détaillées." -ForegroundColor Yellow
    
    # Créer une image de base
    $baseImage = New-ContainerImage -Name "BaseImage" -ModuleDependencies @("Microsoft.PowerShell.Management", "Microsoft.PowerShell.Utility") -EnvironmentVariables @{
        "CONTAINER_ENV" = "Production"
        "LOG_LEVEL" = "Info"
    }
    
    # Ajouter quelques conteneurs de test
    Add-ContainerToQueue -Name "CPU_Container" -ImageName "BaseImage" -Priority 8 -ScriptBlock {
        Write-Host "Conteneur CPU intensif démarré (PID: $PID)"
        $startTime = Get-Date
        $duration = 30  # secondes
        
        while ((Get-Date) -lt $startTime.AddSeconds($duration)) {
            # Utilisation intensive du CPU
            $result = 0
            for ($i = 0; $i -lt 10000000; $i++) {
                $result += [Math]::Sqrt($i)
            }
            
            # Petite pause pour éviter de bloquer complètement le système
            Start-Sleep -Milliseconds 100
        }
        
        Write-Host "Conteneur CPU intensif terminé"
    } -EnvironmentVariables @{
        "CONTAINER_TYPE" = "CPU"
    }
    
    Add-ContainerToQueue -Name "Memory_Container" -ImageName "BaseImage" -Priority 6 -ScriptBlock {
        Write-Host "Conteneur mémoire intensif démarré (PID: $PID)"
        $startTime = Get-Date
        $duration = 20  # secondes
        
        # Allouer de la mémoire
        $memoryList = New-Object System.Collections.ArrayList
        
        while ((Get-Date) -lt $startTime.AddSeconds($duration)) {
            # Allouer environ 10 MB à chaque itération
            $data = New-Object byte[] (10 * 1024 * 1024)
            $memoryList.Add($data) | Out-Null
            
            Write-Host "Mémoire allouée: $($memoryList.Count * 10) MB"
            Start-Sleep -Seconds 2
        }
        
        # Libérer la mémoire
        $memoryList.Clear()
        [System.GC]::Collect()
        
        Write-Host "Conteneur mémoire intensif terminé"
    } -EnvironmentVariables @{
        "CONTAINER_TYPE" = "Memory"
    } -Persistent
    
    Add-ContainerToQueue -Name "IO_Container" -ImageName "BaseImage" -Priority 4 -ScriptBlock {
        Write-Host "Conteneur I/O intensif démarré (PID: $PID)"
        $startTime = Get-Date
        $duration = 15  # secondes
        
        $tempFile = [System.IO.Path]::GetTempFileName()
        
        while ((Get-Date) -lt $startTime.AddSeconds($duration)) {
            # Écrire des données dans un fichier temporaire
            $data = New-Object byte[] (5 * 1024 * 1024)  # 5 MB
            [System.IO.File]::WriteAllBytes($tempFile, $data)
            
            # Lire les données
            $readData = [System.IO.File]::ReadAllBytes($tempFile)
            
            Write-Host "Données écrites/lues: 5 MB"
            Start-Sleep -Seconds 1
        }
        
        # Supprimer le fichier temporaire
        Remove-Item -Path $tempFile -Force
        
        Write-Host "Conteneur I/O intensif terminé"
    } -EnvironmentVariables @{
        "CONTAINER_TYPE" = "IO"
    }
    
    # Démarrer l'orchestrateur
    Start-ContainerOrchestrator -MaxConcurrentContainers 3 -CpuThreshold 80 -MemoryThreshold 80 -UpdateIntervalSeconds 2
}

# Exporter les fonctions
Export-ModuleMember -Function Add-ContainerToQueue, Start-ContainerOrchestrator

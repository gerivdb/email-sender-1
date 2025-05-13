#Requires -Version 5.1
<#
.SYNOPSIS
    Orchestrateur de ressources pour l'execution de taches paralleles.
.DESCRIPTION
    Ce script combine le moniteur de ressources et le gestionnaire de terminaux
    pour orchestrer l'execution de taches paralleles avec une allocation
    intelligente des ressources.
.NOTES
    Nom: Start-ResourceOrchestrator.ps1
    Auteur: EMAIL_SENDER_1 Team
    Version: 1.0
    Date de creation: 2025-05-20
#>

# Importer les modules
$resourceMonitorPath = Join-Path -Path $PSScriptRoot -ChildPath "ResourceMonitor.psm1"
$terminalManagerPath = Join-Path -Path $PSScriptRoot -ChildPath "TerminalManager.psm1"

if (-not (Test-Path -Path $resourceMonitorPath)) {
    Write-Error "Module ResourceMonitor.psm1 introuvable a l'emplacement: $resourceMonitorPath"
    exit 1
}

if (-not (Test-Path -Path $terminalManagerPath)) {
    Write-Error "Module TerminalManager.psm1 introuvable a l'emplacement: $terminalManagerPath"
    exit 1
}

Import-Module $resourceMonitorPath -Force
Import-Module $terminalManagerPath -Force

# Parametres de l'orchestrateur
$maxConcurrentTasks = [Environment]::ProcessorCount
$cpuThreshold = 80  # Pourcentage maximum d'utilisation CPU
$memoryThreshold = 80  # Pourcentage maximum d'utilisation memoire
$monitorName = "OrchestratorMonitor"
$taskQueue = New-Object System.Collections.Queue
$activeTasks = @{}

# Fonction pour ajouter une tache a la file d'attente
function Add-Task {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [object[]]$ArgumentList,
        
        [Parameter(Mandatory = $false)]
        [int]$Priority = 5,  # 1-10, 10 etant la priorite la plus elevee
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ResourceLimits
    )
    
    $task = [PSCustomObject]@{
        Name = $Name
        ScriptBlock = $ScriptBlock
        ArgumentList = $ArgumentList
        Priority = $Priority
        ResourceLimits = $ResourceLimits
        QueueTime = Get-Date
    }
    
    $taskQueue.Enqueue($task)
    Write-Host "Tache '$Name' ajoutee a la file d'attente (Priorite: $Priority)" -ForegroundColor Cyan
    
    return $task
}

# Fonction pour demarrer l'orchestrateur
function Start-Orchestrator {
    param (
        [Parameter(Mandatory = $false)]
        [int]$MaxConcurrentTasks = $maxConcurrentTasks,
        
        [Parameter(Mandatory = $false)]
        [int]$CpuThreshold = $cpuThreshold,
        
        [Parameter(Mandatory = $false)]
        [int]$MemoryThreshold = $memoryThreshold,
        
        [Parameter(Mandatory = $false)]
        [int]$UpdateIntervalSeconds = 2
    )
    
    # Demarrer le moniteur de ressources
    $monitor = Start-ResourceMonitoring -Name $monitorName -IntervalSeconds 1
    
    if ($null -eq $monitor) {
        Write-Error "Impossible de demarrer le moniteur de ressources."
        return
    }
    
    Write-Host "Orchestrateur demarre avec les parametres suivants:" -ForegroundColor Green
    Write-Host "  Taches concurrentes max: $MaxConcurrentTasks" -ForegroundColor Gray
    Write-Host "  Seuil CPU: $CpuThreshold%" -ForegroundColor Gray
    Write-Host "  Seuil memoire: $MemoryThreshold%" -ForegroundColor Gray
    Write-Host "  Intervalle de mise a jour: $UpdateIntervalSeconds secondes" -ForegroundColor Gray
    
    try {
        # Boucle principale de l'orchestrateur
        while ($true) {
            # Obtenir les metriques actuelles
            $metrics = Get-CurrentResourceMetrics -Name $monitorName
            
            if ($null -ne $metrics) {
                $cpuUsage = $metrics.CPU.TotalUsage
                $memoryUsage = $metrics.Memory.PhysicalMemory.UsagePercent
                
                # Afficher les metriques actuelles
                Write-Host "`n===== Metriques systeme =====" -ForegroundColor Cyan
                Write-Host "CPU: $cpuUsage% | Memoire: $memoryUsage% | Taches actives: $($activeTasks.Count) | File d'attente: $($taskQueue.Count)" -ForegroundColor Yellow
                
                # Verifier si nous pouvons demarrer de nouvelles taches
                $canStartNewTask = ($activeTasks.Count -lt $MaxConcurrentTasks) -and 
                                  ($cpuUsage -lt $CpuThreshold) -and 
                                  ($memoryUsage -lt $MemoryThreshold) -and
                                  ($taskQueue.Count -gt 0)
                
                if ($canStartNewTask) {
                    # Recuperer la tache suivante
                    $task = $taskQueue.Dequeue()
                    
                    # Calculer les limites de ressources
                    $availableCpu = $CpuThreshold - $cpuUsage
                    $cpuLimit = [Math]::Max(10, [Math]::Min(50, $availableCpu))
                    
                    # Demarrer la tache
                    $terminal = New-Terminal -Name $task.Name -ScriptBlock $task.ScriptBlock -ArgumentList $task.ArgumentList -ResourceLimits @{
                        CPULimit = $cpuLimit
                        Priority = $task.Priority
                    }
                    
                    if ($null -ne $terminal) {
                        $activeTasks[$task.Name] = $terminal
                        Write-Host "Tache '$($task.Name)' demarree (PID: $($terminal.PID), Limite CPU: $cpuLimit%)" -ForegroundColor Green
                    } else {
                        Write-Host "Echec du demarrage de la tache '$($task.Name)'" -ForegroundColor Red
                        # Remettre la tache dans la file d'attente
                        $taskQueue.Enqueue($task)
                    }
                } else {
                    if ($taskQueue.Count -gt 0) {
                        if ($activeTasks.Count -ge $MaxConcurrentTasks) {
                            Write-Host "Nombre maximum de taches concurrentes atteint ($MaxConcurrentTasks)" -ForegroundColor Yellow
                        } elseif ($cpuUsage -ge $CpuThreshold) {
                            Write-Host "Utilisation CPU trop elevee ($cpuUsage% >= $CpuThreshold%)" -ForegroundColor Yellow
                        } elseif ($memoryUsage -ge $MemoryThreshold) {
                            Write-Host "Utilisation memoire trop elevee ($memoryUsage% >= $MemoryThreshold%)" -ForegroundColor Yellow
                        }
                    }
                }
                
                # Mettre a jour l'etat des taches actives
                $terminalsToRemove = @()
                foreach ($terminalName in $activeTasks.Keys) {
                    $terminal = Get-Terminal -Name $terminalName
                    
                    if ($null -eq $terminal -or $terminal.Status -eq "Stopped" -or $terminal.Status -eq "Completed" -or $terminal.Status -eq "Error") {
                        $terminalsToRemove += $terminalName
                        Write-Host "Tache '$terminalName' terminee (Statut: $($terminal.Status))" -ForegroundColor Cyan
                    } else {
                        Write-Host "  $terminalName (PID: $($terminal.PID), Statut: $($terminal.Status))" -ForegroundColor Gray
                        if ($terminal.PSObject.Properties.Name -contains "CPU") {
                            Write-Host "    CPU: $($terminal.CPU) | Memoire: $($terminal.Memory) MB" -ForegroundColor Gray
                        }
                    }
                }
                
                # Supprimer les taches terminees
                foreach ($terminalName in $terminalsToRemove) {
                    $activeTasks.Remove($terminalName)
                }
                
                # Nettoyer les terminaux inactifs
                Remove-InactiveTerminals -RemoveFiles | Out-Null
            } else {
                Write-Host "Aucune metrique disponible." -ForegroundColor Yellow
            }
            
            # Attendre l'intervalle de mise a jour
            Start-Sleep -Seconds $UpdateIntervalSeconds
            
            # Verifier si l'utilisateur a appuye sur une touche
            if ([Console]::KeyAvailable) {
                $key = [Console]::ReadKey($true)
                
                if ($key.Key -eq "Q") {
                    Write-Host "`nArret de l'orchestrateur..." -ForegroundColor Yellow
                    break
                } elseif ($key.Key -eq "I") {
                    # Afficher des informations detaillees
                    Write-Host "`n===== Informations detaillees =====" -ForegroundColor Cyan
                    Write-Host "Taches actives: $($activeTasks.Count)" -ForegroundColor Yellow
                    Write-Host "Taches en file d'attente: $($taskQueue.Count)" -ForegroundColor Yellow
                    Write-Host "Ressources systeme:" -ForegroundColor Yellow
                    Write-Host "  CPU: $cpuUsage%" -ForegroundColor Gray
                    Write-Host "  Memoire: $memoryUsage%" -ForegroundColor Gray
                    Write-Host "Appuyez sur une touche pour continuer..." -ForegroundColor Cyan
                    [Console]::ReadKey($true) | Out-Null
                }
            }
        }
    } finally {
        # Arreter toutes les taches actives
        Write-Host "`nArret des taches actives..." -ForegroundColor Yellow
        foreach ($terminalName in $activeTasks.Keys) {
            Stop-Terminal -Name $terminalName -Force | Out-Null
            Write-Host "  Tache '$terminalName' arretee" -ForegroundColor Gray
        }
        
        # Nettoyer les terminaux inactifs
        Remove-InactiveTerminals -RemoveFiles | Out-Null
        
        # Arreter le moniteur de ressources
        Stop-ResourceMonitoring -Name $monitorName | Out-Null
        
        Write-Host "Orchestrateur arrete." -ForegroundColor Green
    }
}

# Exemple d'utilisation
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    # Ce code s'execute uniquement si le script est execute directement (pas importe)
    
    Write-Host "===== ORCHESTRATEUR DE RESSOURCES =====" -ForegroundColor Cyan
    Write-Host "Appuyez sur 'Q' pour quitter, 'I' pour afficher des informations detaillees." -ForegroundColor Yellow
    
    # Ajouter quelques taches de test
    Add-Task -Name "CPU_Intensive_Task" -Priority 8 -ScriptBlock {
        Write-Host "Tache CPU intensive demarree (PID: $PID)"
        $startTime = Get-Date
        $duration = 30  # secondes
        
        while ((Get-Date) -lt $startTime.AddSeconds($duration)) {
            # Utilisation intensive du CPU
            $result = 0
            for ($i = 0; $i -lt 10000000; $i++) {
                $result += [Math]::Sqrt($i)
            }
            
            # Petite pause pour eviter de bloquer completement le systeme
            Start-Sleep -Milliseconds 100
        }
        
        Write-Host "Tache CPU intensive terminee"
    }
    
    Add-Task -Name "Memory_Intensive_Task" -Priority 6 -ScriptBlock {
        Write-Host "Tache memoire intensive demarree (PID: $PID)"
        $startTime = Get-Date
        $duration = 20  # secondes
        
        # Allouer de la memoire
        $memoryList = New-Object System.Collections.ArrayList
        
        while ((Get-Date) -lt $startTime.AddSeconds($duration)) {
            # Allouer environ 10 MB a chaque iteration
            $data = New-Object byte[] (10 * 1024 * 1024)
            $memoryList.Add($data) | Out-Null
            
            Write-Host "Memoire allouee: $($memoryList.Count * 10) MB"
            Start-Sleep -Seconds 2
        }
        
        # Liberer la memoire
        $memoryList.Clear()
        [System.GC]::Collect()
        
        Write-Host "Tache memoire intensive terminee"
    }
    
    Add-Task -Name "IO_Intensive_Task" -Priority 4 -ScriptBlock {
        Write-Host "Tache I/O intensive demarree (PID: $PID)"
        $startTime = Get-Date
        $duration = 15  # secondes
        
        $tempFile = [System.IO.Path]::GetTempFileName()
        
        while ((Get-Date) -lt $startTime.AddSeconds($duration)) {
            # Ecrire des donnees dans un fichier temporaire
            $data = New-Object byte[] (5 * 1024 * 1024)  # 5 MB
            [System.IO.File]::WriteAllBytes($tempFile, $data)
            
            # Lire les donnees
            $readData = [System.IO.File]::ReadAllBytes($tempFile)
            
            Write-Host "Donnees ecrites/lues: 5 MB"
            Start-Sleep -Seconds 1
        }
        
        # Supprimer le fichier temporaire
        Remove-Item -Path $tempFile -Force
        
        Write-Host "Tache I/O intensive terminee"
    }
    
    # Demarrer l'orchestrateur
    Start-Orchestrator -MaxConcurrentTasks 3 -CpuThreshold 80 -MemoryThreshold 80 -UpdateIntervalSeconds 2
}

# Exporter les fonctions
Export-ModuleMember -Function Add-Task, Start-Orchestrator

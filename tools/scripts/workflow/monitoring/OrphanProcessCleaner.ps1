<#
.SYNOPSIS
    Nettoie les processus orphelins laissés par des scripts ou applications.

.DESCRIPTION
    Ce script identifie et nettoie les processus orphelins qui peuvent être laissés
    lorsque des scripts ou applications se terminent de manière inattendue. Il peut
    être configuré pour surveiller des processus spécifiques ou des modèles de noms.

.EXAMPLE
    . .\OrphanProcessCleaner.ps1
    Register-ProcessPattern -Name "chrome" -MaxLifetimeMinutes 60
    Start-ProcessMonitoring

.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 07/04/2025
    Version: 1.0
#>

# Liste des modèles de processus à surveiller
$script:ProcessPatterns = [System.Collections.Generic.List[PSCustomObject]]::new()

# Timer pour la surveillance des processus
$script:MonitoringTimer = $null

# Fonction pour enregistrer un modèle de processus à surveiller
function Register-ProcessPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [string]$CommandLinePattern = "",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxLifetimeMinutes = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxMemoryMB = 0,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxCPUPercent = 0,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$CustomCondition = { $false },
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$BeforeKill = { param($process) },
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si le modèle existe déjà
    $existingPattern = $script:ProcessPatterns | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    
    if ($null -ne $existingPattern) {
        if ($Force) {
            # Supprimer le modèle existant
            $script:ProcessPatterns.Remove($existingPattern)
        }
        else {
            Write-Error "Un modèle de processus avec le nom '$Name' existe déjà. Utilisez -Force pour le remplacer."
            return
        }
    }
    
    # Créer le modèle de processus
    $pattern = [PSCustomObject]@{
        Name = $Name
        CommandLinePattern = $CommandLinePattern
        MaxLifetimeMinutes = $MaxLifetimeMinutes
        MaxMemoryMB = $MaxMemoryMB
        MaxCPUPercent = $MaxCPUPercent
        CustomCondition = $CustomCondition
        BeforeKill = $BeforeKill
        LastCleanupTime = [datetime]::MinValue
    }
    
    # Ajouter le modèle à la liste
    $script:ProcessPatterns.Add($pattern)
    
    Write-Verbose "Modèle de processus '$Name' enregistré."
}

# Fonction pour supprimer un modèle de processus
function Unregister-ProcessPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Trouver le modèle
    $pattern = $script:ProcessPatterns | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    
    if ($null -eq $pattern) {
        Write-Error "Modèle de processus '$Name' non trouvé."
        return $false
    }
    
    # Supprimer le modèle
    $script:ProcessPatterns.Remove($pattern)
    
    Write-Verbose "Modèle de processus '$Name' supprimé."
    return $true
}

# Fonction pour obtenir la liste des modèles de processus
function Get-ProcessPatterns {
    [CmdletBinding()]
    param ()
    
    return $script:ProcessPatterns
}

# Fonction pour nettoyer les processus orphelins
function Clear-OrphanProcesses {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    $killedProcesses = @()
    
    # Filtrer les modèles de processus
    $patterns = if ([string]::IsNullOrEmpty($Name)) {
        $script:ProcessPatterns
    }
    else {
        $script:ProcessPatterns | Where-Object { $_.Name -eq $Name }
    }
    
    if ($patterns.Count -eq 0) {
        Write-Warning "Aucun modèle de processus trouvé."
        return $killedProcesses
    }
    
    # Traiter chaque modèle
    foreach ($pattern in $patterns) {
        Write-Verbose "Traitement du modèle '$($pattern.Name)'..."
        
        # Obtenir les processus correspondant au modèle
        $processes = Get-Process -Name $pattern.Name -ErrorAction SilentlyContinue
        
        if ($null -eq $processes -or $processes.Count -eq 0) {
            Write-Verbose "Aucun processus trouvé pour le modèle '$($pattern.Name)'."
            continue
        }
        
        # Filtrer les processus en fonction des critères
        foreach ($process in $processes) {
            $shouldKill = $false
            $reason = ""
            
            # Vérifier la durée de vie
            if ($pattern.MaxLifetimeMinutes -gt 0) {
                $lifetime = (Get-Date) - $process.StartTime
                if ($lifetime.TotalMinutes -gt $pattern.MaxLifetimeMinutes) {
                    $shouldKill = $true
                    $reason = "Durée de vie dépassée ($($lifetime.TotalMinutes.ToString('F2')) minutes > $($pattern.MaxLifetimeMinutes) minutes)"
                }
            }
            
            # Vérifier l'utilisation de la mémoire
            if (-not $shouldKill -and $pattern.MaxMemoryMB -gt 0) {
                $memoryMB = $process.WorkingSet64 / 1MB
                if ($memoryMB -gt $pattern.MaxMemoryMB) {
                    $shouldKill = $true
                    $reason = "Utilisation de la mémoire dépassée ($($memoryMB.ToString('F2')) MB > $($pattern.MaxMemoryMB) MB)"
                }
            }
            
            # Vérifier l'utilisation du CPU
            if (-not $shouldKill -and $pattern.MaxCPUPercent -gt 0) {
                # Obtenir l'utilisation du CPU (nécessite plusieurs mesures)
                $cpuCounter = New-Object System.Diagnostics.PerformanceCounter("Process", "% Processor Time", $process.ProcessName, $true)
                $cpuCounter.NextValue() | Out-Null
                Start-Sleep -Milliseconds 100
                $cpuPercent = $cpuCounter.NextValue() / [System.Environment]::ProcessorCount
                
                if ($cpuPercent -gt $pattern.MaxCPUPercent) {
                    $shouldKill = $true
                    $reason = "Utilisation du CPU dépassée ($($cpuPercent.ToString('F2'))% > $($pattern.MaxCPUPercent)%)"
                }
            }
            
            # Vérifier la ligne de commande
            if (-not $shouldKill -and -not [string]::IsNullOrEmpty($pattern.CommandLinePattern)) {
                try {
                    $commandLine = (Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($process.Id)").CommandLine
                    if ($commandLine -match $pattern.CommandLinePattern) {
                        $shouldKill = $true
                        $reason = "Ligne de commande correspondant au modèle '$($pattern.CommandLinePattern)'"
                    }
                }
                catch {
                    Write-Warning "Erreur lors de l'obtention de la ligne de commande pour le processus $($process.Id): $_"
                }
            }
            
            # Vérifier la condition personnalisée
            if (-not $shouldKill -and $null -ne $pattern.CustomCondition) {
                try {
                    $shouldKill = & $pattern.CustomCondition -Process $process
                    if ($shouldKill) {
                        $reason = "Condition personnalisée satisfaite"
                    }
                }
                catch {
                    Write-Warning "Erreur lors de l'évaluation de la condition personnalisée pour le processus $($process.Id): $_"
                }
            }
            
            # Tuer le processus si nécessaire
            if ($shouldKill) {
                Write-Verbose "Processus $($process.Id) ($($process.ProcessName)) identifié comme orphelin: $reason"
                
                if (-not $WhatIf) {
                    try {
                        # Exécuter le script BeforeKill
                        if ($null -ne $pattern.BeforeKill) {
                            try {
                                & $pattern.BeforeKill -Process $process
                            }
                            catch {
                                Write-Warning "Erreur lors de l'exécution du script BeforeKill pour le processus $($process.Id): $_"
                            }
                        }
                        
                        # Tuer le processus
                        $process.Kill()
                        $process.WaitForExit(5000)
                        
                        $killedProcesses += [PSCustomObject]@{
                            Id = $process.Id
                            Name = $process.ProcessName
                            StartTime = $process.StartTime
                            Reason = $reason
                        }
                        
                        Write-Verbose "Processus $($process.Id) ($($process.ProcessName)) tué."
                    }
                    catch {
                        Write-Warning "Erreur lors de l'arrêt du processus $($process.Id): $_"
                    }
                }
                else {
                    Write-Host "WhatIf: Le processus $($process.Id) ($($process.ProcessName)) serait tué: $reason"
                }
            }
        }
        
        # Mettre à jour l'heure du dernier nettoyage
        $pattern.LastCleanupTime = Get-Date
    }
    
    return $killedProcesses
}

# Fonction pour démarrer la surveillance des processus
function Start-ProcessMonitoring {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$IntervalMinutes = 5
    )
    
    # Arrêter la surveillance existante
    if ($null -ne $script:MonitoringTimer) {
        Stop-ProcessMonitoring
    }
    
    # Vérifier s'il y a des modèles de processus à surveiller
    if ($script:ProcessPatterns.Count -eq 0) {
        Write-Warning "Aucun modèle de processus enregistré. Utilisez Register-ProcessPattern pour ajouter des modèles."
        return $false
    }
    
    # Créer le callback du timer
    $timerCallback = {
        param($state)
        
        Write-Verbose "Exécution du nettoyage des processus orphelins..."
        
        try {
            $killedProcesses = Clear-OrphanProcesses
            
            if ($killedProcesses.Count -gt 0) {
                Write-Verbose "$($killedProcesses.Count) processus orphelins nettoyés."
            }
            else {
                Write-Verbose "Aucun processus orphelin trouvé."
            }
        }
        catch {
            Write-Warning "Erreur lors du nettoyage des processus orphelins: $_"
        }
    }
    
    # Créer le timer
    $script:MonitoringTimer = New-Object System.Threading.Timer(
        $timerCallback,
        $null,
        0,
        ($IntervalMinutes * 60 * 1000)
    )
    
    Write-Verbose "Surveillance des processus démarrée avec un intervalle de $IntervalMinutes minutes."
    return $true
}

# Fonction pour arrêter la surveillance des processus
function Stop-ProcessMonitoring {
    [CmdletBinding()]
    param ()
    
    if ($null -ne $script:MonitoringTimer) {
        $script:MonitoringTimer.Dispose()
        $script:MonitoringTimer = $null
        
        Write-Verbose "Surveillance des processus arrêtée."
        return $true
    }
    else {
        Write-Warning "La surveillance des processus n'est pas active."
        return $false
    }
}

# Fonction pour vérifier si un processus est orphelin
function Test-OrphanProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [int]$Id,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByProcess")]
        [System.Diagnostics.Process]$Process
    )
    
    # Obtenir le processus si l'ID est spécifié
    if ($PSCmdlet.ParameterSetName -eq "ById") {
        try {
            $Process = Get-Process -Id $Id -ErrorAction Stop
        }
        catch {
            Write-Error "Processus avec l'ID $Id non trouvé: $_"
            return $null
        }
    }
    
    # Vérifier si le processus existe
    if ($null -eq $Process) {
        Write-Error "Processus non valide."
        return $null
    }
    
    # Trouver un modèle correspondant
    $pattern = $script:ProcessPatterns | Where-Object { $_.Name -eq $Process.ProcessName } | Select-Object -First 1
    
    if ($null -eq $pattern) {
        Write-Verbose "Aucun modèle de processus trouvé pour '$($Process.ProcessName)'."
        return [PSCustomObject]@{
            IsOrphan = $false
            Process = $Process
            Reason = "Aucun modèle de processus correspondant"
        }
    }
    
    # Vérifier si le processus est orphelin
    $isOrphan = $false
    $reason = ""
    
    # Vérifier la durée de vie
    if ($pattern.MaxLifetimeMinutes -gt 0) {
        $lifetime = (Get-Date) - $Process.StartTime
        if ($lifetime.TotalMinutes -gt $pattern.MaxLifetimeMinutes) {
            $isOrphan = $true
            $reason = "Durée de vie dépassée ($($lifetime.TotalMinutes.ToString('F2')) minutes > $($pattern.MaxLifetimeMinutes) minutes)"
        }
    }
    
    # Vérifier l'utilisation de la mémoire
    if (-not $isOrphan -and $pattern.MaxMemoryMB -gt 0) {
        $memoryMB = $Process.WorkingSet64 / 1MB
        if ($memoryMB -gt $pattern.MaxMemoryMB) {
            $isOrphan = $true
            $reason = "Utilisation de la mémoire dépassée ($($memoryMB.ToString('F2')) MB > $($pattern.MaxMemoryMB) MB)"
        }
    }
    
    # Vérifier l'utilisation du CPU
    if (-not $isOrphan -and $pattern.MaxCPUPercent -gt 0) {
        # Obtenir l'utilisation du CPU (nécessite plusieurs mesures)
        $cpuCounter = New-Object System.Diagnostics.PerformanceCounter("Process", "% Processor Time", $Process.ProcessName, $true)
        $cpuCounter.NextValue() | Out-Null
        Start-Sleep -Milliseconds 100
        $cpuPercent = $cpuCounter.NextValue() / [System.Environment]::ProcessorCount
        
        if ($cpuPercent -gt $pattern.MaxCPUPercent) {
            $isOrphan = $true
            $reason = "Utilisation du CPU dépassée ($($cpuPercent.ToString('F2'))% > $($pattern.MaxCPUPercent)%)"
        }
    }
    
    # Vérifier la ligne de commande
    if (-not $isOrphan -and -not [string]::IsNullOrEmpty($pattern.CommandLinePattern)) {
        try {
            $commandLine = (Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($Process.Id)").CommandLine
            if ($commandLine -match $pattern.CommandLinePattern) {
                $isOrphan = $true
                $reason = "Ligne de commande correspondant au modèle '$($pattern.CommandLinePattern)'"
            }
        }
        catch {
            Write-Warning "Erreur lors de l'obtention de la ligne de commande pour le processus $($Process.Id): $_"
        }
    }
    
    # Vérifier la condition personnalisée
    if (-not $isOrphan -and $null -ne $pattern.CustomCondition) {
        try {
            $isOrphan = & $pattern.CustomCondition -Process $Process
            if ($isOrphan) {
                $reason = "Condition personnalisée satisfaite"
            }
        }
        catch {
            Write-Warning "Erreur lors de l'évaluation de la condition personnalisée pour le processus $($Process.Id): $_"
        }
    }
    
    return [PSCustomObject]@{
        IsOrphan = $isOrphan
        Process = $Process
        Reason = $reason
    }
}

# Fonction pour obtenir tous les processus orphelins
function Get-OrphanProcesses {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Name = ""
    )
    
    $orphanProcesses = @()
    
    # Filtrer les modèles de processus
    $patterns = if ([string]::IsNullOrEmpty($Name)) {
        $script:ProcessPatterns
    }
    else {
        $script:ProcessPatterns | Where-Object { $_.Name -eq $Name }
    }
    
    if ($patterns.Count -eq 0) {
        Write-Warning "Aucun modèle de processus trouvé."
        return $orphanProcesses
    }
    
    # Traiter chaque modèle
    foreach ($pattern in $patterns) {
        Write-Verbose "Traitement du modèle '$($pattern.Name)'..."
        
        # Obtenir les processus correspondant au modèle
        $processes = Get-Process -Name $pattern.Name -ErrorAction SilentlyContinue
        
        if ($null -eq $processes -or $processes.Count -eq 0) {
            Write-Verbose "Aucun processus trouvé pour le modèle '$($pattern.Name)'."
            continue
        }
        
        # Vérifier chaque processus
        foreach ($process in $processes) {
            $result = Test-OrphanProcess -Process $process
            
            if ($result.IsOrphan) {
                $orphanProcesses += [PSCustomObject]@{
                    Id = $process.Id
                    Name = $process.ProcessName
                    StartTime = $process.StartTime
                    Reason = $result.Reason
                }
            }
        }
    }
    
    return $orphanProcesses
}

# Exporter les fonctions
Export-ModuleMember -Function Register-ProcessPattern, Unregister-ProcessPattern, Get-ProcessPatterns, Clear-OrphanProcesses, Start-ProcessMonitoring, Stop-ProcessMonitoring, Test-OrphanProcess, Get-OrphanProcesses

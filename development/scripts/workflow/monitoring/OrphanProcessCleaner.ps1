<#
.SYNOPSIS
    Nettoie les processus orphelins laissÃ©s par des scripts ou applications.

.DESCRIPTION
    Ce script identifie et nettoie les processus orphelins qui peuvent Ãªtre laissÃ©s
    lorsque des scripts ou applications se terminent de maniÃ¨re inattendue. Il peut
    Ãªtre configurÃ© pour surveiller des processus spÃ©cifiques ou des modÃ¨les de noms.

.EXAMPLE
    . .\OrphanProcessCleaner.ps1
    Register-ProcessPattern -Name "chrome" -MaxLifetimeMinutes 60
    Start-ProcessMonitoring

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

# Liste des modÃ¨les de processus Ã  surveiller
$script:ProcessPatterns = [System.Collections.Generic.List[PSCustomObject]]::new()

# Timer pour la surveillance des processus
$script:MonitoringTimer = $null

# Fonction pour enregistrer un modÃ¨le de processus Ã  surveiller
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
    
    # VÃ©rifier si le modÃ¨le existe dÃ©jÃ 
    $existingPattern = $script:ProcessPatterns | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    
    if ($null -ne $existingPattern) {
        if ($Force) {
            # Supprimer le modÃ¨le existant
            $script:ProcessPatterns.Remove($existingPattern)
        }
        else {
            Write-Error "Un modÃ¨le de processus avec le nom '$Name' existe dÃ©jÃ . Utilisez -Force pour le remplacer."
            return
        }
    }
    
    # CrÃ©er le modÃ¨le de processus
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
    
    # Ajouter le modÃ¨le Ã  la liste
    $script:ProcessPatterns.Add($pattern)
    
    Write-Verbose "ModÃ¨le de processus '$Name' enregistrÃ©."
}

# Fonction pour supprimer un modÃ¨le de processus
function Unregister-ProcessPattern {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    # Trouver le modÃ¨le
    $pattern = $script:ProcessPatterns | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    
    if ($null -eq $pattern) {
        Write-Error "ModÃ¨le de processus '$Name' non trouvÃ©."
        return $false
    }
    
    # Supprimer le modÃ¨le
    $script:ProcessPatterns.Remove($pattern)
    
    Write-Verbose "ModÃ¨le de processus '$Name' supprimÃ©."
    return $true
}

# Fonction pour obtenir la liste des modÃ¨les de processus
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
    
    # Filtrer les modÃ¨les de processus
    $patterns = if ([string]::IsNullOrEmpty($Name)) {
        $script:ProcessPatterns
    }
    else {
        $script:ProcessPatterns | Where-Object { $_.Name -eq $Name }
    }
    
    if ($patterns.Count -eq 0) {
        Write-Warning "Aucun modÃ¨le de processus trouvÃ©."
        return $killedProcesses
    }
    
    # Traiter chaque modÃ¨le
    foreach ($pattern in $patterns) {
        Write-Verbose "Traitement du modÃ¨le '$($pattern.Name)'..."
        
        # Obtenir les processus correspondant au modÃ¨le
        $processes = Get-Process -Name $pattern.Name -ErrorAction SilentlyContinue
        
        if ($null -eq $processes -or $processes.Count -eq 0) {
            Write-Verbose "Aucun processus trouvÃ© pour le modÃ¨le '$($pattern.Name)'."
            continue
        }
        
        # Filtrer les processus en fonction des critÃ¨res
        foreach ($process in $processes) {
            $shouldKill = $false
            $reason = ""
            
            # VÃ©rifier la durÃ©e de vie
            if ($pattern.MaxLifetimeMinutes -gt 0) {
                $lifetime = (Get-Date) - $process.StartTime
                if ($lifetime.TotalMinutes -gt $pattern.MaxLifetimeMinutes) {
                    $shouldKill = $true
                    $reason = "DurÃ©e de vie dÃ©passÃ©e ($($lifetime.TotalMinutes.ToString('F2')) minutes > $($pattern.MaxLifetimeMinutes) minutes)"
                }
            }
            
            # VÃ©rifier l'utilisation de la mÃ©moire
            if (-not $shouldKill -and $pattern.MaxMemoryMB -gt 0) {
                $memoryMB = $process.WorkingSet64 / 1MB
                if ($memoryMB -gt $pattern.MaxMemoryMB) {
                    $shouldKill = $true
                    $reason = "Utilisation de la mÃ©moire dÃ©passÃ©e ($($memoryMB.ToString('F2')) MB > $($pattern.MaxMemoryMB) MB)"
                }
            }
            
            # VÃ©rifier l'utilisation du CPU
            if (-not $shouldKill -and $pattern.MaxCPUPercent -gt 0) {
                # Obtenir l'utilisation du CPU (nÃ©cessite plusieurs mesures)
                $cpuCounter = New-Object System.Diagnostics.PerformanceCounter("Process", "% Processor Time", $process.ProcessName, $true)
                $cpuCounter.NextValue() | Out-Null
                Start-Sleep -Milliseconds 100
                $cpuPercent = $cpuCounter.NextValue() / [System.Environment]::ProcessorCount
                
                if ($cpuPercent -gt $pattern.MaxCPUPercent) {
                    $shouldKill = $true
                    $reason = "Utilisation du CPU dÃ©passÃ©e ($($cpuPercent.ToString('F2'))% > $($pattern.MaxCPUPercent)%)"
                }
            }
            
            # VÃ©rifier la ligne de commande
            if (-not $shouldKill -and -not [string]::IsNullOrEmpty($pattern.CommandLinePattern)) {
                try {
                    $commandLine = (Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($process.Id)").CommandLine
                    if ($commandLine -match $pattern.CommandLinePattern) {
                        $shouldKill = $true
                        $reason = "Ligne de commande correspondant au modÃ¨le '$($pattern.CommandLinePattern)'"
                    }
                }
                catch {
                    Write-Warning "Erreur lors de l'obtention de la ligne de commande pour le processus $($process.Id): $_"
                }
            }
            
            # VÃ©rifier la condition personnalisÃ©e
            if (-not $shouldKill -and $null -ne $pattern.CustomCondition) {
                try {
                    $shouldKill = & $pattern.CustomCondition -Process $process
                    if ($shouldKill) {
                        $reason = "Condition personnalisÃ©e satisfaite"
                    }
                }
                catch {
                    Write-Warning "Erreur lors de l'Ã©valuation de la condition personnalisÃ©e pour le processus $($process.Id): $_"
                }
            }
            
            # Tuer le processus si nÃ©cessaire
            if ($shouldKill) {
                Write-Verbose "Processus $($process.Id) ($($process.ProcessName)) identifiÃ© comme orphelin: $reason"
                
                if (-not $WhatIf) {
                    try {
                        # ExÃ©cuter le script BeforeKill
                        if ($null -ne $pattern.BeforeKill) {
                            try {
                                & $pattern.BeforeKill -Process $process
                            }
                            catch {
                                Write-Warning "Erreur lors de l'exÃ©cution du script BeforeKill pour le processus $($process.Id): $_"
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
                        
                        Write-Verbose "Processus $($process.Id) ($($process.ProcessName)) tuÃ©."
                    }
                    catch {
                        Write-Warning "Erreur lors de l'arrÃªt du processus $($process.Id): $_"
                    }
                }
                else {
                    Write-Host "WhatIf: Le processus $($process.Id) ($($process.ProcessName)) serait tuÃ©: $reason"
                }
            }
        }
        
        # Mettre Ã  jour l'heure du dernier nettoyage
        $pattern.LastCleanupTime = Get-Date
    }
    
    return $killedProcesses
}

# Fonction pour dÃ©marrer la surveillance des processus
function Start-ProcessMonitoring {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$IntervalMinutes = 5
    )
    
    # ArrÃªter la surveillance existante
    if ($null -ne $script:MonitoringTimer) {
        Stop-ProcessMonitoring
    }
    
    # VÃ©rifier s'il y a des modÃ¨les de processus Ã  surveiller
    if ($script:ProcessPatterns.Count -eq 0) {
        Write-Warning "Aucun modÃ¨le de processus enregistrÃ©. Utilisez Register-ProcessPattern pour ajouter des modÃ¨les."
        return $false
    }
    
    # CrÃ©er le callback du timer
    $timerCallback = {
        param($state)
        
        Write-Verbose "ExÃ©cution du nettoyage des processus orphelins..."
        
        try {
            $killedProcesses = Clear-OrphanProcesses
            
            if ($killedProcesses.Count -gt 0) {
                Write-Verbose "$($killedProcesses.Count) processus orphelins nettoyÃ©s."
            }
            else {
                Write-Verbose "Aucun processus orphelin trouvÃ©."
            }
        }
        catch {
            Write-Warning "Erreur lors du nettoyage des processus orphelins: $_"
        }
    }
    
    # CrÃ©er le timer
    $script:MonitoringTimer = New-Object System.Threading.Timer(
        $timerCallback,
        $null,
        0,
        ($IntervalMinutes * 60 * 1000)
    )
    
    Write-Verbose "Surveillance des processus dÃ©marrÃ©e avec un intervalle de $IntervalMinutes minutes."
    return $true
}

# Fonction pour arrÃªter la surveillance des processus
function Stop-ProcessMonitoring {
    [CmdletBinding()]
    param ()
    
    if ($null -ne $script:MonitoringTimer) {
        $script:MonitoringTimer.Dispose()
        $script:MonitoringTimer = $null
        
        Write-Verbose "Surveillance des processus arrÃªtÃ©e."
        return $true
    }
    else {
        Write-Warning "La surveillance des processus n'est pas active."
        return $false
    }
}

# Fonction pour vÃ©rifier si un processus est orphelin
function Test-OrphanProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [int]$Id,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByProcess")]
        [System.Diagnostics.Process]$Process
    )
    
    # Obtenir le processus si l'ID est spÃ©cifiÃ©
    if ($PSCmdlet.ParameterSetName -eq "ById") {
        try {
            $Process = Get-Process -Id $Id -ErrorAction Stop
        }
        catch {
            Write-Error "Processus avec l'ID $Id non trouvÃ©: $_"
            return $null
        }
    }
    
    # VÃ©rifier si le processus existe
    if ($null -eq $Process) {
        Write-Error "Processus non valide."
        return $null
    }
    
    # Trouver un modÃ¨le correspondant
    $pattern = $script:ProcessPatterns | Where-Object { $_.Name -eq $Process.ProcessName } | Select-Object -First 1
    
    if ($null -eq $pattern) {
        Write-Verbose "Aucun modÃ¨le de processus trouvÃ© pour '$($Process.ProcessName)'."
        return [PSCustomObject]@{
            IsOrphan = $false
            Process = $Process
            Reason = "Aucun modÃ¨le de processus correspondant"
        }
    }
    
    # VÃ©rifier si le processus est orphelin
    $isOrphan = $false
    $reason = ""
    
    # VÃ©rifier la durÃ©e de vie
    if ($pattern.MaxLifetimeMinutes -gt 0) {
        $lifetime = (Get-Date) - $Process.StartTime
        if ($lifetime.TotalMinutes -gt $pattern.MaxLifetimeMinutes) {
            $isOrphan = $true
            $reason = "DurÃ©e de vie dÃ©passÃ©e ($($lifetime.TotalMinutes.ToString('F2')) minutes > $($pattern.MaxLifetimeMinutes) minutes)"
        }
    }
    
    # VÃ©rifier l'utilisation de la mÃ©moire
    if (-not $isOrphan -and $pattern.MaxMemoryMB -gt 0) {
        $memoryMB = $Process.WorkingSet64 / 1MB
        if ($memoryMB -gt $pattern.MaxMemoryMB) {
            $isOrphan = $true
            $reason = "Utilisation de la mÃ©moire dÃ©passÃ©e ($($memoryMB.ToString('F2')) MB > $($pattern.MaxMemoryMB) MB)"
        }
    }
    
    # VÃ©rifier l'utilisation du CPU
    if (-not $isOrphan -and $pattern.MaxCPUPercent -gt 0) {
        # Obtenir l'utilisation du CPU (nÃ©cessite plusieurs mesures)
        $cpuCounter = New-Object System.Diagnostics.PerformanceCounter("Process", "% Processor Time", $Process.ProcessName, $true)
        $cpuCounter.NextValue() | Out-Null
        Start-Sleep -Milliseconds 100
        $cpuPercent = $cpuCounter.NextValue() / [System.Environment]::ProcessorCount
        
        if ($cpuPercent -gt $pattern.MaxCPUPercent) {
            $isOrphan = $true
            $reason = "Utilisation du CPU dÃ©passÃ©e ($($cpuPercent.ToString('F2'))% > $($pattern.MaxCPUPercent)%)"
        }
    }
    
    # VÃ©rifier la ligne de commande
    if (-not $isOrphan -and -not [string]::IsNullOrEmpty($pattern.CommandLinePattern)) {
        try {
            $commandLine = (Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($Process.Id)").CommandLine
            if ($commandLine -match $pattern.CommandLinePattern) {
                $isOrphan = $true
                $reason = "Ligne de commande correspondant au modÃ¨le '$($pattern.CommandLinePattern)'"
            }
        }
        catch {
            Write-Warning "Erreur lors de l'obtention de la ligne de commande pour le processus $($Process.Id): $_"
        }
    }
    
    # VÃ©rifier la condition personnalisÃ©e
    if (-not $isOrphan -and $null -ne $pattern.CustomCondition) {
        try {
            $isOrphan = & $pattern.CustomCondition -Process $Process
            if ($isOrphan) {
                $reason = "Condition personnalisÃ©e satisfaite"
            }
        }
        catch {
            Write-Warning "Erreur lors de l'Ã©valuation de la condition personnalisÃ©e pour le processus $($Process.Id): $_"
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
    
    # Filtrer les modÃ¨les de processus
    $patterns = if ([string]::IsNullOrEmpty($Name)) {
        $script:ProcessPatterns
    }
    else {
        $script:ProcessPatterns | Where-Object { $_.Name -eq $Name }
    }
    
    if ($patterns.Count -eq 0) {
        Write-Warning "Aucun modÃ¨le de processus trouvÃ©."
        return $orphanProcesses
    }
    
    # Traiter chaque modÃ¨le
    foreach ($pattern in $patterns) {
        Write-Verbose "Traitement du modÃ¨le '$($pattern.Name)'..."
        
        # Obtenir les processus correspondant au modÃ¨le
        $processes = Get-Process -Name $pattern.Name -ErrorAction SilentlyContinue
        
        if ($null -eq $processes -or $processes.Count -eq 0) {
            Write-Verbose "Aucun processus trouvÃ© pour le modÃ¨le '$($pattern.Name)'."
            continue
        }
        
        # VÃ©rifier chaque processus
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

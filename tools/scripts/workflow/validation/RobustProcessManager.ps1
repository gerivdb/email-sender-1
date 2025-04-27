<#
.SYNOPSIS
    Gestionnaire de processus robuste pour PowerShell.

.DESCRIPTION
    Ce script fournit des fonctions pour gÃ©rer les processus de maniÃ¨re robuste,
    avec des fonctionnalitÃ©s de surveillance, de redÃ©marrage automatique, et de
    gestion des erreurs.

.EXAMPLE
    . .\RobustProcessManager.ps1
    $process = Start-ManagedProcess -FilePath "notepad.exe" -MonitorHealth -RestartOnCrash

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

# Classe pour stocker les informations sur un processus gÃ©rÃ©
class ManagedProcess {
    [int]$Id
    [string]$Name
    [string]$FilePath
    [string[]]$Arguments
    [System.Diagnostics.Process]$Process
    [bool]$IsRunning
    [bool]$MonitorHealth
    [bool]$RestartOnCrash
    [int]$RestartCount
    [int]$MaxRestarts
    [int]$RestartDelaySeconds
    [scriptblock]$OnStart
    [scriptblock]$OnExit
    [scriptblock]$OnCrash
    [scriptblock]$HealthCheck
    [int]$HealthCheckIntervalSeconds
    [System.Threading.Timer]$HealthCheckTimer
    [System.Collections.Generic.List[string]]$OutputLog
    [System.Collections.Generic.List[string]]$ErrorLog
    [System.IO.StreamReader]$OutputReader
    [System.IO.StreamReader]$ErrorReader
    [bool]$RedirectOutput
    [string]$OutputFile
    [string]$ErrorFile
    [System.Threading.CancellationTokenSource]$CancellationTokenSource
    [datetime]$StartTime
    [datetime]$LastRestartTime
    [PSCustomObject]$Metadata

    ManagedProcess() {
        $this.Id = -1
        $this.IsRunning = $false
        $this.RestartCount = 0
        $this.MaxRestarts = 3
        $this.RestartDelaySeconds = 5
        $this.HealthCheckIntervalSeconds = 30
        $this.OutputLog = [System.Collections.Generic.List[string]]::new()
        $this.ErrorLog = [System.Collections.Generic.List[string]]::new()
        $this.RedirectOutput = $true
        $this.CancellationTokenSource = [System.Threading.CancellationTokenSource]::new()
        $this.Metadata = [PSCustomObject]@{}
    }
}

# Liste des processus gÃ©rÃ©s
$script:ManagedProcesses = [System.Collections.Generic.List[ManagedProcess]]::new()

# Fonction pour dÃ©marrer un processus gÃ©rÃ©
function Start-ManagedProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$MonitorHealth,
        
        [Parameter(Mandatory = $false)]
        [switch]$RestartOnCrash,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxRestarts = 3,
        
        [Parameter(Mandatory = $false)]
        [int]$RestartDelaySeconds = 5,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$OnStart = {},
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$OnExit = {},
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$OnCrash = {},
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$HealthCheck = { param($process) $process.Process.HasExited -eq $false },
        
        [Parameter(Mandatory = $false)]
        [int]$HealthCheckIntervalSeconds = 30,
        
        [Parameter(Mandatory = $false)]
        [switch]$RedirectOutput,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFile = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorFile = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$EnvironmentVariables = @{},
        
        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Metadata = $null
    )
    
    # CrÃ©er un nouvel objet de processus gÃ©rÃ©
    $managedProcess = [ManagedProcess]::new()
    $managedProcess.FilePath = $FilePath
    $managedProcess.Arguments = $Arguments
    $managedProcess.MonitorHealth = $MonitorHealth
    $managedProcess.RestartOnCrash = $RestartOnCrash
    $managedProcess.MaxRestarts = $MaxRestarts
    $managedProcess.RestartDelaySeconds = $RestartDelaySeconds
    $managedProcess.OnStart = $OnStart
    $managedProcess.OnExit = $OnExit
    $managedProcess.OnCrash = $OnCrash
    $managedProcess.HealthCheck = $HealthCheck
    $managedProcess.HealthCheckIntervalSeconds = $HealthCheckIntervalSeconds
    $managedProcess.RedirectOutput = $RedirectOutput
    $managedProcess.OutputFile = $OutputFile
    $managedProcess.ErrorFile = $ErrorFile
    $managedProcess.Metadata = if ($null -ne $Metadata) { $Metadata } else { [PSCustomObject]@{} }
    
    # CrÃ©er un objet Process
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $FilePath
    $process.StartInfo.Arguments = $Arguments -join " "
    
    if (-not [string]::IsNullOrEmpty($WorkingDirectory)) {
        $process.StartInfo.WorkingDirectory = $WorkingDirectory
    }
    
    # Configurer la redirection de sortie si demandÃ©
    if ($RedirectOutput) {
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
        $process.StartInfo.CreateNoWindow = $true
    }
    
    # Ajouter des variables d'environnement si spÃ©cifiÃ©es
    if ($EnvironmentVariables.Count -gt 0) {
        $process.StartInfo.UseShellExecute = $false
        
        foreach ($key in $EnvironmentVariables.Keys) {
            $process.StartInfo.EnvironmentVariables[$key] = $EnvironmentVariables[$key]
        }
    }
    
    # Configurer les gestionnaires d'Ã©vÃ©nements
    $process.EnableRaisingEvents = $true
    
    # Gestionnaire d'Ã©vÃ©nement pour la sortie standard
    if ($RedirectOutput) {
        $outputHandler = {
            param($sender, $e)
            $line = $e.Data
            if (-not [string]::IsNullOrEmpty($line)) {
                $managedProcess.OutputLog.Add($line)
                
                if (-not [string]::IsNullOrEmpty($managedProcess.OutputFile)) {
                    Add-Content -Path $managedProcess.OutputFile -Value $line
                }
            }
        }
        
        $process.OutputDataReceived += $outputHandler
    }
    
    # Gestionnaire d'Ã©vÃ©nement pour la sortie d'erreur
    if ($RedirectOutput) {
        $errorHandler = {
            param($sender, $e)
            $line = $e.Data
            if (-not [string]::IsNullOrEmpty($line)) {
                $managedProcess.ErrorLog.Add($line)
                
                if (-not [string]::IsNullOrEmpty($managedProcess.ErrorFile)) {
                    Add-Content -Path $managedProcess.ErrorFile -Value $line
                }
            }
        }
        
        $process.ErrorDataReceived += $errorHandler
    }
    
    # Gestionnaire d'Ã©vÃ©nement pour la sortie du processus
    $exitHandler = {
        param($sender, $e)
        $proc = [System.Diagnostics.Process]$sender
        $managedProcess.IsRunning = $false
        
        # ExÃ©cuter le script OnExit
        if ($null -ne $managedProcess.OnExit) {
            try {
                & $managedProcess.OnExit -Process $managedProcess
            }
            catch {
                Write-Warning "Erreur lors de l'exÃ©cution du script OnExit: $_"
            }
        }
        
        # VÃ©rifier si le processus s'est arrÃªtÃ© de maniÃ¨re inattendue
        $crashed = $proc.ExitCode -ne 0
        
        if ($crashed) {
            # ExÃ©cuter le script OnCrash
            if ($null -ne $managedProcess.OnCrash) {
                try {
                    & $managedProcess.OnCrash -Process $managedProcess
                }
                catch {
                    Write-Warning "Erreur lors de l'exÃ©cution du script OnCrash: $_"
                }
            }
            
            # RedÃ©marrer le processus si demandÃ©
            if ($managedProcess.RestartOnCrash -and $managedProcess.RestartCount -lt $managedProcess.MaxRestarts) {
                $managedProcess.RestartCount++
                $managedProcess.LastRestartTime = Get-Date
                
                Write-Warning "Le processus $($managedProcess.Name) (ID: $($managedProcess.Id)) s'est arrÃªtÃ© de maniÃ¨re inattendue. RedÃ©marrage dans $($managedProcess.RestartDelaySeconds) secondes... (Tentative $($managedProcess.RestartCount)/$($managedProcess.MaxRestarts))"
                
                Start-Sleep -Seconds $managedProcess.RestartDelaySeconds
                
                # RedÃ©marrer le processus
                $restartArgs = @{
                    FilePath = $managedProcess.FilePath
                    Arguments = $managedProcess.Arguments
                    MonitorHealth = $managedProcess.MonitorHealth
                    RestartOnCrash = $managedProcess.RestartOnCrash
                    MaxRestarts = $managedProcess.MaxRestarts
                    RestartDelaySeconds = $managedProcess.RestartDelaySeconds
                    OnStart = $managedProcess.OnStart
                    OnExit = $managedProcess.OnExit
                    OnCrash = $managedProcess.OnCrash
                    HealthCheck = $managedProcess.HealthCheck
                    HealthCheckIntervalSeconds = $managedProcess.HealthCheckIntervalSeconds
                    RedirectOutput = $managedProcess.RedirectOutput
                    OutputFile = $managedProcess.OutputFile
                    ErrorFile = $managedProcess.ErrorFile
                    Metadata = $managedProcess.Metadata
                }
                
                if (-not [string]::IsNullOrEmpty($WorkingDirectory)) {
                    $restartArgs.WorkingDirectory = $WorkingDirectory
                }
                
                if ($EnvironmentVariables.Count -gt 0) {
                    $restartArgs.EnvironmentVariables = $EnvironmentVariables
                }
                
                Start-ManagedProcess @restartArgs
            }
            else {
                Write-Warning "Le processus $($managedProcess.Name) (ID: $($managedProcess.Id)) s'est arrÃªtÃ© de maniÃ¨re inattendue et ne sera pas redÃ©marrÃ©."
            }
        }
    }
    
    $process.Exited += $exitHandler
    
    # DÃ©marrer le processus
    try {
        $started = $process.Start()
        
        if (-not $started) {
            Write-Error "Impossible de dÃ©marrer le processus $FilePath"
            return $null
        }
        
        # DÃ©marrer la lecture de la sortie si la redirection est activÃ©e
        if ($RedirectOutput) {
            $process.BeginOutputReadLine()
            $process.BeginErrorReadLine()
        }
        
        # Mettre Ã  jour les propriÃ©tÃ©s du processus gÃ©rÃ©
        $managedProcess.Process = $process
        $managedProcess.Id = $process.Id
        $managedProcess.Name = $process.ProcessName
        $managedProcess.IsRunning = $true
        $managedProcess.StartTime = Get-Date
        
        # ExÃ©cuter le script OnStart
        if ($null -ne $OnStart) {
            try {
                & $OnStart -Process $managedProcess
            }
            catch {
                Write-Warning "Erreur lors de l'exÃ©cution du script OnStart: $_"
            }
        }
        
        # Configurer la surveillance de la santÃ© si demandÃ©
        if ($MonitorHealth) {
            $healthCheckCallback = {
                param($state)
                
                $mp = [ManagedProcess]$state
                
                if ($mp.IsRunning) {
                    try {
                        $isHealthy = & $mp.HealthCheck -Process $mp
                        
                        if (-not $isHealthy) {
                            Write-Warning "Le processus $($mp.Name) (ID: $($mp.Id)) n'est pas en bonne santÃ©. Tentative de redÃ©marrage..."
                            
                            # ArrÃªter le processus
                            Stop-ManagedProcess -Id $mp.Id -Force
                            
                            # RedÃ©marrer le processus si demandÃ©
                            if ($mp.RestartOnCrash -and $mp.RestartCount -lt $mp.MaxRestarts) {
                                $mp.RestartCount++
                                $mp.LastRestartTime = Get-Date
                                
                                Start-Sleep -Seconds $mp.RestartDelaySeconds
                                
                                # RedÃ©marrer le processus
                                $restartArgs = @{
                                    FilePath = $mp.FilePath
                                    Arguments = $mp.Arguments
                                    MonitorHealth = $mp.MonitorHealth
                                    RestartOnCrash = $mp.RestartOnCrash
                                    MaxRestarts = $mp.MaxRestarts
                                    RestartDelaySeconds = $mp.RestartDelaySeconds
                                    OnStart = $mp.OnStart
                                    OnExit = $mp.OnExit
                                    OnCrash = $mp.OnCrash
                                    HealthCheck = $mp.HealthCheck
                                    HealthCheckIntervalSeconds = $mp.HealthCheckIntervalSeconds
                                    RedirectOutput = $mp.RedirectOutput
                                    OutputFile = $mp.OutputFile
                                    ErrorFile = $mp.ErrorFile
                                    Metadata = $mp.Metadata
                                }
                                
                                Start-ManagedProcess @restartArgs
                            }
                        }
                    }
                    catch {
                        Write-Warning "Erreur lors de la vÃ©rification de la santÃ© du processus $($mp.Name) (ID: $($mp.Id)): $_"
                    }
                }
            }
            
            # CrÃ©er un timer pour la vÃ©rification de la santÃ©
            $timer = New-Object System.Threading.Timer(
                $healthCheckCallback,
                $managedProcess,
                ($HealthCheckIntervalSeconds * 1000),
                ($HealthCheckIntervalSeconds * 1000)
            )
            
            $managedProcess.HealthCheckTimer = $timer
        }
        
        # Ajouter le processus Ã  la liste des processus gÃ©rÃ©s
        $script:ManagedProcesses.Add($managedProcess)
        
        return $managedProcess
    }
    catch {
        Write-Error "Erreur lors du dÃ©marrage du processus $FilePath : $_"
        return $null
    }
}

# Fonction pour arrÃªter un processus gÃ©rÃ©
function Stop-ManagedProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [int]$Id,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 10
    )
    
    # Trouver le processus gÃ©rÃ©
    $managedProcess = if ($PSCmdlet.ParameterSetName -eq "ById") {
        $script:ManagedProcesses | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
    }
    else {
        $script:ManagedProcesses | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    }
    
    if ($null -eq $managedProcess) {
        Write-Error "Processus gÃ©rÃ© non trouvÃ©."
        return $false
    }
    
    # ArrÃªter le timer de vÃ©rification de la santÃ©
    if ($null -ne $managedProcess.HealthCheckTimer) {
        $managedProcess.HealthCheckTimer.Dispose()
        $managedProcess.HealthCheckTimer = $null
    }
    
    # ArrÃªter le processus
    try {
        if (-not $managedProcess.Process.HasExited) {
            if ($Force) {
                $managedProcess.Process.Kill()
            }
            else {
                $managedProcess.Process.CloseMainWindow()
                
                # Attendre que le processus se termine
                if (-not $managedProcess.Process.WaitForExit($TimeoutSeconds * 1000)) {
                    Write-Warning "Le processus ne s'est pas arrÃªtÃ© dans le dÃ©lai imparti. Utilisation de Kill()."
                    $managedProcess.Process.Kill()
                }
            }
        }
        
        $managedProcess.IsRunning = $false
        
        # Supprimer le processus de la liste des processus gÃ©rÃ©s
        $script:ManagedProcesses.Remove($managedProcess)
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'arrÃªt du processus : $_"
        return $false
    }
}

# Fonction pour obtenir la liste des processus gÃ©rÃ©s
function Get-ManagedProcesses {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Running
    )
    
    if ($Running) {
        return $script:ManagedProcesses | Where-Object { $_.IsRunning }
    }
    else {
        return $script:ManagedProcesses
    }
}

# Fonction pour obtenir la sortie d'un processus gÃ©rÃ©
function Get-ManagedProcessOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [int]$Id,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Output", "Error", "Both")]
        [string]$Type = "Both",
        
        [Parameter(Mandatory = $false)]
        [int]$Tail = 0
    )
    
    # Trouver le processus gÃ©rÃ©
    $managedProcess = if ($PSCmdlet.ParameterSetName -eq "ById") {
        $script:ManagedProcesses | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
    }
    else {
        $script:ManagedProcesses | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    }
    
    if ($null -eq $managedProcess) {
        Write-Error "Processus gÃ©rÃ© non trouvÃ©."
        return $null
    }
    
    # Obtenir la sortie demandÃ©e
    $output = [PSCustomObject]@{
        ProcessId = $managedProcess.Id
        ProcessName = $managedProcess.Name
        StandardOutput = @()
        StandardError = @()
    }
    
    if ($Type -eq "Output" -or $Type -eq "Both") {
        if ($Tail -gt 0 -and $managedProcess.OutputLog.Count -gt $Tail) {
            $output.StandardOutput = $managedProcess.OutputLog | Select-Object -Last $Tail
        }
        else {
            $output.StandardOutput = $managedProcess.OutputLog
        }
    }
    
    if ($Type -eq "Error" -or $Type -eq "Both") {
        if ($Tail -gt 0 -and $managedProcess.ErrorLog.Count -gt $Tail) {
            $output.StandardError = $managedProcess.ErrorLog | Select-Object -Last $Tail
        }
        else {
            $output.StandardError = $managedProcess.ErrorLog
        }
    }
    
    return $output
}

# Fonction pour envoyer une entrÃ©e Ã  un processus gÃ©rÃ©
function Send-ManagedProcessInput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [int]$Id,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$Input
    )
    
    # Trouver le processus gÃ©rÃ©
    $managedProcess = if ($PSCmdlet.ParameterSetName -eq "ById") {
        $script:ManagedProcesses | Where-Object { $_.Id -eq $Id } | Select-Object -First 1
    }
    else {
        $script:ManagedProcesses | Where-Object { $_.Name -eq $Name } | Select-Object -First 1
    }
    
    if ($null -eq $managedProcess) {
        Write-Error "Processus gÃ©rÃ© non trouvÃ©."
        return $false
    }
    
    # VÃ©rifier si le processus est en cours d'exÃ©cution
    if (-not $managedProcess.IsRunning -or $managedProcess.Process.HasExited) {
        Write-Error "Le processus n'est pas en cours d'exÃ©cution."
        return $false
    }
    
    # VÃ©rifier si la redirection de sortie est activÃ©e
    if (-not $managedProcess.Process.StartInfo.RedirectStandardInput) {
        Write-Error "La redirection d'entrÃ©e n'est pas activÃ©e pour ce processus."
        return $false
    }
    
    # Envoyer l'entrÃ©e au processus
    try {
        $managedProcess.Process.StandardInput.WriteLine($Input)
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'envoi de l'entrÃ©e au processus : $_"
        return $false
    }
}

# Fonction pour nettoyer les ressources des processus gÃ©rÃ©s
function Clear-ManagedProcesses {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # ArrÃªter tous les processus gÃ©rÃ©s
    foreach ($process in $script:ManagedProcesses.ToArray()) {
        Stop-ManagedProcess -Id $process.Id -Force:$Force
    }
    
    # Vider la liste des processus gÃ©rÃ©s
    $script:ManagedProcesses.Clear()
}

# Exporter les fonctions
Export-ModuleMember -Function Start-ManagedProcess, Stop-ManagedProcess, Get-ManagedProcesses, Get-ManagedProcessOutput, Send-ManagedProcessInput, Clear-ManagedProcesses

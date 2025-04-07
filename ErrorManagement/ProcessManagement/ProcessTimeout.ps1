<#
.SYNOPSIS
    Implémente des timeouts systématiques pour les processus.

.DESCRIPTION
    Ce script fournit des fonctions pour exécuter des processus avec des timeouts,
    permettant d'arrêter automatiquement les processus qui prennent trop de temps.

.EXAMPLE
    . .\ProcessTimeout.ps1
    $result = Invoke-ProcessWithTimeout -FilePath "ping.exe" -Arguments @("localhost", "-n", "10") -TimeoutSeconds 2

.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 07/04/2025
    Version: 1.0
#>

# Fonction pour exécuter un processus avec un timeout
function Invoke-ProcessWithTimeout {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = "",
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoWindow,
        
        [Parameter(Mandatory = $false)]
        [switch]$CaptureOutput,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$EnvironmentVariables = @{},
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Continue", "Stop", "SilentlyContinue")]
        [string]$TimeoutAction = "Stop"
    )
    
    # Créer un objet Process
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $FilePath
    $process.StartInfo.Arguments = $Arguments -join " "
    
    if (-not [string]::IsNullOrEmpty($WorkingDirectory)) {
        $process.StartInfo.WorkingDirectory = $WorkingDirectory
    }
    
    # Configurer la fenêtre du processus
    if ($NoWindow) {
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    }
    
    # Configurer la capture de sortie
    if ($CaptureOutput) {
        $process.StartInfo.UseShellExecute = $false
        $process.StartInfo.RedirectStandardOutput = $true
        $process.StartInfo.RedirectStandardError = $true
    }
    
    # Ajouter des variables d'environnement si spécifiées
    if ($EnvironmentVariables.Count -gt 0) {
        $process.StartInfo.UseShellExecute = $false
        
        foreach ($key in $EnvironmentVariables.Keys) {
            $process.StartInfo.EnvironmentVariables[$key] = $EnvironmentVariables[$key]
        }
    }
    
    # Créer des listes pour stocker la sortie
    $outputLines = [System.Collections.Generic.List[string]]::new()
    $errorLines = [System.Collections.Generic.List[string]]::new()
    
    # Configurer les gestionnaires d'événements pour la sortie
    if ($CaptureOutput) {
        $outputHandler = {
            param($sender, $e)
            $line = $e.Data
            if (-not [string]::IsNullOrEmpty($line)) {
                $outputLines.Add($line)
            }
        }
        
        $errorHandler = {
            param($sender, $e)
            $line = $e.Data
            if (-not [string]::IsNullOrEmpty($line)) {
                $errorLines.Add($line)
            }
        }
        
        $process.OutputDataReceived += $outputHandler
        $process.ErrorDataReceived += $errorHandler
    }
    
    # Démarrer le processus
    $started = $process.Start()
    
    if (-not $started) {
        Write-Error "Impossible de démarrer le processus $FilePath"
        return $null
    }
    
    # Démarrer la lecture de la sortie si la capture est activée
    if ($CaptureOutput) {
        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()
    }
    
    # Attendre que le processus se termine ou que le timeout soit atteint
    $completed = $process.WaitForExit($TimeoutSeconds * 1000)
    
    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        Process = $process
        ExitCode = -1
        Output = $outputLines
        Error = $errorLines
        TimedOut = -not $completed
        ExecutionTime = [TimeSpan]::Zero
    }
    
    if ($completed) {
        # Le processus s'est terminé normalement
        $result.ExitCode = $process.ExitCode
        
        # Attendre que toute la sortie soit lue
        if ($CaptureOutput) {
            $process.WaitForExit()
        }
    }
    else {
        # Le processus a dépassé le timeout
        Write-Warning "Le processus $FilePath a dépassé le délai d'attente de $TimeoutSeconds secondes."
        
        # Arrêter le processus
        try {
            $process.Kill()
            $process.WaitForExit(5000) # Attendre 5 secondes que le processus se termine
        }
        catch {
            Write-Warning "Erreur lors de l'arrêt du processus : $_"
        }
        
        # Gérer l'action de timeout
        if ($TimeoutAction -eq "Stop") {
            throw "Le processus $FilePath a dépassé le délai d'attente de $TimeoutSeconds secondes."
        }
        elseif ($TimeoutAction -eq "Continue") {
            # Continuer l'exécution
        }
        elseif ($TimeoutAction -eq "SilentlyContinue") {
            # Continuer silencieusement
        }
    }
    
    # Calculer le temps d'exécution
    $result.ExecutionTime = $process.ExitTime - $process.StartTime
    
    return $result
}

# Fonction pour exécuter un script PowerShell avec un timeout
function Invoke-ScriptBlockWithTimeout {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30,
        
        [Parameter(Mandatory = $false)]
        [object[]]$ArgumentList = @(),
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Continue", "Stop", "SilentlyContinue")]
        [string]$TimeoutAction = "Stop"
    )
    
    # Créer un jeton d'annulation
    $cancellationTokenSource = New-Object System.Threading.CancellationTokenSource
    
    # Créer une tâche pour exécuter le script
    $task = [System.Threading.Tasks.Task]::Run({
        param($scriptBlock, $argumentList)
        
        # Exécuter le script avec les arguments
        & $scriptBlock @argumentList
    }, $cancellationTokenSource.Token)
    
    # Attendre que la tâche se termine ou que le timeout soit atteint
    $completed = $task.Wait($TimeoutSeconds * 1000)
    
    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        Completed = $completed
        TimedOut = -not $completed
        Result = $null
        Exception = $null
    }
    
    if ($completed) {
        # La tâche s'est terminée normalement
        if ($task.Status -eq [System.Threading.Tasks.TaskStatus]::RanToCompletion) {
            $result.Result = $task.Result
        }
        elseif ($task.Status -eq [System.Threading.Tasks.TaskStatus]::Faulted) {
            $result.Exception = $task.Exception.InnerException
        }
    }
    else {
        # La tâche a dépassé le timeout
        Write-Warning "L'exécution du script a dépassé le délai d'attente de $TimeoutSeconds secondes."
        
        # Annuler la tâche
        $cancellationTokenSource.Cancel()
        
        # Gérer l'action de timeout
        if ($TimeoutAction -eq "Stop") {
            throw "L'exécution du script a dépassé le délai d'attente de $TimeoutSeconds secondes."
        }
        elseif ($TimeoutAction -eq "Continue") {
            # Continuer l'exécution
        }
        elseif ($TimeoutAction -eq "SilentlyContinue") {
            # Continuer silencieusement
        }
    }
    
    # Libérer les ressources
    $cancellationTokenSource.Dispose()
    
    return $result
}

# Fonction pour exécuter une commande PowerShell avec un timeout
function Invoke-CommandWithTimeout {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Continue", "Stop", "SilentlyContinue")]
        [string]$TimeoutAction = "Stop"
    )
    
    # Convertir la commande en scriptblock
    $scriptBlock = [scriptblock]::Create($Command)
    
    # Exécuter le scriptblock avec timeout
    return Invoke-ScriptBlockWithTimeout -ScriptBlock $scriptBlock -TimeoutSeconds $TimeoutSeconds -TimeoutAction $TimeoutAction
}

# Fonction pour exécuter une commande en arrière-plan avec un timeout
function Start-BackgroundProcessWithTimeout {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Arguments = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$WorkingDirectory = "",
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 0,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoWindow,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$EnvironmentVariables = @{},
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$OnTimeout = {},
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$OnExit = {}
    )
    
    # Créer un objet Process
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo.FileName = $FilePath
    $process.StartInfo.Arguments = $Arguments -join " "
    
    if (-not [string]::IsNullOrEmpty($WorkingDirectory)) {
        $process.StartInfo.WorkingDirectory = $WorkingDirectory
    }
    
    # Configurer la fenêtre du processus
    if ($NoWindow) {
        $process.StartInfo.CreateNoWindow = $true
        $process.StartInfo.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Hidden
    }
    
    # Ajouter des variables d'environnement si spécifiées
    if ($EnvironmentVariables.Count -gt 0) {
        $process.StartInfo.UseShellExecute = $false
        
        foreach ($key in $EnvironmentVariables.Keys) {
            $process.StartInfo.EnvironmentVariables[$key] = $EnvironmentVariables[$key]
        }
    }
    
    # Démarrer le processus
    $started = $process.Start()
    
    if (-not $started) {
        Write-Error "Impossible de démarrer le processus $FilePath"
        return $null
    }
    
    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        Process = $process
        Id = $process.Id
        StartTime = $process.StartTime
        HasExited = $false
        ExitCode = $null
        TimedOut = $false
    }
    
    # Configurer le timeout si spécifié
    if ($TimeoutSeconds -gt 0) {
        $timer = $null
        
        $timerCallback = {
            param($state)
            
            $processInfo = [PSCustomObject]$state
            $process = $processInfo.Process
            
            if (-not $process.HasExited) {
                Write-Warning "Le processus $($process.Id) a dépassé le délai d'attente de $($processInfo.TimeoutSeconds) secondes."
                
                # Marquer le processus comme ayant dépassé le timeout
                $processInfo.TimedOut = $true
                
                # Exécuter le script OnTimeout
                if ($null -ne $processInfo.OnTimeout) {
                    try {
                        & $processInfo.OnTimeout -Process $process
                    }
                    catch {
                        Write-Warning "Erreur lors de l'exécution du script OnTimeout: $_"
                    }
                }
                
                # Arrêter le processus
                try {
                    $process.Kill()
                }
                catch {
                    Write-Warning "Erreur lors de l'arrêt du processus: $_"
                }
            }
            
            # Arrêter le timer
            $processInfo.Timer.Dispose()
        }
        
        # Créer un objet d'état pour le timer
        $state = [PSCustomObject]@{
            Process = $process
            TimeoutSeconds = $TimeoutSeconds
            OnTimeout = $OnTimeout
            Timer = $null
        }
        
        # Créer le timer
        $timer = New-Object System.Threading.Timer(
            $timerCallback,
            $state,
            ($TimeoutSeconds * 1000),
            [System.Threading.Timeout]::Infinite
        )
        
        $state.Timer = $timer
    }
    
    # Configurer le gestionnaire d'événement pour la sortie du processus
    if ($null -ne $OnExit) {
        $process.EnableRaisingEvents = $true
        
        $exitHandler = {
            param($sender, $e)
            
            $proc = [System.Diagnostics.Process]$sender
            
            # Exécuter le script OnExit
            try {
                & $OnExit -Process $proc
            }
            catch {
                Write-Warning "Erreur lors de l'exécution du script OnExit: $_"
            }
        }
        
        $process.Exited += $exitHandler
    }
    
    return $result
}

# Fonction pour attendre un processus avec un timeout
function Wait-ProcessWithTimeout {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByProcess")]
        [System.Diagnostics.Process]$Process,
        
        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [int]$Id,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 30,
        
        [Parameter(Mandatory = $false)]
        [switch]$KillOnTimeout,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Continue", "Stop", "SilentlyContinue")]
        [string]$TimeoutAction = "Stop"
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
    
    # Vérifier si le processus est déjà terminé
    if ($Process.HasExited) {
        return [PSCustomObject]@{
            Process = $Process
            ExitCode = $Process.ExitCode
            TimedOut = $false
            ExecutionTime = $Process.ExitTime - $Process.StartTime
        }
    }
    
    # Attendre que le processus se termine ou que le timeout soit atteint
    $completed = $Process.WaitForExit($TimeoutSeconds * 1000)
    
    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        Process = $Process
        ExitCode = -1
        TimedOut = -not $completed
        ExecutionTime = [TimeSpan]::Zero
    }
    
    if ($completed) {
        # Le processus s'est terminé normalement
        $result.ExitCode = $Process.ExitCode
        $result.ExecutionTime = $Process.ExitTime - $Process.StartTime
    }
    else {
        # Le processus a dépassé le timeout
        Write-Warning "Le processus $($Process.Id) a dépassé le délai d'attente de $TimeoutSeconds secondes."
        
        # Arrêter le processus si demandé
        if ($KillOnTimeout) {
            try {
                $Process.Kill()
                $Process.WaitForExit(5000) # Attendre 5 secondes que le processus se termine
                $result.ExitCode = $Process.ExitCode
            }
            catch {
                Write-Warning "Erreur lors de l'arrêt du processus : $_"
            }
        }
        
        # Gérer l'action de timeout
        if ($TimeoutAction -eq "Stop") {
            throw "Le processus $($Process.Id) a dépassé le délai d'attente de $TimeoutSeconds secondes."
        }
        elseif ($TimeoutAction -eq "Continue") {
            # Continuer l'exécution
        }
        elseif ($TimeoutAction -eq "SilentlyContinue") {
            # Continuer silencieusement
        }
    }
    
    return $result
}

# Exporter les fonctions
Export-ModuleMember -Function Invoke-ProcessWithTimeout, Invoke-ScriptBlockWithTimeout, Invoke-CommandWithTimeout, Start-BackgroundProcessWithTimeout, Wait-ProcessWithTimeout

<#
.SYNOPSIS
Nettoie les processus Visual Studio Code redondants ou gourmands en mémoire.

.DESCRIPTION
Ce script PowerShell identifie et termine les processus Visual Studio Code (code.exe)
qui dépassent une limite mémoire définie ou sont en surnombre.
Il permet également de préserver le processus principal (fenêtre active).

.PARAMETER MaxMemoryMB
Mémoire maximale autorisée par processus (par défaut : 500 Mo)

.PARAMETER MaxProcessCount
Nombre maximum autorisé de processus VSCode (par défaut : 10)

.PARAMETER PreserveMainProcess
Préserve le processus avec une fenêtre active

.PARAMETER WhatIf
Affiche ce qui serait fait sans exécuter

.PARAMETER Force
Force l'arrêt sans confirmation

.PARAMETER LogPath
Chemin du fichier journal (défaut : .\VSCodeCleanup.log)

.EXAMPLE
.\Clean-VSCodeProcesses.ps1 -MaxMemoryMB 300 -MaxProcessCount 8 -LogPath "C:\Logs\vscode.log"
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [int]$MaxMemoryMB = 500,
    [int]$MaxProcessCount = 10,
    [switch]$PreserveMainProcess,
    [switch]$Force,
    [string]$LogPath = ".\VSCodeCleanup.log"
)

function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $line = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "INFO" { Write-Host $line -ForegroundColor Cyan }
        "SUCCESS" { Write-Host $line -ForegroundColor Green }
        "WARNING" { Write-Host $line -ForegroundColor Yellow }
        "ERROR" { Write-Host $line -ForegroundColor Red }
        default { Write-Host $line }
    }

    $line | Out-File -FilePath $LogPath -Append -Encoding UTF8
}

function Get-VSCodeProcesses {
    Get-Process | Where-Object { $_.Name -like "code*" } | Select-Object Id, Name, StartTime, CPU, MainWindowHandle, MainWindowTitle,
    @{Name = 'WorkingSetMB'; Expression = { [math]::Round($_.WorkingSet / 1MB, 2) } }
}

function Get-MainVSCodeProcess {
    param ([array]$Processes)
    $Processes | Where-Object { $_.MainWindowHandle -ne 0 -and $_.MainWindowTitle } |
        Sort-Object StartTime -Descending | Select-Object -First 1
}

function Stop-VSCodeProcesses {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [array]$ProcessesToStop,
        [switch]$ForceStop
    )

    foreach ($proc in $ProcessesToStop) {
        $msg = "Arrêt du processus $($proc.Name) (PID: $($proc.Id), $($proc.WorkingSetMB)MB) - Raison: $($proc.Reason)"
        if ($ForceStop -or $PSCmdlet.ShouldProcess($proc.Name, $msg)) {
            try {
                Stop-Process -Id $proc.Id -Force
                Write-Log $msg -Level "SUCCESS"
            } catch {
                Write-Log "Erreur lors de l'arrêt de $($proc.Name) (PID: $($proc.Id)) : $_" -Level "ERROR"
            }
        }
    }
}

function Main {
    Write-Output "=== DÉBUT DU NETTOYAGE DES PROCESSUS VSCODE ==="
    Write-Log "Analyse des processus VSCode en cours..."

    $procs = Get-VSCodeProcesses
    if (-not $procs) {
        Write-Output "Aucun processus VSCode trouvé."
        Write-Log "Aucun processus VSCode trouvé." -Level "INFO"
        return
    }

    Write-Output "Nombre de processus VSCode trouvés: $($procs.Count)"
    Write-Output "Mémoire totale utilisée: $(($procs | Measure-Object WorkingSetMB -Sum).Sum) MB"

    $mainProc = $null
    if ($PreserveMainProcess) {
        $mainProc = Get-MainVSCodeProcess -Processes $procs
        if ($mainProc) {
            Write-Output "Processus principal détecté : PID $($mainProc.Id), Mémoire $($mainProc.WorkingSetMB)MB"
            Write-Log "Processus principal détecté : PID $($mainProc.Id), Mémoire $($mainProc.WorkingSetMB)MB"
        }
    }

    $toStop = @()

    # Processus dépassant la mémoire autorisée
    $toStop += $procs | Where-Object {
        $_.WorkingSetMB -gt $MaxMemoryMB -and
        (-not $PreserveMainProcess -or $_.Id -ne $mainProc.Id)
    } | ForEach-Object {
        if (-not ($_.PSObject.Properties.Name -contains "Reason")) {
            $_ | Add-Member -NotePropertyName Reason -NotePropertyValue "Mémoire > $MaxMemoryMB MB"
        }
        $_
    }

    # Processus excédentaires
    if ($procs.Count -gt $MaxProcessCount) {
        $excess = $procs | Where-Object { -not $PreserveMainProcess -or $_.Id -ne $mainProc.Id } |
            Sort-Object StartTime | Select-Object -First ($procs.Count - $MaxProcessCount)

        $toStop += $excess | ForEach-Object {
            if (-not ($_.PSObject.Properties.Name -contains "Reason")) {
                $_ | Add-Member -NotePropertyName Reason -NotePropertyValue "Excès de processus (max $MaxProcessCount)"
            }
            $_
        }
    }

    $uniqueToStop = $toStop | Sort-Object Id -Unique
    if ($uniqueToStop) {
        Write-Output "$($uniqueToStop.Count) processus identifiés pour arrêt."
        Write-Log "$($uniqueToStop.Count) processus identifiés pour arrêt." -Level "WARNING"
        Stop-VSCodeProcesses -ProcessesToStop $uniqueToStop -ForceStop:$Force
    } else {
        Write-Output "Aucun processus à arrêter."
        Write-Log "Aucun processus à arrêter." -Level "INFO"
    }

    $remaining = Get-VSCodeProcesses
    $totalMemory = ($remaining | Measure-Object WorkingSetMB -Sum).Sum
    Write-Output "Processus restants: $($remaining.Count), Mémoire totale: $totalMemory MB"
    Write-Log "Processus restants: $($remaining.Count), Mémoire totale: $totalMemory MB" -Level "INFO"
    Write-Output "=== FIN DU NETTOYAGE DES PROCESSUS VSCODE ==="
}

Main

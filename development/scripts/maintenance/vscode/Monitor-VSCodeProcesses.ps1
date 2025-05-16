<#
.SYNOPSIS
Surveille et nettoie les processus Visual Studio Code.

.DESCRIPTION
Ce script surveille les processus Visual Studio Code (code.exe) et les nettoie
lorsqu'ils dépassent certaines limites de mémoire ou de nombre. Il peut s'exécuter
en continu ou une seule fois.

.PARAMETER IntervalMinutes
Intervalle en minutes entre chaque vérification des processus.
Par défaut: 5 minutes.

.PARAMETER MaxMemoryMB
Mémoire maximale autorisée par processus VSCode individuel.
Par défaut: 500 Mo.

.PARAMETER MaxProcessCount
Nombre maximal de processus VSCode autorisés. Au-delà de cette limite,
les processus les plus anciens ou consommant le plus de mémoire seront arrêtés.
Par défaut: 10.

.PARAMETER MaxTotalMemoryMB
La quantité maximale de mémoire totale (en Mo) que tous les processus VSCode
peuvent utiliser ensemble. Par défaut: 4096 Mo.

.PARAMETER LogFile
Le chemin du fichier de journal où les actions seront enregistrées.
Par défaut: "$env:TEMP\VSCodeMonitor.log".

.PARAMETER RunOnce
Si spécifié, le script s'exécute une seule fois puis se termine.

.EXAMPLE
.\Monitor-VSCodeProcesses.ps1 -IntervalMinutes 10 -MaxMemoryMB 300

.EXAMPLE
.\Monitor-VSCodeProcesses.ps1 -RunOnce -MaxTotalMemoryMB 2048

.NOTES
Auteur: Maintenance Team
Version: 1.0
Date de création: 2025-05-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$IntervalMinutes = 5,

    [Parameter(Mandatory = $false)]
    [int]$MaxMemoryMB = 500,

    [Parameter(Mandatory = $false)]
    [int]$MaxProcessCount = 10,

    [Parameter(Mandatory = $false)]
    [int]$MaxTotalMemoryMB = 4096,

    [Parameter(Mandatory = $false)]
    [string]$LogFile = "$env:TEMP\VSCodeMonitor.log",

    [Parameter(Mandatory = $false)]
    [switch]$RunOnce
)

# Fonction pour écrire des messages de log
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "INFO" { Write-Host $logMessage -ForegroundColor Cyan }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage }
    }

    # Écrire dans le fichier de log
    try {
        Add-Content -Path $LogFile -Value $logMessage -Encoding UTF8
    } catch {
        Write-Host "Erreur lors de l'écriture dans le fichier de log: $_" -ForegroundColor Red
    }
}

# Fonction pour obtenir les processus VSCode
function Get-VSCodeProcesses {
    [CmdletBinding()]
    param ()

    try {
        $processes = Get-Process | Where-Object { $_.Name -like "*code*" } |
            Select-Object Id, Name, Description, StartTime,
            @{Name = 'WorkingSetMB'; Expression = { [math]::Round($_.WorkingSet / 1MB, 2) } },
            @{Name = 'CPU'; Expression = { $_.CPU } },
            @{Name = 'MainWindowTitle'; Expression = { $_.MainWindowTitle } },
            @{Name = 'MainWindowHandle'; Expression = { $_.MainWindowHandle } }

        # Si aucun processus n'est trouvé, retourner un tableau vide
        if ($null -eq $processes) {
            return @()
        }

        return $processes
    } catch {
        Write-Log "Erreur lors de la récupération des processus VSCode: $_" -Level "ERROR"
        return @()
    }
}

# Fonction pour nettoyer les processus VSCode
function Remove-VSCodeProcesses {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$MaxMemoryMB = 500,

        [Parameter(Mandatory = $false)]
        [int]$MaxProcessCount = 10,

        [Parameter(Mandatory = $false)]
        [int]$MaxTotalMemoryMB = 4096
    )

    # Obtenir tous les processus VSCode
    $vsCodeProcesses = Get-VSCodeProcesses

    if ($vsCodeProcesses.Count -eq 0) {
        Write-Log "Aucun processus Visual Studio Code trouvé." -Level "INFO"
        return 0
    }

    Write-Log "Nombre de processus VSCode trouvés: $($vsCodeProcesses.Count)" -Level "INFO"

    # Calculer l'utilisation totale de la mémoire
    $totalMemoryMB = ($vsCodeProcesses | Measure-Object -Property WorkingSetMB -Sum).Sum
    Write-Log "Utilisation totale de la mémoire par VSCode: $totalMemoryMB MB" -Level "INFO"

    # Vérifier si l'utilisation totale de la mémoire dépasse la limite
    $processesToStop = @()

    if ($totalMemoryMB -gt $MaxTotalMemoryMB) {
        Write-Log "L'utilisation totale de la mémoire ($totalMemoryMB MB) dépasse la limite ($MaxTotalMemoryMB MB)" -Level "WARNING"

        # Calculer combien de mémoire doit être libérée
        $memoryToFree = $totalMemoryMB - $MaxTotalMemoryMB
        Write-Log "Mémoire à libérer: $memoryToFree MB" -Level "INFO"

        # Trier les processus par utilisation de mémoire (décroissant)
        $sortedProcesses = $vsCodeProcesses | Sort-Object -Property WorkingSetMB -Descending

        # Identifier les processus à arrêter pour libérer suffisamment de mémoire
        $memoryFreed = 0
        foreach ($process in $sortedProcesses) {
            # Ne pas arrêter le processus principal (celui avec une fenêtre active)
            if ($process.MainWindowHandle -ne 0 -and $process.MainWindowTitle -ne "") {
                continue
            }

            $processesToStop += $process
            $memoryFreed += $process.WorkingSetMB

            if ($memoryFreed -ge $memoryToFree) {
                break
            }
        }
    }

    # Vérifier si le nombre de processus dépasse la limite
    if ($vsCodeProcesses.Count -gt $MaxProcessCount) {
        Write-Log "Le nombre de processus ($($vsCodeProcesses.Count)) dépasse la limite ($MaxProcessCount)" -Level "WARNING"

        # Trier les processus par date de démarrage (croissant = plus anciens d'abord)
        $oldestProcesses = $vsCodeProcesses | Sort-Object -Property StartTime |
            Select-Object -First ($vsCodeProcesses.Count - $MaxProcessCount)

        # Ajouter les processus les plus anciens à la liste des processus à arrêter
        foreach ($process in $oldestProcesses) {
            # Vérifier si le processus n'est pas déjà dans la liste
            if (-not ($processesToStop | Where-Object { $_.Id -eq $process.Id })) {
                $processesToStop += $process
            }
        }
    }

    # Vérifier les processus individuels qui dépassent la limite de mémoire
    $highMemoryProcesses = $vsCodeProcesses | Where-Object { $_.WorkingSetMB -gt $MaxMemoryMB }
    foreach ($process in $highMemoryProcesses) {
        # Vérifier si le processus n'est pas déjà dans la liste
        if (-not ($processesToStop | Where-Object { $_.Id -eq $process.Id })) {
            $processesToStop += $process
        }
    }

    # Arrêter les processus identifiés
    $stoppedCount = 0
    foreach ($process in $processesToStop) {
        try {
            Stop-Process -Id $process.Id -Force
            Write-Log "Processus arrêté: $($process.Name) (PID: $($process.Id), Mémoire: $($process.WorkingSetMB) MB)" -Level "SUCCESS"
            $stoppedCount++
        } catch {
            Write-Log "Erreur lors de l'arrêt du processus $($process.Id): $_" -Level "ERROR"
        }
    }

    if ($stoppedCount -gt 0) {
        Write-Log "$stoppedCount processus VSCode ont été arrêtés." -Level "SUCCESS"

        # Afficher les statistiques après nettoyage
        $remainingProcesses = Get-VSCodeProcesses
        $remainingMemoryMB = ($remainingProcesses | Measure-Object -Property WorkingSetMB -Sum).Sum
        Write-Log "Processus VSCode restants: $($remainingProcesses.Count), Mémoire utilisée: $remainingMemoryMB MB" -Level "SUCCESS"
        Write-Log "Mémoire libérée: $($totalMemoryMB - $remainingMemoryMB) MB" -Level "SUCCESS"
    } else {
        Write-Log "Aucun processus VSCode n'a été arrêté." -Level "INFO"
    }

    return $stoppedCount
}

# Fonction principale
function Main {
    Write-Log "Démarrage de la surveillance des processus Visual Studio Code..." -Level "INFO"
    Write-Log "Intervalle de vérification: $IntervalMinutes minutes" -Level "INFO"
    Write-Log "Limite de mémoire par processus: $MaxMemoryMB MB" -Level "INFO"
    Write-Log "Limite de processus: $MaxProcessCount" -Level "INFO"
    Write-Log "Limite de mémoire totale: $MaxTotalMemoryMB MB" -Level "INFO"

    if ($RunOnce) {
        Write-Log "Exécution unique du nettoyage des processus VSCode..." -Level "INFO"
        Remove-VSCodeProcesses -MaxMemoryMB $MaxMemoryMB -MaxProcessCount $MaxProcessCount -MaxTotalMemoryMB $MaxTotalMemoryMB
        Write-Log "Nettoyage terminé." -Level "SUCCESS"
        return
    }

    try {
        while ($true) {
            Write-Log "Vérification des processus VSCode..." -Level "INFO"
            Remove-VSCodeProcesses -MaxMemoryMB $MaxMemoryMB -MaxProcessCount $MaxProcessCount -MaxTotalMemoryMB $MaxTotalMemoryMB

            Write-Log "Prochaine vérification dans $IntervalMinutes minutes..." -Level "INFO"
            Start-Sleep -Seconds ($IntervalMinutes * 60)
        }
    } catch {
        Write-Log "Erreur lors de la surveillance des processus VSCode: $_" -Level "ERROR"
    }
}

# Exécuter la fonction principale
Main

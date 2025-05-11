﻿# Measure-Memory.ps1
# Module utilitaire pour mesurer la mémoire utilisée par PowerShell
# Version: 1.0
# Date: 2025-05-15

# Fonction pour obtenir l'utilisation mémoire actuelle du processus PowerShell
function Get-CurrentMemoryUsage {
    <#
    .SYNOPSIS
        Obtient l'utilisation mémoire actuelle du processus PowerShell.

    .DESCRIPTION
        Cette fonction récupère l'utilisation mémoire actuelle du processus PowerShell en cours d'exécution.
        Elle renvoie la valeur en mégaoctets (MB) par défaut, mais peut également renvoyer en kilooctets (KB) ou gigaoctets (GB).

    .PARAMETER Unit
        L'unité de mesure pour la valeur de retour. Les valeurs possibles sont "KB", "MB" ou "GB".
        La valeur par défaut est "MB".

    .PARAMETER Process
        Le processus dont on veut mesurer l'utilisation mémoire. Par défaut, il s'agit du processus PowerShell actuel.

    .EXAMPLE
        Get-CurrentMemoryUsage
        Renvoie l'utilisation mémoire actuelle du processus PowerShell en MB.

    .EXAMPLE
        Get-CurrentMemoryUsage -Unit GB
        Renvoie l'utilisation mémoire actuelle du processus PowerShell en GB.

    .EXAMPLE
        Get-CurrentMemoryUsage -Process (Get-Process -Id 1234)
        Renvoie l'utilisation mémoire du processus spécifié en MB.

    .OUTPUTS
        System.Double
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("KB", "MB", "GB")]
        [string]$Unit = "MB",

        [Parameter(Mandatory = $false)]
        [System.Diagnostics.Process]$Process = $null
    )

    if ($null -eq $Process) {
        $Process = Get-Process -Id $PID
    }

    $workingSet = $Process.WorkingSet64
    $privateMemory = $Process.PrivateMemorySize64
    $virtualMemory = $Process.VirtualMemorySize64

    $divisor = switch ($Unit) {
        "KB" { 1KB }
        "MB" { 1MB }
        "GB" { 1GB }
        default { 1MB }
    }

    return [PSCustomObject]@{
        ProcessName   = $Process.ProcessName
        ProcessId     = $Process.Id
        WorkingSet    = [math]::Round($workingSet / $divisor, 2)
        PrivateMemory = [math]::Round($privateMemory / $divisor, 2)
        VirtualMemory = [math]::Round($virtualMemory / $divisor, 2)
        Unit          = $Unit
        Timestamp     = Get-Date
    }
}

# Fonction pour démarrer le suivi de l'utilisation mémoire
function Start-MemoryTracking {
    <#
    .SYNOPSIS
        Démarre le suivi de l'utilisation mémoire.

    .DESCRIPTION
        Cette fonction démarre le suivi de l'utilisation mémoire du processus PowerShell actuel.
        Elle renvoie un objet de suivi qui peut être utilisé pour obtenir des statistiques sur l'utilisation mémoire.

    .PARAMETER SampleInterval
        L'intervalle en millisecondes entre chaque échantillon de mesure mémoire.
        La valeur par défaut est 1000 ms (1 seconde).

    .PARAMETER Unit
        L'unité de mesure pour les valeurs de mémoire. Les valeurs possibles sont "KB", "MB" ou "GB".
        La valeur par défaut est "MB".

    .PARAMETER Process
        Le processus dont on veut suivre l'utilisation mémoire. Par défaut, il s'agit du processus PowerShell actuel.

    .EXAMPLE
        $tracker = Start-MemoryTracking
        # Exécuter du code à mesurer
        $stats = $tracker.GetStatistics()
        $tracker.Stop()

    .OUTPUTS
        System.Management.Automation.PSObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleInterval = 1000,

        [Parameter(Mandatory = $false)]
        [ValidateSet("KB", "MB", "GB")]
        [string]$Unit = "MB",

        [Parameter(Mandatory = $false)]
        [System.Diagnostics.Process]$Process = $null
    )

    if ($null -eq $Process) {
        $Process = Get-Process -Id $PID
    }

    # Créer un objet de suivi
    $tracker = [PSCustomObject]@{
        Process        = $Process
        StartTime      = Get-Date
        EndTime        = $null
        IsRunning      = $true
        SampleInterval = $SampleInterval
        Unit           = $Unit
        Samples        = [System.Collections.ArrayList]@()
        InitialMemory  = $null
        RunspaceId     = $null
        Job            = $null
    }

    # Capturer l'utilisation mémoire initiale
    $initialMemory = Get-CurrentMemoryUsage -Unit $Unit -Process $Process
    $tracker.InitialMemory = $initialMemory
    $tracker.Samples.Add($initialMemory) | Out-Null

    # Ajouter des méthodes à l'objet de suivi
    $tracker | Add-Member -MemberType ScriptMethod -Name Stop -Value {
        if (-not $this.IsRunning) {
            return
        }

        $this.IsRunning = $false
        $this.EndTime = Get-Date

        if ($null -ne $this.Job) {
            Stop-Job -Job $this.Job
            Remove-Job -Job $this.Job -Force
        }

        # Capturer l'utilisation mémoire finale
        $finalMemory = Get-CurrentMemoryUsage -Unit $this.Unit -Process $this.Process
        $this.Samples.Add($finalMemory) | Out-Null
    }

    $tracker | Add-Member -MemberType ScriptMethod -Name GetStatistics -Value {
        $samples = $this.Samples

        if ($samples.Count -eq 0) {
            return $null
        }

        $workingSets = $samples | ForEach-Object { $_.WorkingSet }
        $privateMemories = $samples | ForEach-Object { $_.PrivateMemory }

        $initialWorkingSet = $this.InitialMemory.WorkingSet
        $currentWorkingSet = $samples[-1].WorkingSet
        $peakWorkingSet = ($workingSets | Measure-Object -Maximum).Maximum

        $initialPrivateMemory = $this.InitialMemory.PrivateMemory
        $currentPrivateMemory = $samples[-1].PrivateMemory
        $peakPrivateMemory = ($privateMemories | Measure-Object -Maximum).Maximum

        $duration = if ($this.EndTime) {
            ($this.EndTime - $this.StartTime).TotalSeconds
        } else {
            ((Get-Date) - $this.StartTime).TotalSeconds
        }

        return [PSCustomObject]@{
            StartTime               = $this.StartTime
            EndTime                 = $this.EndTime
            Duration                = [math]::Round($duration, 2)
            SampleCount             = $samples.Count
            InitialWorkingSet       = $initialWorkingSet
            CurrentWorkingSet       = $currentWorkingSet
            PeakWorkingSet          = $peakWorkingSet
            WorkingSetDelta         = [math]::Round($currentWorkingSet - $initialWorkingSet, 2)
            WorkingSetGrowthRate    = if ($duration -gt 0) { [math]::Round(($currentWorkingSet - $initialWorkingSet) / $duration, 2) } else { 0 }
            InitialPrivateMemory    = $initialPrivateMemory
            CurrentPrivateMemory    = $currentPrivateMemory
            PeakPrivateMemory       = $peakPrivateMemory
            PrivateMemoryDelta      = [math]::Round($currentPrivateMemory - $initialPrivateMemory, 2)
            PrivateMemoryGrowthRate = if ($duration -gt 0) { [math]::Round(($currentPrivateMemory - $initialPrivateMemory) / $duration, 2) } else { 0 }
            Unit                    = $this.Unit
        }
    }

    $tracker | Add-Member -MemberType ScriptMethod -Name TakeSample -Value {
        $sample = Get-CurrentMemoryUsage -Unit $this.Unit -Process $this.Process
        $this.Samples.Add($sample) | Out-Null
        return $sample
    }

    # Démarrer un job en arrière-plan pour collecter des échantillons à intervalles réguliers
    if ($SampleInterval -gt 0) {
        $scriptBlock = {
            param($processId, $sampleInterval, $unit, $runspaceId)

            # Importer la fonction Get-CurrentMemoryUsage
            ${function:Get-CurrentMemoryUsage} = $using:function:Get-CurrentMemoryUsage

            while ($true) {
                try {
                    $process = Get-Process -Id $processId -ErrorAction Stop
                    $sample = Get-CurrentMemoryUsage -Unit $unit -Process $process

                    # Envoyer l'échantillon au pipeline
                    $sample

                    Start-Sleep -Milliseconds $sampleInterval
                } catch {
                    # Le processus n'existe plus ou une autre erreur s'est produite
                    break
                }
            }
        }

        $tracker.RunspaceId = [System.Management.Automation.Runspaces.Runspace]::DefaultRunspace.InstanceId
        $tracker.Job = Start-Job -ScriptBlock $scriptBlock -ArgumentList $Process.Id, $SampleInterval, $Unit, $tracker.RunspaceId

        # Ajouter une méthode pour récupérer les échantillons du job
        $tracker | Add-Member -MemberType ScriptMethod -Name UpdateSamples -Value {
            if ($null -eq $this.Job -or $this.Job.State -ne "Running") {
                return
            }

            $newSamples = Receive-Job -Job $this.Job
            foreach ($sample in $newSamples) {
                $this.Samples.Add($sample) | Out-Null
            }
        }
    }

    return $tracker
}

# Fonction pour mesurer l'utilisation mémoire d'un bloc de code
function Measure-ScriptMemoryUsage {
    <#
    .SYNOPSIS
        Mesure l'utilisation mémoire d'un bloc de script.

    .DESCRIPTION
        Cette fonction mesure l'utilisation mémoire avant et après l'exécution d'un bloc de script,
        et renvoie des statistiques sur l'utilisation mémoire.

    .PARAMETER ScriptBlock
        Le bloc de script à mesurer.

    .PARAMETER Arguments
        Les arguments à passer au bloc de script.

    .PARAMETER SampleInterval
        L'intervalle en millisecondes entre chaque échantillon de mesure mémoire.
        La valeur par défaut est 0, ce qui signifie qu'aucun échantillonnage n'est effectué pendant l'exécution.

    .PARAMETER Unit
        L'unité de mesure pour les valeurs de mémoire. Les valeurs possibles sont "KB", "MB" ou "GB".
        La valeur par défaut est "MB".

    .EXAMPLE
        Measure-ScriptMemoryUsage -ScriptBlock {
            # Code à mesurer
            $largeArray = 1..1000000
        }

    .OUTPUTS
        System.Management.Automation.PSObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [object[]]$Arguments = @(),

        [Parameter(Mandatory = $false)]
        [int]$SampleInterval = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("KB", "MB", "GB")]
        [string]$Unit = "MB"
    )

    # Forcer le garbage collector à s'exécuter avant de commencer
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    # Démarrer le suivi de l'utilisation mémoire
    $tracker = Start-MemoryTracking -SampleInterval $SampleInterval -Unit $Unit

    # Exécuter le bloc de script
    $result = $null
    $executionTime = Measure-Command {
        try {
            $result = & $ScriptBlock @Arguments
        } catch {
            Write-Error "Erreur lors de l'exécution du bloc de script: $_"
        }
    }

    # Arrêter le suivi de l'utilisation mémoire
    $tracker.Stop()

    # Forcer le garbage collector à s'exécuter après l'exécution
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()

    # Prendre un échantillon final après le garbage collection
    $finalSample = Get-CurrentMemoryUsage -Unit $Unit

    # Obtenir les statistiques
    $stats = $tracker.GetStatistics()

    # Ajouter des informations supplémentaires
    $stats | Add-Member -MemberType NoteProperty -Name ExecutionTime -Value $executionTime.TotalSeconds
    $stats | Add-Member -MemberType NoteProperty -Name FinalWorkingSetAfterGC -Value $finalSample.WorkingSet
    $stats | Add-Member -MemberType NoteProperty -Name FinalPrivateMemoryAfterGC -Value $finalSample.PrivateMemory
    $stats | Add-Member -MemberType NoteProperty -Name RetainedWorkingSet -Value ($finalSample.WorkingSet - $tracker.InitialMemory.WorkingSet)
    $stats | Add-Member -MemberType NoteProperty -Name RetainedPrivateMemory -Value ($finalSample.PrivateMemory - $tracker.InitialMemory.PrivateMemory)

    return [PSCustomObject]@{
        MemoryStatistics = $stats
        Result           = $result
        Samples          = $tracker.Samples
    }
}

# Fonction pour formater les résultats de mesure mémoire
function Format-MemoryStatistics {
    <#
    .SYNOPSIS
        Formate les statistiques d'utilisation mémoire pour l'affichage.

    .DESCRIPTION
        Cette fonction formate les statistiques d'utilisation mémoire pour l'affichage
        dans différents formats (texte, CSV, JSON, HTML).

    .PARAMETER Statistics
        Les statistiques d'utilisation mémoire à formater.

    .PARAMETER Format
        Le format de sortie. Les valeurs possibles sont "Text", "CSV", "JSON" ou "HTML".
        La valeur par défaut est "Text".

    .EXAMPLE
        $stats = Measure-ScriptMemoryUsage -ScriptBlock { $largeArray = 1..1000000 }
        Format-MemoryStatistics -Statistics $stats.MemoryStatistics

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$Statistics,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Text", "CSV", "JSON", "HTML")]
        [string]$Format = "Text"
    )

    process {
        switch ($Format) {
            "Text" {
                $output = @()
                $output += "=== STATISTIQUES D'UTILISATION MÉMOIRE ==="
                $output += "Heure de début: $($Statistics.StartTime)"
                $output += "Heure de fin: $($Statistics.EndTime)"
                $output += "Durée: $($Statistics.Duration) secondes"
                $output += "Nombre d'échantillons: $($Statistics.SampleCount)"
                $output += ""
                $output += "--- WORKING SET (MÉMOIRE DE TRAVAIL) ---"
                $output += "Initial: $($Statistics.InitialWorkingSet) $($Statistics.Unit)"
                $output += "Final: $($Statistics.CurrentWorkingSet) $($Statistics.Unit)"
                $output += "Pic: $($Statistics.PeakWorkingSet) $($Statistics.Unit)"
                $output += "Delta: $($Statistics.WorkingSetDelta) $($Statistics.Unit)"
                $output += "Taux de croissance: $($Statistics.WorkingSetGrowthRate) $($Statistics.Unit)/s"
                $output += ""
                $output += "--- MÉMOIRE PRIVÉE ---"
                $output += "Initiale: $($Statistics.InitialPrivateMemory) $($Statistics.Unit)"
                $output += "Finale: $($Statistics.CurrentPrivateMemory) $($Statistics.Unit)"
                $output += "Pic: $($Statistics.PeakPrivateMemory) $($Statistics.Unit)"
                $output += "Delta: $($Statistics.PrivateMemoryDelta) $($Statistics.Unit)"
                $output += "Taux de croissance: $($Statistics.PrivateMemoryGrowthRate) $($Statistics.Unit)/s"

                if ($Statistics.PSObject.Properties.Name -contains "ExecutionTime") {
                    $output += ""
                    $output += "--- INFORMATIONS SUPPLÉMENTAIRES ---"
                    $output += "Temps d'exécution: $($Statistics.ExecutionTime) secondes"
                    $output += "Working Set après GC: $($Statistics.FinalWorkingSetAfterGC) $($Statistics.Unit)"
                    $output += "Mémoire privée après GC: $($Statistics.FinalPrivateMemoryAfterGC) $($Statistics.Unit)"
                    $output += "Working Set conservé: $($Statistics.RetainedWorkingSet) $($Statistics.Unit)"
                    $output += "Mémoire privée conservée: $($Statistics.RetainedPrivateMemory) $($Statistics.Unit)"
                }

                return $output -join "`n"
            }
            "CSV" {
                return $Statistics | ConvertTo-Csv -NoTypeInformation
            }
            "JSON" {
                return $Statistics | ConvertTo-Json -Depth 5
            }
            "HTML" {
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Statistiques d'utilisation mémoire</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { padding: 8px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #f2f2f2; }
        .highlight { font-weight: bold; color: #e74c3c; }
    </style>
</head>
<body>
    <h1>Statistiques d'utilisation mémoire</h1>

    <h2>Informations générales</h2>
    <table>
        <tr><th>Métrique</th><th>Valeur</th></tr>
        <tr><td>Heure de début</td><td>$($Statistics.StartTime)</td></tr>
        <tr><td>Heure de fin</td><td>$($Statistics.EndTime)</td></tr>
        <tr><td>Durée</td><td>$($Statistics.Duration) secondes</td></tr>
        <tr><td>Nombre d'échantillons</td><td>$($Statistics.SampleCount)</td></tr>
    </table>

    <h2>Working Set (Mémoire de travail)</h2>
    <table>
        <tr><th>Métrique</th><th>Valeur</th></tr>
        <tr><td>Initial</td><td>$($Statistics.InitialWorkingSet) $($Statistics.Unit)</td></tr>
        <tr><td>Final</td><td>$($Statistics.CurrentWorkingSet) $($Statistics.Unit)</td></tr>
        <tr><td>Pic</td><td class="highlight">$($Statistics.PeakWorkingSet) $($Statistics.Unit)</td></tr>
        <tr><td>Delta</td><td>$($Statistics.WorkingSetDelta) $($Statistics.Unit)</td></tr>
        <tr><td>Taux de croissance</td><td>$($Statistics.WorkingSetGrowthRate) $($Statistics.Unit)/s</td></tr>
    </table>

    <h2>Mémoire privée</h2>
    <table>
        <tr><th>Métrique</th><th>Valeur</th></tr>
        <tr><td>Initiale</td><td>$($Statistics.InitialPrivateMemory) $($Statistics.Unit)</td></tr>
        <tr><td>Finale</td><td>$($Statistics.CurrentPrivateMemory) $($Statistics.Unit)</td></tr>
        <tr><td>Pic</td><td class="highlight">$($Statistics.PeakPrivateMemory) $($Statistics.Unit)</td></tr>
        <tr><td>Delta</td><td>$($Statistics.PrivateMemoryDelta) $($Statistics.Unit)</td></tr>
        <tr><td>Taux de croissance</td><td>$($Statistics.PrivateMemoryGrowthRate) $($Statistics.Unit)/s</td></tr>
    </table>
"@

                if ($Statistics.PSObject.Properties.Name -contains "ExecutionTime") {
                    $html += @"

    <h2>Informations supplémentaires</h2>
    <table>
        <tr><th>Métrique</th><th>Valeur</th></tr>
        <tr><td>Temps d'exécution</td><td>$($Statistics.ExecutionTime) secondes</td></tr>
        <tr><td>Working Set après GC</td><td>$($Statistics.FinalWorkingSetAfterGC) $($Statistics.Unit)</td></tr>
        <tr><td>Mémoire privée après GC</td><td>$($Statistics.FinalPrivateMemoryAfterGC) $($Statistics.Unit)</td></tr>
        <tr><td>Working Set conservé</td><td>$($Statistics.RetainedWorkingSet) $($Statistics.Unit)</td></tr>
        <tr><td>Mémoire privée conservée</td><td>$($Statistics.RetainedPrivateMemory) $($Statistics.Unit)</td></tr>
    </table>
"@
                }

                $html += @"
</body>
</html>
"@

                return $html
            }
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Get-CurrentMemoryUsage, Start-MemoryTracking, Measure-ScriptMemoryUsage, Format-MemoryStatistics

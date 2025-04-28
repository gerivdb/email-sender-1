#Requires -Version 5.1
<#
.SYNOPSIS
    Module de traÃ§age des performances pour l'analyse des pull requests.
.DESCRIPTION
    Fournit des fonctionnalitÃ©s pour tracer et analyser les performances
    du systÃ¨me d'analyse des pull requests.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

# Classe principale pour le traÃ§age des performances
class PRPerformanceTracer {
    # PropriÃ©tÃ©s
    [string[]]$EnabledTracers
    [string]$DetailLevel
    [string]$OutputPath
    [System.Collections.Generic.List[object]]$Operations
    [System.Collections.Generic.Dictionary[string, object]]$ActiveOperations
    [System.Diagnostics.Stopwatch]$MainStopwatch
    [bool]$IsRunning
    [datetime]$StartTime
    [datetime]$EndTime
    [System.Collections.Generic.List[object]]$ResourceSnapshots

    # Constructeur
    PRPerformanceTracer([string[]]$tracerTypes, [string]$detailLevel, [string]$outputPath) {
        $this.EnabledTracers = $tracerTypes
        $this.DetailLevel = $detailLevel
        $this.OutputPath = $outputPath
        $this.Operations = [System.Collections.Generic.List[object]]::new()
        $this.ActiveOperations = [System.Collections.Generic.Dictionary[string, object]]::new()
        $this.MainStopwatch = [System.Diagnostics.Stopwatch]::new()
        $this.IsRunning = $false
        $this.ResourceSnapshots = [System.Collections.Generic.List[object]]::new()
    }

    # DÃ©marrer le traÃ§age
    [void] Start() {
        $this.StartTime = Get-Date
        $this.MainStopwatch.Start()
        $this.IsRunning = $true
        $this.TakeResourceSnapshot("Start")
    }

    # ArrÃªter le traÃ§age
    [void] Stop() {
        $this.EndTime = Get-Date
        $this.MainStopwatch.Stop()
        $this.IsRunning = $false
        $this.TakeResourceSnapshot("End")
    }

    # DÃ©marrer une opÃ©ration
    [void] StartOperation([string]$name, [string]$description) {
        if (-not $this.IsRunning) {
            Write-Warning "Le traceur n'est pas dÃ©marrÃ©. L'opÃ©ration ne sera pas tracÃ©e."
            return
        }

        $operation = [PSCustomObject]@{
            Name          = $name
            Description   = $description
            StartTime     = Get-Date
            EndTime       = $null
            Duration      = $null
            ElapsedMS     = $this.MainStopwatch.ElapsedMilliseconds
            Children      = [System.Collections.Generic.List[object]]::new()
            Parent        = $null
            ResourceUsage = $null
        }

        # Prendre un instantanÃ© des ressources
        $operation.ResourceUsage = $this.CaptureResourceUsage()

        # Ajouter Ã  la liste des opÃ©rations actives
        $this.ActiveOperations[$name] = $operation
    }

    # ArrÃªter une opÃ©ration
    [void] StopOperation([string]$name) {
        if (-not $this.IsRunning) {
            Write-Warning "Le traceur n'est pas dÃ©marrÃ©. L'opÃ©ration ne sera pas arrÃªtÃ©e."
            return
        }

        if (-not $this.ActiveOperations.ContainsKey($name)) {
            Write-Warning "Aucune opÃ©ration active avec le nom '$name'."
            return
        }

        $operation = $this.ActiveOperations[$name]
        $operation.EndTime = Get-Date
        $operation.Duration = $operation.EndTime - $operation.StartTime

        # Mettre Ã  jour l'utilisation des ressources
        $endResourceUsage = $this.CaptureResourceUsage()
        $operation.ResourceUsage = [PSCustomObject]@{
            Start = $operation.ResourceUsage
            End   = $endResourceUsage
            Delta = [PSCustomObject]@{
                CPU           = $endResourceUsage.CPU - $operation.ResourceUsage.CPU
                WorkingSet    = $endResourceUsage.WorkingSet - $operation.ResourceUsage.WorkingSet
                PrivateMemory = $endResourceUsage.PrivateMemory - $operation.ResourceUsage.PrivateMemory
                HandleCount   = $endResourceUsage.HandleCount - $operation.ResourceUsage.HandleCount
            }
        }

        # Ajouter Ã  la liste des opÃ©rations terminÃ©es
        $this.Operations.Add($operation)

        # Supprimer de la liste des opÃ©rations actives
        $this.ActiveOperations.Remove($name)
    }

    # Capturer l'utilisation des ressources
    [object] CaptureResourceUsage() {
        # Obtenir le processus actuel et ses mÃ©triques
        $processObj = Get-Process -Id ([System.Diagnostics.Process]::GetCurrentProcess().Id)
        $cpuTime = $processObj.CPU
        $workingSetSize = $processObj.WorkingSet64
        $privateMemorySize = $processObj.PrivateMemorySize64
        $handleCount = $processObj.HandleCount
        $timestamp = Get-Date

        # CrÃ©er et retourner l'objet d'utilisation des ressources
        return [PSCustomObject]@{
            Timestamp     = $timestamp
            CPU           = $cpuTime
            WorkingSet    = $workingSetSize
            PrivateMemory = $privateMemorySize
            HandleCount   = $handleCount
        }
    }

    # Prendre un instantanÃ© des ressources
    [void] TakeResourceSnapshot([string]$label) {
        $snapshot = $this.CaptureResourceUsage()
        $snapshot | Add-Member -MemberType NoteProperty -Name "Label" -Value $label
        $this.ResourceSnapshots.Add($snapshot)
    }

    # Obtenir les donnÃ©es de traÃ§age
    [object] GetTracingData() {
        return [PSCustomObject]@{
            StartTime         = $this.StartTime
            EndTime           = $this.EndTime
            Duration          = $this.EndTime - $this.StartTime
            Operations        = $this.Operations
            ResourceSnapshots = $this.ResourceSnapshots
            EnabledTracers    = $this.EnabledTracers
            DetailLevel       = $this.DetailLevel
        }
    }
}

# Fonction pour crÃ©er un nouveau traceur de performance
function New-PRPerformanceTracer {
    [CmdletBinding()]
    [OutputType([PRPerformanceTracer])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$TracerTypes,

        [Parameter(Mandatory = $true)]
        [ValidateSet("Basic", "Detailed", "Comprehensive")]
        [string]$DetailLevel,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    try {
        $tracer = [PRPerformanceTracer]::new($TracerTypes, $DetailLevel, $OutputPath)
        return $tracer
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du traceur de performance: $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-PRPerformanceTracer

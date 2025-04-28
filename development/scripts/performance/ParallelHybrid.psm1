#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'orchestration hybride PowerShell-Python pour le traitement parallÃ¨le.
.DESCRIPTION
    Ce module fournit une architecture hybride permettant d'utiliser PowerShell pour
    l'orchestration des tÃ¢ches et Python pour le traitement parallÃ¨le intensif.
    Il intÃ¨gre Ã©galement un systÃ¨me de cache partagÃ© entre les deux langages.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
    CompatibilitÃ©: PowerShell 5.1 et supÃ©rieur, Python 3.6 et supÃ©rieur
#>

# Importer les modules dÃ©pendants
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$taskManagerPath = Join-Path -Path $scriptPath -ChildPath "TaskManager.psm1"
$cacheAdapterPath = Join-Path -Path $scriptPath -ChildPath "CacheAdapter.psm1"

Import-Module $taskManagerPath -Force
Import-Module $cacheAdapterPath -Force

# VÃ©rifier la prÃ©sence de Python
function Test-PythonInstallation {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+\.\d+\.\d+)") {
            $version = $matches[1]
            Write-Verbose "Python version $version dÃ©tectÃ©e."
            return $true
        }
        else {
            Write-Warning "Python est installÃ© mais la version n'a pas pu Ãªtre dÃ©terminÃ©e."
            return $false
        }
    }
    catch {
        Write-Warning "Python n'est pas installÃ© ou n'est pas dans le PATH."
        return $false
    }
}

# VÃ©rifier les modules Python requis
function Test-PythonModules {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$RequiredModules = @("numpy", "psutil", "multiprocessing", "json")
    )

    $results = @{}

    foreach ($module in $RequiredModules) {
        try {
            $output = python -c "import $module; print('OK')" 2>&1
            if ($output -eq "OK") {
                $results[$module] = $true
                Write-Verbose "Module Python '$module' est disponible."
            }
            else {
                $results[$module] = $false
                Write-Warning "Module Python '$module' n'a pas pu Ãªtre importÃ©."
            }
        }
        catch {
            $results[$module] = $false
            Write-Warning "Module Python '$module' n'est pas installÃ©."
        }
    }

    return $results
}

<#
.SYNOPSIS
    Initialise l'environnement hybride PowerShell-Python.
.DESCRIPTION
    VÃ©rifie les prÃ©requis et initialise l'environnement pour le traitement parallÃ¨le hybride.
.PARAMETER PythonPath
    Chemin vers l'exÃ©cutable Python. Si non spÃ©cifiÃ©, utilise 'python' dans le PATH.
.PARAMETER RequiredModules
    Liste des modules Python requis. Par dÃ©faut: numpy, psutil, multiprocessing, json.
.PARAMETER InstallMissing
    Si spÃ©cifiÃ©, tente d'installer les modules Python manquants.
.PARAMETER CacheConfig
    Configuration du cache partagÃ©.
.EXAMPLE
    Initialize-HybridEnvironment -Verbose
.OUTPUTS
    PSCustomObject avec les informations sur l'environnement initialisÃ©.
#>
function Initialize-HybridEnvironment {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$PythonPath = "python",

        [Parameter(Mandatory = $false)]
        [string[]]$RequiredModules = @("numpy", "psutil", "multiprocessing", "json"),

        [Parameter(Mandatory = $false)]
        [switch]$InstallMissing,

        [Parameter(Mandatory = $false)]
        [hashtable]$CacheConfig = @{}
    )

    # VÃ©rifier Python
    $pythonInstalled = Test-PythonInstallation
    if (-not $pythonInstalled) {
        throw "Python est requis pour l'environnement hybride."
    }

    # VÃ©rifier les modules Python
    $moduleStatus = Test-PythonModules -RequiredModules $RequiredModules
    $missingModules = $moduleStatus.Keys | Where-Object { -not $moduleStatus[$_] }

    # Installer les modules manquants si demandÃ©
    if ($missingModules.Count -gt 0 -and $InstallMissing) {
        Write-Host "Installation des modules Python manquants..." -ForegroundColor Yellow
        foreach ($module in $missingModules) {
            try {
                Write-Host "Installation de $module..." -ForegroundColor Yellow
                & $PythonPath -m pip install $module
                Write-Host "Module $module installÃ© avec succÃ¨s." -ForegroundColor Green
            }
            catch {
                Write-Warning "Ã‰chec de l'installation du module $module : $_"
            }
        }

        # RevÃ©rifier les modules
        $moduleStatus = Test-PythonModules -RequiredModules $RequiredModules
        $missingModules = $moduleStatus.Keys | Where-Object { -not $moduleStatus[$_] }
    }

    # Initialiser le cache partagÃ©
    $cache = Initialize-SharedCache -Config $CacheConfig

    # Retourner l'Ã©tat de l'environnement
    return [PSCustomObject]@{
        PythonInstalled = $pythonInstalled
        PythonPath = $PythonPath
        ModuleStatus = $moduleStatus
        MissingModules = $missingModules
        Cache = $cache
        Ready = ($pythonInstalled -and $missingModules.Count -eq 0)
    }
}

<#
.SYNOPSIS
    ExÃ©cute une tÃ¢che parallÃ¨le en utilisant l'architecture hybride PowerShell-Python.
.DESCRIPTION
    DÃ©compose une tÃ¢che en sous-tÃ¢ches, les distribue aux processus Python pour traitement
    parallÃ¨le, puis agrÃ¨ge les rÃ©sultats.
.PARAMETER PythonScript
    Chemin vers le script Python Ã  exÃ©cuter.
.PARAMETER InputData
    DonnÃ©es d'entrÃ©e Ã  traiter.
.PARAMETER BatchSize
    Taille des lots pour le traitement par lots. Par dÃ©faut: 100.
.PARAMETER MaxConcurrency
    Nombre maximum de processus concurrents. Par dÃ©faut: nombre de processeurs.
.PARAMETER CacheConfig
    Configuration du cache partagÃ©.
.PARAMETER AdditionalArguments
    Arguments supplÃ©mentaires Ã  passer au script Python.
.EXAMPLE
    $data = 1..1000
    $results = Invoke-HybridParallelTask -PythonScript ".\scripts\process_data.py" -InputData $data -BatchSize 100
.OUTPUTS
    Les rÃ©sultats agrÃ©gÃ©s du traitement parallÃ¨le.
#>
function Invoke-HybridParallelTask {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PythonScript,

        [Parameter(Mandatory = $true)]
        [array]$InputData,

        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 100,

        [Parameter(Mandatory = $false)]
        [int]$MaxConcurrency = 0,

        [Parameter(Mandatory = $false)]
        [hashtable]$CacheConfig = @{},

        [Parameter(Mandatory = $false)]
        [hashtable]$AdditionalArguments = @{}
    )

    # Initialiser l'environnement si nÃ©cessaire
    $env = Initialize-HybridEnvironment -CacheConfig $CacheConfig
    if (-not $env.Ready) {
        throw "L'environnement hybride n'est pas prÃªt. VÃ©rifiez les prÃ©requis."
    }

    # Initialiser le gestionnaire de tÃ¢ches
    $taskManager = Initialize-TaskManager -MaxConcurrency $MaxConcurrency

    # Partitionner les donnÃ©es
    $batches = Split-DataIntoBatches -InputData $InputData -BatchSize $BatchSize
    Write-Verbose "DonnÃ©es partitionnÃ©es en $($batches.Count) lots."

    # PrÃ©parer les tÃ¢ches
    $tasks = @()
    foreach ($batch in $batches) {
        $taskParams = @{
            PythonScript = $PythonScript
            InputData = $batch
            CachePath = $env.Cache.CachePath
            AdditionalArguments = $AdditionalArguments
        }
        $tasks += $taskParams
    }

    # ExÃ©cuter les tÃ¢ches en parallÃ¨le
    $results = Invoke-ParallelTasks -TaskManager $taskManager -Tasks $tasks

    # AgrÃ©ger les rÃ©sultats
    $aggregatedResults = Merge-TaskResults -Results $results

    return $aggregatedResults
}

<#
.SYNOPSIS
    Partitionne les donnÃ©es en lots pour le traitement parallÃ¨le.
.DESCRIPTION
    Divise un tableau de donnÃ©es en lots de taille spÃ©cifiÃ©e pour optimiser le traitement parallÃ¨le.
.PARAMETER InputData
    DonnÃ©es d'entrÃ©e Ã  partitionner.
.PARAMETER BatchSize
    Taille des lots. Par dÃ©faut: 100.
.PARAMETER BalanceLoad
    Si spÃ©cifiÃ©, tente d'Ã©quilibrer la charge entre les lots.
.EXAMPLE
    $data = 1..1000
    $batches = Split-DataIntoBatches -InputData $data -BatchSize 100
.OUTPUTS
    Un tableau de lots de donnÃ©es.
#>
function Split-DataIntoBatches {
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter(Mandatory = $true)]
        [array]$InputData,

        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 100,

        [Parameter(Mandatory = $false)]
        [switch]$BalanceLoad
    )

    $batches = @()
    $dataCount = $InputData.Count

    if ($dataCount -eq 0) {
        return $batches
    }

    if ($BalanceLoad) {
        # DÃ©terminer le nombre optimal de lots basÃ© sur le nombre de processeurs
        $optimalBatchCount = [Math]::Max(1, [Environment]::ProcessorCount)
        $optimalBatchSize = [Math]::Ceiling($dataCount / $optimalBatchCount)

        # Ajuster la taille des lots pour Ã©quilibrer la charge
        $BatchSize = [Math]::Min($BatchSize, $optimalBatchSize)
    }

    # CrÃ©er les lots
    for ($i = 0; $i -lt $dataCount; $i += $BatchSize) {
        $end = [Math]::Min($i + $BatchSize - 1, $dataCount - 1)
        $batch = $InputData[$i..$end]
        $batches += ,$batch
    }

    return $batches
}

<#
.SYNOPSIS
    Fusionne les rÃ©sultats des tÃ¢ches parallÃ¨les.
.DESCRIPTION
    AgrÃ¨ge les rÃ©sultats des diffÃ©rentes tÃ¢ches parallÃ¨les en un seul rÃ©sultat cohÃ©rent.
.PARAMETER Results
    RÃ©sultats des tÃ¢ches parallÃ¨les Ã  fusionner.
.EXAMPLE
    $mergedResults = Merge-TaskResults -Results $taskResults
.OUTPUTS
    Les rÃ©sultats fusionnÃ©s.
#>
function Merge-TaskResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Results
    )

    # DÃ©terminer le type de rÃ©sultat pour choisir la stratÃ©gie de fusion appropriÃ©e
    if ($Results.Count -eq 0) {
        return @()
    }

    $firstResult = $Results[0]

    # StratÃ©gie pour les tableaux simples
    if ($firstResult -is [array] -and $firstResult.Count -gt 0 -and $firstResult[0] -isnot [hashtable] -and $firstResult[0] -isnot [PSCustomObject]) {
        return $Results | ForEach-Object { $_ } # Aplatir le tableau
    }

    # StratÃ©gie pour les tableaux d'objets
    if ($firstResult -is [array] -and $firstResult.Count -gt 0 -and ($firstResult[0] -is [hashtable] -or $firstResult[0] -is [PSCustomObject])) {
        $mergedArray = @()
        foreach ($result in $Results) {
            $mergedArray += $result
        }
        return $mergedArray
    }

    # StratÃ©gie pour les hashtables
    if ($firstResult -is [hashtable]) {
        $mergedHash = @{}
        foreach ($result in $Results) {
            foreach ($key in $result.Keys) {
                if (-not $mergedHash.ContainsKey($key)) {
                    $mergedHash[$key] = $result[$key]
                }
                else {
                    # Si la valeur est un tableau, concatÃ©ner
                    if ($mergedHash[$key] -is [array] -and $result[$key] -is [array]) {
                        $mergedHash[$key] = $mergedHash[$key] + $result[$key]
                    }
                    # Si la valeur est un nombre, additionner
                    elseif ($mergedHash[$key] -is [int] -or $mergedHash[$key] -is [double]) {
                        $mergedHash[$key] += $result[$key]
                    }
                    # Sinon, conserver la derniÃ¨re valeur
                    else {
                        $mergedHash[$key] = $result[$key]
                    }
                }
            }
        }
        return $mergedHash
    }

    # StratÃ©gie par dÃ©faut : retourner le tableau de rÃ©sultats tel quel
    return $Results
}

<#
.SYNOPSIS
    Surveille les ressources systÃ¨me pendant l'exÃ©cution des tÃ¢ches parallÃ¨les.
.DESCRIPTION
    Utilise Python pour surveiller l'utilisation du CPU, de la mÃ©moire et du disque
    pendant l'exÃ©cution des tÃ¢ches parallÃ¨les.
.PARAMETER IntervalSeconds
    Intervalle de surveillance en secondes. Par dÃ©faut: 1.
.PARAMETER MaxSamples
    Nombre maximum d'Ã©chantillons Ã  collecter. Par dÃ©faut: 0 (illimitÃ©).
.EXAMPLE
    Start-ResourceMonitoring -IntervalSeconds 2
.OUTPUTS
    Un objet reprÃ©sentant le processus de surveillance.
#>
function Start-ResourceMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [int]$IntervalSeconds = 1,

        [Parameter(Mandatory = $false)]
        [int]$MaxSamples = 0
    )

    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $monitorScript = Join-Path -Path $scriptPath -ChildPath "python\resource_monitor.py"

    # VÃ©rifier que le script existe
    if (-not (Test-Path -Path $monitorScript)) {
        throw "Le script de surveillance des ressources n'existe pas : $monitorScript"
    }

    # Lancer le script Python en arriÃ¨re-plan
    $pythonArgs = @(
        $monitorScript,
        "--interval", $IntervalSeconds,
        "--output", (Join-Path -Path $env:TEMP -ChildPath "resource_monitoring.json")
    )

    if ($MaxSamples -gt 0) {
        $pythonArgs += @("--max-samples", $MaxSamples)
    }

    $process = Start-Process -FilePath "python" -ArgumentList $pythonArgs -PassThru -WindowStyle Hidden

    return [PSCustomObject]@{
        Process = $process
        OutputFile = (Join-Path -Path $env:TEMP -ChildPath "resource_monitoring.json")
        StartTime = Get-Date
    }
}

<#
.SYNOPSIS
    ArrÃªte la surveillance des ressources systÃ¨me.
.DESCRIPTION
    ArrÃªte le processus de surveillance des ressources et rÃ©cupÃ¨re les donnÃ©es collectÃ©es.
.PARAMETER MonitoringObject
    Objet de surveillance retournÃ© par Start-ResourceMonitoring.
.EXAMPLE
    $monitoring = Start-ResourceMonitoring
    # ExÃ©cuter des tÃ¢ches...
    $resourceData = Stop-ResourceMonitoring -MonitoringObject $monitoring
.OUTPUTS
    Les donnÃ©es de surveillance des ressources.
#>
function Stop-ResourceMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$MonitoringObject
    )

    # ArrÃªter le processus de surveillance
    if ($MonitoringObject.Process -and -not $MonitoringObject.Process.HasExited) {
        $MonitoringObject.Process | Stop-Process -Force
    }

    # Attendre un peu pour s'assurer que les donnÃ©es sont Ã©crites
    Start-Sleep -Seconds 1

    # Lire les donnÃ©es de surveillance
    $monitoringData = @{
        StartTime = $MonitoringObject.StartTime
        EndTime = Get-Date
        Duration = (Get-Date) - $MonitoringObject.StartTime
        Samples = @()
    }

    if (Test-Path -Path $MonitoringObject.OutputFile) {
        try {
            $rawData = Get-Content -Path $MonitoringObject.OutputFile -Raw | ConvertFrom-Json
            $monitoringData.Samples = $rawData
        }
        catch {
            Write-Warning "Erreur lors de la lecture des donnÃ©es de surveillance : $_"
        }
    }
    else {
        Write-Warning "Fichier de donnÃ©es de surveillance introuvable : $($MonitoringObject.OutputFile)"
    }

    return $monitoringData
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-HybridEnvironment, Invoke-HybridParallelTask, Split-DataIntoBatches, Merge-TaskResults, Start-ResourceMonitoring, Stop-ResourceMonitoring

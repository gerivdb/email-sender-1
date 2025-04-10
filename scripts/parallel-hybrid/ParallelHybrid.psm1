#Requires -Version 5.1
<#
.SYNOPSIS
    Module d'orchestration hybride PowerShell-Python pour le traitement parallèle.
.DESCRIPTION
    Ce module fournit une architecture hybride permettant d'utiliser PowerShell pour
    l'orchestration des tâches et Python pour le traitement parallèle intensif.
    Il intègre également un système de cache partagé entre les deux langages.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-10
    Compatibilité: PowerShell 5.1 et supérieur, Python 3.6 et supérieur
#>

# Importer les modules dépendants
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$taskManagerPath = Join-Path -Path $scriptPath -ChildPath "TaskManager.psm1"
$cacheAdapterPath = Join-Path -Path $scriptPath -ChildPath "CacheAdapter.psm1"

Import-Module $taskManagerPath -Force
Import-Module $cacheAdapterPath -Force

# Vérifier la présence de Python
function Test-PythonInstallation {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+\.\d+\.\d+)") {
            $version = $matches[1]
            Write-Verbose "Python version $version détectée."
            return $true
        }
        else {
            Write-Warning "Python est installé mais la version n'a pas pu être déterminée."
            return $false
        }
    }
    catch {
        Write-Warning "Python n'est pas installé ou n'est pas dans le PATH."
        return $false
    }
}

# Vérifier les modules Python requis
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
                Write-Warning "Module Python '$module' n'a pas pu être importé."
            }
        }
        catch {
            $results[$module] = $false
            Write-Warning "Module Python '$module' n'est pas installé."
        }
    }

    return $results
}

<#
.SYNOPSIS
    Initialise l'environnement hybride PowerShell-Python.
.DESCRIPTION
    Vérifie les prérequis et initialise l'environnement pour le traitement parallèle hybride.
.PARAMETER PythonPath
    Chemin vers l'exécutable Python. Si non spécifié, utilise 'python' dans le PATH.
.PARAMETER RequiredModules
    Liste des modules Python requis. Par défaut: numpy, psutil, multiprocessing, json.
.PARAMETER InstallMissing
    Si spécifié, tente d'installer les modules Python manquants.
.PARAMETER CacheConfig
    Configuration du cache partagé.
.EXAMPLE
    Initialize-HybridEnvironment -Verbose
.OUTPUTS
    PSCustomObject avec les informations sur l'environnement initialisé.
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

    # Vérifier Python
    $pythonInstalled = Test-PythonInstallation
    if (-not $pythonInstalled) {
        throw "Python est requis pour l'environnement hybride."
    }

    # Vérifier les modules Python
    $moduleStatus = Test-PythonModules -RequiredModules $RequiredModules
    $missingModules = $moduleStatus.Keys | Where-Object { -not $moduleStatus[$_] }

    # Installer les modules manquants si demandé
    if ($missingModules.Count -gt 0 -and $InstallMissing) {
        Write-Host "Installation des modules Python manquants..." -ForegroundColor Yellow
        foreach ($module in $missingModules) {
            try {
                Write-Host "Installation de $module..." -ForegroundColor Yellow
                & $PythonPath -m pip install $module
                Write-Host "Module $module installé avec succès." -ForegroundColor Green
            }
            catch {
                Write-Warning "Échec de l'installation du module $module : $_"
            }
        }

        # Revérifier les modules
        $moduleStatus = Test-PythonModules -RequiredModules $RequiredModules
        $missingModules = $moduleStatus.Keys | Where-Object { -not $moduleStatus[$_] }
    }

    # Initialiser le cache partagé
    $cache = Initialize-SharedCache -Config $CacheConfig

    # Retourner l'état de l'environnement
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
    Exécute une tâche parallèle en utilisant l'architecture hybride PowerShell-Python.
.DESCRIPTION
    Décompose une tâche en sous-tâches, les distribue aux processus Python pour traitement
    parallèle, puis agrège les résultats.
.PARAMETER PythonScript
    Chemin vers le script Python à exécuter.
.PARAMETER InputData
    Données d'entrée à traiter.
.PARAMETER BatchSize
    Taille des lots pour le traitement par lots. Par défaut: 100.
.PARAMETER MaxConcurrency
    Nombre maximum de processus concurrents. Par défaut: nombre de processeurs.
.PARAMETER CacheConfig
    Configuration du cache partagé.
.PARAMETER AdditionalArguments
    Arguments supplémentaires à passer au script Python.
.EXAMPLE
    $data = 1..1000
    $results = Invoke-HybridParallelTask -PythonScript ".\scripts\process_data.py" -InputData $data -BatchSize 100
.OUTPUTS
    Les résultats agrégés du traitement parallèle.
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

    # Initialiser l'environnement si nécessaire
    $env = Initialize-HybridEnvironment -CacheConfig $CacheConfig
    if (-not $env.Ready) {
        throw "L'environnement hybride n'est pas prêt. Vérifiez les prérequis."
    }

    # Initialiser le gestionnaire de tâches
    $taskManager = Initialize-TaskManager -MaxConcurrency $MaxConcurrency

    # Partitionner les données
    $batches = Split-DataIntoBatches -InputData $InputData -BatchSize $BatchSize
    Write-Verbose "Données partitionnées en $($batches.Count) lots."

    # Préparer les tâches
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

    # Exécuter les tâches en parallèle
    $results = Invoke-ParallelTasks -TaskManager $taskManager -Tasks $tasks

    # Agréger les résultats
    $aggregatedResults = Merge-TaskResults -Results $results

    return $aggregatedResults
}

<#
.SYNOPSIS
    Partitionne les données en lots pour le traitement parallèle.
.DESCRIPTION
    Divise un tableau de données en lots de taille spécifiée pour optimiser le traitement parallèle.
.PARAMETER InputData
    Données d'entrée à partitionner.
.PARAMETER BatchSize
    Taille des lots. Par défaut: 100.
.PARAMETER BalanceLoad
    Si spécifié, tente d'équilibrer la charge entre les lots.
.EXAMPLE
    $data = 1..1000
    $batches = Split-DataIntoBatches -InputData $data -BatchSize 100
.OUTPUTS
    Un tableau de lots de données.
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
        # Déterminer le nombre optimal de lots basé sur le nombre de processeurs
        $optimalBatchCount = [Math]::Max(1, [Environment]::ProcessorCount)
        $optimalBatchSize = [Math]::Ceiling($dataCount / $optimalBatchCount)

        # Ajuster la taille des lots pour équilibrer la charge
        $BatchSize = [Math]::Min($BatchSize, $optimalBatchSize)
    }

    # Créer les lots
    for ($i = 0; $i -lt $dataCount; $i += $BatchSize) {
        $end = [Math]::Min($i + $BatchSize - 1, $dataCount - 1)
        $batch = $InputData[$i..$end]
        $batches += ,$batch
    }

    return $batches
}

<#
.SYNOPSIS
    Fusionne les résultats des tâches parallèles.
.DESCRIPTION
    Agrège les résultats des différentes tâches parallèles en un seul résultat cohérent.
.PARAMETER Results
    Résultats des tâches parallèles à fusionner.
.EXAMPLE
    $mergedResults = Merge-TaskResults -Results $taskResults
.OUTPUTS
    Les résultats fusionnés.
#>
function Merge-TaskResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Results
    )

    # Déterminer le type de résultat pour choisir la stratégie de fusion appropriée
    if ($Results.Count -eq 0) {
        return @()
    }

    $firstResult = $Results[0]

    # Stratégie pour les tableaux simples
    if ($firstResult -is [array] -and $firstResult.Count -gt 0 -and $firstResult[0] -isnot [hashtable] -and $firstResult[0] -isnot [PSCustomObject]) {
        return $Results | ForEach-Object { $_ } # Aplatir le tableau
    }

    # Stratégie pour les tableaux d'objets
    if ($firstResult -is [array] -and $firstResult.Count -gt 0 -and ($firstResult[0] -is [hashtable] -or $firstResult[0] -is [PSCustomObject])) {
        $mergedArray = @()
        foreach ($result in $Results) {
            $mergedArray += $result
        }
        return $mergedArray
    }

    # Stratégie pour les hashtables
    if ($firstResult -is [hashtable]) {
        $mergedHash = @{}
        foreach ($result in $Results) {
            foreach ($key in $result.Keys) {
                if (-not $mergedHash.ContainsKey($key)) {
                    $mergedHash[$key] = $result[$key]
                }
                else {
                    # Si la valeur est un tableau, concaténer
                    if ($mergedHash[$key] -is [array] -and $result[$key] -is [array]) {
                        $mergedHash[$key] = $mergedHash[$key] + $result[$key]
                    }
                    # Si la valeur est un nombre, additionner
                    elseif ($mergedHash[$key] -is [int] -or $mergedHash[$key] -is [double]) {
                        $mergedHash[$key] += $result[$key]
                    }
                    # Sinon, conserver la dernière valeur
                    else {
                        $mergedHash[$key] = $result[$key]
                    }
                }
            }
        }
        return $mergedHash
    }

    # Stratégie par défaut : retourner le tableau de résultats tel quel
    return $Results
}

<#
.SYNOPSIS
    Surveille les ressources système pendant l'exécution des tâches parallèles.
.DESCRIPTION
    Utilise Python pour surveiller l'utilisation du CPU, de la mémoire et du disque
    pendant l'exécution des tâches parallèles.
.PARAMETER IntervalSeconds
    Intervalle de surveillance en secondes. Par défaut: 1.
.PARAMETER MaxSamples
    Nombre maximum d'échantillons à collecter. Par défaut: 0 (illimité).
.EXAMPLE
    Start-ResourceMonitoring -IntervalSeconds 2
.OUTPUTS
    Un objet représentant le processus de surveillance.
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

    # Vérifier que le script existe
    if (-not (Test-Path -Path $monitorScript)) {
        throw "Le script de surveillance des ressources n'existe pas : $monitorScript"
    }

    # Lancer le script Python en arrière-plan
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
    Arrête la surveillance des ressources système.
.DESCRIPTION
    Arrête le processus de surveillance des ressources et récupère les données collectées.
.PARAMETER MonitoringObject
    Objet de surveillance retourné par Start-ResourceMonitoring.
.EXAMPLE
    $monitoring = Start-ResourceMonitoring
    # Exécuter des tâches...
    $resourceData = Stop-ResourceMonitoring -MonitoringObject $monitoring
.OUTPUTS
    Les données de surveillance des ressources.
#>
function Stop-ResourceMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$MonitoringObject
    )

    # Arrêter le processus de surveillance
    if ($MonitoringObject.Process -and -not $MonitoringObject.Process.HasExited) {
        $MonitoringObject.Process | Stop-Process -Force
    }

    # Attendre un peu pour s'assurer que les données sont écrites
    Start-Sleep -Seconds 1

    # Lire les données de surveillance
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
            Write-Warning "Erreur lors de la lecture des données de surveillance : $_"
        }
    }
    else {
        Write-Warning "Fichier de données de surveillance introuvable : $($MonitoringObject.OutputFile)"
    }

    return $monitoringData
}

# Exporter les fonctions publiques
Export-ModuleMember -Function Initialize-HybridEnvironment, Invoke-HybridParallelTask, Split-DataIntoBatches, Merge-TaskResults, Start-ResourceMonitoring, Stop-ResourceMonitoring

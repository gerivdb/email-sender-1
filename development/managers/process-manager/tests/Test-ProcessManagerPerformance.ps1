<#
.SYNOPSIS
    Tests de performance pour le Process Manager.

.DESCRIPTION
    Ce script exÃ©cute des tests de performance pour Ã©valuer les performances
    du Process Manager avec les modules amÃ©liorÃ©s.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER Iterations
    Nombre d'itÃ©rations pour chaque test de performance. Par dÃ©faut, 10.

.PARAMETER SkipCleanup
    Ne supprime pas les fichiers de test aprÃ¨s l'exÃ©cution.

.EXAMPLE
    .\Test-ProcessManagerPerformance.ps1
    ExÃ©cute les tests de performance pour le Process Manager.

.EXAMPLE
    .\Test-ProcessManagerPerformance.ps1 -ProjectRoot "D:\Projets\MonProjet" -Iterations 20 -SkipCleanup
    ExÃ©cute les tests de performance avec 20 itÃ©rations et ne supprime pas les fichiers de test.

.NOTES
    Auteur: EMAIL_SENDER_1
    Version: 1.0
    Date de crÃ©ation: 2025-05-15
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1",

    [Parameter(Mandatory = $false)]
    [int]$Iterations = 10,

    [Parameter(Mandatory = $false)]
    [switch]$SkipCleanup
)

# DÃ©finir les chemins
$processManagerRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers\process-manager"
$modulesRoot = Join-Path -Path $processManagerRoot -ChildPath "modules"
$scriptsRoot = Join-Path -Path $processManagerRoot -ChildPath "scripts"
$testsRoot = Join-Path -Path $processManagerRoot -ChildPath "tests"
$processManagerScript = Join-Path -Path $scriptsRoot -ChildPath "process-manager.ps1"
$testDir = Join-Path -Path $testsRoot -ChildPath "performance-tests"
$testConfigPath = Join-Path -Path $testDir -ChildPath "test-performance.config.json"
$resultsPath = Join-Path -Path $testDir -ChildPath "performance-results.csv"

# Fonction pour Ã©crire des messages de journal
function Write-TestLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success", "Debug")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # DÃ©finir la couleur en fonction du niveau
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        "Debug" { "Gray" }
        default { "White" }
    }
    
    # Afficher le message dans la console
    Write-Host $logMessage -ForegroundColor $color
}

# Fonction pour mesurer les performances d'une opÃ©ration
function Measure-Performance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Operation,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 10,

        [Parameter(Mandatory = $false)]
        [string]$Description = ""
    )

    Write-TestLog -Message "Test de performance : $Name" -Level Info
    if ($Description) {
        Write-TestLog -Message "  Description : $Description" -Level Debug
    }
    
    $results = @()
    
    for ($i = 1; $i -le $Iterations; $i++) {
        Write-TestLog -Message "  ItÃ©ration $i/$Iterations..." -Level Debug
        
        try {
            # Mesurer le temps d'exÃ©cution
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = & $Operation
            $stopwatch.Stop()
            $executionTime = $stopwatch.ElapsedMilliseconds
            
            # Mesurer l'utilisation de la mÃ©moire
            $memoryBefore = [System.GC]::GetTotalMemory($true)
            $result = & $Operation
            $memoryAfter = [System.GC]::GetTotalMemory($true)
            $memoryUsage = $memoryAfter - $memoryBefore
            
            $results += [PSCustomObject]@{
                Iteration = $i
                ExecutionTime = $executionTime
                MemoryUsage = $memoryUsage
            }
        } catch {
            Write-TestLog -Message "  Erreur lors de l'itÃ©ration $i : $_" -Level Error
        }
    }
    
    # Calculer les statistiques
    $avgExecutionTime = ($results | Measure-Object -Property ExecutionTime -Average).Average
    $minExecutionTime = ($results | Measure-Object -Property ExecutionTime -Minimum).Minimum
    $maxExecutionTime = ($results | Measure-Object -Property ExecutionTime -Maximum).Maximum
    $stdDevExecutionTime = [Math]::Sqrt(($results | ForEach-Object { [Math]::Pow($_.ExecutionTime - $avgExecutionTime, 2) } | Measure-Object -Average).Average)
    
    $avgMemoryUsage = ($results | Measure-Object -Property MemoryUsage -Average).Average
    $minMemoryUsage = ($results | Measure-Object -Property MemoryUsage -Minimum).Minimum
    $maxMemoryUsage = ($results | Measure-Object -Property MemoryUsage -Maximum).Maximum
    $stdDevMemoryUsage = [Math]::Sqrt(($results | ForEach-Object { [Math]::Pow($_.MemoryUsage - $avgMemoryUsage, 2) } | Measure-Object -Average).Average)
    
    # Afficher les rÃ©sultats
    Write-TestLog -Message "  RÃ©sultats :" -Level Info
    Write-TestLog -Message "    Temps d'exÃ©cution moyen : $($avgExecutionTime.ToString("F2")) ms" -Level Info
    Write-TestLog -Message "    Temps d'exÃ©cution min   : $($minExecutionTime.ToString("F2")) ms" -Level Info
    Write-TestLog -Message "    Temps d'exÃ©cution max   : $($maxExecutionTime.ToString("F2")) ms" -Level Info
    Write-TestLog -Message "    Ã‰cart-type              : $($stdDevExecutionTime.ToString("F2")) ms" -Level Info
    Write-TestLog -Message "    Utilisation mÃ©moire moy.: $($avgMemoryUsage.ToString("F2")) octets" -Level Info
    
    # Retourner les rÃ©sultats
    return [PSCustomObject]@{
        Name = $Name
        Description = $Description
        Iterations = $Iterations
        AvgExecutionTime = $avgExecutionTime
        MinExecutionTime = $minExecutionTime
        MaxExecutionTime = $maxExecutionTime
        StdDevExecutionTime = $stdDevExecutionTime
        AvgMemoryUsage = $avgMemoryUsage
        MinMemoryUsage = $minMemoryUsage
        MaxMemoryUsage = $maxMemoryUsage
        StdDevMemoryUsage = $stdDevMemoryUsage
        RawResults = $results
    }
}

# VÃ©rifier que le rÃ©pertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-TestLog -Message "Le rÃ©pertoire du projet n'existe pas : $ProjectRoot" -Level Error
    exit 1
}

# VÃ©rifier que le rÃ©pertoire du Process Manager existe
if (-not (Test-Path -Path $processManagerRoot -PathType Container)) {
    Write-TestLog -Message "Le rÃ©pertoire du Process Manager n'existe pas : $processManagerRoot" -Level Error
    exit 1
}

# VÃ©rifier que le script du Process Manager existe
if (-not (Test-Path -Path $processManagerScript -PathType Leaf)) {
    Write-TestLog -Message "Le script du Process Manager n'existe pas : $processManagerScript" -Level Error
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de configuration de test
$testConfig = @{
    Enabled = $true
    LogLevel = "Error" # Utiliser Error pour rÃ©duire la sortie console pendant les tests de performance
    LogPath = "logs/test-performance"
    Managers = @{}
}
$testConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testConfigPath -Encoding UTF8

# CrÃ©er des gestionnaires de test pour les tests de performance
$numTestManagers = 50 # Nombre de gestionnaires de test Ã  crÃ©er
$testManagerTemplate = @"
<#
.SYNOPSIS
    Gestionnaire de test {0} pour les tests de performance.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisÃ© pour les tests de performance
    du Process Manager.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-TestManager{0} {{
    [CmdletBinding()]
    param()
    
    Write-Host "DÃ©marrage du gestionnaire de test {0}..."
}}

function Stop-TestManager{0} {{
    [CmdletBinding()]
    param()
    
    Write-Host "ArrÃªt du gestionnaire de test {0}..."
}}

function Get-TestManager{0}Status {{
    [CmdletBinding()]
    param()
    
    return @{{
        Status = "Running"
        StartTime = Get-Date
        ManagerId = {0}
    }}
}}

# ExÃ©cuter la commande spÃ©cifiÃ©e
switch (`$Command) {{
    "Start" {{
        Start-TestManager{0}
    }}
    "Stop" {{
        Stop-TestManager{0}
    }}
    "Status" {{
        Get-TestManager{0}Status
    }}
    default {{
        Write-Host "Commande inconnue : `$Command"
    }}
}}
"@

$testManagers = @()
for ($i = 1; $i -le $numTestManagers; $i++) {
    $managerName = "TestManager$i"
    $managerPath = Join-Path -Path $testDir -ChildPath "test-manager-$i.ps1"
    $manifestPath = Join-Path -Path $testDir -ChildPath "test-manager-$i.manifest.json"
    
    # CrÃ©er le script du gestionnaire
    $managerContent = $testManagerTemplate -f $i
    Set-Content -Path $managerPath -Value $managerContent -Encoding UTF8
    
    # CrÃ©er le manifeste du gestionnaire
    $manifest = @{
        Name = $managerName
        Description = "Gestionnaire de test $i pour les tests de performance"
        Version = "1.0.0"
        Author = "EMAIL_SENDER_1"
        Dependencies = @()
    }
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $manifestPath -Encoding UTF8
    
    $testManagers += [PSCustomObject]@{
        Name = $managerName
        Path = $managerPath
        ManifestPath = $manifestPath
    }
}

# DÃ©finir les tests de performance
$performanceTests = @(
    @{
        Name = "Enregistrement d'un gestionnaire"
        Description = "Mesure les performances d'enregistrement d'un gestionnaire."
        Operation = {
            $manager = $testManagers | Get-Random
            & $processManagerScript -Command Register -ManagerName $manager.Name -ManagerPath $manager.Path -ConfigPath $testConfigPath -Force
        }
    },
    @{
        Name = "DÃ©couverte des gestionnaires"
        Description = "Mesure les performances de dÃ©couverte des gestionnaires."
        Operation = {
            & $processManagerScript -Command Discover -ConfigPath $testConfigPath -Force -SearchPaths @($testDir)
        }
    },
    @{
        Name = "Listage des gestionnaires"
        Description = "Mesure les performances de listage des gestionnaires."
        Operation = {
            & $processManagerScript -Command List -ConfigPath $testConfigPath
        }
    },
    @{
        Name = "ExÃ©cution d'une commande sur un gestionnaire"
        Description = "Mesure les performances d'exÃ©cution d'une commande sur un gestionnaire."
        Operation = {
            $manager = $testManagers | Get-Random
            & $processManagerScript -Command Run -ManagerName $manager.Name -ManagerCommand "Status" -ConfigPath $testConfigPath
        }
    },
    @{
        Name = "Obtention de l'Ã©tat d'un gestionnaire"
        Description = "Mesure les performances d'obtention de l'Ã©tat d'un gestionnaire."
        Operation = {
            $manager = $testManagers | Get-Random
            & $processManagerScript -Command Status -ManagerName $manager.Name -ConfigPath $testConfigPath
        }
    },
    @{
        Name = "Configuration d'un gestionnaire"
        Description = "Mesure les performances de configuration d'un gestionnaire."
        Operation = {
            $manager = $testManagers | Get-Random
            & $processManagerScript -Command Configure -ManagerName $manager.Name -Enabled $true -ConfigPath $testConfigPath
        }
    }
)

# ExÃ©cuter les tests de performance
$results = @()

Write-TestLog -Message "ExÃ©cution de $($performanceTests.Count) tests de performance pour le Process Manager..." -Level Info
Write-TestLog -Message "Nombre d'itÃ©rations par test : $Iterations" -Level Info

foreach ($test in $performanceTests) {
    $result = Measure-Performance -Name $test.Name -Description $test.Description -Operation $test.Operation -Iterations $Iterations
    $results += $result
}

# Enregistrer les rÃ©sultats dans un fichier CSV
$results | Select-Object Name, Description, Iterations, AvgExecutionTime, MinExecutionTime, MaxExecutionTime, StdDevExecutionTime, AvgMemoryUsage | Export-Csv -Path $resultsPath -NoTypeInformation -Encoding UTF8
Write-TestLog -Message "RÃ©sultats enregistrÃ©s dans : $resultsPath" -Level Success

# Afficher le rÃ©sumÃ©
Write-TestLog -Message "`nRÃ©sumÃ© des tests de performance :" -Level Info
$results | ForEach-Object {
    Write-TestLog -Message "  $($_.Name) : $($_.AvgExecutionTime.ToString("F2")) ms (Â±$($_.StdDevExecutionTime.ToString("F2")) ms)" -Level Info
}

# Nettoyer les fichiers de test
if (-not $SkipCleanup) {
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
}

# Retourner les rÃ©sultats
return $results

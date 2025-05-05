<#
.SYNOPSIS
    Tests de charge pour le Process Manager.

.DESCRIPTION
    Ce script exÃ©cute des tests de charge pour Ã©valuer la capacitÃ© du Process Manager
    Ã  gÃ©rer un grand nombre de gestionnaires et d'opÃ©rations simultanÃ©es.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER NumManagers
    Nombre de gestionnaires Ã  crÃ©er pour les tests de charge. Par dÃ©faut, 100.

.PARAMETER NumOperations
    Nombre d'opÃ©rations Ã  exÃ©cuter pour les tests de charge. Par dÃ©faut, 500.

.PARAMETER SkipCleanup
    Ne supprime pas les fichiers de test aprÃ¨s l'exÃ©cution.

.EXAMPLE
    .\Test-ProcessManagerLoad.ps1
    ExÃ©cute les tests de charge pour le Process Manager.

.EXAMPLE
    .\Test-ProcessManagerLoad.ps1 -ProjectRoot "D:\Projets\MonProjet" -NumManagers 200 -NumOperations 1000 -SkipCleanup
    ExÃ©cute les tests de charge avec 200 gestionnaires et 1000 opÃ©rations, et ne supprime pas les fichiers de test.

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
    [int]$NumManagers = 100,

    [Parameter(Mandatory = $false)]
    [int]$NumOperations = 500,

    [Parameter(Mandatory = $false)]
    [switch]$SkipCleanup
)

# DÃ©finir les chemins
$processManagerRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers\process-manager"
$modulesRoot = Join-Path -Path $processManagerRoot -ChildPath "modules"
$scriptsRoot = Join-Path -Path $processManagerRoot -ChildPath "scripts"
$testsRoot = Join-Path -Path $processManagerRoot -ChildPath "tests"
$processManagerScript = Join-Path -Path $scriptsRoot -ChildPath "process-manager.ps1"
$testDir = Join-Path -Path $testsRoot -ChildPath "load-tests"
$testConfigPath = Join-Path -Path $testDir -ChildPath "test-load.config.json"
$resultsPath = Join-Path -Path $testDir -ChildPath "load-results.csv"

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
    LogLevel = "Error" # Utiliser Error pour rÃ©duire la sortie console pendant les tests de charge
    LogPath = "logs/test-load"
    Managers = @{}
}
$testConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testConfigPath -Encoding UTF8

# CrÃ©er des gestionnaires de test pour les tests de charge
$testManagerTemplate = @"
<#
.SYNOPSIS
    Gestionnaire de test {0} pour les tests de charge.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisÃ© pour les tests de charge
    du Process Manager.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-LoadManager{0} {{
    [CmdletBinding()]
    param()
    
    Write-Host "DÃ©marrage du gestionnaire de charge {0}..."
}}

function Stop-LoadManager{0} {{
    [CmdletBinding()]
    param()
    
    Write-Host "ArrÃªt du gestionnaire de charge {0}..."
}}

function Get-LoadManager{0}Status {{
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
        Start-LoadManager{0}
    }}
    "Stop" {{
        Stop-LoadManager{0}
    }}
    "Status" {{
        Get-LoadManager{0}Status
    }}
    default {{
        Write-Host "Commande inconnue : `$Command"
    }}
}}
"@

Write-TestLog -Message "CrÃ©ation de $NumManagers gestionnaires de test pour les tests de charge..." -Level Info

$testManagers = @()
for ($i = 1; $i -le $NumManagers; $i++) {
    $managerName = "LoadManager$i"
    $managerPath = Join-Path -Path $testDir -ChildPath "load-manager-$i.ps1"
    $manifestPath = Join-Path -Path $testDir -ChildPath "load-manager-$i.manifest.json"
    
    # CrÃ©er le script du gestionnaire
    $managerContent = $testManagerTemplate -f $i
    Set-Content -Path $managerPath -Value $managerContent -Encoding UTF8
    
    # CrÃ©er le manifeste du gestionnaire
    $manifest = @{
        Name = $managerName
        Description = "Gestionnaire de test $i pour les tests de charge"
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
    
    # Afficher la progression
    if ($i % 10 -eq 0) {
        Write-Progress -Activity "CrÃ©ation des gestionnaires de test" -Status "$i/$NumManagers gestionnaires crÃ©Ã©s" -PercentComplete (($i / $NumManagers) * 100)
    }
}

Write-Progress -Activity "CrÃ©ation des gestionnaires de test" -Completed

# Enregistrer les gestionnaires de test
Write-TestLog -Message "Enregistrement des gestionnaires de test..." -Level Info

$registeredManagers = 0
foreach ($manager in $testManagers) {
    try {
        & $processManagerScript -Command Register -ManagerName $manager.Name -ManagerPath $manager.Path -ConfigPath $testConfigPath -Force -SkipValidation
        $registeredManagers++
        
        # Afficher la progression
        if ($registeredManagers % 10 -eq 0) {
            Write-Progress -Activity "Enregistrement des gestionnaires de test" -Status "$registeredManagers/$NumManagers gestionnaires enregistrÃ©s" -PercentComplete (($registeredManagers / $NumManagers) * 100)
        }
    } catch {
        Write-TestLog -Message "Erreur lors de l'enregistrement du gestionnaire $($manager.Name) : $_" -Level Error
    }
}

Write-Progress -Activity "Enregistrement des gestionnaires de test" -Completed
Write-TestLog -Message "$registeredManagers/$NumManagers gestionnaires enregistrÃ©s avec succÃ¨s." -Level Success

# DÃ©finir les opÃ©rations de test
$operations = @(
    @{
        Name = "Status"
        Operation = {
            param($ManagerName)
            & $processManagerScript -Command Status -ManagerName $ManagerName -ConfigPath $testConfigPath
        }
    },
    @{
        Name = "Run"
        Operation = {
            param($ManagerName)
            & $processManagerScript -Command Run -ManagerName $ManagerName -ManagerCommand "Status" -ConfigPath $testConfigPath
        }
    },
    @{
        Name = "Configure"
        Operation = {
            param($ManagerName)
            & $processManagerScript -Command Configure -ManagerName $ManagerName -Enabled $true -ConfigPath $testConfigPath
        }
    }
)

# ExÃ©cuter les opÃ©rations de test
Write-TestLog -Message "ExÃ©cution de $NumOperations opÃ©rations de test..." -Level Info

$results = @()
$successfulOperations = 0
$failedOperations = 0
$startTime = Get-Date

for ($i = 1; $i -le $NumOperations; $i++) {
    # SÃ©lectionner un gestionnaire et une opÃ©ration alÃ©atoires
    $manager = $testManagers | Get-Random
    $operation = $operations | Get-Random
    
    # Mesurer le temps d'exÃ©cution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        & $operation.Operation -ManagerName $manager.Name
        $stopwatch.Stop()
        $executionTime = $stopwatch.ElapsedMilliseconds
        
        $results += [PSCustomObject]@{
            OperationId = $i
            OperationType = $operation.Name
            ManagerName = $manager.Name
            ExecutionTime = $executionTime
            Success = $true
        }
        
        $successfulOperations++
    } catch {
        $stopwatch.Stop()
        $executionTime = $stopwatch.ElapsedMilliseconds
        
        $results += [PSCustomObject]@{
            OperationId = $i
            OperationType = $operation.Name
            ManagerName = $manager.Name
            ExecutionTime = $executionTime
            Success = $false
            Error = $_.Exception.Message
        }
        
        $failedOperations++
        Write-TestLog -Message "Erreur lors de l'opÃ©ration $($operation.Name) sur le gestionnaire $($manager.Name) : $_" -Level Error
    }
    
    # Afficher la progression
    if ($i % 10 -eq 0) {
        Write-Progress -Activity "ExÃ©cution des opÃ©rations de test" -Status "$i/$NumOperations opÃ©rations exÃ©cutÃ©es" -PercentComplete (($i / $NumOperations) * 100)
    }
}

$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalSeconds

Write-Progress -Activity "ExÃ©cution des opÃ©rations de test" -Completed

# Calculer les statistiques
$avgExecutionTime = ($results | Measure-Object -Property ExecutionTime -Average).Average
$minExecutionTime = ($results | Measure-Object -Property ExecutionTime -Minimum).Minimum
$maxExecutionTime = ($results | Measure-Object -Property ExecutionTime -Maximum).Maximum
$stdDevExecutionTime = [Math]::Sqrt(($results | ForEach-Object { [Math]::Pow($_.ExecutionTime - $avgExecutionTime, 2) } | Measure-Object -Average).Average)

$operationsPerSecond = $NumOperations / $totalDuration

# Enregistrer les rÃ©sultats dans un fichier CSV
$results | Export-Csv -Path $resultsPath -NoTypeInformation -Encoding UTF8
Write-TestLog -Message "RÃ©sultats dÃ©taillÃ©s enregistrÃ©s dans : $resultsPath" -Level Success

# Afficher le rÃ©sumÃ©
Write-TestLog -Message "`nRÃ©sumÃ© des tests de charge :" -Level Info
Write-TestLog -Message "  Nombre de gestionnaires : $NumManagers" -Level Info
Write-TestLog -Message "  Nombre d'opÃ©rations : $NumOperations" -Level Info
Write-TestLog -Message "  OpÃ©rations rÃ©ussies : $successfulOperations" -Level Success
Write-TestLog -Message "  OpÃ©rations Ã©chouÃ©es : $failedOperations" -Level Error
Write-TestLog -Message "  DurÃ©e totale : $($totalDuration.ToString("F2")) secondes" -Level Info
Write-TestLog -Message "  OpÃ©rations par seconde : $($operationsPerSecond.ToString("F2"))" -Level Info
Write-TestLog -Message "  Temps d'exÃ©cution moyen : $($avgExecutionTime.ToString("F2")) ms" -Level Info
Write-TestLog -Message "  Temps d'exÃ©cution min : $($minExecutionTime.ToString("F2")) ms" -Level Info
Write-TestLog -Message "  Temps d'exÃ©cution max : $($maxExecutionTime.ToString("F2")) ms" -Level Info
Write-TestLog -Message "  Ã‰cart-type : $($stdDevExecutionTime.ToString("F2")) ms" -Level Info

# Nettoyer les fichiers de test
if (-not $SkipCleanup) {
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
}

# Retourner les rÃ©sultats
return [PSCustomObject]@{
    NumManagers = $NumManagers
    NumOperations = $NumOperations
    SuccessfulOperations = $successfulOperations
    FailedOperations = $failedOperations
    TotalDuration = $totalDuration
    OperationsPerSecond = $operationsPerSecond
    AvgExecutionTime = $avgExecutionTime
    MinExecutionTime = $minExecutionTime
    MaxExecutionTime = $maxExecutionTime
    StdDevExecutionTime = $stdDevExecutionTime
    RawResults = $results
}

<#
.SYNOPSIS
    Tests de charge pour le Process Manager.

.DESCRIPTION
    Ce script exécute des tests de charge pour évaluer la capacité du Process Manager
    à gérer un grand nombre de gestionnaires et d'opérations simultanées.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par défaut, utilise le répertoire courant.

.PARAMETER NumManagers
    Nombre de gestionnaires à créer pour les tests de charge. Par défaut, 100.

.PARAMETER NumOperations
    Nombre d'opérations à exécuter pour les tests de charge. Par défaut, 500.

.PARAMETER SkipCleanup
    Ne supprime pas les fichiers de test après l'exécution.

.EXAMPLE
    .\Test-ProcessManagerLoad.ps1
    Exécute les tests de charge pour le Process Manager.

.EXAMPLE
    .\Test-ProcessManagerLoad.ps1 -ProjectRoot "D:\Projets\MonProjet" -NumManagers 200 -NumOperations 1000 -SkipCleanup
    Exécute les tests de charge avec 200 gestionnaires et 1000 opérations, et ne supprime pas les fichiers de test.

.NOTES
    Auteur: EMAIL_SENDER_1
    Version: 1.0
    Date de création: 2025-05-15
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

# Définir les chemins
$processManagerRoot = Join-Path -Path $ProjectRoot -ChildPath "development\managers\process-manager"
$modulesRoot = Join-Path -Path $processManagerRoot -ChildPath "modules"
$scriptsRoot = Join-Path -Path $processManagerRoot -ChildPath "scripts"
$testsRoot = Join-Path -Path $processManagerRoot -ChildPath "tests"
$processManagerScript = Join-Path -Path $scriptsRoot -ChildPath "process-manager.ps1"
$testDir = Join-Path -Path $testsRoot -ChildPath "load-tests"
$testConfigPath = Join-Path -Path $testDir -ChildPath "test-load.config.json"
$resultsPath = Join-Path -Path $testDir -ChildPath "load-results.csv"

# Fonction pour écrire des messages de journal
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
    
    # Définir la couleur en fonction du niveau
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

# Vérifier que le répertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-TestLog -Message "Le répertoire du projet n'existe pas : $ProjectRoot" -Level Error
    exit 1
}

# Vérifier que le répertoire du Process Manager existe
if (-not (Test-Path -Path $processManagerRoot -PathType Container)) {
    Write-TestLog -Message "Le répertoire du Process Manager n'existe pas : $processManagerRoot" -Level Error
    exit 1
}

# Vérifier que le script du Process Manager existe
if (-not (Test-Path -Path $processManagerScript -PathType Leaf)) {
    Write-TestLog -Message "Le script du Process Manager n'existe pas : $processManagerScript" -Level Error
    exit 1
}

# Créer un répertoire temporaire pour les tests
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier de configuration de test
$testConfig = @{
    Enabled = $true
    LogLevel = "Error" # Utiliser Error pour réduire la sortie console pendant les tests de charge
    LogPath = "logs/test-load"
    Managers = @{}
}
$testConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testConfigPath -Encoding UTF8

# Créer des gestionnaires de test pour les tests de charge
$testManagerTemplate = @"
<#
.SYNOPSIS
    Gestionnaire de test {0} pour les tests de charge.

.DESCRIPTION
    Ce script est un gestionnaire de test utilisé pour les tests de charge
    du Process Manager.
#>

param (
    [Parameter(Mandatory = `$false)]
    [string]`$Command = "Status"
)

function Start-LoadManager{0} {{
    [CmdletBinding()]
    param()
    
    Write-Host "Démarrage du gestionnaire de charge {0}..."
}}

function Stop-LoadManager{0} {{
    [CmdletBinding()]
    param()
    
    Write-Host "Arrêt du gestionnaire de charge {0}..."
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

# Exécuter la commande spécifiée
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

Write-TestLog -Message "Création de $NumManagers gestionnaires de test pour les tests de charge..." -Level Info

$testManagers = @()
for ($i = 1; $i -le $NumManagers; $i++) {
    $managerName = "LoadManager$i"
    $managerPath = Join-Path -Path $testDir -ChildPath "load-manager-$i.ps1"
    $manifestPath = Join-Path -Path $testDir -ChildPath "load-manager-$i.manifest.json"
    
    # Créer le script du gestionnaire
    $managerContent = $testManagerTemplate -f $i
    Set-Content -Path $managerPath -Value $managerContent -Encoding UTF8
    
    # Créer le manifeste du gestionnaire
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
        Write-Progress -Activity "Création des gestionnaires de test" -Status "$i/$NumManagers gestionnaires créés" -PercentComplete (($i / $NumManagers) * 100)
    }
}

Write-Progress -Activity "Création des gestionnaires de test" -Completed

# Enregistrer les gestionnaires de test
Write-TestLog -Message "Enregistrement des gestionnaires de test..." -Level Info

$registeredManagers = 0
foreach ($manager in $testManagers) {
    try {
        & $processManagerScript -Command Register -ManagerName $manager.Name -ManagerPath $manager.Path -ConfigPath $testConfigPath -Force -SkipValidation
        $registeredManagers++
        
        # Afficher la progression
        if ($registeredManagers % 10 -eq 0) {
            Write-Progress -Activity "Enregistrement des gestionnaires de test" -Status "$registeredManagers/$NumManagers gestionnaires enregistrés" -PercentComplete (($registeredManagers / $NumManagers) * 100)
        }
    } catch {
        Write-TestLog -Message "Erreur lors de l'enregistrement du gestionnaire $($manager.Name) : $_" -Level Error
    }
}

Write-Progress -Activity "Enregistrement des gestionnaires de test" -Completed
Write-TestLog -Message "$registeredManagers/$NumManagers gestionnaires enregistrés avec succès." -Level Success

# Définir les opérations de test
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

# Exécuter les opérations de test
Write-TestLog -Message "Exécution de $NumOperations opérations de test..." -Level Info

$results = @()
$successfulOperations = 0
$failedOperations = 0
$startTime = Get-Date

for ($i = 1; $i -le $NumOperations; $i++) {
    # Sélectionner un gestionnaire et une opération aléatoires
    $manager = $testManagers | Get-Random
    $operation = $operations | Get-Random
    
    # Mesurer le temps d'exécution
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
        Write-TestLog -Message "Erreur lors de l'opération $($operation.Name) sur le gestionnaire $($manager.Name) : $_" -Level Error
    }
    
    # Afficher la progression
    if ($i % 10 -eq 0) {
        Write-Progress -Activity "Exécution des opérations de test" -Status "$i/$NumOperations opérations exécutées" -PercentComplete (($i / $NumOperations) * 100)
    }
}

$endTime = Get-Date
$totalDuration = ($endTime - $startTime).TotalSeconds

Write-Progress -Activity "Exécution des opérations de test" -Completed

# Calculer les statistiques
$avgExecutionTime = ($results | Measure-Object -Property ExecutionTime -Average).Average
$minExecutionTime = ($results | Measure-Object -Property ExecutionTime -Minimum).Minimum
$maxExecutionTime = ($results | Measure-Object -Property ExecutionTime -Maximum).Maximum
$stdDevExecutionTime = [Math]::Sqrt(($results | ForEach-Object { [Math]::Pow($_.ExecutionTime - $avgExecutionTime, 2) } | Measure-Object -Average).Average)

$operationsPerSecond = $NumOperations / $totalDuration

# Enregistrer les résultats dans un fichier CSV
$results | Export-Csv -Path $resultsPath -NoTypeInformation -Encoding UTF8
Write-TestLog -Message "Résultats détaillés enregistrés dans : $resultsPath" -Level Success

# Afficher le résumé
Write-TestLog -Message "`nRésumé des tests de charge :" -Level Info
Write-TestLog -Message "  Nombre de gestionnaires : $NumManagers" -Level Info
Write-TestLog -Message "  Nombre d'opérations : $NumOperations" -Level Info
Write-TestLog -Message "  Opérations réussies : $successfulOperations" -Level Success
Write-TestLog -Message "  Opérations échouées : $failedOperations" -Level Error
Write-TestLog -Message "  Durée totale : $($totalDuration.ToString("F2")) secondes" -Level Info
Write-TestLog -Message "  Opérations par seconde : $($operationsPerSecond.ToString("F2"))" -Level Info
Write-TestLog -Message "  Temps d'exécution moyen : $($avgExecutionTime.ToString("F2")) ms" -Level Info
Write-TestLog -Message "  Temps d'exécution min : $($minExecutionTime.ToString("F2")) ms" -Level Info
Write-TestLog -Message "  Temps d'exécution max : $($maxExecutionTime.ToString("F2")) ms" -Level Info
Write-TestLog -Message "  Écart-type : $($stdDevExecutionTime.ToString("F2")) ms" -Level Info

# Nettoyer les fichiers de test
if (-not $SkipCleanup) {
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }
}

# Retourner les résultats
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

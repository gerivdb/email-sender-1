# Tests de performance à long terme pour le mode manager

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\mode-manager.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script mode-manager.ps1 est introuvable à l'emplacement : $scriptPath"
    exit 1
}

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Fonction pour mesurer le temps d'exécution
function Measure-ExecutionTime {
    param (
        [ScriptBlock]$ScriptBlock
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    & $ScriptBlock
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Fonction pour mesurer l'utilisation de la mémoire
function Measure-MemoryUsage {
    param (
        [ScriptBlock]$ScriptBlock
    )

    [System.GC]::Collect()
    $initialMemory = [System.GC]::GetTotalMemory($true)
    & $ScriptBlock
    [System.GC]::Collect()
    $finalMemory = [System.GC]::GetTotalMemory($true)
    return ($finalMemory - $initialMemory) / 1MB
}

# Fonction pour créer un fichier de roadmap
function Create-Roadmap {
    param (
        [string]$FilePath,
        [int]$TaskCount = 100
    )

    $content = "# Fichier de roadmap pour tests de performance à long terme`n`n"

    for ($i = 1; $i -le $TaskCount; $i++) {
        $content += "## Tâche $i`n`n"

        for ($j = 1; $j -le 5; $j++) {
            $content += "### Sous-tâche $i.$j`n`n"

            for ($k = 1; $k -le 3; $k++) {
                $content += "- [ ] Élément $i.$j.$k`n"
                $content += "  - Description de l'élément $i.$j.$k`n"
                $content += "  - Détails supplémentaires pour l'élément $i.$j.$k`n`n"
            }
        }
    }

    $content | Set-Content -Path $FilePath -Encoding UTF8
    return $FilePath
}

# Fonction pour créer une configuration
function Create-Config {
    param (
        [string]$FilePath,
        [int]$ModeCount = 10
    )

    $config = @{
        General = @{
            RoadmapPath        = "docs\plans\roadmap_complete_2.md"
            ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
            ReportPath         = "reports"
        }
        Modes   = @{}
    }

    # Ajouter les modes standard
    $standardModes = @("CHECK", "GRAN", "DEBUG", "TEST")
    foreach ($mode in $standardModes) {
        $config.Modes[$mode] = @{
            Enabled    = $true
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-$($mode.ToLower())-mode.ps1"
        }
    }

    # Ajouter des modes supplémentaires
    for ($i = 1; $i -le $ModeCount; $i++) {
        $modeName = "MODE$i"
        $config.Modes[$modeName] = @{
            Enabled     = ($i % 2 -eq 0) # Activer un mode sur deux
            ScriptPath  = Join-Path -Path $PSScriptRoot -ChildPath "mock-mode$i-mode.ps1"
            Description = "Mode de test $i"
            Parameters  = @{
                Param1 = "Value1"
                Param2 = "Value2"
                Param3 = "Value3"
            }
        }
    }

    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $FilePath -Encoding UTF8
    return $FilePath
}

# Fonction pour créer des scripts de mode simulés
function Create-MockScripts {
    param (
        [string]$TestDir,
        [int]$ModeCount = 10
    )

    $mockScripts = @()

    # Créer les scripts de mode standard
    $standardModes = @("check", "gran", "debug", "test")
    foreach ($mode in $standardModes) {
        $mockScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-$mode-mode.ps1"
        $mockScriptContent = @"
param (
    [Parameter(Mandatory = `$false)]
    [string]`$FilePath,

    [Parameter(Mandatory = `$false)]
    [string]`$TaskIdentifier,

    [Parameter(Mandatory = `$false)]
    [switch]`$Force,

    [Parameter(Mandatory = `$false)]
    [string]`$ConfigPath,

    [Parameter(Mandatory = `$false)]
    [string]`$WorkflowName
)

# Créer un fichier de sortie pour vérifier que le script a été exécuté
`$outputPath = Join-Path -Path "$TestDir" -ChildPath "$mode-mode-output.txt"
@"
FilePath : `$FilePath
TaskIdentifier : `$TaskIdentifier
Force : `$Force
ConfigPath : `$ConfigPath
WorkflowName : `$WorkflowName
"@ | Set-Content -Path `$outputPath -Encoding UTF8

        exit 0
        "@
        Set-Content -Path $mockScriptPath -Value $mockScriptContent -Encoding UTF8
        $mockScripts += $mockScriptPath
    }

    # Créer des scripts de mode supplémentaires
    for ($i = 1; $i -le $ModeCount; $i++) {
        $mockScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-mode$i-mode.ps1"
        $mockScriptContent = @'
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,

    [Parameter(Mandatory = $false)]
    [string]$WorkflowName,

    [Parameter(Mandatory = $false)]
    [string]$Param1,

    [Parameter(Mandatory = $false)]
    [string]$Param2,

    [Parameter(Mandatory = $false)]
    [string]$Param3
)

# Créer un fichier de sortie pour vérifier que le script a été exécuté
$outputPath = Join-Path -Path "TESTDIR_PLACEHOLDER" -ChildPath "mode{ 0 }-output.txt" -f $i
@"
        FilePath : $FilePath
        TaskIdentifier : $TaskIdentifier
        Force : $Force
        ConfigPath : $ConfigPath
        WorkflowName : $WorkflowName
        Param1 : $Param1
        Param2 : $Param2
        Param3 : $Param3
        "@ | Set-Content -Path $outputPath -Encoding UTF8

exit 0
'@
        Set-Content -Path $mockScriptPath -Value $mockScriptContent -Encoding UTF8
        $mockScripts += $mockScriptPath
    }

    return $mockScripts
}

# Créer un fichier de roadmap
$roadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
Create-Roadmap -FilePath $roadmapPath -TaskCount 100

# Créer une configuration
$configPath = Join-Path -Path $testDir -ChildPath "test-config.json"
Create-Config -FilePath $configPath -ModeCount 10

# Créer des scripts de mode simulés
$mockScripts = Create-MockScripts -TestDir $testDir -ModeCount 10

# Créer un fichier de résultats
$resultsPath = Join-Path -Path $testDir -ChildPath "long-term-performance-results.csv"
"Iteration, ExecutionTime, MemoryUsage" | Set-Content -Path $resultsPath -Encoding UTF8

# Test 1: Performance à long terme - Exécution répétée
Write-Host "Test 1: Performance à long terme - Exécution répétée" -ForegroundColor Cyan
$iterations = 20
$executionTimes = @()
$memoryUsages = @()

for ($i = 1; $i -le $iterations; $i++) {
    Write-Host "Itération $i/$iterations" -ForegroundColor Cyan

    # Mesurer le temps d'exécution
    $executionTime = Measure-ExecutionTime {
        & $scriptPath -Mode "CHECK" -FilePath $roadmapPath -TaskIdentifier "1.2.3" -ConfigPath $configPath
    }
    $executionTimes += $executionTime

    # Mesurer l'utilisation de la mémoire
    $memoryUsage = Measure-MemoryUsage {
        & $scriptPath -Mode "CHECK" -FilePath $roadmapPath -TaskIdentifier "1.2.3" -ConfigPath $configPath
    }
    $memoryUsages += $memoryUsage

    # Enregistrer les résultats
    "$i, $executionTime, $memoryUsage" | Add-Content -Path $resultsPath -Encoding UTF8

    Write-Host "Temps d'exécution : $executionTime ms" -ForegroundColor Cyan
    Write-Host "Utilisation de la mémoire : $memoryUsage MB" -ForegroundColor Cyan
}

# Analyser les résultats
$averageExecutionTime = ($executionTimes | Measure-Object -Average).Average
$minExecutionTime = ($executionTimes | Measure-Object -Minimum).Minimum
$maxExecutionTime = ($executionTimes | Measure-Object -Maximum).Maximum
$stdDevExecutionTime = [Math]::Sqrt(($executionTimes | ForEach-Object { [Math]::Pow($_ - $averageExecutionTime, 2) } | Measure-Object -Average).Average)

$averageMemoryUsage = ($memoryUsages | Measure-Object -Average).Average
$minMemoryUsage = ($memoryUsages | Measure-Object -Minimum).Minimum
$maxMemoryUsage = ($memoryUsages | Measure-Object -Maximum).Maximum
$stdDevMemoryUsage = [Math]::Sqrt(($memoryUsages | ForEach-Object { [Math]::Pow($_ - $averageMemoryUsage, 2) } | Measure-Object -Average).Average)

Write-Host "`nRésultats du test de performance à long terme :" -ForegroundColor Cyan
Write-Host "Nombre d'itérations : $iterations" -ForegroundColor Cyan
Write-Host "Temps d'exécution moyen : $averageExecutionTime ms" -ForegroundColor Cyan
Write-Host "Temps d'exécution minimum : $minExecutionTime ms" -ForegroundColor Cyan
Write-Host "Temps d'exécution maximum : $maxExecutionTime ms" -ForegroundColor Cyan
Write-Host "Écart-type du temps d'exécution : $stdDevExecutionTime ms" -ForegroundColor Cyan
Write-Host "Utilisation de la mémoire moyenne : $averageMemoryUsage MB" -ForegroundColor Cyan
Write-Host "Utilisation de la mémoire minimum : $minMemoryUsage MB" -ForegroundColor Cyan
Write-Host "Utilisation de la mémoire maximum : $maxMemoryUsage MB" -ForegroundColor Cyan
Write-Host "Écart-type de l'utilisation de la mémoire : $stdDevMemoryUsage MB" -ForegroundColor Cyan

# Vérifier si les performances se dégradent au fil du temps
$firstHalfExecutionTimes = $executionTimes[0..($iterations / 2 - 1)]
$secondHalfExecutionTimes = $executionTimes[($iterations / 2)..($iterations - 1)]
$firstHalfAverage = ($firstHalfExecutionTimes | Measure-Object -Average).Average
$secondHalfAverage = ($secondHalfExecutionTimes | Measure-Object -Average).Average

$firstHalfMemoryUsages = $memoryUsages[0..($iterations / 2 - 1)]
$secondHalfMemoryUsages = $memoryUsages[($iterations / 2)..($iterations - 1)]
$firstHalfMemoryAverage = ($firstHalfMemoryUsages | Measure-Object -Average).Average
$secondHalfMemoryAverage = ($secondHalfMemoryUsages | Measure-Object -Average).Average

Write-Host "`nAnalyse de la dégradation des performances :" -ForegroundColor Cyan
Write-Host "Temps d'exécution moyen (première moitié) : $firstHalfAverage ms" -ForegroundColor Cyan
Write-Host "Temps d'exécution moyen (seconde moitié) : $secondHalfAverage ms" -ForegroundColor Cyan
Write-Host "Différence : $($secondHalfAverage - $firstHalfAverage) ms" -ForegroundColor Cyan
Write-Host "Utilisation de la mémoire moyenne (première moitié) : $firstHalfMemoryAverage MB" -ForegroundColor Cyan
Write-Host "Utilisation de la mémoire moyenne (seconde moitié) : $secondHalfMemoryAverage MB" -ForegroundColor Cyan
Write-Host "Différence : $($secondHalfMemoryAverage - $firstHalfMemoryAverage) MB" -ForegroundColor Cyan

if ($secondHalfAverage -gt $firstHalfAverage * 1.1) {
    Write-Host "Test 1 échoué: Les performances se dégradent au fil du temps (temps d'exécution)" -ForegroundColor Red
} else {
    Write-Host "Test 1 réussi: Les performances ne se dégradent pas au fil du temps (temps d'exécution)" -ForegroundColor Green
}

if ($secondHalfMemoryAverage -gt $firstHalfMemoryAverage * 1.1) {
    Write-Host "Test 1 échoué: Les performances se dégradent au fil du temps (utilisation de la mémoire)" -ForegroundColor Red
} else {
    Write-Host "Test 1 réussi: Les performances ne se dégradent pas au fil du temps (utilisation de la mémoire)" -ForegroundColor Green
}

# Test 2: Performance à long terme - Modification du fichier de roadmap
Write-Host "`nTest 2: Performance à long terme - Modification du fichier de roadmap" -ForegroundColor Cyan
$iterations = 10
$executionTimes = @()
$memoryUsages = @()

for ($i = 1; $i -le $iterations; $i++) {
    Write-Host "Itération $i/$iterations" -ForegroundColor Cyan

    # Modifier le fichier de roadmap
    $modifiedRoadmapPath = Join-Path -Path $testDir -ChildPath "modified-roadmap-$i.md"
    Create-Roadmap -FilePath $modifiedRoadmapPath -TaskCount (100 + $i * 10)

    # Mesurer le temps d'exécution
        $executionTime = Measure-ExecutionTime {
            & $scriptPath -Mode "CHECK" -FilePath $modifiedRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $configPath
        }
        $executionTimes += $executionTime

        # Mesurer l'utilisation de la mémoire
        $memoryUsage = Measure-MemoryUsage {
            & $scriptPath -Mode "CHECK" -FilePath $modifiedRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $configPath
        }
        $memoryUsages += $memoryUsage

        Write-Host "Temps d'exécution : $executionTime ms" -ForegroundColor Cyan
        Write-Host "Utilisation de la mémoire : $memoryUsage MB" -ForegroundColor Cyan
    }

    # Analyser les résultats
    $averageExecutionTime = ($executionTimes | Measure-Object -Average).Average
    $minExecutionTime = ($executionTimes | Measure-Object -Minimum).Minimum
    $maxExecutionTime = ($executionTimes | Measure-Object -Maximum).Maximum
    $stdDevExecutionTime = [Math]::Sqrt(($executionTimes | ForEach-Object { [Math]::Pow($_ - $averageExecutionTime, 2) } | Measure-Object -Average).Average)

    $averageMemoryUsage = ($memoryUsages | Measure-Object -Average).Average
    $minMemoryUsage = ($memoryUsages | Measure-Object -Minimum).Minimum
    $maxMemoryUsage = ($memoryUsages | Measure-Object -Maximum).Maximum
    $stdDevMemoryUsage = [Math]::Sqrt(($memoryUsages | ForEach-Object { [Math]::Pow($_ - $averageMemoryUsage, 2) } | Measure-Object -Average).Average)

    Write-Host "`nRésultats du test de performance à long terme avec modification du fichier de roadmap :" -ForegroundColor Cyan
    Write-Host "Nombre d'itérations : $iterations" -ForegroundColor Cyan
    Write-Host "Temps d'exécution moyen : $averageExecutionTime ms" -ForegroundColor Cyan
    Write-Host "Temps d'exécution minimum : $minExecutionTime ms" -ForegroundColor Cyan
    Write-Host "Temps d'exécution maximum : $maxExecutionTime ms" -ForegroundColor Cyan
    Write-Host "Écart-type du temps d'exécution : $stdDevExecutionTime ms" -ForegroundColor Cyan
    Write-Host "Utilisation de la mémoire moyenne : $averageMemoryUsage MB" -ForegroundColor Cyan
    Write-Host "Utilisation de la mémoire minimum : $minMemoryUsage MB" -ForegroundColor Cyan
    Write-Host "Utilisation de la mémoire maximum : $maxMemoryUsage MB" -ForegroundColor Cyan
    Write-Host "Écart-type de l'utilisation de la mémoire : $stdDevMemoryUsage MB" -ForegroundColor Cyan

    # Vérifier si les performances se dégradent avec la taille du fichier de roadmap
    $correlation = [Math]::Abs(($executionTimes | ForEach-Object { $_ } | Measure-Object -Average).Average / ($executionTimes | ForEach-Object { $_ } | Measure-Object -Maximum).Maximum)

    if ($correlation -gt 0.8) {
        Write-Host "Test 2 réussi: Les performances ne se dégradent pas de manière significative avec la taille du fichier de roadmap" -ForegroundColor Green
    } else {
        Write-Host "Test 2 échoué: Les performances se dégradent de manière significative avec la taille du fichier de roadmap" -ForegroundColor Red
    }

    # Test 3: Performance à long terme - Exécution de différents modes
    Write-Host "`nTest 3: Performance à long terme - Exécution de différents modes" -ForegroundColor Cyan
    $modes = @("CHECK", "GRAN", "DEBUG", "TEST")
    $executionTimes = @{}
    $memoryUsages = @{}

    foreach ($mode in $modes) {
        Write-Host "Mode $mode" -ForegroundColor Cyan
        $modeExecutionTimes = @()
        $modeMemoryUsages = @()

        for ($i = 1; $i -le 5; $i++) {
            Write-Host "Itération $i/5" -ForegroundColor Cyan

            # Mesurer le temps d'exécution
            $executionTime = Measure-ExecutionTime {
                & $scriptPath -Mode $mode -FilePath $roadmapPath -TaskIdentifier "1.2.3" -ConfigPath $configPath
            }
            $modeExecutionTimes += $executionTime

            # Mesurer l'utilisation de la mémoire
            $memoryUsage = Measure-MemoryUsage {
                & $scriptPath -Mode $mode -FilePath $roadmapPath -TaskIdentifier "1.2.3" -ConfigPath $configPath
            }
            $modeMemoryUsages += $memoryUsage

            Write-Host "Temps d'exécution : $executionTime ms" -ForegroundColor Cyan
            Write-Host "Utilisation de la mémoire : $memoryUsage MB" -ForegroundColor Cyan
        }

        $executionTimes[$mode] = $modeExecutionTimes
        $memoryUsages[$mode] = $modeMemoryUsages
    }

    # Analyser les résultats
    Write-Host "`nRésultats du test de performance à long terme avec différents modes :" -ForegroundColor Cyan
    foreach ($mode in $modes) {
        $averageExecutionTime = ($executionTimes[$mode] | Measure-Object -Average).Average
        $averageMemoryUsage = ($memoryUsages[$mode] | Measure-Object -Average).Average

        Write-Host "Mode $mode :" -ForegroundColor Cyan
        Write-Host "Temps d'exécution moyen : $averageExecutionTime ms" -ForegroundColor Cyan
        Write-Host "Utilisation de la mémoire moyenne : $averageMemoryUsage MB" -ForegroundColor Cyan
    }

    # Vérifier si les performances sont cohérentes entre les modes
    $averageExecutionTimes = $modes | ForEach-Object { ($executionTimes[$_] | Measure-Object -Average).Average }
    $averageMemoryUsages = $modes | ForEach-Object { ($memoryUsages[$_] | Measure-Object -Average).Average }

    $maxExecutionTime = ($averageExecutionTimes | Measure-Object -Maximum).Maximum
    $minExecutionTime = ($averageExecutionTimes | Measure-Object -Minimum).Minimum
    $maxMemoryUsage = ($averageMemoryUsages | Measure-Object -Maximum).Maximum
    $minMemoryUsage = ($averageMemoryUsages | Measure-Object -Minimum).Minimum

    if ($maxExecutionTime -lt $minExecutionTime * 2) {
        Write-Host "Test 3 réussi: Les performances sont cohérentes entre les modes (temps d'exécution)" -ForegroundColor Green
    } else {
        Write-Host "Test 3 échoué: Les performances ne sont pas cohérentes entre les modes (temps d'exécution)" -ForegroundColor Red
    }

    if ($maxMemoryUsage -lt $minMemoryUsage * 2) {
        Write-Host "Test 3 réussi: Les performances sont cohérentes entre les modes (utilisation de la mémoire)" -ForegroundColor Green
    } else {
        Write-Host "Test 3 échoué: Les performances ne sont pas cohérentes entre les modes (utilisation de la mémoire)" -ForegroundColor Red
    }

    # Nettoyer les fichiers temporaires
    Write-Host "`nNettoyage des fichiers temporaires..." -ForegroundColor Cyan
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
    }

    foreach ($script in $mockScripts) {
        if (Test-Path -Path $script) {
            Remove-Item -Path $script -Force
        }
    }

    Write-Host "Tests terminés." -ForegroundColor Cyan

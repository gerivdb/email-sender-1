# Tests de charge pour le mode manager

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

# Fonction pour créer un grand fichier de roadmap
function Create-LargeRoadmap {
    param (
        [string]$FilePath,
        [int]$TaskCount = 1000
    )
    
    $content = "# Grand fichier de roadmap pour tests de charge`n`n"
    
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

# Fonction pour créer une configuration avec de nombreux modes
function Create-LargeConfig {
    param (
        [string]$FilePath,
        [int]$ModeCount = 100
    )
    
    $config = @{
        General = @{
            RoadmapPath = "docs\plans\roadmap_complete_2.md"
            ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
            ReportPath = "reports"
        }
        Modes = @{}
        Workflows = @{}
    }
    
    # Ajouter les modes standard
    $standardModes = @("CHECK", "GRAN", "DEBUG", "TEST")
    foreach ($mode in $standardModes) {
        $config.Modes[$mode] = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-$($mode.ToLower())-mode.ps1"
        }
    }
    
    # Ajouter des modes supplémentaires
    for ($i = 1; $i -le $ModeCount; $i++) {
        $modeName = "MODE$i"
        $config.Modes[$modeName] = @{
            Enabled = ($i % 2 -eq 0) # Activer un mode sur deux
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-mode$i-mode.ps1"
            Description = "Mode de test $i"
            Parameters = @{
                Param1 = "Value1"
                Param2 = "Value2"
                Param3 = "Value3"
            }
        }
    }
    
    # Ajouter des workflows complexes
    for ($i = 1; $i -le 20; $i++) {
        $workflowName = "Workflow$i"
        $modes = @()
        
        # Ajouter des modes aléatoires au workflow
        $modeCount = Get-Random -Minimum 3 -Maximum 10
        $allModes = @($standardModes) + (1..$ModeCount | ForEach-Object { "MODE$_" })
        
        for ($j = 0; $j -lt $modeCount; $j++) {
            $randomIndex = Get-Random -Minimum 0 -Maximum $allModes.Count
            $modes += $allModes[$randomIndex]
        }
        
        $config.Workflows[$workflowName] = @{
            Description = "Workflow de test $i"
            Modes = $modes
            AutoContinue = ($i % 2 -eq 0) # Activer AutoContinue un workflow sur deux
        }
    }
    
    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $FilePath -Encoding UTF8
    return $FilePath
}

# Fonction pour créer des scripts de mode simulés
function Create-MockScripts {
    param (
        [string]$TestDir,
        [int]$ModeCount = 100
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
    [string]`$WorkflowName,

    [Parameter(Mandatory = `$false)]
    [string]`$Param1,

    [Parameter(Mandatory = `$false)]
    [string]`$Param2,

    [Parameter(Mandatory = `$false)]
    [string]`$Param3
)

# Créer un fichier de sortie pour vérifier que le script a été exécuté
`$outputPath = Join-Path -Path "$TestDir" -ChildPath "mode$i-output.txt"
@"
FilePath : `$FilePath
TaskIdentifier : `$TaskIdentifier
Force : `$Force
ConfigPath : `$ConfigPath
WorkflowName : `$WorkflowName
Param1 : `$Param1
Param2 : `$Param2
Param3 : `$Param3
"@ | Set-Content -Path `$outputPath -Encoding UTF8

exit 0
"@
        Set-Content -Path $mockScriptPath -Value $mockScriptContent -Encoding UTF8
        $mockScripts += $mockScriptPath
    }
    
    return $mockScripts
}

# Créer un grand fichier de roadmap
$largeRoadmapPath = Join-Path -Path $testDir -ChildPath "large-roadmap.md"
Create-LargeRoadmap -FilePath $largeRoadmapPath -TaskCount 1000

# Créer une configuration avec de nombreux modes
$largeConfigPath = Join-Path -Path $testDir -ChildPath "large-config.json"
Create-LargeConfig -FilePath $largeConfigPath -ModeCount 100

# Créer des scripts de mode simulés
$mockScripts = Create-MockScripts -TestDir $testDir -ModeCount 100

# Test 1: Charge - Grand fichier de roadmap
Write-Host "Test 1: Charge - Grand fichier de roadmap" -ForegroundColor Cyan
$executionTime = Measure-ExecutionTime {
    & $scriptPath -Mode "CHECK" -FilePath $largeRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $largeConfigPath
}
Write-Host "Temps d'exécution avec un grand fichier de roadmap : $executionTime ms" -ForegroundColor Cyan
if ($executionTime -lt 10000) {
    Write-Host "Test 1 réussi: Le script a traité un grand fichier de roadmap en moins de 10 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 1 échoué: Le script a pris plus de 10 secondes pour traiter un grand fichier de roadmap" -ForegroundColor Red
}

# Test 2: Charge - Configuration avec de nombreux modes
Write-Host "Test 2: Charge - Configuration avec de nombreux modes" -ForegroundColor Cyan
$memoryUsage = Measure-MemoryUsage {
    & $scriptPath -ListModes -ConfigPath $largeConfigPath
}
Write-Host "Utilisation de la mémoire avec de nombreux modes : $memoryUsage MB" -ForegroundColor Cyan
if ($memoryUsage -lt 100) {
    Write-Host "Test 2 réussi: Le script a utilisé moins de 100 MB de mémoire avec de nombreux modes" -ForegroundColor Green
} else {
    Write-Host "Test 2 échoué: Le script a utilisé plus de 100 MB de mémoire avec de nombreux modes" -ForegroundColor Red
}

# Test 3: Charge - Exécution répétée
Write-Host "Test 3: Charge - Exécution répétée" -ForegroundColor Cyan
$executionTimes = @()
for ($i = 1; $i -le 10; $i++) {
    $executionTime = Measure-ExecutionTime {
        & $scriptPath -Mode "CHECK" -FilePath $largeRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $largeConfigPath
    }
    $executionTimes += $executionTime
    Write-Host "Exécution $i : $executionTime ms" -ForegroundColor Cyan
}
$averageTime = ($executionTimes | Measure-Object -Average).Average
Write-Host "Temps d'exécution moyen : $averageTime ms" -ForegroundColor Cyan
if ($averageTime -lt 10000) {
    Write-Host "Test 3 réussi: Le script a maintenu des performances acceptables lors d'exécutions répétées" -ForegroundColor Green
} else {
    Write-Host "Test 3 échoué: Le script n'a pas maintenu des performances acceptables lors d'exécutions répétées" -ForegroundColor Red
}

# Test 4: Charge - Exécution parallèle
Write-Host "Test 4: Charge - Exécution parallèle" -ForegroundColor Cyan
$parallelExecutionTime = Measure-ExecutionTime {
    1..5 | ForEach-Object -Parallel {
        $scriptPath = $using:scriptPath
        $largeRoadmapPath = $using:largeRoadmapPath
        $largeConfigPath = $using:largeConfigPath
        & $scriptPath -Mode "CHECK" -FilePath $largeRoadmapPath -TaskIdentifier "$_.1.1" -ConfigPath $largeConfigPath
    } -ThrottleLimit 5
}
Write-Host "Temps d'exécution parallèle : $parallelExecutionTime ms" -ForegroundColor Cyan
if ($parallelExecutionTime -lt 20000) {
    Write-Host "Test 4 réussi: Le script a géré l'exécution parallèle en moins de 20 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 4 échoué: Le script a pris plus de 20 secondes pour gérer l'exécution parallèle" -ForegroundColor Red
}

# Test 5: Charge - Chaîne de modes longue
Write-Host "Test 5: Charge - Chaîne de modes longue" -ForegroundColor Cyan
$longChain = "CHECK,GRAN,TEST,DEBUG"
for ($i = 1; $i -le 10; $i++) {
    $longChain += ",MODE$i"
}
$executionTime = Measure-ExecutionTime {
    & $scriptPath -Chain $longChain -FilePath $largeRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $largeConfigPath
}
Write-Host "Temps d'exécution avec une chaîne de modes longue : $executionTime ms" -ForegroundColor Cyan
if ($executionTime -lt 30000) {
    Write-Host "Test 5 réussi: Le script a exécuté une chaîne de modes longue en moins de 30 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 5 échoué: Le script a pris plus de 30 secondes pour exécuter une chaîne de modes longue" -ForegroundColor Red
}

# Test 6: Charge - Tâches profondes
Write-Host "Test 6: Charge - Tâches profondes" -ForegroundColor Cyan
$deepTaskId = "1000.5.3"
$executionTime = Measure-ExecutionTime {
    & $scriptPath -Mode "CHECK" -FilePath $largeRoadmapPath -TaskIdentifier $deepTaskId -ConfigPath $largeConfigPath
}
Write-Host "Temps d'exécution avec une tâche profonde : $executionTime ms" -ForegroundColor Cyan
if ($executionTime -lt 10000) {
    Write-Host "Test 6 réussi: Le script a traité une tâche profonde en moins de 10 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 6 échoué: Le script a pris plus de 10 secondes pour traiter une tâche profonde" -ForegroundColor Red
}

# Test 7: Charge - Fichier de roadmap très grand
Write-Host "Test 7: Charge - Fichier de roadmap très grand" -ForegroundColor Cyan
$veryLargeRoadmapPath = Join-Path -Path $testDir -ChildPath "very-large-roadmap.md"
Create-LargeRoadmap -FilePath $veryLargeRoadmapPath -TaskCount 5000
$executionTime = Measure-ExecutionTime {
    & $scriptPath -Mode "CHECK" -FilePath $veryLargeRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $largeConfigPath
}
Write-Host "Temps d'exécution avec un fichier de roadmap très grand : $executionTime ms" -ForegroundColor Cyan
if ($executionTime -lt 30000) {
    Write-Host "Test 7 réussi: Le script a traité un fichier de roadmap très grand en moins de 30 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 7 échoué: Le script a pris plus de 30 secondes pour traiter un fichier de roadmap très grand" -ForegroundColor Red
}

# Test 8: Charge - Configuration très grande
Write-Host "Test 8: Charge - Configuration très grande" -ForegroundColor Cyan
$veryLargeConfigPath = Join-Path -Path $testDir -ChildPath "very-large-config.json"
Create-LargeConfig -FilePath $veryLargeConfigPath -ModeCount 500
$executionTime = Measure-ExecutionTime {
    & $scriptPath -ListModes -ConfigPath $veryLargeConfigPath
}
Write-Host "Temps d'exécution avec une configuration très grande : $executionTime ms" -ForegroundColor Cyan
if ($executionTime -lt 10000) {
    Write-Host "Test 8 réussi: Le script a traité une configuration très grande en moins de 10 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 8 échoué: Le script a pris plus de 10 secondes pour traiter une configuration très grande" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
Write-Host "Nettoyage des fichiers temporaires..." -ForegroundColor Cyan
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

foreach ($script in $mockScripts) {
    if (Test-Path -Path $script) {
        Remove-Item -Path $script -Force
    }
}

Write-Host "Tests terminés." -ForegroundColor Cyan

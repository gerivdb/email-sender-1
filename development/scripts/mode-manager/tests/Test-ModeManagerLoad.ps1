# Tests de charge pour le mode manager

# DÃ©finir le chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\mode-manager.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script mode-manager.ps1 est introuvable Ã  l'emplacement : $scriptPath"
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Fonction pour mesurer le temps d'exÃ©cution
function Measure-ExecutionTime {
    param (
        [ScriptBlock]$ScriptBlock
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    & $ScriptBlock
    $stopwatch.Stop()
    return $stopwatch.ElapsedMilliseconds
}

# Fonction pour mesurer l'utilisation de la mÃ©moire
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

# Fonction pour crÃ©er un grand fichier de roadmap
function Create-LargeRoadmap {
    param (
        [string]$FilePath,
        [int]$TaskCount = 1000
    )
    
    $content = "# Grand fichier de roadmap pour tests de charge`n`n"
    
    for ($i = 1; $i -le $TaskCount; $i++) {
        $content += "## TÃ¢che $i`n`n"
        
        for ($j = 1; $j -le 5; $j++) {
            $content += "### Sous-tÃ¢che $i.$j`n`n"
            
            for ($k = 1; $k -le 3; $k++) {
                $content += "- [ ] Ã‰lÃ©ment $i.$j.$k`n"
                $content += "  - Description de l'Ã©lÃ©ment $i.$j.$k`n"
                $content += "  - DÃ©tails supplÃ©mentaires pour l'Ã©lÃ©ment $i.$j.$k`n`n"
            }
        }
    }
    
    $content | Set-Content -Path $FilePath -Encoding UTF8
    return $FilePath
}

# Fonction pour crÃ©er une configuration avec de nombreux modes
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
    
    # Ajouter des modes supplÃ©mentaires
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
        
        # Ajouter des modes alÃ©atoires au workflow
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

# Fonction pour crÃ©er des scripts de mode simulÃ©s
function Create-MockScripts {
    param (
        [string]$TestDir,
        [int]$ModeCount = 100
    )
    
    $mockScripts = @()
    
    # CrÃ©er les scripts de mode standard
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

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
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
    
    # CrÃ©er des scripts de mode supplÃ©mentaires
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

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
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

# CrÃ©er un grand fichier de roadmap
$largeRoadmapPath = Join-Path -Path $testDir -ChildPath "large-roadmap.md"
Create-LargeRoadmap -FilePath $largeRoadmapPath -TaskCount 1000

# CrÃ©er une configuration avec de nombreux modes
$largeConfigPath = Join-Path -Path $testDir -ChildPath "large-config.json"
Create-LargeConfig -FilePath $largeConfigPath -ModeCount 100

# CrÃ©er des scripts de mode simulÃ©s
$mockScripts = Create-MockScripts -TestDir $testDir -ModeCount 100

# Test 1: Charge - Grand fichier de roadmap
Write-Host "Test 1: Charge - Grand fichier de roadmap" -ForegroundColor Cyan
$executionTime = Measure-ExecutionTime {
    & $scriptPath -Mode "CHECK" -FilePath $largeRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $largeConfigPath
}
Write-Host "Temps d'exÃ©cution avec un grand fichier de roadmap : $executionTime ms" -ForegroundColor Cyan
if ($executionTime -lt 10000) {
    Write-Host "Test 1 rÃ©ussi: Le script a traitÃ© un grand fichier de roadmap en moins de 10 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 1 Ã©chouÃ©: Le script a pris plus de 10 secondes pour traiter un grand fichier de roadmap" -ForegroundColor Red
}

# Test 2: Charge - Configuration avec de nombreux modes
Write-Host "Test 2: Charge - Configuration avec de nombreux modes" -ForegroundColor Cyan
$memoryUsage = Measure-MemoryUsage {
    & $scriptPath -ListModes -ConfigPath $largeConfigPath
}
Write-Host "Utilisation de la mÃ©moire avec de nombreux modes : $memoryUsage MB" -ForegroundColor Cyan
if ($memoryUsage -lt 100) {
    Write-Host "Test 2 rÃ©ussi: Le script a utilisÃ© moins de 100 MB de mÃ©moire avec de nombreux modes" -ForegroundColor Green
} else {
    Write-Host "Test 2 Ã©chouÃ©: Le script a utilisÃ© plus de 100 MB de mÃ©moire avec de nombreux modes" -ForegroundColor Red
}

# Test 3: Charge - ExÃ©cution rÃ©pÃ©tÃ©e
Write-Host "Test 3: Charge - ExÃ©cution rÃ©pÃ©tÃ©e" -ForegroundColor Cyan
$executionTimes = @()
for ($i = 1; $i -le 10; $i++) {
    $executionTime = Measure-ExecutionTime {
        & $scriptPath -Mode "CHECK" -FilePath $largeRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $largeConfigPath
    }
    $executionTimes += $executionTime
    Write-Host "ExÃ©cution $i : $executionTime ms" -ForegroundColor Cyan
}
$averageTime = ($executionTimes | Measure-Object -Average).Average
Write-Host "Temps d'exÃ©cution moyen : $averageTime ms" -ForegroundColor Cyan
if ($averageTime -lt 10000) {
    Write-Host "Test 3 rÃ©ussi: Le script a maintenu des performances acceptables lors d'exÃ©cutions rÃ©pÃ©tÃ©es" -ForegroundColor Green
} else {
    Write-Host "Test 3 Ã©chouÃ©: Le script n'a pas maintenu des performances acceptables lors d'exÃ©cutions rÃ©pÃ©tÃ©es" -ForegroundColor Red
}

# Test 4: Charge - ExÃ©cution parallÃ¨le
Write-Host "Test 4: Charge - ExÃ©cution parallÃ¨le" -ForegroundColor Cyan
$parallelExecutionTime = Measure-ExecutionTime {
    1..5 | ForEach-Object -Parallel {
        $scriptPath = $using:scriptPath
        $largeRoadmapPath = $using:largeRoadmapPath
        $largeConfigPath = $using:largeConfigPath
        & $scriptPath -Mode "CHECK" -FilePath $largeRoadmapPath -TaskIdentifier "$_.1.1" -ConfigPath $largeConfigPath
    } -ThrottleLimit 5
}
Write-Host "Temps d'exÃ©cution parallÃ¨le : $parallelExecutionTime ms" -ForegroundColor Cyan
if ($parallelExecutionTime -lt 20000) {
    Write-Host "Test 4 rÃ©ussi: Le script a gÃ©rÃ© l'exÃ©cution parallÃ¨le en moins de 20 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 4 Ã©chouÃ©: Le script a pris plus de 20 secondes pour gÃ©rer l'exÃ©cution parallÃ¨le" -ForegroundColor Red
}

# Test 5: Charge - ChaÃ®ne de modes longue
Write-Host "Test 5: Charge - ChaÃ®ne de modes longue" -ForegroundColor Cyan
$longChain = "CHECK,GRAN,TEST,DEBUG"
for ($i = 1; $i -le 10; $i++) {
    $longChain += ",MODE$i"
}
$executionTime = Measure-ExecutionTime {
    & $scriptPath -Chain $longChain -FilePath $largeRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $largeConfigPath
}
Write-Host "Temps d'exÃ©cution avec une chaÃ®ne de modes longue : $executionTime ms" -ForegroundColor Cyan
if ($executionTime -lt 30000) {
    Write-Host "Test 5 rÃ©ussi: Le script a exÃ©cutÃ© une chaÃ®ne de modes longue en moins de 30 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 5 Ã©chouÃ©: Le script a pris plus de 30 secondes pour exÃ©cuter une chaÃ®ne de modes longue" -ForegroundColor Red
}

# Test 6: Charge - TÃ¢ches profondes
Write-Host "Test 6: Charge - TÃ¢ches profondes" -ForegroundColor Cyan
$deepTaskId = "1000.5.3"
$executionTime = Measure-ExecutionTime {
    & $scriptPath -Mode "CHECK" -FilePath $largeRoadmapPath -TaskIdentifier $deepTaskId -ConfigPath $largeConfigPath
}
Write-Host "Temps d'exÃ©cution avec une tÃ¢che profonde : $executionTime ms" -ForegroundColor Cyan
if ($executionTime -lt 10000) {
    Write-Host "Test 6 rÃ©ussi: Le script a traitÃ© une tÃ¢che profonde en moins de 10 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 6 Ã©chouÃ©: Le script a pris plus de 10 secondes pour traiter une tÃ¢che profonde" -ForegroundColor Red
}

# Test 7: Charge - Fichier de roadmap trÃ¨s grand
Write-Host "Test 7: Charge - Fichier de roadmap trÃ¨s grand" -ForegroundColor Cyan
$veryLargeRoadmapPath = Join-Path -Path $testDir -ChildPath "very-large-roadmap.md"
Create-LargeRoadmap -FilePath $veryLargeRoadmapPath -TaskCount 5000
$executionTime = Measure-ExecutionTime {
    & $scriptPath -Mode "CHECK" -FilePath $veryLargeRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $largeConfigPath
}
Write-Host "Temps d'exÃ©cution avec un fichier de roadmap trÃ¨s grand : $executionTime ms" -ForegroundColor Cyan
if ($executionTime -lt 30000) {
    Write-Host "Test 7 rÃ©ussi: Le script a traitÃ© un fichier de roadmap trÃ¨s grand en moins de 30 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 7 Ã©chouÃ©: Le script a pris plus de 30 secondes pour traiter un fichier de roadmap trÃ¨s grand" -ForegroundColor Red
}

# Test 8: Charge - Configuration trÃ¨s grande
Write-Host "Test 8: Charge - Configuration trÃ¨s grande" -ForegroundColor Cyan
$veryLargeConfigPath = Join-Path -Path $testDir -ChildPath "very-large-config.json"
Create-LargeConfig -FilePath $veryLargeConfigPath -ModeCount 500
$executionTime = Measure-ExecutionTime {
    & $scriptPath -ListModes -ConfigPath $veryLargeConfigPath
}
Write-Host "Temps d'exÃ©cution avec une configuration trÃ¨s grande : $executionTime ms" -ForegroundColor Cyan
if ($executionTime -lt 10000) {
    Write-Host "Test 8 rÃ©ussi: Le script a traitÃ© une configuration trÃ¨s grande en moins de 10 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 8 Ã©chouÃ©: Le script a pris plus de 10 secondes pour traiter une configuration trÃ¨s grande" -ForegroundColor Red
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

Write-Host "Tests terminÃ©s." -ForegroundColor Cyan

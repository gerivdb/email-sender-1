# Tests de performance avancÃ©s pour le mode manager

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
    
    $content = "# Grand fichier de roadmap pour tests de performance`n`n"
    
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
function Create-ComplexConfig {
    param (
        [string]$FilePath,
        [int]$ModeCount = 20
    )
    
    $config = @{
        General = @{
            RoadmapPath = "docs\plans\roadmap_complete_2.md"
            ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
            ReportPath = "reports"
            LogPath = "logs"
            DefaultEncoding = "UTF8-BOM"
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
    for ($i = 1; $i -le 5; $i++) {
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

# CrÃ©er des scripts de mode simulÃ©s
function Create-MockScripts {
    param (
        [string]$TestDir,
        [int]$ModeCount = 20
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

Write-Host "Mode $($mode.ToUpper()) exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : `$FilePath"
Write-Host "TaskIdentifier : `$TaskIdentifier"
Write-Host "Force : `$Force"
Write-Host "ConfigPath : `$ConfigPath"
Write-Host "WorkflowName : `$WorkflowName"

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
`$outputPath = Join-Path -Path "$TestDir" -ChildPath "$mode-mode-output.txt"
@"
FilePath : `$FilePath
TaskIdentifier : `$TaskIdentifier
Force : `$Force
ConfigPath : `$ConfigPath
WorkflowName : `$WorkflowName
"@ | Set-Content -Path `$outputPath -Encoding UTF8

# Simuler un traitement long pour les tests de performance
Start-Sleep -Milliseconds 50

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

Write-Host "Mode MODE$i exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : `$FilePath"
Write-Host "TaskIdentifier : `$TaskIdentifier"
Write-Host "Force : `$Force"
Write-Host "ConfigPath : `$ConfigPath"
Write-Host "WorkflowName : `$WorkflowName"
Write-Host "Param1 : `$Param1"
Write-Host "Param2 : `$Param2"
Write-Host "Param3 : `$Param3"

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

# Simuler un traitement long pour les tests de performance
Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 100)

exit 0
"@
        Set-Content -Path $mockScriptPath -Value $mockScriptContent -Encoding UTF8
        $mockScripts += $mockScriptPath
    }
    
    return $mockScripts
}

# CrÃ©er un grand fichier de roadmap
$largeRoadmapPath = Join-Path -Path $testDir -ChildPath "large-roadmap.md"
Create-LargeRoadmap -FilePath $largeRoadmapPath -TaskCount 100

# CrÃ©er une configuration complexe
$complexConfigPath = Join-Path -Path $testDir -ChildPath "complex-config.json"
Create-ComplexConfig -FilePath $complexConfigPath -ModeCount 20

# CrÃ©er des scripts de mode simulÃ©s
$mockScripts = Create-MockScripts -TestDir $testDir -ModeCount 20

# Test 1: Performance avec un grand fichier de roadmap
Write-Host "Test 1: Performance avec un grand fichier de roadmap" -ForegroundColor Cyan
$executionTime = Measure-ExecutionTime {
    & $scriptPath -Mode "CHECK" -FilePath $largeRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $complexConfigPath
}
Write-Host "Temps d'exÃ©cution avec un grand fichier de roadmap : $executionTime ms" -ForegroundColor Cyan
if ($executionTime -lt 5000) {
    Write-Host "Test 1 rÃ©ussi: Le script a traitÃ© un grand fichier de roadmap en moins de 5 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 1 Ã©chouÃ©: Le script a pris plus de 5 secondes pour traiter un grand fichier de roadmap" -ForegroundColor Red
}

# Test 2: Performance avec de nombreux modes
Write-Host "Test 2: Performance avec de nombreux modes" -ForegroundColor Cyan
$memoryUsage = Measure-MemoryUsage {
    & $scriptPath -ListModes -ConfigPath $complexConfigPath
}
Write-Host "Utilisation de la mÃ©moire avec de nombreux modes : $memoryUsage MB" -ForegroundColor Cyan
if ($memoryUsage -lt 50) {
    Write-Host "Test 2 rÃ©ussi: Le script a utilisÃ© moins de 50 MB de mÃ©moire avec de nombreux modes" -ForegroundColor Green
} else {
    Write-Host "Test 2 Ã©chouÃ©: Le script a utilisÃ© plus de 50 MB de mÃ©moire avec de nombreux modes" -ForegroundColor Red
}

# Test 3: Performance avec une chaÃ®ne de modes
Write-Host "Test 3: Performance avec une chaÃ®ne de modes" -ForegroundColor Cyan
$executionTime = Measure-ExecutionTime {
    & $scriptPath -Chain "CHECK,GRAN,TEST" -FilePath $largeRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $complexConfigPath
}
Write-Host "Temps d'exÃ©cution avec une chaÃ®ne de modes : $executionTime ms" -ForegroundColor Cyan
if ($executionTime -lt 10000) {
    Write-Host "Test 3 rÃ©ussi: Le script a exÃ©cutÃ© une chaÃ®ne de modes en moins de 10 secondes" -ForegroundColor Green
} else {
    Write-Host "Test 3 Ã©chouÃ©: Le script a pris plus de 10 secondes pour exÃ©cuter une chaÃ®ne de modes" -ForegroundColor Red
}

# Test 4: Performance avec des tÃ¢ches spÃ©cifiques
Write-Host "Test 4: Performance avec des tÃ¢ches spÃ©cifiques" -ForegroundColor Cyan
$executionTimes = @()
for ($i = 1; $i -le 5; $i++) {
    $taskId = "$i.1.1"
    $executionTime = Measure-ExecutionTime {
        & $scriptPath -Mode "CHECK" -FilePath $largeRoadmapPath -TaskIdentifier $taskId -ConfigPath $complexConfigPath
    }
    $executionTimes += $executionTime
    Write-Host "Temps d'exÃ©cution pour la tÃ¢che $taskId : $executionTime ms" -ForegroundColor Cyan
}
$averageTime = ($executionTimes | Measure-Object -Average).Average
Write-Host "Temps d'exÃ©cution moyen pour des tÃ¢ches spÃ©cifiques : $averageTime ms" -ForegroundColor Cyan
if ($averageTime -lt 2000) {
    Write-Host "Test 4 rÃ©ussi: Le script a traitÃ© des tÃ¢ches spÃ©cifiques en moins de 2 secondes en moyenne" -ForegroundColor Green
} else {
    Write-Host "Test 4 Ã©chouÃ©: Le script a pris plus de 2 secondes en moyenne pour traiter des tÃ¢ches spÃ©cifiques" -ForegroundColor Red
}

# Test 5: Performance avec des exÃ©cutions rÃ©pÃ©tÃ©es
Write-Host "Test 5: Performance avec des exÃ©cutions rÃ©pÃ©tÃ©es" -ForegroundColor Cyan
$executionTimes = @()
for ($i = 1; $i -le 5; $i++) {
    $executionTime = Measure-ExecutionTime {
        & $scriptPath -Mode "CHECK" -FilePath $largeRoadmapPath -TaskIdentifier "1.1.1" -ConfigPath $complexConfigPath
    }
    $executionTimes += $executionTime
    Write-Host "Temps d'exÃ©cution pour l'exÃ©cution $i : $executionTime ms" -ForegroundColor Cyan
}
$firstTime = $executionTimes[0]
$averageTime = ($executionTimes | Select-Object -Skip 1 | Measure-Object -Average).Average
Write-Host "Temps d'exÃ©cution pour la premiÃ¨re exÃ©cution : $firstTime ms" -ForegroundColor Cyan
Write-Host "Temps d'exÃ©cution moyen pour les exÃ©cutions suivantes : $averageTime ms" -ForegroundColor Cyan
if ($averageTime -lt $firstTime) {
    Write-Host "Test 5 rÃ©ussi: Les exÃ©cutions suivantes sont plus rapides que la premiÃ¨re exÃ©cution" -ForegroundColor Green
} else {
    Write-Host "Test 5 Ã©chouÃ©: Les exÃ©cutions suivantes ne sont pas plus rapides que la premiÃ¨re exÃ©cution" -ForegroundColor Red
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

# Tests de performance Ã  long terme simplifiÃ©s pour le mode manager

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

# CrÃ©er un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
$roadmapContent = "# Test Roadmap`n`n"
for ($i = 1; $i -le 100; $i++) {
    $roadmapContent += "## TÃ¢che $i`n`n"
    for ($j = 1; $j -le 5; $j++) {
        $roadmapContent += "### Sous-tÃ¢che $i.$j`n`n"
        for ($k = 1; $k -le 3; $k++) {
            $roadmapContent += "- [ ] Ã‰lÃ©ment $i.$j.$k`n"
            $roadmapContent += "  - Description de l'Ã©lÃ©ment $i.$j.$k`n"
            $roadmapContent += "  - DÃ©tails supplÃ©mentaires pour l'Ã©lÃ©ment $i.$j.$k`n`n"
        }
    }
}
$roadmapContent | Set-Content -Path $testRoadmapPath -Encoding UTF8

# CrÃ©er un fichier de configuration pour les tests
$configPath = Join-Path -Path $testDir -ChildPath "test-config.json"
@{
    General = @{
        RoadmapPath = "docs\plans\roadmap_complete_2.md"
        ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
        ReportPath = "reports"
    }
    Modes = @{
        Check = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
        }
        Gran = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-gran-mode.ps1"
        }
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $configPath -Encoding UTF8

# CrÃ©er des scripts de mode simulÃ©s
$mockCheckModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
$mockCheckContent = @'
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false)]
    [switch]$CheckActiveDocument,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
)

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "check-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ActiveDocumentPath : $ActiveDocumentPath
CheckActiveDocument : $CheckActiveDocument
ConfigPath : $ConfigPath
"@ | Set-Content -Path $outputPath -Encoding UTF8

exit 0
'@
Set-Content -Path $mockCheckModePath -Value $mockCheckContent -Encoding UTF8

$mockGranModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-gran-mode.ps1"
$mockGranContent = @'
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath
)

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "gran-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ConfigPath : $ConfigPath
"@ | Set-Content -Path $outputPath -Encoding UTF8

exit 0
'@
Set-Content -Path $mockGranModePath -Value $mockGranContent -Encoding UTF8

# CrÃ©er un fichier de rÃ©sultats
$resultsPath = Join-Path -Path $testDir -ChildPath "long-term-performance-results.csv"
"Iteration,ExecutionTime" | Set-Content -Path $resultsPath -Encoding UTF8

# Test 1: Performance Ã  long terme - ExÃ©cution rÃ©pÃ©tÃ©e
Write-Host "Test 1: Performance Ã  long terme - ExÃ©cution rÃ©pÃ©tÃ©e" -ForegroundColor Cyan
$iterations = 10
$executionTimes = @()

for ($i = 1; $i -le $iterations; $i++) {
    Write-Host "ItÃ©ration $i/$iterations" -ForegroundColor Cyan
    
    # Mesurer le temps d'exÃ©cution
    $executionTime = Measure-ExecutionTime {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $configPath
    }
    $executionTimes += $executionTime
    
    # Enregistrer les rÃ©sultats
    "$i,$executionTime" | Add-Content -Path $resultsPath -Encoding UTF8
    
    Write-Host "Temps d'exÃ©cution : $executionTime ms" -ForegroundColor Cyan
}

# Analyser les rÃ©sultats
$averageExecutionTime = ($executionTimes | Measure-Object -Average).Average
$minExecutionTime = ($executionTimes | Measure-Object -Minimum).Minimum
$maxExecutionTime = ($executionTimes | Measure-Object -Maximum).Maximum
$stdDevExecutionTime = [Math]::Sqrt(($executionTimes | ForEach-Object { [Math]::Pow($_ - $averageExecutionTime, 2) } | Measure-Object -Average).Average)

Write-Host "`nRÃ©sultats du test de performance Ã  long terme :" -ForegroundColor Cyan
Write-Host "Nombre d'itÃ©rations : $iterations" -ForegroundColor Cyan
Write-Host "Temps d'exÃ©cution moyen : $averageExecutionTime ms" -ForegroundColor Cyan
Write-Host "Temps d'exÃ©cution minimum : $minExecutionTime ms" -ForegroundColor Cyan
Write-Host "Temps d'exÃ©cution maximum : $maxExecutionTime ms" -ForegroundColor Cyan
Write-Host "Ã‰cart-type du temps d'exÃ©cution : $stdDevExecutionTime ms" -ForegroundColor Cyan

# VÃ©rifier si les performances se dÃ©gradent au fil du temps
$firstHalfExecutionTimes = $executionTimes[0..($iterations / 2 - 1)]
$secondHalfExecutionTimes = $executionTimes[($iterations / 2)..($iterations - 1)]
$firstHalfAverage = ($firstHalfExecutionTimes | Measure-Object -Average).Average
$secondHalfAverage = ($secondHalfExecutionTimes | Measure-Object -Average).Average

Write-Host "`nAnalyse de la dÃ©gradation des performances :" -ForegroundColor Cyan
Write-Host "Temps d'exÃ©cution moyen (premiÃ¨re moitiÃ©) : $firstHalfAverage ms" -ForegroundColor Cyan
Write-Host "Temps d'exÃ©cution moyen (seconde moitiÃ©) : $secondHalfAverage ms" -ForegroundColor Cyan
Write-Host "DiffÃ©rence : $($secondHalfAverage - $firstHalfAverage) ms" -ForegroundColor Cyan

if ($secondHalfAverage -gt $firstHalfAverage * 1.1) {
    Write-Host "Test 1 Ã©chouÃ©: Les performances se dÃ©gradent au fil du temps" -ForegroundColor Red
} else {
    Write-Host "Test 1 rÃ©ussi: Les performances ne se dÃ©gradent pas au fil du temps" -ForegroundColor Green
}

# Nettoyer les fichiers temporaires
Write-Host "`nNettoyage des fichiers temporaires..." -ForegroundColor Cyan
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

$mockFiles = @(
    "mock-check-mode.ps1",
    "mock-gran-mode.ps1"
)

foreach ($file in $mockFiles) {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
    if (Test-Path -Path $filePath) {
        Remove-Item -Path $filePath -Force
    }
}

Write-Host "Tests terminÃ©s." -ForegroundColor Cyan

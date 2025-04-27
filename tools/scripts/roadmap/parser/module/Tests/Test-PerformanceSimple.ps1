#
# Test-PerformanceSimple.ps1
#
# Script pour tester les fonctions de mesure de performance de maniÃ¨re simple
#

# Importer les fonctions
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"
$measurePath = Join-Path -Path $publicPath -ChildPath "Measure-RoadmapExecutionTime.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $measurePath)) {
    Write-Error "Le fichier Measure-RoadmapExecutionTime.ps1 est introuvable Ã  l'emplacement : $measurePath"
    exit 1
}

# Importer la fonction
. $measurePath

Write-Host "DÃ©but des tests simples de mesure de performance..." -ForegroundColor Cyan

# Test 1: Mesurer le temps d'exÃ©cution d'un bloc de code
Write-Host "`nTest 1: Mesurer le temps d'exÃ©cution d'un bloc de code" -ForegroundColor Cyan

# Mesurer le temps d'exÃ©cution d'un bloc de code
$result = Measure-RoadmapExecutionTime -Name "TestSimple" -ScriptBlock {
    Start-Sleep -Milliseconds 100
    return "Test rÃ©ussi"
}

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq "Test rÃ©ussi" -and
           $result.ElapsedMilliseconds -ge 100

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du temps d'exÃ©cution: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result='Test rÃ©ussi', ElapsedMilliseconds>=100" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result='$($result.Result)', ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

# Test 2: Mesurer le temps d'exÃ©cution d'un bloc de code avec des paramÃ¨tres
Write-Host "`nTest 2: Mesurer le temps d'exÃ©cution d'un bloc de code avec des paramÃ¨tres" -ForegroundColor Cyan

# Mesurer le temps d'exÃ©cution d'un bloc de code avec des paramÃ¨tres
$result = Measure-RoadmapExecutionTime -Name "TestSimpleWithParams" -ScriptBlock {
    param($a, $b)
    Start-Sleep -Milliseconds 50
    return $a + $b
} -ArgumentList 10, 20

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq 30 -and
           $result.ElapsedMilliseconds -ge 50

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du temps d'exÃ©cution avec paramÃ¨tres: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result=30, ElapsedMilliseconds>=50" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result=$($result.Result), ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

# Test 3: Mesurer le temps d'exÃ©cution d'un bloc de code avec pipeline
Write-Host "`nTest 3: Mesurer le temps d'exÃ©cution d'un bloc de code avec pipeline" -ForegroundColor Cyan

# Mesurer le temps d'exÃ©cution d'un bloc de code avec pipeline
$result = Measure-RoadmapExecutionTime -Name "TestSimpleWithPipeline" -ScriptBlock {
    process {
        Start-Sleep -Milliseconds 50
        return $_ * 2
    }
} -InputObject 15

# VÃ©rifier le rÃ©sultat
$success = $result.Result -eq 30 -and
           $result.ElapsedMilliseconds -ge 50

$status = if ($success) { "RÃ©ussi" } else { "Ã‰chouÃ©" }
$color = if ($success) { "Green" } else { "Red" }

Write-Host "  Mesure du temps d'exÃ©cution avec pipeline: $status" -ForegroundColor $color

if (-not $success) {
    Write-Host "    RÃ©sultat attendu: Result=30, ElapsedMilliseconds>=50" -ForegroundColor Red
    Write-Host "    RÃ©sultat obtenu: Result=$($result.Result), ElapsedMilliseconds=$($result.ElapsedMilliseconds)" -ForegroundColor Red
}

Write-Host "`nTests simples de mesure de performance terminÃ©s." -ForegroundColor Cyan

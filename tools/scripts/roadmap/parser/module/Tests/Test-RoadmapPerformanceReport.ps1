#
# Test-RoadmapPerformanceReport.ps1
#
# Script pour tester la fonction de gÃ©nÃ©ration de rapports de performance
#

# Importer les fonctions nÃ©cessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"

# Fonctions de mesure de performance
$measureExecutionTimePath = Join-Path -Path $publicPath -ChildPath "Measure-RoadmapExecutionTime.ps1"
$measureMemoryUsagePath = Join-Path -Path $publicPath -ChildPath "Measure-RoadmapMemoryUsage.ps1"
$measureOperationsPath = Join-Path -Path $publicPath -ChildPath "Measure-RoadmapOperations.ps1"
$addOperationCountPath = Join-Path -Path $publicPath -ChildPath "Add-RoadmapOperationCount.ps1"

# Fonctions de rapport
$newPerformanceReportPath = Join-Path -Path $publicPath -ChildPath "New-RoadmapPerformanceReport.ps1"

# Importer les fonctions
. $measureExecutionTimePath
. $measureMemoryUsagePath
. $measureOperationsPath
. $addOperationCountPath
. $newPerformanceReportPath

Write-Host "DÃ©but des tests de gÃ©nÃ©ration de rapports de performance..." -ForegroundColor Cyan

# GÃ©nÃ©rer des donnÃ©es de test
Write-Host "`nGÃ©nÃ©ration de donnÃ©es de test..." -ForegroundColor Cyan

# Test de temps d'exÃ©cution
for ($i = 1; $i -le 5; $i++) {
    $result = Measure-RoadmapExecutionTime -Name "TestExecution" -ScriptBlock {
        param($sleepTime)
        Start-Sleep -Milliseconds $sleepTime
        return "Test $sleepTime"
    } -ArgumentList ($i * 50)
}

# Test d'utilisation de mÃ©moire
for ($i = 1; $i -le 3; $i++) {
    $result = Measure-RoadmapMemoryUsage -Name "TestMemory" -ScriptBlock {
        param($size)
        $memoryHog = @()
        for ($j = 0; $j -lt $size; $j++) {
            $memoryHog += "X" * 1000
        }
        return "Test $size"
    } -ArgumentList ($i * 500)
}

# Test de comptage d'opÃ©rations
for ($i = 1; $i -le 4; $i++) {
    $result = Measure-RoadmapOperations -Name "TestOperations" -ScriptBlock {
        param($count)
        for ($j = 0; $j -lt $count; $j++) {
            Add-RoadmapOperationCount -Name "TestOperations"
        }
        return "Test $count"
    } -ArgumentList ($i * 25)
}

# Test 1: GÃ©nÃ©rer un rapport au format texte
Write-Host "`nTest 1: GÃ©nÃ©ration d'un rapport au format texte" -ForegroundColor Cyan
$textReport = New-RoadmapPerformanceReport -Format Text
Write-Host "Rapport texte gÃ©nÃ©rÃ© avec succÃ¨s. Extrait :"
Write-Host ($textReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

# Test 2: GÃ©nÃ©rer un rapport au format HTML
Write-Host "`nTest 2: GÃ©nÃ©ration d'un rapport au format HTML" -ForegroundColor Cyan
$htmlReport = New-RoadmapPerformanceReport -Format HTML
Write-Host "Rapport HTML gÃ©nÃ©rÃ© avec succÃ¨s. Extrait :"
Write-Host ($htmlReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

# Test 3: GÃ©nÃ©rer un rapport au format JSON
Write-Host "`nTest 3: GÃ©nÃ©ration d'un rapport au format JSON" -ForegroundColor Cyan
$jsonReport = New-RoadmapPerformanceReport -Format JSON
Write-Host "Rapport JSON gÃ©nÃ©rÃ© avec succÃ¨s. Extrait :"
Write-Host ($jsonReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

# Test 4: GÃ©nÃ©rer un rapport au format CSV
Write-Host "`nTest 4: GÃ©nÃ©ration d'un rapport au format CSV" -ForegroundColor Cyan
$csvReport = New-RoadmapPerformanceReport -Format CSV
Write-Host "Rapport CSV gÃ©nÃ©rÃ© avec succÃ¨s. Extrait :"
Write-Host ($csvReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

# Test 5: Enregistrer un rapport dans un fichier
Write-Host "`nTest 5: Enregistrement d'un rapport dans un fichier" -ForegroundColor Cyan
$tempFolder = [System.IO.Path]::GetTempPath()
$tempFile = Join-Path -Path $tempFolder -ChildPath "performance_report.html"
New-RoadmapPerformanceReport -Format HTML -OutputPath $tempFile
$fileExists = Test-Path -Path $tempFile
Write-Host "Rapport enregistrÃ© dans : $tempFile"
Write-Host "Le fichier existe : $fileExists"

# Test 6: GÃ©nÃ©rer un rapport avec des filtres
Write-Host "`nTest 6: GÃ©nÃ©ration d'un rapport avec des filtres" -ForegroundColor Cyan
$filteredReport = New-RoadmapPerformanceReport -Format Text -TimerName "TestExecution" -IncludeMemoryUsage $false -IncludeOperations $false
Write-Host "Rapport filtrÃ© gÃ©nÃ©rÃ© avec succÃ¨s. Extrait :"
Write-Host ($filteredReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

Write-Host "`nTests de gÃ©nÃ©ration de rapports de performance terminÃ©s." -ForegroundColor Cyan

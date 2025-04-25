#
# Test-RoadmapPerformanceReport.ps1
#
# Script pour tester la fonction de génération de rapports de performance
#

# Importer les fonctions nécessaires
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

Write-Host "Début des tests de génération de rapports de performance..." -ForegroundColor Cyan

# Générer des données de test
Write-Host "`nGénération de données de test..." -ForegroundColor Cyan

# Test de temps d'exécution
for ($i = 1; $i -le 5; $i++) {
    $result = Measure-RoadmapExecutionTime -Name "TestExecution" -ScriptBlock {
        param($sleepTime)
        Start-Sleep -Milliseconds $sleepTime
        return "Test $sleepTime"
    } -ArgumentList ($i * 50)
}

# Test d'utilisation de mémoire
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

# Test de comptage d'opérations
for ($i = 1; $i -le 4; $i++) {
    $result = Measure-RoadmapOperations -Name "TestOperations" -ScriptBlock {
        param($count)
        for ($j = 0; $j -lt $count; $j++) {
            Add-RoadmapOperationCount -Name "TestOperations"
        }
        return "Test $count"
    } -ArgumentList ($i * 25)
}

# Test 1: Générer un rapport au format texte
Write-Host "`nTest 1: Génération d'un rapport au format texte" -ForegroundColor Cyan
$textReport = New-RoadmapPerformanceReport -Format Text
Write-Host "Rapport texte généré avec succès. Extrait :"
Write-Host ($textReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

# Test 2: Générer un rapport au format HTML
Write-Host "`nTest 2: Génération d'un rapport au format HTML" -ForegroundColor Cyan
$htmlReport = New-RoadmapPerformanceReport -Format HTML
Write-Host "Rapport HTML généré avec succès. Extrait :"
Write-Host ($htmlReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

# Test 3: Générer un rapport au format JSON
Write-Host "`nTest 3: Génération d'un rapport au format JSON" -ForegroundColor Cyan
$jsonReport = New-RoadmapPerformanceReport -Format JSON
Write-Host "Rapport JSON généré avec succès. Extrait :"
Write-Host ($jsonReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

# Test 4: Générer un rapport au format CSV
Write-Host "`nTest 4: Génération d'un rapport au format CSV" -ForegroundColor Cyan
$csvReport = New-RoadmapPerformanceReport -Format CSV
Write-Host "Rapport CSV généré avec succès. Extrait :"
Write-Host ($csvReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

# Test 5: Enregistrer un rapport dans un fichier
Write-Host "`nTest 5: Enregistrement d'un rapport dans un fichier" -ForegroundColor Cyan
$tempFolder = [System.IO.Path]::GetTempPath()
$tempFile = Join-Path -Path $tempFolder -ChildPath "performance_report.html"
New-RoadmapPerformanceReport -Format HTML -OutputPath $tempFile
$fileExists = Test-Path -Path $tempFile
Write-Host "Rapport enregistré dans : $tempFile"
Write-Host "Le fichier existe : $fileExists"

# Test 6: Générer un rapport avec des filtres
Write-Host "`nTest 6: Génération d'un rapport avec des filtres" -ForegroundColor Cyan
$filteredReport = New-RoadmapPerformanceReport -Format Text -TimerName "TestExecution" -IncludeMemoryUsage $false -IncludeOperations $false
Write-Host "Rapport filtré généré avec succès. Extrait :"
Write-Host ($filteredReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

Write-Host "`nTests de génération de rapports de performance terminés." -ForegroundColor Cyan

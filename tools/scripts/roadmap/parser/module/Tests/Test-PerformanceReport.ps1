#
# Test-PerformanceReport.ps1
#
# Script pour tester la fonction de gÃ©nÃ©ration de rapports de performance
#

# Importer la fonction de gÃ©nÃ©ration de rapports
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$publicPath = Join-Path -Path $modulePath -ChildPath "Functions\Public"
$reportFunctionPath = Join-Path -Path $publicPath -ChildPath "New-RoadmapPerformanceReport.ps1"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $reportFunctionPath)) {
    Write-Error "Le fichier New-RoadmapPerformanceReport.ps1 est introuvable Ã  l'emplacement : $reportFunctionPath"
    exit 1
}

# Importer la fonction
. $reportFunctionPath

Write-Host "DÃ©but des tests de gÃ©nÃ©ration de rapports de performance..." -ForegroundColor Cyan

# CrÃ©er des donnÃ©es de test
$testData = [PSCustomObject]@{
    GeneratedAt = Get-Date
    Title = "Rapport de test"
    ExecutionTime = @(
        [PSCustomObject]@{
            Name = "TestFunction1"
            Count = 5
            MinDurationMs = 10
            MaxDurationMs = 100
            AverageDurationMs = 50
            TotalDurationMs = 250
            LastDurationMs = 45
        },
        [PSCustomObject]@{
            Name = "TestFunction2"
            Count = 3
            MinDurationMs = 20
            MaxDurationMs = 200
            AverageDurationMs = 100
            TotalDurationMs = 300
            LastDurationMs = 80
        }
    )
    MemoryUsage = @(
        [PSCustomObject]@{
            Name = "TestMemory1"
            Count = 4
            MinBytes = 1024
            MaxBytes = 10240
            AverageBytes = 5120
            TotalBytes = 20480
            LastBytes = 4096
        }
    )
    Operations = @(
        [PSCustomObject]@{
            Name = "TestOperation1"
            Count = 3
            MinOperations = 10
            MaxOperations = 100
            AverageOperations = 50
            TotalOperations = 150
            LastOperations = 40
            CurrentValue = 0
        }
    )
}

# Test 1: GÃ©nÃ©rer un rapport au format texte
Write-Host "`nTest 1: GÃ©nÃ©ration d'un rapport au format texte" -ForegroundColor Cyan
$textReport = New-TextPerformanceReport -PerformanceData $testData -IncludeTimestamp $true
Write-Host "Rapport texte gÃ©nÃ©rÃ© avec succÃ¨s. Extrait :"
Write-Host ($textReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

# Test 2: GÃ©nÃ©rer un rapport au format HTML
Write-Host "`nTest 2: GÃ©nÃ©ration d'un rapport au format HTML" -ForegroundColor Cyan
$htmlReport = New-HtmlPerformanceReport -PerformanceData $testData -IncludeTimestamp $true
Write-Host "Rapport HTML gÃ©nÃ©rÃ© avec succÃ¨s. Extrait :"
Write-Host ($htmlReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

# Test 3: GÃ©nÃ©rer un rapport CSV
Write-Host "`nTest 3: GÃ©nÃ©ration d'un rapport au format CSV" -ForegroundColor Cyan
$csvReport = New-CsvPerformanceReport -PerformanceData $testData
Write-Host "Rapport CSV gÃ©nÃ©rÃ© avec succÃ¨s. Extrait :"
Write-Host ($csvReport -split "`n" | Select-Object -First 10) -ForegroundColor Gray
Write-Host "..."

# Test 4: Enregistrer un rapport dans un fichier
Write-Host "`nTest 4: Enregistrement d'un rapport dans un fichier" -ForegroundColor Cyan
$tempFolder = [System.IO.Path]::GetTempPath()
$tempFile = Join-Path -Path $tempFolder -ChildPath "performance_report_test.html"

# CrÃ©er une fonction de journalisation simplifiÃ©e pour le test
function Write-Log {
    param (
        [string]$Message,
        [string]$Level,
        [string]$Source
    )
    Write-Host "[$Level] [$Source] $Message" -ForegroundColor Yellow
}

# Appeler la fonction avec les donnÃ©es de test
try {
    # DÃ©finir les variables de script nÃ©cessaires
    $script:LogLevelInfo = "INFO"
    
    # Simuler la fonction New-RoadmapPerformanceReport
    $htmlContent = New-HtmlPerformanceReport -PerformanceData $testData -IncludeTimestamp $true
    $htmlContent | Out-File -FilePath $tempFile -Encoding UTF8
    Write-Log -Message "Rapport de performance enregistrÃ© dans : $tempFile" -Level $script:LogLevelInfo -Source "PerformanceReport"
    
    $fileExists = Test-Path -Path $tempFile
    Write-Host "Le fichier existe : $fileExists" -ForegroundColor $(if ($fileExists) { "Green" } else { "Red" })
    
    if ($fileExists) {
        $fileContent = Get-Content -Path $tempFile -Raw
        $fileSize = (Get-Item -Path $tempFile).Length
        Write-Host "Taille du fichier : $fileSize octets" -ForegroundColor Cyan
        Write-Host "Le fichier contient du HTML : $($fileContent.Contains('<!DOCTYPE html>'))" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Erreur lors de l'enregistrement du rapport : $_" -ForegroundColor Red
}

Write-Host "`nTests de gÃ©nÃ©ration de rapports de performance terminÃ©s." -ForegroundColor Cyan

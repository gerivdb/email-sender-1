# Tests d'interface utilisateur et de journalisation pour le mode manager

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

# CrÃ©er un rÃ©pertoire pour les journaux
$logDir = Join-Path -Path $testDir -ChildPath "logs"
if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier de configuration avec des options d'interface utilisateur et de journalisation
$tempConfigPath = Join-Path -Path $testDir -ChildPath "ui-config.json"
@{
    General = @{
        RoadmapPath = "docs\plans\roadmap_complete_2.md"
        ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
        ReportPath = "reports"
        LogPath = $logDir
        LogLevel = "Verbose"
        ColorEnabled = $true
        ProgressEnabled = $true
        SummaryEnabled = $true
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
} | ConvertTo-Json -Depth 5 | Set-Content -Path $tempConfigPath -Encoding UTF8

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
    [string]$ConfigPath,

    [Parameter(Mandatory = $false)]
    [string]$LogPath,

    [Parameter(Mandatory = $false)]
    [string]$LogLevel
)

Write-Host "Mode CHECK exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ActiveDocumentPath : $ActiveDocumentPath"
Write-Host "CheckActiveDocument : $CheckActiveDocument"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "LogPath : $LogPath"
Write-Host "LogLevel : $LogLevel"

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "check-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ActiveDocumentPath : $ActiveDocumentPath
CheckActiveDocument : $CheckActiveDocument
ConfigPath : $ConfigPath
LogPath : $LogPath
LogLevel : $LogLevel
"@ | Set-Content -Path $outputPath -Encoding UTF8

# CrÃ©er un fichier de journal pour vÃ©rifier la journalisation
if (-not [string]::IsNullOrEmpty($LogPath)) {
    $logFilePath = Join-Path -Path $LogPath -ChildPath "check-mode.log"
    @"
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Mode CHECK dÃ©marrÃ©
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: ParamÃ¨tres : FilePath=$FilePath, TaskIdentifier=$TaskIdentifier, Force=$Force
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Mode CHECK terminÃ© avec succÃ¨s
"@ | Set-Content -Path $logFilePath -Encoding UTF8
}

# Simuler une progression
for ($i = 0; $i -le 100; $i += 10) {
    Write-Progress -Activity "ExÃ©cution du mode CHECK" -Status "Progression : $i%" -PercentComplete $i
    Start-Sleep -Milliseconds 50
}

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
    [string]$ConfigPath,

    [Parameter(Mandatory = $false)]
    [string]$LogPath,

    [Parameter(Mandatory = $false)]
    [string]$LogLevel
)

Write-Host "Mode GRAN exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "LogPath : $LogPath"
Write-Host "LogLevel : $LogLevel"

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "gran-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ConfigPath : $ConfigPath
LogPath : $LogPath
LogLevel : $LogLevel
"@ | Set-Content -Path $outputPath -Encoding UTF8

# CrÃ©er un fichier de journal pour vÃ©rifier la journalisation
if (-not [string]::IsNullOrEmpty($LogPath)) {
    $logFilePath = Join-Path -Path $LogPath -ChildPath "gran-mode.log"
    @"
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Mode GRAN dÃ©marrÃ©
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: ParamÃ¨tres : FilePath=$FilePath, TaskIdentifier=$TaskIdentifier, Force=$Force
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Mode GRAN terminÃ© avec succÃ¨s
"@ | Set-Content -Path $logFilePath -Encoding UTF8
}

# Simuler une progression
for ($i = 0; $i -le 100; $i += 10) {
    Write-Progress -Activity "ExÃ©cution du mode GRAN" -Status "Progression : $i%" -PercentComplete $i
    Start-Sleep -Milliseconds 50
}

exit 0
'@
Set-Content -Path $mockGranModePath -Value $mockGranContent -Encoding UTF8

# CrÃ©er un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
"# Test Roadmap" | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Fonction pour capturer la sortie d'une commande
function Capture-Output {
    param (
        [ScriptBlock]$ScriptBlock
    )
    
    $tempFile = Join-Path -Path $testDir -ChildPath "output.txt"
    & $ScriptBlock | Out-File -FilePath $tempFile -Encoding UTF8
    return Get-Content -Path $tempFile -Raw
}

# Test 1: VÃ©rification de la sortie console
Write-Host "Test 1: VÃ©rification de la sortie console" -ForegroundColor Cyan
try {
    # Capturer la sortie de la commande
    $output = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    }
    
    # VÃ©rifier que la sortie contient des informations utiles
    $success = $true
    
    if (-not ($output -match "Mode CHECK")) {
        Write-Host "Test 1 Ã©chouÃ©: La sortie ne contient pas d'informations sur le mode CHECK" -ForegroundColor Red
        $success = $false
    }
    
    if (-not ($output -match "exÃ©cutÃ© avec succÃ¨s")) {
        Write-Host "Test 1 Ã©chouÃ©: La sortie ne contient pas d'informations sur le succÃ¨s de l'exÃ©cution" -ForegroundColor Red
        $success = $false
    }
    
    if ($success) {
        Write-Host "Test 1 rÃ©ussi: La sortie console contient des informations utiles" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 1 Ã©chouÃ©: Une erreur s'est produite lors de la vÃ©rification de la sortie console" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: VÃ©rification de la journalisation
Write-Host "Test 2: VÃ©rification de la journalisation" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script avec journalisation
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    
    # VÃ©rifier que les fichiers de journal ont Ã©tÃ© crÃ©Ã©s
    $managerLogPath = Join-Path -Path $logDir -ChildPath "mode-manager.log"
    $checkLogPath = Join-Path -Path $logDir -ChildPath "check-mode.log"
    
    $success = $true
    
    if (-not (Test-Path -Path $managerLogPath)) {
        Write-Host "Test 2 Ã©chouÃ©: Le fichier de journal du mode manager n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
        $success = $false
    } else {
        $managerLog = Get-Content -Path $managerLogPath -Raw
        if (-not ($managerLog -match "Mode CHECK")) {
            Write-Host "Test 2 Ã©chouÃ©: Le journal du mode manager ne contient pas d'informations sur le mode CHECK" -ForegroundColor Red
            $success = $false
        }
    }
    
    if (-not (Test-Path -Path $checkLogPath)) {
        Write-Host "Test 2 Ã©chouÃ©: Le fichier de journal du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
        $success = $false
    } else {
        $checkLog = Get-Content -Path $checkLogPath -Raw
        if (-not ($checkLog -match "Mode CHECK dÃ©marrÃ©")) {
            Write-Host "Test 2 Ã©chouÃ©: Le journal du mode CHECK ne contient pas d'informations sur le dÃ©marrage" -ForegroundColor Red
            $success = $false
        }
    }
    
    if ($success) {
        Write-Host "Test 2 rÃ©ussi: Les fichiers de journal ont Ã©tÃ© crÃ©Ã©s et contiennent des informations utiles" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 2 Ã©chouÃ©: Une erreur s'est produite lors de la vÃ©rification de la journalisation" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: VÃ©rification des niveaux de verbositÃ©
Write-Host "Test 3: VÃ©rification des niveaux de verbositÃ©" -ForegroundColor Cyan
try {
    # CrÃ©er une configuration avec un niveau de verbositÃ© diffÃ©rent
    $verboseConfigPath = Join-Path -Path $testDir -ChildPath "verbose-config.json"
    $verboseConfig = @{
        General = @{
            RoadmapPath = "docs\plans\roadmap_complete_2.md"
            ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
            ReportPath = "reports"
            LogPath = $logDir
            LogLevel = "Debug"
            ColorEnabled = $true
            ProgressEnabled = $true
            SummaryEnabled = $true
        }
        Modes = @{
            Check = @{
                Enabled = $true
                ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
            }
        }
    }
    $verboseConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $verboseConfigPath -Encoding UTF8
    
    # ExÃ©cuter le script avec un niveau de verbositÃ© Ã©levÃ©
    $verboseOutput = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $verboseConfigPath -Verbose
    }
    
    # ExÃ©cuter le script avec un niveau de verbositÃ© normal
    $normalOutput = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    }
    
    # VÃ©rifier que la sortie verbose contient plus d'informations que la sortie normale
    if ($verboseOutput.Length -gt $normalOutput.Length) {
        Write-Host "Test 3 rÃ©ussi: La sortie verbose contient plus d'informations que la sortie normale" -ForegroundColor Green
    } else {
        Write-Host "Test 3 Ã©chouÃ©: La sortie verbose ne contient pas plus d'informations que la sortie normale" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 3 Ã©chouÃ©: Une erreur s'est produite lors de la vÃ©rification des niveaux de verbositÃ©" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: VÃ©rification de l'affichage de la progression
Write-Host "Test 4: VÃ©rification de l'affichage de la progression" -ForegroundColor Cyan
try {
    # CrÃ©er une configuration avec l'affichage de la progression dÃ©sactivÃ©
    $noProgressConfigPath = Join-Path -Path $testDir -ChildPath "no-progress-config.json"
    $noProgressConfig = @{
        General = @{
            RoadmapPath = "docs\plans\roadmap_complete_2.md"
            ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
            ReportPath = "reports"
            LogPath = $logDir
            LogLevel = "Verbose"
            ColorEnabled = $true
            ProgressEnabled = $false
            SummaryEnabled = $true
        }
        Modes = @{
            Check = @{
                Enabled = $true
                ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
            }
        }
    }
    $noProgressConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $noProgressConfigPath -Encoding UTF8
    
    # ExÃ©cuter le script avec l'affichage de la progression dÃ©sactivÃ©
    $noProgressOutput = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $noProgressConfigPath
    }
    
    # ExÃ©cuter le script avec l'affichage de la progression activÃ©
    $progressOutput = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    }
    
    # VÃ©rifier que la sortie avec progression contient des informations sur la progression
    if ($progressOutput -match "Progression" -and (-not ($noProgressOutput -match "Progression"))) {
        Write-Host "Test 4 rÃ©ussi: La sortie avec progression contient des informations sur la progression" -ForegroundColor Green
    } else {
        Write-Host "Test 4 Ã©chouÃ©: La sortie avec progression ne contient pas d'informations sur la progression" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 4 Ã©chouÃ©: Une erreur s'est produite lors de la vÃ©rification de l'affichage de la progression" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 5: VÃ©rification de l'affichage du rÃ©sumÃ©
Write-Host "Test 5: VÃ©rification de l'affichage du rÃ©sumÃ©" -ForegroundColor Cyan
try {
    # CrÃ©er une configuration avec l'affichage du rÃ©sumÃ© dÃ©sactivÃ©
    $noSummaryConfigPath = Join-Path -Path $testDir -ChildPath "no-summary-config.json"
    $noSummaryConfig = @{
        General = @{
            RoadmapPath = "docs\plans\roadmap_complete_2.md"
            ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
            ReportPath = "reports"
            LogPath = $logDir
            LogLevel = "Verbose"
            ColorEnabled = $true
            ProgressEnabled = $true
            SummaryEnabled = $false
        }
        Modes = @{
            Check = @{
                Enabled = $true
                ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
            }
        }
    }
    $noSummaryConfig | ConvertTo-Json -Depth 5 | Set-Content -Path $noSummaryConfigPath -Encoding UTF8
    
    # ExÃ©cuter le script avec l'affichage du rÃ©sumÃ© dÃ©sactivÃ©
    $noSummaryOutput = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $noSummaryConfigPath
    }
    
    # ExÃ©cuter le script avec l'affichage du rÃ©sumÃ© activÃ©
    $summaryOutput = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    }
    
    # VÃ©rifier que la sortie avec rÃ©sumÃ© contient des informations sur le rÃ©sumÃ©
    if ($summaryOutput -match "RÃ©sumÃ©" -and (-not ($noSummaryOutput -match "RÃ©sumÃ©"))) {
        Write-Host "Test 5 rÃ©ussi: La sortie avec rÃ©sumÃ© contient des informations sur le rÃ©sumÃ©" -ForegroundColor Green
    } else {
        Write-Host "Test 5 Ã©chouÃ©: La sortie avec rÃ©sumÃ© ne contient pas d'informations sur le rÃ©sumÃ©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 5 Ã©chouÃ©: Une erreur s'est produite lors de la vÃ©rification de l'affichage du rÃ©sumÃ©" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
Write-Host "Nettoyage des fichiers temporaires..." -ForegroundColor Cyan
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

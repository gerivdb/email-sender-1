# Tests d'interface utilisateur et de journalisation pour le mode manager

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

# Créer un répertoire pour les journaux
$logDir = Join-Path -Path $testDir -ChildPath "logs"
if (-not (Test-Path -Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

# Créer un fichier de configuration avec des options d'interface utilisateur et de journalisation
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

# Créer des scripts de mode simulés
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

Write-Host "Mode CHECK exécuté avec les paramètres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ActiveDocumentPath : $ActiveDocumentPath"
Write-Host "CheckActiveDocument : $CheckActiveDocument"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "LogPath : $LogPath"
Write-Host "LogLevel : $LogLevel"

# Créer un fichier de sortie pour vérifier que le script a été exécuté
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

# Créer un fichier de journal pour vérifier la journalisation
if (-not [string]::IsNullOrEmpty($LogPath)) {
    $logFilePath = Join-Path -Path $LogPath -ChildPath "check-mode.log"
    @"
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Mode CHECK démarré
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Paramètres : FilePath=$FilePath, TaskIdentifier=$TaskIdentifier, Force=$Force
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Mode CHECK terminé avec succès
"@ | Set-Content -Path $logFilePath -Encoding UTF8
}

# Simuler une progression
for ($i = 0; $i -le 100; $i += 10) {
    Write-Progress -Activity "Exécution du mode CHECK" -Status "Progression : $i%" -PercentComplete $i
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

Write-Host "Mode GRAN exécuté avec les paramètres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "LogPath : $LogPath"
Write-Host "LogLevel : $LogLevel"

# Créer un fichier de sortie pour vérifier que le script a été exécuté
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "gran-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ConfigPath : $ConfigPath
LogPath : $LogPath
LogLevel : $LogLevel
"@ | Set-Content -Path $outputPath -Encoding UTF8

# Créer un fichier de journal pour vérifier la journalisation
if (-not [string]::IsNullOrEmpty($LogPath)) {
    $logFilePath = Join-Path -Path $LogPath -ChildPath "gran-mode.log"
    @"
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Mode GRAN démarré
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Paramètres : FilePath=$FilePath, TaskIdentifier=$TaskIdentifier, Force=$Force
[$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")] INFO: Mode GRAN terminé avec succès
"@ | Set-Content -Path $logFilePath -Encoding UTF8
}

# Simuler une progression
for ($i = 0; $i -le 100; $i += 10) {
    Write-Progress -Activity "Exécution du mode GRAN" -Status "Progression : $i%" -PercentComplete $i
    Start-Sleep -Milliseconds 50
}

exit 0
'@
Set-Content -Path $mockGranModePath -Value $mockGranContent -Encoding UTF8

# Créer un fichier de roadmap de test
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

# Test 1: Vérification de la sortie console
Write-Host "Test 1: Vérification de la sortie console" -ForegroundColor Cyan
try {
    # Capturer la sortie de la commande
    $output = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    }
    
    # Vérifier que la sortie contient des informations utiles
    $success = $true
    
    if (-not ($output -match "Mode CHECK")) {
        Write-Host "Test 1 échoué: La sortie ne contient pas d'informations sur le mode CHECK" -ForegroundColor Red
        $success = $false
    }
    
    if (-not ($output -match "exécuté avec succès")) {
        Write-Host "Test 1 échoué: La sortie ne contient pas d'informations sur le succès de l'exécution" -ForegroundColor Red
        $success = $false
    }
    
    if ($success) {
        Write-Host "Test 1 réussi: La sortie console contient des informations utiles" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 1 échoué: Une erreur s'est produite lors de la vérification de la sortie console" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: Vérification de la journalisation
Write-Host "Test 2: Vérification de la journalisation" -ForegroundColor Cyan
try {
    # Exécuter le script avec journalisation
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    
    # Vérifier que les fichiers de journal ont été créés
    $managerLogPath = Join-Path -Path $logDir -ChildPath "mode-manager.log"
    $checkLogPath = Join-Path -Path $logDir -ChildPath "check-mode.log"
    
    $success = $true
    
    if (-not (Test-Path -Path $managerLogPath)) {
        Write-Host "Test 2 échoué: Le fichier de journal du mode manager n'a pas été créé" -ForegroundColor Red
        $success = $false
    } else {
        $managerLog = Get-Content -Path $managerLogPath -Raw
        if (-not ($managerLog -match "Mode CHECK")) {
            Write-Host "Test 2 échoué: Le journal du mode manager ne contient pas d'informations sur le mode CHECK" -ForegroundColor Red
            $success = $false
        }
    }
    
    if (-not (Test-Path -Path $checkLogPath)) {
        Write-Host "Test 2 échoué: Le fichier de journal du mode CHECK n'a pas été créé" -ForegroundColor Red
        $success = $false
    } else {
        $checkLog = Get-Content -Path $checkLogPath -Raw
        if (-not ($checkLog -match "Mode CHECK démarré")) {
            Write-Host "Test 2 échoué: Le journal du mode CHECK ne contient pas d'informations sur le démarrage" -ForegroundColor Red
            $success = $false
        }
    }
    
    if ($success) {
        Write-Host "Test 2 réussi: Les fichiers de journal ont été créés et contiennent des informations utiles" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 2 échoué: Une erreur s'est produite lors de la vérification de la journalisation" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: Vérification des niveaux de verbosité
Write-Host "Test 3: Vérification des niveaux de verbosité" -ForegroundColor Cyan
try {
    # Créer une configuration avec un niveau de verbosité différent
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
    
    # Exécuter le script avec un niveau de verbosité élevé
    $verboseOutput = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $verboseConfigPath -Verbose
    }
    
    # Exécuter le script avec un niveau de verbosité normal
    $normalOutput = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    }
    
    # Vérifier que la sortie verbose contient plus d'informations que la sortie normale
    if ($verboseOutput.Length -gt $normalOutput.Length) {
        Write-Host "Test 3 réussi: La sortie verbose contient plus d'informations que la sortie normale" -ForegroundColor Green
    } else {
        Write-Host "Test 3 échoué: La sortie verbose ne contient pas plus d'informations que la sortie normale" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 3 échoué: Une erreur s'est produite lors de la vérification des niveaux de verbosité" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: Vérification de l'affichage de la progression
Write-Host "Test 4: Vérification de l'affichage de la progression" -ForegroundColor Cyan
try {
    # Créer une configuration avec l'affichage de la progression désactivé
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
    
    # Exécuter le script avec l'affichage de la progression désactivé
    $noProgressOutput = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $noProgressConfigPath
    }
    
    # Exécuter le script avec l'affichage de la progression activé
    $progressOutput = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    }
    
    # Vérifier que la sortie avec progression contient des informations sur la progression
    if ($progressOutput -match "Progression" -and (-not ($noProgressOutput -match "Progression"))) {
        Write-Host "Test 4 réussi: La sortie avec progression contient des informations sur la progression" -ForegroundColor Green
    } else {
        Write-Host "Test 4 échoué: La sortie avec progression ne contient pas d'informations sur la progression" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 4 échoué: Une erreur s'est produite lors de la vérification de l'affichage de la progression" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 5: Vérification de l'affichage du résumé
Write-Host "Test 5: Vérification de l'affichage du résumé" -ForegroundColor Cyan
try {
    # Créer une configuration avec l'affichage du résumé désactivé
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
    
    # Exécuter le script avec l'affichage du résumé désactivé
    $noSummaryOutput = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $noSummaryConfigPath
    }
    
    # Exécuter le script avec l'affichage du résumé activé
    $summaryOutput = Capture-Output {
        & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    }
    
    # Vérifier que la sortie avec résumé contient des informations sur le résumé
    if ($summaryOutput -match "Résumé" -and (-not ($noSummaryOutput -match "Résumé"))) {
        Write-Host "Test 5 réussi: La sortie avec résumé contient des informations sur le résumé" -ForegroundColor Green
    } else {
        Write-Host "Test 5 échoué: La sortie avec résumé ne contient pas d'informations sur le résumé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 5 échoué: Une erreur s'est produite lors de la vérification de l'affichage du résumé" -ForegroundColor Red
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

Write-Host "Tests terminés." -ForegroundColor Cyan

# Tests de sÃ©curitÃ© pour le mode manager

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

# CrÃ©er un fichier de configuration pour les tests
$tempConfigPath = Join-Path -Path $testDir -ChildPath "security-config.json"
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
    [string]$ConfigPath
)

Write-Host "Mode CHECK exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ActiveDocumentPath : $ActiveDocumentPath"
Write-Host "CheckActiveDocument : $CheckActiveDocument"
Write-Host "ConfigPath : $ConfigPath"

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

Write-Host "Mode GRAN exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ConfigPath : $ConfigPath"

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

# CrÃ©er un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
"# Test Roadmap" | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Test 1: Injection de commandes dans les paramÃ¨tres
Write-Host "Test 1: Injection de commandes dans les paramÃ¨tres" -ForegroundColor Cyan
try {
    # Tenter d'injecter une commande dans le paramÃ¨tre FilePath
    $injectionFilePath = "$testRoadmapPath; Write-Host 'Injection rÃ©ussie' -ForegroundColor Red"
    
    # ExÃ©cuter le script avec le paramÃ¨tre injectÃ©
    $output = & $scriptPath -Mode "CHECK" -FilePath $injectionFilePath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier si l'injection a rÃ©ussi
    if ($output -match "Injection rÃ©ussie") {
        Write-Host "Test 1 Ã©chouÃ©: L'injection de commandes a rÃ©ussi" -ForegroundColor Red
    } else {
        Write-Host "Test 1 rÃ©ussi: L'injection de commandes a Ã©chouÃ©" -ForegroundColor Green
    }
} catch {
    # Si une erreur est gÃ©nÃ©rÃ©e, c'est aussi acceptable
    Write-Host "Test 1 rÃ©ussi: L'injection de commandes a gÃ©nÃ©rÃ© une erreur" -ForegroundColor Green
    Write-Host "Erreur: $_" -ForegroundColor Cyan
}

# Test 2: Injection de commandes dans le paramÃ¨tre TaskIdentifier
Write-Host "Test 2: Injection de commandes dans le paramÃ¨tre TaskIdentifier" -ForegroundColor Cyan
try {
    # Tenter d'injecter une commande dans le paramÃ¨tre TaskIdentifier
    $injectionTaskId = "1.2.3; Write-Host 'Injection rÃ©ussie' -ForegroundColor Red"
    
    # ExÃ©cuter le script avec le paramÃ¨tre injectÃ©
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier $injectionTaskId -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier si l'injection a rÃ©ussi
    if ($output -match "Injection rÃ©ussie") {
        Write-Host "Test 2 Ã©chouÃ©: L'injection de commandes a rÃ©ussi" -ForegroundColor Red
    } else {
        Write-Host "Test 2 rÃ©ussi: L'injection de commandes a Ã©chouÃ©" -ForegroundColor Green
    }
} catch {
    # Si une erreur est gÃ©nÃ©rÃ©e, c'est aussi acceptable
    Write-Host "Test 2 rÃ©ussi: L'injection de commandes a gÃ©nÃ©rÃ© une erreur" -ForegroundColor Green
    Write-Host "Erreur: $_" -ForegroundColor Cyan
}

# Test 3: Injection de commandes dans le paramÃ¨tre ConfigPath
Write-Host "Test 3: Injection de commandes dans le paramÃ¨tre ConfigPath" -ForegroundColor Cyan
try {
    # Tenter d'injecter une commande dans le paramÃ¨tre ConfigPath
    $injectionConfigPath = "$tempConfigPath; Write-Host 'Injection rÃ©ussie' -ForegroundColor Red"
    
    # ExÃ©cuter le script avec le paramÃ¨tre injectÃ©
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $injectionConfigPath 2>&1
    
    # VÃ©rifier si l'injection a rÃ©ussi
    if ($output -match "Injection rÃ©ussie") {
        Write-Host "Test 3 Ã©chouÃ©: L'injection de commandes a rÃ©ussi" -ForegroundColor Red
    } else {
        Write-Host "Test 3 rÃ©ussi: L'injection de commandes a Ã©chouÃ©" -ForegroundColor Green
    }
} catch {
    # Si une erreur est gÃ©nÃ©rÃ©e, c'est aussi acceptable
    Write-Host "Test 3 rÃ©ussi: L'injection de commandes a gÃ©nÃ©rÃ© une erreur" -ForegroundColor Green
    Write-Host "Erreur: $_" -ForegroundColor Cyan
}

# Test 4: Injection de commandes dans le paramÃ¨tre Mode
Write-Host "Test 4: Injection de commandes dans le paramÃ¨tre Mode" -ForegroundColor Cyan
try {
    # Tenter d'injecter une commande dans le paramÃ¨tre Mode
    $injectionMode = "CHECK; Write-Host 'Injection rÃ©ussie' -ForegroundColor Red"
    
    # ExÃ©cuter le script avec le paramÃ¨tre injectÃ©
    $output = & $scriptPath -Mode $injectionMode -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier si l'injection a rÃ©ussi
    if ($output -match "Injection rÃ©ussie") {
        Write-Host "Test 4 Ã©chouÃ©: L'injection de commandes a rÃ©ussi" -ForegroundColor Red
    } else {
        Write-Host "Test 4 rÃ©ussi: L'injection de commandes a Ã©chouÃ©" -ForegroundColor Green
    }
} catch {
    # Si une erreur est gÃ©nÃ©rÃ©e, c'est aussi acceptable
    Write-Host "Test 4 rÃ©ussi: L'injection de commandes a gÃ©nÃ©rÃ© une erreur" -ForegroundColor Green
    Write-Host "Erreur: $_" -ForegroundColor Cyan
}

# Test 5: AccÃ¨s Ã  des fichiers en dehors du rÃ©pertoire de travail
Write-Host "Test 5: AccÃ¨s Ã  des fichiers en dehors du rÃ©pertoire de travail" -ForegroundColor Cyan
try {
    # Tenter d'accÃ©der Ã  un fichier en dehors du rÃ©pertoire de travail
    $outsideFilePath = "C:\Windows\System32\drivers\etc\hosts"
    
    # ExÃ©cuter le script avec le paramÃ¨tre pointant vers un fichier systÃ¨me
    $output = & $scriptPath -Mode "CHECK" -FilePath $outsideFilePath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier si le script a correctement validÃ© le chemin du fichier
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($outsideFilePath))") {
            # Le script a acceptÃ© le chemin du fichier, mais il devrait vÃ©rifier s'il est dans le rÃ©pertoire de travail
            Write-Host "Test 5 Ã©chouÃ©: Le script a acceptÃ© un chemin de fichier en dehors du rÃ©pertoire de travail" -ForegroundColor Red
        } else {
            Write-Host "Test 5 rÃ©ussi: Le script a rejetÃ© un chemin de fichier en dehors du rÃ©pertoire de travail" -ForegroundColor Green
        }
    } else {
        # Si le fichier de sortie n'a pas Ã©tÃ© crÃ©Ã©, c'est que le script a rejetÃ© le chemin du fichier
        Write-Host "Test 5 rÃ©ussi: Le script a rejetÃ© un chemin de fichier en dehors du rÃ©pertoire de travail" -ForegroundColor Green
    }
} catch {
    # Si une erreur est gÃ©nÃ©rÃ©e, c'est aussi acceptable
    Write-Host "Test 5 rÃ©ussi: L'accÃ¨s Ã  un fichier en dehors du rÃ©pertoire de travail a gÃ©nÃ©rÃ© une erreur" -ForegroundColor Green
    Write-Host "Erreur: $_" -ForegroundColor Cyan
}

# Test 6: Validation des entrÃ©es
Write-Host "Test 6: Validation des entrÃ©es" -ForegroundColor Cyan
try {
    # Tester avec des caractÃ¨res spÃ©ciaux dans les paramÃ¨tres
    $specialCharsFilePath = Join-Path -Path $testDir -ChildPath "test-roadmap-`"'<>&|;.md"
    "# Test Roadmap with special chars" | Set-Content -Path $specialCharsFilePath -Encoding UTF8
    
    # ExÃ©cuter le script avec des caractÃ¨res spÃ©ciaux dans les paramÃ¨tres
    $output = & $scriptPath -Mode "CHECK" -FilePath $specialCharsFilePath -TaskIdentifier "1.2.3`"'<>&|;" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier si le script a correctement gÃ©rÃ© les caractÃ¨res spÃ©ciaux
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($specialCharsFilePath))") {
            Write-Host "Test 6 rÃ©ussi: Le script a correctement gÃ©rÃ© les caractÃ¨res spÃ©ciaux" -ForegroundColor Green
        } else {
            Write-Host "Test 6 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© les caractÃ¨res spÃ©ciaux" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 6 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    # Si une erreur est gÃ©nÃ©rÃ©e, c'est que le script n'a pas correctement gÃ©rÃ© les caractÃ¨res spÃ©ciaux
    Write-Host "Test 6 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© les caractÃ¨res spÃ©ciaux" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 7: Gestion des permissions
Write-Host "Test 7: Gestion des permissions" -ForegroundColor Cyan
try {
    # CrÃ©er un fichier en lecture seule
    $readOnlyFilePath = Join-Path -Path $testDir -ChildPath "readonly-roadmap.md"
    "# Read-only Roadmap" | Set-Content -Path $readOnlyFilePath -Encoding UTF8
    Set-ItemProperty -Path $readOnlyFilePath -Name IsReadOnly -Value $true
    
    # ExÃ©cuter le script avec un fichier en lecture seule
    $output = & $scriptPath -Mode "CHECK" -FilePath $readOnlyFilePath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier si le script a correctement gÃ©rÃ© le fichier en lecture seule
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($readOnlyFilePath))") {
            Write-Host "Test 7 rÃ©ussi: Le script a correctement gÃ©rÃ© un fichier en lecture seule" -ForegroundColor Green
        } else {
            Write-Host "Test 7 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un fichier en lecture seule" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 7 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
    
    # Remettre le fichier en mode normal
    Set-ItemProperty -Path $readOnlyFilePath -Name IsReadOnly -Value $false
} catch {
    # Si une erreur est gÃ©nÃ©rÃ©e, c'est que le script n'a pas correctement gÃ©rÃ© le fichier en lecture seule
    Write-Host "Test 7 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un fichier en lecture seule" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 8: SÃ©curitÃ© des fichiers temporaires
Write-Host "Test 8: SÃ©curitÃ© des fichiers temporaires" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script et vÃ©rifier s'il crÃ©e des fichiers temporaires
    $tempFilesBefore = Get-ChildItem -Path $env:TEMP -Filter "mode-manager-*" -ErrorAction SilentlyContinue
    
    # ExÃ©cuter le script
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    
    # VÃ©rifier si des fichiers temporaires ont Ã©tÃ© crÃ©Ã©s et non supprimÃ©s
    $tempFilesAfter = Get-ChildItem -Path $env:TEMP -Filter "mode-manager-*" -ErrorAction SilentlyContinue
    
    if ($tempFilesAfter.Count -gt $tempFilesBefore.Count) {
        $newTempFiles = $tempFilesAfter | Where-Object { $tempFilesBefore -notcontains $_ }
        Write-Host "Test 8 Ã©chouÃ©: Le script a crÃ©Ã© des fichiers temporaires non supprimÃ©s" -ForegroundColor Red
        Write-Host "Fichiers temporaires non supprimÃ©s: $($newTempFiles.FullName -join ', ')" -ForegroundColor Red
    } else {
        Write-Host "Test 8 rÃ©ussi: Le script n'a pas laissÃ© de fichiers temporaires non supprimÃ©s" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 8 Ã©chouÃ©: Une erreur s'est produite lors de la vÃ©rification des fichiers temporaires" -ForegroundColor Red
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

# Test des configurations spÃ©ciales pour le mode manager

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

# CrÃ©er un fichier de configuration avec des chemins relatifs
$relativeConfigPath = Join-Path -Path $testDir -ChildPath "relative-config.json"
@{
    General = @{
        RoadmapPath = "docs\plans\roadmap_complete_2.md"
        ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
        ReportPath = "reports"
    }
    Modes = @{
        Check = @{
            Enabled = $true
            ScriptPath = "mock-check-mode.ps1"  # Chemin relatif
        }
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $relativeConfigPath -Encoding UTF8

# CrÃ©er un fichier de configuration avec des modes personnalisÃ©s
$customConfigPath = Join-Path -Path $testDir -ChildPath "custom-config.json"
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
            Parameters = @{
                CustomParam1 = "Value1"
                CustomParam2 = "Value2"
            }
        }
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $customConfigPath -Encoding UTF8

# CrÃ©er un fichier de configuration avec des modes dÃ©sactivÃ©s
$disabledConfigPath = Join-Path -Path $testDir -ChildPath "disabled-config.json"
@{
    General = @{
        RoadmapPath = "docs\plans\roadmap_complete_2.md"
        ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
        ReportPath = "reports"
    }
    Modes = @{
        Check = @{
            Enabled = $false
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
        }
        Gran = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-gran-mode.ps1"
        }
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $disabledConfigPath -Encoding UTF8

# CrÃ©er un fichier de configuration avec des paramÃ¨tres par dÃ©faut
$defaultsConfigPath = Join-Path -Path $testDir -ChildPath "defaults-config.json"
@{
    General = @{
        RoadmapPath = "docs\plans\roadmap_complete_2.md"
        ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
        ReportPath = "reports"
        DefaultParameters = @{
            DefaultParam1 = "DefaultValue1"
            DefaultParam2 = "DefaultValue2"
        }
    }
    Modes = @{
        Check = @{
            Enabled = $true
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
        }
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $defaultsConfigPath -Encoding UTF8

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
    [string]$CustomParam1,

    [Parameter(Mandatory = $false)]
    [string]$CustomParam2,

    [Parameter(Mandatory = $false)]
    [string]$DefaultParam1,

    [Parameter(Mandatory = $false)]
    [string]$DefaultParam2
)

Write-Host "Mode CHECK exÃ©cutÃ© avec les paramÃ¨tres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ActiveDocumentPath : $ActiveDocumentPath"
Write-Host "CheckActiveDocument : $CheckActiveDocument"
Write-Host "ConfigPath : $ConfigPath"
Write-Host "CustomParam1 : $CustomParam1"
Write-Host "CustomParam2 : $CustomParam2"
Write-Host "DefaultParam1 : $DefaultParam1"
Write-Host "DefaultParam2 : $DefaultParam2"

# CrÃ©er un fichier de sortie pour vÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ©
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "check-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ActiveDocumentPath : $ActiveDocumentPath
CheckActiveDocument : $CheckActiveDocument
ConfigPath : $ConfigPath
CustomParam1 : $CustomParam1
CustomParam2 : $CustomParam2
DefaultParam1 : $DefaultParam1
DefaultParam2 : $DefaultParam2
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

# Test 1: Configuration avec chemins relatifs
Write-Host "Test 1: Configuration avec chemins relatifs" -ForegroundColor Cyan
try {
    # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        Remove-Item -Path $checkOutputPath -Force
    }
    
    # ExÃ©cuter le script avec la configuration relative
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $relativeConfigPath
    
    # VÃ©rifier que le mode CHECK a Ã©tÃ© exÃ©cutÃ©
    if (Test-Path -Path $checkOutputPath) {
        $output = Get-Content -Path $checkOutputPath -Raw
        if ($output -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
            Write-Host "Test 1 rÃ©ussi: Le script a exÃ©cutÃ© le mode CHECK avec un chemin relatif" -ForegroundColor Green
        } else {
            Write-Host "Test 1 Ã©chouÃ©: Le script n'a pas exÃ©cutÃ© le mode CHECK avec les bons paramÃ¨tres" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 1 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec une configuration relative" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: Configuration avec des modes personnalisÃ©s
Write-Host "Test 2: Configuration avec des modes personnalisÃ©s" -ForegroundColor Cyan
try {
    # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        Remove-Item -Path $checkOutputPath -Force
    }
    
    # ExÃ©cuter le script avec la configuration personnalisÃ©e
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $customConfigPath
    
    # VÃ©rifier que le mode CHECK a Ã©tÃ© exÃ©cutÃ© avec les paramÃ¨tres personnalisÃ©s
    if (Test-Path -Path $checkOutputPath) {
        $output = Get-Content -Path $checkOutputPath -Raw
        $success = $true
        
        if (-not ($output -match "CustomParam1 : Value1")) {
            Write-Host "Test 2 Ã©chouÃ©: Le mode CHECK n'a pas reÃ§u le paramÃ¨tre CustomParam1" -ForegroundColor Red
            $success = $false
        }
        
        if (-not ($output -match "CustomParam2 : Value2")) {
            Write-Host "Test 2 Ã©chouÃ©: Le mode CHECK n'a pas reÃ§u le paramÃ¨tre CustomParam2" -ForegroundColor Red
            $success = $false
        }
        
        if ($success) {
            Write-Host "Test 2 rÃ©ussi: Le script a exÃ©cutÃ© le mode CHECK avec des paramÃ¨tres personnalisÃ©s" -ForegroundColor Green
        }
    } else {
        Write-Host "Test 2 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 2 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec une configuration personnalisÃ©e" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: Configuration avec des modes dÃ©sactivÃ©s
Write-Host "Test 3: Configuration avec des modes dÃ©sactivÃ©s" -ForegroundColor Cyan
try {
    # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    $granOutputPath = Join-Path -Path $testDir -ChildPath "gran-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        Remove-Item -Path $checkOutputPath -Force
    }
    if (Test-Path -Path $granOutputPath) {
        Remove-Item -Path $granOutputPath -Force
    }
    
    # ExÃ©cuter le script avec la configuration dÃ©sactivÃ©e pour CHECK
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $disabledConfigPath
    
    # VÃ©rifier que le mode CHECK n'a pas Ã©tÃ© exÃ©cutÃ©
    if (Test-Path -Path $checkOutputPath) {
        Write-Host "Test 3 Ã©chouÃ©: Le fichier de sortie du mode CHECK a Ã©tÃ© crÃ©Ã© alors qu'il ne devrait pas l'Ãªtre" -ForegroundColor Red
    } else {
        Write-Host "Test 3 rÃ©ussi: Le script n'a pas exÃ©cutÃ© le mode CHECK dÃ©sactivÃ©" -ForegroundColor Green
    }
    
    # ExÃ©cuter le script avec la configuration activÃ©e pour GRAN
    & $scriptPath -Mode "GRAN" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $disabledConfigPath
    
    # VÃ©rifier que le mode GRAN a Ã©tÃ© exÃ©cutÃ©
    if (Test-Path -Path $granOutputPath) {
        $output = Get-Content -Path $granOutputPath -Raw
        if ($output -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
            Write-Host "Test 3 rÃ©ussi: Le script a exÃ©cutÃ© le mode GRAN activÃ©" -ForegroundColor Green
        } else {
            Write-Host "Test 3 Ã©chouÃ©: Le script n'a pas exÃ©cutÃ© le mode GRAN avec les bons paramÃ¨tres" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 3 Ã©chouÃ©: Le fichier de sortie du mode GRAN n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 3 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec une configuration dÃ©sactivÃ©e" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: Configuration avec des paramÃ¨tres par dÃ©faut
Write-Host "Test 4: Configuration avec des paramÃ¨tres par dÃ©faut" -ForegroundColor Cyan
try {
    # Supprimer les fichiers de sortie des tests prÃ©cÃ©dents
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        Remove-Item -Path $checkOutputPath -Force
    }
    
    # ExÃ©cuter le script avec la configuration par dÃ©faut
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $defaultsConfigPath
    
    # VÃ©rifier que le mode CHECK a Ã©tÃ© exÃ©cutÃ© avec les paramÃ¨tres par dÃ©faut
    if (Test-Path -Path $checkOutputPath) {
        $output = Get-Content -Path $checkOutputPath -Raw
        $success = $true
        
        if (-not ($output -match "DefaultParam1 : DefaultValue1")) {
            Write-Host "Test 4 Ã©chouÃ©: Le mode CHECK n'a pas reÃ§u le paramÃ¨tre DefaultParam1" -ForegroundColor Red
            $success = $false
        }
        
        if (-not ($output -match "DefaultParam2 : DefaultValue2")) {
            Write-Host "Test 4 Ã©chouÃ©: Le mode CHECK n'a pas reÃ§u le paramÃ¨tre DefaultParam2" -ForegroundColor Red
            $success = $false
        }
        
        if ($success) {
            Write-Host "Test 4 rÃ©ussi: Le script a exÃ©cutÃ© le mode CHECK avec des paramÃ¨tres par dÃ©faut" -ForegroundColor Green
        }
    } else {
        Write-Host "Test 4 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 4 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec une configuration par dÃ©faut" -ForegroundColor Red
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

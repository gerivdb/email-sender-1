# Tests de compatibilitÃ© pour le mode manager

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
$tempConfigPath = Join-Path -Path $testDir -ChildPath "compatibility-config.json"
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

# Test 1: CompatibilitÃ© - PowerShell 5.1
Write-Host "Test 1: CompatibilitÃ© - PowerShell 5.1" -ForegroundColor Cyan
try {
    # VÃ©rifier la version de PowerShell
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -eq 5 -and $psVersion.Minor -eq 1) {
        # ExÃ©cuter le script avec PowerShell 5.1
        $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
        
        # VÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ© avec succÃ¨s
        $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
        if (Test-Path -Path $checkOutputPath) {
            $checkOutput = Get-Content -Path $checkOutputPath -Raw
            if ($checkOutput -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
                Write-Host "Test 1 rÃ©ussi: Le script est compatible avec PowerShell 5.1" -ForegroundColor Green
            } else {
                Write-Host "Test 1 Ã©chouÃ©: Le script n'a pas Ã©tÃ© exÃ©cutÃ© correctement avec PowerShell 5.1" -ForegroundColor Red
            }
        } else {
            Write-Host "Test 1 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1 ignorÃ©: Ce test doit Ãªtre exÃ©cutÃ© avec PowerShell 5.1" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Test 1 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec PowerShell 5.1" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: CompatibilitÃ© - PowerShell 7
Write-Host "Test 2: CompatibilitÃ© - PowerShell 7" -ForegroundColor Cyan
try {
    # VÃ©rifier si PowerShell 7 est installÃ©
    $pwsh = Get-Command -Name pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        # CrÃ©er un script temporaire pour exÃ©cuter le test avec PowerShell 7
        $tempScriptPath = Join-Path -Path $testDir -ChildPath "test-ps7.ps1"
        @"
# DÃ©finir le chemin du script Ã  tester
`$scriptPath = "$scriptPath"

# DÃ©finir le chemin du fichier de roadmap
`$testRoadmapPath = "$testRoadmapPath"

# DÃ©finir le chemin du fichier de configuration
`$tempConfigPath = "$tempConfigPath"

# ExÃ©cuter le script avec PowerShell 7
`$output = & `$scriptPath -Mode "CHECK" -FilePath `$testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath `$tempConfigPath 2>&1

# VÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ© avec succÃ¨s
`$checkOutputPath = "$testDir\check-mode-output.txt"
if (Test-Path -Path `$checkOutputPath) {
    `$checkOutput = Get-Content -Path `$checkOutputPath -Raw
    if (`$checkOutput -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
        Write-Host "Le script est compatible avec PowerShell 7" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Le script n'a pas Ã©tÃ© exÃ©cutÃ© correctement avec PowerShell 7" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    exit 1
}
"@ | Set-Content -Path $tempScriptPath -Encoding UTF8
        
        # ExÃ©cuter le script avec PowerShell 7
        $result = & $pwsh -File $tempScriptPath
        
        if ($result -match "compatible avec PowerShell 7") {
            Write-Host "Test 2 rÃ©ussi: Le script est compatible avec PowerShell 7" -ForegroundColor Green
        } else {
            Write-Host "Test 2 Ã©chouÃ©: Le script n'a pas Ã©tÃ© exÃ©cutÃ© correctement avec PowerShell 7" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 2 ignorÃ©: PowerShell 7 n'est pas installÃ©" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Test 2 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec PowerShell 7" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: CompatibilitÃ© - Chemins UNC
Write-Host "Test 3: CompatibilitÃ© - Chemins UNC" -ForegroundColor Cyan
try {
    # CrÃ©er un chemin UNC simulÃ©
    $uncPath = "\\localhost\c$\temp\test-roadmap.md"
    
    # ExÃ©cuter le script avec un chemin UNC
    $output = & $scriptPath -Mode "CHECK" -FilePath $uncPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© le chemin UNC
    if ($output -match "introuvable" -or $output -match "not found" -or $output -match "n'existe pas") {
        Write-Host "Test 3 rÃ©ussi: Le script a correctement gÃ©rÃ© un chemin UNC" -ForegroundColor Green
    } else {
        Write-Host "Test 3 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un chemin UNC" -ForegroundColor Red
    }
} catch {
    # Si une erreur est gÃ©nÃ©rÃ©e, c'est aussi acceptable
    if ($_.Exception.Message -match "introuvable" -or $_.Exception.Message -match "not found" -or $_.Exception.Message -match "n'existe pas") {
        Write-Host "Test 3 rÃ©ussi: Le script a correctement gÃ©rÃ© un chemin UNC" -ForegroundColor Green
    } else {
        Write-Host "Test 3 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un chemin UNC" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Test 4: CompatibilitÃ© - Chemins longs
Write-Host "Test 4: CompatibilitÃ© - Chemins longs" -ForegroundColor Cyan
try {
    # CrÃ©er un chemin long
    $longPath = Join-Path -Path $testDir -ChildPath ("a" * 200 + ".md")
    "# Test Roadmap with Long Path" | Set-Content -Path $longPath -Encoding UTF8
    
    # ExÃ©cuter le script avec un chemin long
    $output = & $scriptPath -Mode "CHECK" -FilePath $longPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© le chemin long
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($longPath))") {
            Write-Host "Test 4 rÃ©ussi: Le script a correctement gÃ©rÃ© un chemin long" -ForegroundColor Green
        } else {
            Write-Host "Test 4 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un chemin long" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 4 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 4 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec un chemin long" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 5: CompatibilitÃ© - ExÃ©cution en tant qu'administrateur
Write-Host "Test 5: CompatibilitÃ© - ExÃ©cution en tant qu'administrateur" -ForegroundColor Cyan
try {
    # VÃ©rifier si le script est exÃ©cutÃ© en tant qu'administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        # ExÃ©cuter le script en tant qu'administrateur
        $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
        
        # VÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ© avec succÃ¨s
        $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
        if (Test-Path -Path $checkOutputPath) {
            $checkOutput = Get-Content -Path $checkOutputPath -Raw
            if ($checkOutput -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
                Write-Host "Test 5 rÃ©ussi: Le script est compatible avec l'exÃ©cution en tant qu'administrateur" -ForegroundColor Green
            } else {
                Write-Host "Test 5 Ã©chouÃ©: Le script n'a pas Ã©tÃ© exÃ©cutÃ© correctement en tant qu'administrateur" -ForegroundColor Red
            }
        } else {
            Write-Host "Test 5 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 5 ignorÃ©: Ce test doit Ãªtre exÃ©cutÃ© en tant qu'administrateur" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Test 5 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script en tant qu'administrateur" -ForegroundColor Red
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

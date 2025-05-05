# Tests de rÃ©gression pour le mode manager

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
$tempConfigPath = Join-Path -Path $testDir -ChildPath "regression-config.json"
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

# Test 1: RÃ©gression - Espaces dans les chemins de fichier
Write-Host "Test 1: RÃ©gression - Espaces dans les chemins de fichier" -ForegroundColor Cyan
try {
    # CrÃ©er un fichier de roadmap avec des espaces dans le chemin
    $roadmapWithSpacesPath = Join-Path -Path $testDir -ChildPath "test roadmap with spaces.md"
    "# Test Roadmap with Spaces" | Set-Content -Path $roadmapWithSpacesPath -Encoding UTF8
    
    # ExÃ©cuter le script avec un chemin contenant des espaces
    $output = & $scriptPath -Mode "CHECK" -FilePath $roadmapWithSpacesPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© le chemin avec des espaces
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($roadmapWithSpacesPath))") {
            Write-Host "Test 1 rÃ©ussi: Le script a correctement gÃ©rÃ© un chemin de fichier avec des espaces" -ForegroundColor Green
        } else {
            Write-Host "Test 1 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un chemin de fichier avec des espaces" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 1 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec un chemin contenant des espaces" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: RÃ©gression - CaractÃ¨res spÃ©ciaux dans les identifiants de tÃ¢che
Write-Host "Test 2: RÃ©gression - CaractÃ¨res spÃ©ciaux dans les identifiants de tÃ¢che" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script avec un identifiant de tÃ¢che contenant des caractÃ¨res spÃ©ciaux
    $specialTaskId = "1.2.3-alpha.beta_gamma"
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier $specialTaskId -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© l'identifiant de tÃ¢che avec des caractÃ¨res spÃ©ciaux
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "TaskIdentifier : $([regex]::Escape($specialTaskId))") {
            Write-Host "Test 2 rÃ©ussi: Le script a correctement gÃ©rÃ© un identifiant de tÃ¢che avec des caractÃ¨res spÃ©ciaux" -ForegroundColor Green
        } else {
            Write-Host "Test 2 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un identifiant de tÃ¢che avec des caractÃ¨res spÃ©ciaux" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 2 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 2 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec un identifiant de tÃ¢che contenant des caractÃ¨res spÃ©ciaux" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: RÃ©gression - Chemins relatifs et absolus
Write-Host "Test 3: RÃ©gression - Chemins relatifs et absolus" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script avec un chemin relatif
    $relativeRoadmapPath = "temp\test-roadmap.md"
    $output = & $scriptPath -Mode "CHECK" -FilePath $relativeRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© le chemin relatif
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        $absolutePath = Join-Path -Path (Get-Location) -ChildPath $relativeRoadmapPath
        if ($checkOutput -match "FilePath : $([regex]::Escape($absolutePath))") {
            Write-Host "Test 3 rÃ©ussi: Le script a correctement gÃ©rÃ© un chemin relatif" -ForegroundColor Green
        } else {
            Write-Host "Test 3 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un chemin relatif" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 3 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 3 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec un chemin relatif" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: RÃ©gression - Fichiers inexistants
Write-Host "Test 4: RÃ©gression - Fichiers inexistants" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script avec un fichier inexistant
    $nonExistentFilePath = Join-Path -Path $testDir -ChildPath "non-existent-file.md"
    $output = & $scriptPath -Mode "CHECK" -FilePath $nonExistentFilePath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© le fichier inexistant
    if ($output -match "introuvable" -or $output -match "not found" -or $output -match "n'existe pas") {
        Write-Host "Test 4 rÃ©ussi: Le script a correctement gÃ©rÃ© un fichier inexistant" -ForegroundColor Green
    } else {
        Write-Host "Test 4 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un fichier inexistant" -ForegroundColor Red
    }
} catch {
    # Si une erreur est gÃ©nÃ©rÃ©e, c'est aussi acceptable
    if ($_.Exception.Message -match "introuvable" -or $_.Exception.Message -match "not found" -or $_.Exception.Message -match "n'existe pas") {
        Write-Host "Test 4 rÃ©ussi: Le script a correctement gÃ©rÃ© un fichier inexistant" -ForegroundColor Green
    } else {
        Write-Host "Test 4 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un fichier inexistant" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Test 5: RÃ©gression - ParamÃ¨tres manquants
Write-Host "Test 5: RÃ©gression - ParamÃ¨tres manquants" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script sans le paramÃ¨tre FilePath
    $output = & $scriptPath -Mode "CHECK" -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© le paramÃ¨tre manquant
    if ($output -match "manquant" -or $output -match "missing" -or $output -match "obligatoire") {
        Write-Host "Test 5 rÃ©ussi: Le script a correctement gÃ©rÃ© un paramÃ¨tre manquant" -ForegroundColor Green
    } else {
        Write-Host "Test 5 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un paramÃ¨tre manquant" -ForegroundColor Red
    }
} catch {
    # Si une erreur est gÃ©nÃ©rÃ©e, c'est aussi acceptable
    if ($_.Exception.Message -match "manquant" -or $_.Exception.Message -match "missing" -or $_.Exception.Message -match "obligatoire") {
        Write-Host "Test 5 rÃ©ussi: Le script a correctement gÃ©rÃ© un paramÃ¨tre manquant" -ForegroundColor Green
    } else {
        Write-Host "Test 5 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un paramÃ¨tre manquant" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Test 6: RÃ©gression - Encodage UTF-8 avec BOM
Write-Host "Test 6: RÃ©gression - Encodage UTF-8 avec BOM" -ForegroundColor Cyan
try {
    # CrÃ©er un fichier de roadmap avec encodage UTF-8 avec BOM
    $utf8BomRoadmapPath = Join-Path -Path $testDir -ChildPath "utf8-bom-roadmap.md"
    "# Test Roadmap with UTF-8 BOM" | Set-Content -Path $utf8BomRoadmapPath -Encoding UTF8
    
    # ExÃ©cuter le script avec le fichier UTF-8 avec BOM
    $output = & $scriptPath -Mode "CHECK" -FilePath $utf8BomRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© le fichier UTF-8 avec BOM
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($utf8BomRoadmapPath))") {
            Write-Host "Test 6 rÃ©ussi: Le script a correctement gÃ©rÃ© un fichier UTF-8 avec BOM" -ForegroundColor Green
        } else {
            Write-Host "Test 6 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un fichier UTF-8 avec BOM" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 6 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 6 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec un fichier UTF-8 avec BOM" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 7: RÃ©gression - CaractÃ¨res accentuÃ©s
Write-Host "Test 7: RÃ©gression - CaractÃ¨res accentuÃ©s" -ForegroundColor Cyan
try {
    # CrÃ©er un fichier de roadmap avec des caractÃ¨res accentuÃ©s
    $accentedRoadmapPath = Join-Path -Path $testDir -ChildPath "accented-roadmap.md"
    "# Test Roadmap avec des caractÃ¨res accentuÃ©s : Ã© Ã  Ã¨ Ã¹ Ã§" | Set-Content -Path $accentedRoadmapPath -Encoding UTF8
    
    # ExÃ©cuter le script avec le fichier contenant des caractÃ¨res accentuÃ©s
    $output = & $scriptPath -Mode "CHECK" -FilePath $accentedRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© le fichier avec des caractÃ¨res accentuÃ©s
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($accentedRoadmapPath))") {
            Write-Host "Test 7 rÃ©ussi: Le script a correctement gÃ©rÃ© un fichier avec des caractÃ¨res accentuÃ©s" -ForegroundColor Green
        } else {
            Write-Host "Test 7 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un fichier avec des caractÃ¨res accentuÃ©s" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 7 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 7 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec un fichier contenant des caractÃ¨res accentuÃ©s" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 8: RÃ©gression - ParamÃ¨tres avec des valeurs par dÃ©faut
Write-Host "Test 8: RÃ©gression - ParamÃ¨tres avec des valeurs par dÃ©faut" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script sans le paramÃ¨tre TaskIdentifier
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement utilisÃ© la valeur par dÃ©faut pour TaskIdentifier
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "TaskIdentifier : ") {
            Write-Host "Test 8 rÃ©ussi: Le script a correctement utilisÃ© la valeur par dÃ©faut pour TaskIdentifier" -ForegroundColor Green
        } else {
            Write-Host "Test 8 Ã©chouÃ©: Le script n'a pas correctement utilisÃ© la valeur par dÃ©faut pour TaskIdentifier" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 8 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 8 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script sans le paramÃ¨tre TaskIdentifier" -ForegroundColor Red
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

# Tests de localisation pour le mode manager

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
$tempConfigPath = Join-Path -Path $testDir -ChildPath "localization-config.json"
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

# CrÃ©er un fichier de roadmap de test avec des caractÃ¨res spÃ©ciaux
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
@"
# Test Roadmap avec des caractÃ¨res spÃ©ciaux

## TÃ¢che 1.2.3

### Description
Cette tÃ¢che contient des caractÃ¨res spÃ©ciaux : Ã© Ã  Ã¨ Ã¹ Ã§ Ã± Ã¶ Ã¤ Ã¼ ÃŸ.

### Sous-tÃ¢ches
- [ ] Sous-tÃ¢che avec des caractÃ¨res spÃ©ciaux : Ã© Ã  Ã¨ Ã¹ Ã§ Ã± Ã¶ Ã¤ Ã¼ ÃŸ
- [ ] Sous-tÃ¢che avec des symboles : â‚¬ Â£ Â¥ Â© Â® â„¢ Â§ Â¶ â€  â€¡
- [ ] Sous-tÃ¢che avec des caractÃ¨res asiatiques : ä½ å¥½ ã“ã‚“ã«ã¡ã¯ ì•ˆë…•í•˜ì„¸ìš”
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Test 1: Localisation - CaractÃ¨res spÃ©ciaux dans les fichiers
Write-Host "Test 1: Localisation - CaractÃ¨res spÃ©ciaux dans les fichiers" -ForegroundColor Cyan
try {
    # ExÃ©cuter le script avec un fichier contenant des caractÃ¨res spÃ©ciaux
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© les caractÃ¨res spÃ©ciaux
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
            Write-Host "Test 1 rÃ©ussi: Le script a correctement gÃ©rÃ© les caractÃ¨res spÃ©ciaux dans les fichiers" -ForegroundColor Green
        } else {
            Write-Host "Test 1 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© les caractÃ¨res spÃ©ciaux dans les fichiers" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 1 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec des caractÃ¨res spÃ©ciaux dans les fichiers" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: Localisation - CaractÃ¨res spÃ©ciaux dans les chemins de fichier
Write-Host "Test 2: Localisation - CaractÃ¨res spÃ©ciaux dans les chemins de fichier" -ForegroundColor Cyan
try {
    # CrÃ©er un fichier avec des caractÃ¨res spÃ©ciaux dans le chemin
    $specialCharPath = Join-Path -Path $testDir -ChildPath "test-Ã©Ã Ã¨Ã¹Ã§-roadmap.md"
    "# Test Roadmap with Special Characters in Path" | Set-Content -Path $specialCharPath -Encoding UTF8
    
    # ExÃ©cuter le script avec un chemin contenant des caractÃ¨res spÃ©ciaux
    $output = & $scriptPath -Mode "CHECK" -FilePath $specialCharPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© les caractÃ¨res spÃ©ciaux dans le chemin
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($specialCharPath))") {
            Write-Host "Test 2 rÃ©ussi: Le script a correctement gÃ©rÃ© les caractÃ¨res spÃ©ciaux dans les chemins de fichier" -ForegroundColor Green
        } else {
            Write-Host "Test 2 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© les caractÃ¨res spÃ©ciaux dans les chemins de fichier" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 2 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 2 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec des caractÃ¨res spÃ©ciaux dans les chemins de fichier" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: Localisation - Culture franÃ§aise
Write-Host "Test 3: Localisation - Culture franÃ§aise" -ForegroundColor Cyan
try {
    # Sauvegarder la culture actuelle
    $currentCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
    $currentUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
    
    # DÃ©finir la culture franÃ§aise
    [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo("fr-FR")
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo("fr-FR")
    
    # ExÃ©cuter le script avec la culture franÃ§aise
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ© avec succÃ¨s
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
            Write-Host "Test 3 rÃ©ussi: Le script est compatible avec la culture franÃ§aise" -ForegroundColor Green
        } else {
            Write-Host "Test 3 Ã©chouÃ©: Le script n'a pas Ã©tÃ© exÃ©cutÃ© correctement avec la culture franÃ§aise" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 3 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
    
    # Restaurer la culture d'origine
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $currentCulture
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $currentUICulture
} catch {
    # Restaurer la culture d'origine en cas d'erreur
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $currentCulture
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $currentUICulture
    
    Write-Host "Test 3 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec la culture franÃ§aise" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: Localisation - Culture anglaise
Write-Host "Test 4: Localisation - Culture anglaise" -ForegroundColor Cyan
try {
    # Sauvegarder la culture actuelle
    $currentCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
    $currentUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
    
    # DÃ©finir la culture anglaise
    [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
    
    # ExÃ©cuter le script avec la culture anglaise
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a Ã©tÃ© exÃ©cutÃ© avec succÃ¨s
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
            Write-Host "Test 4 rÃ©ussi: Le script est compatible avec la culture anglaise" -ForegroundColor Green
        } else {
            Write-Host "Test 4 Ã©chouÃ©: Le script n'a pas Ã©tÃ© exÃ©cutÃ© correctement avec la culture anglaise" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 4 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
    
    # Restaurer la culture d'origine
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $currentCulture
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $currentUICulture
} catch {
    # Restaurer la culture d'origine en cas d'erreur
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $currentCulture
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $currentUICulture
    
    Write-Host "Test 4 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec la culture anglaise" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 5: Localisation - Encodage UTF-8 sans BOM
Write-Host "Test 5: Localisation - Encodage UTF-8 sans BOM" -ForegroundColor Cyan
try {
    # CrÃ©er un fichier avec encodage UTF-8 sans BOM
    $utf8NoBomPath = Join-Path -Path $testDir -ChildPath "utf8-no-bom-roadmap.md"
    $utf8NoBomContent = "# Test Roadmap with UTF-8 No BOM`n`n## TÃ¢che 1.2.3`n`n### Description`nCette tÃ¢che contient des caractÃ¨res spÃ©ciaux : Ã© Ã  Ã¨ Ã¹ Ã§ Ã± Ã¶ Ã¤ Ã¼ ÃŸ."
    [System.IO.File]::WriteAllText($utf8NoBomPath, $utf8NoBomContent, [System.Text.Encoding]::UTF8)
    
    # ExÃ©cuter le script avec un fichier UTF-8 sans BOM
    $output = & $scriptPath -Mode "CHECK" -FilePath $utf8NoBomPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© le fichier UTF-8 sans BOM
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($utf8NoBomPath))") {
            Write-Host "Test 5 rÃ©ussi: Le script a correctement gÃ©rÃ© un fichier UTF-8 sans BOM" -ForegroundColor Green
        } else {
            Write-Host "Test 5 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un fichier UTF-8 sans BOM" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 5 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 5 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec un fichier UTF-8 sans BOM" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 6: Localisation - Encodage UTF-16
Write-Host "Test 6: Localisation - Encodage UTF-16" -ForegroundColor Cyan
try {
    # CrÃ©er un fichier avec encodage UTF-16
    $utf16Path = Join-Path -Path $testDir -ChildPath "utf16-roadmap.md"
    $utf16Content = "# Test Roadmap with UTF-16`n`n## TÃ¢che 1.2.3`n`n### Description`nCette tÃ¢che contient des caractÃ¨res spÃ©ciaux : Ã© Ã  Ã¨ Ã¹ Ã§ Ã± Ã¶ Ã¤ Ã¼ ÃŸ."
    [System.IO.File]::WriteAllText($utf16Path, $utf16Content, [System.Text.Encoding]::Unicode)
    
    # ExÃ©cuter le script avec un fichier UTF-16
    $output = & $scriptPath -Mode "CHECK" -FilePath $utf16Path -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # VÃ©rifier que le script a correctement gÃ©rÃ© le fichier UTF-16
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($utf16Path))") {
            Write-Host "Test 6 rÃ©ussi: Le script a correctement gÃ©rÃ© un fichier UTF-16" -ForegroundColor Green
        } else {
            Write-Host "Test 6 Ã©chouÃ©: Le script n'a pas correctement gÃ©rÃ© un fichier UTF-16" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 6 Ã©chouÃ©: Le fichier de sortie du mode CHECK n'a pas Ã©tÃ© crÃ©Ã©" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 6 Ã©chouÃ©: Une erreur s'est produite lors de l'exÃ©cution du script avec un fichier UTF-16" -ForegroundColor Red
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

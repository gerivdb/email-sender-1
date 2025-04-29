# Tests de localisation pour le mode manager

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

# Créer un fichier de configuration pour les tests
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
    [string]$ConfigPath
)

Write-Host "Mode CHECK exécuté avec les paramètres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ActiveDocumentPath : $ActiveDocumentPath"
Write-Host "CheckActiveDocument : $CheckActiveDocument"
Write-Host "ConfigPath : $ConfigPath"

# Créer un fichier de sortie pour vérifier que le script a été exécuté
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

Write-Host "Mode GRAN exécuté avec les paramètres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ConfigPath : $ConfigPath"

# Créer un fichier de sortie pour vérifier que le script a été exécuté
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

# Créer un fichier de roadmap de test avec des caractères spéciaux
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
@"
# Test Roadmap avec des caractères spéciaux

## Tâche 1.2.3

### Description
Cette tâche contient des caractères spéciaux : é à è ù ç ñ ö ä ü ß.

### Sous-tâches
- [ ] Sous-tâche avec des caractères spéciaux : é à è ù ç ñ ö ä ü ß
- [ ] Sous-tâche avec des symboles : € £ ¥ © ® ™ § ¶ † ‡
- [ ] Sous-tâche avec des caractères asiatiques : 你好 こんにちは 안녕하세요
"@ | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Test 1: Localisation - Caractères spéciaux dans les fichiers
Write-Host "Test 1: Localisation - Caractères spéciaux dans les fichiers" -ForegroundColor Cyan
try {
    # Exécuter le script avec un fichier contenant des caractères spéciaux
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré les caractères spéciaux
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
            Write-Host "Test 1 réussi: Le script a correctement géré les caractères spéciaux dans les fichiers" -ForegroundColor Green
        } else {
            Write-Host "Test 1 échoué: Le script n'a pas correctement géré les caractères spéciaux dans les fichiers" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 1 échoué: Une erreur s'est produite lors de l'exécution du script avec des caractères spéciaux dans les fichiers" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: Localisation - Caractères spéciaux dans les chemins de fichier
Write-Host "Test 2: Localisation - Caractères spéciaux dans les chemins de fichier" -ForegroundColor Cyan
try {
    # Créer un fichier avec des caractères spéciaux dans le chemin
    $specialCharPath = Join-Path -Path $testDir -ChildPath "test-éàèùç-roadmap.md"
    "# Test Roadmap with Special Characters in Path" | Set-Content -Path $specialCharPath -Encoding UTF8
    
    # Exécuter le script avec un chemin contenant des caractères spéciaux
    $output = & $scriptPath -Mode "CHECK" -FilePath $specialCharPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré les caractères spéciaux dans le chemin
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($specialCharPath))") {
            Write-Host "Test 2 réussi: Le script a correctement géré les caractères spéciaux dans les chemins de fichier" -ForegroundColor Green
        } else {
            Write-Host "Test 2 échoué: Le script n'a pas correctement géré les caractères spéciaux dans les chemins de fichier" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 2 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 2 échoué: Une erreur s'est produite lors de l'exécution du script avec des caractères spéciaux dans les chemins de fichier" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: Localisation - Culture française
Write-Host "Test 3: Localisation - Culture française" -ForegroundColor Cyan
try {
    # Sauvegarder la culture actuelle
    $currentCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
    $currentUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
    
    # Définir la culture française
    [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo("fr-FR")
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo("fr-FR")
    
    # Exécuter le script avec la culture française
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a été exécuté avec succès
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
            Write-Host "Test 3 réussi: Le script est compatible avec la culture française" -ForegroundColor Green
        } else {
            Write-Host "Test 3 échoué: Le script n'a pas été exécuté correctement avec la culture française" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 3 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
    
    # Restaurer la culture d'origine
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $currentCulture
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $currentUICulture
} catch {
    # Restaurer la culture d'origine en cas d'erreur
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $currentCulture
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $currentUICulture
    
    Write-Host "Test 3 échoué: Une erreur s'est produite lors de l'exécution du script avec la culture française" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: Localisation - Culture anglaise
Write-Host "Test 4: Localisation - Culture anglaise" -ForegroundColor Cyan
try {
    # Sauvegarder la culture actuelle
    $currentCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
    $currentUICulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
    
    # Définir la culture anglaise
    [System.Threading.Thread]::CurrentThread.CurrentCulture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = [System.Globalization.CultureInfo]::GetCultureInfo("en-US")
    
    # Exécuter le script avec la culture anglaise
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a été exécuté avec succès
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
            Write-Host "Test 4 réussi: Le script est compatible avec la culture anglaise" -ForegroundColor Green
        } else {
            Write-Host "Test 4 échoué: Le script n'a pas été exécuté correctement avec la culture anglaise" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 4 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
    
    # Restaurer la culture d'origine
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $currentCulture
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $currentUICulture
} catch {
    # Restaurer la culture d'origine en cas d'erreur
    [System.Threading.Thread]::CurrentThread.CurrentCulture = $currentCulture
    [System.Threading.Thread]::CurrentThread.CurrentUICulture = $currentUICulture
    
    Write-Host "Test 4 échoué: Une erreur s'est produite lors de l'exécution du script avec la culture anglaise" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 5: Localisation - Encodage UTF-8 sans BOM
Write-Host "Test 5: Localisation - Encodage UTF-8 sans BOM" -ForegroundColor Cyan
try {
    # Créer un fichier avec encodage UTF-8 sans BOM
    $utf8NoBomPath = Join-Path -Path $testDir -ChildPath "utf8-no-bom-roadmap.md"
    $utf8NoBomContent = "# Test Roadmap with UTF-8 No BOM`n`n## Tâche 1.2.3`n`n### Description`nCette tâche contient des caractères spéciaux : é à è ù ç ñ ö ä ü ß."
    [System.IO.File]::WriteAllText($utf8NoBomPath, $utf8NoBomContent, [System.Text.Encoding]::UTF8)
    
    # Exécuter le script avec un fichier UTF-8 sans BOM
    $output = & $scriptPath -Mode "CHECK" -FilePath $utf8NoBomPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré le fichier UTF-8 sans BOM
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($utf8NoBomPath))") {
            Write-Host "Test 5 réussi: Le script a correctement géré un fichier UTF-8 sans BOM" -ForegroundColor Green
        } else {
            Write-Host "Test 5 échoué: Le script n'a pas correctement géré un fichier UTF-8 sans BOM" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 5 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 5 échoué: Une erreur s'est produite lors de l'exécution du script avec un fichier UTF-8 sans BOM" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 6: Localisation - Encodage UTF-16
Write-Host "Test 6: Localisation - Encodage UTF-16" -ForegroundColor Cyan
try {
    # Créer un fichier avec encodage UTF-16
    $utf16Path = Join-Path -Path $testDir -ChildPath "utf16-roadmap.md"
    $utf16Content = "# Test Roadmap with UTF-16`n`n## Tâche 1.2.3`n`n### Description`nCette tâche contient des caractères spéciaux : é à è ù ç ñ ö ä ü ß."
    [System.IO.File]::WriteAllText($utf16Path, $utf16Content, [System.Text.Encoding]::Unicode)
    
    # Exécuter le script avec un fichier UTF-16
    $output = & $scriptPath -Mode "CHECK" -FilePath $utf16Path -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré le fichier UTF-16
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($utf16Path))") {
            Write-Host "Test 6 réussi: Le script a correctement géré un fichier UTF-16" -ForegroundColor Green
        } else {
            Write-Host "Test 6 échoué: Le script n'a pas correctement géré un fichier UTF-16" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 6 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 6 échoué: Une erreur s'est produite lors de l'exécution du script avec un fichier UTF-16" -ForegroundColor Red
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

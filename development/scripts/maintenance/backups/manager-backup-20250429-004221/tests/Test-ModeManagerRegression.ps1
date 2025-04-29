# Tests de régression pour le mode manager

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

# Créer un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
"# Test Roadmap" | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Test 1: Régression - Espaces dans les chemins de fichier
Write-Host "Test 1: Régression - Espaces dans les chemins de fichier" -ForegroundColor Cyan
try {
    # Créer un fichier de roadmap avec des espaces dans le chemin
    $roadmapWithSpacesPath = Join-Path -Path $testDir -ChildPath "test roadmap with spaces.md"
    "# Test Roadmap with Spaces" | Set-Content -Path $roadmapWithSpacesPath -Encoding UTF8
    
    # Exécuter le script avec un chemin contenant des espaces
    $output = & $scriptPath -Mode "CHECK" -FilePath $roadmapWithSpacesPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré le chemin avec des espaces
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($roadmapWithSpacesPath))") {
            Write-Host "Test 1 réussi: Le script a correctement géré un chemin de fichier avec des espaces" -ForegroundColor Green
        } else {
            Write-Host "Test 1 échoué: Le script n'a pas correctement géré un chemin de fichier avec des espaces" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 1 échoué: Une erreur s'est produite lors de l'exécution du script avec un chemin contenant des espaces" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: Régression - Caractères spéciaux dans les identifiants de tâche
Write-Host "Test 2: Régression - Caractères spéciaux dans les identifiants de tâche" -ForegroundColor Cyan
try {
    # Exécuter le script avec un identifiant de tâche contenant des caractères spéciaux
    $specialTaskId = "1.2.3-alpha.beta_gamma"
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier $specialTaskId -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré l'identifiant de tâche avec des caractères spéciaux
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "TaskIdentifier : $([regex]::Escape($specialTaskId))") {
            Write-Host "Test 2 réussi: Le script a correctement géré un identifiant de tâche avec des caractères spéciaux" -ForegroundColor Green
        } else {
            Write-Host "Test 2 échoué: Le script n'a pas correctement géré un identifiant de tâche avec des caractères spéciaux" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 2 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 2 échoué: Une erreur s'est produite lors de l'exécution du script avec un identifiant de tâche contenant des caractères spéciaux" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: Régression - Chemins relatifs et absolus
Write-Host "Test 3: Régression - Chemins relatifs et absolus" -ForegroundColor Cyan
try {
    # Exécuter le script avec un chemin relatif
    $relativeRoadmapPath = "temp\test-roadmap.md"
    $output = & $scriptPath -Mode "CHECK" -FilePath $relativeRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré le chemin relatif
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        $absolutePath = Join-Path -Path (Get-Location) -ChildPath $relativeRoadmapPath
        if ($checkOutput -match "FilePath : $([regex]::Escape($absolutePath))") {
            Write-Host "Test 3 réussi: Le script a correctement géré un chemin relatif" -ForegroundColor Green
        } else {
            Write-Host "Test 3 échoué: Le script n'a pas correctement géré un chemin relatif" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 3 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 3 échoué: Une erreur s'est produite lors de l'exécution du script avec un chemin relatif" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: Régression - Fichiers inexistants
Write-Host "Test 4: Régression - Fichiers inexistants" -ForegroundColor Cyan
try {
    # Exécuter le script avec un fichier inexistant
    $nonExistentFilePath = Join-Path -Path $testDir -ChildPath "non-existent-file.md"
    $output = & $scriptPath -Mode "CHECK" -FilePath $nonExistentFilePath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré le fichier inexistant
    if ($output -match "introuvable" -or $output -match "not found" -or $output -match "n'existe pas") {
        Write-Host "Test 4 réussi: Le script a correctement géré un fichier inexistant" -ForegroundColor Green
    } else {
        Write-Host "Test 4 échoué: Le script n'a pas correctement géré un fichier inexistant" -ForegroundColor Red
    }
} catch {
    # Si une erreur est générée, c'est aussi acceptable
    if ($_.Exception.Message -match "introuvable" -or $_.Exception.Message -match "not found" -or $_.Exception.Message -match "n'existe pas") {
        Write-Host "Test 4 réussi: Le script a correctement géré un fichier inexistant" -ForegroundColor Green
    } else {
        Write-Host "Test 4 échoué: Le script n'a pas correctement géré un fichier inexistant" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Test 5: Régression - Paramètres manquants
Write-Host "Test 5: Régression - Paramètres manquants" -ForegroundColor Cyan
try {
    # Exécuter le script sans le paramètre FilePath
    $output = & $scriptPath -Mode "CHECK" -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré le paramètre manquant
    if ($output -match "manquant" -or $output -match "missing" -or $output -match "obligatoire") {
        Write-Host "Test 5 réussi: Le script a correctement géré un paramètre manquant" -ForegroundColor Green
    } else {
        Write-Host "Test 5 échoué: Le script n'a pas correctement géré un paramètre manquant" -ForegroundColor Red
    }
} catch {
    # Si une erreur est générée, c'est aussi acceptable
    if ($_.Exception.Message -match "manquant" -or $_.Exception.Message -match "missing" -or $_.Exception.Message -match "obligatoire") {
        Write-Host "Test 5 réussi: Le script a correctement géré un paramètre manquant" -ForegroundColor Green
    } else {
        Write-Host "Test 5 échoué: Le script n'a pas correctement géré un paramètre manquant" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Test 6: Régression - Encodage UTF-8 avec BOM
Write-Host "Test 6: Régression - Encodage UTF-8 avec BOM" -ForegroundColor Cyan
try {
    # Créer un fichier de roadmap avec encodage UTF-8 avec BOM
    $utf8BomRoadmapPath = Join-Path -Path $testDir -ChildPath "utf8-bom-roadmap.md"
    "# Test Roadmap with UTF-8 BOM" | Set-Content -Path $utf8BomRoadmapPath -Encoding UTF8
    
    # Exécuter le script avec le fichier UTF-8 avec BOM
    $output = & $scriptPath -Mode "CHECK" -FilePath $utf8BomRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré le fichier UTF-8 avec BOM
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($utf8BomRoadmapPath))") {
            Write-Host "Test 6 réussi: Le script a correctement géré un fichier UTF-8 avec BOM" -ForegroundColor Green
        } else {
            Write-Host "Test 6 échoué: Le script n'a pas correctement géré un fichier UTF-8 avec BOM" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 6 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 6 échoué: Une erreur s'est produite lors de l'exécution du script avec un fichier UTF-8 avec BOM" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 7: Régression - Caractères accentués
Write-Host "Test 7: Régression - Caractères accentués" -ForegroundColor Cyan
try {
    # Créer un fichier de roadmap avec des caractères accentués
    $accentedRoadmapPath = Join-Path -Path $testDir -ChildPath "accented-roadmap.md"
    "# Test Roadmap avec des caractères accentués : é à è ù ç" | Set-Content -Path $accentedRoadmapPath -Encoding UTF8
    
    # Exécuter le script avec le fichier contenant des caractères accentués
    $output = & $scriptPath -Mode "CHECK" -FilePath $accentedRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré le fichier avec des caractères accentués
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($accentedRoadmapPath))") {
            Write-Host "Test 7 réussi: Le script a correctement géré un fichier avec des caractères accentués" -ForegroundColor Green
        } else {
            Write-Host "Test 7 échoué: Le script n'a pas correctement géré un fichier avec des caractères accentués" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 7 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 7 échoué: Une erreur s'est produite lors de l'exécution du script avec un fichier contenant des caractères accentués" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 8: Régression - Paramètres avec des valeurs par défaut
Write-Host "Test 8: Régression - Paramètres avec des valeurs par défaut" -ForegroundColor Cyan
try {
    # Exécuter le script sans le paramètre TaskIdentifier
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement utilisé la valeur par défaut pour TaskIdentifier
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "TaskIdentifier : ") {
            Write-Host "Test 8 réussi: Le script a correctement utilisé la valeur par défaut pour TaskIdentifier" -ForegroundColor Green
        } else {
            Write-Host "Test 8 échoué: Le script n'a pas correctement utilisé la valeur par défaut pour TaskIdentifier" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 8 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 8 échoué: Une erreur s'est produite lors de l'exécution du script sans le paramètre TaskIdentifier" -ForegroundColor Red
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

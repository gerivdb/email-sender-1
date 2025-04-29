# Test des configurations spéciales pour le mode manager

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

# Créer un fichier de configuration avec des chemins relatifs
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

# Créer un fichier de configuration avec des modes personnalisés
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

# Créer un fichier de configuration avec des modes désactivés
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

# Créer un fichier de configuration avec des paramètres par défaut
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
    [string]$CustomParam1,

    [Parameter(Mandatory = $false)]
    [string]$CustomParam2,

    [Parameter(Mandatory = $false)]
    [string]$DefaultParam1,

    [Parameter(Mandatory = $false)]
    [string]$DefaultParam2
)

Write-Host "Mode CHECK exécuté avec les paramètres suivants :"
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

# Créer un fichier de sortie pour vérifier que le script a été exécuté
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

# Test 1: Configuration avec chemins relatifs
Write-Host "Test 1: Configuration avec chemins relatifs" -ForegroundColor Cyan
try {
    # Supprimer les fichiers de sortie des tests précédents
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        Remove-Item -Path $checkOutputPath -Force
    }
    
    # Exécuter le script avec la configuration relative
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $relativeConfigPath
    
    # Vérifier que le mode CHECK a été exécuté
    if (Test-Path -Path $checkOutputPath) {
        $output = Get-Content -Path $checkOutputPath -Raw
        if ($output -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
            Write-Host "Test 1 réussi: Le script a exécuté le mode CHECK avec un chemin relatif" -ForegroundColor Green
        } else {
            Write-Host "Test 1 échoué: Le script n'a pas exécuté le mode CHECK avec les bons paramètres" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 1 échoué: Une erreur s'est produite lors de l'exécution du script avec une configuration relative" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: Configuration avec des modes personnalisés
Write-Host "Test 2: Configuration avec des modes personnalisés" -ForegroundColor Cyan
try {
    # Supprimer les fichiers de sortie des tests précédents
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        Remove-Item -Path $checkOutputPath -Force
    }
    
    # Exécuter le script avec la configuration personnalisée
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $customConfigPath
    
    # Vérifier que le mode CHECK a été exécuté avec les paramètres personnalisés
    if (Test-Path -Path $checkOutputPath) {
        $output = Get-Content -Path $checkOutputPath -Raw
        $success = $true
        
        if (-not ($output -match "CustomParam1 : Value1")) {
            Write-Host "Test 2 échoué: Le mode CHECK n'a pas reçu le paramètre CustomParam1" -ForegroundColor Red
            $success = $false
        }
        
        if (-not ($output -match "CustomParam2 : Value2")) {
            Write-Host "Test 2 échoué: Le mode CHECK n'a pas reçu le paramètre CustomParam2" -ForegroundColor Red
            $success = $false
        }
        
        if ($success) {
            Write-Host "Test 2 réussi: Le script a exécuté le mode CHECK avec des paramètres personnalisés" -ForegroundColor Green
        }
    } else {
        Write-Host "Test 2 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 2 échoué: Une erreur s'est produite lors de l'exécution du script avec une configuration personnalisée" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: Configuration avec des modes désactivés
Write-Host "Test 3: Configuration avec des modes désactivés" -ForegroundColor Cyan
try {
    # Supprimer les fichiers de sortie des tests précédents
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    $granOutputPath = Join-Path -Path $testDir -ChildPath "gran-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        Remove-Item -Path $checkOutputPath -Force
    }
    if (Test-Path -Path $granOutputPath) {
        Remove-Item -Path $granOutputPath -Force
    }
    
    # Exécuter le script avec la configuration désactivée pour CHECK
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $disabledConfigPath
    
    # Vérifier que le mode CHECK n'a pas été exécuté
    if (Test-Path -Path $checkOutputPath) {
        Write-Host "Test 3 échoué: Le fichier de sortie du mode CHECK a été créé alors qu'il ne devrait pas l'être" -ForegroundColor Red
    } else {
        Write-Host "Test 3 réussi: Le script n'a pas exécuté le mode CHECK désactivé" -ForegroundColor Green
    }
    
    # Exécuter le script avec la configuration activée pour GRAN
    & $scriptPath -Mode "GRAN" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $disabledConfigPath
    
    # Vérifier que le mode GRAN a été exécuté
    if (Test-Path -Path $granOutputPath) {
        $output = Get-Content -Path $granOutputPath -Raw
        if ($output -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
            Write-Host "Test 3 réussi: Le script a exécuté le mode GRAN activé" -ForegroundColor Green
        } else {
            Write-Host "Test 3 échoué: Le script n'a pas exécuté le mode GRAN avec les bons paramètres" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 3 échoué: Le fichier de sortie du mode GRAN n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 3 échoué: Une erreur s'est produite lors de l'exécution du script avec une configuration désactivée" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 4: Configuration avec des paramètres par défaut
Write-Host "Test 4: Configuration avec des paramètres par défaut" -ForegroundColor Cyan
try {
    # Supprimer les fichiers de sortie des tests précédents
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        Remove-Item -Path $checkOutputPath -Force
    }
    
    # Exécuter le script avec la configuration par défaut
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $defaultsConfigPath
    
    # Vérifier que le mode CHECK a été exécuté avec les paramètres par défaut
    if (Test-Path -Path $checkOutputPath) {
        $output = Get-Content -Path $checkOutputPath -Raw
        $success = $true
        
        if (-not ($output -match "DefaultParam1 : DefaultValue1")) {
            Write-Host "Test 4 échoué: Le mode CHECK n'a pas reçu le paramètre DefaultParam1" -ForegroundColor Red
            $success = $false
        }
        
        if (-not ($output -match "DefaultParam2 : DefaultValue2")) {
            Write-Host "Test 4 échoué: Le mode CHECK n'a pas reçu le paramètre DefaultParam2" -ForegroundColor Red
            $success = $false
        }
        
        if ($success) {
            Write-Host "Test 4 réussi: Le script a exécuté le mode CHECK avec des paramètres par défaut" -ForegroundColor Green
        }
    } else {
        Write-Host "Test 4 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 4 échoué: Une erreur s'est produite lors de l'exécution du script avec une configuration par défaut" -ForegroundColor Red
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

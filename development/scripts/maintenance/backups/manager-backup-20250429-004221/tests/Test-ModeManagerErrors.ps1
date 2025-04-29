# Test de la gestion des erreurs pour le mode manager

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

# Créer un fichier de configuration temporaire pour les tests d'erreur
$tempConfigPath = Join-Path -Path $testDir -ChildPath "errors-config.json"
@{
    General = @{
        RoadmapPath        = "docs\plans\roadmap_complete_2.md"
        ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
        ReportPath         = "reports"
    }
    Modes   = @{
        Check   = @{
            Enabled    = $true
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-check-mode.ps1"
        }
        Error   = @{
            Enabled    = $true
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-error-mode.ps1"
        }
        Missing = @{
            Enabled    = $true
            ScriptPath = "non-existent-script.ps1"
        }
        Invalid = @{
            Enabled    = $true
            ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "mock-invalid-mode.ps1"
        }
    }
} | ConvertTo-Json -Depth 5 | Set-Content -Path $tempConfigPath -Encoding UTF8

# Créer un fichier de configuration invalide
$invalidConfigPath = Join-Path -Path $testDir -ChildPath "invalid-config.json"
"This is not a valid JSON file" | Set-Content -Path $invalidConfigPath -Encoding UTF8

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

$mockErrorModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-error-mode.ps1"
$mockErrorContent = @'
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

Write-Host "Mode ERROR exécuté avec les paramètres suivants :"
Write-Host "FilePath : $FilePath"
Write-Host "TaskIdentifier : $TaskIdentifier"
Write-Host "Force : $Force"
Write-Host "ConfigPath : $ConfigPath"

# Créer un fichier de sortie pour vérifier que le script a été exécuté
$outputPath = Join-Path -Path "$PSScriptRoot\temp" -ChildPath "error-mode-output.txt"
@"
FilePath : $FilePath
TaskIdentifier : $TaskIdentifier
Force : $Force
ConfigPath : $ConfigPath
"@ | Set-Content -Path $outputPath -Encoding UTF8

# Simuler une erreur
Write-Error "Erreur simulée dans le mode ERROR"
exit 1
'@
Set-Content -Path $mockErrorModePath -Value $mockErrorContent -Encoding UTF8

$mockInvalidModePath = Join-Path -Path $PSScriptRoot -ChildPath "mock-invalid-mode.ps1"
$mockInvalidContent = @'
# Ce script contient une erreur de syntaxe
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

# Erreur de syntaxe intentionnelle
if ($FilePath -eq $null) {
    Write-Host "FilePath est null"
} else {
    Write-Host "FilePath : $FilePath"
}

# Cette ligne contient une erreur de syntaxe
$variable = "Valeur
'@
Set-Content -Path $mockInvalidModePath -Value $mockInvalidContent -Encoding UTF8

# Créer un fichier de roadmap de test
$testRoadmapPath = Join-Path -Path $testDir -ChildPath "test-roadmap.md"
"# Test Roadmap" | Set-Content -Path $testRoadmapPath -Encoding UTF8

# Test 1: Mode inexistant
Write-Host "Test 1: Mode inexistant" -ForegroundColor Cyan
try {
    & $scriptPath -Mode "NONEXISTENT" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    Write-Host "Test 1 échoué: Le script n'a pas généré d'erreur pour un mode inexistant" -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "n'appartient pas au jeu" -or $_.Exception.Message -match "ValidateSet") {
        Write-Host "Test 1 réussi: Le script a généré une erreur pour un mode inexistant" -ForegroundColor Green
    } else {
        Write-Host "Test 1 échoué: Le script a généré une erreur inattendue pour un mode inexistant" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Test 2: Script introuvable
Write-Host "Test 2: Script introuvable" -ForegroundColor Cyan
try {
    # Nous utilisons le mode CHECK avec un chemin de script inexistant
    # Modifions temporairement la configuration pour que le chemin du script CHECK soit inexistant
    $tempConfigPath2 = Join-Path -Path $testDir -ChildPath "missing-script-config.json"
    $config = @{
        General = @{
            RoadmapPath        = "docs\plans\roadmap_complete_2.md"
            ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
            ReportPath         = "reports"
        }
        Modes   = @{
            Check = @{
                Enabled    = $true
                ScriptPath = "non-existent-script.ps1"
            }
        }
    }
    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $tempConfigPath2 -Encoding UTF8

    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath2
    Write-Host "Test 2 échoué: Le script n'a pas généré d'erreur pour un script introuvable" -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "Script .* introuvable" -or $_.Exception.Message -match "Le script .* est introuvable" -or $_.Exception.Message -match "Impossible de trouver le chemin") {
        Write-Host "Test 2 réussi: Le script a généré une erreur pour un script introuvable" -ForegroundColor Green
    } else {
        Write-Host "Test 2 échoué: Le script a généré une erreur inattendue pour un script introuvable" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Test 3: Erreur d'exécution
Write-Host "Test 3: Erreur d'exécution" -ForegroundColor Cyan
try {
    # Nous utilisons le mode CHECK avec un script qui génère une erreur
    # Modifions temporairement la configuration pour que le script CHECK génère une erreur
    $tempConfigPath3 = Join-Path -Path $testDir -ChildPath "error-script-config.json"
    $errorScriptPath = Join-Path -Path $testDir -ChildPath "error-script.ps1"

    # Créer un script qui génère une erreur
    @'
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

Write-Error "Erreur simulée dans le script"
exit 1
'@ | Set-Content -Path $errorScriptPath -Encoding UTF8

    $config = @{
        General = @{
            RoadmapPath        = "docs\plans\roadmap_complete_2.md"
            ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
            ReportPath         = "reports"
        }
        Modes   = @{
            Check = @{
                Enabled    = $true
                ScriptPath = $errorScriptPath
            }
        }
    }
    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $tempConfigPath3 -Encoding UTF8

    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath3
    Write-Host "Test 3 échoué: Le script n'a pas généré d'erreur pour une erreur d'exécution" -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "Erreur lors de l'exécution du mode" -or $_.Exception.Message -match "Code de sortie : 1" -or $_.Exception.Message -match "Erreur simulée") {
        Write-Host "Test 3 réussi: Le script a généré une erreur pour une erreur d'exécution" -ForegroundColor Green
    } else {
        Write-Host "Test 3 échoué: Le script a généré une erreur inattendue pour une erreur d'exécution" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Test 4: Script invalide
Write-Host "Test 4: Script invalide" -ForegroundColor Cyan
try {
    # Nous utilisons le mode CHECK avec un script invalide
    # Modifions temporairement la configuration pour que le script CHECK soit invalide
    $tempConfigPath4 = Join-Path -Path $testDir -ChildPath "invalid-script-config.json"
    $invalidScriptPath = Join-Path -Path $testDir -ChildPath "invalid-script.ps1"

    # Créer un script avec une erreur de syntaxe
    @'
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

# Erreur de syntaxe intentionnelle
$variable = "Valeur
'@ | Set-Content -Path $invalidScriptPath -Encoding UTF8

    $config = @{
        General = @{
            RoadmapPath        = "docs\plans\roadmap_complete_2.md"
            ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
            ReportPath         = "reports"
        }
        Modes   = @{
            Check = @{
                Enabled    = $true
                ScriptPath = $invalidScriptPath
            }
        }
    }
    $config | ConvertTo-Json -Depth 5 | Set-Content -Path $tempConfigPath4 -Encoding UTF8

    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath4
    Write-Host "Test 4 échoué: Le script n'a pas généré d'erreur pour un script invalide" -ForegroundColor Red
} catch {
    if ($_.Exception.Message -match "Erreur lors de l'exécution du mode" -or $_.Exception.Message -match "erreur de syntaxe" -or $_.Exception.Message -match "Impossible d'analyser") {
        Write-Host "Test 4 réussi: Le script a généré une erreur pour un script invalide" -ForegroundColor Green
    } else {
        Write-Host "Test 4 échoué: Le script a généré une erreur inattendue pour un script invalide" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Test 5: Configuration invalide
Write-Host "Test 5: Configuration invalide" -ForegroundColor Cyan
$result = $null
try {
    $result = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $invalidConfigPath
    if ($result -eq $false) {
        Write-Host "Test 5 réussi: Le script a généré une erreur pour une configuration invalide" -ForegroundColor Green
    } else {
        Write-Host "Test 5 échoué: Le script n'a pas généré d'erreur pour une configuration invalide" -ForegroundColor Red
    }
} catch {
    if ($_.Exception.Message -match "Erreur lors du chargement de la configuration" -or $_.Exception.Message -match "JSON invalide") {
        Write-Host "Test 5 réussi: Le script a généré une erreur pour une configuration invalide" -ForegroundColor Green
    } else {
        Write-Host "Test 5 échoué: Le script a généré une erreur inattendue pour une configuration invalide" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Test 6: Configuration manquante
Write-Host "Test 6: Configuration manquante" -ForegroundColor Cyan
$result = $null
try {
    $nonExistentConfigPath = Join-Path -Path $testDir -ChildPath "non-existent-config.json"
    $result = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $nonExistentConfigPath

    # Le script devrait utiliser une configuration par défaut et continuer l'exécution
    if ($result -eq $true) {
        Write-Host "Test 6 réussi: Le script a utilisé une configuration par défaut pour une configuration manquante" -ForegroundColor Green
    } else {
        Write-Host "Test 6 échoué: Le script n'a pas utilisé une configuration par défaut pour une configuration manquante" -ForegroundColor Red
    }
} catch {
    # Si le script génère une erreur, c'est aussi acceptable car il peut être configuré pour échouer
    # si la configuration est manquante
    if ($_.Exception.Message -match "Fichier de configuration introuvable" -or $_.Exception.Message -match "configuration manquante") {
        Write-Host "Test 6 réussi: Le script a généré une erreur appropriée pour une configuration manquante" -ForegroundColor Green
    } else {
        Write-Host "Test 6 échoué: Le script a généré une erreur inattendue pour une configuration manquante" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Test 7: Paramètres manquants
Write-Host "Test 7: Paramètres manquants" -ForegroundColor Cyan
try {
    & $scriptPath
    Write-Host "Test 7 réussi: Le script a été exécuté sans paramètres" -ForegroundColor Green
} catch {
    Write-Host "Test 7 échoué: Le script a généré une erreur pour des paramètres manquants" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
Write-Host "Nettoyage des fichiers temporaires..." -ForegroundColor Cyan
if (Test-Path -Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force
}

$mockFiles = @(
    "mock-check-mode.ps1",
    "mock-error-mode.ps1",
    "mock-invalid-mode.ps1"
)

foreach ($file in $mockFiles) {
    $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
    if (Test-Path -Path $filePath) {
        Remove-Item -Path $filePath -Force
    }
}

Write-Host "Tests terminés." -ForegroundColor Cyan

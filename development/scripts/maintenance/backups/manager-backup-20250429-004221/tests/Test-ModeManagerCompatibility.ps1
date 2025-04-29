# Tests de compatibilité pour le mode manager

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

# Test 1: Compatibilité - PowerShell 5.1
Write-Host "Test 1: Compatibilité - PowerShell 5.1" -ForegroundColor Cyan
try {
    # Vérifier la version de PowerShell
    $psVersion = $PSVersionTable.PSVersion
    if ($psVersion.Major -eq 5 -and $psVersion.Minor -eq 1) {
        # Exécuter le script avec PowerShell 5.1
        $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
        
        # Vérifier que le script a été exécuté avec succès
        $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
        if (Test-Path -Path $checkOutputPath) {
            $checkOutput = Get-Content -Path $checkOutputPath -Raw
            if ($checkOutput -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
                Write-Host "Test 1 réussi: Le script est compatible avec PowerShell 5.1" -ForegroundColor Green
            } else {
                Write-Host "Test 1 échoué: Le script n'a pas été exécuté correctement avec PowerShell 5.1" -ForegroundColor Red
            }
        } else {
            Write-Host "Test 1 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 1 ignoré: Ce test doit être exécuté avec PowerShell 5.1" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Test 1 échoué: Une erreur s'est produite lors de l'exécution du script avec PowerShell 5.1" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 2: Compatibilité - PowerShell 7
Write-Host "Test 2: Compatibilité - PowerShell 7" -ForegroundColor Cyan
try {
    # Vérifier si PowerShell 7 est installé
    $pwsh = Get-Command -Name pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        # Créer un script temporaire pour exécuter le test avec PowerShell 7
        $tempScriptPath = Join-Path -Path $testDir -ChildPath "test-ps7.ps1"
        @"
# Définir le chemin du script à tester
`$scriptPath = "$scriptPath"

# Définir le chemin du fichier de roadmap
`$testRoadmapPath = "$testRoadmapPath"

# Définir le chemin du fichier de configuration
`$tempConfigPath = "$tempConfigPath"

# Exécuter le script avec PowerShell 7
`$output = & `$scriptPath -Mode "CHECK" -FilePath `$testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath `$tempConfigPath 2>&1

# Vérifier que le script a été exécuté avec succès
`$checkOutputPath = "$testDir\check-mode-output.txt"
if (Test-Path -Path `$checkOutputPath) {
    `$checkOutput = Get-Content -Path `$checkOutputPath -Raw
    if (`$checkOutput -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
        Write-Host "Le script est compatible avec PowerShell 7" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "Le script n'a pas été exécuté correctement avec PowerShell 7" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    exit 1
}
"@ | Set-Content -Path $tempScriptPath -Encoding UTF8
        
        # Exécuter le script avec PowerShell 7
        $result = & $pwsh -File $tempScriptPath
        
        if ($result -match "compatible avec PowerShell 7") {
            Write-Host "Test 2 réussi: Le script est compatible avec PowerShell 7" -ForegroundColor Green
        } else {
            Write-Host "Test 2 échoué: Le script n'a pas été exécuté correctement avec PowerShell 7" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 2 ignoré: PowerShell 7 n'est pas installé" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Test 2 échoué: Une erreur s'est produite lors de l'exécution du script avec PowerShell 7" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 3: Compatibilité - Chemins UNC
Write-Host "Test 3: Compatibilité - Chemins UNC" -ForegroundColor Cyan
try {
    # Créer un chemin UNC simulé
    $uncPath = "\\localhost\c$\temp\test-roadmap.md"
    
    # Exécuter le script avec un chemin UNC
    $output = & $scriptPath -Mode "CHECK" -FilePath $uncPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré le chemin UNC
    if ($output -match "introuvable" -or $output -match "not found" -or $output -match "n'existe pas") {
        Write-Host "Test 3 réussi: Le script a correctement géré un chemin UNC" -ForegroundColor Green
    } else {
        Write-Host "Test 3 échoué: Le script n'a pas correctement géré un chemin UNC" -ForegroundColor Red
    }
} catch {
    # Si une erreur est générée, c'est aussi acceptable
    if ($_.Exception.Message -match "introuvable" -or $_.Exception.Message -match "not found" -or $_.Exception.Message -match "n'existe pas") {
        Write-Host "Test 3 réussi: Le script a correctement géré un chemin UNC" -ForegroundColor Green
    } else {
        Write-Host "Test 3 échoué: Le script n'a pas correctement géré un chemin UNC" -ForegroundColor Red
        Write-Host "Erreur: $_" -ForegroundColor Red
    }
}

# Test 4: Compatibilité - Chemins longs
Write-Host "Test 4: Compatibilité - Chemins longs" -ForegroundColor Cyan
try {
    # Créer un chemin long
    $longPath = Join-Path -Path $testDir -ChildPath ("a" * 200 + ".md")
    "# Test Roadmap with Long Path" | Set-Content -Path $longPath -Encoding UTF8
    
    # Exécuter le script avec un chemin long
    $output = & $scriptPath -Mode "CHECK" -FilePath $longPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier que le script a correctement géré le chemin long
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($longPath))") {
            Write-Host "Test 4 réussi: Le script a correctement géré un chemin long" -ForegroundColor Green
        } else {
            Write-Host "Test 4 échoué: Le script n'a pas correctement géré un chemin long" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 4 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    Write-Host "Test 4 échoué: Une erreur s'est produite lors de l'exécution du script avec un chemin long" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 5: Compatibilité - Exécution en tant qu'administrateur
Write-Host "Test 5: Compatibilité - Exécution en tant qu'administrateur" -ForegroundColor Cyan
try {
    # Vérifier si le script est exécuté en tant qu'administrateur
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        # Exécuter le script en tant qu'administrateur
        $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
        
        # Vérifier que le script a été exécuté avec succès
        $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
        if (Test-Path -Path $checkOutputPath) {
            $checkOutput = Get-Content -Path $checkOutputPath -Raw
            if ($checkOutput -match "FilePath : $([regex]::Escape($testRoadmapPath))") {
                Write-Host "Test 5 réussi: Le script est compatible avec l'exécution en tant qu'administrateur" -ForegroundColor Green
            } else {
                Write-Host "Test 5 échoué: Le script n'a pas été exécuté correctement en tant qu'administrateur" -ForegroundColor Red
            }
        } else {
            Write-Host "Test 5 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 5 ignoré: Ce test doit être exécuté en tant qu'administrateur" -ForegroundColor Yellow
    }
} catch {
    Write-Host "Test 5 échoué: Une erreur s'est produite lors de l'exécution du script en tant qu'administrateur" -ForegroundColor Red
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

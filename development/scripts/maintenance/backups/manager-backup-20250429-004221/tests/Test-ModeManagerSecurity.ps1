# Tests de sécurité pour le mode manager

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

# Test 1: Injection de commandes dans les paramètres
Write-Host "Test 1: Injection de commandes dans les paramètres" -ForegroundColor Cyan
try {
    # Tenter d'injecter une commande dans le paramètre FilePath
    $injectionFilePath = "$testRoadmapPath; Write-Host 'Injection réussie' -ForegroundColor Red"
    
    # Exécuter le script avec le paramètre injecté
    $output = & $scriptPath -Mode "CHECK" -FilePath $injectionFilePath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier si l'injection a réussi
    if ($output -match "Injection réussie") {
        Write-Host "Test 1 échoué: L'injection de commandes a réussi" -ForegroundColor Red
    } else {
        Write-Host "Test 1 réussi: L'injection de commandes a échoué" -ForegroundColor Green
    }
} catch {
    # Si une erreur est générée, c'est aussi acceptable
    Write-Host "Test 1 réussi: L'injection de commandes a généré une erreur" -ForegroundColor Green
    Write-Host "Erreur: $_" -ForegroundColor Cyan
}

# Test 2: Injection de commandes dans le paramètre TaskIdentifier
Write-Host "Test 2: Injection de commandes dans le paramètre TaskIdentifier" -ForegroundColor Cyan
try {
    # Tenter d'injecter une commande dans le paramètre TaskIdentifier
    $injectionTaskId = "1.2.3; Write-Host 'Injection réussie' -ForegroundColor Red"
    
    # Exécuter le script avec le paramètre injecté
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier $injectionTaskId -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier si l'injection a réussi
    if ($output -match "Injection réussie") {
        Write-Host "Test 2 échoué: L'injection de commandes a réussi" -ForegroundColor Red
    } else {
        Write-Host "Test 2 réussi: L'injection de commandes a échoué" -ForegroundColor Green
    }
} catch {
    # Si une erreur est générée, c'est aussi acceptable
    Write-Host "Test 2 réussi: L'injection de commandes a généré une erreur" -ForegroundColor Green
    Write-Host "Erreur: $_" -ForegroundColor Cyan
}

# Test 3: Injection de commandes dans le paramètre ConfigPath
Write-Host "Test 3: Injection de commandes dans le paramètre ConfigPath" -ForegroundColor Cyan
try {
    # Tenter d'injecter une commande dans le paramètre ConfigPath
    $injectionConfigPath = "$tempConfigPath; Write-Host 'Injection réussie' -ForegroundColor Red"
    
    # Exécuter le script avec le paramètre injecté
    $output = & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $injectionConfigPath 2>&1
    
    # Vérifier si l'injection a réussi
    if ($output -match "Injection réussie") {
        Write-Host "Test 3 échoué: L'injection de commandes a réussi" -ForegroundColor Red
    } else {
        Write-Host "Test 3 réussi: L'injection de commandes a échoué" -ForegroundColor Green
    }
} catch {
    # Si une erreur est générée, c'est aussi acceptable
    Write-Host "Test 3 réussi: L'injection de commandes a généré une erreur" -ForegroundColor Green
    Write-Host "Erreur: $_" -ForegroundColor Cyan
}

# Test 4: Injection de commandes dans le paramètre Mode
Write-Host "Test 4: Injection de commandes dans le paramètre Mode" -ForegroundColor Cyan
try {
    # Tenter d'injecter une commande dans le paramètre Mode
    $injectionMode = "CHECK; Write-Host 'Injection réussie' -ForegroundColor Red"
    
    # Exécuter le script avec le paramètre injecté
    $output = & $scriptPath -Mode $injectionMode -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier si l'injection a réussi
    if ($output -match "Injection réussie") {
        Write-Host "Test 4 échoué: L'injection de commandes a réussi" -ForegroundColor Red
    } else {
        Write-Host "Test 4 réussi: L'injection de commandes a échoué" -ForegroundColor Green
    }
} catch {
    # Si une erreur est générée, c'est aussi acceptable
    Write-Host "Test 4 réussi: L'injection de commandes a généré une erreur" -ForegroundColor Green
    Write-Host "Erreur: $_" -ForegroundColor Cyan
}

# Test 5: Accès à des fichiers en dehors du répertoire de travail
Write-Host "Test 5: Accès à des fichiers en dehors du répertoire de travail" -ForegroundColor Cyan
try {
    # Tenter d'accéder à un fichier en dehors du répertoire de travail
    $outsideFilePath = "C:\Windows\System32\drivers\etc\hosts"
    
    # Exécuter le script avec le paramètre pointant vers un fichier système
    $output = & $scriptPath -Mode "CHECK" -FilePath $outsideFilePath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier si le script a correctement validé le chemin du fichier
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($outsideFilePath))") {
            # Le script a accepté le chemin du fichier, mais il devrait vérifier s'il est dans le répertoire de travail
            Write-Host "Test 5 échoué: Le script a accepté un chemin de fichier en dehors du répertoire de travail" -ForegroundColor Red
        } else {
            Write-Host "Test 5 réussi: Le script a rejeté un chemin de fichier en dehors du répertoire de travail" -ForegroundColor Green
        }
    } else {
        # Si le fichier de sortie n'a pas été créé, c'est que le script a rejeté le chemin du fichier
        Write-Host "Test 5 réussi: Le script a rejeté un chemin de fichier en dehors du répertoire de travail" -ForegroundColor Green
    }
} catch {
    # Si une erreur est générée, c'est aussi acceptable
    Write-Host "Test 5 réussi: L'accès à un fichier en dehors du répertoire de travail a généré une erreur" -ForegroundColor Green
    Write-Host "Erreur: $_" -ForegroundColor Cyan
}

# Test 6: Validation des entrées
Write-Host "Test 6: Validation des entrées" -ForegroundColor Cyan
try {
    # Tester avec des caractères spéciaux dans les paramètres
    $specialCharsFilePath = Join-Path -Path $testDir -ChildPath "test-roadmap-`"'<>&|;.md"
    "# Test Roadmap with special chars" | Set-Content -Path $specialCharsFilePath -Encoding UTF8
    
    # Exécuter le script avec des caractères spéciaux dans les paramètres
    $output = & $scriptPath -Mode "CHECK" -FilePath $specialCharsFilePath -TaskIdentifier "1.2.3`"'<>&|;" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier si le script a correctement géré les caractères spéciaux
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($specialCharsFilePath))") {
            Write-Host "Test 6 réussi: Le script a correctement géré les caractères spéciaux" -ForegroundColor Green
        } else {
            Write-Host "Test 6 échoué: Le script n'a pas correctement géré les caractères spéciaux" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 6 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
} catch {
    # Si une erreur est générée, c'est que le script n'a pas correctement géré les caractères spéciaux
    Write-Host "Test 6 échoué: Le script n'a pas correctement géré les caractères spéciaux" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 7: Gestion des permissions
Write-Host "Test 7: Gestion des permissions" -ForegroundColor Cyan
try {
    # Créer un fichier en lecture seule
    $readOnlyFilePath = Join-Path -Path $testDir -ChildPath "readonly-roadmap.md"
    "# Read-only Roadmap" | Set-Content -Path $readOnlyFilePath -Encoding UTF8
    Set-ItemProperty -Path $readOnlyFilePath -Name IsReadOnly -Value $true
    
    # Exécuter le script avec un fichier en lecture seule
    $output = & $scriptPath -Mode "CHECK" -FilePath $readOnlyFilePath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath 2>&1
    
    # Vérifier si le script a correctement géré le fichier en lecture seule
    $checkOutputPath = Join-Path -Path $testDir -ChildPath "check-mode-output.txt"
    if (Test-Path -Path $checkOutputPath) {
        $checkOutput = Get-Content -Path $checkOutputPath -Raw
        if ($checkOutput -match "FilePath : $([regex]::Escape($readOnlyFilePath))") {
            Write-Host "Test 7 réussi: Le script a correctement géré un fichier en lecture seule" -ForegroundColor Green
        } else {
            Write-Host "Test 7 échoué: Le script n'a pas correctement géré un fichier en lecture seule" -ForegroundColor Red
        }
    } else {
        Write-Host "Test 7 échoué: Le fichier de sortie du mode CHECK n'a pas été créé" -ForegroundColor Red
    }
    
    # Remettre le fichier en mode normal
    Set-ItemProperty -Path $readOnlyFilePath -Name IsReadOnly -Value $false
} catch {
    # Si une erreur est générée, c'est que le script n'a pas correctement géré le fichier en lecture seule
    Write-Host "Test 7 échoué: Le script n'a pas correctement géré un fichier en lecture seule" -ForegroundColor Red
    Write-Host "Erreur: $_" -ForegroundColor Red
}

# Test 8: Sécurité des fichiers temporaires
Write-Host "Test 8: Sécurité des fichiers temporaires" -ForegroundColor Cyan
try {
    # Exécuter le script et vérifier s'il crée des fichiers temporaires
    $tempFilesBefore = Get-ChildItem -Path $env:TEMP -Filter "mode-manager-*" -ErrorAction SilentlyContinue
    
    # Exécuter le script
    & $scriptPath -Mode "CHECK" -FilePath $testRoadmapPath -TaskIdentifier "1.2.3" -ConfigPath $tempConfigPath
    
    # Vérifier si des fichiers temporaires ont été créés et non supprimés
    $tempFilesAfter = Get-ChildItem -Path $env:TEMP -Filter "mode-manager-*" -ErrorAction SilentlyContinue
    
    if ($tempFilesAfter.Count -gt $tempFilesBefore.Count) {
        $newTempFiles = $tempFilesAfter | Where-Object { $tempFilesBefore -notcontains $_ }
        Write-Host "Test 8 échoué: Le script a créé des fichiers temporaires non supprimés" -ForegroundColor Red
        Write-Host "Fichiers temporaires non supprimés: $($newTempFiles.FullName -join ', ')" -ForegroundColor Red
    } else {
        Write-Host "Test 8 réussi: Le script n'a pas laissé de fichiers temporaires non supprimés" -ForegroundColor Green
    }
} catch {
    Write-Host "Test 8 échoué: Une erreur s'est produite lors de la vérification des fichiers temporaires" -ForegroundColor Red
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

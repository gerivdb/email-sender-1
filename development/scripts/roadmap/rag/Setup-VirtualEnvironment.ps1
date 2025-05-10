# Setup-VirtualEnvironment.ps1
# Script pour configurer un environnement virtuel Python pour le système RAG de roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$VenvPath = "venv",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoPrompt
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path $scriptPath -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        $color = switch ($Level) {
            "Info" { "White" }
            "Warning" { "Yellow" }
            "Error" { "Red" }
            "Success" { "Green" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour vérifier si Python est installé
function Test-PythonInstalled {
    try {
        $pythonVersion = python --version 2>&1
        Write-Log "Python installé: $pythonVersion" -Level "Info"
        return $true
    } catch {
        Write-Log "Python n'est pas installé ou n'est pas dans le PATH." -Level "Error"
        return $false
    }
}

# Fonction pour créer un environnement virtuel
function New-VirtualEnvironment {
    param (
        [string]$VenvPath,
        [switch]$Force
    )
    
    # Vérifier si l'environnement virtuel existe déjà
    if (Test-Path -Path $VenvPath) {
        if ($Force) {
            Write-Log "Suppression de l'environnement virtuel existant: $VenvPath" -Level "Warning"
            Remove-Item -Path $VenvPath -Recurse -Force
        } else {
            Write-Log "L'environnement virtuel existe déjà: $VenvPath. Utilisez -Force pour le recréer." -Level "Warning"
            return $false
        }
    }
    
    # Créer l'environnement virtuel
    Write-Log "Création de l'environnement virtuel: $VenvPath" -Level "Info"
    python -m venv $VenvPath
    
    if (-not (Test-Path -Path $VenvPath)) {
        Write-Log "Erreur lors de la création de l'environnement virtuel." -Level "Error"
        return $false
    }
    
    Write-Log "Environnement virtuel créé avec succès: $VenvPath" -Level "Success"
    return $true
}

# Fonction pour activer l'environnement virtuel
function Activate-VirtualEnvironment {
    param (
        [string]$VenvPath
    )
    
    $activateScript = Join-Path -Path $VenvPath -ChildPath "Scripts\Activate.ps1"
    
    if (-not (Test-Path -Path $activateScript)) {
        Write-Log "Script d'activation non trouvé: $activateScript" -Level "Error"
        return $false
    }
    
    Write-Log "Activation de l'environnement virtuel: $VenvPath" -Level "Info"
    & $activateScript
    
    return $true
}

# Fonction pour installer les dépendances
function Install-Dependencies {
    param (
        [string]$RequirementsFile
    )
    
    if (-not (Test-Path -Path $RequirementsFile)) {
        Write-Log "Fichier de dépendances non trouvé: $RequirementsFile" -Level "Error"
        return $false
    }
    
    Write-Log "Installation des dépendances à partir de: $RequirementsFile" -Level "Info"
    pip install -r $RequirementsFile
    
    if ($LASTEXITCODE -ne 0) {
        Write-Log "Erreur lors de l'installation des dépendances." -Level "Error"
        return $false
    }
    
    Write-Log "Dépendances installées avec succès." -Level "Success"
    return $true
}

# Fonction pour créer le fichier de dépendances
function New-RequirementsFile {
    param (
        [string]$OutputPath
    )
    
    $requirements = @"
# Dépendances pour le système RAG de roadmaps
# Version: 1.0
# Date: 2025-05-15

# Qdrant client
qdrant-client==1.7.0

# Sentence Transformers (avec versions compatibles)
sentence-transformers==2.2.2
huggingface-hub==0.19.4
transformers==4.36.2
torch==2.1.2

# Visualisation
matplotlib
networkx
pyvis
"@
    
    # Créer le répertoire parent si nécessaire
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Écrire le fichier de dépendances
    $requirements | Set-Content -Path $OutputPath -Encoding UTF8
    
    Write-Log "Fichier de dépendances créé: $OutputPath" -Level "Success"
    return $true
}

# Fonction pour créer un script d'activation
function New-ActivationScript {
    param (
        [string]$VenvPath,
        [string]$OutputPath
    )
    
    $activationScript = @"
# Activate-RoadmapEnvironment.ps1
# Script pour activer l'environnement virtuel du système RAG de roadmaps
# Version: 1.0
# Date: 2025-05-15

# Activer l'environnement virtuel
`$venvPath = "$VenvPath"
`$activateScript = Join-Path -Path `$venvPath -ChildPath "Scripts\Activate.ps1"

if (-not (Test-Path -Path `$activateScript)) {
    Write-Host "[ERROR] Script d'activation non trouvé: `$activateScript" -ForegroundColor Red
    Write-Host "[INFO] Exécutez d'abord Setup-VirtualEnvironment.ps1 pour créer l'environnement virtuel." -ForegroundColor Yellow
    exit 1
}

# Activer l'environnement virtuel
& `$activateScript

# Afficher les informations sur l'environnement
Write-Host "[INFO] Environnement virtuel activé: `$venvPath" -ForegroundColor Green
Write-Host "[INFO] Python: `$(python --version)" -ForegroundColor Cyan
Write-Host "[INFO] pip: `$(pip --version)" -ForegroundColor Cyan

# Afficher les dépendances installées
Write-Host "[INFO] Dépendances installées:" -ForegroundColor Cyan
pip list | Select-String -Pattern "qdrant|sentence|transformers|huggingface|torch"
"@
    
    # Créer le répertoire parent si nécessaire
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Écrire le script d'activation
    $activationScript | Set-Content -Path $OutputPath -Encoding UTF8
    
    Write-Log "Script d'activation créé: $OutputPath" -Level "Success"
    return $true
}

# Fonction pour créer un script de test
function New-TestScript {
    param (
        [string]$VenvPath,
        [string]$OutputPath
    )
    
    $testScript = @"
# Run-TestsInVenv.ps1
# Script pour exécuter les tests dans l'environnement virtuel
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = `$false)]
    [ValidateSet("All", "ChangeDetection", "VectorUpdate", "Versioning")]
    [string]`$TestType = "All",
    
    [Parameter(Mandatory = `$false)]
    [switch]`$GenerateReport
)

# Activer l'environnement virtuel
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$activateScript = Join-Path -Path `$scriptPath -ChildPath "Activate-RoadmapEnvironment.ps1"

if (-not (Test-Path -Path `$activateScript)) {
    Write-Host "[ERROR] Script d'activation non trouvé: `$activateScript" -ForegroundColor Red
    exit 1
}

# Activer l'environnement virtuel
& `$activateScript

# Exécuter les tests
`$testsPath = Join-Path -Path `$scriptPath -ChildPath "tests\Invoke-AllTests.ps1"

if (-not (Test-Path -Path `$testsPath)) {
    Write-Host "[ERROR] Script de test non trouvé: `$testsPath" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Exécution des tests (`$TestType)..." -ForegroundColor Cyan

`$params = @{
    TestType = `$TestType
}

if (`$GenerateReport) {
    `$params.GenerateReport = `$true
}

& `$testsPath @params

if (`$LASTEXITCODE -eq 0) {
    Write-Host "[SUCCESS] Tests terminés avec succès." -ForegroundColor Green
    
    if (`$GenerateReport) {
        `$reportPath = Join-Path -Path "projet\roadmaps\analysis\test\output" -ChildPath "test_report.html"
        if (Test-Path -Path `$reportPath) {
            Write-Host "[INFO] Rapport de test généré: `$reportPath" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "[ERROR] Erreur lors de l'exécution des tests." -ForegroundColor Red
}
"@
    
    # Créer le répertoire parent si nécessaire
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Écrire le script de test
    $testScript | Set-Content -Path $OutputPath -Encoding UTF8
    
    Write-Log "Script de test créé: $OutputPath" -Level "Success"
    return $true
}

# Fonction principale
function Setup-VirtualEnvironment {
    param (
        [string]$VenvPath,
        [switch]$Force,
        [switch]$NoPrompt
    )
    
    Write-Log "Configuration de l'environnement virtuel pour le système RAG de roadmaps..." -Level "Info"
    
    # Demander confirmation si -NoPrompt n'est pas spécifié
    if (-not $NoPrompt) {
        $confirmation = Read-Host "Voulez-vous configurer un environnement virtuel Python ? (O/N)"
        if ($confirmation -ne "O") {
            Write-Log "Opération annulée." -Level "Info"
            return $false
        }
    }
    
    # Vérifier si Python est installé
    if (-not (Test-PythonInstalled)) {
        Write-Log "Python doit être installé pour continuer." -Level "Error"
        return $false
    }
    
    # Créer l'environnement virtuel
    $venvCreated = New-VirtualEnvironment -VenvPath $VenvPath -Force:$Force
    
    if (-not $venvCreated) {
        return $false
    }
    
    # Créer le fichier de dépendances
    $requirementsPath = Join-Path -Path $scriptPath -ChildPath "requirements.txt"
    New-RequirementsFile -OutputPath $requirementsPath
    
    # Activer l'environnement virtuel
    $venvActivated = Activate-VirtualEnvironment -VenvPath $VenvPath
    
    if (-not $venvActivated) {
        return $false
    }
    
    # Installer les dépendances
    $depsInstalled = Install-Dependencies -RequirementsFile $requirementsPath
    
    if (-not $depsInstalled) {
        return $false
    }
    
    # Créer le script d'activation
    $activationScriptPath = Join-Path -Path $scriptPath -ChildPath "Activate-RoadmapEnvironment.ps1"
    New-ActivationScript -VenvPath $VenvPath -OutputPath $activationScriptPath
    
    # Créer le script de test
    $testScriptPath = Join-Path -Path $scriptPath -ChildPath "Run-TestsInVenv.ps1"
    New-TestScript -VenvPath $VenvPath -OutputPath $testScriptPath
    
    Write-Log "Configuration de l'environnement virtuel terminée avec succès." -Level "Success"
    Write-Log "Pour activer l'environnement virtuel, exécutez: $activationScriptPath" -Level "Info"
    Write-Log "Pour exécuter les tests dans l'environnement virtuel, exécutez: $testScriptPath" -Level "Info"
    
    return $true
}

# Exécuter la fonction principale
Setup-VirtualEnvironment -VenvPath $VenvPath -Force:$Force -NoPrompt:$NoPrompt

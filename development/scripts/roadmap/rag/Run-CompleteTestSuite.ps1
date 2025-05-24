# Start-CompleteTestSuite.ps1
# Script tout-en-un pour exécuter la suite complète de tests du système RAG de roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "ChangeDetection", "VectorUpdate", "Versioning")]
    [string]$TestType = "All",
    
    [Parameter(Mandatory = $false)]
    [string]$VenvPath = "venv",
    
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$QdrantContainerName = "roadmap-qdrant",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipQdrantCheck,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipVenvSetup,
    
    [Parameter(Mandatory = $false)]
    [switch]$NoReport
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
            "Debug" { "Gray" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour vérifier si Docker est installé
function Test-DockerInstalled {
    try {
        $dockerVersion = docker --version 2>&1
        Write-Log "Docker installé: $dockerVersion" -Level "Info"
        return $true
    } catch {
        Write-Log "Docker n'est pas installé ou n'est pas dans le PATH." -Level "Error"
        return $false
    }
}

# Fonction pour vérifier si Qdrant est en cours d'exécution
function Test-QdrantRunning {
    param (
        [string]$Url = "http://localhost:6333"
    )
    
    try {
        $null = Invoke-RestMethod -Uri "$Url/collections" -Method Get -TimeoutSec 5 -ErrorAction Stop
        Write-Log "Qdrant est en cours d'exécution sur $Url" -Level "Success"
        return $true
    } catch {
        Write-Log "Qdrant n'est pas en cours d'exécution sur $Url: $_" -Level "Warning"
        return $false
    }
}

# Fonction pour démarrer Qdrant dans Docker
function Start-QdrantContainer {
    param (
        [string]$ContainerName = "roadmap-qdrant"
    )
    
    # Vérifier si le conteneur existe déjà
    $containerExists = docker ps -a --filter "name=$ContainerName" --format "{{.Names}}" 2>&1
    
    if ($containerExists -eq $ContainerName) {
        # Vérifier si le conteneur est déjà en cours d'exécution
        $containerRunning = docker ps --filter "name=$ContainerName" --format "{{.Names}}" 2>&1
        
        if ($containerRunning -eq $ContainerName) {
            Write-Log "Le conteneur Qdrant '$ContainerName' est déjà en cours d'exécution." -Level "Info"
        } else {
            # Démarrer le conteneur existant
            Write-Log "Démarrage du conteneur Qdrant existant '$ContainerName'..." -Level "Info"
            docker start $ContainerName
        }
    } else {
        # Créer et démarrer un nouveau conteneur
        Write-Log "Création et démarrage d'un nouveau conteneur Qdrant '$ContainerName'..." -Level "Info"
        docker run -d --name $ContainerName -p 6333:6333 -p 6334:6334 qdrant/qdrant:latest
    }
    
    # Attendre que Qdrant soit prêt
    $maxRetries = 10
    $retryCount = 0
    $qdrantReady = $false
    
    Write-Log "Attente du démarrage de Qdrant..." -Level "Info"
    
    while (-not $qdrantReady -and $retryCount -lt $maxRetries) {
        Start-Sleep -Seconds 2
        $qdrantReady = Test-QdrantRunning
        $retryCount++
    }
    
    if ($qdrantReady) {
        Write-Log "Qdrant est prêt et en cours d'exécution." -Level "Success"
        return $true
    } else {
        Write-Log "Impossible de démarrer Qdrant après $maxRetries tentatives." -Level "Error"
        return $false
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

# Fonction pour vérifier si pip est installé
function Test-PipInstalled {
    try {
        $pipVersion = pip --version 2>&1
        Write-Log "pip installé: $pipVersion" -Level "Info"
        return $true
    } catch {
        Write-Log "pip n'est pas installé ou n'est pas dans le PATH." -Level "Error"
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
            return $true
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

# Fonction pour installer les dépendances dans l'environnement virtuel
function Install-VenvDependencies {
    param (
        [string]$VenvPath
    )
    
    $activateScript = Join-Path -Path $VenvPath -ChildPath "Scripts\Activate.ps1"
    
    if (-not (Test-Path -Path $activateScript)) {
        Write-Log "Script d'activation non trouvé: $activateScript" -Level "Error"
        return $false
    }
    
    # Créer un script temporaire pour installer les dépendances
    $tempScript = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".ps1"
    
    $installScript = @"
# Script temporaire pour installer les dépendances dans l'environnement virtuel
. "$activateScript"

# Mettre à jour pip
python -m pip install --upgrade pip

# Installer les dépendances avec versions spécifiques
pip install huggingface-hub==0.19.4 transformers==4.36.2 torch==2.1.2 sentence-transformers==2.2.2 qdrant-client==1.7.0 matplotlib networkx pyvis

# Vérifier l'installation
try {
    python -c "import sentence_transformers; import qdrant_client; print('Bibliothèques importées avec succès!')"
    if (`$LASTEXITCODE -ne 0) {
        exit 1
    }
} catch {
    exit 1
}
"@
    
    Set-Content -Path $tempScript -Value $installScript -Encoding UTF8
    
    # Exécuter le script d'installation
    Write-Log "Installation des dépendances dans l'environnement virtuel..." -Level "Info"
    & $tempScript
    
    # Supprimer le script temporaire
    Remove-Item -Path $tempScript -Force
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Dépendances installées avec succès dans l'environnement virtuel." -Level "Success"
        return $true
    } else {
        Write-Log "Erreur lors de l'installation des dépendances dans l'environnement virtuel." -Level "Error"
        return $false
    }
}

# Fonction pour exécuter les tests dans l'environnement virtuel
function Invoke-TestsInVenv {
    param (
        [string]$VenvPath,
        [string]$TestType,
        [switch]$GenerateReport
    )
    
    $activateScript = Join-Path -Path $VenvPath -ChildPath "Scripts\Activate.ps1"
    
    if (-not (Test-Path -Path $activateScript)) {
        Write-Log "Script d'activation non trouvé: $activateScript" -Level "Error"
        return $false
    }
    
    # Créer un script temporaire pour exécuter les tests
    $tempScript = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".ps1"
    
    $testScript = @"
# Script temporaire pour exécuter les tests dans l'environnement virtuel
. "$activateScript"

# Exécuter les tests
`$testsPath = Join-Path -Path "$scriptPath" -ChildPath "tests\Invoke-AllTests.ps1"

if (-not (Test-Path -Path `$testsPath)) {
    Write-Host "[ERROR] Script de test non trouvé: `$testsPath" -ForegroundColor Red
    exit 1
}

`$params = @{
    TestType = "$TestType"
}

if (`$true -eq `$$($GenerateReport.IsPresent)) {
    `$params.GenerateReport = `$true
}

& `$testsPath @params
"@
    
    Set-Content -Path $tempScript -Value $testScript -Encoding UTF8
    
    # Exécuter le script de test
    Write-Log "Exécution des tests ($TestType) dans l'environnement virtuel..." -Level "Info"
    & $tempScript
    
    # Supprimer le script temporaire
    Remove-Item -Path $tempScript -Force
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Tests exécutés avec succès dans l'environnement virtuel." -Level "Success"
        return $true
    } else {
        Write-Log "Erreur lors de l'exécution des tests dans l'environnement virtuel." -Level "Error"
        return $false
    }
}

# Fonction principale
function Start-CompleteTestSuite {
    param (
        [string]$TestType,
        [string]$VenvPath,
        [string]$QdrantUrl,
        [string]$QdrantContainerName,
        [switch]$Force,
        [switch]$SkipQdrantCheck,
        [switch]$SkipVenvSetup,
        [switch]$NoReport
    )
    
    Write-Log "Exécution de la suite complète de tests du système RAG de roadmaps..." -Level "Info"
    
    # Étape 1: Vérifier et démarrer Qdrant si nécessaire
    if (-not $SkipQdrantCheck) {
        $qdrantRunning = Test-QdrantRunning -Url $QdrantUrl
        
        if (-not $qdrantRunning) {
            $dockerInstalled = Test-DockerInstalled
            
            if (-not $dockerInstalled) {
                Write-Log "Docker est nécessaire pour démarrer Qdrant." -Level "Error"
                return $false
            }
            
            $qdrantStarted = Start-QdrantContainer -ContainerName $QdrantContainerName
            
            if (-not $qdrantStarted) {
                Write-Log "Impossible de démarrer Qdrant. Les tests qui nécessitent Qdrant échoueront." -Level "Error"
                return $false
            }
        }
    }
    
    # Étape 2: Configurer l'environnement virtuel si nécessaire
    if (-not $SkipVenvSetup) {
        $pythonInstalled = Test-PythonInstalled
        
        if (-not $pythonInstalled) {
            Write-Log "Python est nécessaire pour exécuter les tests." -Level "Error"
            return $false
        }
        
        $pipInstalled = Test-PipInstalled
        
        if (-not $pipInstalled) {
            Write-Log "pip est nécessaire pour installer les dépendances." -Level "Error"
            return $false
        }
        
        $venvCreated = New-VirtualEnvironment -VenvPath $VenvPath -Force:$Force
        
        if (-not $venvCreated) {
            Write-Log "Impossible de créer l'environnement virtuel." -Level "Error"
            return $false
        }
        
        $depsInstalled = Install-VenvDependencies -VenvPath $VenvPath
        
        if (-not $depsInstalled) {
            Write-Log "Impossible d'installer les dépendances dans l'environnement virtuel." -Level "Error"
            return $false
        }
    }
    
    # Étape 3: Exécuter les tests
    $testsSucceeded = Invoke-TestsInVenv -VenvPath $VenvPath -TestType $TestType -GenerateReport:(-not $NoReport)
    
    if ($testsSucceeded) {
        Write-Log "Suite complète de tests exécutée avec succès." -Level "Success"
        
        if (-not $NoReport) {
            $reportPath = Join-Path -Path "projet\roadmaps\analysis\test\output" -ChildPath "test_report.html"
            if (Test-Path -Path $reportPath) {
                Write-Log "Rapport de test généré: $reportPath" -Level "Info"
                Write-Log "Pour ouvrir le rapport: Invoke-Item $reportPath" -Level "Info"
            }
        }
        
        return $true
    } else {
        Write-Log "Erreur lors de l'exécution de la suite complète de tests." -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale
Start-CompleteTestSuite -TestType $TestType -VenvPath $VenvPath -QdrantUrl $QdrantUrl -QdrantContainerName $QdrantContainerName -Force:$Force -SkipQdrantCheck:$SkipQdrantCheck -SkipVenvSetup:$SkipVenvSetup -NoReport:$NoReport


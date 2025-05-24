# Start-TestsWithCompatibleDependencies.ps1
# Script pour exécuter les tests avec des dépendances compatibles
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "ChangeDetection", "VectorUpdate", "Versioning")]
    [string]$TestType = "All",
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport,
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipDependencyCheck,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
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

# Fonction pour vérifier et installer les dépendances compatibles
function Install-CompatibleDependencies {
    Write-Log "Vérification et installation des dépendances compatibles..." -Level "Info"
    
    # Vérifier si Python est installé
    try {
        $pythonVersion = python --version 2>&1
        Write-Log "Python installé: $pythonVersion" -Level "Info"
    } catch {
        Write-Log "Python n'est pas installé ou n'est pas dans le PATH." -Level "Error"
        return $false
    }
    
    # Vérifier si pip est installé
    try {
        $pipVersion = pip --version 2>&1
        Write-Log "pip installé: $pipVersion" -Level "Info"
    } catch {
        Write-Log "pip n'est pas installé ou n'est pas dans le PATH." -Level "Error"
        return $false
    }
    
    # Installer les dépendances compatibles
    Write-Log "Installation des dépendances compatibles..." -Level "Info"
    
    $dependencies = @(
        "huggingface-hub==0.19.4",
        "transformers==4.36.2",
        "torch==2.1.2",
        "sentence-transformers==2.2.2",
        "qdrant-client==1.7.0"
    )
    
    foreach ($dependency in $dependencies) {
        Write-Log "Installation de $dependency..." -Level "Info"
        pip install $dependency
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Erreur lors de l'installation de $dependency." -Level "Error"
            return $false
        }
    }
    
    # Vérifier l'installation
    Write-Log "Vérification de l'installation..." -Level "Info"
    
    try {
        $testImport = python -c "import sentence_transformers; import qdrant_client; print('Bibliothèques importées avec succès!')" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Log "Dépendances installées et vérifiées avec succès." -Level "Success"
            return $true
        } else {
            Write-Log "Erreur lors de la vérification des dépendances: $testImport" -Level "Error"
            return $false
        }
    } catch {
        Write-Log "Erreur lors de la vérification des dépendances: $_" -Level "Error"
        return $false
    }
}

# Fonction pour exécuter les tests
function Invoke-Tests {
    param (
        [string]$TestType,
        [switch]$GenerateReport
    )
    
    $testScriptPath = Join-Path -Path $scriptPath -ChildPath "Invoke-AllTests.ps1"
    
    if (-not (Test-Path -Path $testScriptPath)) {
        Write-Log "Script de test introuvable: $testScriptPath" -Level "Error"
        return $false
    }
    
    Write-Log "Exécution des tests ($TestType)..." -Level "Info"
    
    $params = @{
        TestType = $TestType
    }
    
    if ($GenerateReport) {
        $params.GenerateReport = $true
    }
    
    & $testScriptPath @params
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "Tests terminés avec succès." -Level "Success"
        return $true
    } else {
        Write-Log "Erreur lors de l'exécution des tests." -Level "Error"
        return $false
    }
}

# Fonction principale
function Start-TestsWithCompatibleDependencies {
    param (
        [string]$TestType,
        [switch]$GenerateReport,
        [switch]$SkipDependencyCheck,
        [switch]$Force
    )
    
    # Vérifier et installer les dépendances compatibles si nécessaire
    if (-not $SkipDependencyCheck) {
        $dependenciesInstalled = Install-CompatibleDependencies
        
        if (-not $dependenciesInstalled) {
            if ($Force) {
                Write-Log "Tentative d'exécution des tests malgré les problèmes de dépendances..." -Level "Warning"
            } else {
                Write-Log "Impossible de continuer sans les dépendances compatibles." -Level "Error"
                Write-Log "Utilisez -Force pour exécuter les tests malgré les problèmes de dépendances." -Level "Info"
                Write-Log "Consultez le guide de dépannage: docs\guides\roadmap\TROUBLESHOOTING_DEPENDENCIES.md" -Level "Info"
                return $false
            }
        }
    }
    
    # Exécuter les tests
    $testsSucceeded = Invoke-Tests -TestType $TestType -GenerateReport:$GenerateReport
    
    if ($testsSucceeded) {
        Write-Log "Tests exécutés avec succès." -Level "Success"
        
        if ($GenerateReport) {
            $reportPath = Join-Path -Path "projet\roadmaps\analysis\test\output" -ChildPath "test_report.html"
            if (Test-Path -Path $reportPath) {
                Write-Log "Rapport de test généré: $reportPath" -Level "Info"
            }
        }
        
        return $true
    } else {
        Write-Log "Erreur lors de l'exécution des tests." -Level "Error"
        Write-Log "Consultez le guide de dépannage: docs\guides\roadmap\TROUBLESHOOTING_DEPENDENCIES.md" -Level "Info"
        return $false
    }
}

# Exécuter la fonction principale
Start-TestsWithCompatibleDependencies -TestType $TestType -GenerateReport:$GenerateReport -SkipDependencyCheck:$SkipDependencyCheck -Force:$Force


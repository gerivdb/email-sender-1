<#
.SYNOPSIS
    Vérifie les prérequis pour l'exécution de la Phase 6.
.DESCRIPTION
    Ce script vérifie que l'environnement est correctement configuré pour l'exécution des scripts de la Phase 6.
    Il teste l'accès aux répertoires, la disponibilité des dépendances et l'environnement PowerShell.
#>

[CmdletBinding()]
param (
    [string]$ScriptsDirectory = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath ""),
    [string]$LogFilePath = (Join-Path -Path $PSScriptRoot -ChildPath "prerequisites_check.log")
)

# Fonction de journalisation simple
function Write-Log {
    param ([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        default { Write-Host $logEntry }
    }

    # Écrire dans le fichier journal
    try {
        $logDir = Split-Path -Path $LogFilePath -Parent
        if (-not (Test-Path -Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
        Add-Content -Path $LogFilePath -Value $logEntry -ErrorAction SilentlyContinue
    } catch { Write-Warning "Impossible d'écrire dans le journal: $_" }
}

# Fonction pour vérifier l'environnement PowerShell
function Test-PowerShellEnvironment {
    Write-Log "Vérification de l'environnement PowerShell..."

    # Vérifier la version de PowerShell
    $psVersion = $PSVersionTable.PSVersion
    Write-Log "Version PowerShell: $psVersion"

    # Vérifier l'exécution de scripts
    $executionPolicy = Get-ExecutionPolicy
    Write-Log "Politique d'exécution: $executionPolicy"
    if ($executionPolicy -eq "Restricted") {
        Write-Log "La politique d'exécution est restrictive. Certains scripts pourraient ne pas s'exécuter." -Level "WARNING"
    }

    # Vérifier les modules requis
    $requiredModules = @("PSScriptAnalyzer")
    foreach ($module in $requiredModules) {
        if (Get-Module -ListAvailable -Name $module) {
            Write-Log "Module $module disponible" -Level "SUCCESS"
        } else {
            Write-Log "Module $module non disponible" -Level "WARNING"
        }
    }

    # Vérifier l'accès au système de fichiers
    try {
        $testFile = Join-Path -Path $env:TEMP -ChildPath "phase6_test.txt"
        "Test" | Out-File -FilePath $testFile -Force
        if (Test-Path -Path $testFile) {
            Remove-Item -Path $testFile -Force
            Write-Log "Accès en écriture au système de fichiers: OK" -Level "SUCCESS"
        }
    } catch {
        Write-Log "Problème d'accès au système de fichiers: $_" -Level "ERROR"
    }

    return $true
}

# Fonction pour vérifier les répertoires
function Test-Directories {
    Write-Log "Vérification des répertoires..."

    $directories = @(
        $ScriptsDirectory,
        (Join-Path -Path $PSScriptRoot -ChildPath "modules"),
        (Join-Path -Path $PSScriptRoot -ChildPath "logs")
    )

    $allExist = $true

    foreach ($dir in $directories) {
        if (Test-Path -Path $dir -PathType Container) {
            Write-Log "Répertoire existant: $dir" -Level "SUCCESS"
        } else {
            Write-Log "Répertoire manquant: $dir" -Level "WARNING"
            try {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
                Write-Log "Répertoire créé: $dir" -Level "SUCCESS"
            } catch {
                Write-Log "Impossible de créer le répertoire: $dir - $_" -Level "ERROR"
                $allExist = $false
            }
        }
    }

    return $allExist
}

# Fonction pour vérifier les scripts de la Phase 6
function Test-Phase6Scripts {
    Write-Log "Vérification des scripts de la Phase 6..."

    $scripts = @(
        "Start-Phase6.ps1",
        "Test-Phase6Implementation.ps1",
        "Implement-CentralizedLogging.ps1",
        "Test-EnvironmentCompatibility.ps1"
    )

    $allExist = $true

    foreach ($script in $scripts) {
        $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $script
        if (Test-Path -Path $scriptPath -PathType Leaf) {
            Write-Log "Script existant: $script" -Level "SUCCESS"

            # Vérifier la syntaxe du script si PSScriptAnalyzer est disponible
            if (Get-Module -ListAvailable -Name PSScriptAnalyzer) {
                $errors = Invoke-ScriptAnalyzer -Path $scriptPath -Severity Error
                if ($errors.Count -eq 0) {
                    Write-Log "Syntaxe du script ${script}: OK" -Level "SUCCESS"
                } else {
                    Write-Log "Erreurs de syntaxe dans le script ${script}:" -Level "ERROR"
                    foreach ($error in $errors) {
                        Write-Log "  - Ligne $($error.Line): $($error.Message)" -Level "ERROR"
                    }
                    $allExist = $false
                }
            }
        } else {
            Write-Log "Script manquant: $script" -Level "ERROR"
            $allExist = $false
        }
    }

    return $allExist
}

# Fonction pour vérifier les dépendances
function Test-Dependencies {
    Write-Log "Vérification des dépendances..."

    $dependencies = @{
        "TryCatchAdder.ps1" = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "journal\TryCatchAdder.ps1")
        "ScriptAnalyzer.ps1" = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "journal\ScriptAnalyzer.ps1")
        "CentralizedLogger.ps1" = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "journal\CentralizedLogger.ps1")
        "PathStandardizer.ps1" = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "utils\automation\PathStandardizer.ps1")
    }

    $missingDependencies = @()

    foreach ($dependency in $dependencies.Keys) {
        $path = $dependencies[$dependency]
        if (Test-Path -Path $path -PathType Leaf) {
            Write-Log "Dépendance disponible: $dependency" -Level "SUCCESS"
        } else {
            Write-Log "Dépendance manquante: $dependency ($path)" -Level "WARNING"
            $missingDependencies += $dependency
        }
    }

    if ($missingDependencies.Count -gt 0) {
        Write-Log "Certaines dépendances sont manquantes. Les fonctionnalités correspondantes seront limitées." -Level "WARNING"
    }

    return ($missingDependencies.Count -eq 0)
}

# Fonction pour effectuer un test simple d'exécution
function Test-SimpleExecution {
    Write-Log "Test simple d'exécution..."

    try {
        # Test d'une commande simple
        $result = Get-Date
        Write-Log "Commande simple exécutée avec succès: $result" -Level "SUCCESS"

        # Test d'une commande avec pipeline
        $result = 1..5 | ForEach-Object { $_ * 2 }
        Write-Log "Commande avec pipeline exécutée avec succès: $($result -join ', ')" -Level "SUCCESS"

        # Test d'une fonction simple
        function Test-Function { param($value) return $value * 2 }
        $result = Test-Function -value 10
        Write-Log "Fonction simple exécutée avec succès: $result" -Level "SUCCESS"

        return $true
    } catch {
        Write-Log "Erreur lors du test d'exécution: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale
function Test-Phase6Prerequisites {
    Write-Log "Démarrage de la vérification des prérequis pour la Phase 6..."

    $results = @{
        PowerShellEnvironment = Test-PowerShellEnvironment
        Directories = Test-Directories
        Phase6Scripts = Test-Phase6Scripts
        Dependencies = Test-Dependencies
        SimpleExecution = Test-SimpleExecution
    }

    $allPassed = $true
    foreach ($key in $results.Keys) {
        if (-not $results[$key]) {
            $allPassed = $false
        }
    }

    Write-Log "Résumé des vérifications:"
    foreach ($key in $results.Keys) {
        $status = if ($results[$key]) { "RÉUSSI" } else { "ÉCHOUÉ" }
        $level = if ($results[$key]) { "SUCCESS" } else { "ERROR" }
        Write-Log "  - $key : $status" -Level $level
    }

    if ($allPassed) {
        Write-Log "Tous les prérequis sont satisfaits. Vous pouvez exécuter les scripts de la Phase 6." -Level "SUCCESS"
    } else {
        Write-Log "Certains prérequis ne sont pas satisfaits. Veuillez corriger les problèmes avant d'exécuter les scripts de la Phase 6." -Level "WARNING"
    }

    return $results
}

# Exécuter la fonction principale
$results = Test-Phase6Prerequisites

# Afficher un résumé
Write-Host "`nRésumé des vérifications des prérequis:" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
foreach ($key in $results.Keys) {
    $status = if ($results[$key]) { "RÉUSSI" } else { "ÉCHOUÉ" }
    $color = if ($results[$key]) { "Green" } else { "Red" }
    Write-Host "  - $key : $status" -ForegroundColor $color
}

$allPassed = $true
foreach ($key in $results.Keys) {
    if (-not $results[$key]) {
        $allPassed = $false
    }
}

if ($allPassed) {
    Write-Host "`nTous les prérequis sont satisfaits. Vous pouvez exécuter les scripts de la Phase 6." -ForegroundColor Green
} else {
    Write-Host "`nCertains prérequis ne sont pas satisfaits. Veuillez corriger les problèmes avant d'exécuter les scripts de la Phase 6." -ForegroundColor Yellow
}

Write-Host "Journal: $LogFilePath" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

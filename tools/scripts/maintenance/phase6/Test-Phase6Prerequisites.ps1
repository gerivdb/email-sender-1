<#
.SYNOPSIS
    VÃ©rifie les prÃ©requis pour l'exÃ©cution de la Phase 6.
.DESCRIPTION
    Ce script vÃ©rifie que l'environnement est correctement configurÃ© pour l'exÃ©cution des scripts de la Phase 6.
    Il teste l'accÃ¨s aux rÃ©pertoires, la disponibilitÃ© des dÃ©pendances et l'environnement PowerShell.
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

    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $LogFilePath -Parent
        if (-not (Test-Path -Path $logDir)) { New-Item -Path $logDir -ItemType Directory -Force | Out-Null }
        Add-Content -Path $LogFilePath -Value $logEntry -ErrorAction SilentlyContinue
    } catch { Write-Warning "Impossible d'Ã©crire dans le journal: $_" }
}

# Fonction pour vÃ©rifier l'environnement PowerShell
function Test-PowerShellEnvironment {
    Write-Log "VÃ©rification de l'environnement PowerShell..."

    # VÃ©rifier la version de PowerShell
    $psVersion = $PSVersionTable.PSVersion
    Write-Log "Version PowerShell: $psVersion"

    # VÃ©rifier l'exÃ©cution de scripts
    $executionPolicy = Get-ExecutionPolicy
    Write-Log "Politique d'exÃ©cution: $executionPolicy"
    if ($executionPolicy -eq "Restricted") {
        Write-Log "La politique d'exÃ©cution est restrictive. Certains scripts pourraient ne pas s'exÃ©cuter." -Level "WARNING"
    }

    # VÃ©rifier les modules requis
    $requiredModules = @("PSScriptAnalyzer")
    foreach ($module in $requiredModules) {
        if (Get-Module -ListAvailable -Name $module) {
            Write-Log "Module $module disponible" -Level "SUCCESS"
        } else {
            Write-Log "Module $module non disponible" -Level "WARNING"
        }
    }

    # VÃ©rifier l'accÃ¨s au systÃ¨me de fichiers
    try {
        $testFile = Join-Path -Path $env:TEMP -ChildPath "phase6_test.txt"
        "Test" | Out-File -FilePath $testFile -Force
        if (Test-Path -Path $testFile) {
            Remove-Item -Path $testFile -Force
            Write-Log "AccÃ¨s en Ã©criture au systÃ¨me de fichiers: OK" -Level "SUCCESS"
        }
    } catch {
        Write-Log "ProblÃ¨me d'accÃ¨s au systÃ¨me de fichiers: $_" -Level "ERROR"
    }

    return $true
}

# Fonction pour vÃ©rifier les rÃ©pertoires
function Test-Directories {
    Write-Log "VÃ©rification des rÃ©pertoires..."

    $directories = @(
        $ScriptsDirectory,
        (Join-Path -Path $PSScriptRoot -ChildPath "modules"),
        (Join-Path -Path $PSScriptRoot -ChildPath "logs")
    )

    $allExist = $true

    foreach ($dir in $directories) {
        if (Test-Path -Path $dir -PathType Container) {
            Write-Log "RÃ©pertoire existant: $dir" -Level "SUCCESS"
        } else {
            Write-Log "RÃ©pertoire manquant: $dir" -Level "WARNING"
            try {
                New-Item -Path $dir -ItemType Directory -Force | Out-Null
                Write-Log "RÃ©pertoire crÃ©Ã©: $dir" -Level "SUCCESS"
            } catch {
                Write-Log "Impossible de crÃ©er le rÃ©pertoire: $dir - $_" -Level "ERROR"
                $allExist = $false
            }
        }
    }

    return $allExist
}

# Fonction pour vÃ©rifier les scripts de la Phase 6
function Test-Phase6Scripts {
    Write-Log "VÃ©rification des scripts de la Phase 6..."

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

            # VÃ©rifier la syntaxe du script si PSScriptAnalyzer est disponible
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

# Fonction pour vÃ©rifier les dÃ©pendances
function Test-Dependencies {
    Write-Log "VÃ©rification des dÃ©pendances..."

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
            Write-Log "DÃ©pendance disponible: $dependency" -Level "SUCCESS"
        } else {
            Write-Log "DÃ©pendance manquante: $dependency ($path)" -Level "WARNING"
            $missingDependencies += $dependency
        }
    }

    if ($missingDependencies.Count -gt 0) {
        Write-Log "Certaines dÃ©pendances sont manquantes. Les fonctionnalitÃ©s correspondantes seront limitÃ©es." -Level "WARNING"
    }

    return ($missingDependencies.Count -eq 0)
}

# Fonction pour effectuer un test simple d'exÃ©cution
function Test-SimpleExecution {
    Write-Log "Test simple d'exÃ©cution..."

    try {
        # Test d'une commande simple
        $result = Get-Date
        Write-Log "Commande simple exÃ©cutÃ©e avec succÃ¨s: $result" -Level "SUCCESS"

        # Test d'une commande avec pipeline
        $result = 1..5 | ForEach-Object { $_ * 2 }
        Write-Log "Commande avec pipeline exÃ©cutÃ©e avec succÃ¨s: $($result -join ', ')" -Level "SUCCESS"

        # Test d'une fonction simple
        function Test-Function { param($value) return $value * 2 }
        $result = Test-Function -value 10
        Write-Log "Fonction simple exÃ©cutÃ©e avec succÃ¨s: $result" -Level "SUCCESS"

        return $true
    } catch {
        Write-Log "Erreur lors du test d'exÃ©cution: $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale
function Test-Phase6Prerequisites {
    Write-Log "DÃ©marrage de la vÃ©rification des prÃ©requis pour la Phase 6..."

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

    Write-Log "RÃ©sumÃ© des vÃ©rifications:"
    foreach ($key in $results.Keys) {
        $status = if ($results[$key]) { "RÃ‰USSI" } else { "Ã‰CHOUÃ‰" }
        $level = if ($results[$key]) { "SUCCESS" } else { "ERROR" }
        Write-Log "  - $key : $status" -Level $level
    }

    if ($allPassed) {
        Write-Log "Tous les prÃ©requis sont satisfaits. Vous pouvez exÃ©cuter les scripts de la Phase 6." -Level "SUCCESS"
    } else {
        Write-Log "Certains prÃ©requis ne sont pas satisfaits. Veuillez corriger les problÃ¨mes avant d'exÃ©cuter les scripts de la Phase 6." -Level "WARNING"
    }

    return $results
}

# ExÃ©cuter la fonction principale
$results = Test-Phase6Prerequisites

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des vÃ©rifications des prÃ©requis:" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
foreach ($key in $results.Keys) {
    $status = if ($results[$key]) { "RÃ‰USSI" } else { "Ã‰CHOUÃ‰" }
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
    Write-Host "`nTous les prÃ©requis sont satisfaits. Vous pouvez exÃ©cuter les scripts de la Phase 6." -ForegroundColor Green
} else {
    Write-Host "`nCertains prÃ©requis ne sont pas satisfaits. Veuillez corriger les problÃ¨mes avant d'exÃ©cuter les scripts de la Phase 6." -ForegroundColor Yellow
}

Write-Host "Journal: $LogFilePath" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan

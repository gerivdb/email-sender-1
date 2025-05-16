﻿<#
.SYNOPSIS
Débogue les scripts de maintenance VSCode.

.DESCRIPTION
Ce script débogue les scripts de maintenance VSCode en vérifiant leur syntaxe
et en exécutant des tests unitaires. Les résultats sont écrits dans un fichier
de log pour faciliter l'analyse.

.PARAMETER LogFile
    Le chemin du fichier de log où les résultats seront écrits.
    Par défaut: ".\VSCodeScriptsDebug.log"

.EXAMPLE
    .\Debug-VSCodeScripts.ps1

.NOTES
    Auteur: Maintenance Team
    Version: 1.0
    Date de création: 2025-05-16
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$LogFile = ".\VSCodeScriptsDebug.log"
)

# Fonction pour écrire dans le fichier de log
function Write-DebugLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TEST")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    # Écrire dans le fichier de log
    Add-Content -Path $LogFile -Value $logMessage -Encoding UTF8
}

# Fonction pour vérifier la syntaxe d'un script
function Test-ScriptSyntax {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )

    try {
        # Utiliser la méthode moderne pour vérifier la syntaxe (PowerShell 5.1+)
        if ($PSVersionTable.PSVersion.Major -ge 5) {
            $errors = $null
            $null = [System.Management.Automation.Language.Parser]::ParseFile($ScriptPath, [ref]$null, [ref]$errors)

            if ($errors.Count -gt 0) {
                foreach ($error in $errors) {
                    Write-DebugLog "Erreur de syntaxe à la ligne $($error.Extent.StartLineNumber), colonne $($error.Extent.StartColumnNumber): $($error.Message)" -Level "ERROR"
                }
                return $false
            }
        }
        # Méthode de secours pour les anciennes versions de PowerShell
        else {
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $ScriptPath -Raw), [ref]$null)
        }

        Write-DebugLog "Vérification de la syntaxe réussie pour: $ScriptPath" -Level "SUCCESS"
        return $true
    } catch {
        Write-DebugLog "Erreur de syntaxe dans le script $ScriptPath : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester le script Clean-VSCodeProcesses.ps1
function Test-CleanVSCodeProcesses {
    [CmdletBinding()]
    param ()

    $scriptName = "Clean-VSCodeProcesses.ps1"
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptName

    Write-DebugLog "Test du script $scriptName..." -Level "TEST"

    # Vérifier si le script existe
    if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
        Write-DebugLog "Le script $scriptName n'existe pas: $scriptPath" -Level "ERROR"
        return $false
    }

    # Vérifier la syntaxe du script
    if (-not (Test-ScriptSyntax -ScriptPath $scriptPath)) {
        return $false
    }

    # Tester les fonctionnalités du script
    try {
        # Exécuter le script avec WhatIf
        & $scriptPath -WhatIf

        Write-DebugLog "Test du script $scriptName réussi." -Level "SUCCESS"
        return $true
    } catch {
        Write-DebugLog "Erreur lors du test du script $scriptName : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester le script Monitor-VSCodeProcesses.ps1
function Test-MonitorVSCodeProcesses {
    [CmdletBinding()]
    param ()

    $scriptName = "Monitor-VSCodeProcesses.ps1"
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptName

    Write-DebugLog "Test du script $scriptName..." -Level "TEST"

    # Vérifier si le script existe
    if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
        Write-DebugLog "Le script $scriptName n'existe pas: $scriptPath" -Level "ERROR"
        return $false
    }

    # Vérifier la syntaxe du script
    if (-not (Test-ScriptSyntax -ScriptPath $scriptPath)) {
        return $false
    }

    # Tester les fonctionnalités du script
    try {
        # Exécuter le script avec RunOnce
        & $scriptPath -RunOnce

        Write-DebugLog "Test du script $scriptName réussi." -Level "SUCCESS"
        return $true
    } catch {
        Write-DebugLog "Erreur lors du test du script $scriptName : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester le script Configure-VSCodePerformance.ps1
function Test-ConfigureVSCodePerformance {
    [CmdletBinding()]
    param ()

    $scriptName = "Configure-VSCodePerformance.ps1"
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptName

    Write-DebugLog "Test du script $scriptName..." -Level "TEST"

    # Vérifier si le script existe
    if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
        Write-DebugLog "Le script $scriptName n'existe pas: $scriptPath" -Level "ERROR"
        return $false
    }

    # Vérifier la syntaxe du script
    if (-not (Test-ScriptSyntax -ScriptPath $scriptPath)) {
        return $false
    }

    # Tester les fonctionnalités du script
    try {
        # Exécuter le script sans paramètres
        & $scriptPath

        Write-DebugLog "Test du script $scriptName réussi." -Level "SUCCESS"
        return $true
    } catch {
        Write-DebugLog "Erreur lors du test du script $scriptName : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester le script Set-VSCodeStartupOptions.ps1
function Test-SetVSCodeStartupOptions {
    [CmdletBinding()]
    param ()

    $scriptName = "Set-VSCodeStartupOptions.ps1"
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath $scriptName

    Write-DebugLog "Test du script $scriptName..." -Level "TEST"

    # Vérifier si le script existe
    if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
        Write-DebugLog "Le script $scriptName n'existe pas: $scriptPath" -Level "ERROR"
        return $false
    }

    # Vérifier la syntaxe du script
    if (-not (Test-ScriptSyntax -ScriptPath $scriptPath)) {
        return $false
    }

    # Tester les fonctionnalités du script
    try {
        # Exécuter le script sans paramètres
        & $scriptPath

        Write-DebugLog "Test du script $scriptName réussi." -Level "SUCCESS"
        return $true
    } catch {
        Write-DebugLog "Erreur lors du test du script $scriptName : $_" -Level "ERROR"
        return $false
    }
}

# Fonction principale
function Main {
    # Initialiser le fichier de log
    if (Test-Path -Path $LogFile) {
        Remove-Item -Path $LogFile -Force
    }

    Write-DebugLog "Démarrage du débogage des scripts de maintenance VSCode..." -Level "INFO"
    Write-DebugLog "Version PowerShell: $($PSVersionTable.PSVersion)" -Level "INFO"

    $testResults = @()

    # Tester le script Clean-VSCodeProcesses.ps1
    $result = Test-CleanVSCodeProcesses
    $testResults += [PSCustomObject]@{
        Script = "Clean-VSCodeProcesses.ps1"
        Result = $result
    }

    # Tester le script Monitor-VSCodeProcesses.ps1
    $result = Test-MonitorVSCodeProcesses
    $testResults += [PSCustomObject]@{
        Script = "Monitor-VSCodeProcesses.ps1"
        Result = $result
    }

    # Tester le script Configure-VSCodePerformance.ps1
    $result = Test-ConfigureVSCodePerformance
    $testResults += [PSCustomObject]@{
        Script = "Configure-VSCodePerformance.ps1"
        Result = $result
    }

    # Tester le script Set-VSCodeStartupOptions.ps1
    $result = Test-SetVSCodeStartupOptions
    $testResults += [PSCustomObject]@{
        Script = "Set-VSCodeStartupOptions.ps1"
        Result = $result
    }

    # Afficher les résultats des tests
    Write-DebugLog "Résultats des tests:" -Level "INFO"

    $successCount = 0
    $failureCount = 0

    foreach ($test in $testResults) {
        $resultText = if ($test.Result) { "RÉUSSI" } else { "ÉCHOUÉ" }
        $resultLevel = if ($test.Result) { "SUCCESS" } else { "ERROR" }

        Write-DebugLog "Script: $($test.Script) - Résultat: $resultText" -Level $resultLevel

        if ($test.Result) {
            $successCount++
        } else {
            $failureCount++
        }
    }

    Write-DebugLog "Tests terminés. Réussis: $successCount, Échoués: $failureCount" -Level "INFO"

    if ($failureCount -eq 0 -and $successCount -gt 0) {
        Write-DebugLog "Tous les tests ont réussi!" -Level "SUCCESS"
    } elseif ($failureCount -gt 0) {
        Write-DebugLog "Certains tests ont échoué. Vérifiez les erreurs ci-dessus." -Level "ERROR"
    } else {
        Write-DebugLog "Aucun test n'a été exécuté." -Level "WARNING"
    }
}

# Exécuter la fonction principale
Main

# Afficher le contenu du fichier de log
Get-Content -Path $LogFile

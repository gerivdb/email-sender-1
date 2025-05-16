# Script de test simple pour vérifier les scripts de maintenance VSCode
$logFile = ".\VSCodeDebug.log"

# Initialiser le fichier de log
if (Test-Path -Path $logFile) {
    Remove-Item -Path $logFile -Force
}

# Fonction pour écrire dans le fichier de log
function Write-Log {
    param (
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    
    # Écrire dans le fichier de log
    Add-Content -Path $logFile -Value $logMessage -Encoding UTF8
}

# Tester les scripts
Write-Log "Démarrage des tests..."

# Tester Clean-VSCodeProcesses.ps1
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Clean-VSCodeProcesses.ps1"
if (Test-Path -Path $scriptPath) {
    Write-Log "Test de Clean-VSCodeProcesses.ps1..."
    try {
        & $scriptPath -WhatIf
        Write-Log "Clean-VSCodeProcesses.ps1: RÉUSSI"
    }
    catch {
        Write-Log "Clean-VSCodeProcesses.ps1: ÉCHOUÉ - $_"
    }
}
else {
    Write-Log "Clean-VSCodeProcesses.ps1: INTROUVABLE"
}

# Tester Monitor-VSCodeProcesses.ps1
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Monitor-VSCodeProcesses.ps1"
if (Test-Path -Path $scriptPath) {
    Write-Log "Test de Monitor-VSCodeProcesses.ps1..."
    try {
        & $scriptPath -RunOnce
        Write-Log "Monitor-VSCodeProcesses.ps1: RÉUSSI"
    }
    catch {
        Write-Log "Monitor-VSCodeProcesses.ps1: ÉCHOUÉ - $_"
    }
}
else {
    Write-Log "Monitor-VSCodeProcesses.ps1: INTROUVABLE"
}

# Tester Configure-VSCodePerformance.ps1
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Configure-VSCodePerformance.ps1"
if (Test-Path -Path $scriptPath) {
    Write-Log "Test de Configure-VSCodePerformance.ps1..."
    try {
        & $scriptPath
        Write-Log "Configure-VSCodePerformance.ps1: RÉUSSI"
    }
    catch {
        Write-Log "Configure-VSCodePerformance.ps1: ÉCHOUÉ - $_"
    }
}
else {
    Write-Log "Configure-VSCodePerformance.ps1: INTROUVABLE"
}

# Tester Set-VSCodeStartupOptions.ps1
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Set-VSCodeStartupOptions.ps1"
if (Test-Path -Path $scriptPath) {
    Write-Log "Test de Set-VSCodeStartupOptions.ps1..."
    try {
        & $scriptPath
        Write-Log "Set-VSCodeStartupOptions.ps1: RÉUSSI"
    }
    catch {
        Write-Log "Set-VSCodeStartupOptions.ps1: ÉCHOUÉ - $_"
    }
}
else {
    Write-Log "Set-VSCodeStartupOptions.ps1: INTROUVABLE"
}

Write-Log "Tests terminés."

# Afficher le contenu du fichier de log
Get-Content -Path $logFile

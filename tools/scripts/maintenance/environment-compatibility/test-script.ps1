<#
.SYNOPSIS
    Script de test pour l'amélioration de la compatibilité.

.DESCRIPTION
    Ce script contient des problèmes de compatibilité à corriger.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Importer le module EnvironmentManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\maintenance\environment-compatibility\EnvironmentManager.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
}
else {
    Write-Warning "Module EnvironmentManager non trouvé: $modulePath"
}

# Initialiser le module
if (Get-Command -Name Initialize-EnvironmentManager -ErrorAction SilentlyContinue) {
    Initialize-EnvironmentManager
}


# Chemins codés en dur
$logPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\logs"
$configPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\config"

# Utilisation de séparateurs de chemin spécifiques à Windows
$scriptPath = "scripts\utils\path-utils.ps1"

# Commandes spécifiques à Windows
$result = Invoke-CrossPlatformCommand -WindowsCommand 'cmd.exe /c' -UnixCommand 'bash -c' "dir /b"

# Variables d'environnement spécifiques à Windows
$userProfile = if ($IsWindows) { $env:USERPROFILE } else { $HOME }
$appData = if ($IsWindows) { $env:APPDATA } else { Join-Path -Path $HOME -ChildPath ".config" }
$programFiles = if ($IsWindows) { $env:ProgramFiles } else { "/usr/local" }
$systemRoot = if ($IsWindows) { $env:SystemRoot } else { "/" }

# Fonctions spécifiques à PowerShell Windows
$processes = Get-CimInstance -Class Win32_Process
$logs = Get-WinEvent -LogName Application -Newest 10

# Afficher les résultats
Write-Host "Log Path: $logPath"
Write-Host "Config Path: $configPath"
Write-Host "Script Path: $scriptPath"
Write-Host "Result: $result"
Write-Host "User Profile: $userProfile"
Write-Host "App Data: $appData"
Write-Host "Program Files: $programFiles"
Write-Host "System Root: $systemRoot"
Write-Host "Processes: $($processes.Count)"
Write-Host "Logs: $($logs.Count)"


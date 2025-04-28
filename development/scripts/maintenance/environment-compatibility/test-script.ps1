<#
.SYNOPSIS
    Script de test pour l'amÃ©lioration de la compatibilitÃ©.

.DESCRIPTION
    Ce script contient des problÃ¨mes de compatibilitÃ© Ã  corriger.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# Importer le module EnvironmentManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\maintenance\environment-compatibility\EnvironmentManager.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
}
else {
    Write-Warning "Module EnvironmentManager non trouvÃ©: $modulePath"
}

# Initialiser le module
if (Get-Command -Name Initialize-EnvironmentManager -ErrorAction SilentlyContinue) {
    Initialize-EnvironmentManager
}


# Chemins codÃ©s en dur
$logPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\logs"
$configPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\config"

# Utilisation de sÃ©parateurs de chemin spÃ©cifiques Ã  Windows
$scriptPath = "scripts\utils\path-utils.ps1"

# Commandes spÃ©cifiques Ã  Windows
$result = Invoke-CrossPlatformCommand -WindowsCommand 'cmd.exe /c' -UnixCommand 'bash -c' "dir /b"

# Variables d'environnement spÃ©cifiques Ã  Windows
$userProfile = if ($IsWindows) { $env:USERPROFILE } else { $HOME }
$appData = if ($IsWindows) { $env:APPDATA } else { Join-Path -Path $HOME -ChildPath ".config" }
$programFiles = if ($IsWindows) { $env:ProgramFiles } else { "/usr/local" }
$systemRoot = if ($IsWindows) { $env:SystemRoot } else { "/" }

# Fonctions spÃ©cifiques Ã  PowerShell Windows
$processes = Get-CimInstance -Class Win32_Process
$logs = Get-WinEvent -LogName Application -Newest 10

# Afficher les rÃ©sultats
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


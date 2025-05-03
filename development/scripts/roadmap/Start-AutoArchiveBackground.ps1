# Start-AutoArchiveBackground.ps1
# Script pour démarrer le moniteur d'archivage automatique en arrière-plan
# Version: 1.0
# Date: 2025-05-03

[CmdletBinding()]
param (
    [Parameter()]
    [string]$RoadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\active\roadmap_active.md",
    
    [Parameter()]
    [int]$IntervalMinutes = 20,
    
    [Parameter()]
    [string]$IDEProcessName = "Code",
    
    [Parameter()]
    [switch]$UpdateVectorDB,
    
    [Parameter()]
    [switch]$Force
)

# Obtenir le chemin du script de surveillance
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$monitorScriptPath = Join-Path -Path $scriptPath -ChildPath "Start-AutoArchiveMonitor.ps1"

if (-not (Test-Path -Path $monitorScriptPath)) {
    Write-Error "Script de surveillance introuvable: $monitorScriptPath"
    exit 1
}

# Construire les paramètres pour le script de surveillance
$params = @{
    RoadmapPath = $RoadmapPath
    IntervalMinutes = $IntervalMinutes
    IDEProcessName = $IDEProcessName
}

if ($UpdateVectorDB) {
    $params.Add("UpdateVectorDB", $true)
}

if ($Force) {
    $params.Add("Force", $true)
}

# Convertir les paramètres en chaîne de commande
$paramString = ""
foreach ($key in $params.Keys) {
    $value = $params[$key]
    if ($value -is [bool] -and $value) {
        $paramString += " -$key"
    } else {
        $paramString += " -$key `"$value`""
    }
}

# Créer le script PowerShell à exécuter en arrière-plan
$command = "& `"$monitorScriptPath`"$paramString"

# Démarrer le script en arrière-plan
$encodedCommand = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($command))
$process = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $encodedCommand -WindowStyle Minimized -PassThru

# Afficher les informations sur le processus démarré
Write-Host "Moniteur d'archivage automatique démarré en arrière-plan."
Write-Host "ID du processus: $($process.Id)"
Write-Host "Intervalle d'archivage: $IntervalMinutes minutes"
Write-Host "Fichier de roadmap: $RoadmapPath"
Write-Host "Processus IDE: $IDEProcessName"
Write-Host "Mise à jour de la base vectorielle: $UpdateVectorDB"
Write-Host "Mode forcé: $Force"
Write-Host ""
Write-Host "Pour arrêter le moniteur, exécutez la commande suivante:"
Write-Host "Stop-Process -Id $($process.Id) -Force"

# Enregistrer l'ID du processus dans un fichier pour pouvoir l'arrêter facilement plus tard
$pidFilePath = Join-Path -Path $scriptPath -ChildPath "auto_archive_monitor.pid"
$process.Id | Out-File -FilePath $pidFilePath -Force

Write-Host "ID du processus enregistré dans: $pidFilePath"

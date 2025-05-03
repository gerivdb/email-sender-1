# Setup-ArchiveScheduledTask.ps1
# Script pour configurer une tâche planifiée Windows qui archive les tâches terminées
# Version: 1.0
# Date: 2025-05-03

[CmdletBinding()]
param (
    [Parameter()]
    [string]$RoadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\active\roadmap_active.md",
    
    [Parameter()]
    [int]$IntervalMinutes = 20,
    
    [Parameter()]
    [switch]$UpdateVectorDB,
    
    [Parameter()]
    [switch]$Force
)

# Fonction pour créer un raccourci Windows
function New-Shortcut {
    param (
        [string]$TargetPath,
        [string]$ShortcutPath,
        [string]$Arguments,
        [string]$Description,
        [string]$WorkingDirectory,
        [switch]$Hidden
    )
    
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($ShortcutPath)
    $Shortcut.TargetPath = $TargetPath
    $Shortcut.Arguments = $Arguments
    $Shortcut.Description = $Description
    $Shortcut.WorkingDirectory = $WorkingDirectory
    
    if ($Hidden) {
        $Shortcut.WindowStyle = 7 # 7 = Minimized
    }
    
    $Shortcut.Save()
    
    return $ShortcutPath
}

# Obtenir le chemin du script d'exécution
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$executionScriptPath = Join-Path -Path $scriptPath -ChildPath "Execute-ArchiveIfNeeded.ps1"

if (-not (Test-Path -Path $executionScriptPath)) {
    Write-Error "Script d'exécution introuvable: $executionScriptPath"
    exit 1
}

# Construire les paramètres pour le script d'exécution
$params = @{
    RoadmapPath = $RoadmapPath
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

# Créer le dossier de démarrage si nécessaire
$startupFolder = [Environment]::GetFolderPath("Startup")
if (-not (Test-Path -Path $startupFolder)) {
    New-Item -Path $startupFolder -ItemType Directory -Force | Out-Null
}

# Créer un fichier batch qui exécute le script PowerShell
$batchFilePath = Join-Path -Path $scriptPath -ChildPath "RunArchiveTask.bat"
$batchContent = @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$executionScriptPath"$paramString
exit
"@

Set-Content -Path $batchFilePath -Value $batchContent -Encoding ASCII

# Créer un raccourci dans le dossier de démarrage
$shortcutPath = Join-Path -Path $startupFolder -ChildPath "ArchiveRoadmapTasks.lnk"
New-Shortcut -TargetPath "C:\Windows\System32\wscript.exe" -ShortcutPath $shortcutPath -Arguments "`"$scriptPath\RunArchiveTaskHidden.vbs`"" -Description "Archive automatiquement les tâches terminées de la roadmap" -WorkingDirectory $scriptPath -Hidden

# Créer un script VBS pour exécuter le batch file en arrière-plan
$vbsFilePath = Join-Path -Path $scriptPath -ChildPath "RunArchiveTaskHidden.vbs"
$vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run chr(34) & "$batchFilePath" & Chr(34), 0
Set WshShell = Nothing
"@

Set-Content -Path $vbsFilePath -Value $vbsContent -Encoding ASCII

# Créer un fichier XML pour la tâche planifiée
$taskXmlPath = Join-Path -Path $scriptPath -ChildPath "ArchiveTask.xml"
$taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Archive automatiquement les tâches terminées de la roadmap toutes les $IntervalMinutes minutes si l'IDE est ouvert et si le fichier a été modifié.</Description>
  </RegistrationInfo>
  <Triggers>
    <TimeTrigger>
      <Repetition>
        <Interval>PT${IntervalMinutes}M</Interval>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <StartBoundary>$(Get-Date -Format "yyyy-MM-ddTHH:mm:ss")</StartBoundary>
      <Enabled>true</Enabled>
    </TimeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT1H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$executionScriptPath"$paramString</Arguments>
    </Exec>
  </Actions>
</Task>
"@

Set-Content -Path $taskXmlPath -Value $taskXml -Encoding Unicode

# Créer un script pour enregistrer la tâche planifiée
$registerTaskScriptPath = Join-Path -Path $scriptPath -ChildPath "RegisterTask.bat"
$registerTaskContent = @"
@echo off
schtasks /create /tn "ArchiveRoadmapTasks" /xml "$taskXmlPath" /f
"@

Set-Content -Path $registerTaskScriptPath -Value $registerTaskContent -Encoding ASCII

# Créer un script pour supprimer la tâche planifiée
$unregisterTaskScriptPath = Join-Path -Path $scriptPath -ChildPath "UnregisterTask.bat"
$unregisterTaskContent = @"
@echo off
schtasks /delete /tn "ArchiveRoadmapTasks" /f
"@

Set-Content -Path $unregisterTaskScriptPath -Value $unregisterTaskContent -Encoding ASCII

# Enregistrer la tâche planifiée
try {
    $process = Start-Process -FilePath $registerTaskScriptPath -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "Tâche planifiée 'ArchiveRoadmapTasks' enregistrée avec succès."
    } else {
        Write-Warning "Erreur lors de l'enregistrement de la tâche planifiée. Code de sortie: $($process.ExitCode)"
        Write-Host "Vous pouvez enregistrer la tâche manuellement en exécutant le fichier: $registerTaskScriptPath"
    }
} catch {
    Write-Warning "Erreur lors de l'enregistrement de la tâche planifiée: $_"
    Write-Host "Vous pouvez enregistrer la tâche manuellement en exécutant le fichier: $registerTaskScriptPath"
}

Write-Host "Configuration terminée."
Write-Host "La tâche s'exécutera toutes les $IntervalMinutes minutes et vérifiera si l'IDE est ouvert et si le fichier a été modifié."
Write-Host "Fichier de roadmap: $RoadmapPath"
Write-Host "Mise à jour de la base vectorielle: $UpdateVectorDB"
Write-Host "Mode forcé: $Force"
Write-Host ""
Write-Host "Pour supprimer la tâche planifiée, exécutez le fichier: $unregisterTaskScriptPath"
Write-Host "Pour exécuter la tâche manuellement, exécutez le fichier: $batchFilePath"

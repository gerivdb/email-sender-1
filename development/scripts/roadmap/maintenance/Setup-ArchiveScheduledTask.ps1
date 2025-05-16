# Setup-ArchiveScheduledTask.ps1
# Script pour configurer une tÃ¢che planifiÃ©e Windows qui archive les tÃ¢ches terminÃ©es
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

# Fonction pour crÃ©er un raccourci Windows
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

# Obtenir le chemin du script d'exÃ©cution
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$executionScriptPath = Join-Path -Path $scriptPath -ChildPath "Execute-ArchiveIfNeeded.ps1"

if (-not (Test-Path -Path $executionScriptPath)) {
    Write-Error "Script d'exÃ©cution introuvable: $executionScriptPath"
    exit 1
}

# Construire les paramÃ¨tres pour le script d'exÃ©cution
$params = @{
    RoadmapPath = $RoadmapPath
}

if ($UpdateVectorDB) {
    $params.Add("UpdateVectorDB", $true)
}

if ($Force) {
    $params.Add("Force", $true)
}

# Convertir les paramÃ¨tres en chaÃ®ne de commande
$paramString = ""
foreach ($key in $params.Keys) {
    $value = $params[$key]
    if ($value -is [bool] -and $value) {
        $paramString += " -$key"
    } else {
        $paramString += " -$key `"$value`""
    }
}

# CrÃ©er le dossier de dÃ©marrage si nÃ©cessaire
$startupFolder = [Environment]::GetFolderPath("Startup")
if (-not (Test-Path -Path $startupFolder)) {
    New-Item -Path $startupFolder -ItemType Directory -Force | Out-Null
}

# CrÃ©er un fichier batch qui exÃ©cute le script PowerShell
$batchFilePath = Join-Path -Path $scriptPath -ChildPath "RunArchiveTask.bat"
$batchContent = @"
@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "$executionScriptPath"$paramString
exit
"@

Set-Content -Path $batchFilePath -Value $batchContent -Encoding ASCII

# CrÃ©er un raccourci dans le dossier de dÃ©marrage
$shortcutPath = Join-Path -Path $startupFolder -ChildPath "ArchiveRoadmapTasks.lnk"
New-Shortcut -TargetPath "C:\Windows\System32\wscript.exe" -ShortcutPath $shortcutPath -Arguments "`"$scriptPath\RunArchiveTaskHidden.vbs`"" -Description "Archive automatiquement les tÃ¢ches terminÃ©es de la roadmap" -WorkingDirectory $scriptPath -Hidden

# CrÃ©er un script VBS pour exÃ©cuter le batch file en arriÃ¨re-plan
$vbsFilePath = Join-Path -Path $scriptPath -ChildPath "RunArchiveTaskHidden.vbs"
$vbsContent = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run chr(34) & "$batchFilePath" & Chr(34), 0
Set WshShell = Nothing
"@

Set-Content -Path $vbsFilePath -Value $vbsContent -Encoding ASCII

# CrÃ©er un fichier XML pour la tÃ¢che planifiÃ©e
$taskXmlPath = Join-Path -Path $scriptPath -ChildPath "ArchiveTask.xml"
$taskXml = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Archive automatiquement les tÃ¢ches terminÃ©es de la roadmap toutes les $IntervalMinutes minutes si l'IDE est ouvert et si le fichier a Ã©tÃ© modifiÃ©.</Description>
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

# CrÃ©er un script pour enregistrer la tÃ¢che planifiÃ©e
$registerTaskScriptPath = Join-Path -Path $scriptPath -ChildPath "RegisterTask.bat"
$registerTaskContent = @"
@echo off
schtasks /create /tn "ArchiveRoadmapTasks" /xml "$taskXmlPath" /f
"@

Set-Content -Path $registerTaskScriptPath -Value $registerTaskContent -Encoding ASCII

# CrÃ©er un script pour supprimer la tÃ¢che planifiÃ©e
$unregisterTaskScriptPath = Join-Path -Path $scriptPath -ChildPath "UnregisterTask.bat"
$unregisterTaskContent = @"
@echo off
schtasks /delete /tn "ArchiveRoadmapTasks" /f
"@

Set-Content -Path $unregisterTaskScriptPath -Value $unregisterTaskContent -Encoding ASCII

# Enregistrer la tÃ¢che planifiÃ©e
try {
    $process = Start-Process -FilePath $registerTaskScriptPath -NoNewWindow -Wait -PassThru
    if ($process.ExitCode -eq 0) {
        Write-Host "TÃ¢che planifiÃ©e 'ArchiveRoadmapTasks' enregistrÃ©e avec succÃ¨s."
    } else {
        Write-Warning "Erreur lors de l'enregistrement de la tÃ¢che planifiÃ©e. Code de sortie: $($process.ExitCode)"
        Write-Host "Vous pouvez enregistrer la tÃ¢che manuellement en exÃ©cutant le fichier: $registerTaskScriptPath"
    }
} catch {
    Write-Warning "Erreur lors de l'enregistrement de la tÃ¢che planifiÃ©e: $_"
    Write-Host "Vous pouvez enregistrer la tÃ¢che manuellement en exÃ©cutant le fichier: $registerTaskScriptPath"
}

Write-Host "Configuration terminÃ©e."
Write-Host "La tÃ¢che s'exÃ©cutera toutes les $IntervalMinutes minutes et vÃ©rifiera si l'IDE est ouvert et si le fichier a Ã©tÃ© modifiÃ©."
Write-Host "Fichier de roadmap: $RoadmapPath"
Write-Host "Mise Ã  jour de la base vectorielle: $UpdateVectorDB"
Write-Host "Mode forcÃ©: $Force"
Write-Host ""
Write-Host "Pour supprimer la tÃ¢che planifiÃ©e, exÃ©cutez le fichier: $unregisterTaskScriptPath"
Write-Host "Pour exÃ©cuter la tÃ¢che manuellement, exÃ©cutez le fichier: $batchFilePath"

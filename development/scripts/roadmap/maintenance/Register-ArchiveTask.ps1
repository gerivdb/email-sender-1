# Register-ArchiveTask.ps1
# Script pour enregistrer une tÃ¢che planifiÃ©e Windows qui archive les tÃ¢ches terminÃ©es
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

# Obtenir le chemin du script d'archivage
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$archiveScriptPath = Join-Path -Path $scriptPath -ChildPath "Archive-CompletedTasks.ps1"

if (-not (Test-Path -Path $archiveScriptPath)) {
    Write-Error "Script d'archivage introuvable: $archiveScriptPath"
    exit 1
}

# CrÃ©er le script d'exÃ©cution qui vÃ©rifie si l'IDE est ouvert et si le fichier a Ã©tÃ© modifiÃ©
$executionScriptPath = Join-Path -Path $scriptPath -ChildPath "Execute-ArchiveIfNeeded.ps1"

$executionScriptContent = @"
# Execute-ArchiveIfNeeded.ps1
# Script exÃ©cutÃ© par la tÃ¢che planifiÃ©e pour archiver les tÃ¢ches terminÃ©es si nÃ©cessaire
# Version: 1.0
# Date: 2025-05-03

[CmdletBinding()]
param (
    [Parameter(Mandatory=`$true)]
    [string]`$RoadmapPath,

    [Parameter()]
    [switch]`$UpdateVectorDB,

    [Parameter()]
    [switch]`$Force
)

# VÃ©rifier si l'IDE est ouvert
function Test-IDERunning {
    `$process = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    return `$null -ne `$process
}

# VÃ©rifier si le fichier a Ã©tÃ© modifiÃ© depuis la derniÃ¨re exÃ©cution
function Test-FileChanged {
    param (
        [string]`$FilePath,
        [string]`$LastRunFilePath
    )

    if (-not (Test-Path -Path `$FilePath)) {
        return `$false
    }

    `$lastWriteTime = (Get-Item -Path `$FilePath).LastWriteTime

    if (Test-Path -Path `$LastRunFilePath) {
        `$lastRunTime = Get-Content -Path `$LastRunFilePath | ConvertFrom-Json
        `$lastRunDateTime = [datetime]`$lastRunTime.LastRun
        return `$lastWriteTime -gt `$lastRunDateTime
    }

    return `$true
}

# Mettre Ã  jour le fichier de derniÃ¨re exÃ©cution
function Update-LastRunTime {
    param (
        [string]`$LastRunFilePath
    )

    `$lastRun = @{
        LastRun = (Get-Date).ToString("o")
    }

    `$lastRun | ConvertTo-Json | Set-Content -Path `$LastRunFilePath -Encoding UTF8
}

# Chemin du fichier de derniÃ¨re exÃ©cution
`$lastRunFilePath = Join-Path -Path "`$PSScriptRoot" -ChildPath "last_archive_run.json"

# VÃ©rifier si l'IDE est ouvert
`$ideRunning = Test-IDERunning

if (-not `$ideRunning) {
    # L'IDE n'est pas ouvert, ne rien faire
    exit 0
}

# VÃ©rifier si le fichier a Ã©tÃ© modifiÃ©
`$fileChanged = Test-FileChanged -FilePath `$RoadmapPath -LastRunFilePath `$lastRunFilePath

if (-not `$fileChanged) {
    # Le fichier n'a pas Ã©tÃ© modifiÃ©, ne rien faire
    exit 0
}

# L'IDE est ouvert et le fichier a Ã©tÃ© modifiÃ©, exÃ©cuter l'archivage
`$archiveScriptPath = Join-Path -Path "`$PSScriptRoot" -ChildPath "Archive-CompletedTasks.ps1"

if (-not (Test-Path -Path `$archiveScriptPath)) {
    Write-Error "Script d'archivage introuvable: `$archiveScriptPath"
    exit 1
}

# Construire les paramÃ¨tres pour le script d'archivage
`$params = @{
    RoadmapPath = `$RoadmapPath
}

if (`$UpdateVectorDB) {
    `$params.Add("UpdateVectorDB", `$true)
}

if (`$Force) {
    `$params.Add("Force", `$true)
}

# ExÃ©cuter le script d'archivage
& `$archiveScriptPath @params

# Mettre Ã  jour le fichier de derniÃ¨re exÃ©cution
Update-LastRunTime -LastRunFilePath `$lastRunFilePath
"@

Set-Content -Path $executionScriptPath -Value $executionScriptContent -Encoding UTF8

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

# CrÃ©er la commande PowerShell Ã  exÃ©cuter par la tÃ¢che planifiÃ©e
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$executionScriptPath`"$paramString"

# CrÃ©er le dÃ©clencheur pour exÃ©cuter la tÃ¢che toutes les X minutes
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 3650)

# CrÃ©er les paramÃ¨tres de la tÃ¢che
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -Hidden

# CrÃ©er la tÃ¢che planifiÃ©e
$taskName = "ArchiveRoadmapTasks"
$description = "Archive automatiquement les tÃ¢ches terminÃ©es de la roadmap toutes les $IntervalMinutes minutes si l'IDE est ouvert et si le fichier a Ã©tÃ© modifiÃ©."

# Supprimer la tÃ¢che si elle existe dÃ©jÃ 
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Enregistrer la tÃ¢che
Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskName $taskName -Description $description -RunLevel Highest

Write-Host "TÃ¢che planifiÃ©e '$taskName' enregistrÃ©e avec succÃ¨s."
Write-Host "La tÃ¢che s'exÃ©cutera toutes les $IntervalMinutes minutes et vÃ©rifiera si l'IDE est ouvert et si le fichier a Ã©tÃ© modifiÃ©."
Write-Host "Fichier de roadmap: $RoadmapPath"
Write-Host "Mise Ã  jour de la base vectorielle: $UpdateVectorDB"
Write-Host "Mode forcÃ©: $Force"

# Register-ArchiveTask.ps1
# Script pour enregistrer une tâche planifiée Windows qui archive les tâches terminées
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

# Créer le script d'exécution qui vérifie si l'IDE est ouvert et si le fichier a été modifié
$executionScriptPath = Join-Path -Path $scriptPath -ChildPath "Execute-ArchiveIfNeeded.ps1"

$executionScriptContent = @"
# Execute-ArchiveIfNeeded.ps1
# Script exécuté par la tâche planifiée pour archiver les tâches terminées si nécessaire
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

# Vérifier si l'IDE est ouvert
function Test-IDERunning {
    `$process = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    return `$null -ne `$process
}

# Vérifier si le fichier a été modifié depuis la dernière exécution
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

# Mettre à jour le fichier de dernière exécution
function Update-LastRunTime {
    param (
        [string]`$LastRunFilePath
    )

    `$lastRun = @{
        LastRun = (Get-Date).ToString("o")
    }

    `$lastRun | ConvertTo-Json | Set-Content -Path `$LastRunFilePath -Encoding UTF8
}

# Chemin du fichier de dernière exécution
`$lastRunFilePath = Join-Path -Path "`$PSScriptRoot" -ChildPath "last_archive_run.json"

# Vérifier si l'IDE est ouvert
`$ideRunning = Test-IDERunning

if (-not `$ideRunning) {
    # L'IDE n'est pas ouvert, ne rien faire
    exit 0
}

# Vérifier si le fichier a été modifié
`$fileChanged = Test-FileChanged -FilePath `$RoadmapPath -LastRunFilePath `$lastRunFilePath

if (-not `$fileChanged) {
    # Le fichier n'a pas été modifié, ne rien faire
    exit 0
}

# L'IDE est ouvert et le fichier a été modifié, exécuter l'archivage
`$archiveScriptPath = Join-Path -Path "`$PSScriptRoot" -ChildPath "Archive-CompletedTasks.ps1"

if (-not (Test-Path -Path `$archiveScriptPath)) {
    Write-Error "Script d'archivage introuvable: `$archiveScriptPath"
    exit 1
}

# Construire les paramètres pour le script d'archivage
`$params = @{
    RoadmapPath = `$RoadmapPath
}

if (`$UpdateVectorDB) {
    `$params.Add("UpdateVectorDB", `$true)
}

if (`$Force) {
    `$params.Add("Force", `$true)
}

# Exécuter le script d'archivage
& `$archiveScriptPath @params

# Mettre à jour le fichier de dernière exécution
Update-LastRunTime -LastRunFilePath `$lastRunFilePath
"@

Set-Content -Path $executionScriptPath -Value $executionScriptContent -Encoding UTF8

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

# Créer la commande PowerShell à exécuter par la tâche planifiée
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$executionScriptPath`"$paramString"

# Créer le déclencheur pour exécuter la tâche toutes les X minutes
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $IntervalMinutes) -RepetitionDuration (New-TimeSpan -Days 3650)

# Créer les paramètres de la tâche
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable -Hidden

# Créer la tâche planifiée
$taskName = "ArchiveRoadmapTasks"
$description = "Archive automatiquement les tâches terminées de la roadmap toutes les $IntervalMinutes minutes si l'IDE est ouvert et si le fichier a été modifié."

# Supprimer la tâche si elle existe déjà
$existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
}

# Enregistrer la tâche
Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskName $taskName -Description $description -RunLevel Highest

Write-Host "Tâche planifiée '$taskName' enregistrée avec succès."
Write-Host "La tâche s'exécutera toutes les $IntervalMinutes minutes et vérifiera si l'IDE est ouvert et si le fichier a été modifié."
Write-Host "Fichier de roadmap: $RoadmapPath"
Write-Host "Mise à jour de la base vectorielle: $UpdateVectorDB"
Write-Host "Mode forcé: $Force"

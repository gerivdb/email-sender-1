# Execute-ArchiveIfNeeded.ps1
# Script exécuté par la tâche planifiée pour archiver les tâches terminées si nécessaire
# Version: 1.0
# Date: 2025-05-03

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)]
    [string]$RoadmapPath,

    [Parameter()]
    [switch]$UpdateVectorDB,

    [Parameter()]
    [switch]$Force
)

# Vérifier si l'IDE est ouvert
function Test-IDERunning {
    $process = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    return $null -ne $process
}

# Vérifier si le fichier a été modifié depuis la dernière exécution
function Test-FileChanged {
    param (
        [string]$FilePath,
        [string]$LastRunFilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        return $false
    }

    $lastWriteTime = (Get-Item -Path $FilePath).LastWriteTime

    if (Test-Path -Path $LastRunFilePath) {
        $lastRunTime = Get-Content -Path $LastRunFilePath | ConvertFrom-Json
        $lastRunDateTime = [datetime]$lastRunTime.LastRun
        return $lastWriteTime -gt $lastRunDateTime
    }

    return $true
}

# Mettre à jour le fichier de dernière exécution
function Update-LastRunTime {
    param (
        [string]$LastRunFilePath
    )

    $lastRun = @{
        LastRun = (Get-Date).ToString("o")
    }

    $lastRun | ConvertTo-Json | Set-Content -Path $LastRunFilePath -Encoding UTF8
}

# Chemin du fichier de dernière exécution
$lastRunFilePath = Join-Path -Path "$PSScriptRoot" -ChildPath "last_archive_run.json"

# Vérifier si l'IDE est ouvert
$ideRunning = Test-IDERunning

if (-not $ideRunning) {
    # L'IDE n'est pas ouvert, ne rien faire
    exit 0
}

# Vérifier si le fichier a été modifié
$fileChanged = Test-FileChanged -FilePath $RoadmapPath -LastRunFilePath $lastRunFilePath

if (-not $fileChanged) {
    # Le fichier n'a pas été modifié, ne rien faire
    exit 0
}

# L'IDE est ouvert et le fichier a été modifié, exécuter l'archivage
$archiveScriptPath = Join-Path -Path "$PSScriptRoot" -ChildPath "Archive-CompletedTasks.ps1"

if (-not (Test-Path -Path $archiveScriptPath)) {
    Write-Error "Script d'archivage introuvable: $archiveScriptPath"
    exit 1
}

# Construire les paramètres pour le script d'archivage
$params = @{
    RoadmapPath = $RoadmapPath
}

if ($UpdateVectorDB) {
    $params.Add("UpdateVectorDB", $true)
}

if ($Force) {
    $params.Add("Force", $true)
}

# Exécuter le script d'archivage
& $archiveScriptPath @params

# Mettre à jour le fichier de dernière exécution
Update-LastRunTime -LastRunFilePath $lastRunFilePath

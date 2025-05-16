# Execute-ArchiveIfNeeded.ps1
# Script exÃ©cutÃ© par la tÃ¢che planifiÃ©e pour archiver les tÃ¢ches terminÃ©es si nÃ©cessaire
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

# VÃ©rifier si l'IDE est ouvert
function Test-IDERunning {
    $process = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    return $null -ne $process
}

# VÃ©rifier si le fichier a Ã©tÃ© modifiÃ© depuis la derniÃ¨re exÃ©cution
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

# Mettre Ã  jour le fichier de derniÃ¨re exÃ©cution
function Update-LastRunTime {
    param (
        [string]$LastRunFilePath
    )

    $lastRun = @{
        LastRun = (Get-Date).ToString("o")
    }

    $lastRun | ConvertTo-Json | Set-Content -Path $LastRunFilePath -Encoding UTF8
}

# Chemin du fichier de derniÃ¨re exÃ©cution
$lastRunFilePath = Join-Path -Path "$PSScriptRoot" -ChildPath "last_archive_run.json"

# VÃ©rifier si l'IDE est ouvert
$ideRunning = Test-IDERunning

if (-not $ideRunning) {
    # L'IDE n'est pas ouvert, ne rien faire
    exit 0
}

# VÃ©rifier si le fichier a Ã©tÃ© modifiÃ©
$fileChanged = Test-FileChanged -FilePath $RoadmapPath -LastRunFilePath $lastRunFilePath

if (-not $fileChanged) {
    # Le fichier n'a pas Ã©tÃ© modifiÃ©, ne rien faire
    exit 0
}

# L'IDE est ouvert et le fichier a Ã©tÃ© modifiÃ©, exÃ©cuter l'archivage
$archiveScriptPath = Join-Path -Path "$PSScriptRoot" -ChildPath "Archive-CompletedTasks.ps1"

if (-not (Test-Path -Path $archiveScriptPath)) {
    Write-Error "Script d'archivage introuvable: $archiveScriptPath"
    exit 1
}

# Construire les paramÃ¨tres pour le script d'archivage
$params = @{
    RoadmapPath = $RoadmapPath
}

if ($UpdateVectorDB) {
    $params.Add("UpdateVectorDB", $true)
}

if ($Force) {
    $params.Add("Force", $true)
}

# ExÃ©cuter le script d'archivage
& $archiveScriptPath @params

# Mettre Ã  jour le fichier de derniÃ¨re exÃ©cution
Update-LastRunTime -LastRunFilePath $lastRunFilePath

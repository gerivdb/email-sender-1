# Show-TaskLogs.ps1
# Script pour afficher et gÃ©rer les journaux des tÃ¢ches dÃ©tectÃ©es et traitÃ©es

param (
    [Parameter(Mandatory = $false)]
    [string]$LogFile = ".\tasks-log.txt",
    
    [Parameter(Mandatory = $false)]
    [int]$LastEntries = 0,
    
    [Parameter(Mandatory = $false)]
    [switch]$Clear,
    
    [Parameter(Mandatory = $false)]
    [switch]$Export,
    
    [Parameter(Mandatory = $false)]
    [string]$ExportFile = ".\tasks-log-export.csv"
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$taskLogPath = Join-Path -Path $scriptPath -ChildPath "tasks-log.txt"

# Utiliser le chemin par dÃ©faut si non spÃ©cifiÃ©
if ($LogFile -eq ".\tasks-log.txt") {
    $LogFile = $taskLogPath
}

# VÃ©rifier que le fichier de journal existe
if (-not (Test-Path -Path $LogFile)) {
    Write-Error "Le fichier de journal '$LogFile' n'existe pas."
    exit 1
}

# Fonction pour effacer le journal
function Clear-Log {
    param (
        [string]$LogFile
    )
    
    $confirmation = Read-Host "ÃŠtes-vous sÃ»r de vouloir effacer le journal ? Cette action est irrÃ©versible. (O/N)"
    
    if ($confirmation -eq "O" -or $confirmation -eq "o") {
        Clear-Content -Path $LogFile
        Write-Host "Journal effacÃ© avec succÃ¨s." -ForegroundColor Green
    }
    else {
        Write-Host "OpÃ©ration annulÃ©e." -ForegroundColor Yellow
    }
}

# Fonction pour exporter le journal au format CSV
function Export-Log {
    param (
        [string]$LogFile,
        [string]$ExportFile
    )
    
    $logs = Get-Content -Path $LogFile
    $csvData = @()
    
    foreach ($log in $logs) {
        if ($log -match "\[(.*?)\] (.*?) : (.*)") {
            $timestamp = $matches[1]
            $action = $matches[2]
            $details = $matches[3]
            
            $csvData += [PSCustomObject]@{
                Timestamp = $timestamp
                Action = $action
                Details = $details
            }
        }
    }
    
    if ($csvData.Count -eq 0) {
        Write-Host "Aucune entrÃ©e de journal Ã  exporter." -ForegroundColor Yellow
        return
    }
    
    $csvData | Export-Csv -Path $ExportFile -NoTypeInformation
    Write-Host "Journal exportÃ© avec succÃ¨s vers '$ExportFile'." -ForegroundColor Green
}

# Fonction pour afficher le journal
function Show-Log {
    param (
        [string]$LogFile,
        [int]$LastEntries
    )
    
    $logs = Get-Content -Path $LogFile
    
    if ($logs.Count -eq 0) {
        Write-Host "Le journal est vide." -ForegroundColor Yellow
        return
    }
    
    if ($LastEntries -gt 0 -and $LastEntries -lt $logs.Count) {
        $logs = $logs | Select-Object -Last $LastEntries
        Write-Host "Affichage des $LastEntries derniÃ¨res entrÃ©es du journal :"
    }
    else {
        Write-Host "Affichage de toutes les entrÃ©es du journal ($($logs.Count) entrÃ©es) :"
    }
    
    Write-Host ""
    
    foreach ($log in $logs) {
        if ($log -match "\[(.*?)\] (.*?) : (.*)") {
            $timestamp = $matches[1]
            $action = $matches[2]
            $details = $matches[3]
            
            $color = switch ($action) {
                "Analyse" { "Cyan" }
                "Ajout" { "Green" }
                "Erreur" { "Red" }
                "IgnorÃ©" { "Yellow" }
                "SupprimÃ©" { "Magenta" }
                default { "White" }
            }
            
            Write-Host "[$timestamp] " -NoNewline
            Write-Host "$action : " -NoNewline -ForegroundColor $color
            Write-Host "$details"
        }
        else {
            Write-Host $log
        }
    }
}

# Traitement des actions
if ($Clear) {
    Clear-Log -LogFile $LogFile
}
elseif ($Export) {
    Export-Log -LogFile $LogFile -ExportFile $ExportFile
}
else {
    Show-Log -LogFile $LogFile -LastEntries $LastEntries
}

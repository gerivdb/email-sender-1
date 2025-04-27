# Module de suivi des modifications pour le Script Manager
# Ce module suit les modifications apportÃ©es aux scripts
# Author: Script Manager
# Version: 1.0
# Tags: monitoring, changes, scripts

function Initialize-ChangeTracker {
    <#
    .SYNOPSIS
        Initialise le suivi des modifications
    .DESCRIPTION
        Configure le suivi des modifications pour les scripts
    .PARAMETER Inventory
        Objet d'inventaire des scripts
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les rÃ©sultats du suivi
    .EXAMPLE
        Initialize-ChangeTracker -Inventory $inventory -OutputPath "monitoring"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Inventory,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    # CrÃ©er le dossier de suivi des modifications
    $ChangesPath = Join-Path -Path $OutputPath -ChildPath "changes"
    if (-not (Test-Path -Path $ChangesPath)) {
        New-Item -ItemType Directory -Path $ChangesPath -Force | Out-Null
    }
    
    Write-Host "Initialisation du suivi des modifications..." -ForegroundColor Cyan
    
    # CrÃ©er un instantanÃ© initial des scripts
    $Snapshot = @()
    
    foreach ($Script in $Inventory.Scripts) {
        # Calculer le hash du fichier
        $FileHash = Get-FileHash -Path $Script.Path -Algorithm SHA256 -ErrorAction SilentlyContinue
        
        if ($FileHash) {
            $Snapshot += [PSCustomObject]@{
                Path = $Script.Path
                Name = $Script.Name
                Type = $Script.Type
                Hash = $FileHash.Hash
                LastWriteTime = (Get-Item -Path $Script.Path).LastWriteTime
                Size = (Get-Item -Path $Script.Path).Length
                SnapshotTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
    }
    
    # Enregistrer l'instantanÃ© initial
    $SnapshotPath = Join-Path -Path $ChangesPath -ChildPath "initial_snapshot.json"
    $Snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path $SnapshotPath
    
    Write-Host "  InstantanÃ© initial crÃ©Ã©: $SnapshotPath" -ForegroundColor Green
    
    # CrÃ©er le fichier d'historique des modifications
    $HistoryPath = Join-Path -Path $ChangesPath -ChildPath "changes_history.json"
    $History = @{
        LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Changes = @()
    } | ConvertTo-Json -Depth 10
    
    Set-Content -Path $HistoryPath -Value $History
    
    Write-Host "  Historique des modifications initialisÃ©: $HistoryPath" -ForegroundColor Green
    
    # Configurer le FileSystemWatcher pour surveiller les modifications en temps rÃ©el
    $WatcherConfig = @{
        ChangesPath = $ChangesPath
        HistoryPath = $HistoryPath
        SnapshotPath = $SnapshotPath
    }
    
    $WatcherConfigPath = Join-Path -Path $ChangesPath -ChildPath "watcher_config.json"
    $WatcherConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $WatcherConfigPath
    
    # CrÃ©er le script de surveillance des modifications
    $WatcherScriptPath = Join-Path -Path $ChangesPath -ChildPath "Start-ChangeWatcher.ps1"
    $WatcherScriptContent = @"
<#
.SYNOPSIS
    Surveille les modifications des scripts en temps rÃ©el
.DESCRIPTION
    Utilise FileSystemWatcher pour surveiller les modifications des scripts
    et les enregistre dans l'historique des modifications
.PARAMETER ConfigPath
    Chemin vers le fichier de configuration du watcher
.EXAMPLE
    .\Start-ChangeWatcher.ps1 -ConfigPath "monitoring\changes\watcher_config.json"
#>

param (
    [Parameter(Mandatory=`$true)]
    [string]`$ConfigPath
)

# VÃ©rifier si le fichier de configuration existe
if (-not (Test-Path -Path `$ConfigPath)) {
    Write-Error "Fichier de configuration non trouvÃ©: `$ConfigPath"
    exit 1
}

# Charger la configuration
try {
    `$Config = Get-Content -Path `$ConfigPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement de la configuration: `$_"
    exit 1
}

# Charger l'instantanÃ© initial
try {
    `$Snapshot = Get-Content -Path `$Config.SnapshotPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement de l'instantanÃ©: `$_"
    exit 1
}

# Charger l'historique des modifications
try {
    `$History = Get-Content -Path `$Config.HistoryPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement de l'historique: `$_"
    exit 1
}

# Fonction pour enregistrer une modification
function Register-Change {
    param (
        [string]`$Path,
        [string]`$ChangeType,
        [string]`$Details = ""
    )
    
    # Obtenir le nom et le type du script
    `$ScriptName = Split-Path -Leaf `$Path
    `$ScriptType = switch -Regex (`$ScriptName) {
        "\.ps1`$" { "PowerShell" }
        "\.py`$" { "Python" }
        "\.cmd`$|\.bat`$" { "Batch" }
        "\.sh`$" { "Shell" }
        default { "Unknown" }
    }
    
    # CrÃ©er l'objet de modification
    `$Change = [PSCustomObject]@{
        Path = `$Path
        Name = `$ScriptName
        Type = `$ScriptType
        ChangeType = `$ChangeType
        Details = `$Details
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    # Ajouter la modification Ã  l'historique
    `$History.Changes += `$Change
    `$History.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Enregistrer l'historique
    `$History | ConvertTo-Json -Depth 10 | Set-Content -Path `$Config.HistoryPath
    
    Write-Host "Modification enregistrÃ©e: `$ChangeType - `$Path" -ForegroundColor Yellow
}

# CrÃ©er les FileSystemWatcher pour chaque dossier contenant des scripts
`$Watchers = @()

# Obtenir tous les dossiers uniques contenant des scripts
`$ScriptFolders = `$Snapshot | ForEach-Object { Split-Path -Parent `$_.Path } | Sort-Object -Unique

foreach (`$Folder in `$ScriptFolders) {
    # CrÃ©er un nouveau FileSystemWatcher
    `$Watcher = New-Object System.IO.FileSystemWatcher
    `$Watcher.Path = `$Folder
    `$Watcher.IncludeSubdirectories = `$true
    `$Watcher.EnableRaisingEvents = `$true
    
    # DÃ©finir les filtres pour les types de scripts
    `$Watcher.Filter = "*.ps1"
    
    # DÃ©finir les Ã©vÃ©nements
    `$Action = {
        `$Path = `$Event.SourceEventArgs.FullPath
        `$ChangeType = `$Event.SourceEventArgs.ChangeType
        
        # VÃ©rifier si le fichier est un script connu
        `$IsKnownScript = `$Snapshot | Where-Object { `$_.Path -eq `$Path }
        
        if (`$IsKnownScript) {
            switch (`$ChangeType) {
                "Changed" {
                    # Calculer le nouveau hash
                    `$NewHash = Get-FileHash -Path `$Path -Algorithm SHA256 -ErrorAction SilentlyContinue
                    
                    if (`$NewHash) {
                        # VÃ©rifier si le hash a changÃ©
                        `$OldHash = (`$Snapshot | Where-Object { `$_.Path -eq `$Path }).Hash
                        
                        if (`$NewHash.Hash -ne `$OldHash) {
                            # Mettre Ã  jour le hash dans l'instantanÃ©
                            (`$Snapshot | Where-Object { `$_.Path -eq `$Path }).Hash = `$NewHash.Hash
                            (`$Snapshot | Where-Object { `$_.Path -eq `$Path }).LastWriteTime = (Get-Item -Path `$Path).LastWriteTime
                            (`$Snapshot | Where-Object { `$_.Path -eq `$Path }).Size = (Get-Item -Path `$Path).Length
                            (`$Snapshot | Where-Object { `$_.Path -eq `$Path }).SnapshotTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                            
                            # Enregistrer l'instantanÃ© mis Ã  jour
                            `$Snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path `$Config.SnapshotPath
                            
                            # Enregistrer la modification
                            Register-Change -Path `$Path -ChangeType "Modified" -Details "Hash changed from `$OldHash to `$(`$NewHash.Hash)"
                        }
                    }
                }
                "Deleted" {
                    # Enregistrer la suppression
                    Register-Change -Path `$Path -ChangeType "Deleted"
                    
                    # Supprimer le script de l'instantanÃ©
                    `$Snapshot = `$Snapshot | Where-Object { `$_.Path -ne `$Path }
                    
                    # Enregistrer l'instantanÃ© mis Ã  jour
                    `$Snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path `$Config.SnapshotPath
                }
                "Renamed" {
                    # Obtenir le nouveau nom
                    `$NewPath = `$Event.SourceEventArgs.FullPath
                    `$OldPath = `$Event.SourceEventArgs.OldFullPath
                    
                    # Enregistrer le renommage
                    Register-Change -Path `$OldPath -ChangeType "Renamed" -Details "Renamed to `$NewPath"
                    
                    # Mettre Ã  jour le chemin dans l'instantanÃ©
                    (`$Snapshot | Where-Object { `$_.Path -eq `$OldPath }).Path = `$NewPath
                    (`$Snapshot | Where-Object { `$_.Path -eq `$OldPath }).Name = Split-Path -Leaf `$NewPath
                    (`$Snapshot | Where-Object { `$_.Path -eq `$OldPath }).SnapshotTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    
                    # Enregistrer l'instantanÃ© mis Ã  jour
                    `$Snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path `$Config.SnapshotPath
                }
                "Created" {
                    # VÃ©rifier si le fichier est un script
                    `$Extension = [System.IO.Path]::GetExtension(`$Path).ToLower()
                    
                    if (`$Extension -in ".ps1", ".py", ".cmd", ".bat", ".sh") {
                        # Calculer le hash du nouveau fichier
                        `$NewHash = Get-FileHash -Path `$Path -Algorithm SHA256 -ErrorAction SilentlyContinue
                        
                        if (`$NewHash) {
                            # Ajouter le script Ã  l'instantanÃ©
                            `$NewScript = [PSCustomObject]@{
                                Path = `$Path
                                Name = Split-Path -Leaf `$Path
                                Type = switch (`$Extension) {
                                    ".ps1" { "PowerShell" }
                                    ".py" { "Python" }
                                    ".cmd" { "Batch" }
                                    ".bat" { "Batch" }
                                    ".sh" { "Shell" }
                                    default { "Unknown" }
                                }
                                Hash = `$NewHash.Hash
                                LastWriteTime = (Get-Item -Path `$Path).LastWriteTime
                                Size = (Get-Item -Path `$Path).Length
                                SnapshotTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                            }
                            
                            `$Snapshot += `$NewScript
                            
                            # Enregistrer l'instantanÃ© mis Ã  jour
                            `$Snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path `$Config.SnapshotPath
                            
                            # Enregistrer la crÃ©ation
                            Register-Change -Path `$Path -ChangeType "Created"
                        }
                    }
                }
            }
        }
    }
    
    # Enregistrer les Ã©vÃ©nements
    `$Changed = Register-ObjectEvent -InputObject `$Watcher -EventName Changed -Action `$Action
    `$Created = Register-ObjectEvent -InputObject `$Watcher -EventName Created -Action `$Action
    `$Deleted = Register-ObjectEvent -InputObject `$Watcher -EventName Deleted -Action `$Action
    `$Renamed = Register-ObjectEvent -InputObject `$Watcher -EventName Renamed -Action `$Action
    
    # Ajouter le watcher au tableau
    `$Watchers += `$Watcher
}

Write-Host "Surveillance des modifications dÃ©marrÃ©e. Appuyez sur Ctrl+C pour arrÃªter." -ForegroundColor Green

try {
    # Maintenir le script en cours d'exÃ©cution
    while (`$true) {
        Start-Sleep -Seconds 1
    }
} finally {
    # Nettoyer les Ã©vÃ©nements et les watchers
    Get-EventSubscriber | Unregister-Event
    `$Watchers | ForEach-Object { `$_.Dispose() }
    Write-Host "Surveillance des modifications arrÃªtÃ©e." -ForegroundColor Yellow
}
"@
    
    Set-Content -Path $WatcherScriptPath -Value $WatcherScriptContent
    
    Write-Host "  Script de surveillance crÃ©Ã©: $WatcherScriptPath" -ForegroundColor Green
    
    return [PSCustomObject]@{
        ChangesPath = $ChangesPath
        SnapshotPath = $SnapshotPath
        HistoryPath = $HistoryPath
        WatcherScriptPath = $WatcherScriptPath
        WatcherConfigPath = $WatcherConfigPath
        ScriptCount = $Snapshot.Count
    }
}

function Get-ScriptChanges {
    <#
    .SYNOPSIS
        Obtient les modifications des scripts
    .DESCRIPTION
        RÃ©cupÃ¨re l'historique des modifications des scripts
    .PARAMETER HistoryPath
        Chemin vers le fichier d'historique des modifications
    .PARAMETER Since
        Date Ã  partir de laquelle rÃ©cupÃ©rer les modifications
    .EXAMPLE
        Get-ScriptChanges -HistoryPath "monitoring\changes\changes_history.json" -Since (Get-Date).AddDays(-7)
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$HistoryPath,
        
        [Parameter()]
        [DateTime]$Since = (Get-Date).AddDays(-30)
    )
    
    # VÃ©rifier si le fichier d'historique existe
    if (-not (Test-Path -Path $HistoryPath)) {
        Write-Error "Fichier d'historique non trouvÃ©: $HistoryPath"
        return $null
    }
    
    # Charger l'historique
    try {
        $History = Get-Content -Path $HistoryPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de l'historique: $_"
        return $null
    }
    
    # Filtrer les modifications par date
    $FilteredChanges = $History.Changes | Where-Object {
        [DateTime]::ParseExact($_.Timestamp, "yyyy-MM-dd HH:mm:ss", $null) -ge $Since
    }
    
    return $FilteredChanges
}

function Compare-ScriptSnapshots {
    <#
    .SYNOPSIS
        Compare deux instantanÃ©s de scripts
    .DESCRIPTION
        Compare deux instantanÃ©s pour dÃ©tecter les modifications entre eux
    .PARAMETER SnapshotPath1
        Chemin vers le premier instantanÃ©
    .PARAMETER SnapshotPath2
        Chemin vers le deuxiÃ¨me instantanÃ©
    .EXAMPLE
        Compare-ScriptSnapshots -SnapshotPath1 "monitoring\changes\snapshot_20230101.json" -SnapshotPath2 "monitoring\changes\snapshot_20230201.json"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$SnapshotPath1,
        
        [Parameter(Mandatory=$true)]
        [string]$SnapshotPath2
    )
    
    # VÃ©rifier si les fichiers d'instantanÃ© existent
    if (-not (Test-Path -Path $SnapshotPath1)) {
        Write-Error "Fichier d'instantanÃ© 1 non trouvÃ©: $SnapshotPath1"
        return $null
    }
    
    if (-not (Test-Path -Path $SnapshotPath2)) {
        Write-Error "Fichier d'instantanÃ© 2 non trouvÃ©: $SnapshotPath2"
        return $null
    }
    
    # Charger les instantanÃ©s
    try {
        $Snapshot1 = Get-Content -Path $SnapshotPath1 -Raw | ConvertFrom-Json
        $Snapshot2 = Get-Content -Path $SnapshotPath2 -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement des instantanÃ©s: $_"
        return $null
    }
    
    # Comparer les instantanÃ©s
    $Comparison = @{
        Added = @()
        Removed = @()
        Modified = @()
        Unchanged = @()
    }
    
    # Trouver les scripts ajoutÃ©s et modifiÃ©s
    foreach ($Script2 in $Snapshot2) {
        $Script1 = $Snapshot1 | Where-Object { $_.Path -eq $Script2.Path }
        
        if ($Script1) {
            # Le script existe dans les deux instantanÃ©s
            if ($Script1.Hash -ne $Script2.Hash) {
                # Le script a Ã©tÃ© modifiÃ©
                $Comparison.Modified += [PSCustomObject]@{
                    Path = $Script2.Path
                    Name = $Script2.Name
                    Type = $Script2.Type
                    OldHash = $Script1.Hash
                    NewHash = $Script2.Hash
                    OldSize = $Script1.Size
                    NewSize = $Script2.Size
                    OldLastWriteTime = $Script1.LastWriteTime
                    NewLastWriteTime = $Script2.LastWriteTime
                }
            } else {
                # Le script n'a pas changÃ©
                $Comparison.Unchanged += [PSCustomObject]@{
                    Path = $Script2.Path
                    Name = $Script2.Name
                    Type = $Script2.Type
                    Hash = $Script2.Hash
                }
            }
        } else {
            # Le script a Ã©tÃ© ajoutÃ©
            $Comparison.Added += [PSCustomObject]@{
                Path = $Script2.Path
                Name = $Script2.Name
                Type = $Script2.Type
                Hash = $Script2.Hash
                Size = $Script2.Size
                LastWriteTime = $Script2.LastWriteTime
            }
        }
    }
    
    # Trouver les scripts supprimÃ©s
    foreach ($Script1 in $Snapshot1) {
        $Script2 = $Snapshot2 | Where-Object { $_.Path -eq $Script1.Path }
        
        if (-not $Script2) {
            # Le script a Ã©tÃ© supprimÃ©
            $Comparison.Removed += [PSCustomObject]@{
                Path = $Script1.Path
                Name = $Script1.Name
                Type = $Script1.Type
                Hash = $Script1.Hash
                Size = $Script1.Size
                LastWriteTime = $Script1.LastWriteTime
            }
        }
    }
    
    return $Comparison
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-ChangeTracker, Get-ScriptChanges, Compare-ScriptSnapshots

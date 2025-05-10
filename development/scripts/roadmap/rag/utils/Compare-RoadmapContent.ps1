# Compare-RoadmapContent.ps1
# Script pour comparer le contenu des roadmaps et détecter les changements
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OriginalContent,
    
    [Parameter(Mandatory = $false)]
    [string]$NewContent,
    
    [Parameter(Mandatory = $false)]
    [string]$OriginalPath,
    
    [Parameter(Mandatory = $false)]
    [string]$NewPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetailedOutput,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path $scriptPath -ChildPath "..\utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        Write-Host "[$Level] $Message"
    }
}

# Fonction pour calculer le hachage d'une chaîne
function Get-ContentHash {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    $stringAsStream = [System.IO.MemoryStream]::new([System.Text.Encoding]::UTF8.GetBytes($Content))
    $hash = Get-FileHash -InputStream $stringAsStream -Algorithm SHA256
    return $hash.Hash
}

# Fonction pour extraire les tâches d'un contenu markdown
function Get-TasksFromContent {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    $tasks = @()
    $lines = $Content -split "`n"
    
    foreach ($line in $lines) {
        if ($line -match '^\s*-\s*\[([ xX])\]\s*(?:\*\*([0-9.]+)\*\*)?\s*(.+)$') {
            $status = $matches[1] -ne ' ' ? "Completed" : "Incomplete"
            $taskId = $matches[2]
            $description = $matches[3].Trim()
            
            # Calculer le niveau d'indentation
            $indentLevel = ($line -match '^\s+') ? $matches[0].Length : 0
            
            $tasks += [PSCustomObject]@{
                TaskId = $taskId
                Description = $description
                Status = $status
                IndentLevel = $indentLevel
                OriginalLine = $line
                Hash = Get-ContentHash -Content $line
            }
        }
    }
    
    return $tasks
}

# Fonction pour comparer deux ensembles de tâches
function Compare-Tasks {
    param (
        [Parameter(Mandatory = $true)]
        [array]$OriginalTasks,
        
        [Parameter(Mandatory = $true)]
        [array]$NewTasks
    )
    
    $changes = @{
        Added = @()
        Removed = @()
        Modified = @()
        StatusChanged = @()
        Moved = @()
        Unchanged = @()
    }
    
    # Créer des dictionnaires pour un accès rapide
    $originalTasksById = @{}
    $newTasksById = @{}
    
    foreach ($task in $OriginalTasks) {
        if ($task.TaskId) {
            $originalTasksById[$task.TaskId] = $task
        }
    }
    
    foreach ($task in $NewTasks) {
        if ($task.TaskId) {
            $newTasksById[$task.TaskId] = $task
        }
    }
    
    # Trouver les tâches ajoutées et modifiées
    foreach ($task in $NewTasks) {
        if ($task.TaskId -and $originalTasksById.ContainsKey($task.TaskId)) {
            $originalTask = $originalTasksById[$task.TaskId]
            
            if ($task.Hash -ne $originalTask.Hash) {
                if ($task.Status -ne $originalTask.Status) {
                    $changes.StatusChanged += [PSCustomObject]@{
                        TaskId = $task.TaskId
                        OldStatus = $originalTask.Status
                        NewStatus = $task.Status
                        Description = $task.Description
                    }
                }
                
                if ($task.IndentLevel -ne $originalTask.IndentLevel) {
                    $changes.Moved += [PSCustomObject]@{
                        TaskId = $task.TaskId
                        OldIndentLevel = $originalTask.IndentLevel
                        NewIndentLevel = $task.IndentLevel
                        Description = $task.Description
                    }
                }
                
                if ($task.Description -ne $originalTask.Description) {
                    $changes.Modified += [PSCustomObject]@{
                        TaskId = $task.TaskId
                        OldDescription = $originalTask.Description
                        NewDescription = $task.Description
                    }
                }
            } else {
                $changes.Unchanged += $task
            }
        } else {
            $changes.Added += $task
        }
    }
    
    # Trouver les tâches supprimées
    foreach ($task in $OriginalTasks) {
        if ($task.TaskId -and -not $newTasksById.ContainsKey($task.TaskId)) {
            $changes.Removed += $task
        }
    }
    
    return $changes
}

# Fonction principale
function Compare-RoadmapContent {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OriginalContent,
        
        [Parameter(Mandatory = $true)]
        [string]$NewContent,
        
        [Parameter(Mandatory = $false)]
        [switch]$DetailedOutput
    )
    
    # Calculer les hachages globaux
    $originalHash = Get-ContentHash -Content $OriginalContent
    $newHash = Get-ContentHash -Content $NewContent
    
    # Si les hachages sont identiques, aucun changement
    if ($originalHash -eq $newHash) {
        Write-Log "Aucun changement détecté (hachages identiques)" -Level "Info"
        return @{
            HasChanges = $false
            GlobalHashMatch = $true
            Changes = $null
        }
    }
    
    # Extraire les tâches
    $originalTasks = Get-TasksFromContent -Content $OriginalContent
    $newTasks = Get-TasksFromContent -Content $NewContent
    
    # Comparer les tâches
    $changes = Compare-Tasks -OriginalTasks $originalTasks -NewTasks $newTasks
    
    # Déterminer s'il y a des changements significatifs
    $hasChanges = $changes.Added.Count -gt 0 -or 
                 $changes.Removed.Count -gt 0 -or 
                 $changes.Modified.Count -gt 0 -or 
                 $changes.StatusChanged.Count -gt 0 -or 
                 $changes.Moved.Count -gt 0
    
    return @{
        HasChanges = $hasChanges
        GlobalHashMatch = $false
        Changes = $changes
        OriginalTaskCount = $originalTasks.Count
        NewTaskCount = $newTasks.Count
    }
}

# Fonction principale du script
function Main {
    # Vérifier si nous avons le contenu ou les chemins
    if (-not $OriginalContent -and -not $OriginalPath) {
        Write-Log "Vous devez spécifier soit OriginalContent, soit OriginalPath" -Level "Error"
        return
    }
    
    if (-not $NewContent -and -not $NewPath) {
        Write-Log "Vous devez spécifier soit NewContent, soit NewPath" -Level "Error"
        return
    }
    
    # Charger le contenu à partir des fichiers si nécessaire
    if (-not $OriginalContent -and $OriginalPath) {
        if (Test-Path -Path $OriginalPath) {
            $OriginalContent = Get-Content -Path $OriginalPath -Raw
        } else {
            Write-Log "Le fichier original n'existe pas: $OriginalPath" -Level "Error"
            return
        }
    }
    
    if (-not $NewContent -and $NewPath) {
        if (Test-Path -Path $NewPath) {
            $NewContent = Get-Content -Path $NewPath -Raw
        } else {
            Write-Log "Le nouveau fichier n'existe pas: $NewPath" -Level "Error"
            return
        }
    }
    
    # Comparer le contenu
    $result = Compare-RoadmapContent -OriginalContent $OriginalContent -NewContent $NewContent -DetailedOutput:$DetailedOutput
    
    # Afficher les résultats
    if ($result.HasChanges) {
        Write-Log "Changements détectés:" -Level "Info"
        Write-Log "  - Tâches ajoutées: $($result.Changes.Added.Count)" -Level "Info"
        Write-Log "  - Tâches supprimées: $($result.Changes.Removed.Count)" -Level "Info"
        Write-Log "  - Tâches modifiées: $($result.Changes.Modified.Count)" -Level "Info"
        Write-Log "  - Statuts changés: $($result.Changes.StatusChanged.Count)" -Level "Info"
        Write-Log "  - Tâches déplacées: $($result.Changes.Moved.Count)" -Level "Info"
        Write-Log "  - Tâches inchangées: $($result.Changes.Unchanged.Count)" -Level "Info"
    } else {
        Write-Log "Aucun changement significatif détecté" -Level "Info"
    }
    
    # Enregistrer les résultats détaillés si demandé
    if ($OutputPath) {
        $result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Log "Résultats détaillés enregistrés dans $OutputPath" -Level "Info"
    }
    
    return $result
}

# Exécuter la fonction principale
Main

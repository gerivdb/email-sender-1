# Find-TaskMovements.ps1
# Script pour détecter les déplacements de tâches dans les roadmaps
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

# Fonction pour extraire les tâches avec leur contexte
function Get-TasksWithContext {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    $tasks = @()
    $lines = $Content -split "`n"
    $headers = @()
    $currentPath = @()
    
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Détecter les en-têtes
        if ($line -match '^(#+)\s+(.+)$') {
            $level = $matches[1].Length
            $title = $matches[2].Trim()
            
            # Ajuster le chemin actuel
            if ($headers.Count -gt 0 -and $level -le $headers[-1].Level) {
                $currentPath = $currentPath[0..($level - 2)]
            }
            
            $currentPath += $title
            
            $headers += [PSCustomObject]@{
                Level = $level
                Title = $title
                LineNumber = $i
                Path = $currentPath -join " > "
            }
        }
        # Détecter les tâches
        elseif ($line -match '^\s*-\s*\[([ xX])\]\s*(?:\*\*([0-9.]+)\*\*)?\s*(.+)$') {
            $status = $matches[1] -ne ' ' ? "Completed" : "Incomplete"
            $taskId = $matches[2]
            $description = $matches[3].Trim()
            
            # Calculer le niveau d'indentation
            $indentLevel = ($line -match '^\s+') ? $matches[0].Length : 0
            
            # Trouver le parent (tâche précédente avec un niveau d'indentation inférieur)
            $parentId = $null
            $parentDescription = $null
            
            for ($j = $i - 1; $j -ge 0; $j--) {
                $prevLine = $lines[$j]
                if ($prevLine -match '^\s*-\s*\[([ xX])\]\s*(?:\*\*([0-9.]+)\*\*)?\s*(.+)$') {
                    $prevIndent = ($prevLine -match '^\s+') ? $matches[0].Length : 0
                    
                    if ($prevIndent -lt $indentLevel) {
                        $parentId = $matches[2]
                        $parentDescription = $matches[3].Trim()
                        break
                    }
                }
            }
            
            # Trouver le contexte (en-tête le plus proche)
            $context = $null
            if ($headers.Count -gt 0) {
                $context = $headers[-1].Path
            }
            
            $tasks += [PSCustomObject]@{
                TaskId = $taskId
                Description = $description
                Status = $status
                IndentLevel = $indentLevel
                LineNumber = $i
                ParentId = $parentId
                ParentDescription = $parentDescription
                Context = $context
                Path = $currentPath -join " > "
                OriginalLine = $line
            }
        }
    }
    
    return $tasks
}

# Fonction pour détecter les déplacements de tâches
function Find-Movements {
    param (
        [Parameter(Mandatory = $true)]
        [array]$OriginalTasks,
        
        [Parameter(Mandatory = $true)]
        [array]$NewTasks
    )
    
    $movements = @{
        ContextChanges = @()
        ParentChanges = @()
        IndentChanges = @()
        OrderChanges = @()
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
    
    # Détecter les changements de contexte et de parent
    foreach ($taskId in $newTasksById.Keys) {
        if ($originalTasksById.ContainsKey($taskId)) {
            $originalTask = $originalTasksById[$taskId]
            $newTask = $newTasksById[$taskId]
            
            # Changement de contexte (en-tête)
            if ($newTask.Context -ne $originalTask.Context) {
                $movements.ContextChanges += [PSCustomObject]@{
                    TaskId = $taskId
                    Description = $newTask.Description
                    OldContext = $originalTask.Context
                    NewContext = $newTask.Context
                }
            }
            
            # Changement de parent
            if ($newTask.ParentId -ne $originalTask.ParentId) {
                $movements.ParentChanges += [PSCustomObject]@{
                    TaskId = $taskId
                    Description = $newTask.Description
                    OldParentId = $originalTask.ParentId
                    NewParentId = $newTask.ParentId
                    OldParentDescription = $originalTask.ParentDescription
                    NewParentDescription = $newTask.ParentDescription
                }
            }
            
            # Changement de niveau d'indentation
            if ($newTask.IndentLevel -ne $originalTask.IndentLevel) {
                $movements.IndentChanges += [PSCustomObject]@{
                    TaskId = $taskId
                    Description = $newTask.Description
                    OldIndentLevel = $originalTask.IndentLevel
                    NewIndentLevel = $newTask.IndentLevel
                }
            }
        }
    }
    
    # Détecter les changements d'ordre
    $originalOrder = $OriginalTasks | Where-Object { $_.TaskId } | ForEach-Object { $_.TaskId }
    $newOrder = $NewTasks | Where-Object { $_.TaskId } | ForEach-Object { $_.TaskId }
    
    $commonTasks = $originalOrder | Where-Object { $newOrder -contains $_ }
    
    for ($i = 0; $i -lt $commonTasks.Count; $i++) {
        $taskId = $commonTasks[$i]
        $originalIndex = [array]::IndexOf($originalOrder, $taskId)
        $newIndex = [array]::IndexOf($newOrder, $taskId)
        
        # Si la position relative a changé
        if ($i -gt 0) {
            $prevTaskId = $commonTasks[$i - 1]
            $originalPrevIndex = [array]::IndexOf($originalOrder, $prevTaskId)
            $newPrevIndex = [array]::IndexOf($newOrder, $prevTaskId)
            
            if (($originalIndex - $originalPrevIndex) -ne ($newIndex - $newPrevIndex)) {
                $movements.OrderChanges += [PSCustomObject]@{
                    TaskId = $taskId
                    Description = $newTasksById[$taskId].Description
                    OldPosition = $originalIndex
                    NewPosition = $newIndex
                    RelativeChange = $true
                }
            }
        }
    }
    
    return $movements
}

# Fonction principale
function Find-TaskMovements {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OriginalContent,
        
        [Parameter(Mandatory = $true)]
        [string]$NewContent,
        
        [Parameter(Mandatory = $false)]
        [switch]$DetailedOutput
    )
    
    # Extraire les tâches avec leur contexte
    $originalTasks = Get-TasksWithContext -Content $OriginalContent
    $newTasks = Get-TasksWithContext -Content $NewContent
    
    # Détecter les mouvements
    $movements = Find-Movements -OriginalTasks $originalTasks -NewTasks $newTasks
    
    # Déterminer s'il y a des mouvements
    $hasMovements = $movements.ContextChanges.Count -gt 0 -or 
                   $movements.ParentChanges.Count -gt 0 -or 
                   $movements.IndentChanges.Count -gt 0 -or 
                   $movements.OrderChanges.Count -gt 0
    
    return @{
        HasMovements = $hasMovements
        Movements = $movements
        OriginalTasks = if ($DetailedOutput) { $originalTasks } else { $null }
        NewTasks = if ($DetailedOutput) { $newTasks } else { $null }
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
    
    # Détecter les mouvements
    $result = Find-TaskMovements -OriginalContent $OriginalContent -NewContent $NewContent -DetailedOutput:$DetailedOutput
    
    # Afficher les résultats
    if ($result.HasMovements) {
        Write-Log "Mouvements de tâches détectés:" -Level "Info"
        Write-Log "  - Changements de contexte: $($result.Movements.ContextChanges.Count)" -Level "Info"
        Write-Log "  - Changements de parent: $($result.Movements.ParentChanges.Count)" -Level "Info"
        Write-Log "  - Changements d'indentation: $($result.Movements.IndentChanges.Count)" -Level "Info"
        Write-Log "  - Changements d'ordre: $($result.Movements.OrderChanges.Count)" -Level "Info"
    } else {
        Write-Log "Aucun mouvement de tâche détecté" -Level "Info"
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


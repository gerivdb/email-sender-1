# Propagate-RoadmapChanges.ps1
# Script pour propager les changements dans la hiérarchie des tâches
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "projet/roadmaps/active/roadmap_active.md",
    
    [Parameter(Mandatory = $false)]
    [string]$ChangesPath,
    
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333",
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [switch]$UpdateVectors,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path $scriptPath -ChildPath "utils"
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

# Fonction pour extraire la hiérarchie des tâches
function Get-TaskHierarchy {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    $tasks = @{}
    $taskRelations = @{}
    $lines = $Content -split "`n"
    $currentPath = @()
    $lastTaskAtLevel = @{}
    
    foreach ($line in $lines) {
        # Détecter les tâches
        if ($line -match '^\s*-\s*\[([ xX])\]\s*(?:\*\*([0-9.]+)\*\*)?\s*(.+)$') {
            $status = $matches[1] -ne ' ' ? "Completed" : "Incomplete"
            $taskId = $matches[2]
            $description = $matches[3].Trim()
            
            # Calculer le niveau d'indentation
            $indentLevel = ($line -match '^\s+') ? $matches[0].Length : 0
            
            # Stocker la tâche
            if ($taskId) {
                $tasks[$taskId] = @{
                    Description = $description
                    Status = $status
                    IndentLevel = $indentLevel
                    Children = @()
                    Parent = $null
                }
                
                # Trouver le parent
                foreach ($level in ($indentLevel - 1)..0) {
                    if ($lastTaskAtLevel.ContainsKey($level)) {
                        $parentId = $lastTaskAtLevel[$level]
                        $tasks[$taskId].Parent = $parentId
                        $tasks[$parentId].Children += $taskId
                        break
                    }
                }
                
                # Mettre à jour le dernier ID à ce niveau
                $lastTaskAtLevel[$indentLevel] = $taskId
                
                # Supprimer les niveaux plus profonds
                foreach ($level in ($indentLevel + 1)..100) {
                    $lastTaskAtLevel.Remove($level)
                }
            }
        }
    }
    
    return $tasks
}

# Fonction pour propager les changements de statut
function Propagate-StatusChanges {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks,
        
        [Parameter(Mandatory = $true)]
        [array]$StatusChanges
    )
    
    $propagatedChanges = @()
    
    foreach ($change in $StatusChanges) {
        $taskId = $change.TaskId
        $newStatus = $change.NewStatus
        
        # Propager vers le haut (parents)
        $currentId = $taskId
        while ($Tasks[$currentId].Parent) {
            $parentId = $Tasks[$currentId].Parent
            $parent = $Tasks[$parentId]
            
            # Vérifier si tous les enfants sont complétés
            $allChildrenCompleted = $true
            foreach ($childId in $parent.Children) {
                if ($childId -eq $currentId) {
                    # Utiliser le nouveau statut pour l'enfant qui a changé
                    if ($newStatus -ne "Completed") {
                        $allChildrenCompleted = $false
                        break
                    }
                } else {
                    # Utiliser le statut actuel pour les autres enfants
                    if ($Tasks[$childId].Status -ne "Completed") {
                        $allChildrenCompleted = $false
                        break
                    }
                }
            }
            
            # Si tous les enfants sont complétés et le parent ne l'est pas, propager le changement
            if ($allChildrenCompleted -and $parent.Status -ne "Completed") {
                $propagatedChanges += [PSCustomObject]@{
                    TaskId = $parentId
                    OldStatus = $parent.Status
                    NewStatus = "Completed"
                    Description = $parent.Description
                    PropagationType = "ChildrenCompleted"
                }
            }
            # Si un enfant n'est pas complété et le parent l'est, propager le changement
            elseif (-not $allChildrenCompleted -and $parent.Status -eq "Completed") {
                $propagatedChanges += [PSCustomObject]@{
                    TaskId = $parentId
                    OldStatus = $parent.Status
                    NewStatus = "Incomplete"
                    Description = $parent.Description
                    PropagationType = "ChildIncomplete"
                }
            }
            
            $currentId = $parentId
        }
        
        # Propager vers le bas (enfants)
        if ($newStatus -eq "Completed") {
            # Si une tâche est marquée comme complétée, vérifier si elle a des enfants non complétés
            $stack = New-Object System.Collections.Stack
            foreach ($childId in $Tasks[$taskId].Children) {
                $stack.Push($childId)
            }
            
            while ($stack.Count -gt 0) {
                $currentId = $stack.Pop()
                $current = $Tasks[$currentId]
                
                if ($current.Status -ne "Completed") {
                    $propagatedChanges += [PSCustomObject]@{
                        TaskId = $currentId
                        OldStatus = $current.Status
                        NewStatus = "Completed"
                        Description = $current.Description
                        PropagationType = "ParentCompleted"
                    }
                }
                
                foreach ($childId in $current.Children) {
                    $stack.Push($childId)
                }
            }
        }
    }
    
    return $propagatedChanges
}

# Fonction pour propager les changements de contexte
function Propagate-ContextChanges {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks,
        
        [Parameter(Mandatory = $true)]
        [array]$ContextChanges
    )
    
    $propagatedChanges = @()
    
    foreach ($change in $ContextChanges) {
        $taskId = $change.TaskId
        $newContext = $change.NewContext
        
        # Propager vers le bas (enfants)
        $stack = New-Object System.Collections.Stack
        foreach ($childId in $Tasks[$taskId].Children) {
            $stack.Push($childId)
        }
        
        while ($stack.Count -gt 0) {
            $currentId = $stack.Pop()
            
            $propagatedChanges += [PSCustomObject]@{
                TaskId = $currentId
                OldContext = $null  # Nous n'avons pas cette information ici
                NewContext = $newContext
                Description = $Tasks[$currentId].Description
                PropagationType = "ParentContextChanged"
            }
            
            foreach ($childId in $Tasks[$currentId].Children) {
                $stack.Push($childId)
            }
        }
    }
    
    return $propagatedChanges
}

# Fonction pour propager les changements de parent
function Propagate-ParentChanges {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks,
        
        [Parameter(Mandatory = $true)]
        [array]$ParentChanges
    )
    
    $propagatedChanges = @()
    
    foreach ($change in $ParentChanges) {
        $taskId = $change.TaskId
        $newParentId = $change.NewParentId
        
        # Propager vers le bas (enfants)
        $stack = New-Object System.Collections.Stack
        foreach ($childId in $Tasks[$taskId].Children) {
            $stack.Push(@{
                Id = $childId
                ParentChain = @($taskId)
            })
        }
        
        while ($stack.Count -gt 0) {
            $current = $stack.Pop()
            $currentId = $current.Id
            $parentChain = $current.ParentChain
            
            $propagatedChanges += [PSCustomObject]@{
                TaskId = $currentId
                ParentChain = $parentChain
                Description = $Tasks[$currentId].Description
                PropagationType = "AncestorParentChanged"
            }
            
            foreach ($childId in $Tasks[$currentId].Children) {
                $stack.Push(@{
                    Id = $childId
                    ParentChain = $parentChain + @($currentId)
                })
            }
        }
    }
    
    return $propagatedChanges
}

# Fonction pour mettre à jour le fichier roadmap avec les changements propagés
function Update-RoadmapWithPropagatedChanges {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $true)]
        [array]$PropagatedChanges
    )
    
    # Charger le contenu du fichier
    $content = Get-Content -Path $RoadmapPath -Raw
    $lines = $content -split "`n"
    $modified = $false
    
    # Créer un dictionnaire pour un accès rapide
    $changesByTaskId = @{}
    foreach ($change in $PropagatedChanges) {
        if ($change.TaskId) {
            $changesByTaskId[$change.TaskId] = $change
        }
    }
    
    # Parcourir les lignes et appliquer les changements
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Détecter les tâches
        if ($line -match '^\s*-\s*\[([ xX])\]\s*(?:\*\*([0-9.]+)\*\*)?\s*(.+)$') {
            $status = $matches[1]
            $taskId = $matches[2]
            $description = $matches[3]
            
            if ($taskId -and $changesByTaskId.ContainsKey($taskId)) {
                $change = $changesByTaskId[$taskId]
                
                # Mettre à jour le statut
                if ($change.NewStatus) {
                    $newStatus = $change.NewStatus -eq "Completed" ? "x" : " "
                    if ($status -ne $newStatus) {
                        $lines[$i] = $line -replace '\[([ xX])\]', "[$newStatus]"
                        $modified = $true
                    }
                }
            }
        }
    }
    
    # Enregistrer le fichier si des modifications ont été apportées
    if ($modified) {
        $lines -join "`n" | Set-Content -Path $RoadmapPath -Encoding UTF8
        Write-Log "Fichier roadmap mis à jour avec les changements propagés: $RoadmapPath" -Level "Success"
        return $true
    } else {
        Write-Log "Aucune modification nécessaire dans le fichier roadmap." -Level "Info"
        return $false
    }
}

# Fonction pour créer un fichier de changements propagés
function New-PropagatedChangesFile {
    param (
        [Parameter(Mandatory = $true)]
        [array]$PropagatedChanges,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    $result = @{
        PropagatedChanges = $PropagatedChanges
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Count = $PropagatedChanges.Count
    }
    
    $result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Log "Fichier de changements propagés créé: $OutputPath" -Level "Success"
    
    return $OutputPath
}

# Fonction principale
function Propagate-RoadmapChanges {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ChangesPath,
        
        [Parameter(Mandatory = $false)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $false)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $false)]
        [switch]$UpdateVectors,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si les fichiers existent
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Log "Le fichier roadmap n'existe pas: $RoadmapPath" -Level "Error"
        return $false
    }
    
    if (-not (Test-Path -Path $ChangesPath)) {
        Write-Log "Le fichier de changements n'existe pas: $ChangesPath" -Level "Error"
        return $false
    }
    
    # Charger les changements
    $changes = Get-Content -Path $ChangesPath -Raw | ConvertFrom-Json
    
    # Vérifier s'il y a des changements
    if (-not $changes.HasChanges) {
        Write-Log "Aucun changement détecté. Aucune propagation nécessaire." -Level "Info"
        return $true
    }
    
    # Charger le contenu du fichier roadmap
    $content = Get-Content -Path $RoadmapPath -Raw
    
    # Extraire la hiérarchie des tâches
    Write-Log "Extraction de la hiérarchie des tâches..." -Level "Info"
    $tasks = Get-TaskHierarchy -Content $content
    
    # Propager les changements de statut
    Write-Log "Propagation des changements de statut..." -Level "Info"
    $statusChanges = @()
    if ($changes.ContentChanges.Changes.StatusChanged) {
        $statusChanges = $changes.ContentChanges.Changes.StatusChanged
    }
    $propagatedStatusChanges = Propagate-StatusChanges -Tasks $tasks -StatusChanges $statusChanges
    
    # Propager les changements de contexte
    Write-Log "Propagation des changements de contexte..." -Level "Info"
    $contextChanges = @()
    if ($changes.TaskMovements.Movements.ContextChanges) {
        $contextChanges = $changes.TaskMovements.Movements.ContextChanges
    }
    $propagatedContextChanges = Propagate-ContextChanges -Tasks $tasks -ContextChanges $contextChanges
    
    # Propager les changements de parent
    Write-Log "Propagation des changements de parent..." -Level "Info"
    $parentChanges = @()
    if ($changes.TaskMovements.Movements.ParentChanges) {
        $parentChanges = $changes.TaskMovements.Movements.ParentChanges
    }
    $propagatedParentChanges = Propagate-ParentChanges -Tasks $tasks -ParentChanges $parentChanges
    
    # Combiner tous les changements propagés
    $allPropagatedChanges = $propagatedStatusChanges + $propagatedContextChanges + $propagatedParentChanges
    
    # Afficher un résumé des changements propagés
    Write-Log "Changements propagés:" -Level "Info"
    Write-Log "  - Changements de statut: $($propagatedStatusChanges.Count)" -Level "Info"
    Write-Log "  - Changements de contexte: $($propagatedContextChanges.Count)" -Level "Info"
    Write-Log "  - Changements de parent: $($propagatedParentChanges.Count)" -Level "Info"
    Write-Log "  - Total: $($allPropagatedChanges.Count)" -Level "Info"
    
    # Mettre à jour le fichier roadmap avec les changements propagés
    if ($allPropagatedChanges.Count -gt 0) {
        Write-Log "Mise à jour du fichier roadmap avec les changements propagés..." -Level "Info"
        $updated = Update-RoadmapWithPropagatedChanges -RoadmapPath $RoadmapPath -PropagatedChanges $allPropagatedChanges
        
        # Créer un fichier de changements propagés
        $propagatedChangesPath = $ChangesPath -replace "\.json$", "_propagated.json"
        New-PropagatedChangesFile -PropagatedChanges $allPropagatedChanges -OutputPath $propagatedChangesPath
        
        # Mettre à jour les vecteurs si demandé
        if ($UpdateVectors -and $updated) {
            Write-Log "Mise à jour des vecteurs avec les changements propagés..." -Level "Info"
            $updateScriptPath = Join-Path -Path $scriptPath -ChildPath "Update-SelectiveVectors.ps1"
            
            if (Test-Path -Path $updateScriptPath) {
                & $updateScriptPath -RoadmapPath $RoadmapPath -ChangesPath $propagatedChangesPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -Force:$Force
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Vecteurs mis à jour avec succès." -Level "Success"
                } else {
                    Write-Log "Erreur lors de la mise à jour des vecteurs." -Level "Error"
                }
            } else {
                Write-Log "Script de mise à jour des vecteurs introuvable: $updateScriptPath" -Level "Error"
            }
        }
    } else {
        Write-Log "Aucun changement à propager." -Level "Info"
    }
    
    return $true
}

# Exécuter la fonction principale
Propagate-RoadmapChanges -RoadmapPath $RoadmapPath -ChangesPath $ChangesPath -QdrantUrl $QdrantUrl -CollectionName $CollectionName -UpdateVectors:$UpdateVectors -Force:$Force

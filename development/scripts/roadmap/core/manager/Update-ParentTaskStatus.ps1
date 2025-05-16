# Update-ParentTaskStatus.ps1
# Script pour mettre à jour automatiquement le statut des tâches parents en fonction des tâches enfants
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\plans\plan-dev-v8-RAG-roadmap.md",

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Fonction pour écrire des messages de journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        default { "White" }
    }

    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Fonction pour extraire la hiérarchie des tâches du fichier Markdown
function Get-TaskHierarchy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Log "Le fichier n'existe pas: $FilePath" -Level "Error"
        return $null
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8 -ErrorAction Stop

    # Vérifier si le contenu est vide
    if ($null -eq $content -or $content.Count -eq 0) {
        Write-Log "Le fichier est vide: $FilePath" -Level "Error"
        return $null
    }

    Write-Host "Contenu du fichier lu avec succès: $($content.Count) lignes"

    # Structure pour stocker les tâches
    $tasks = @{}
    $taskLines = @{}
    $lastIndentLevel = @{}
    $lastTaskId = @{}

    # Parcourir chaque ligne
    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]

        # Détecter les tâches avec le format "- [x] **ID** Description"
        if ($line -match '^\s*-\s+\[([ xX])\]\s+\*\*([0-9.]+)\*\*\s+(.+)$') {
            $status = if ($matches[1] -eq ' ') { $false } else { $true }
            $taskId = $matches[2]
            $description = $matches[3].Trim()

            # Calculer le niveau d'indentation
            $indentLevel = 0
            if ($line -match '^(\s*)') {
                $indentLevel = $matches[1].Length
            }

            # Stocker la tâche
            $tasks[$taskId] = @{
                Id          = $taskId
                Description = $description
                IsCompleted = $status
                IndentLevel = $indentLevel
                LineNumber  = $i
                Children    = @()
                Parent      = $null
            }

            $taskLines[$i] = $taskId

            # Trouver le parent
            for ($level = $indentLevel - 2; $level -ge 0; $level -= 2) {
                if ($lastIndentLevel.ContainsKey($level) -and $lastTaskId.ContainsKey($level)) {
                    $parentId = $lastTaskId[$level]
                    $tasks[$taskId].Parent = $parentId

                    # Ajouter l'enfant au parent
                    if (-not $tasks[$parentId].Children.Contains($taskId)) {
                        $tasks[$parentId].Children += $taskId
                    }

                    break
                }
            }

            # Mettre à jour le dernier ID à ce niveau
            $lastIndentLevel[$indentLevel] = $i
            $lastTaskId[$indentLevel] = $taskId
        }
    }

    return @{
        Tasks     = $tasks
        TaskLines = $taskLines
        Content   = $content
    }
}

# Fonction pour mettre à jour le statut des tâches parents
function Update-ParentStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks,

        [Parameter(Mandatory = $true)]
        [hashtable]$TaskLines,

        [Parameter(Mandatory = $true)]
        [string[]]$Content,

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    $updatedTasks = @()
    $updatedContent = $Content.Clone()

    # Parcourir toutes les tâches
    foreach ($taskId in $Tasks.Keys) {
        $task = $Tasks[$taskId]

        # Vérifier si la tâche a des enfants
        if ($task.Children.Count -gt 0) {
            $allChildrenCompleted = $true

            # Vérifier si tous les enfants sont complétés
            foreach ($childId in $task.Children) {
                if (-not $Tasks[$childId].IsCompleted) {
                    $allChildrenCompleted = $false
                    break
                }
            }

            # Si tous les enfants sont complétés mais la tâche parent ne l'est pas, mettre à jour le statut
            if ($allChildrenCompleted -and -not $task.IsCompleted) {
                $lineNumber = $task.LineNumber
                $line = $Content[$lineNumber]

                # Mettre à jour la ligne
                $updatedLine = $line -replace '\[ \]', '[x]'

                if (-not $WhatIf) {
                    $updatedContent[$lineNumber] = $updatedLine
                }

                $updatedTasks += @{
                    Id          = $taskId
                    Description = $task.Description
                    OldStatus   = "Incomplete"
                    NewStatus   = "Complete"
                    LineNumber  = $lineNumber
                    OldLine     = $line
                    NewLine     = $updatedLine
                }

                # Mettre à jour le statut dans la structure de données
                $Tasks[$taskId].IsCompleted = $true
            }
        }
    }

    return @{
        UpdatedTasks   = $updatedTasks
        UpdatedContent = $updatedContent
    }
}

# Fonction principale
function Update-ParentTaskStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$Force,

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )

    # Extraire la hiérarchie des tâches
    $hierarchy = Get-TaskHierarchy -FilePath $FilePath

    if (-not $hierarchy) {
        Write-Log "Impossible d'extraire la hiérarchie des tâches." -Level "Error"
        return $false
    }

    # Mettre à jour le statut des tâches parents
    $result = Update-ParentStatus -Tasks $hierarchy.Tasks -TaskLines $hierarchy.TaskLines -Content $hierarchy.Content -WhatIf:$WhatIf

    # Afficher les tâches mises à jour
    if ($result.UpdatedTasks.Count -gt 0) {
        Write-Log "$($result.UpdatedTasks.Count) tâche(s) parent(s) mise(s) à jour:" -Level "Success"

        foreach ($task in $result.UpdatedTasks) {
            Write-Log "  - Tâche $($task.Id): $($task.Description)" -Level "Success"
            Write-Log "    Ligne $($task.LineNumber): $($task.OldLine)" -Level "Info"
            Write-Log "    Nouvelle ligne: $($task.NewLine)" -Level "Info"
        }

        # Enregistrer les modifications
        if (-not $WhatIf) {
            $result.UpdatedContent | Out-File -FilePath $FilePath -Encoding UTF8
            Write-Log "Modifications enregistrées dans le fichier: $FilePath" -Level "Success"
        } else {
            Write-Log "Mode simulation: aucune modification n'a été enregistrée." -Level "Warning"
        }

        return $true
    } else {
        Write-Log "Aucune tâche parent à mettre à jour." -Level "Info"
        return $false
    }
}

# Exécuter la fonction principale
try {
    Write-Host "Démarrage du script..."
    Write-Host "Chemin du fichier: $RoadmapPath"

    # Vérifier si le fichier existe
    if (Test-Path $RoadmapPath) {
        Write-Host "Le fichier existe."
    } else {
        Write-Host "Le fichier n'existe pas!"
        Write-Host "Chemin absolu: $(Resolve-Path -Path $RoadmapPath -ErrorAction SilentlyContinue)"
        Write-Host "Répertoire courant: $(Get-Location)"
        exit 1
    }

    $result = Update-ParentTaskStatus -FilePath $RoadmapPath -Force:$Force -WhatIf:$WhatIf

    if ($result) {
        Write-Host "Mise à jour réussie."
        exit 0
    } else {
        Write-Host "Aucune mise à jour nécessaire."
        exit 1
    }
} catch {
    Write-Log "Erreur lors de la mise à jour des tâches parents: $_" -Level "Error"
    Write-Host "Erreur: $_"
    Write-Host "Trace de la pile: $($_.ScriptStackTrace)"
    exit 1
}

# Fix-ParentTaskStatus.ps1
# Script simple pour mettre à jour les tâches parents dont toutes les sous-tâches sont terminées
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\plans\plan-dev-v8-RAG-roadmap.md",

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Fonction pour afficher des messages
function Write-Message {
    param (
        [string]$Message,
        [string]$Color = "White"
    )

    Write-Host $Message -ForegroundColor $Color
}

# Vérifier si le fichier existe
Write-Message "Vérification du fichier: $RoadmapPath" -Color "Yellow"
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Message "Le fichier n'existe pas: $RoadmapPath" -Color "Red"
    exit 1
}
Write-Message "Le fichier existe." -Color "Green"

# Lire le contenu du fichier
try {
    $content = Get-Content -Path $RoadmapPath -Encoding UTF8 -ErrorAction Stop
    Write-Message "Fichier lu: $($content.Count) lignes" -Color "Green"
} catch {
    Write-Message "Erreur lors de la lecture du fichier: $_" -Color "Red"
    exit 1
}

# Extraire les tâches et leur statut
$tasks = @{}
$taskIndent = @{}
$taskLineNumbers = @{}

for ($i = 0; $i -lt $content.Count; $i++) {
    $line = $content[$i]

    # Détecter les tâches avec le format "- [x] **ID** Description"
    if ($line -match '^\s*-\s+\[([ xX])\]\s+\*\*([0-9.]+)\*\*\s+(.+)$') {
        $status = if ($matches[1] -eq ' ') { $false } else { $true }
        $taskId = $matches[2]
        $description = $matches[3].Trim()

        # Calculer l'indentation
        $indent = 0
        if ($line -match '^(\s*)') {
            $indent = $matches[1].Length
        }

        # Stocker les informations de la tâche
        $tasks[$taskId] = @{
            Id          = $taskId
            Description = $description
            IsCompleted = $status
            Indent      = $indent
            LineNumber  = $i
            Line        = $line
        }

        if (-not $taskIndent.ContainsKey($indent)) {
            $taskIndent[$indent] = @()
        }
        $taskIndent[$indent] += $taskId

        $taskLineNumbers[$i] = $taskId
    }
}

Write-Message "Tâches extraites: $($tasks.Count)" -Color "Green"

# Afficher quelques tâches pour vérification
$i = 0
foreach ($taskId in $tasks.Keys | Sort-Object) {
    if ($i -lt 5) {
        Write-Message "  Tâche $taskId : $($tasks[$taskId].Description) - Complétée: $($tasks[$taskId].IsCompleted)" -Color "Cyan"
    }
    $i++
}
if ($tasks.Count -gt 5) {
    Write-Message "  ... et $($tasks.Count - 5) autres tâches" -Color "Cyan"
}

# Identifier les relations parent-enfant
$parentChildRelations = @{}

foreach ($taskId in $tasks.Keys) {
    $task = $tasks[$taskId]
    $taskParts = $taskId -split '\.'

    if ($taskParts.Count -gt 1) {
        # Construire l'ID du parent
        $parentParts = $taskParts[0..($taskParts.Count - 2)]
        $parentId = $parentParts -join '.'

        # Vérifier si le parent existe
        if ($tasks.ContainsKey($parentId)) {
            if (-not $parentChildRelations.ContainsKey($parentId)) {
                $parentChildRelations[$parentId] = @()
            }
            $parentChildRelations[$parentId] += $taskId
        }
    }
}

Write-Message "Relations parent-enfant identifiées: $($parentChildRelations.Count) parents" -Color "Green"

# Afficher quelques relations parent-enfant pour vérification
$i = 0
foreach ($parentId in $parentChildRelations.Keys | Sort-Object) {
    if ($i -lt 3) {
        $childrenCount = $parentChildRelations[$parentId].Count
        Write-Message "  Parent $parentId : $childrenCount enfant(s)" -Color "Cyan"

        $j = 0
        foreach ($childId in $parentChildRelations[$parentId] | Sort-Object) {
            if ($j -lt 3) {
                Write-Message "    - Enfant $childId : $($tasks[$childId].Description) - Complété: $($tasks[$childId].IsCompleted)" -Color "Gray"
            }
            $j++
        }
        if ($childrenCount -gt 3) {
            Write-Message "    - ... et $($childrenCount - 3) autres enfants" -Color "Gray"
        }
    }
    $i++
}
if ($parentChildRelations.Count -gt 3) {
    Write-Message "  ... et $($parentChildRelations.Count - 3) autres parents" -Color "Cyan"
}

# Identifier les tâches parents à mettre à jour
$parentsToUpdate = @()

foreach ($parentId in $parentChildRelations.Keys) {
    $parent = $tasks[$parentId]
    $children = $parentChildRelations[$parentId]

    # Vérifier si le parent n'est pas déjà complété
    if (-not $parent.IsCompleted) {
        # Vérifier si tous les enfants sont complétés
        $allChildrenCompleted = $true

        foreach ($childId in $children) {
            if (-not $tasks[$childId].IsCompleted) {
                $allChildrenCompleted = $false
                break
            }
        }

        # Si tous les enfants sont complétés, ajouter le parent à la liste des tâches à mettre à jour
        if ($allChildrenCompleted) {
            $parentsToUpdate += $parentId
        }
    }
}

Write-Message "Tâches parents à mettre à jour: $($parentsToUpdate.Count)" -Color "Yellow"

# Afficher les tâches parents à mettre à jour
foreach ($parentId in $parentsToUpdate | Sort-Object) {
    Write-Message "  Parent $parentId : $($tasks[$parentId].Description)" -Color "Magenta"
    Write-Message "    - Ligne $($tasks[$parentId].LineNumber) : $($tasks[$parentId].Line)" -Color "Gray"

    # Afficher les enfants
    Write-Message "    - Enfants complétés:" -Color "Gray"
    foreach ($childId in $parentChildRelations[$parentId] | Sort-Object) {
        Write-Message "      - $childId : $($tasks[$childId].Description) - Complété: $($tasks[$childId].IsCompleted)" -Color "Gray"
    }
}

# Mettre à jour les tâches parents
$updatedContent = $content.Clone()
$updatedCount = 0

foreach ($parentId in $parentsToUpdate) {
    $parent = $tasks[$parentId]
    $lineNumber = $parent.LineNumber
    $line = $parent.Line

    # Mettre à jour la ligne
    $updatedLine = $line -replace '\[ \]', '[x]'

    Write-Message "Tâche $parentId : $($parent.Description)" -Color "Cyan"
    Write-Message "  Ligne $lineNumber : $line" -Color "Gray"
    Write-Message "  Nouvelle ligne : $updatedLine" -Color "Green"

    if (-not $WhatIf) {
        $updatedContent[$lineNumber] = $updatedLine
        $updatedCount++
    }
}

# Enregistrer les modifications
if ($updatedCount -gt 0 -and -not $WhatIf) {
    $updatedContent | Out-File -FilePath $RoadmapPath -Encoding UTF8
    Write-Message "$updatedCount tâche(s) parent(s) mise(s) à jour et enregistrée(s) dans le fichier." -Color "Green"
} elseif ($updatedCount -gt 0) {
    Write-Message "Mode simulation: $updatedCount tâche(s) parent(s) serai(en)t mise(s) à jour." -Color "Yellow"
} else {
    Write-Message "Aucune tâche parent à mettre à jour." -Color "Yellow"
}

exit 0

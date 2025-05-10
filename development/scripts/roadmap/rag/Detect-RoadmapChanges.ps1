# Detect-RoadmapChanges.ps1
# Script principal pour détecter les changements dans les roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OriginalPath,
    
    [Parameter(Mandatory = $false)]
    [string]$NewPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Json", "Markdown", "Html")]
    [string]$OutputFormat = "Json",
    
    [Parameter(Mandatory = $false)]
    [switch]$DetailedOutput,
    
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

# Importer les scripts de détection
$compareContentPath = Join-Path -Path $utilsPath -ChildPath "Compare-RoadmapContent.ps1"
$compareStructurePath = Join-Path -Path $utilsPath -ChildPath "Compare-RoadmapStructure.ps1"
$detectMovementsPath = Join-Path -Path $utilsPath -ChildPath "Detect-TaskMovements.ps1"

# Vérifier si les scripts existent
if (-not (Test-Path -Path $compareContentPath)) {
    Write-Log "Le script Compare-RoadmapContent.ps1 n'existe pas: $compareContentPath" -Level "Error"
    exit 1
}

if (-not (Test-Path -Path $compareStructurePath)) {
    Write-Log "Le script Compare-RoadmapStructure.ps1 n'existe pas: $compareStructurePath" -Level "Error"
    exit 1
}

if (-not (Test-Path -Path $detectMovementsPath)) {
    Write-Log "Le script Detect-TaskMovements.ps1 n'existe pas: $detectMovementsPath" -Level "Error"
    exit 1
}

# Fonction pour générer un rapport au format Markdown
function ConvertTo-MarkdownReport {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )
    
    $markdown = @"
# Rapport de détection des changements dans la roadmap

## Résumé

- **Fichier original**: $OriginalPath
- **Nouveau fichier**: $NewPath
- **Date d'analyse**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

"@
    
    # Ajouter le résumé des changements
    $markdown += @"

## Changements détectés

### Changements de contenu
- Tâches ajoutées: $($Results.ContentChanges.Changes.Added.Count)
- Tâches supprimées: $($Results.ContentChanges.Changes.Removed.Count)
- Tâches modifiées: $($Results.ContentChanges.Changes.Modified.Count)
- Statuts changés: $($Results.ContentChanges.Changes.StatusChanged.Count)
- Tâches déplacées: $($Results.ContentChanges.Changes.Moved.Count)
- Tâches inchangées: $($Results.ContentChanges.Changes.Unchanged.Count)

### Changements structurels
- En-têtes ajoutés: $($Results.StructuralChanges.Changes.AddedHeaders.Count)
- En-têtes supprimés: $($Results.StructuralChanges.Changes.RemovedHeaders.Count)
- En-têtes modifiés: $($Results.StructuralChanges.Changes.ModifiedHeaders.Count)
- Autres changements structurels: $($Results.StructuralChanges.Changes.StructuralChanges.Count)

### Mouvements de tâches
- Changements de contexte: $($Results.TaskMovements.Movements.ContextChanges.Count)
- Changements de parent: $($Results.TaskMovements.Movements.ParentChanges.Count)
- Changements d'indentation: $($Results.TaskMovements.Movements.IndentChanges.Count)
- Changements d'ordre: $($Results.TaskMovements.Movements.OrderChanges.Count)

"@
    
    # Ajouter les détails des changements si demandé
    if ($DetailedOutput) {
        $markdown += @"

## Détails des changements

### Tâches ajoutées
"@
        
        if ($Results.ContentChanges.Changes.Added.Count -gt 0) {
            $markdown += "`n"
            foreach ($task in $Results.ContentChanges.Changes.Added) {
                $markdown += "- **$($task.TaskId)**: $($task.Description)`n"
            }
        } else {
            $markdown += "`nAucune tâche ajoutée.`n"
        }
        
        $markdown += @"

### Tâches supprimées
"@
        
        if ($Results.ContentChanges.Changes.Removed.Count -gt 0) {
            $markdown += "`n"
            foreach ($task in $Results.ContentChanges.Changes.Removed) {
                $markdown += "- **$($task.TaskId)**: $($task.Description)`n"
            }
        } else {
            $markdown += "`nAucune tâche supprimée.`n"
        }
        
        $markdown += @"

### Statuts changés
"@
        
        if ($Results.ContentChanges.Changes.StatusChanged.Count -gt 0) {
            $markdown += "`n"
            foreach ($task in $Results.ContentChanges.Changes.StatusChanged) {
                $markdown += "- **$($task.TaskId)**: $($task.Description) ($($task.OldStatus) → $($task.NewStatus))`n"
            }
        } else {
            $markdown += "`nAucun statut changé.`n"
        }
        
        $markdown += @"

### Mouvements de tâches
"@
        
        if ($Results.TaskMovements.HasMovements) {
            $markdown += "`n"
            
            if ($Results.TaskMovements.Movements.ContextChanges.Count -gt 0) {
                $markdown += "#### Changements de contexte`n`n"
                foreach ($change in $Results.TaskMovements.Movements.ContextChanges) {
                    $markdown += "- **$($change.TaskId)**: $($change.Description)`n"
                    $markdown += "  - De: $($change.OldContext)`n"
                    $markdown += "  - À: $($change.NewContext)`n`n"
                }
            }
            
            if ($Results.TaskMovements.Movements.ParentChanges.Count -gt 0) {
                $markdown += "#### Changements de parent`n`n"
                foreach ($change in $Results.TaskMovements.Movements.ParentChanges) {
                    $markdown += "- **$($change.TaskId)**: $($change.Description)`n"
                    $markdown += "  - De: $($change.OldParentId) ($($change.OldParentDescription))`n"
                    $markdown += "  - À: $($change.NewParentId) ($($change.NewParentDescription))`n`n"
                }
            }
        } else {
            $markdown += "`nAucun mouvement de tâche détecté.`n"
        }
    }
    
    return $markdown
}

# Fonction pour générer un rapport au format HTML
function ConvertTo-HtmlReport {
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Results
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de détection des changements</title>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; margin: 0; padding: 20px; color: #333; }
        h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 10px; }
        h2 { color: #2980b9; margin-top: 20px; }
        h3 { color: #3498db; }
        h4 { color: #2c3e50; }
        .summary { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin-bottom: 20px; }
        .changes { margin-bottom: 30px; }
        .task-list { margin-left: 20px; }
        .task-item { margin-bottom: 10px; }
        .task-id { font-weight: bold; color: #2c3e50; }
        .status-change { color: #e74c3c; }
        .added { color: #27ae60; }
        .removed { color: #c0392b; }
        .modified { color: #f39c12; }
        .unchanged { color: #7f8c8d; }
    </style>
</head>
<body>
    <h1>Rapport de détection des changements dans la roadmap</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p><strong>Fichier original</strong>: $OriginalPath</p>
        <p><strong>Nouveau fichier</strong>: $NewPath</p>
        <p><strong>Date d'analyse</strong>: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>
    
    <div class="changes">
        <h2>Changements détectés</h2>
        
        <h3>Changements de contenu</h3>
        <ul>
            <li class="added">Tâches ajoutées: $($Results.ContentChanges.Changes.Added.Count)</li>
            <li class="removed">Tâches supprimées: $($Results.ContentChanges.Changes.Removed.Count)</li>
            <li class="modified">Tâches modifiées: $($Results.ContentChanges.Changes.Modified.Count)</li>
            <li class="status-change">Statuts changés: $($Results.ContentChanges.Changes.StatusChanged.Count)</li>
            <li>Tâches déplacées: $($Results.ContentChanges.Changes.Moved.Count)</li>
            <li class="unchanged">Tâches inchangées: $($Results.ContentChanges.Changes.Unchanged.Count)</li>
        </ul>
        
        <h3>Changements structurels</h3>
        <ul>
            <li class="added">En-têtes ajoutés: $($Results.StructuralChanges.Changes.AddedHeaders.Count)</li>
            <li class="removed">En-têtes supprimés: $($Results.StructuralChanges.Changes.RemovedHeaders.Count)</li>
            <li class="modified">En-têtes modifiés: $($Results.StructuralChanges.Changes.ModifiedHeaders.Count)</li>
            <li>Autres changements structurels: $($Results.StructuralChanges.Changes.StructuralChanges.Count)</li>
        </ul>
        
        <h3>Mouvements de tâches</h3>
        <ul>
            <li>Changements de contexte: $($Results.TaskMovements.Movements.ContextChanges.Count)</li>
            <li>Changements de parent: $($Results.TaskMovements.Movements.ParentChanges.Count)</li>
            <li>Changements d'indentation: $($Results.TaskMovements.Movements.IndentChanges.Count)</li>
            <li>Changements d'ordre: $($Results.TaskMovements.Movements.OrderChanges.Count)</li>
        </ul>
    </div>
"@
    
    # Ajouter les détails des changements si demandé
    if ($DetailedOutput) {
        $html += @"
    <div class="details">
        <h2>Détails des changements</h2>
        
        <h3>Tâches ajoutées</h3>
"@
        
        if ($Results.ContentChanges.Changes.Added.Count -gt 0) {
            $html += @"
        <div class="task-list">
"@
            foreach ($task in $Results.ContentChanges.Changes.Added) {
                $html += @"
            <div class="task-item added">
                <span class="task-id">$($task.TaskId)</span>: $($task.Description)
            </div>
"@
            }
            $html += @"
        </div>
"@
        } else {
            $html += @"
        <p>Aucune tâche ajoutée.</p>
"@
        }
        
        $html += @"
        
        <h3>Tâches supprimées</h3>
"@
        
        if ($Results.ContentChanges.Changes.Removed.Count -gt 0) {
            $html += @"
        <div class="task-list">
"@
            foreach ($task in $Results.ContentChanges.Changes.Removed) {
                $html += @"
            <div class="task-item removed">
                <span class="task-id">$($task.TaskId)</span>: $($task.Description)
            </div>
"@
            }
            $html += @"
        </div>
"@
        } else {
            $html += @"
        <p>Aucune tâche supprimée.</p>
"@
        }
        
        $html += @"
        
        <h3>Statuts changés</h3>
"@
        
        if ($Results.ContentChanges.Changes.StatusChanged.Count -gt 0) {
            $html += @"
        <div class="task-list">
"@
            foreach ($task in $Results.ContentChanges.Changes.StatusChanged) {
                $html += @"
            <div class="task-item status-change">
                <span class="task-id">$($task.TaskId)</span>: $($task.Description) ($($task.OldStatus) → $($task.NewStatus))
            </div>
"@
            }
            $html += @"
        </div>
"@
        } else {
            $html += @"
        <p>Aucun statut changé.</p>
"@
        }
        
        $html += @"
        
        <h3>Mouvements de tâches</h3>
"@
        
        if ($Results.TaskMovements.HasMovements) {
            if ($Results.TaskMovements.Movements.ContextChanges.Count -gt 0) {
                $html += @"
        <h4>Changements de contexte</h4>
        <div class="task-list">
"@
                foreach ($change in $Results.TaskMovements.Movements.ContextChanges) {
                    $html += @"
            <div class="task-item">
                <span class="task-id">$($change.TaskId)</span>: $($change.Description)
                <ul>
                    <li>De: $($change.OldContext)</li>
                    <li>À: $($change.NewContext)</li>
                </ul>
            </div>
"@
                }
                $html += @"
        </div>
"@
            }
            
            if ($Results.TaskMovements.Movements.ParentChanges.Count -gt 0) {
                $html += @"
        <h4>Changements de parent</h4>
        <div class="task-list">
"@
                foreach ($change in $Results.TaskMovements.Movements.ParentChanges) {
                    $html += @"
            <div class="task-item">
                <span class="task-id">$($change.TaskId)</span>: $($change.Description)
                <ul>
                    <li>De: $($change.OldParentId) ($($change.OldParentDescription))</li>
                    <li>À: $($change.NewParentId) ($($change.NewParentDescription))</li>
                </ul>
            </div>
"@
                }
                $html += @"
        </div>
"@
            }
        } else {
            $html += @"
        <p>Aucun mouvement de tâche détecté.</p>
"@
        }
        
        $html += @"
    </div>
"@
    }
    
    $html += @"
</body>
</html>
"@
    
    return $html
}

# Fonction principale
function Detect-RoadmapChanges {
    param (
        [Parameter(Mandatory = $true)]
        [string]$OriginalPath,
        
        [Parameter(Mandatory = $true)]
        [string]$NewPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFormat = "Json",
        
        [Parameter(Mandatory = $false)]
        [switch]$DetailedOutput,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si les fichiers existent
    if (-not (Test-Path -Path $OriginalPath)) {
        Write-Log "Le fichier original n'existe pas: $OriginalPath" -Level "Error"
        return $false
    }
    
    if (-not (Test-Path -Path $NewPath)) {
        Write-Log "Le nouveau fichier n'existe pas: $NewPath" -Level "Error"
        return $false
    }
    
    # Vérifier si le fichier de sortie existe déjà
    if ($OutputPath -and (Test-Path -Path $OutputPath) -and -not $Force) {
        Write-Log "Le fichier de sortie existe déjà: $OutputPath. Utilisez -Force pour l'écraser." -Level "Error"
        return $false
    }
    
    # Charger le contenu des fichiers
    $originalContent = Get-Content -Path $OriginalPath -Raw
    $newContent = Get-Content -Path $NewPath -Raw
    
    # Détecter les changements de contenu
    Write-Log "Détection des changements de contenu..." -Level "Info"
    $contentChanges = & $compareContentPath -OriginalContent $originalContent -NewContent $newContent -DetailedOutput:$DetailedOutput
    
    # Détecter les changements structurels
    Write-Log "Détection des changements structurels..." -Level "Info"
    $structuralChanges = & $compareStructurePath -OriginalContent $originalContent -NewContent $newContent -DetailedOutput:$DetailedOutput
    
    # Détecter les mouvements de tâches
    Write-Log "Détection des mouvements de tâches..." -Level "Info"
    $taskMovements = & $detectMovementsPath -OriginalContent $originalContent -NewContent $newContent -DetailedOutput:$DetailedOutput
    
    # Combiner les résultats
    $results = @{
        ContentChanges = $contentChanges
        StructuralChanges = $structuralChanges
        TaskMovements = $taskMovements
        HasChanges = $contentChanges.HasChanges -or $structuralChanges.HasStructuralChanges -or $taskMovements.HasMovements
        AnalysisTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        OriginalPath = $OriginalPath
        NewPath = $NewPath
    }
    
    # Enregistrer les résultats si demandé
    if ($OutputPath) {
        $outputDir = Split-Path -Parent $OutputPath
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        switch ($OutputFormat) {
            "Json" {
                $results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
            }
            "Markdown" {
                $markdown = ConvertTo-MarkdownReport -Results $results
                $markdown | Set-Content -Path $OutputPath -Encoding UTF8
            }
            "Html" {
                $html = ConvertTo-HtmlReport -Results $results
                $html | Set-Content -Path $OutputPath -Encoding UTF8
            }
        }
        
        Write-Log "Résultats enregistrés dans $OutputPath" -Level "Info"
    }
    
    # Afficher un résumé des changements
    if ($results.HasChanges) {
        Write-Log "Changements détectés:" -Level "Info"
        Write-Log "  - Changements de contenu: $($contentChanges.HasChanges)" -Level "Info"
        Write-Log "  - Changements structurels: $($structuralChanges.HasStructuralChanges)" -Level "Info"
        Write-Log "  - Mouvements de tâches: $($taskMovements.HasMovements)" -Level "Info"
    } else {
        Write-Log "Aucun changement détecté" -Level "Info"
    }
    
    return $results
}

# Exécuter la fonction principale
Detect-RoadmapChanges -OriginalPath $OriginalPath -NewPath $NewPath -OutputPath $OutputPath -OutputFormat $OutputFormat -DetailedOutput:$DetailedOutput -Force:$Force

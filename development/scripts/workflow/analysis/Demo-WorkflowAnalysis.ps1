# Script de démonstration pour l'analyse des workflows n8n
# Ce script montre comment utiliser le module WorkflowAnalyzer pour les trois tâches demandées

#Requires -Version 5.1

<#
.SYNOPSIS
    Démontre l'utilisation du module WorkflowAnalyzer pour les trois tâches demandées.

.DESCRIPTION
    Ce script montre comment utiliser le module WorkflowAnalyzer pour :
    1. Détecter les activités de workflow
    2. Extraire les transitions de workflow
    3. Analyser les conditions de workflow

.PARAMETER WorkflowPath
    Chemin du fichier de workflow n8n à analyser.

.PARAMETER OutputFolder
    Dossier où enregistrer les rapports d'analyse.

.EXAMPLE
    .\Demo-WorkflowAnalysis.ps1 -WorkflowPath "path\to\workflow.json" -OutputFolder "path\to\reports"
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$WorkflowPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = (Join-Path -Path $PSScriptRoot -ChildPath "reports")
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "WorkflowAnalyzer.psm1"
Import-Module $modulePath -Force

# Fonction pour afficher un message
function Write-DemoMessage {
    param (
        [string]$Message,
        [string]$Status = "INFO"
    )
    
    $color = switch ($Status) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "TASK" { "Magenta" }
        default { "White" }
    }
    
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

# Si aucun chemin de workflow n'est spécifié, demander à l'utilisateur
if (-not $WorkflowPath) {
    Write-DemoMessage "Veuillez spécifier le chemin d'un fichier de workflow n8n à analyser:"
    $WorkflowPath = Read-Host
}

# Vérifier si le fichier de workflow existe
if (-not (Test-Path -Path $WorkflowPath)) {
    Write-DemoMessage "Le fichier de workflow n'existe pas: $WorkflowPath" -Status "ERROR"
    exit 1
}

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# Charger le workflow
Write-DemoMessage "Chargement du workflow: $WorkflowPath"
$workflow = Get-N8nWorkflow -WorkflowPath $WorkflowPath

if (-not $workflow) {
    Write-DemoMessage "Échec du chargement du workflow" -Status "ERROR"
    exit 1
}

Write-DemoMessage "Workflow chargé avec succès: $($workflow.name)" -Status "SUCCESS"
Write-DemoMessage "Nombre de nœuds: $($workflow.nodes.Count)"
Write-DemoMessage "Workflow actif: $($workflow.active)"

# Tâche 1: Détecter les activités de workflow
Write-DemoMessage "TÂCHE 1: DÉTECTER LES ACTIVITÉS DE WORKFLOW" -Status "TASK"
Write-DemoMessage "Cette tâche identifie tous les nœuds du workflow et les catégorise par type et fonction."

$activities = Get-N8nWorkflowActivities -Workflow $workflow -IncludeDetails

if ($activities) {
    Write-DemoMessage "Activités détectées avec succès: $($activities.Count) activités trouvées" -Status "SUCCESS"
    
    # Afficher les activités par catégorie
    $categorizedActivities = $activities | Group-Object -Property Category
    
    foreach ($category in $categorizedActivities) {
        Write-DemoMessage "Catégorie: $($category.Name) ($($category.Count) activités)" -Status "INFO"
        
        foreach ($activity in $category.Group) {
            Write-Host "  - $($activity.Name) (Type: $($activity.Type))"
        }
        
        Write-Host ""
    }
    
    # Enregistrer les activités dans un fichier Markdown
    $activitiesOutputPath = Join-Path -Path $OutputFolder -ChildPath "workflow_activities.md"
    
    $markdown = "# Activités du workflow: $($workflow.name)`n`n"
    
    foreach ($category in $categorizedActivities) {
        $markdown += "## Catégorie: $($category.Name)`n`n"
        $markdown += "| ID | Nom | Type |`n"
        $markdown += "|----|-----|------|`n"
        
        foreach ($activity in $category.Group) {
            $markdown += "| $($activity.Id) | $($activity.Name) | $($activity.Type) |`n"
        }
        
        $markdown += "`n"
    }
    
    $markdown | Out-File -FilePath $activitiesOutputPath -Encoding UTF8
    Write-DemoMessage "Activités enregistrées dans: $activitiesOutputPath" -Status "SUCCESS"
}
else {
    Write-DemoMessage "Échec de la détection des activités" -Status "ERROR"
}

# Tâche 2: Extraire les transitions de workflow
Write-DemoMessage "TÂCHE 2: EXTRAIRE LES TRANSITIONS DE WORKFLOW" -Status "TASK"
Write-DemoMessage "Cette tâche identifie toutes les connexions entre les nœuds du workflow et les chemins de transition."

$transitions = Get-N8nWorkflowTransitions -Workflow $workflow

if ($transitions) {
    Write-DemoMessage "Transitions extraites avec succès: $($transitions.Count) transitions trouvées" -Status "SUCCESS"
    
    # Afficher les transitions
    Write-DemoMessage "Chemins de transition:"
    
    foreach ($transition in $transitions) {
        Write-Host "  - $($transition.SourceNodeName) -> $($transition.TargetNodeName)"
    }
    
    Write-Host ""
    
    # Identifier les points de branchement (nœuds avec plusieurs sorties)
    $branchingPoints = $transitions | Group-Object -Property SourceNodeId | Where-Object { $_.Count -gt 1 }
    
    if ($branchingPoints) {
        Write-DemoMessage "Points de branchement identifiés: $($branchingPoints.Count) nœuds" -Status "INFO"
        
        foreach ($point in $branchingPoints) {
            $sourceName = ($point.Group | Select-Object -First 1).SourceNodeName
            Write-Host "  - $sourceName (ID: $($point.Name)) -> $($point.Count) chemins"
            
            foreach ($transition in $point.Group) {
                Write-Host "    - Vers: $($transition.TargetNodeName) (Index: $($transition.OutputIndex))"
            }
            
            Write-Host ""
        }
    }
    else {
        Write-DemoMessage "Aucun point de branchement identifié" -Status "INFO"
    }
    
    # Identifier les points de fusion (nœuds avec plusieurs entrées)
    $mergingPoints = $transitions | Group-Object -Property TargetNodeId | Where-Object { $_.Count -gt 1 }
    
    if ($mergingPoints) {
        Write-DemoMessage "Points de fusion identifiés: $($mergingPoints.Count) nœuds" -Status "INFO"
        
        foreach ($point in $mergingPoints) {
            $targetName = ($point.Group | Select-Object -First 1).TargetNodeName
            Write-Host "  - $targetName (ID: $($point.Name)) <- $($point.Count) chemins"
            
            foreach ($transition in $point.Group) {
                Write-Host "    - Depuis: $($transition.SourceNodeName)"
            }
            
            Write-Host ""
        }
    }
    else {
        Write-DemoMessage "Aucun point de fusion identifié" -Status "INFO"
    }
    
    # Enregistrer les transitions dans un fichier Markdown
    $transitionsOutputPath = Join-Path -Path $OutputFolder -ChildPath "workflow_transitions.md"
    
    $markdown = "# Transitions du workflow: $($workflow.name)`n`n"
    $markdown += "## Chemins de transition`n`n"
    $markdown += "| Source | Destination | Index |`n"
    $markdown += "|--------|-------------|-------|`n"
    
    foreach ($transition in $transitions) {
        $markdown += "| $($transition.SourceNodeName) | $($transition.TargetNodeName) | $($transition.OutputIndex) |`n"
    }
    
    if ($branchingPoints) {
        $markdown += "`n## Points de branchement`n`n"
        
        foreach ($point in $branchingPoints) {
            $sourceName = ($point.Group | Select-Object -First 1).SourceNodeName
            $markdown += "### $sourceName (ID: $($point.Name))`n`n"
            $markdown += "| Destination | Index |`n"
            $markdown += "|-------------|-------|`n"
            
            foreach ($transition in $point.Group) {
                $markdown += "| $($transition.TargetNodeName) | $($transition.OutputIndex) |`n"
            }
            
            $markdown += "`n"
        }
    }
    
    if ($mergingPoints) {
        $markdown += "`n## Points de fusion`n`n"
        
        foreach ($point in $mergingPoints) {
            $targetName = ($point.Group | Select-Object -First 1).TargetNodeName
            $markdown += "### $targetName (ID: $($point.Name))`n`n"
            $markdown += "| Source |`n"
            $markdown += "|--------|`n"
            
            foreach ($transition in $point.Group) {
                $markdown += "| $($transition.SourceNodeName) |`n"
            }
            
            $markdown += "`n"
        }
    }
    
    $markdown | Out-File -FilePath $transitionsOutputPath -Encoding UTF8
    Write-DemoMessage "Transitions enregistrées dans: $transitionsOutputPath" -Status "SUCCESS"
}
else {
    Write-DemoMessage "Échec de l'extraction des transitions" -Status "ERROR"
}

# Tâche 3: Analyser les conditions de workflow
Write-DemoMessage "TÂCHE 3: ANALYSER LES CONDITIONS DE WORKFLOW" -Status "TASK"
Write-DemoMessage "Cette tâche identifie et analyse les nœuds conditionnels (IF, Switch) et leurs expressions de condition."

$conditions = Get-N8nWorkflowConditions -Workflow $workflow -IncludeTransitions

if ($conditions -ne $null) {
    if ($conditions.Count -eq 0) {
        Write-DemoMessage "Aucun nœud conditionnel trouvé dans le workflow" -Status "WARNING"
    }
    else {
        Write-DemoMessage "Conditions analysées avec succès: $($conditions.Count) nœuds conditionnels trouvés" -Status "SUCCESS"
        
        # Afficher les conditions
        foreach ($condition in $conditions) {
            Write-DemoMessage "Nœud conditionnel: $($condition.Name) (Type: $($condition.Type))" -Status "INFO"
            
            Write-Host "  Conditions:"
            foreach ($cond in $condition.Conditions) {
                Write-Host "  - $($cond.Type): $($cond.Value1) $($cond.Operation) $($cond.Value2)"
            }
            
            if ($condition.Transitions) {
                Write-Host "  Transitions:"
                foreach ($transition in $condition.Transitions) {
                    Write-Host "  - $($transition.OutputLabel) -> $($transition.TargetNodeName)"
                }
            }
            
            Write-Host ""
        }
        
        # Enregistrer les conditions dans un fichier Markdown
        $conditionsOutputPath = Join-Path -Path $OutputFolder -ChildPath "workflow_conditions.md"
        
        $markdown = "# Conditions du workflow: $($workflow.name)`n`n"
        
        foreach ($condition in $conditions) {
            $markdown += "## $($condition.Name)`n`n"
            $markdown += "- **Type**: $($condition.Type)`n"
            $markdown += "- **Conditions**:`n`n"
            
            $markdown += "| Type | Valeur 1 | Opération | Valeur 2 |`n"
            $markdown += "|------|----------|-----------|----------|`n"
            foreach ($cond in $condition.Conditions) {
                $markdown += "| $($cond.Type) | $($cond.Value1) | $($cond.Operation) | $($cond.Value2) |`n"
            }
            
            if ($condition.Transitions) {
                $markdown += "`n- **Transitions**:`n`n"
                $markdown += "| Sortie | Label | Destination |`n"
                $markdown += "|--------|-------|-------------|`n"
                foreach ($transition in $condition.Transitions) {
                    $markdown += "| $($transition.OutputIndex) | $($transition.OutputLabel) | $($transition.TargetNodeName) |`n"
                }
            }
            
            $markdown += "`n"
        }
        
        $markdown | Out-File -FilePath $conditionsOutputPath -Encoding UTF8
        Write-DemoMessage "Conditions enregistrées dans: $conditionsOutputPath" -Status "SUCCESS"
    }
}
else {
    Write-DemoMessage "Échec de l'analyse des conditions" -Status "ERROR"
}

# Générer un rapport complet
$reportOutputPath = Join-Path -Path $OutputFolder -ChildPath "workflow_analysis_report.md"
$report = Get-N8nWorkflowAnalysisReport -WorkflowPath $WorkflowPath -OutputPath $reportOutputPath -Format "Markdown"

if ($report) {
    Write-DemoMessage "Rapport complet généré avec succès: $reportOutputPath" -Status "SUCCESS"
    Write-DemoMessage "Vous pouvez consulter ce rapport pour une vue d'ensemble de l'analyse du workflow."
}
else {
    Write-DemoMessage "Échec de la génération du rapport complet" -Status "ERROR"
}

Write-DemoMessage "Démonstration terminée. Les résultats ont été enregistrés dans le dossier: $OutputFolder" -Status "SUCCESS"

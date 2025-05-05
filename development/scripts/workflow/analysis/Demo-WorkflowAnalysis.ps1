# Script de dÃ©monstration pour l'analyse des workflows n8n
# Ce script montre comment utiliser le module WorkflowAnalyzer pour les trois tÃ¢ches demandÃ©es

#Requires -Version 5.1

<#
.SYNOPSIS
    DÃ©montre l'utilisation du module WorkflowAnalyzer pour les trois tÃ¢ches demandÃ©es.

.DESCRIPTION
    Ce script montre comment utiliser le module WorkflowAnalyzer pour :
    1. DÃ©tecter les activitÃ©s de workflow
    2. Extraire les transitions de workflow
    3. Analyser les conditions de workflow

.PARAMETER WorkflowPath
    Chemin du fichier de workflow n8n Ã  analyser.

.PARAMETER OutputFolder
    Dossier oÃ¹ enregistrer les rapports d'analyse.

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

# Si aucun chemin de workflow n'est spÃ©cifiÃ©, demander Ã  l'utilisateur
if (-not $WorkflowPath) {
    Write-DemoMessage "Veuillez spÃ©cifier le chemin d'un fichier de workflow n8n Ã  analyser:"
    $WorkflowPath = Read-Host
}

# VÃ©rifier si le fichier de workflow existe
if (-not (Test-Path -Path $WorkflowPath)) {
    Write-DemoMessage "Le fichier de workflow n'existe pas: $WorkflowPath" -Status "ERROR"
    exit 1
}

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# Charger le workflow
Write-DemoMessage "Chargement du workflow: $WorkflowPath"
$workflow = Get-N8nWorkflow -WorkflowPath $WorkflowPath

if (-not $workflow) {
    Write-DemoMessage "Ã‰chec du chargement du workflow" -Status "ERROR"
    exit 1
}

Write-DemoMessage "Workflow chargÃ© avec succÃ¨s: $($workflow.name)" -Status "SUCCESS"
Write-DemoMessage "Nombre de nÅ“uds: $($workflow.nodes.Count)"
Write-DemoMessage "Workflow actif: $($workflow.active)"

# TÃ¢che 1: DÃ©tecter les activitÃ©s de workflow
Write-DemoMessage "TÃ‚CHE 1: DÃ‰TECTER LES ACTIVITÃ‰S DE WORKFLOW" -Status "TASK"
Write-DemoMessage "Cette tÃ¢che identifie tous les nÅ“uds du workflow et les catÃ©gorise par type et fonction."

$activities = Get-N8nWorkflowActivities -Workflow $workflow -IncludeDetails

if ($activities) {
    Write-DemoMessage "ActivitÃ©s dÃ©tectÃ©es avec succÃ¨s: $($activities.Count) activitÃ©s trouvÃ©es" -Status "SUCCESS"
    
    # Afficher les activitÃ©s par catÃ©gorie
    $categorizedActivities = $activities | Group-Object -Property Category
    
    foreach ($category in $categorizedActivities) {
        Write-DemoMessage "CatÃ©gorie: $($category.Name) ($($category.Count) activitÃ©s)" -Status "INFO"
        
        foreach ($activity in $category.Group) {
            Write-Host "  - $($activity.Name) (Type: $($activity.Type))"
        }
        
        Write-Host ""
    }
    
    # Enregistrer les activitÃ©s dans un fichier Markdown
    $activitiesOutputPath = Join-Path -Path $OutputFolder -ChildPath "workflow_activities.md"
    
    $markdown = "# ActivitÃ©s du workflow: $($workflow.name)`n`n"
    
    foreach ($category in $categorizedActivities) {
        $markdown += "## CatÃ©gorie: $($category.Name)`n`n"
        $markdown += "| ID | Nom | Type |`n"
        $markdown += "|----|-----|------|`n"
        
        foreach ($activity in $category.Group) {
            $markdown += "| $($activity.Id) | $($activity.Name) | $($activity.Type) |`n"
        }
        
        $markdown += "`n"
    }
    
    $markdown | Out-File -FilePath $activitiesOutputPath -Encoding UTF8
    Write-DemoMessage "ActivitÃ©s enregistrÃ©es dans: $activitiesOutputPath" -Status "SUCCESS"
}
else {
    Write-DemoMessage "Ã‰chec de la dÃ©tection des activitÃ©s" -Status "ERROR"
}

# TÃ¢che 2: Extraire les transitions de workflow
Write-DemoMessage "TÃ‚CHE 2: EXTRAIRE LES TRANSITIONS DE WORKFLOW" -Status "TASK"
Write-DemoMessage "Cette tÃ¢che identifie toutes les connexions entre les nÅ“uds du workflow et les chemins de transition."

$transitions = Get-N8nWorkflowTransitions -Workflow $workflow

if ($transitions) {
    Write-DemoMessage "Transitions extraites avec succÃ¨s: $($transitions.Count) transitions trouvÃ©es" -Status "SUCCESS"
    
    # Afficher les transitions
    Write-DemoMessage "Chemins de transition:"
    
    foreach ($transition in $transitions) {
        Write-Host "  - $($transition.SourceNodeName) -> $($transition.TargetNodeName)"
    }
    
    Write-Host ""
    
    # Identifier les points de branchement (nÅ“uds avec plusieurs sorties)
    $branchingPoints = $transitions | Group-Object -Property SourceNodeId | Where-Object { $_.Count -gt 1 }
    
    if ($branchingPoints) {
        Write-DemoMessage "Points de branchement identifiÃ©s: $($branchingPoints.Count) nÅ“uds" -Status "INFO"
        
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
        Write-DemoMessage "Aucun point de branchement identifiÃ©" -Status "INFO"
    }
    
    # Identifier les points de fusion (nÅ“uds avec plusieurs entrÃ©es)
    $mergingPoints = $transitions | Group-Object -Property TargetNodeId | Where-Object { $_.Count -gt 1 }
    
    if ($mergingPoints) {
        Write-DemoMessage "Points de fusion identifiÃ©s: $($mergingPoints.Count) nÅ“uds" -Status "INFO"
        
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
        Write-DemoMessage "Aucun point de fusion identifiÃ©" -Status "INFO"
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
    Write-DemoMessage "Transitions enregistrÃ©es dans: $transitionsOutputPath" -Status "SUCCESS"
}
else {
    Write-DemoMessage "Ã‰chec de l'extraction des transitions" -Status "ERROR"
}

# TÃ¢che 3: Analyser les conditions de workflow
Write-DemoMessage "TÃ‚CHE 3: ANALYSER LES CONDITIONS DE WORKFLOW" -Status "TASK"
Write-DemoMessage "Cette tÃ¢che identifie et analyse les nÅ“uds conditionnels (IF, Switch) et leurs expressions de condition."

$conditions = Get-N8nWorkflowConditions -Workflow $workflow -IncludeTransitions

if ($conditions -ne $null) {
    if ($conditions.Count -eq 0) {
        Write-DemoMessage "Aucun nÅ“ud conditionnel trouvÃ© dans le workflow" -Status "WARNING"
    }
    else {
        Write-DemoMessage "Conditions analysÃ©es avec succÃ¨s: $($conditions.Count) nÅ“uds conditionnels trouvÃ©s" -Status "SUCCESS"
        
        # Afficher les conditions
        foreach ($condition in $conditions) {
            Write-DemoMessage "NÅ“ud conditionnel: $($condition.Name) (Type: $($condition.Type))" -Status "INFO"
            
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
            
            $markdown += "| Type | Valeur 1 | OpÃ©ration | Valeur 2 |`n"
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
        Write-DemoMessage "Conditions enregistrÃ©es dans: $conditionsOutputPath" -Status "SUCCESS"
    }
}
else {
    Write-DemoMessage "Ã‰chec de l'analyse des conditions" -Status "ERROR"
}

# GÃ©nÃ©rer un rapport complet
$reportOutputPath = Join-Path -Path $OutputFolder -ChildPath "workflow_analysis_report.md"
$report = Get-N8nWorkflowAnalysisReport -WorkflowPath $WorkflowPath -OutputPath $reportOutputPath -Format "Markdown"

if ($report) {
    Write-DemoMessage "Rapport complet gÃ©nÃ©rÃ© avec succÃ¨s: $reportOutputPath" -Status "SUCCESS"
    Write-DemoMessage "Vous pouvez consulter ce rapport pour une vue d'ensemble de l'analyse du workflow."
}
else {
    Write-DemoMessage "Ã‰chec de la gÃ©nÃ©ration du rapport complet" -Status "ERROR"
}

Write-DemoMessage "DÃ©monstration terminÃ©e. Les rÃ©sultats ont Ã©tÃ© enregistrÃ©s dans le dossier: $OutputFolder" -Status "SUCCESS"

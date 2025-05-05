# Script d'analyse des workflows n8n
# Ce script utilise le module WorkflowAnalyzer pour analyser les workflows n8n

#Requires -Version 5.1

<#
.SYNOPSIS
    Analyse les workflows n8n pour dÃ©tecter les activitÃ©s, extraire les transitions et analyser les conditions.

.DESCRIPTION
    Ce script utilise le module WorkflowAnalyzer pour analyser les workflows n8n.
    Il permet de dÃ©tecter les activitÃ©s, extraire les transitions et analyser les conditions des workflows.
    Les rÃ©sultats peuvent Ãªtre exportÃ©s dans diffÃ©rents formats (Markdown, JSON, HTML, Text).

.PARAMETER WorkflowPath
    Chemin du fichier de workflow n8n Ã  analyser.

.PARAMETER OutputFolder
    Dossier oÃ¹ enregistrer les rapports d'analyse.

.PARAMETER Format
    Format des rapports d'analyse (Markdown, JSON, HTML, Text).

.PARAMETER ActivitiesOnly
    Indique si seules les activitÃ©s doivent Ãªtre analysÃ©es.

.PARAMETER TransitionsOnly
    Indique si seules les transitions doivent Ãªtre analysÃ©es.

.PARAMETER ConditionsOnly
    Indique si seules les conditions doivent Ãªtre analysÃ©es.

.PARAMETER IncludeDetails
    Indique si les dÃ©tails des nÅ“uds doivent Ãªtre inclus dans les rÃ©sultats.

.EXAMPLE
    .\Analyze-N8nWorkflow.ps1 -WorkflowPath "path\to\workflow.json" -OutputFolder "path\to\reports"

.EXAMPLE
    .\Analyze-N8nWorkflow.ps1 -WorkflowPath "path\to\workflow.json" -ActivitiesOnly -Format "JSON"

.EXAMPLE
    .\Analyze-N8nWorkflow.ps1 -WorkflowPath "path\to\workflow.json" -TransitionsOnly -ConditionsOnly
#>

param (
    [Parameter(Mandatory = $true)]
    [string]$WorkflowPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = (Join-Path -Path $PSScriptRoot -ChildPath "reports"),
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Markdown", "JSON", "HTML", "Text")]
    [string]$Format = "Markdown",
    
    [Parameter(Mandatory = $false)]
    [switch]$ActivitiesOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$TransitionsOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$ConditionsOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeDetails
)

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "WorkflowAnalyzer.psm1"
Import-Module $modulePath -Force

# Fonction pour afficher un message
function Write-Message {
    param (
        [string]$Message,
        [string]$Status = "INFO"
    )
    
    $color = switch ($Status) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    
    Write-Host "[$Status] $Message" -ForegroundColor $color
}

# VÃ©rifier si le fichier de workflow existe
if (-not (Test-Path -Path $WorkflowPath)) {
    Write-Message "Le fichier de workflow n'existe pas: $WorkflowPath" -Status "ERROR"
    exit 1
}

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# Charger le workflow
Write-Message "Chargement du workflow: $WorkflowPath"
$workflow = Get-N8nWorkflow -WorkflowPath $WorkflowPath

if (-not $workflow) {
    Write-Message "Ã‰chec du chargement du workflow" -Status "ERROR"
    exit 1
}

Write-Message "Workflow chargÃ© avec succÃ¨s: $($workflow.name)" -Status "SUCCESS"

# Si aucune option spÃ©cifique n'est sÃ©lectionnÃ©e, analyser tout
if (-not ($ActivitiesOnly -or $TransitionsOnly -or $ConditionsOnly)) {
    $ActivitiesOnly = $true
    $TransitionsOnly = $true
    $ConditionsOnly = $true
}

# Analyser les activitÃ©s
if ($ActivitiesOnly) {
    Write-Message "DÃ©tection des activitÃ©s du workflow..."
    $activities = Get-N8nWorkflowActivities -Workflow $workflow -IncludeDetails:$IncludeDetails
    
    if ($activities) {
        Write-Message "ActivitÃ©s dÃ©tectÃ©es avec succÃ¨s: $($activities.Count) activitÃ©s trouvÃ©es" -Status "SUCCESS"
        
        # Enregistrer les activitÃ©s
        $activitiesOutputPath = Join-Path -Path $OutputFolder -ChildPath "workflow_activities.$($Format.ToLower())"
        
        switch ($Format) {
            "JSON" {
                $activities | ConvertTo-Json -Depth 10 | Out-File -FilePath $activitiesOutputPath -Encoding UTF8
            }
            "Markdown" {
                $markdown = "# ActivitÃ©s du workflow: $($workflow.name)`n`n"
                $markdown += "| ID | Nom | Type | CatÃ©gorie |`n"
                $markdown += "|----|-----|------|-----------|`n"
                foreach ($activity in $activities) {
                    $markdown += "| $($activity.Id) | $($activity.Name) | $($activity.Type) | $($activity.Category) |`n"
                }
                $markdown | Out-File -FilePath $activitiesOutputPath -Encoding UTF8
            }
            "HTML" {
                $html = "<html><head><title>ActivitÃ©s du workflow: $($workflow.name)</title></head><body>"
                $html += "<h1>ActivitÃ©s du workflow: $($workflow.name)</h1>"
                $html += "<table border='1'><tr><th>ID</th><th>Nom</th><th>Type</th><th>CatÃ©gorie</th></tr>"
                foreach ($activity in $activities) {
                    $html += "<tr><td>$($activity.Id)</td><td>$($activity.Name)</td><td>$($activity.Type)</td><td>$($activity.Category)</td></tr>"
                }
                $html += "</table></body></html>"
                $html | Out-File -FilePath $activitiesOutputPath -Encoding UTF8
            }
            "Text" {
                $text = "ActivitÃ©s du workflow: $($workflow.name)`r`n`r`n"
                foreach ($activity in $activities) {
                    $text += "- $($activity.Name) (ID: $($activity.Id), Type: $($activity.Type), CatÃ©gorie: $($activity.Category))`r`n"
                }
                $text | Out-File -FilePath $activitiesOutputPath -Encoding UTF8
            }
        }
        
        Write-Message "ActivitÃ©s enregistrÃ©es dans: $activitiesOutputPath" -Status "SUCCESS"
    }
    else {
        Write-Message "Ã‰chec de la dÃ©tection des activitÃ©s" -Status "ERROR"
    }
}

# Analyser les transitions
if ($TransitionsOnly) {
    Write-Message "Extraction des transitions du workflow..."
    $transitions = Get-N8nWorkflowTransitions -Workflow $workflow -IncludeNodeDetails:$IncludeDetails
    
    if ($transitions) {
        Write-Message "Transitions extraites avec succÃ¨s: $($transitions.Count) transitions trouvÃ©es" -Status "SUCCESS"
        
        # Enregistrer les transitions
        $transitionsOutputPath = Join-Path -Path $OutputFolder -ChildPath "workflow_transitions.$($Format.ToLower())"
        
        switch ($Format) {
            "JSON" {
                $transitions | ConvertTo-Json -Depth 10 | Out-File -FilePath $transitionsOutputPath -Encoding UTF8
            }
            "Markdown" {
                $markdown = "# Transitions du workflow: $($workflow.name)`n`n"
                $markdown += "| Source | Destination | Index |`n"
                $markdown += "|--------|-------------|-------|`n"
                foreach ($transition in $transitions) {
                    $markdown += "| $($transition.SourceNodeName) | $($transition.TargetNodeName) | $($transition.OutputIndex) |`n"
                }
                $markdown | Out-File -FilePath $transitionsOutputPath -Encoding UTF8
            }
            "HTML" {
                $html = "<html><head><title>Transitions du workflow: $($workflow.name)</title></head><body>"
                $html += "<h1>Transitions du workflow: $($workflow.name)</h1>"
                $html += "<table border='1'><tr><th>Source</th><th>Destination</th><th>Index</th></tr>"
                foreach ($transition in $transitions) {
                    $html += "<tr><td>$($transition.SourceNodeName)</td><td>$($transition.TargetNodeName)</td><td>$($transition.OutputIndex)</td></tr>"
                }
                $html += "</table></body></html>"
                $html | Out-File -FilePath $transitionsOutputPath -Encoding UTF8
            }
            "Text" {
                $text = "Transitions du workflow: $($workflow.name)`r`n`r`n"
                foreach ($transition in $transitions) {
                    $text += "- $($transition.SourceNodeName) -> $($transition.TargetNodeName) (Index: $($transition.OutputIndex))`r`n"
                }
                $text | Out-File -FilePath $transitionsOutputPath -Encoding UTF8
            }
        }
        
        Write-Message "Transitions enregistrÃ©es dans: $transitionsOutputPath" -Status "SUCCESS"
    }
    else {
        Write-Message "Ã‰chec de l'extraction des transitions" -Status "ERROR"
    }
}

# Analyser les conditions
if ($ConditionsOnly) {
    Write-Message "Analyse des conditions du workflow..."
    $conditions = Get-N8nWorkflowConditions -Workflow $workflow -IncludeTransitions
    
    if ($conditions -ne $null) {
        Write-Message "Conditions analysÃ©es avec succÃ¨s: $($conditions.Count) nÅ“uds conditionnels trouvÃ©s" -Status "SUCCESS"
        
        # Enregistrer les conditions
        $conditionsOutputPath = Join-Path -Path $OutputFolder -ChildPath "workflow_conditions.$($Format.ToLower())"
        
        switch ($Format) {
            "JSON" {
                $conditions | ConvertTo-Json -Depth 10 | Out-File -FilePath $conditionsOutputPath -Encoding UTF8
            }
            "Markdown" {
                $markdown = "# Conditions du workflow: $($workflow.name)`n`n"
                
                if ($conditions.Count -eq 0) {
                    $markdown += "Aucun nÅ“ud conditionnel trouvÃ© dans le workflow.`n"
                }
                else {
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
                }
                
                $markdown | Out-File -FilePath $conditionsOutputPath -Encoding UTF8
            }
            "HTML" {
                $html = "<html><head><title>Conditions du workflow: $($workflow.name)</title></head><body>"
                $html += "<h1>Conditions du workflow: $($workflow.name)</h1>"
                
                if ($conditions.Count -eq 0) {
                    $html += "<p>Aucun nÅ“ud conditionnel trouvÃ© dans le workflow.</p>"
                }
                else {
                    foreach ($condition in $conditions) {
                        $html += "<h2>$($condition.Name)</h2>"
                        $html += "<p><strong>Type</strong>: $($condition.Type)</p>"
                        $html += "<p><strong>Conditions</strong>:</p>"
                        
                        $html += "<table border='1'><tr><th>Type</th><th>Valeur 1</th><th>OpÃ©ration</th><th>Valeur 2</th></tr>"
                        foreach ($cond in $condition.Conditions) {
                            $html += "<tr><td>$($cond.Type)</td><td>$($cond.Value1)</td><td>$($cond.Operation)</td><td>$($cond.Value2)</td></tr>"
                        }
                        $html += "</table>"
                        
                        if ($condition.Transitions) {
                            $html += "<p><strong>Transitions</strong>:</p>"
                            $html += "<table border='1'><tr><th>Sortie</th><th>Label</th><th>Destination</th></tr>"
                            foreach ($transition in $condition.Transitions) {
                                $html += "<tr><td>$($transition.OutputIndex)</td><td>$($transition.OutputLabel)</td><td>$($transition.TargetNodeName)</td></tr>"
                            }
                            $html += "</table>"
                        }
                    }
                }
                
                $html += "</body></html>"
                $html | Out-File -FilePath $conditionsOutputPath -Encoding UTF8
            }
            "Text" {
                $text = "Conditions du workflow: $($workflow.name)`r`n`r`n"
                
                if ($conditions.Count -eq 0) {
                    $text += "Aucun nÅ“ud conditionnel trouvÃ© dans le workflow.`r`n"
                }
                else {
                    foreach ($condition in $conditions) {
                        $text += "- $($condition.Name) (Type: $($condition.Type))`r`n"
                        $text += "  Conditions:`r`n"
                        
                        foreach ($cond in $condition.Conditions) {
                            $text += "  - $($cond.Type): $($cond.Value1) $($cond.Operation) $($cond.Value2)`r`n"
                        }
                        
                        if ($condition.Transitions) {
                            $text += "  Transitions:`r`n"
                            foreach ($transition in $condition.Transitions) {
                                $text += "  - $($transition.OutputIndex) ($($transition.OutputLabel)) -> $($transition.TargetNodeName)`r`n"
                            }
                        }
                        
                        $text += "`r`n"
                    }
                }
                
                $text | Out-File -FilePath $conditionsOutputPath -Encoding UTF8
            }
        }
        
        Write-Message "Conditions enregistrÃ©es dans: $conditionsOutputPath" -Status "SUCCESS"
    }
    else {
        Write-Message "Ã‰chec de l'analyse des conditions" -Status "ERROR"
    }
}

# GÃ©nÃ©rer un rapport complet
$reportOutputPath = Join-Path -Path $OutputFolder -ChildPath "workflow_analysis_report.$($Format.ToLower())"
$report = Get-N8nWorkflowAnalysisReport -WorkflowPath $WorkflowPath -OutputPath $reportOutputPath -Format $Format

if ($report) {
    Write-Message "Rapport complet gÃ©nÃ©rÃ© avec succÃ¨s: $reportOutputPath" -Status "SUCCESS"
}
else {
    Write-Message "Ã‰chec de la gÃ©nÃ©ration du rapport complet" -Status "ERROR"
}

Write-Message "Analyse terminÃ©e."

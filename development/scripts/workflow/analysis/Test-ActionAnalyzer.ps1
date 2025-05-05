# Script de test pour les fonctions d'analyse des actions de workflow n8n
# Ce script teste les fonctions Get-N8nWorkflowActions, Get-N8nWorkflowActionParameters et Get-N8nWorkflowActionResults

#Requires -Version 5.1

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$WorkflowPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = ".\test-results"
)

# Fonction pour afficher des messages de test
function Write-TestMessage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Status = "INFO"
    )
    
    switch ($Status) {
        "INFO" { 
            Write-Host "[INFO] $Message" -ForegroundColor Cyan 
        }
        "SUCCESS" { 
            Write-Host "[SUCCESS] $Message" -ForegroundColor Green 
        }
        "WARNING" { 
            Write-Host "[WARNING] $Message" -ForegroundColor Yellow 
        }
        "ERROR" { 
            Write-Host "[ERROR] $Message" -ForegroundColor Red 
        }
    }
}

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputFolder -PathType Container)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    Write-TestMessage "Dossier de sortie crÃ©Ã©: $OutputFolder" -Status "INFO"
}

# Importer le module WorkflowAnalyzer
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "WorkflowAnalyzer.psm1"
if (Test-Path -Path $modulePath -PathType Leaf) {
    Import-Module $modulePath -Force
    Write-TestMessage "Module WorkflowAnalyzer importÃ© avec succÃ¨s" -Status "SUCCESS"
} else {
    Write-TestMessage "Module WorkflowAnalyzer introuvable: $modulePath" -Status "ERROR"
    exit 1
}

# VÃ©rifier si le fichier de workflow existe
if (-not (Test-Path -Path $WorkflowPath -PathType Leaf)) {
    Write-TestMessage "Fichier de workflow introuvable: $WorkflowPath" -Status "ERROR"
    exit 1
}

# Charger le workflow
Write-TestMessage "Chargement du workflow: $WorkflowPath" -Status "INFO"
$workflow = Get-N8nWorkflow -WorkflowPath $WorkflowPath

if (-not $workflow) {
    Write-TestMessage "Ã‰chec du chargement du workflow" -Status "ERROR"
    exit 1
}

Write-TestMessage "Workflow chargÃ© avec succÃ¨s: $($workflow.name)" -Status "SUCCESS"
Write-TestMessage "Nombre de nÅ“uds: $($workflow.nodes.Count)" -Status "INFO"
Write-TestMessage "Workflow actif: $($workflow.active)" -Status "INFO"

# Test 1: Extraire les actions exÃ©cutÃ©es
Write-TestMessage "Test 1: Extraction des actions exÃ©cutÃ©es..." -Status "INFO"
$actions = Get-N8nWorkflowActions -Workflow $workflow -IncludeDetails -IncludeRelationships

if ($actions -ne $null) {
    Write-TestMessage "Actions extraites avec succÃ¨s: $($actions.Count) actions trouvÃ©es" -Status "SUCCESS"
    
    # Afficher quelques actions
    if ($actions.Count -gt 0) {
        Write-TestMessage "Exemples d'actions:" -Status "INFO"
        $actions | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.Name) (Type: $($_.ActionType))"
            if ($_.Parameters.Count -gt 0) {
                Write-Host "    ParamÃ¨tres:"
                $_.Parameters | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * $($_.Name): $($_.Value) (Type: $($_.Type))"
                }
            }
            if ($_.InputNodes.Count -gt 0) {
                Write-Host "    NÅ“uds d'entrÃ©e:"
                $_.InputNodes | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * $($_.NodeName) (Type: $($_.NodeType))"
                }
            }
            if ($_.OutputNodes.Count -gt 0) {
                Write-Host "    NÅ“uds de sortie:"
                $_.OutputNodes | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * $($_.NodeName) (Type: $($_.NodeType))"
                }
            }
        }
    } else {
        Write-TestMessage "Aucune action trouvÃ©e dans le workflow" -Status "WARNING"
    }
    
    # Enregistrer les rÃ©sultats
    $actionsOutputPath = Join-Path -Path $OutputFolder -ChildPath "actions.json"
    $actions | ConvertTo-Json -Depth 10 | Out-File -FilePath $actionsOutputPath -Encoding UTF8
    Write-TestMessage "RÃ©sultats enregistrÃ©s dans: $actionsOutputPath" -Status "INFO"
} else {
    Write-TestMessage "Ã‰chec de l'extraction des actions" -Status "ERROR"
}

# Test 2: DÃ©tecter les paramÃ¨tres d'action
Write-TestMessage "Test 2: DÃ©tection des paramÃ¨tres d'action..." -Status "INFO"
$actionParameters = Get-N8nWorkflowActionParameters -Workflow $workflow -IncludeDetails

if ($actionParameters -ne $null) {
    Write-TestMessage "ParamÃ¨tres d'action dÃ©tectÃ©s avec succÃ¨s: $($actionParameters.Count) actions analysÃ©es" -Status "SUCCESS"
    
    # Afficher quelques paramÃ¨tres d'action
    if ($actionParameters.Count -gt 0) {
        Write-TestMessage "Exemples de paramÃ¨tres d'action:" -Status "INFO"
        $actionParameters | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.Name) (Type: $($_.ActionType))"
            Write-Host "    Impact:"
            Write-Host "      * Performance: $($_.Impact.Performance)"
            Write-Host "      * Taille des donnÃ©es: $($_.Impact.DataSize)"
            Write-Host "      * FiabilitÃ©: $($_.Impact.Reliability)"
            Write-Host "      * SÃ©curitÃ©: $($_.Impact.Security)"
            if ($_.Parameters.Count -gt 0) {
                Write-Host "    ParamÃ¨tres:"
                $_.Parameters | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * $($_.Name): $($_.Value) (Type: $($_.Type))"
                }
            }
        }
    } else {
        Write-TestMessage "Aucun paramÃ¨tre d'action trouvÃ© dans le workflow" -Status "WARNING"
    }
    
    # Enregistrer les rÃ©sultats
    $actionParametersOutputPath = Join-Path -Path $OutputFolder -ChildPath "action_parameters.json"
    $actionParameters | ConvertTo-Json -Depth 10 | Out-File -FilePath $actionParametersOutputPath -Encoding UTF8
    Write-TestMessage "RÃ©sultats enregistrÃ©s dans: $actionParametersOutputPath" -Status "INFO"
} else {
    Write-TestMessage "Ã‰chec de la dÃ©tection des paramÃ¨tres d'action" -Status "ERROR"
}

# Test 3: Analyser les rÃ©sultats d'action
Write-TestMessage "Test 3: Analyse des rÃ©sultats d'action..." -Status "INFO"
$actionResults = Get-N8nWorkflowActionResults -Workflow $workflow -IncludeDetails

if ($actionResults -ne $null) {
    Write-TestMessage "RÃ©sultats d'action analysÃ©s avec succÃ¨s: $($actionResults.Count) actions analysÃ©es" -Status "SUCCESS"
    
    # Afficher quelques rÃ©sultats d'action
    if ($actionResults.Count -gt 0) {
        Write-TestMessage "Exemples de rÃ©sultats d'action:" -Status "INFO"
        $actionResults | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.Name) (Type: $($_.ActionType))"
            Write-Host "    Type de sortie: $($_.OutputType)"
            if ($_.Consumers.Count -gt 0) {
                Write-Host "    Consommateurs:"
                $_.Consumers | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * $($_.NodeName) (Type: $($_.NodeType))"
                }
            }
            if ($_.DataFlow.Count -gt 0) {
                Write-Host "    Flux de donnÃ©es:"
                $_.DataFlow | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * De $($_.SourceNode) Ã  $($_.TargetNode) (TransformÃ©: $($_.DataTransformed))"
                }
            }
        }
    } else {
        Write-TestMessage "Aucun rÃ©sultat d'action trouvÃ© dans le workflow" -Status "WARNING"
    }
    
    # Enregistrer les rÃ©sultats
    $actionResultsOutputPath = Join-Path -Path $OutputFolder -ChildPath "action_results.json"
    $actionResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $actionResultsOutputPath -Encoding UTF8
    Write-TestMessage "RÃ©sultats enregistrÃ©s dans: $actionResultsOutputPath" -Status "INFO"
} else {
    Write-TestMessage "Ã‰chec de l'analyse des rÃ©sultats d'action" -Status "ERROR"
}

# GÃ©nÃ©rer un rapport de test
$reportPath = Join-Path -Path $OutputFolder -ChildPath "action_analysis_report.md"
$report = @"
# Rapport d'analyse des actions de workflow

## Informations gÃ©nÃ©rales
- **Workflow**: $($workflow.name)
- **ID**: $($workflow.id)
- **Actif**: $($workflow.active)
- **Nombre de nÅ“uds**: $($workflow.nodes.Count)

## Actions exÃ©cutÃ©es
- **Nombre d'actions**: $($actions.Count)

$(if ($actions.Count -gt 0) {
    $actions | ForEach-Object {
        "### $($_.Name) (Type: $($_.ActionType))
- **ID**: $($_.Id)
- **Type**: $($_.Type)
- **CatÃ©gorie**: $($_.Category)
- **ParamÃ¨tres**:
$(if ($_.Parameters.Count -gt 0) {
    $_.Parameters | ForEach-Object {
        "  - **$($_.Name)**: $($_.Value) (Type: $($_.Type))"
    } | Out-String
} else {
    "  - Aucun paramÃ¨tre spÃ©cifique"
})
- **NÅ“uds d'entrÃ©e**:
$(if ($_.InputNodes.Count -gt 0) {
    $_.InputNodes | ForEach-Object {
        "  - **$($_.NodeName)** (Type: $($_.NodeType))"
    } | Out-String
} else {
    "  - Aucun nÅ“ud d'entrÃ©e"
})
- **NÅ“uds de sortie**:
$(if ($_.OutputNodes.Count -gt 0) {
    $_.OutputNodes | ForEach-Object {
        "  - **$($_.NodeName)** (Type: $($_.NodeType))"
    } | Out-String
} else {
    "  - Aucun nÅ“ud de sortie"
})
"
    } | Out-String
} else {
    "Aucune action trouvÃ©e dans le workflow."
})

## ParamÃ¨tres d'action
- **Nombre d'actions analysÃ©es**: $($actionParameters.Count)

$(if ($actionParameters.Count -gt 0) {
    $actionParameters | ForEach-Object {
        "### $($_.Name) (Type: $($_.ActionType))
- **ID**: $($_.Id)
- **Type**: $($_.Type)
- **CatÃ©gorie**: $($_.Category)
- **Impact**:
  - **Performance**: $($_.Impact.Performance)
  - **Taille des donnÃ©es**: $($_.Impact.DataSize)
  - **FiabilitÃ©**: $($_.Impact.Reliability)
  - **SÃ©curitÃ©**: $($_.Impact.Security)
  - **DÃ©pendances**: $($_.Impact.Dependencies -join ', ')
- **ParamÃ¨tres**:
$(if ($_.Parameters.Count -gt 0) {
    $_.Parameters | ForEach-Object {
        "  - **$($_.Name)**: $($_.Value) (Type: $($_.Type))"
    } | Out-String
} else {
    "  - Aucun paramÃ¨tre spÃ©cifique"
})
"
    } | Out-String
} else {
    "Aucun paramÃ¨tre d'action trouvÃ© dans le workflow."
})

## RÃ©sultats d'action
- **Nombre d'actions analysÃ©es**: $($actionResults.Count)

$(if ($actionResults.Count -gt 0) {
    $actionResults | ForEach-Object {
        "### $($_.Name) (Type: $($_.ActionType))
- **ID**: $($_.Id)
- **Type**: $($_.Type)
- **CatÃ©gorie**: $($_.Category)
- **Type de sortie**: $($_.OutputType)
- **Consommateurs**:
$(if ($_.Consumers.Count -gt 0) {
    $_.Consumers | ForEach-Object {
        "  - **$($_.NodeName)** (Type: $($_.NodeType), Index de sortie: $($_.OutputIndex))"
    } | Out-String
} else {
    "  - Aucun consommateur"
})
- **Flux de donnÃ©es**:
$(if ($_.DataFlow.Count -gt 0) {
    $_.DataFlow | ForEach-Object {
        "  - De **$($_.SourceNode)** Ã  **$($_.TargetNode)** (TransformÃ©: $($_.DataTransformed))"
    } | Out-String
} else {
    "  - Aucun flux de donnÃ©es"
})
"
    } | Out-String
} else {
    "Aucun rÃ©sultat d'action trouvÃ© dans le workflow."
})
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-TestMessage "Rapport de test gÃ©nÃ©rÃ©: $reportPath" -Status "SUCCESS"

Write-TestMessage "Tests terminÃ©s avec succÃ¨s!" -Status "SUCCESS"

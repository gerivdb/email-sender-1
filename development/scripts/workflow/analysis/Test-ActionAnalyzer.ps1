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

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputFolder -PathType Container)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    Write-TestMessage "Dossier de sortie créé: $OutputFolder" -Status "INFO"
}

# Importer le module WorkflowAnalyzer
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "WorkflowAnalyzer.psm1"
if (Test-Path -Path $modulePath -PathType Leaf) {
    Import-Module $modulePath -Force
    Write-TestMessage "Module WorkflowAnalyzer importé avec succès" -Status "SUCCESS"
} else {
    Write-TestMessage "Module WorkflowAnalyzer introuvable: $modulePath" -Status "ERROR"
    exit 1
}

# Vérifier si le fichier de workflow existe
if (-not (Test-Path -Path $WorkflowPath -PathType Leaf)) {
    Write-TestMessage "Fichier de workflow introuvable: $WorkflowPath" -Status "ERROR"
    exit 1
}

# Charger le workflow
Write-TestMessage "Chargement du workflow: $WorkflowPath" -Status "INFO"
$workflow = Get-N8nWorkflow -WorkflowPath $WorkflowPath

if (-not $workflow) {
    Write-TestMessage "Échec du chargement du workflow" -Status "ERROR"
    exit 1
}

Write-TestMessage "Workflow chargé avec succès: $($workflow.name)" -Status "SUCCESS"
Write-TestMessage "Nombre de nœuds: $($workflow.nodes.Count)" -Status "INFO"
Write-TestMessage "Workflow actif: $($workflow.active)" -Status "INFO"

# Test 1: Extraire les actions exécutées
Write-TestMessage "Test 1: Extraction des actions exécutées..." -Status "INFO"
$actions = Get-N8nWorkflowActions -Workflow $workflow -IncludeDetails -IncludeRelationships

if ($actions -ne $null) {
    Write-TestMessage "Actions extraites avec succès: $($actions.Count) actions trouvées" -Status "SUCCESS"
    
    # Afficher quelques actions
    if ($actions.Count -gt 0) {
        Write-TestMessage "Exemples d'actions:" -Status "INFO"
        $actions | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.Name) (Type: $($_.ActionType))"
            if ($_.Parameters.Count -gt 0) {
                Write-Host "    Paramètres:"
                $_.Parameters | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * $($_.Name): $($_.Value) (Type: $($_.Type))"
                }
            }
            if ($_.InputNodes.Count -gt 0) {
                Write-Host "    Nœuds d'entrée:"
                $_.InputNodes | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * $($_.NodeName) (Type: $($_.NodeType))"
                }
            }
            if ($_.OutputNodes.Count -gt 0) {
                Write-Host "    Nœuds de sortie:"
                $_.OutputNodes | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * $($_.NodeName) (Type: $($_.NodeType))"
                }
            }
        }
    } else {
        Write-TestMessage "Aucune action trouvée dans le workflow" -Status "WARNING"
    }
    
    # Enregistrer les résultats
    $actionsOutputPath = Join-Path -Path $OutputFolder -ChildPath "actions.json"
    $actions | ConvertTo-Json -Depth 10 | Out-File -FilePath $actionsOutputPath -Encoding UTF8
    Write-TestMessage "Résultats enregistrés dans: $actionsOutputPath" -Status "INFO"
} else {
    Write-TestMessage "Échec de l'extraction des actions" -Status "ERROR"
}

# Test 2: Détecter les paramètres d'action
Write-TestMessage "Test 2: Détection des paramètres d'action..." -Status "INFO"
$actionParameters = Get-N8nWorkflowActionParameters -Workflow $workflow -IncludeDetails

if ($actionParameters -ne $null) {
    Write-TestMessage "Paramètres d'action détectés avec succès: $($actionParameters.Count) actions analysées" -Status "SUCCESS"
    
    # Afficher quelques paramètres d'action
    if ($actionParameters.Count -gt 0) {
        Write-TestMessage "Exemples de paramètres d'action:" -Status "INFO"
        $actionParameters | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.Name) (Type: $($_.ActionType))"
            Write-Host "    Impact:"
            Write-Host "      * Performance: $($_.Impact.Performance)"
            Write-Host "      * Taille des données: $($_.Impact.DataSize)"
            Write-Host "      * Fiabilité: $($_.Impact.Reliability)"
            Write-Host "      * Sécurité: $($_.Impact.Security)"
            if ($_.Parameters.Count -gt 0) {
                Write-Host "    Paramètres:"
                $_.Parameters | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * $($_.Name): $($_.Value) (Type: $($_.Type))"
                }
            }
        }
    } else {
        Write-TestMessage "Aucun paramètre d'action trouvé dans le workflow" -Status "WARNING"
    }
    
    # Enregistrer les résultats
    $actionParametersOutputPath = Join-Path -Path $OutputFolder -ChildPath "action_parameters.json"
    $actionParameters | ConvertTo-Json -Depth 10 | Out-File -FilePath $actionParametersOutputPath -Encoding UTF8
    Write-TestMessage "Résultats enregistrés dans: $actionParametersOutputPath" -Status "INFO"
} else {
    Write-TestMessage "Échec de la détection des paramètres d'action" -Status "ERROR"
}

# Test 3: Analyser les résultats d'action
Write-TestMessage "Test 3: Analyse des résultats d'action..." -Status "INFO"
$actionResults = Get-N8nWorkflowActionResults -Workflow $workflow -IncludeDetails

if ($actionResults -ne $null) {
    Write-TestMessage "Résultats d'action analysés avec succès: $($actionResults.Count) actions analysées" -Status "SUCCESS"
    
    # Afficher quelques résultats d'action
    if ($actionResults.Count -gt 0) {
        Write-TestMessage "Exemples de résultats d'action:" -Status "INFO"
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
                Write-Host "    Flux de données:"
                $_.DataFlow | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * De $($_.SourceNode) à $($_.TargetNode) (Transformé: $($_.DataTransformed))"
                }
            }
        }
    } else {
        Write-TestMessage "Aucun résultat d'action trouvé dans le workflow" -Status "WARNING"
    }
    
    # Enregistrer les résultats
    $actionResultsOutputPath = Join-Path -Path $OutputFolder -ChildPath "action_results.json"
    $actionResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $actionResultsOutputPath -Encoding UTF8
    Write-TestMessage "Résultats enregistrés dans: $actionResultsOutputPath" -Status "INFO"
} else {
    Write-TestMessage "Échec de l'analyse des résultats d'action" -Status "ERROR"
}

# Générer un rapport de test
$reportPath = Join-Path -Path $OutputFolder -ChildPath "action_analysis_report.md"
$report = @"
# Rapport d'analyse des actions de workflow

## Informations générales
- **Workflow**: $($workflow.name)
- **ID**: $($workflow.id)
- **Actif**: $($workflow.active)
- **Nombre de nœuds**: $($workflow.nodes.Count)

## Actions exécutées
- **Nombre d'actions**: $($actions.Count)

$(if ($actions.Count -gt 0) {
    $actions | ForEach-Object {
        "### $($_.Name) (Type: $($_.ActionType))
- **ID**: $($_.Id)
- **Type**: $($_.Type)
- **Catégorie**: $($_.Category)
- **Paramètres**:
$(if ($_.Parameters.Count -gt 0) {
    $_.Parameters | ForEach-Object {
        "  - **$($_.Name)**: $($_.Value) (Type: $($_.Type))"
    } | Out-String
} else {
    "  - Aucun paramètre spécifique"
})
- **Nœuds d'entrée**:
$(if ($_.InputNodes.Count -gt 0) {
    $_.InputNodes | ForEach-Object {
        "  - **$($_.NodeName)** (Type: $($_.NodeType))"
    } | Out-String
} else {
    "  - Aucun nœud d'entrée"
})
- **Nœuds de sortie**:
$(if ($_.OutputNodes.Count -gt 0) {
    $_.OutputNodes | ForEach-Object {
        "  - **$($_.NodeName)** (Type: $($_.NodeType))"
    } | Out-String
} else {
    "  - Aucun nœud de sortie"
})
"
    } | Out-String
} else {
    "Aucune action trouvée dans le workflow."
})

## Paramètres d'action
- **Nombre d'actions analysées**: $($actionParameters.Count)

$(if ($actionParameters.Count -gt 0) {
    $actionParameters | ForEach-Object {
        "### $($_.Name) (Type: $($_.ActionType))
- **ID**: $($_.Id)
- **Type**: $($_.Type)
- **Catégorie**: $($_.Category)
- **Impact**:
  - **Performance**: $($_.Impact.Performance)
  - **Taille des données**: $($_.Impact.DataSize)
  - **Fiabilité**: $($_.Impact.Reliability)
  - **Sécurité**: $($_.Impact.Security)
  - **Dépendances**: $($_.Impact.Dependencies -join ', ')
- **Paramètres**:
$(if ($_.Parameters.Count -gt 0) {
    $_.Parameters | ForEach-Object {
        "  - **$($_.Name)**: $($_.Value) (Type: $($_.Type))"
    } | Out-String
} else {
    "  - Aucun paramètre spécifique"
})
"
    } | Out-String
} else {
    "Aucun paramètre d'action trouvé dans le workflow."
})

## Résultats d'action
- **Nombre d'actions analysées**: $($actionResults.Count)

$(if ($actionResults.Count -gt 0) {
    $actionResults | ForEach-Object {
        "### $($_.Name) (Type: $($_.ActionType))
- **ID**: $($_.Id)
- **Type**: $($_.Type)
- **Catégorie**: $($_.Category)
- **Type de sortie**: $($_.OutputType)
- **Consommateurs**:
$(if ($_.Consumers.Count -gt 0) {
    $_.Consumers | ForEach-Object {
        "  - **$($_.NodeName)** (Type: $($_.NodeType), Index de sortie: $($_.OutputIndex))"
    } | Out-String
} else {
    "  - Aucun consommateur"
})
- **Flux de données**:
$(if ($_.DataFlow.Count -gt 0) {
    $_.DataFlow | ForEach-Object {
        "  - De **$($_.SourceNode)** à **$($_.TargetNode)** (Transformé: $($_.DataTransformed))"
    } | Out-String
} else {
    "  - Aucun flux de données"
})
"
    } | Out-String
} else {
    "Aucun résultat d'action trouvé dans le workflow."
})
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-TestMessage "Rapport de test généré: $reportPath" -Status "SUCCESS"

Write-TestMessage "Tests terminés avec succès!" -Status "SUCCESS"

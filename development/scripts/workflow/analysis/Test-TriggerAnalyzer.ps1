# Script de test pour les fonctions d'analyse des déclencheurs de workflow n8n
# Ce script teste les fonctions Get-N8nWorkflowTriggerConditions, Get-N8nWorkflowEventSources et Get-N8nWorkflowTriggerParameters

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

# Test 1: Extraire les conditions de déclenchement
Write-TestMessage "Test 1: Extraction des conditions de déclenchement..." -Status "INFO"
$triggerConditions = Get-N8nWorkflowTriggerConditions -Workflow $workflow -IncludeDetails

if ($triggerConditions -ne $null) {
    Write-TestMessage "Conditions de déclenchement extraites avec succès: $($triggerConditions.Count) déclencheurs trouvés" -Status "SUCCESS"
    
    # Afficher quelques conditions de déclenchement
    if ($triggerConditions.Count -gt 0) {
        Write-TestMessage "Exemples de conditions de déclenchement:" -Status "INFO"
        $triggerConditions | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.Name) (Type: $($_.TriggerType))"
            if ($_.Conditions.Count -gt 0) {
                Write-Host "    Conditions:"
                $_.Conditions | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * $($_.Type): $($_.Value)"
                }
            }
        }
    } else {
        Write-TestMessage "Aucun déclencheur trouvé dans le workflow" -Status "WARNING"
    }
    
    # Enregistrer les résultats
    $triggerConditionsOutputPath = Join-Path -Path $OutputFolder -ChildPath "trigger_conditions.json"
    $triggerConditions | ConvertTo-Json -Depth 10 | Out-File -FilePath $triggerConditionsOutputPath -Encoding UTF8
    Write-TestMessage "Résultats enregistrés dans: $triggerConditionsOutputPath" -Status "INFO"
} else {
    Write-TestMessage "Échec de l'extraction des conditions de déclenchement" -Status "ERROR"
}

# Test 2: Détecter les sources d'événements
Write-TestMessage "Test 2: Détection des sources d'événements..." -Status "INFO"
$eventSources = Get-N8nWorkflowEventSources -Workflow $workflow -IncludeDetails

if ($eventSources -ne $null) {
    Write-TestMessage "Sources d'événements détectées avec succès: $($eventSources.Count) sources trouvées" -Status "SUCCESS"
    
    # Afficher quelques sources d'événements
    if ($eventSources.Count -gt 0) {
        Write-TestMessage "Exemples de sources d'événements:" -Status "INFO"
        $eventSources | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.Name) (Type: $($_.SourceType))"
            if ($_.Details.Count -gt 0) {
                Write-Host "    Détails:"
                $_.Details.GetEnumerator() | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * $($_.Key): $($_.Value)"
                }
            }
        }
    } else {
        Write-TestMessage "Aucune source d'événements trouvée dans le workflow" -Status "WARNING"
    }
    
    # Enregistrer les résultats
    $eventSourcesOutputPath = Join-Path -Path $OutputFolder -ChildPath "event_sources.json"
    $eventSources | ConvertTo-Json -Depth 10 | Out-File -FilePath $eventSourcesOutputPath -Encoding UTF8
    Write-TestMessage "Résultats enregistrés dans: $eventSourcesOutputPath" -Status "INFO"
} else {
    Write-TestMessage "Échec de la détection des sources d'événements" -Status "ERROR"
}

# Test 3: Analyser les paramètres de déclenchement
Write-TestMessage "Test 3: Analyse des paramètres de déclenchement..." -Status "INFO"
$triggerParameters = Get-N8nWorkflowTriggerParameters -Workflow $workflow -IncludeDetails

if ($triggerParameters -ne $null) {
    Write-TestMessage "Paramètres de déclenchement analysés avec succès: $($triggerParameters.Count) déclencheurs analysés" -Status "SUCCESS"
    
    # Afficher quelques paramètres de déclenchement
    if ($triggerParameters.Count -gt 0) {
        Write-TestMessage "Exemples de paramètres de déclenchement:" -Status "INFO"
        $triggerParameters | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.Name) (Type: $($_.TriggerType))"
            Write-Host "    Impact:"
            Write-Host "      * Fréquence: $($_.Impact.Frequency)"
            Write-Host "      * Volume de données: $($_.Impact.DataVolume)"
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
        Write-TestMessage "Aucun paramètre de déclenchement trouvé dans le workflow" -Status "WARNING"
    }
    
    # Enregistrer les résultats
    $triggerParametersOutputPath = Join-Path -Path $OutputFolder -ChildPath "trigger_parameters.json"
    $triggerParameters | ConvertTo-Json -Depth 10 | Out-File -FilePath $triggerParametersOutputPath -Encoding UTF8
    Write-TestMessage "Résultats enregistrés dans: $triggerParametersOutputPath" -Status "INFO"
} else {
    Write-TestMessage "Échec de l'analyse des paramètres de déclenchement" -Status "ERROR"
}

# Générer un rapport de test
$reportPath = Join-Path -Path $OutputFolder -ChildPath "trigger_analysis_report.md"
$report = @"
# Rapport d'analyse des déclencheurs de workflow

## Informations générales
- **Workflow**: $($workflow.name)
- **ID**: $($workflow.id)
- **Actif**: $($workflow.active)
- **Nombre de nœuds**: $($workflow.nodes.Count)

## Conditions de déclenchement
- **Nombre de déclencheurs**: $($triggerConditions.Count)

$(if ($triggerConditions.Count -gt 0) {
    $triggerConditions | ForEach-Object {
        "### $($_.Name) (Type: $($_.TriggerType))
- **ID**: $($_.Id)
- **Type**: $($_.Type)
- **Conditions**:
$(if ($_.Conditions.Count -gt 0) {
    $_.Conditions | ForEach-Object {
        "  - **$($_.Type)**: $($_.Value)"
    } | Out-String
} else {
    "  - Aucune condition spécifique"
})
"
    } | Out-String
} else {
    "Aucun déclencheur trouvé dans le workflow."
})

## Sources d'événements
- **Nombre de sources**: $($eventSources.Count)

$(if ($eventSources.Count -gt 0) {
    $eventSources | ForEach-Object {
        "### $($_.Name) (Type: $($_.SourceType))
- **ID**: $($_.Id)
- **Type**: $($_.Type)
- **Détails**:
$(if ($_.Details.Count -gt 0) {
    $_.Details.GetEnumerator() | ForEach-Object {
        "  - **$($_.Key)**: $($_.Value)"
    } | Out-String
} else {
    "  - Aucun détail spécifique"
})
"
    } | Out-String
} else {
    "Aucune source d'événements trouvée dans le workflow."
})

## Paramètres de déclenchement
- **Nombre de déclencheurs analysés**: $($triggerParameters.Count)

$(if ($triggerParameters.Count -gt 0) {
    $triggerParameters | ForEach-Object {
        "### $($_.Name) (Type: $($_.TriggerType))
- **ID**: $($_.Id)
- **Type**: $($_.Type)
- **Impact**:
  - **Fréquence**: $($_.Impact.Frequency)
  - **Volume de données**: $($_.Impact.DataVolume)
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
    "Aucun paramètre de déclenchement trouvé dans le workflow."
})
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-TestMessage "Rapport de test généré: $reportPath" -Status "SUCCESS"

Write-TestMessage "Tests terminés avec succès!" -Status "SUCCESS"

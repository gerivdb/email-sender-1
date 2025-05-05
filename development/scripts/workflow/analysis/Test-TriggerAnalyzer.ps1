# Script de test pour les fonctions d'analyse des dÃ©clencheurs de workflow n8n
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

# Test 1: Extraire les conditions de dÃ©clenchement
Write-TestMessage "Test 1: Extraction des conditions de dÃ©clenchement..." -Status "INFO"
$triggerConditions = Get-N8nWorkflowTriggerConditions -Workflow $workflow -IncludeDetails

if ($triggerConditions -ne $null) {
    Write-TestMessage "Conditions de dÃ©clenchement extraites avec succÃ¨s: $($triggerConditions.Count) dÃ©clencheurs trouvÃ©s" -Status "SUCCESS"
    
    # Afficher quelques conditions de dÃ©clenchement
    if ($triggerConditions.Count -gt 0) {
        Write-TestMessage "Exemples de conditions de dÃ©clenchement:" -Status "INFO"
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
        Write-TestMessage "Aucun dÃ©clencheur trouvÃ© dans le workflow" -Status "WARNING"
    }
    
    # Enregistrer les rÃ©sultats
    $triggerConditionsOutputPath = Join-Path -Path $OutputFolder -ChildPath "trigger_conditions.json"
    $triggerConditions | ConvertTo-Json -Depth 10 | Out-File -FilePath $triggerConditionsOutputPath -Encoding UTF8
    Write-TestMessage "RÃ©sultats enregistrÃ©s dans: $triggerConditionsOutputPath" -Status "INFO"
} else {
    Write-TestMessage "Ã‰chec de l'extraction des conditions de dÃ©clenchement" -Status "ERROR"
}

# Test 2: DÃ©tecter les sources d'Ã©vÃ©nements
Write-TestMessage "Test 2: DÃ©tection des sources d'Ã©vÃ©nements..." -Status "INFO"
$eventSources = Get-N8nWorkflowEventSources -Workflow $workflow -IncludeDetails

if ($eventSources -ne $null) {
    Write-TestMessage "Sources d'Ã©vÃ©nements dÃ©tectÃ©es avec succÃ¨s: $($eventSources.Count) sources trouvÃ©es" -Status "SUCCESS"
    
    # Afficher quelques sources d'Ã©vÃ©nements
    if ($eventSources.Count -gt 0) {
        Write-TestMessage "Exemples de sources d'Ã©vÃ©nements:" -Status "INFO"
        $eventSources | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.Name) (Type: $($_.SourceType))"
            if ($_.Details.Count -gt 0) {
                Write-Host "    DÃ©tails:"
                $_.Details.GetEnumerator() | Select-Object -First 3 | ForEach-Object {
                    Write-Host "      * $($_.Key): $($_.Value)"
                }
            }
        }
    } else {
        Write-TestMessage "Aucune source d'Ã©vÃ©nements trouvÃ©e dans le workflow" -Status "WARNING"
    }
    
    # Enregistrer les rÃ©sultats
    $eventSourcesOutputPath = Join-Path -Path $OutputFolder -ChildPath "event_sources.json"
    $eventSources | ConvertTo-Json -Depth 10 | Out-File -FilePath $eventSourcesOutputPath -Encoding UTF8
    Write-TestMessage "RÃ©sultats enregistrÃ©s dans: $eventSourcesOutputPath" -Status "INFO"
} else {
    Write-TestMessage "Ã‰chec de la dÃ©tection des sources d'Ã©vÃ©nements" -Status "ERROR"
}

# Test 3: Analyser les paramÃ¨tres de dÃ©clenchement
Write-TestMessage "Test 3: Analyse des paramÃ¨tres de dÃ©clenchement..." -Status "INFO"
$triggerParameters = Get-N8nWorkflowTriggerParameters -Workflow $workflow -IncludeDetails

if ($triggerParameters -ne $null) {
    Write-TestMessage "ParamÃ¨tres de dÃ©clenchement analysÃ©s avec succÃ¨s: $($triggerParameters.Count) dÃ©clencheurs analysÃ©s" -Status "SUCCESS"
    
    # Afficher quelques paramÃ¨tres de dÃ©clenchement
    if ($triggerParameters.Count -gt 0) {
        Write-TestMessage "Exemples de paramÃ¨tres de dÃ©clenchement:" -Status "INFO"
        $triggerParameters | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.Name) (Type: $($_.TriggerType))"
            Write-Host "    Impact:"
            Write-Host "      * FrÃ©quence: $($_.Impact.Frequency)"
            Write-Host "      * Volume de donnÃ©es: $($_.Impact.DataVolume)"
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
        Write-TestMessage "Aucun paramÃ¨tre de dÃ©clenchement trouvÃ© dans le workflow" -Status "WARNING"
    }
    
    # Enregistrer les rÃ©sultats
    $triggerParametersOutputPath = Join-Path -Path $OutputFolder -ChildPath "trigger_parameters.json"
    $triggerParameters | ConvertTo-Json -Depth 10 | Out-File -FilePath $triggerParametersOutputPath -Encoding UTF8
    Write-TestMessage "RÃ©sultats enregistrÃ©s dans: $triggerParametersOutputPath" -Status "INFO"
} else {
    Write-TestMessage "Ã‰chec de l'analyse des paramÃ¨tres de dÃ©clenchement" -Status "ERROR"
}

# GÃ©nÃ©rer un rapport de test
$reportPath = Join-Path -Path $OutputFolder -ChildPath "trigger_analysis_report.md"
$report = @"
# Rapport d'analyse des dÃ©clencheurs de workflow

## Informations gÃ©nÃ©rales
- **Workflow**: $($workflow.name)
- **ID**: $($workflow.id)
- **Actif**: $($workflow.active)
- **Nombre de nÅ“uds**: $($workflow.nodes.Count)

## Conditions de dÃ©clenchement
- **Nombre de dÃ©clencheurs**: $($triggerConditions.Count)

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
    "  - Aucune condition spÃ©cifique"
})
"
    } | Out-String
} else {
    "Aucun dÃ©clencheur trouvÃ© dans le workflow."
})

## Sources d'Ã©vÃ©nements
- **Nombre de sources**: $($eventSources.Count)

$(if ($eventSources.Count -gt 0) {
    $eventSources | ForEach-Object {
        "### $($_.Name) (Type: $($_.SourceType))
- **ID**: $($_.Id)
- **Type**: $($_.Type)
- **DÃ©tails**:
$(if ($_.Details.Count -gt 0) {
    $_.Details.GetEnumerator() | ForEach-Object {
        "  - **$($_.Key)**: $($_.Value)"
    } | Out-String
} else {
    "  - Aucun dÃ©tail spÃ©cifique"
})
"
    } | Out-String
} else {
    "Aucune source d'Ã©vÃ©nements trouvÃ©e dans le workflow."
})

## ParamÃ¨tres de dÃ©clenchement
- **Nombre de dÃ©clencheurs analysÃ©s**: $($triggerParameters.Count)

$(if ($triggerParameters.Count -gt 0) {
    $triggerParameters | ForEach-Object {
        "### $($_.Name) (Type: $($_.TriggerType))
- **ID**: $($_.Id)
- **Type**: $($_.Type)
- **Impact**:
  - **FrÃ©quence**: $($_.Impact.Frequency)
  - **Volume de donnÃ©es**: $($_.Impact.DataVolume)
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
    "Aucun paramÃ¨tre de dÃ©clenchement trouvÃ© dans le workflow."
})
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-TestMessage "Rapport de test gÃ©nÃ©rÃ©: $reportPath" -Status "SUCCESS"

Write-TestMessage "Tests terminÃ©s avec succÃ¨s!" -Status "SUCCESS"

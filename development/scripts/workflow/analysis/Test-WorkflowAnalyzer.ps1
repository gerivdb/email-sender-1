# Script de test pour le module WorkflowAnalyzer
# Ce script teste les fonctionnalitÃ©s du module WorkflowAnalyzer

#Requires -Version 5.1

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "WorkflowAnalyzer.psm1"
Import-Module $modulePath -Force

# Fonction pour afficher un message de test
function Write-TestMessage {
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

# Fonction pour tester le module
function Test-WorkflowAnalyzer {
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = $PSScriptRoot
    )
    
    Write-TestMessage "DÃ©marrage des tests du module WorkflowAnalyzer..."
    
    # VÃ©rifier si le fichier de workflow existe
    if (-not (Test-Path -Path $WorkflowPath)) {
        Write-TestMessage "Le fichier de workflow n'existe pas: $WorkflowPath" -Status "ERROR"
        return
    }
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Test 1: Charger un workflow
    Write-TestMessage "Test 1: Chargement d'un workflow..."
    $workflow = Get-N8nWorkflow -WorkflowPath $WorkflowPath
    
    if ($workflow) {
        Write-TestMessage "Workflow chargÃ© avec succÃ¨s: $($workflow.name)" -Status "SUCCESS"
    }
    else {
        Write-TestMessage "Ã‰chec du chargement du workflow" -Status "ERROR"
        return
    }
    
    # Test 2: DÃ©tecter les activitÃ©s
    Write-TestMessage "Test 2: DÃ©tection des activitÃ©s..."
    $activities = Get-N8nWorkflowActivities -Workflow $workflow -IncludeDetails
    
    if ($activities) {
        Write-TestMessage "ActivitÃ©s dÃ©tectÃ©es avec succÃ¨s: $($activities.Count) activitÃ©s trouvÃ©es" -Status "SUCCESS"
        
        # Afficher quelques activitÃ©s
        Write-TestMessage "Exemples d'activitÃ©s:"
        $activities | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.Name) (Type: $($_.Type), CatÃ©gorie: $($_.Category))"
        }
    }
    else {
        Write-TestMessage "Ã‰chec de la dÃ©tection des activitÃ©s" -Status "ERROR"
    }
    
    # Test 3: Extraire les transitions
    Write-TestMessage "Test 3: Extraction des transitions..."
    $transitions = Get-N8nWorkflowTransitions -Workflow $workflow
    
    if ($transitions) {
        Write-TestMessage "Transitions extraites avec succÃ¨s: $($transitions.Count) transitions trouvÃ©es" -Status "SUCCESS"
        
        # Afficher quelques transitions
        Write-TestMessage "Exemples de transitions:"
        $transitions | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.SourceNodeName) -> $($_.TargetNodeName)"
        }
    }
    else {
        Write-TestMessage "Ã‰chec de l'extraction des transitions" -Status "ERROR"
    }
    
    # Test 4: Analyser les conditions
    Write-TestMessage "Test 4: Analyse des conditions..."
    $conditions = Get-N8nWorkflowConditions -Workflow $workflow -IncludeTransitions
    
    if ($conditions -ne $null) {
        Write-TestMessage "Conditions analysÃ©es avec succÃ¨s: $($conditions.Count) nÅ“uds conditionnels trouvÃ©s" -Status "SUCCESS"
        
        # Afficher quelques conditions
        if ($conditions.Count -gt 0) {
            Write-TestMessage "Exemples de conditions:"
            $conditions | Select-Object -First 3 | ForEach-Object {
                Write-Host "  - $($_.Name) (Type: $($_.Type), Nombre de conditions: $($_.Conditions.Count))"
            }
        }
        else {
            Write-TestMessage "Aucun nÅ“ud conditionnel trouvÃ© dans le workflow" -Status "WARNING"
        }
    }
    else {
        Write-TestMessage "Ã‰chec de l'analyse des conditions" -Status "ERROR"
    }
    
    # Test 5: GÃ©nÃ©rer un rapport
    Write-TestMessage "Test 5: GÃ©nÃ©ration d'un rapport..."
    $outputPath = Join-Path -Path $OutputFolder -ChildPath "workflow_analysis_report.md"
    $report = Get-N8nWorkflowAnalysisReport -WorkflowPath $WorkflowPath -OutputPath $outputPath -Format "Markdown"
    
    if ($report) {
        Write-TestMessage "Rapport gÃ©nÃ©rÃ© avec succÃ¨s: $outputPath" -Status "SUCCESS"
    }
    else {
        Write-TestMessage "Ã‰chec de la gÃ©nÃ©ration du rapport" -Status "ERROR"
    }
    
    # Test 6: GÃ©nÃ©rer un rapport JSON
    Write-TestMessage "Test 6: GÃ©nÃ©ration d'un rapport JSON..."
    $outputPathJson = Join-Path -Path $OutputFolder -ChildPath "workflow_analysis_report.json"
    $reportJson = Get-N8nWorkflowAnalysisReport -WorkflowPath $WorkflowPath -OutputPath $outputPathJson -Format "JSON"
    
    if ($reportJson) {
        Write-TestMessage "Rapport JSON gÃ©nÃ©rÃ© avec succÃ¨s: $outputPathJson" -Status "SUCCESS"
    }
    else {
        Write-TestMessage "Ã‰chec de la gÃ©nÃ©ration du rapport JSON" -Status "ERROR"
    }
    
    Write-TestMessage "Tests terminÃ©s."
}

# VÃ©rifier si le script est exÃ©cutÃ© directement
if ($MyInvocation.InvocationName -ne ".") {
    # Obtenir les arguments de la ligne de commande
    param (
        [Parameter(Mandatory = $false)]
        [string]$WorkflowPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = $PSScriptRoot
    )
    
    # Si aucun chemin de workflow n'est spÃ©cifiÃ©, demander Ã  l'utilisateur
    if (-not $WorkflowPath) {
        Write-Host "Veuillez spÃ©cifier le chemin d'un fichier de workflow n8n Ã  analyser:" -ForegroundColor Cyan
        $WorkflowPath = Read-Host
    }
    
    # ExÃ©cuter les tests
    Test-WorkflowAnalyzer -WorkflowPath $WorkflowPath -OutputFolder $OutputFolder
}

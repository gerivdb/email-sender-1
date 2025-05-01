# Script de test pour le module WorkflowAnalyzer
# Ce script teste les fonctionnalités du module WorkflowAnalyzer

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
    
    Write-TestMessage "Démarrage des tests du module WorkflowAnalyzer..."
    
    # Vérifier si le fichier de workflow existe
    if (-not (Test-Path -Path $WorkflowPath)) {
        Write-TestMessage "Le fichier de workflow n'existe pas: $WorkflowPath" -Status "ERROR"
        return
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Test 1: Charger un workflow
    Write-TestMessage "Test 1: Chargement d'un workflow..."
    $workflow = Get-N8nWorkflow -WorkflowPath $WorkflowPath
    
    if ($workflow) {
        Write-TestMessage "Workflow chargé avec succès: $($workflow.name)" -Status "SUCCESS"
    }
    else {
        Write-TestMessage "Échec du chargement du workflow" -Status "ERROR"
        return
    }
    
    # Test 2: Détecter les activités
    Write-TestMessage "Test 2: Détection des activités..."
    $activities = Get-N8nWorkflowActivities -Workflow $workflow -IncludeDetails
    
    if ($activities) {
        Write-TestMessage "Activités détectées avec succès: $($activities.Count) activités trouvées" -Status "SUCCESS"
        
        # Afficher quelques activités
        Write-TestMessage "Exemples d'activités:"
        $activities | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.Name) (Type: $($_.Type), Catégorie: $($_.Category))"
        }
    }
    else {
        Write-TestMessage "Échec de la détection des activités" -Status "ERROR"
    }
    
    # Test 3: Extraire les transitions
    Write-TestMessage "Test 3: Extraction des transitions..."
    $transitions = Get-N8nWorkflowTransitions -Workflow $workflow
    
    if ($transitions) {
        Write-TestMessage "Transitions extraites avec succès: $($transitions.Count) transitions trouvées" -Status "SUCCESS"
        
        # Afficher quelques transitions
        Write-TestMessage "Exemples de transitions:"
        $transitions | Select-Object -First 3 | ForEach-Object {
            Write-Host "  - $($_.SourceNodeName) -> $($_.TargetNodeName)"
        }
    }
    else {
        Write-TestMessage "Échec de l'extraction des transitions" -Status "ERROR"
    }
    
    # Test 4: Analyser les conditions
    Write-TestMessage "Test 4: Analyse des conditions..."
    $conditions = Get-N8nWorkflowConditions -Workflow $workflow -IncludeTransitions
    
    if ($conditions -ne $null) {
        Write-TestMessage "Conditions analysées avec succès: $($conditions.Count) nœuds conditionnels trouvés" -Status "SUCCESS"
        
        # Afficher quelques conditions
        if ($conditions.Count -gt 0) {
            Write-TestMessage "Exemples de conditions:"
            $conditions | Select-Object -First 3 | ForEach-Object {
                Write-Host "  - $($_.Name) (Type: $($_.Type), Nombre de conditions: $($_.Conditions.Count))"
            }
        }
        else {
            Write-TestMessage "Aucun nœud conditionnel trouvé dans le workflow" -Status "WARNING"
        }
    }
    else {
        Write-TestMessage "Échec de l'analyse des conditions" -Status "ERROR"
    }
    
    # Test 5: Générer un rapport
    Write-TestMessage "Test 5: Génération d'un rapport..."
    $outputPath = Join-Path -Path $OutputFolder -ChildPath "workflow_analysis_report.md"
    $report = Get-N8nWorkflowAnalysisReport -WorkflowPath $WorkflowPath -OutputPath $outputPath -Format "Markdown"
    
    if ($report) {
        Write-TestMessage "Rapport généré avec succès: $outputPath" -Status "SUCCESS"
    }
    else {
        Write-TestMessage "Échec de la génération du rapport" -Status "ERROR"
    }
    
    # Test 6: Générer un rapport JSON
    Write-TestMessage "Test 6: Génération d'un rapport JSON..."
    $outputPathJson = Join-Path -Path $OutputFolder -ChildPath "workflow_analysis_report.json"
    $reportJson = Get-N8nWorkflowAnalysisReport -WorkflowPath $WorkflowPath -OutputPath $outputPathJson -Format "JSON"
    
    if ($reportJson) {
        Write-TestMessage "Rapport JSON généré avec succès: $outputPathJson" -Status "SUCCESS"
    }
    else {
        Write-TestMessage "Échec de la génération du rapport JSON" -Status "ERROR"
    }
    
    Write-TestMessage "Tests terminés."
}

# Vérifier si le script est exécuté directement
if ($MyInvocation.InvocationName -ne ".") {
    # Obtenir les arguments de la ligne de commande
    param (
        [Parameter(Mandatory = $false)]
        [string]$WorkflowPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFolder = $PSScriptRoot
    )
    
    # Si aucun chemin de workflow n'est spécifié, demander à l'utilisateur
    if (-not $WorkflowPath) {
        Write-Host "Veuillez spécifier le chemin d'un fichier de workflow n8n à analyser:" -ForegroundColor Cyan
        $WorkflowPath = Read-Host
    }
    
    # Exécuter les tests
    Test-WorkflowAnalyzer -WorkflowPath $WorkflowPath -OutputFolder $OutputFolder
}

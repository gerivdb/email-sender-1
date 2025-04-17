#Requires -Version 5.1
<#
.SYNOPSIS
    Valide tous les workflows n8n du projet.
.DESCRIPTION
    Ce script valide tous les workflows n8n du projet pour détecter les cycles,
    les nœuds manquants, et autres problèmes potentiels.
.PARAMETER WorkflowsPath
    Chemin du dossier contenant les workflows n8n.
.PARAMETER ReportsPath
    Chemin du dossier pour les rapports de validation.
.PARAMETER FixIssues
    Tente de corriger automatiquement les problèmes détectés.
.PARAMETER GenerateReport
    Génère un rapport HTML détaillé.
.EXAMPLE
    .\Validate-AllWorkflows.ps1 -WorkflowsPath ".\workflows" -ReportsPath ".\reports\workflows" -GenerateReport
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-17
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$WorkflowsPath = ".\workflows",
    
    [Parameter(Mandatory = $false)]
    [string]$ReportsPath = ".\reports\workflows",
    
    [Parameter(Mandatory = $false)]
    [switch]$FixIssues,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport
)

# Importer le module de détection de cycles
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\modules\CycleDetector.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module de détection de cycles introuvable: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour écrire dans le journal
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        "TITLE" { "Cyan" }
    }
    
    Write-Host "[$timestamp] " -NoNewline
    Write-Host "[$Level] " -NoNewline -ForegroundColor $color
    Write-Host $Message
}

# Fonction pour valider un workflow n8n
function Test-N8nWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowPath
    )
    
    Write-Log "Validation du workflow: $WorkflowPath" -Level "INFO"
    
    $issues = @()
    
    try {
        # Charger le workflow
        $workflow = Get-Content -Path $WorkflowPath -Raw | ConvertFrom-Json
        
        # Vérifier si le workflow a des nœuds et des connexions
        if (-not $workflow.nodes -or -not $workflow.connections) {
            $issues += [PSCustomObject]@{
                Type = "StructureError"
                Description = "Le workflow ne contient pas de nœuds ou de connexions"
                Severity = "High"
                CanFix = $false
            }
            
            return $issues
        }
        
        # Vérifier les cycles
        $hasCycles = -not (Test-N8nWorkflowCycles -WorkflowPath $WorkflowPath)
        
        if ($hasCycles) {
            $issues += [PSCustomObject]@{
                Type = "CycleDetected"
                Description = "Des cycles ont été détectés dans le workflow"
                Severity = "High"
                CanFix = $true
            }
        }
        
        # Vérifier les nœuds manquants dans les connexions
        $nodeIds = $workflow.nodes | ForEach-Object { $_.id }
        
        foreach ($sourceId in $workflow.connections.PSObject.Properties.Name) {
            if ($sourceId -notin $nodeIds) {
                $issues += [PSCustomObject]@{
                    Type = "MissingNode"
                    Description = "Connexion depuis un nœud inexistant: $sourceId"
                    Severity = "High"
                    CanFix = $true
                    NodeId = $sourceId
                }
            }
            
            $connections = $workflow.connections.$sourceId
            
            if ($connections.main) {
                foreach ($outputIndex in 0..($connections.main.Count - 1)) {
                    $targets = $connections.main[$outputIndex]
                    
                    foreach ($target in $targets) {
                        $targetId = $target.node
                        
                        if ($targetId -notin $nodeIds) {
                            $issues += [PSCustomObject]@{
                                Type = "MissingNode"
                                Description = "Connexion vers un nœud inexistant: $targetId (depuis $sourceId)"
                                Severity = "High"
                                CanFix = $true
                                NodeId = $targetId
                                SourceId = $sourceId
                                OutputIndex = $outputIndex
                                InputIndex = $target.index
                            }
                        }
                    }
                }
            }
        }
        
        # Vérifier les nœuds isolés (sans connexions)
        foreach ($node in $workflow.nodes) {
            $nodeId = $node.id
            $hasIncomingConnections = $false
            $hasOutgoingConnections = $false
            
            # Vérifier les connexions sortantes
            if ($workflow.connections.$nodeId) {
                $hasOutgoingConnections = $true
            }
            
            # Vérifier les connexions entrantes
            foreach ($sourceId in $workflow.connections.PSObject.Properties.Name) {
                $connections = $workflow.connections.$sourceId
                
                if ($connections.main) {
                    foreach ($outputIndex in 0..($connections.main.Count - 1)) {
                        $targets = $connections.main[$outputIndex]
                        
                        foreach ($target in $targets) {
                            if ($target.node -eq $nodeId) {
                                $hasIncomingConnections = $true
                                break
                            }
                        }
                        
                        if ($hasIncomingConnections) {
                            break
                        }
                    }
                }
                
                if ($hasIncomingConnections) {
                    break
                }
            }
            
            if (-not $hasIncomingConnections -and -not $hasOutgoingConnections) {
                $issues += [PSCustomObject]@{
                    Type = "IsolatedNode"
                    Description = "Nœud isolé (sans connexions): $nodeId ($($node.name))"
                    Severity = "Medium"
                    CanFix = $true
                    NodeId = $nodeId
                }
            }
        }
        
        # Vérifier les nœuds de début manquants
        $startNodes = $workflow.nodes | Where-Object { $_.type -like "*start*" -or $_.type -like "*trigger*" }
        
        if ($startNodes.Count -eq 0) {
            $issues += [PSCustomObject]@{
                Type = "MissingStartNode"
                Description = "Aucun nœud de début ou déclencheur trouvé dans le workflow"
                Severity = "Medium"
                CanFix = $false
            }
        }
        
        # Vérifier les nœuds avec des paramètres manquants
        foreach ($node in $workflow.nodes) {
            if ($node.parameters) {
                # Vérifier les paramètres requis selon le type de nœud
                # (Cette partie nécessiterait une connaissance spécifique des types de nœuds n8n)
            }
        }
    }
    catch {
        $issues += [PSCustomObject]@{
            Type = "ParseError"
            Description = "Erreur lors de l'analyse du workflow: $_"
            Severity = "Critical"
            CanFix = $false
        }
    }
    
    return $issues
}

# Fonction pour corriger les problèmes d'un workflow
function Repair-N8nWorkflow {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowPath,
        
        [Parameter(Mandatory = $true)]
        [array]$Issues
    )
    
    Write-Log "Correction du workflow: $WorkflowPath" -Level "INFO"
    
    # Vérifier s'il y a des problèmes à corriger
    $fixableIssues = $Issues | Where-Object { $_.CanFix }
    
    if ($fixableIssues.Count -eq 0) {
        Write-Log "Aucun problème corrigible trouvé." -Level "INFO"
        return $false
    }
    
    try {
        # Charger le workflow
        $workflow = Get-Content -Path $WorkflowPath -Raw | ConvertFrom-Json
        
        # Créer une copie de sauvegarde
        $backupPath = "$WorkflowPath.bak"
        Copy-Item -Path $WorkflowPath -Destination $backupPath -Force
        
        $modified = $false
        
        # Corriger les problèmes
        foreach ($issue in $fixableIssues) {
            switch ($issue.Type) {
                "CycleDetected" {
                    # Utiliser le script Validate-WorkflowCycles.ps1 pour corriger les cycles
                    $validateScript = Join-Path -Path $PSScriptRoot -ChildPath "Validate-WorkflowCycles.ps1"
                    
                    if (Test-Path -Path $validateScript) {
                        & $validateScript -WorkflowsPath $WorkflowPath -FixCycles
                        $modified = $true
                        Write-Log "Cycles corrigés dans le workflow." -Level "SUCCESS"
                    }
                    else {
                        Write-Log "Script de validation des cycles introuvable: $validateScript" -Level "ERROR"
                    }
                }
                "MissingNode" {
                    if ($issue.SourceId -and $issue.NodeId) {
                        # Supprimer la connexion vers le nœud manquant
                        $connections = $workflow.connections.$($issue.SourceId).main[$issue.OutputIndex]
                        $newConnections = $connections | Where-Object { $_.node -ne $issue.NodeId }
                        $workflow.connections.$($issue.SourceId).main[$issue.OutputIndex] = $newConnections
                        
                        $modified = $true
                        Write-Log "Connexion vers le nœud manquant supprimée: $($issue.SourceId) -> $($issue.NodeId)" -Level "SUCCESS"
                    }
                    elseif ($issue.NodeId) {
                        # Supprimer toutes les connexions depuis le nœud manquant
                        $workflow.connections.PSObject.Properties.Remove($issue.NodeId)
                        
                        $modified = $true
                        Write-Log "Connexions depuis le nœud manquant supprimées: $($issue.NodeId)" -Level "SUCCESS"
                    }
                }
                "IsolatedNode" {
                    # Supprimer le nœud isolé
                    $workflow.nodes = $workflow.nodes | Where-Object { $_.id -ne $issue.NodeId }
                    
                    $modified = $true
                    Write-Log "Nœud isolé supprimé: $($issue.NodeId)" -Level "SUCCESS"
                }
            }
        }
        
        # Enregistrer les modifications
        if ($modified) {
            $workflow | ConvertTo-Json -Depth 10 | Out-File -FilePath $WorkflowPath -Encoding utf8
            Write-Log "Workflow corrigé et enregistré: $WorkflowPath (sauvegarde: $backupPath)" -Level "SUCCESS"
            return $true
        }
        else {
            Write-Log "Aucune modification apportée au workflow." -Level "INFO"
            Remove-Item -Path $backupPath -Force
            return $false
        }
    }
    catch {
        Write-Log "Erreur lors de la correction du workflow: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour générer un rapport HTML
function New-ValidationReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Results,
        
        [Parameter(Mandatory = $true)]
        [string]$ReportPath
    )
    
    $totalWorkflows = $Results.Count
    $workflowsWithIssues = ($Results | Where-Object { $_.Issues.Count -gt 0 }).Count
    $totalIssues = ($Results | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum).Sum
    $fixedWorkflows = ($Results | Where-Object { $_.Fixed }).Count
    
    $html = @"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Rapport de validation des workflows n8n</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 0;
            padding: 20px;
            color: #333;
        }
        h1, h2, h3 {
            color: #0066cc;
        }
        .summary {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 5px;
            margin-bottom: 20px;
        }
        .workflow {
            background-color: #fff;
            border: 1px solid #ddd;
            border-radius: 5px;
            padding: 15px;
            margin-bottom: 20px;
        }
        .workflow-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 10px;
        }
        .workflow-title {
            margin: 0;
        }
        .workflow-status {
            font-weight: bold;
            padding: 5px 10px;
            border-radius: 3px;
        }
        .status-ok {
            background-color: #2ecc71;
            color: white;
        }
        .status-warning {
            background-color: #f39c12;
            color: white;
        }
        .status-error {
            background-color: #e74c3c;
            color: white;
        }
        .issues {
            margin-top: 10px;
        }
        .issue {
            background-color: #f9f9f9;
            border-left: 4px solid #ddd;
            padding: 10px;
            margin-bottom: 10px;
        }
        .issue-critical {
            border-left-color: #e74c3c;
        }
        .issue-high {
            border-left-color: #f39c12;
        }
        .issue-medium {
            border-left-color: #3498db;
        }
        .issue-low {
            border-left-color: #2ecc71;
        }
        .fixed {
            background-color: #eafaf1;
            border: 1px solid #2ecc71;
            padding: 5px 10px;
            border-radius: 3px;
            color: #27ae60;
            font-weight: bold;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 20px;
        }
        th, td {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
        }
        th {
            background-color: #0066cc;
            color: white;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        .timestamp {
            color: #666;
            font-style: italic;
            margin-top: 20px;
        }
    </style>
</head>
<body>
    <h1>Rapport de validation des workflows n8n</h1>
    
    <div class="summary">
        <h2>Résumé</h2>
        <p>Workflows analysés: <strong>$totalWorkflows</strong></p>
        <p>Workflows avec problèmes: <strong>$workflowsWithIssues</strong></p>
        <p>Problèmes détectés: <strong>$totalIssues</strong></p>
        <p>Workflows corrigés: <strong>$fixedWorkflows</strong></p>
    </div>
    
    <h2>Détails des workflows</h2>
"@
    
    foreach ($result in $Results) {
        $workflowName = [System.IO.Path]::GetFileName($result.Path)
        $issuesCount = $result.Issues.Count
        $status = if ($issuesCount -eq 0) { "OK" } elseif ($result.Fixed) { "Corrigé" } else { "Problèmes" }
        $statusClass = if ($issuesCount -eq 0) { "status-ok" } elseif ($result.Fixed) { "status-warning" } else { "status-error" }
        
        $html += @"
    <div class="workflow">
        <div class="workflow-header">
            <h3 class="workflow-title">$workflowName</h3>
            <span class="workflow-status $statusClass">$status</span>
        </div>
        <p>Chemin: $($result.Path)</p>
"@
        
        if ($result.Fixed) {
            $html += @"
        <p class="fixed">Workflow corrigé automatiquement</p>
"@
        }
        
        if ($issuesCount -gt 0) {
            $html += @"
        <div class="issues">
            <h4>Problèmes détectés ($issuesCount)</h4>
"@
            
            foreach ($issue in $result.Issues) {
                $issueClass = "issue-$($issue.Severity.ToLower())"
                
                $html += @"
            <div class="issue $issueClass">
                <p><strong>Type:</strong> $($issue.Type)</p>
                <p><strong>Description:</strong> $($issue.Description)</p>
                <p><strong>Sévérité:</strong> $($issue.Severity)</p>
                <p><strong>Corrigible:</strong> $($issue.CanFix)</p>
            </div>
"@
            }
            
            $html += @"
        </div>
"@
        }
        
        $html += @"
    </div>
"@
    }
    
    $html += @"
    
    <p class="timestamp">Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
</body>
</html>
"@
    
    # Créer le dossier de sortie s'il n'existe pas
    $outputDir = [System.IO.Path]::GetDirectoryName($ReportPath)
    
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Enregistrer le rapport
    $html | Out-File -FilePath $ReportPath -Encoding utf8
    
    Write-Log "Rapport généré: $ReportPath" -Level "SUCCESS"
}

# Fonction principale
function Start-WorkflowValidation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$WorkflowsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$ReportsPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$FixIssues,
        
        [Parameter(Mandatory = $false)]
        [switch]$GenerateReport
    )
    
    Write-Log "Démarrage de la validation des workflows n8n..." -Level "TITLE"
    Write-Log "Dossier des workflows: $WorkflowsPath"
    Write-Log "Dossier des rapports: $ReportsPath"
    
    # Vérifier si le dossier des workflows existe
    if (-not (Test-Path -Path $WorkflowsPath)) {
        Write-Log "Le dossier des workflows n'existe pas: $WorkflowsPath" -Level "ERROR"
        return
    }
    
    # Créer le dossier des rapports s'il n'existe pas
    if (-not (Test-Path -Path $ReportsPath)) {
        New-Item -Path $ReportsPath -ItemType Directory -Force | Out-Null
    }
    
    # Obtenir les fichiers de workflow
    $workflowFiles = Get-ChildItem -Path $WorkflowsPath -Filter "*.json" -Recurse
    
    Write-Log "Nombre de fichiers JSON trouvés: $($workflowFiles.Count)"
    
    # Filtrer pour ne garder que les workflows n8n
    $n8nWorkflows = @()
    
    foreach ($file in $workflowFiles) {
        try {
            $content = Get-Content -Path $file.FullName -Raw
            $json = ConvertFrom-Json -InputObject $content -ErrorAction Stop
            
            # Vérifier si c'est un workflow n8n
            if ($json.nodes -and $json.connections) {
                $n8nWorkflows += $file
            }
        }
        catch {
            Write-Log "Erreur lors de l'analyse du fichier JSON: $($file.FullName)" -Level "WARNING"
        }
    }
    
    Write-Log "Nombre de workflows n8n identifiés: $($n8nWorkflows.Count)"
    
    # Valider les workflows
    $results = @()
    
    foreach ($workflow in $n8nWorkflows) {
        Write-Log "Validation du workflow: $($workflow.FullName)" -Level "INFO"
        
        $issues = Test-N8nWorkflow -WorkflowPath $workflow.FullName
        
        if ($issues.Count -gt 0) {
            Write-Log "Problèmes détectés: $($issues.Count)" -Level "WARNING"
            
            foreach ($issue in $issues) {
                Write-Log "- $($issue.Type): $($issue.Description)" -Level "WARNING"
            }
            
            $fixed = $false
            
            if ($FixIssues) {
                $fixed = Repair-N8nWorkflow -WorkflowPath $workflow.FullName -Issues $issues
            }
        }
        else {
            Write-Log "Aucun problème détecté." -Level "SUCCESS"
        }
        
        $results += [PSCustomObject]@{
            Path = $workflow.FullName
            Name = $workflow.Name
            Issues = $issues
            Fixed = if ($FixIssues -and $issues.Count -gt 0) { $fixed } else { $false }
        }
    }
    
    # Générer le rapport JSON
    $reportJson = [PSCustomObject]@{
        GeneratedAt = (Get-Date).ToString("o")
        WorkflowsPath = $WorkflowsPath
        TotalWorkflows = $n8nWorkflows.Count
        WorkflowsWithIssues = ($results | Where-Object { $_.Issues.Count -gt 0 }).Count
        FixedWorkflows = ($results | Where-Object { $_.Fixed }).Count
        Results = $results
    }
    
    $jsonReportPath = Join-Path -Path $ReportsPath -ChildPath "workflow_validation_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $reportJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonReportPath -Encoding utf8
    
    Write-Log "Rapport JSON généré: $jsonReportPath" -Level "SUCCESS"
    
    # Générer le rapport HTML si demandé
    if ($GenerateReport) {
        $htmlReportPath = Join-Path -Path $ReportsPath -ChildPath "workflow_validation_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        New-ValidationReport -Results $results -ReportPath $htmlReportPath
    }
    
    # Afficher le résumé
    $workflowsWithIssues = ($results | Where-Object { $_.Issues.Count -gt 0 }).Count
    $totalIssues = ($results | ForEach-Object { $_.Issues.Count } | Measure-Object -Sum).Sum
    $fixedWorkflows = ($results | Where-Object { $_.Fixed }).Count
    
    Write-Log "Résumé:" -Level "TITLE"
    Write-Log "Workflows analysés: $($n8nWorkflows.Count)"
    Write-Log "Workflows avec problèmes: $workflowsWithIssues"
    Write-Log "Problèmes détectés: $totalIssues"
    
    if ($FixIssues) {
        Write-Log "Workflows corrigés: $fixedWorkflows"
    }
    
    return $reportJson
}

# Exécuter la fonction principale
Start-WorkflowValidation -WorkflowsPath $WorkflowsPath -ReportsPath $ReportsPath -FixIssues:$FixIssues -GenerateReport:$GenerateReport

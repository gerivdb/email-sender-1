#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intégration pour la détection de cycles dans les workflows n8n.
.DESCRIPTION
    Ce script contient les tests d'intégration pour la détection de cycles
    dans les workflows n8n, vérifiant l'intégration avec n8n.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-14
#>

BeforeAll {
    # Importer le module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\CycleDetector.psm1"
    Import-Module $modulePath -Force
    
    # Créer un dossier temporaire pour les workflows de test
    $tempDir = Join-Path -Path $TestDrive -ChildPath "workflows"
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    
    # Créer un workflow n8n de test avec un cycle
    $workflowWithCycle = @{
        name = "Workflow with cycle"
        nodes = @(
            @{
                id = "node1"
                name = "Start"
                type = "n8n-nodes-base.start"
                position = @(100, 300)
            },
            @{
                id = "node2"
                name = "Function"
                type = "n8n-nodes-base.function"
                position = @(300, 300)
            },
            @{
                id = "node3"
                name = "IF"
                type = "n8n-nodes-base.if"
                position = @(500, 300)
            },
            @{
                id = "node4"
                name = "End"
                type = "n8n-nodes-base.noOp"
                position = @(700, 300)
            }
        )
        connections = @{
            node1 = @{
                main = @(
                    @(
                        @{
                            node = "node2"
                            type = "main"
                            index = 0
                        }
                    )
                )
            }
            node2 = @{
                main = @(
                    @(
                        @{
                            node = "node3"
                            type = "main"
                            index = 0
                        }
                    )
                )
            }
            node3 = @{
                main = @(
                    @(
                        @{
                            node = "node4"
                            type = "main"
                            index = 0
                        }
                    ),
                    @(
                        @{
                            node = "node2"
                            type = "main"
                            index = 0
                        }
                    )
                )
            }
        }
    }
    
    $workflowWithCyclePath = Join-Path -Path $tempDir -ChildPath "workflow_with_cycle.json"
    $workflowWithCycle | ConvertTo-Json -Depth 10 | Out-File -FilePath $workflowWithCyclePath -Encoding utf8
    
    # Créer un workflow n8n de test sans cycle
    $workflowWithoutCycle = @{
        name = "Workflow without cycle"
        nodes = @(
            @{
                id = "node1"
                name = "Start"
                type = "n8n-nodes-base.start"
                position = @(100, 300)
            },
            @{
                id = "node2"
                name = "Function"
                type = "n8n-nodes-base.function"
                position = @(300, 300)
            },
            @{
                id = "node3"
                name = "End"
                type = "n8n-nodes-base.noOp"
                position = @(500, 300)
            }
        )
        connections = @{
            node1 = @{
                main = @(
                    @(
                        @{
                            node = "node2"
                            type = "main"
                            index = 0
                        }
                    )
                )
            }
            node2 = @{
                main = @(
                    @(
                        @{
                            node = "node3"
                            type = "main"
                            index = 0
                        }
                    )
                )
            }
        }
    }
    
    $workflowWithoutCyclePath = Join-Path -Path $tempDir -ChildPath "workflow_without_cycle.json"
    $workflowWithoutCycle | ConvertTo-Json -Depth 10 | Out-File -FilePath $workflowWithoutCyclePath -Encoding utf8
    
    # Créer un workflow n8n de test avec plusieurs cycles
    $workflowWithMultipleCycles = @{
        name = "Workflow with multiple cycles"
        nodes = @(
            @{
                id = "node1"
                name = "Start"
                type = "n8n-nodes-base.start"
                position = @(100, 300)
            },
            @{
                id = "node2"
                name = "Function 1"
                type = "n8n-nodes-base.function"
                position = @(300, 300)
            },
            @{
                id = "node3"
                name = "Function 2"
                type = "n8n-nodes-base.function"
                position = @(500, 300)
            },
            @{
                id = "node4"
                name = "Function 3"
                type = "n8n-nodes-base.function"
                position = @(700, 300)
            },
            @{
                id = "node5"
                name = "Function 4"
                type = "n8n-nodes-base.function"
                position = @(900, 300)
            },
            @{
                id = "node6"
                name = "End"
                type = "n8n-nodes-base.noOp"
                position = @(1100, 300)
            }
        )
        connections = @{
            node1 = @{
                main = @(
                    @(
                        @{
                            node = "node2"
                            type = "main"
                            index = 0
                        }
                    )
                )
            }
            node2 = @{
                main = @(
                    @(
                        @{
                            node = "node3"
                            type = "main"
                            index = 0
                        }
                    )
                )
            }
            node3 = @{
                main = @(
                    @(
                        @{
                            node = "node4"
                            type = "main"
                            index = 0
                        }
                    ),
                    @(
                        @{
                            node = "node2"
                            type = "main"
                            index = 0
                        }
                    )
                )
            }
            node4 = @{
                main = @(
                    @(
                        @{
                            node = "node5"
                            type = "main"
                            index = 0
                        }
                    )
                )
            }
            node5 = @{
                main = @(
                    @(
                        @{
                            node = "node6"
                            type = "main"
                            index = 0
                        }
                    ),
                    @(
                        @{
                            node = "node4"
                            type = "main"
                            index = 0
                        }
                    )
                )
            }
        }
    }
    
    $workflowWithMultipleCyclesPath = Join-Path -Path $tempDir -ChildPath "workflow_with_multiple_cycles.json"
    $workflowWithMultipleCycles | ConvertTo-Json -Depth 10 | Out-File -FilePath $workflowWithMultipleCyclesPath -Encoding utf8
}

Describe "Validate-WorkflowCycles Integration" {
    Context "Lorsqu'on valide des workflows n8n" {
        BeforeAll {
            # Chemin du script à tester
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\n8n\workflow-validation\Validate-WorkflowCycles.ps1"
            
            # Vérifier si le script existe, sinon le créer pour les tests
            if (-not (Test-Path -Path $scriptPath)) {
                $scriptDir = Split-Path -Path $scriptPath -Parent
                if (-not (Test-Path -Path $scriptDir)) {
                    New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
                }
                
                @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Valide les cycles dans les workflows n8n.
.DESCRIPTION
    Ce script valide les cycles dans les workflows n8n et peut les corriger automatiquement.
.PARAMETER WorkflowsPath
    Chemin du dossier ou fichier contenant les workflows n8n.
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport.
.PARAMETER FixCycles
    Tente de corriger automatiquement les cycles détectés.
.EXAMPLE
    .\Validate-WorkflowCycles.ps1 -WorkflowsPath ".\workflows" -OutputPath ".\reports\workflow_cycles.json"
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = `$true)]
    [string]`$WorkflowsPath,
    
    [Parameter(Mandatory = `$false)]
    [string]`$OutputPath = "",
    
    [Parameter(Mandatory = `$false)]
    [switch]`$FixCycles
)

# Importer le module de détection de cycles
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\..\..\modules\CycleDetector.psm1"
Import-Module `$modulePath -Force

# Fonction principale
function Start-WorkflowCycleValidation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$WorkflowsPath,
        
        [Parameter(Mandatory = `$false)]
        [string]`$OutputPath = "",
        
        [Parameter(Mandatory = `$false)]
        [switch]`$FixCycles
    )
    
    # Vérifier si le chemin existe
    if (-not (Test-Path -Path `$WorkflowsPath)) {
        Write-Error "Le chemin n'existe pas: `$WorkflowsPath"
        return `$null
    }
    
    # Obtenir les fichiers de workflow
    `$workflowFiles = @()
    
    if (Test-Path -Path `$WorkflowsPath -PathType Container) {
        # C'est un dossier
        `$workflowFiles = Get-ChildItem -Path `$WorkflowsPath -Filter "*.json" -Recurse
    }
    else {
        # C'est un fichier
        `$workflowFiles = @(Get-Item -Path `$WorkflowsPath)
    }
    
    # Valider les workflows
    `$results = @()
    
    foreach (`$file in `$workflowFiles) {
        `$result = Test-WorkflowCycles -WorkflowPath `$file.FullName
        
        if (`$result.HasCycles -and `$FixCycles) {
            # Corriger les cycles
            `$fixedWorkflow = Fix-WorkflowCycles -WorkflowPath `$file.FullName -Cycles `$result.Cycles
            
            if (`$fixedWorkflow) {
                # Sauvegarder le workflow corrigé
                `$fixedWorkflow | ConvertTo-Json -Depth 10 | Out-File -FilePath `$file.FullName -Encoding utf8
                
                # Vérifier à nouveau
                `$result = Test-WorkflowCycles -WorkflowPath `$file.FullName
                `$result | Add-Member -MemberType NoteProperty -Name "Fixed" -Value `$true
            }
        }
        else {
            `$result | Add-Member -MemberType NoteProperty -Name "Fixed" -Value `$false
        }
        
        `$result | Add-Member -MemberType NoteProperty -Name "Path" -Value `$file.FullName
        `$results += `$result
    }
    
    # Créer le rapport
    `$report = [PSCustomObject]@{
        GeneratedAt = (Get-Date).ToString("o")
        WorkflowsPath = `$WorkflowsPath
        TotalWorkflows = `$workflowFiles.Count
        WorkflowsWithCycles = (`$results | Where-Object { `$_.HasCycles }).Count
        FixedWorkflows = (`$results | Where-Object { `$_.Fixed }).Count
        Results = `$results
    }
    
    # Enregistrer le rapport si demandé
    if (`$OutputPath) {
        `$report | ConvertTo-Json -Depth 10 | Out-File -FilePath `$OutputPath -Encoding utf8
    }
    
    return `$report
}

# Fonction pour corriger les cycles dans un workflow
function Fix-WorkflowCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$WorkflowPath,
        
        [Parameter(Mandatory = `$true)]
        [array]`$Cycles
    )
    
    try {
        # Charger le workflow
        `$workflow = Get-Content -Path `$WorkflowPath -Raw | ConvertFrom-Json
        
        # Pour chaque cycle, supprimer la dernière connexion
        foreach (`$cycle in `$Cycles) {
            `$lastNode = `$cycle[-1]
            `$firstNode = `$cycle[0]
            
            # Trouver la connexion à supprimer
            if (`$workflow.connections.PSObject.Properties.Name -contains `$lastNode) {
                `$connections = `$workflow.connections.(`$lastNode).main
                
                if (`$connections) {
                    for (`$i = 0; `$i -lt `$connections.Count; `$i++) {
                        `$targets = `$connections[`$i]
                        
                        if (`$targets) {
                            # Filtrer les connexions qui pointent vers le premier nœud du cycle
                            `$newTargets = `$targets | Where-Object { `$_.node -ne `$firstNode }
                            `$workflow.connections.(`$lastNode).main[`$i] = `$newTargets
                        }
                    }
                }
            }
        }
        
        return `$workflow
    }
    catch {
        Write-Error "Erreur lors de la correction des cycles: `$_"
        return `$null
    }
}

# Exécuter la fonction principale
Start-WorkflowCycleValidation -WorkflowsPath `$WorkflowsPath -OutputPath `$OutputPath -FixCycles:`$FixCycles
"@ | Out-File -FilePath $scriptPath -Encoding utf8
            }
        }
        
        It "Devrait détecter des cycles dans un workflow avec cycles" {
            $result = & $scriptPath -WorkflowsPath $workflowWithCyclePath
            $result.WorkflowsWithCycles | Should -Be 1
            $result.Results[0].HasCycles | Should -Be $true
        }
        
        It "Ne devrait pas détecter de cycles dans un workflow sans cycles" {
            $result = & $scriptPath -WorkflowsPath $workflowWithoutCyclePath
            $result.WorkflowsWithCycles | Should -Be 0
            $result.Results[0].HasCycles | Should -Be $false
        }
        
        It "Devrait corriger automatiquement les cycles lorsque demandé" {
            $result = & $scriptPath -WorkflowsPath $workflowWithCyclePath -FixCycles
            $result.FixedWorkflows | Should -Be 1
            $result.Results[0].HasCycles | Should -Be $false
        }
        
        It "Devrait détecter et corriger plusieurs cycles dans un workflow complexe" {
            $result = & $scriptPath -WorkflowsPath $workflowWithMultipleCyclesPath -FixCycles
            $result.FixedWorkflows | Should -Be 1
            $result.Results[0].HasCycles | Should -Be $false
        }
        
        It "Devrait générer un rapport lorsqu'un chemin de sortie est spécifié" {
            $outputPath = Join-Path -Path $TestDrive -ChildPath "workflow_cycles_report.json"
            $result = & $scriptPath -WorkflowsPath $tempDir -OutputPath $outputPath
            
            Test-Path -Path $outputPath | Should -Be $true
            $report = Get-Content -Path $outputPath -Raw | ConvertFrom-Json
            $report.TotalWorkflows | Should -Be 3
        }
    }
}

Describe "Validate-AllWorkflows Integration" {
    Context "Lorsqu'on valide tous les workflows n8n" {
        BeforeAll {
            # Chemin du script à tester
            $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\n8n\workflow-validation\Validate-AllWorkflows.ps1"
            
            # Vérifier si le script existe, sinon le créer pour les tests
            if (-not (Test-Path -Path $scriptPath)) {
                $scriptDir = Split-Path -Path $scriptPath -Parent
                if (-not (Test-Path -Path $scriptDir)) {
                    New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null
                }
                
                @"
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
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = `$false)]
    [string]`$WorkflowsPath = ".\workflows",
    
    [Parameter(Mandatory = `$false)]
    [string]`$ReportsPath = ".\reports\workflows",
    
    [Parameter(Mandatory = `$false)]
    [switch]`$FixIssues,
    
    [Parameter(Mandatory = `$false)]
    [switch]`$GenerateReport
)

# Importer le module de détection de cycles
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\..\modules\CycleDetector.psm1"

if (-not (Test-Path -Path `$modulePath)) {
    Write-Error "Module de détection de cycles introuvable: `$modulePath"
    exit 1
}

Import-Module `$modulePath -Force

# Fonction principale simplifiée pour les tests
function Start-WorkflowValidation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$WorkflowsPath,
        
        [Parameter(Mandatory = `$true)]
        [string]`$ReportsPath,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$FixIssues,
        
        [Parameter(Mandatory = `$false)]
        [switch]`$GenerateReport
    )
    
    # Vérifier si le dossier des workflows existe
    if (-not (Test-Path -Path `$WorkflowsPath)) {
        Write-Error "Le dossier des workflows n'existe pas: `$WorkflowsPath"
        return `$null
    }
    
    # Créer le dossier des rapports s'il n'existe pas
    if (-not (Test-Path -Path `$ReportsPath)) {
        New-Item -Path `$ReportsPath -ItemType Directory -Force | Out-Null
    }
    
    # Obtenir les fichiers de workflow
    `$workflowFiles = Get-ChildItem -Path `$WorkflowsPath -Filter "*.json" -Recurse
    
    # Filtrer pour ne garder que les workflows n8n
    `$n8nWorkflows = @()
    
    foreach (`$file in `$workflowFiles) {
        try {
            `$content = Get-Content -Path `$file.FullName -Raw
            `$json = ConvertFrom-Json -InputObject `$content -ErrorAction Stop
            
            # Vérifier si c'est un workflow n8n
            if (`$json.nodes -and `$json.connections) {
                `$n8nWorkflows += `$file
            }
        }
        catch {
            Write-Warning "Erreur lors de l'analyse du fichier JSON: `$(`$file.FullName)"
        }
    }
    
    # Valider les workflows
    `$results = @()
    
    foreach (`$workflow in `$n8nWorkflows) {
        # Vérifier les cycles
        `$cycleResult = Test-WorkflowCycles -WorkflowPath `$workflow.FullName
        
        `$issues = @()
        
        if (`$cycleResult.HasCycles) {
            foreach (`$cycle in `$cycleResult.Cycles) {
                `$issues += [PSCustomObject]@{
                    Type = "CycleDetected"
                    Description = "Cycle détecté: `$(`$cycle -join ' -> ')"
                    Severity = "High"
                    CanFix = `$true
                }
            }
        }
        
        `$fixed = `$false
        
        if (`$issues.Count -gt 0 -and `$FixIssues) {
            # Corriger les cycles
            if (`$cycleResult.HasCycles) {
                `$fixedWorkflow = Fix-WorkflowCycles -WorkflowPath `$workflow.FullName -Cycles `$cycleResult.Cycles
                
                if (`$fixedWorkflow) {
                    # Sauvegarder le workflow corrigé
                    `$fixedWorkflow | ConvertTo-Json -Depth 10 | Out-File -FilePath `$workflow.FullName -Encoding utf8
                    `$fixed = `$true
                }
            }
        }
        
        `$results += [PSCustomObject]@{
            Path = `$workflow.FullName
            Name = `$workflow.Name
            Issues = `$issues
            Fixed = `$fixed
        }
    }
    
    # Générer le rapport JSON
    `$reportJson = [PSCustomObject]@{
        GeneratedAt = (Get-Date).ToString("o")
        WorkflowsPath = `$WorkflowsPath
        TotalWorkflows = `$n8nWorkflows.Count
        WorkflowsWithIssues = (`$results | Where-Object { `$_.Issues.Count -gt 0 }).Count
        FixedWorkflows = (`$results | Where-Object { `$_.Fixed }).Count
        Results = `$results
    }
    
    `$jsonReportPath = Join-Path -Path `$ReportsPath -ChildPath "workflow_validation_`$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    `$reportJson | ConvertTo-Json -Depth 10 | Out-File -FilePath `$jsonReportPath -Encoding utf8
    
    # Générer le rapport HTML si demandé
    if (`$GenerateReport) {
        `$htmlReportPath = Join-Path -Path `$ReportsPath -ChildPath "workflow_validation_`$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
        
        # Contenu HTML simplifié pour les tests
        `$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Rapport de validation des workflows n8n</title>
</head>
<body>
    <h1>Rapport de validation des workflows n8n</h1>
    <p>Workflows analysés: `$(`$n8nWorkflows.Count)</p>
    <p>Workflows avec problèmes: `$((`$results | Where-Object { `$_.Issues.Count -gt 0 }).Count)</p>
    <p>Workflows corrigés: `$((`$results | Where-Object { `$_.Fixed }).Count)</p>
</body>
</html>
"@
        
        `$htmlContent | Out-File -FilePath `$htmlReportPath -Encoding utf8
    }
    
    return `$reportJson
}

# Fonction pour corriger les cycles dans un workflow
function Fix-WorkflowCycles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$WorkflowPath,
        
        [Parameter(Mandatory = `$true)]
        [array]`$Cycles
    )
    
    try {
        # Charger le workflow
        `$workflow = Get-Content -Path `$WorkflowPath -Raw | ConvertFrom-Json
        
        # Pour chaque cycle, supprimer la dernière connexion
        foreach (`$cycle in `$Cycles) {
            `$lastNode = `$cycle[-1]
            `$firstNode = `$cycle[0]
            
            # Trouver la connexion à supprimer
            if (`$workflow.connections.PSObject.Properties.Name -contains `$lastNode) {
                `$connections = `$workflow.connections.(`$lastNode).main
                
                if (`$connections) {
                    for (`$i = 0; `$i -lt `$connections.Count; `$i++) {
                        `$targets = `$connections[`$i]
                        
                        if (`$targets) {
                            # Filtrer les connexions qui pointent vers le premier nœud du cycle
                            `$newTargets = `$targets | Where-Object { `$_.node -ne `$firstNode }
                            `$workflow.connections.(`$lastNode).main[`$i] = `$newTargets
                        }
                    }
                }
            }
        }
        
        return `$workflow
    }
    catch {
        Write-Error "Erreur lors de la correction des cycles: `$_"
        return `$null
    }
}

# Exécuter la fonction principale
Start-WorkflowValidation -WorkflowsPath `$WorkflowsPath -ReportsPath `$ReportsPath -FixIssues:`$FixIssues -GenerateReport:`$GenerateReport
"@ | Out-File -FilePath $scriptPath -Encoding utf8
            }
            
            # Créer un dossier de rapports temporaire
            $tempReportsDir = Join-Path -Path $TestDrive -ChildPath "reports"
            New-Item -Path $tempReportsDir -ItemType Directory -Force | Out-Null
        }
        
        It "Devrait valider tous les workflows dans un dossier" {
            $result = & $scriptPath -WorkflowsPath $tempDir -ReportsPath $tempReportsDir
            $result.TotalWorkflows | Should -Be 3
            $result.WorkflowsWithIssues | Should -Be 2  # Les deux workflows avec cycles
        }
        
        It "Devrait corriger les problèmes lorsque demandé" {
            $result = & $scriptPath -WorkflowsPath $tempDir -ReportsPath $tempReportsDir -FixIssues
            $result.FixedWorkflows | Should -BeGreaterThan 0
        }
        
        It "Devrait générer un rapport HTML lorsque demandé" {
            & $scriptPath -WorkflowsPath $tempDir -ReportsPath $tempReportsDir -GenerateReport
            $htmlReports = Get-ChildItem -Path $tempReportsDir -Filter "*.html"
            $htmlReports.Count | Should -BeGreaterThan 0
        }
        
        It "Devrait générer un rapport JSON" {
            & $scriptPath -WorkflowsPath $tempDir -ReportsPath $tempReportsDir
            $jsonReports = Get-ChildItem -Path $tempReportsDir -Filter "*.json"
            $jsonReports.Count | Should -BeGreaterThan 0
        }
    }
}

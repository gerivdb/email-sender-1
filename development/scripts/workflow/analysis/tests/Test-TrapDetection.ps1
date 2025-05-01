# Script pour tester la détection des blocs trap
# Ce script teste spécifiquement la détection des blocs trap dans les workflows n8n

#Requires -Version 5.1

# Paramètres
param (
    [Parameter(Mandatory = $false)]
    [string]$TestDataPath = "TestData",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "TestResults"
)

# Définir les chemins complets
$TestDataPath = Join-Path -Path $PSScriptRoot -ChildPath $TestDataPath
$OutputFolder = Join-Path -Path $PSScriptRoot -ChildPath $OutputFolder

# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "WorkflowAnalyzer.psm1"
Import-Module $modulePath -Force

# Fonction pour afficher un message
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

# Créer les dossiers s'ils n'existent pas
if (-not (Test-Path -Path $TestDataPath)) {
    New-Item -Path $TestDataPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# Créer un workflow de test avec des blocs trap
$trapWorkflowPath = Join-Path -Path $TestDataPath -ChildPath "trap_workflow.json"
if (-not (Test-Path -Path $trapWorkflowPath)) {
    Write-TestMessage "Création d'un workflow de test avec des blocs trap..." -Status "INFO"
    
    $workflow = @{
        id          = "test-workflow-trap"
        name        = "Test Workflow Trap"
        nodes       = @(
            @{
                id          = "node1"
                name        = "Start"
                type        = "n8n-nodes-base.start"
                typeVersion = 1
                position    = @(100, 300)
            },
            @{
                id          = "node2"
                name        = "Set Data"
                type        = "n8n-nodes-base.set"
                typeVersion = 1
                position    = @(300, 300)
                parameters  = @{
                    values = @{
                        string = @(
                            @{
                                name  = "testValue"
                                value = "test"
                            }
                        )
                    }
                }
            },
            @{
                id          = "node3"
                name        = "Function with Trap"
                type        = "n8n-nodes-base.function"
                typeVersion = 1
                position    = @(500, 300)
                parameters  = @{
                    functionCode = @"
// This is a JavaScript function with PowerShell-like trap statements
// Note: This is just for testing the trap detection, not actual working code

function processData() {
    // Simple trap statement
    trap {
        console.log('Error caught in trap');
        return { error: true, message: 'An error occurred' };
    }
    
    // Trap with specific exception type
    trap [TypeError] {
        console.log('TypeError caught in trap');
        return { error: true, message: 'Type error occurred' };
    }
    
    // Multiple trap statements
    trap [ReferenceError] {
        console.log('ReferenceError caught in trap');
        return { error: true, message: 'Reference error occurred' };
    }
    
    // Some code that might throw errors
    const result = items[0].json.testValue.toUpperCase();
    
    return [{ json: { result: result } }];
}

return processData();
"@
                }
            },
            @{
                id          = "node4"
                name        = "Output"
                type        = "n8n-nodes-base.noOp"
                typeVersion = 1
                position    = @(700, 300)
            }
        )
        connections = @{
            node1 = @{
                main = @(
                    @(
                        @{
                            node  = "node2"
                            type  = "main"
                            index = 0
                        }
                    )
                )
            }
            node2 = @{
                main = @(
                    @(
                        @{
                            node  = "node3"
                            type  = "main"
                            index = 0
                        }
                    )
                )
            }
            node3 = @{
                main = @(
                    @(
                        @{
                            node  = "node4"
                            type  = "main"
                            index = 0
                        }
                    )
                )
            }
        }
        active      = $false
        settings    = @{}
    }
    
    $workflowJson = $workflow | ConvertTo-Json -Depth 10
    Set-Content -Path $trapWorkflowPath -Value $workflowJson -Encoding UTF8
    
    Write-TestMessage "Workflow de test créé: $trapWorkflowPath" -Status "SUCCESS"
}
else {
    Write-TestMessage "Utilisation du workflow de test existant: $trapWorkflowPath" -Status "INFO"
}

# Tester la détection des blocs trap
Write-TestMessage "Test de la détection des blocs trap..." -Status "INFO"

# Charger le workflow
$workflow = Get-N8nWorkflow -WorkflowPath $trapWorkflowPath

if (-not $workflow) {
    Write-TestMessage "Échec du chargement du workflow" -Status "ERROR"
    exit 1
}

Write-TestMessage "Workflow chargé avec succès: $($workflow.name)" -Status "SUCCESS"

# Détecter les blocs trap
$trapBlocks = Get-N8nWorkflowTrapBlocks -Workflow $workflow

if ($trapBlocks) {
    Write-TestMessage "Blocs trap détectés avec succès: $($trapBlocks.Count) noeuds trouvés" -Status "SUCCESS"
    
    # Afficher les résultats
    foreach ($node in $trapBlocks) {
        Write-TestMessage "Noeud: $($node.Name) (ID: $($node.Id))" -Status "INFO"
        Write-Host "  Type: $($node.Type)"
        Write-Host "  Blocs trap: $($node.TrapBlocks)"
        Write-Host ""
        
        # Afficher les extraits de code
        Write-Host "  Extraits de code:"
        
        foreach ($block in $node.Blocks) {
            Write-Host "    Trap block:"
            Write-Host "      Type d'exception: $($block.ExceptionType)"
            Write-Host "      $($block.Code.Substring(0, [Math]::Min(50, $block.Code.Length)))..."
            Write-Host ""
        }
    }
    
    # Enregistrer les résultats dans un fichier Markdown
    $outputPath = Join-Path -Path $OutputFolder -ChildPath "trap_blocks.md"
    
    $markdown = "# Blocs trap dans le workflow: $($workflow.name)`n`n"
    
    foreach ($node in $trapBlocks) {
        $markdown += "## Noeud: $($node.Name) (ID: $($node.Id))`n`n"
        $markdown += "- **Type**: $($node.Type)`n"
        $markdown += "- **Blocs trap**: $($node.TrapBlocks)`n`n"
        
        $markdown += "### Extraits de code`n`n"
        
        foreach ($block in $node.Blocks) {
            $markdown += "#### Trap block"
            if ($block.ExceptionType) {
                $markdown += " (Type: $($block.ExceptionType))"
            }
            $markdown += "`n`n"
            $markdown += "```javascript`n$($block.Code)`n```n`n"
        }
        
        $markdown += "---`n`n"
    }
    
    $markdown | Out-File -FilePath $outputPath -Encoding UTF8
    Write-TestMessage "Résultats enregistrés dans: $outputPath" -Status "SUCCESS"
}
else {
    Write-TestMessage "Aucun bloc trap détecté" -Status "WARNING"
}

Write-TestMessage "Test terminé." -Status "SUCCESS"

# Script pour tester la dÃ©tection des blocs try/catch/finally
# Ce script teste spÃ©cifiquement la dÃ©tection des blocs try/catch/finally dans les workflows n8n

#Requires -Version 5.1

# ParamÃ¨tres
param (
    [Parameter(Mandatory = $false)]
    [string]$TestDataPath = "TestData",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "TestResults"
)

# DÃ©finir les chemins complets
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

# CrÃ©er les dossiers s'ils n'existent pas
if (-not (Test-Path -Path $TestDataPath)) {
    New-Item -Path $TestDataPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# GÃ©nÃ©rer le workflow de test avec try/catch/finally si nÃ©cessaire
$tryCatchWorkflowPath = Join-Path -Path $TestDataPath -ChildPath "try_catch_workflow.json"
if (-not (Test-Path -Path $tryCatchWorkflowPath)) {
    Write-TestMessage "Le workflow de test n'existe pas. GÃ©nÃ©ration en cours..." -Status "WARNING"
    
    # ExÃ©cuter le script de gÃ©nÃ©ration de workflows
    $generateScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Generate-TestWorkflows.ps1"
    if (Test-Path -Path $generateScriptPath) {
        & $generateScriptPath -OutputFolder $TestDataPath
    }
    else {
        Write-TestMessage "Le script de gÃ©nÃ©ration de workflows n'existe pas: $generateScriptPath" -Status "ERROR"
        exit 1
    }
}

# Tester la dÃ©tection des blocs try/catch/finally
Write-TestMessage "Test de la dÃ©tection des blocs try/catch/finally..." -Status "INFO"

# Charger le workflow
$workflow = Get-N8nWorkflow -WorkflowPath $tryCatchWorkflowPath

if (-not $workflow) {
    Write-TestMessage "Ã‰chec du chargement du workflow" -Status "ERROR"
    exit 1
}

Write-TestMessage "Workflow chargÃ© avec succÃ¨s: $($workflow.name)" -Status "SUCCESS"

# DÃ©tecter les blocs try/catch/finally
$tryCatchBlocks = Get-N8nWorkflowTryCatchBlocks -Workflow $workflow

if ($tryCatchBlocks) {
    Write-TestMessage "Blocs try/catch/finally dÃ©tectÃ©s avec succÃ¨s: $($tryCatchBlocks.Count) noeuds trouvÃ©s" -Status "SUCCESS"
    
    # Afficher les rÃ©sultats
    foreach ($node in $tryCatchBlocks) {
        Write-TestMessage "Noeud: $($node.Name) (ID: $($node.Id))" -Status "INFO"
        Write-Host "  Type: $($node.Type)"
        Write-Host "  Blocs try: $($node.TryBlocks)"
        Write-Host "  Blocs catch: $($node.CatchBlocks)"
        Write-Host "  Blocs finally: $($node.FinallyBlocks)"
        Write-Host ""
        
        # Afficher les extraits de code
        Write-Host "  Extraits de code:"
        
        if ($node.Blocks.TryBlocks.Count -gt 0) {
            Write-Host "    Try blocks:"
            foreach ($block in $node.Blocks.TryBlocks) {
                Write-Host "      $($block.Code.Substring(0, [Math]::Min(50, $block.Code.Length)))..."
            }
        }
        
        if ($node.Blocks.CatchBlocks.Count -gt 0) {
            Write-Host "    Catch blocks:"
            foreach ($block in $node.Blocks.CatchBlocks) {
                Write-Host "      $($block.Code.Substring(0, [Math]::Min(50, $block.Code.Length)))..."
            }
        }
        
        if ($node.Blocks.FinallyBlocks.Count -gt 0) {
            Write-Host "    Finally blocks:"
            foreach ($block in $node.Blocks.FinallyBlocks) {
                Write-Host "      $($block.Code.Substring(0, [Math]::Min(50, $block.Code.Length)))..."
            }
        }
        
        Write-Host ""
    }
    
    # Enregistrer les rÃ©sultats dans un fichier Markdown
    $outputPath = Join-Path -Path $OutputFolder -ChildPath "try_catch_blocks.md"
    
    $markdown = "# Blocs try/catch/finally dans le workflow: $($workflow.name)`n`n"
    
    foreach ($node in $tryCatchBlocks) {
        $markdown += "## Noeud: $($node.Name) (ID: $($node.Id))`n`n"
        $markdown += "- **Type**: $($node.Type)`n"
        $markdown += "- **Blocs try**: $($node.TryBlocks)`n"
        $markdown += "- **Blocs catch**: $($node.CatchBlocks)`n"
        $markdown += "- **Blocs finally**: $($node.FinallyBlocks)`n`n"
        
        $markdown += "### Extraits de code`n`n"
        
        if ($node.Blocks.TryBlocks.Count -gt 0) {
            $markdown += "#### Try blocks`n`n"
            foreach ($block in $node.Blocks.TryBlocks) {
                $markdown += "```javascript`n$($block.Code)`n```n`n"
            }
        }
        
        if ($node.Blocks.CatchBlocks.Count -gt 0) {
            $markdown += "#### Catch blocks`n`n"
            foreach ($block in $node.Blocks.CatchBlocks) {
                $markdown += "```javascript`n$($block.Code)`n```n`n"
            }
        }
        
        if ($node.Blocks.FinallyBlocks.Count -gt 0) {
            $markdown += "#### Finally blocks`n`n"
            foreach ($block in $node.Blocks.FinallyBlocks) {
                $markdown += "```javascript`n$($block.Code)`n```n`n"
            }
        }
        
        $markdown += "---`n`n"
    }
    
    $markdown | Out-File -FilePath $outputPath -Encoding UTF8
    Write-TestMessage "RÃ©sultats enregistrÃ©s dans: $outputPath" -Status "SUCCESS"
}
else {
    Write-TestMessage "Aucun bloc try/catch/finally dÃ©tectÃ©" -Status "WARNING"
}

Write-TestMessage "Test terminÃ©." -Status "SUCCESS"

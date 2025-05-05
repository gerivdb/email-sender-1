# Script pour tester la dÃ©tection des gestionnaires d'erreurs personnalisÃ©s
# Ce script teste spÃ©cifiquement la dÃ©tection des gestionnaires d'erreurs personnalisÃ©s dans les workflows n8n

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

# CrÃ©er un workflow de test avec des gestionnaires d'erreurs personnalisÃ©s
$customErrorHandlersWorkflowPath = Join-Path -Path $TestDataPath -ChildPath "custom_error_handlers_workflow.json"
if (-not (Test-Path -Path $customErrorHandlersWorkflowPath)) {
    Write-TestMessage "CrÃ©ation d'un workflow de test avec des gestionnaires d'erreurs personnalisÃ©s..." -Status "INFO"
    
    $workflow = @{
        id          = "test-workflow-custom-error-handlers"
        name        = "Test Workflow Custom Error Handlers"
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
                name        = "Function with Custom Error Handlers"
                type        = "n8n-nodes-base.function"
                typeVersion = 1
                position    = @(500, 300)
                parameters  = @{
                    functionCode = @"
// This is a JavaScript function with custom error handlers
// Note: This is just for testing the custom error handlers detection

function processData() {
    try {
        // Some code that might throw errors
        const result = items[0].json.testValue.toUpperCase();
        
        // Check for potential errors
        if (!result) {
            throw new Error('Result is empty');
        }
        
        return [{ json: { result: result } }];
    } catch (error) {
        // Custom error handler
        console.log('Error caught:', error.message);
        
        // Custom error object
        const errorObj = {
            status: 'error',
            code: 500,
            message: error.message,
            timestamp: new Date().toISOString()
        };
        
        // Return error information
        return [{ json: { error: errorObj } }];
    }
}

// Custom error handling function
function handleApiError(error) {
    console.log('API Error:', error.message);
    return {
        success: false,
        error: error.message
    };
}

// Function that uses the custom error handler
function callApi() {
    try {
        // Simulate API call
        const response = makeApiCall();
        return response;
    } catch (e) {
        return handleApiError(e);
    }
}

// Error checking condition
if (items[0].json.error) {
    // Handle the error
    items[0].json.errorHandled = true;
}

return processData();
"@
                }
            },
            @{
                id          = "node4"
                name        = "Stop And Error"
                type        = "n8n-nodes-base.stopAndError"
                typeVersion = 1
                position    = @(700, 300)
                parameters  = @{
                    errorType    = "Error Message"
                    errorMessage = "This is a custom error message"
                }
            },
            @{
                id          = "node5"
                name        = "Output"
                type        = "n8n-nodes-base.noOp"
                typeVersion = 1
                position    = @(900, 300)
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
            node4 = @{
                main = @(
                    @(
                        @{
                            node  = "node5"
                            type  = "main"
                            index = 0
                        }
                    )
                )
            }
        }
        active      = $false
        settings    = @{
            errorWorkflow = "error-workflow-id"
        }
    }
    
    $workflowJson = $workflow | ConvertTo-Json -Depth 10
    Set-Content -Path $customErrorHandlersWorkflowPath -Value $workflowJson -Encoding UTF8
    
    Write-TestMessage "Workflow de test crÃ©Ã©: $customErrorHandlersWorkflowPath" -Status "SUCCESS"
}
else {
    Write-TestMessage "Utilisation du workflow de test existant: $customErrorHandlersWorkflowPath" -Status "INFO"
}

# Tester la dÃ©tection des gestionnaires d'erreurs personnalisÃ©s
Write-TestMessage "Test de la dÃ©tection des gestionnaires d'erreurs personnalisÃ©s..." -Status "INFO"

# Charger le workflow
$workflow = Get-N8nWorkflow -WorkflowPath $customErrorHandlersWorkflowPath

if (-not $workflow) {
    Write-TestMessage "Ã‰chec du chargement du workflow" -Status "ERROR"
    exit 1
}

Write-TestMessage "Workflow chargÃ© avec succÃ¨s: $($workflow.name)" -Status "SUCCESS"

# DÃ©tecter les gestionnaires d'erreurs personnalisÃ©s
$customErrorHandlers = Get-N8nWorkflowCustomErrorHandlers -Workflow $workflow

if ($customErrorHandlers) {
    Write-TestMessage "Gestionnaires d'erreurs personnalisÃ©s dÃ©tectÃ©s avec succÃ¨s: $($customErrorHandlers.Count) noeuds trouvÃ©s" -Status "SUCCESS"
    
    # Afficher les rÃ©sultats
    foreach ($node in $customErrorHandlers) {
        Write-TestMessage "Noeud: $($node.Name) (ID: $($node.Id))" -Status "INFO"
        Write-Host "  Type: $($node.Type)"
        Write-Host "  Nombre de gestionnaires: $($node.CustomErrorHandlersCount)"
        
        if ($node.Type -eq "n8n-nodes-base.stopAndError") {
            Write-Host "  Type d'erreur: $($node.ErrorType)"
            Write-Host "  Message d'erreur: $($node.ErrorMessage)"
        }
        elseif ($node.Type -eq "ErrorWorkflowConfig") {
            Write-Host "  Workflow d'erreur: $($node.ErrorWorkflow)"
        }
        else {
            Write-Host "  Gestionnaires d'erreurs:"
            foreach ($handler in $node.Handlers) {
                Write-Host "    Type: $($handler.Type)"
                if ($handler.Name) {
                    Write-Host "    Nom: $($handler.Name)"
                }
                Write-Host "    Code: $($handler.Code.Substring(0, [Math]::Min(50, $handler.Code.Length)))..."
                Write-Host ""
            }
        }
        
        Write-Host ""
    }
    
    # Enregistrer les rÃ©sultats dans un fichier Markdown
    $outputPath = Join-Path -Path $OutputFolder -ChildPath "custom_error_handlers.md"
    
    $markdown = "# Gestionnaires d'erreurs personnalisÃ©s dans le workflow: $($workflow.name)`n`n"
    
    foreach ($node in $customErrorHandlers) {
        $markdown += "## Noeud: $($node.Name) (ID: $($node.Id))`n`n"
        $markdown += "- **Type**: $($node.Type)`n"
        $markdown += "- **Nombre de gestionnaires**: $($node.CustomErrorHandlersCount)`n`n"
        
        if ($node.Type -eq "n8n-nodes-base.stopAndError") {
            $markdown += "### DÃ©tails du noeud Stop And Error`n`n"
            $markdown += "- **Type d'erreur**: $($node.ErrorType)`n"
            $markdown += "- **Message d'erreur**: $($node.ErrorMessage)`n`n"
        }
        elseif ($node.Type -eq "ErrorWorkflowConfig") {
            $markdown += "### Configuration du workflow d'erreur`n`n"
            $markdown += "- **Workflow d'erreur**: $($node.ErrorWorkflow)`n`n"
        }
        else {
            $markdown += "### Gestionnaires d'erreurs`n`n"
            foreach ($handler in $node.Handlers) {
                $markdown += "#### Type: $($handler.Type)`n`n"
                if ($handler.Name) {
                    $markdown += "- **Nom**: $($handler.Name)`n`n"
                }
                $markdown += "```javascript`n$($handler.Code)`n```n`n"
            }
        }
        
        $markdown += "---`n`n"
    }
    
    $markdown | Out-File -FilePath $outputPath -Encoding UTF8
    Write-TestMessage "RÃ©sultats enregistrÃ©s dans: $outputPath" -Status "SUCCESS"
}
else {
    Write-TestMessage "Aucun gestionnaire d'erreur personnalisÃ© dÃ©tectÃ©" -Status "WARNING"
}

Write-TestMessage "Test terminÃ©." -Status "SUCCESS"

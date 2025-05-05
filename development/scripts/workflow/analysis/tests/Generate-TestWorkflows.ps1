# Script pour gÃ©nÃ©rer des workflows n8n de test
# Ce script gÃ©nÃ¨re des workflows n8n de test pour les tests unitaires

#Requires -Version 5.1

# ParamÃ¨tres
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "TestData"
)

# DÃ©finir le chemin complet du dossier de sortie
$OutputFolder = Join-Path -Path $PSScriptRoot -ChildPath $OutputFolder

# Fonction pour afficher un message
function Write-Message {
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

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputFolder)) {
    New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
}

# GÃ©nÃ©rer un workflow n8n de test simple
function New-SimpleWorkflow {
    param (
        [string]$OutputPath
    )

    $workflow = @{
        id          = "test-workflow-1"
        name        = "Test Workflow Simple"
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
                name        = "HTTP Request"
                type        = "n8n-nodes-base.httpRequest"
                typeVersion = 1
                position    = @(500, 300)
                parameters  = @{
                    url    = "https://example.com"
                    method = "GET"
                }
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
        }
        active      = $false
        settings    = @{}
    }

    $workflowJson = $workflow | ConvertTo-Json -Depth 10
    Set-Content -Path $OutputPath -Value $workflowJson -Encoding UTF8

    return $workflow
}

# GÃ©nÃ©rer un workflow n8n de test avec des conditions
function New-ConditionalWorkflow {
    param (
        [string]$OutputPath
    )

    $workflow = @{
        id          = "test-workflow-2"
        name        = "Test Workflow Conditional"
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
                name        = "Condition"
                type        = "n8n-nodes-base.if"
                typeVersion = 1
                position    = @(500, 300)
                parameters  = @{
                    conditions = @{
                        string = @(
                            @{
                                value1    = "={{`$json.testValue}}"
                                operation = "equal"
                                value2    = "test"
                            }
                        )
                    }
                }
            },
            @{
                id          = "node4"
                name        = "True Path"
                type        = "n8n-nodes-base.set"
                typeVersion = 1
                position    = @(700, 200)
                parameters  = @{
                    values = @{
                        string = @(
                            @{
                                name  = "result"
                                value = "true"
                            }
                        )
                    }
                }
            },
            @{
                id          = "node5"
                name        = "False Path"
                type        = "n8n-nodes-base.set"
                typeVersion = 1
                position    = @(700, 400)
                parameters  = @{
                    values = @{
                        string = @(
                            @{
                                name  = "result"
                                value = "false"
                            }
                        )
                    }
                }
            },
            @{
                id          = "node6"
                name        = "Switch"
                type        = "n8n-nodes-base.switch"
                typeVersion = 1
                position    = @(900, 300)
                parameters  = @{
                    value = "={{`$json.result}}"
                    rules = @(
                        @{
                            operation = "equal"
                            value     = "true"
                            output    = 0
                        },
                        @{
                            operation = "equal"
                            value     = "false"
                            output    = 1
                        }
                    )
                }
            },
            @{
                id          = "node7"
                name        = "Output True"
                type        = "n8n-nodes-base.noOp"
                typeVersion = 1
                position    = @(1100, 200)
            },
            @{
                id          = "node8"
                name        = "Output False"
                type        = "n8n-nodes-base.noOp"
                typeVersion = 1
                position    = @(1100, 400)
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
                    ),
                    @(
                        @{
                            node  = "node5"
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
                            node  = "node6"
                            type  = "main"
                            index = 0
                        }
                    )
                )
            }
            node5 = @{
                main = @(
                    @(
                        @{
                            node  = "node6"
                            type  = "main"
                            index = 0
                        }
                    )
                )
            }
            node6 = @{
                main = @(
                    @(
                        @{
                            node  = "node7"
                            type  = "main"
                            index = 0
                        }
                    ),
                    @(
                        @{
                            node  = "node8"
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
    Set-Content -Path $OutputPath -Value $workflowJson -Encoding UTF8

    return $workflow
}

# GÃ©nÃ©rer un workflow n8n de test complexe avec diffÃ©rents types de nÅ“uds
function New-ComplexWorkflow {
    param (
        [string]$OutputPath
    )

    $workflow = @{
        id          = "test-workflow-3"
        name        = "Test Workflow Complex"
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
                name        = "Webhook"
                type        = "n8n-nodes-base.webhook"
                typeVersion = 1
                position    = @(300, 300)
                parameters  = @{
                    path         = "test-webhook"
                    responseMode = "lastNode"
                }
            },
            @{
                id          = "node3"
                name        = "Set Data"
                type        = "n8n-nodes-base.set"
                typeVersion = 1
                position    = @(500, 300)
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
                id          = "node4"
                name        = "Function"
                type        = "n8n-nodes-base.function"
                typeVersion = 1
                position    = @(700, 300)
                parameters  = @{
                    functionCode = "return [\n  {\n    json: {\n      result: items[0].json.testValue + '_processed'\n    }\n  }\n];"
                }
            },
            @{
                id          = "node5"
                name        = "Split In Batches"
                type        = "n8n-nodes-base.splitInBatches"
                typeVersion = 1
                position    = @(900, 300)
                parameters  = @{
                    batchSize = 1
                }
            },
            @{
                id          = "node6"
                name        = "HTTP Request"
                type        = "n8n-nodes-base.httpRequest"
                typeVersion = 1
                position    = @(1100, 300)
                parameters  = @{
                    url    = "https://example.com"
                    method = "GET"
                }
            },
            @{
                id          = "node7"
                name        = "Merge"
                type        = "n8n-nodes-base.merge"
                typeVersion = 1
                position    = @(1300, 300)
                parameters  = @{
                    mode = "append"
                }
            },
            @{
                id          = "node8"
                name        = "Wait"
                type        = "n8n-nodes-base.wait"
                typeVersion = 1
                position    = @(1500, 300)
                parameters  = @{
                    amount = 1
                    unit   = "seconds"
                }
            },
            @{
                id          = "node9"
                name        = "Sticky Note"
                type        = "n8n-nodes-base.stickyNote"
                typeVersion = 1
                position    = @(1700, 300)
                parameters  = @{
                    content = "This is a test workflow"
                }
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
            node5 = @{
                main = @(
                    @(
                        @{
                            node  = "node6"
                            type  = "main"
                            index = 0
                        }
                    )
                )
            }
            node6 = @{
                main = @(
                    @(
                        @{
                            node  = "node7"
                            type  = "main"
                            index = 0
                        }
                    )
                )
            }
            node7 = @{
                main = @(
                    @(
                        @{
                            node  = "node8"
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
    Set-Content -Path $OutputPath -Value $workflowJson -Encoding UTF8

    return $workflow
}

# GÃ©nÃ©rer un workflow n8n de test avec des blocs try/catch/finally
function New-TryCatchWorkflow {
    param (
        [string]$OutputPath
    )

    $workflow = @{
        id          = "test-workflow-4"
        name        = "Test Workflow Try Catch"
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
                name        = "Try"
                type        = "n8n-nodes-base.function"
                typeVersion = 1
                position    = @(500, 300)
                parameters  = @{
                    functionCode = "try {\n  // This is a try block\n  if (items[0].json.testValue !== 'test') {\n    throw new Error('Test error');\n  }\n  return [\n    {\n      json: {\n        result: 'success',\n        value: items[0].json.testValue\n      }\n    }\n  ];\n} catch (error) {\n  // This is a catch block\n  return [\n    {\n      json: {\n        result: 'error',\n        error: error.message\n      }\n    }\n  ];\n} finally {\n  // This is a finally block\n  console.log('Finally block executed');\n}"
                }
            },
            @{
                id          = "node4"
                name        = "If Success"
                type        = "n8n-nodes-base.if"
                typeVersion = 1
                position    = @(700, 300)
                parameters  = @{
                    conditions = @{
                        string = @(
                            @{
                                value1    = "={{`$json.result}}"
                                operation = "equal"
                                value2    = "success"
                            }
                        )
                    }
                }
            },
            @{
                id          = "node5"
                name        = "Success Path"
                type        = "n8n-nodes-base.set"
                typeVersion = 1
                position    = @(900, 200)
                parameters  = @{
                    values = @{
                        string = @(
                            @{
                                name  = "finalResult"
                                value = "success"
                            }
                        )
                    }
                }
            },
            @{
                id          = "node6"
                name        = "Error Path"
                type        = "n8n-nodes-base.set"
                typeVersion = 1
                position    = @(900, 400)
                parameters  = @{
                    values = @{
                        string = @(
                            @{
                                name  = "finalResult"
                                value = "error"
                            }
                        )
                    }
                }
            },
            @{
                id          = "node7"
                name        = "Finally"
                type        = "n8n-nodes-base.merge"
                typeVersion = 1
                position    = @(1100, 300)
                parameters  = @{
                    mode = "append"
                }
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
                    ),
                    @(
                        @{
                            node  = "node6"
                            type  = "main"
                            index = 0
                        }
                    )
                )
            }
            node5 = @{
                main = @(
                    @(
                        @{
                            node  = "node7"
                            type  = "main"
                            index = 0
                        }
                    )
                )
            }
            node6 = @{
                main = @(
                    @(
                        @{
                            node  = "node7"
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
    Set-Content -Path $OutputPath -Value $workflowJson -Encoding UTF8

    return $workflow
}

# GÃ©nÃ©rer un workflow n8n de test avec des blocs trap
function New-TrapWorkflow {
    param (
        [string]$OutputPath
    )

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
    Set-Content -Path $OutputPath -Value $workflowJson -Encoding UTF8

    return $workflow
}

# GÃ©nÃ©rer un workflow n8n de test avec des gestionnaires d'erreurs personnalisÃ©s
function New-CustomErrorHandlersWorkflow {
    param (
        [string]$OutputPath
    )

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
    Set-Content -Path $OutputPath -Value $workflowJson -Encoding UTF8

    return $workflow
}

# GÃ©nÃ©rer les workflows de test
Write-Message "GÃ©nÃ©ration des workflows de test..." -Status "INFO"

# Workflow simple
$simpleWorkflowPath = Join-Path -Path $OutputFolder -ChildPath "simple_workflow.json"
New-SimpleWorkflow -OutputPath $simpleWorkflowPath | Out-Null
Write-Message "Workflow simple gÃ©nÃ©rÃ©: $simpleWorkflowPath" -Status "SUCCESS"

# Workflow conditionnel
$conditionalWorkflowPath = Join-Path -Path $OutputFolder -ChildPath "conditional_workflow.json"
New-ConditionalWorkflow -OutputPath $conditionalWorkflowPath | Out-Null
Write-Message "Workflow conditionnel gÃ©nÃ©rÃ©: $conditionalWorkflowPath" -Status "SUCCESS"

# Workflow complexe
$complexWorkflowPath = Join-Path -Path $OutputFolder -ChildPath "complex_workflow.json"
New-ComplexWorkflow -OutputPath $complexWorkflowPath | Out-Null
Write-Message "Workflow complexe gÃ©nÃ©rÃ©: $complexWorkflowPath" -Status "SUCCESS"

# Workflow avec try/catch
$tryCatchWorkflowPath = Join-Path -Path $OutputFolder -ChildPath "try_catch_workflow.json"
New-TryCatchWorkflow -OutputPath $tryCatchWorkflowPath | Out-Null
Write-Message "Workflow avec try/catch gÃ©nÃ©rÃ©: $tryCatchWorkflowPath" -Status "SUCCESS"

# Workflow avec trap
$trapWorkflowPath = Join-Path -Path $OutputFolder -ChildPath "trap_workflow.json"
New-TrapWorkflow -OutputPath $trapWorkflowPath | Out-Null
Write-Message "Workflow avec trap gÃ©nÃ©rÃ©: $trapWorkflowPath" -Status "SUCCESS"

# Workflow avec gestionnaires d'erreurs personnalisÃ©s
$customErrorHandlersWorkflowPath = Join-Path -Path $OutputFolder -ChildPath "custom_error_handlers_workflow.json"
New-CustomErrorHandlersWorkflow -OutputPath $customErrorHandlersWorkflowPath | Out-Null
Write-Message "Workflow avec gestionnaires d'erreurs personnalisÃ©s gÃ©nÃ©rÃ©: $customErrorHandlersWorkflowPath" -Status "SUCCESS"

Write-Message "GÃ©nÃ©ration des workflows de test terminÃ©e." -Status "SUCCESS"

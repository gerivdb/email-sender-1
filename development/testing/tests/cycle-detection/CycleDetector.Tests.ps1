#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module CycleDetector.
.DESCRIPTION
    Ce script contient les tests unitaires pour le module CycleDetector,
    vÃ©rifiant la dÃ©tection de cycles dans diffÃ©rents types de graphes.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-05-10
#>

BeforeAll {
    # Importer le module Ã  tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\CycleDetector.psm1"
    Import-Module $modulePath -Force
}

Describe "Find-GraphCycle" {
    Context "Lorsqu'on vÃ©rifie des cycles simples" {
        It "Devrait dÃ©tecter un cycle direct entre deux noeuds" {
            $graph = @{
                "A" = @("B")
                "B" = @("A")
            }
            $result = Find-GraphCycle -Graph $graph
            $result.HasCycle | Should -Be $true
            $result.CyclePath | Should -Contain "A"
            $result.CyclePath | Should -Contain "B"
        }

        It "Ne devrait pas dÃ©tecter de cycles dans un graphe linÃ©aire" {
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @()
            }
            $result = Find-GraphCycle -Graph $graph
            $result.HasCycle | Should -Be $false
        }

        It "Devrait dÃ©tecter un cycle dans un graphe complexe" {
            $graph = @{
                "A" = @("B", "C")
                "B" = @("D")
                "C" = @("E")
                "D" = @("F")
                "E" = @("D")
                "F" = @("B")
            }
            $result = Find-GraphCycle -Graph $graph
            $result.HasCycle | Should -Be $true
        }
    }
}

Describe "Find-DependencyCycles" {
    Context "Lorsqu'on analyse des dÃ©pendances de scripts" {
        BeforeAll {
            # CrÃ©er des fichiers de test temporaires
            $tempDir = Join-Path -Path $TestDrive -ChildPath "scripts"
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

            @"
# Script A
. .\B.ps1
function Test-A { Write-Host "A" }
"@ | Out-File -FilePath "$tempDir\A.ps1" -Encoding utf8

            @"
# Script B
. .\C.ps1
function Test-B { Write-Host "B" }
"@ | Out-File -FilePath "$tempDir\B.ps1" -Encoding utf8

            @"
# Script C
. .\A.ps1
function Test-C { Write-Host "C" }
"@ | Out-File -FilePath "$tempDir\C.ps1" -Encoding utf8

            @"
# Script D
. .\E.ps1
function Test-D { Write-Host "D" }
"@ | Out-File -FilePath "$tempDir\D.ps1" -Encoding utf8

            @"
# Script E
function Test-E { Write-Host "E" }
"@ | Out-File -FilePath "$tempDir\E.ps1" -Encoding utf8
        }

        It "Devrait dÃ©tecter un cycle dans les dÃ©pendances de scripts" {
            $result = Find-DependencyCycles -Path $tempDir
            $result.HasCycles | Should -Be $true
            $result.Cycles.Count | Should -BeGreaterThan 0
        }

        It "Devrait identifier correctement les scripts impliquÃ©s dans le cycle" {
            $result = Find-DependencyCycles -Path $tempDir
            $cycle = $result.Cycles[0]
            $cycle | Should -Contain "A.ps1"
            $cycle | Should -Contain "B.ps1"
            $cycle | Should -Contain "C.ps1"
        }

        It "Ne devrait pas signaler de cycle pour les scripts sans dÃ©pendances cycliques" {
            $result = Find-DependencyCycles -Path $tempDir
            $result.NonCyclicScripts | Should -Contain "D.ps1"
            $result.NonCyclicScripts | Should -Contain "E.ps1"
        }
    }
}

Describe "Test-WorkflowCycles" {
    Context "Lorsqu'on analyse des workflows n8n" {
        BeforeAll {
            # CrÃ©er un workflow n8n de test avec un cycle
            $tempDir = Join-Path -Path $TestDrive -ChildPath "workflows"
            New-Item -Path $tempDir -ItemType Directory -Force | Out-Null

            $workflowWithCycle = @{
                name        = "Workflow with cycle"
                nodes       = @(
                    @{
                        id       = "node1"
                        name     = "Start"
                        type     = "n8n-nodes-base.start"
                        position = @(100, 300)
                    },
                    @{
                        id       = "node2"
                        name     = "Function"
                        type     = "n8n-nodes-base.function"
                        position = @(300, 300)
                    },
                    @{
                        id       = "node3"
                        name     = "IF"
                        type     = "n8n-nodes-base.if"
                        position = @(500, 300)
                    },
                    @{
                        id       = "node4"
                        name     = "End"
                        type     = "n8n-nodes-base.noOp"
                        position = @(700, 300)
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
                                    node  = "node2"
                                    type  = "main"
                                    index = 0
                                }
                            )
                        )
                    }
                }
            }

            $workflowWithCycle | ConvertTo-Json -Depth 10 | Out-File -FilePath "$tempDir\workflow_with_cycle.json" -Encoding utf8

            # CrÃ©er un workflow n8n de test sans cycle
            $workflowWithoutCycle = @{
                name        = "Workflow without cycle"
                nodes       = @(
                    @{
                        id       = "node1"
                        name     = "Start"
                        type     = "n8n-nodes-base.start"
                        position = @(100, 300)
                    },
                    @{
                        id       = "node2"
                        name     = "Function"
                        type     = "n8n-nodes-base.function"
                        position = @(300, 300)
                    },
                    @{
                        id       = "node3"
                        name     = "End"
                        type     = "n8n-nodes-base.noOp"
                        position = @(500, 300)
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
            }

            $workflowWithoutCycle | ConvertTo-Json -Depth 10 | Out-File -FilePath "$tempDir\workflow_without_cycle.json" -Encoding utf8
        }

        It "Devrait dÃ©tecter un cycle dans un workflow n8n" {
            $result = Test-WorkflowCycles -WorkflowPath "$tempDir\workflow_with_cycle.json"
            $result.HasCycles | Should -Be $true
        }

        It "Ne devrait pas dÃ©tecter de cycle dans un workflow linÃ©aire" {
            $result = Test-WorkflowCycles -WorkflowPath "$tempDir\workflow_without_cycle.json"
            $result.HasCycles | Should -Be $false
        }

        It "Devrait identifier correctement les noeuds impliquÃ©s dans le cycle" {
            $result = Test-WorkflowCycles -WorkflowPath "$tempDir\workflow_with_cycle.json"
            $cycle = $result.Cycles[0]
            $cycle | Should -Contain "node2"
            $cycle | Should -Contain "node3"
        }
    }
}

Describe "Remove-Cycle" {
    Context "Lorsqu'on tente de supprimer un cycle" {
        It "Devrait supprimer un cycle simple en retirant une arete" {
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }

            $cycle = @("A", "B", "C")
            $result = Remove-Cycle -Graph $graph -Cycle $cycle

            # VÃ©rifier que le cycle a Ã©tÃ© supprimÃ©
            $newCycleCheck = Find-GraphCycle -Graph $result
            $newCycleCheck.HasCycle | Should -Be $false

            # VÃ©rifier qu'une seule arÃªte a Ã©tÃ© supprimÃ©e
            $edgeCount = 0
            foreach ($node in $result.Keys) {
                $edgeCount += $result[$node].Count
            }
            $originalEdgeCount = 0
            foreach ($node in $graph.Keys) {
                $originalEdgeCount += $graph[$node].Count
            }

            $edgeCount | Should -Be ($originalEdgeCount - 1)
        }
    }
}

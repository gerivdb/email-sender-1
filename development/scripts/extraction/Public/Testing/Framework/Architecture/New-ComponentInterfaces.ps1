<#
.SYNOPSIS
    Définit les interfaces entre les composants du framework de test.

.DESCRIPTION
    Ce script définit les interfaces et les flux de données entre les différents
    composants du framework de test de performance. Il spécifie comment les composants
    interagissent et échangent des données.

.NOTES
    Version:        1.0
    Author:         Extraction Module Team
    Creation Date:  2023-05-15
#>

# Définition des interfaces entre les composants
$ComponentInterfaces = @{
    Name = "TestFrameworkInterfaces"
    Description = "Définition des interfaces entre les composants du framework de test de performance"
    
    Interfaces = @(
        @{
            Name = "DataGenerator_TestExecutor"
            Source = "TestDataGenerator"
            Target = "TestExecutor"
            Description = "Interface entre le générateur de données et l'exécuteur de tests"
            DataFlow = @{
                Direction = "Source -> Target"
                DataType = "TestCollection"
                Description = "Collection de données de test générée"
            }
            Methods = @(
                @{
                    Name = "New-TestCollection"
                    Source = "TestDataGenerator"
                    Parameters = @("Size", "ItemCount", "TextRatio", "Complexity", "OutputPath", "OutputFormat", "RandomSeed")
                    ReturnType = "Hashtable/PSCustomObject"
                    Description = "Génère une collection de données de test"
                },
                @{
                    Name = "Import-TestCollection"
                    Source = "TestDataGenerator"
                    Parameters = @("InputPath")
                    ReturnType = "Hashtable/PSCustomObject"
                    Description = "Importe une collection de données de test existante"
                }
            )
        },
        @{
            Name = "TestExecutor_MetricsCollector"
            Source = "TestExecutor"
            Target = "MetricsCollector"
            Description = "Interface entre l'exécuteur de tests et le collecteur de métriques"
            DataFlow = @{
                Direction = "Bidirectional"
                DataTypes = @(
                    @{
                        Direction = "Source -> Target"
                        DataType = "TestContext"
                        Description = "Contexte d'exécution du test"
                    },
                    @{
                        Direction = "Target -> Source"
                        DataType = "CollectedMetrics"
                        Description = "Métriques collectées pendant le test"
                    }
                )
            }
            Methods = @(
                @{
                    Name = "Start-MetricsCollection"
                    Source = "MetricsCollector"
                    Parameters = @("TestId", "MetricsToCollect", "SamplingInterval", "DetailLevel")
                    ReturnType = "String/Guid"
                    Description = "Démarre la collecte des métriques pour un test"
                },
                @{
                    Name = "Stop-MetricsCollection"
                    Source = "MetricsCollector"
                    Parameters = @("CollectionId")
                    ReturnType = "Hashtable/PSCustomObject"
                    Description = "Arrête la collecte des métriques et retourne les résultats"
                },
                @{
                    Name = "Measure-ExecutionTime"
                    Source = "MetricsCollector"
                    Parameters = @("ScriptBlock", "Name", "CollectionId")
                    ReturnType = "Hashtable/PSCustomObject"
                    Description = "Mesure le temps d'exécution d'un bloc de code"
                }
            )
        },
        @{
            Name = "TestExecutor_AnalysisReporting"
            Source = "TestExecutor"
            Target = "AnalysisReporting"
            Description = "Interface entre l'exécuteur de tests et le composant d'analyse et de reporting"
            DataFlow = @{
                Direction = "Source -> Target"
                DataType = "TestResults"
                Description = "Résultats des tests exécutés"
            }
            Methods = @(
                @{
                    Name = "Get-TestResults"
                    Source = "TestExecutor"
                    Parameters = @("TestId")
                    ReturnType = "Hashtable/PSCustomObject"
                    Description = "Récupère les résultats d'un test"
                }
            )
        },
        @{
            Name = "MetricsCollector_AnalysisReporting"
            Source = "MetricsCollector"
            Target = "AnalysisReporting"
            Description = "Interface entre le collecteur de métriques et le composant d'analyse et de reporting"
            DataFlow = @{
                Direction = "Source -> Target"
                DataType = "CollectedMetrics"
                Description = "Métriques collectées pendant les tests"
            }
            Methods = @(
                @{
                    Name = "Get-CollectedMetrics"
                    Source = "MetricsCollector"
                    Parameters = @("CollectionId")
                    ReturnType = "Hashtable/PSCustomObject"
                    Description = "Récupère les métriques collectées"
                }
            )
        }
    )
    
    DataContracts = @(
        @{
            Name = "TestCollection"
            Description = "Structure de données pour une collection de test"
            Schema = @{
                Name = "String"
                Description = "String"
                CreatedAt = "DateTime"
                Items = "Hashtable/Dictionary<String, Object>"
                Metadata = "Hashtable"
            }
            Validation = @(
                "Name doit être non vide",
                "Items doit contenir au moins un élément",
                "Chaque élément doit avoir un ID unique"
            )
        },
        @{
            Name = "TestContext"
            Description = "Contexte d'exécution d'un test"
            Schema = @{
                TestId = "String/Guid"
                TestName = "String"
                TestDescription = "String"
                StartTime = "DateTime"
                Configuration = "Hashtable"
                Collection = "TestCollection"
            }
            Validation = @(
                "TestId doit être un GUID valide",
                "TestName doit être non vide",
                "Configuration doit contenir les paramètres requis"
            )
        },
        @{
            Name = "CollectedMetrics"
            Description = "Métriques collectées pendant un test"
            Schema = @{
                TestId = "String/Guid"
                CollectionId = "String/Guid"
                StartTime = "DateTime"
                EndTime = "DateTime"
                TimeMetrics = "Hashtable/Array"
                MemoryMetrics = "Hashtable/Array"
                CpuMetrics = "Hashtable/Array"
                DiskMetrics = "Hashtable/Array"
                CustomMetrics = "Hashtable/Array"
                Configuration = "Hashtable"
            }
            Validation = @(
                "TestId doit correspondre à un test existant",
                "StartTime doit être antérieure à EndTime",
                "Au moins un type de métrique doit être présent"
            )
        },
        @{
            Name = "TestResults"
            Description = "Résultats d'un test de performance"
            Schema = @{
                TestId = "String/Guid"
                TestName = "String"
                TestDescription = "String"
                StartTime = "DateTime"
                EndTime = "DateTime"
                Duration = "TimeSpan"
                Configuration = "Hashtable"
                RawMetrics = "Hashtable/Array"
                Status = "String/Enum"
                ErrorInfo = "Hashtable"
            }
            Validation = @(
                "TestId doit être un GUID valide",
                "Status doit être une valeur valide (Success, Failed, Timeout, etc.)",
                "Si Status est Failed, ErrorInfo doit contenir des informations"
            )
        },
        @{
            Name = "AnalysisResults"
            Description = "Résultats de l'analyse des tests"
            Schema = @{
                TestId = "String/Guid"
                Statistics = "Hashtable"
                Comparisons = "Hashtable/Array"
                Regressions = "Hashtable/Array"
                Trends = "Hashtable/Array"
                Recommendations = "Array/String[]"
            }
            Validation = @(
                "TestId doit correspondre à un test existant",
                "Statistics doit contenir au moins les métriques de base"
            )
        }
    )
    
    EventFlow = @(
        @{
            Name = "TestExecution"
            Description = "Flux d'événements pour l'exécution d'un test"
            Steps = @(
                @{
                    Step = 1
                    Component = "TestDataGenerator"
                    Action = "New-TestCollection"
                    Output = "TestCollection"
                },
                @{
                    Step = 2
                    Component = "TestExecutor"
                    Action = "Initialize-TestEnvironment"
                    Input = "TestCollection"
                },
                @{
                    Step = 3
                    Component = "TestExecutor"
                    Action = "Start-Test"
                    Output = "TestContext"
                },
                @{
                    Step = 4
                    Component = "MetricsCollector"
                    Action = "Start-MetricsCollection"
                    Input = "TestContext"
                    Output = "CollectionId"
                },
                @{
                    Step = 5
                    Component = "TestExecutor"
                    Action = "Execute-Test"
                    Input = @("TestContext", "CollectionId")
                },
                @{
                    Step = 6
                    Component = "MetricsCollector"
                    Action = "Stop-MetricsCollection"
                    Input = "CollectionId"
                    Output = "CollectedMetrics"
                },
                @{
                    Step = 7
                    Component = "TestExecutor"
                    Action = "Complete-Test"
                    Input = @("TestContext", "CollectedMetrics")
                    Output = "TestResults"
                },
                @{
                    Step = 8
                    Component = "AnalysisReporting"
                    Action = "Invoke-PerformanceAnalysis"
                    Input = @("TestResults", "CollectedMetrics")
                    Output = "AnalysisResults"
                },
                @{
                    Step = 9
                    Component = "AnalysisReporting"
                    Action = "New-PerformanceReport"
                    Input = "AnalysisResults"
                    Output = "GeneratedReports"
                }
            )
        },
        @{
            Name = "TestComparison"
            Description = "Flux d'événements pour la comparaison de tests"
            Steps = @(
                @{
                    Step = 1
                    Component = "TestExecutor"
                    Action = "Get-TestResults"
                    Output = @("TestResults1", "TestResults2")
                },
                @{
                    Step = 2
                    Component = "MetricsCollector"
                    Action = "Get-CollectedMetrics"
                    Output = @("CollectedMetrics1", "CollectedMetrics2")
                },
                @{
                    Step = 3
                    Component = "AnalysisReporting"
                    Action = "Compare-TestResults"
                    Input = @("TestResults1", "TestResults2", "CollectedMetrics1", "CollectedMetrics2")
                    Output = "ComparisonResults"
                },
                @{
                    Step = 4
                    Component = "AnalysisReporting"
                    Action = "New-PerformanceReport"
                    Input = "ComparisonResults"
                    Output = "ComparisonReport"
                }
            )
        }
    )
    
    ErrorHandling = @{
        Strategy = "Centralized"
        Description = "Stratégie de gestion des erreurs centralisée"
        ErrorTypes = @(
            @{
                Type = "DataGenerationError"
                Description = "Erreur lors de la génération des données de test"
                HandledBy = "TestDataGenerator"
                Recovery = "Retry with smaller data set or different parameters"
            },
            @{
                Type = "TestExecutionError"
                Description = "Erreur lors de l'exécution d'un test"
                HandledBy = "TestExecutor"
                Recovery = "Cleanup environment and retry or report failure"
            },
            @{
                Type = "MetricsCollectionError"
                Description = "Erreur lors de la collecte des métriques"
                HandledBy = "MetricsCollector"
                Recovery = "Continue with partial metrics or report degraded results"
            },
            @{
                Type = "AnalysisError"
                Description = "Erreur lors de l'analyse des résultats"
                HandledBy = "AnalysisReporting"
                Recovery = "Report partial analysis or use fallback analysis methods"
            },
            @{
                Type = "ReportGenerationError"
                Description = "Erreur lors de la génération des rapports"
                HandledBy = "AnalysisReporting"
                Recovery = "Generate simplified report or output raw data"
            }
        )
    }
}

# Fonction pour exporter la définition des interfaces au format JSON
function Export-ComponentInterfacesDefinition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\ComponentInterfaces.json"
    )
    
    try {
        $ComponentInterfaces | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Output "La définition des interfaces a été exportée vers $OutputPath"
    }
    catch {
        Write-Error "Erreur lors de l'exportation de la définition des interfaces: $_"
    }
}

# Fonction pour générer un diagramme de séquence au format PlantUML
function New-ComponentSequenceDiagram {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\ComponentSequence.puml",
        
        [Parameter(Mandatory = $false)]
        [string]$EventFlowName = "TestExecution"
    )
    
    # Trouver le flux d'événements spécifié
    $eventFlow = $ComponentInterfaces.EventFlow | Where-Object { $_.Name -eq $EventFlowName }
    
    if (-not $eventFlow) {
        Write-Error "Flux d'événements '$EventFlowName' non trouvé."
        return
    }
    
    $plantUml = @"
@startuml $($eventFlow.Name)Sequence

title $($eventFlow.Description)

"@
    
    # Ajouter les participants
    $participants = $eventFlow.Steps | ForEach-Object { $_.Component } | Select-Object -Unique
    foreach ($participant in $participants) {
        $plantUml += "participant $participant`n"
    }
    
    $plantUml += "`n"
    
    # Ajouter les étapes
    foreach ($step in $eventFlow.Steps) {
        $source = $step.Component
        
        if ($step.ContainsKey('Input')) {
            $inputs = $step.Input
            if ($inputs -is [array]) {
                foreach ($input in $inputs) {
                    # Trouver l'étape précédente qui a produit cette sortie
                    $previousStep = $eventFlow.Steps | Where-Object { 
                        $_.Step -lt $step.Step -and 
                        $_.ContainsKey('Output') -and 
                        ($_.Output -eq $input -or ($_.Output -is [array] -and $_.Output -contains $input))
                    } | Sort-Object -Property Step -Descending | Select-Object -First 1
                    
                    if ($previousStep) {
                        $plantUml += "$($previousStep.Component) -> $source : $input`n"
                    }
                }
            }
            else {
                # Trouver l'étape précédente qui a produit cette sortie
                $previousStep = $eventFlow.Steps | Where-Object { 
                    $_.Step -lt $step.Step -and 
                    $_.ContainsKey('Output') -and 
                    ($_.Output -eq $inputs -or ($_.Output -is [array] -and $_.Output -contains $inputs))
                } | Sort-Object -Property Step -Descending | Select-Object -First 1
                
                if ($previousStep) {
                    $plantUml += "$($previousStep.Component) -> $source : $inputs`n"
                }
            }
        }
        
        $plantUml += "activate $source`n"
        $plantUml += "note over $source : $($step.Action)`n"
        
        if ($step.ContainsKey('Output')) {
            $outputs = $step.Output
            if ($outputs -is [array]) {
                foreach ($output in $outputs) {
                    # Trouver l'étape suivante qui utilise cette sortie
                    $nextStep = $eventFlow.Steps | Where-Object { 
                        $_.Step -gt $step.Step -and 
                        $_.ContainsKey('Input') -and 
                        ($_.Input -eq $output -or ($_.Input -is [array] -and $_.Input -contains $output))
                    } | Sort-Object -Property Step | Select-Object -First 1
                    
                    if ($nextStep) {
                        $plantUml += "$source -> $($nextStep.Component) : $output`n"
                    }
                }
            }
            else {
                # Trouver l'étape suivante qui utilise cette sortie
                $nextStep = $eventFlow.Steps | Where-Object { 
                    $_.Step -gt $step.Step -and 
                    $_.ContainsKey('Input') -and 
                    ($_.Input -eq $outputs -or ($_.Input -is [array] -and $_.Input -contains $outputs))
                } | Sort-Object -Property Step | Select-Object -First 1
                
                if ($nextStep) {
                    $plantUml += "$source -> $($nextStep.Component) : $outputs`n"
                }
            }
        }
        
        $plantUml += "deactivate $source`n`n"
    }
    
    $plantUml += "@enduml"
    
    try {
        $plantUml | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Output "Le diagramme de séquence a été généré à $OutputPath"
    }
    catch {
        Write-Error "Erreur lors de la génération du diagramme de séquence: $_"
    }
}

# Fonction pour générer un diagramme de composants au format PlantUML
function New-ComponentsInterfaceDiagram {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ".\ComponentsInterface.puml"
    )
    
    $plantUml = @"
@startuml ComponentsInterface

package "Test Framework" {
    component [TestDataGenerator] as TDG
    component [TestExecutor] as TE
    component [MetricsCollector] as MC
    component [AnalysisReporting] as AR
    
    interface "TestCollection" as TC
    interface "TestContext" as TCX
    interface "CollectedMetrics" as CM
    interface "TestResults" as TR
    
    TDG -- TC
    TC -- TE
    
    TE -- TCX
    TCX -- MC
    
    MC -- CM
    CM -- TE
    CM -- AR
    
    TE -- TR
    TR -- AR
}

@enduml
"@
    
    try {
        $plantUml | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Output "Le diagramme d'interfaces des composants a été généré à $OutputPath"
    }
    catch {
        Write-Error "Erreur lors de la génération du diagramme d'interfaces des composants: $_"
    }
}

# Fonction pour valider la définition des interfaces
function Test-ComponentInterfacesDefinition {
    [CmdletBinding()]
    param()
    
    $issues = @()
    
    # Vérifier que les sections requises existent
    $requiredSections = @('Name', 'Description', 'Interfaces', 'DataContracts', 'EventFlow')
    foreach ($section in $requiredSections) {
        if (-not $ComponentInterfaces.ContainsKey($section)) {
            $issues += "Section manquante: $section"
        }
    }
    
    # Vérifier que chaque interface a une source et une cible
    foreach ($interface in $ComponentInterfaces.Interfaces) {
        if (-not $interface.ContainsKey('Source') -or -not $interface.ContainsKey('Target')) {
            $issues += "Source ou cible manquante pour l'interface: $($interface.Name)"
        }
    }
    
    # Vérifier que chaque contrat de données a un schéma
    foreach ($contract in $ComponentInterfaces.DataContracts) {
        if (-not $contract.ContainsKey('Schema')) {
            $issues += "Schéma manquant pour le contrat de données: $($contract.Name)"
        }
    }
    
    # Vérifier que chaque flux d'événements a des étapes
    foreach ($flow in $ComponentInterfaces.EventFlow) {
        if (-not $flow.ContainsKey('Steps') -or $flow.Steps.Count -eq 0) {
            $issues += "Étapes manquantes pour le flux d'événements: $($flow.Name)"
        }
    }
    
    # Afficher les résultats
    if ($issues.Count -eq 0) {
        Write-Output "Validation réussie: La définition des interfaces est complète et cohérente."
        return $true
    }
    else {
        Write-Warning "Validation échouée: $($issues.Count) problèmes détectés."
        foreach ($issue in $issues) {
            Write-Warning "- $issue"
        }
        return $false
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Export-ComponentInterfacesDefinition, New-ComponentSequenceDiagram, New-ComponentsInterfaceDiagram, Test-ComponentInterfacesDefinition

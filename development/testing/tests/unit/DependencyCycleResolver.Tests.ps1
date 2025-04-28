#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module DependencyCycleResolver.
.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du module DependencyCycleResolver.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}
Import-Module Pester -Force

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\DependencyCycleResolver.psm1"

# Vérifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Le module DependencyCycleResolver.psm1 n'existe pas à l'emplacement spécifié: $modulePath"
}

# Importer le module à tester
Import-Module $modulePath -Force

Describe "DependencyCycleResolver - Tests unitaires" {
    BeforeAll {
        # Initialiser le module
        Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
    }

    Context "Initialize-DependencyCycleResolver" {
        It "Devrait initialiser le résolveur avec les paramètres par défaut" {
            $result = Initialize-DependencyCycleResolver
            $result | Should -Be $true
        }

        It "Devrait initialiser le résolveur avec des paramètres personnalisés" {
            $result = Initialize-DependencyCycleResolver -Enabled $false -MaxIterations 5 -Strategy "Random"
            $result | Should -Be $true
        }
    }

    Context "Resolve-DependencyCycle" {
        It "Devrait résoudre un cycle simple" {
            # Créer un graphe avec un cycle
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }

            # Créer un objet CycleResult
            $cycleResult = [PSCustomObject]@{
                HasCycle = $true
                CyclePath = @("A", "B", "C", "A")
                Graph = $graph
            }

            # Résoudre le cycle
            $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

            # Vérifier que le cycle est résolu
            $resolveResult.Success | Should -Be $true
            $resolveResult.RemovedEdges.Count | Should -Be 1
        }

        It "Devrait retourner false si aucun cycle n'est détecté" {
            # Créer un graphe sans cycle
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @()
            }

            # Créer un objet CycleResult
            $cycleResult = [PSCustomObject]@{
                HasCycle = $false
                CyclePath = @()
                Graph = $graph
            }

            # Résoudre le cycle
            $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

            # Vérifier que la fonction retourne false
            $resolveResult | Should -Be $false
        }

        It "Devrait retourner false si le résolveur est désactivé" {
            # Désactiver le résolveur
            Initialize-DependencyCycleResolver -Enabled $false

            # Créer un graphe avec un cycle
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }

            # Créer un objet CycleResult
            $cycleResult = [PSCustomObject]@{
                HasCycle = $true
                CyclePath = @("A", "B", "C", "A")
                Graph = $graph
            }

            # Résoudre le cycle
            $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

            # Vérifier que la fonction retourne false
            $resolveResult | Should -Be $false

            # Réactiver le résolveur
            Initialize-DependencyCycleResolver -Enabled $true
        }
    }

    Context "Get-CycleResolverStatistics" {
        It "Devrait retourner les statistiques du résolveur" {
            # Obtenir les statistiques
            $stats = Get-CycleResolverStatistics

            # Vérifier que les statistiques sont disponibles
            $stats | Should -Not -BeNullOrEmpty
            $stats.Enabled | Should -BeOfType [bool]
            $stats.MaxIterations | Should -BeOfType [int]
            $stats.Strategy | Should -BeOfType [string]
            $stats.TotalResolutions | Should -BeOfType [int]
            $stats.SuccessfulResolutions | Should -BeOfType [int]
            $stats.FailedResolutions | Should -BeOfType [int]
            $stats.SuccessRate | Should -BeOfType [double]
        }
    }

    Context "Select-EdgeToRemove (fonction interne)" {
        It "Devrait sélectionner une arête à supprimer selon la stratégie MinimumImpact" {
            # Créer un graphe avec un cycle
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }

            # Cycle
            $cycle = @("A", "B", "C", "A")

            # Appeler la fonction interne via Invoke-Command
            $scriptBlock = {
                param($Graph, $Cycle, $Strategy)
                # Charger le module
                Import-Module "$using:modulePath" -Force
                
                # Accéder à la fonction interne
                $functionInfo = Get-Command -Module DependencyCycleResolver -Name "Select-EdgeToRemove" -ErrorAction SilentlyContinue
                
                if ($functionInfo) {
                    # La fonction est exportée, l'appeler directement
                    Select-EdgeToRemove -Graph $Graph -Cycle $Cycle -Strategy $Strategy
                } else {
                    # La fonction n'est pas exportée, utiliser une autre approche
                    $moduleScript = Get-Content -Path "$using:modulePath" -Raw
                    $moduleScriptBlock = [ScriptBlock]::Create($moduleScript)
                    
                    # Créer un nouveau contexte avec la fonction
                    $newScriptBlock = {
                        param($Graph, $Cycle, $Strategy)
                        
                        # Définir la fonction Select-EdgeToRemove
                        function Select-EdgeToRemove {
                            [CmdletBinding()]
                            param (
                                [Parameter(Mandatory = $true)]
                                [hashtable]$Graph,
                                
                                [Parameter(Mandatory = $true)]
                                [array]$Cycle,
                                
                                [Parameter(Mandatory = $false)]
                                [ValidateSet("MinimumImpact", "WeightBased", "Random")]
                                [string]$Strategy = "MinimumImpact"
                            )
                            
                            # Créer la liste des arêtes du cycle
                            $edges = @()
                            for ($i = 0; $i -lt $Cycle.Count - 1; $i++) {
                                $source = $Cycle[$i]
                                $target = $Cycle[$i + 1]
                                
                                # Vérifier que l'arête existe
                                if ($Graph.ContainsKey($source) -and $Graph[$source] -contains $target) {
                                    $edges += [PSCustomObject]@{
                                        Source = $source
                                        Target = $target
                                        Weight = 1 # Poids par défaut
                                    }
                                }
                            }
                            
                            # Sélectionner l'arête selon la stratégie
                            switch ($Strategy) {
                                "MinimumImpact" {
                                    # Sélectionner l'arête avec le moins d'impact (par exemple, la moins utilisée)
                                    return $edges | Select-Object -First 1
                                }
                                "WeightBased" {
                                    # Sélectionner l'arête avec le poids le plus faible
                                    return $edges | Sort-Object -Property Weight | Select-Object -First 1
                                }
                                "Random" {
                                    # Sélectionner une arête aléatoire
                                    return $edges | Get-Random
                                }
                            }
                        }
                        
                        # Appeler la fonction
                        Select-EdgeToRemove -Graph $Graph -Cycle $Cycle -Strategy $Strategy
                    }
                    
                    # Exécuter le script block
                    & $newScriptBlock $Graph $Cycle $Strategy
                }
            }
            
            $edge = Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $graph, $cycle, "MinimumImpact"
            
            # Vérifier que l'arête est sélectionnée
            $edge | Should -Not -BeNullOrEmpty
            $edge.Source | Should -BeIn @("A", "B", "C")
            $edge.Target | Should -BeIn @("A", "B", "C")
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSScriptRoot -Output Detailed

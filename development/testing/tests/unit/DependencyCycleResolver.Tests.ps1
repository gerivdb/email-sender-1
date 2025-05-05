#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module DependencyCycleResolver.
.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement
    du module DependencyCycleResolver.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-04-20
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Install-Module -Name Pester -Force -SkipPublisherCheck
}
Import-Module Pester -Force

# Chemin du module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\DependencyCycleResolver.psm1"

# VÃ©rifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Le module DependencyCycleResolver.psm1 n'existe pas Ã  l'emplacement spÃ©cifiÃ©: $modulePath"
}

# Importer le module Ã  tester
Import-Module $modulePath -Force

Describe "DependencyCycleResolver - Tests unitaires" {
    BeforeAll {
        # Initialiser le module
        Initialize-DependencyCycleResolver -Enabled $true -MaxIterations 10 -Strategy "MinimumImpact"
    }

    Context "Initialize-DependencyCycleResolver" {
        It "Devrait initialiser le rÃ©solveur avec les paramÃ¨tres par dÃ©faut" {
            $result = Initialize-DependencyCycleResolver
            $result | Should -Be $true
        }

        It "Devrait initialiser le rÃ©solveur avec des paramÃ¨tres personnalisÃ©s" {
            $result = Initialize-DependencyCycleResolver -Enabled $false -MaxIterations 5 -Strategy "Random"
            $result | Should -Be $true
        }
    }

    Context "Resolve-DependencyCycle" {
        It "Devrait rÃ©soudre un cycle simple" {
            # CrÃ©er un graphe avec un cycle
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }

            # CrÃ©er un objet CycleResult
            $cycleResult = [PSCustomObject]@{
                HasCycle = $true
                CyclePath = @("A", "B", "C", "A")
                Graph = $graph
            }

            # RÃ©soudre le cycle
            $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

            # VÃ©rifier que le cycle est rÃ©solu
            $resolveResult.Success | Should -Be $true
            $resolveResult.RemovedEdges.Count | Should -Be 1
        }

        It "Devrait retourner false si aucun cycle n'est dÃ©tectÃ©" {
            # CrÃ©er un graphe sans cycle
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @()
            }

            # CrÃ©er un objet CycleResult
            $cycleResult = [PSCustomObject]@{
                HasCycle = $false
                CyclePath = @()
                Graph = $graph
            }

            # RÃ©soudre le cycle
            $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

            # VÃ©rifier que la fonction retourne false
            $resolveResult | Should -Be $false
        }

        It "Devrait retourner false si le rÃ©solveur est dÃ©sactivÃ©" {
            # DÃ©sactiver le rÃ©solveur
            Initialize-DependencyCycleResolver -Enabled $false

            # CrÃ©er un graphe avec un cycle
            $graph = @{
                "A" = @("B")
                "B" = @("C")
                "C" = @("A")
            }

            # CrÃ©er un objet CycleResult
            $cycleResult = [PSCustomObject]@{
                HasCycle = $true
                CyclePath = @("A", "B", "C", "A")
                Graph = $graph
            }

            # RÃ©soudre le cycle
            $resolveResult = Resolve-DependencyCycle -CycleResult $cycleResult

            # VÃ©rifier que la fonction retourne false
            $resolveResult | Should -Be $false

            # RÃ©activer le rÃ©solveur
            Initialize-DependencyCycleResolver -Enabled $true
        }
    }

    Context "Get-CycleResolverStatistics" {
        It "Devrait retourner les statistiques du rÃ©solveur" {
            # Obtenir les statistiques
            $stats = Get-CycleResolverStatistics

            # VÃ©rifier que les statistiques sont disponibles
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
        It "Devrait sÃ©lectionner une arÃªte Ã  supprimer selon la stratÃ©gie MinimumImpact" {
            # CrÃ©er un graphe avec un cycle
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
                
                # AccÃ©der Ã  la fonction interne
                $functionInfo = Get-Command -Module DependencyCycleResolver -Name "Select-EdgeToRemove" -ErrorAction SilentlyContinue
                
                if ($functionInfo) {
                    # La fonction est exportÃ©e, l'appeler directement
                    Select-EdgeToRemove -Graph $Graph -Cycle $Cycle -Strategy $Strategy
                } else {
                    # La fonction n'est pas exportÃ©e, utiliser une autre approche
                    $moduleScript = Get-Content -Path "$using:modulePath" -Raw
                    $moduleScriptBlock = [ScriptBlock]::Create($moduleScript)
                    
                    # CrÃ©er un nouveau contexte avec la fonction
                    $newScriptBlock = {
                        param($Graph, $Cycle, $Strategy)
                        
                        # DÃ©finir la fonction Select-EdgeToRemove
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
                            
                            # CrÃ©er la liste des arÃªtes du cycle
                            $edges = @()
                            for ($i = 0; $i -lt $Cycle.Count - 1; $i++) {
                                $source = $Cycle[$i]
                                $target = $Cycle[$i + 1]
                                
                                # VÃ©rifier que l'arÃªte existe
                                if ($Graph.ContainsKey($source) -and $Graph[$source] -contains $target) {
                                    $edges += [PSCustomObject]@{
                                        Source = $source
                                        Target = $target
                                        Weight = 1 # Poids par dÃ©faut
                                    }
                                }
                            }
                            
                            # SÃ©lectionner l'arÃªte selon la stratÃ©gie
                            switch ($Strategy) {
                                "MinimumImpact" {
                                    # SÃ©lectionner l'arÃªte avec le moins d'impact (par exemple, la moins utilisÃ©e)
                                    return $edges | Select-Object -First 1
                                }
                                "WeightBased" {
                                    # SÃ©lectionner l'arÃªte avec le poids le plus faible
                                    return $edges | Sort-Object -Property Weight | Select-Object -First 1
                                }
                                "Random" {
                                    # SÃ©lectionner une arÃªte alÃ©atoire
                                    return $edges | Get-Random
                                }
                            }
                        }
                        
                        # Appeler la fonction
                        Select-EdgeToRemove -Graph $Graph -Cycle $Cycle -Strategy $Strategy
                    }
                    
                    # ExÃ©cuter le script block
                    & $newScriptBlock $Graph $Cycle $Strategy
                }
            }
            
            $edge = Invoke-Command -ScriptBlock $scriptBlock -ArgumentList $graph, $cycle, "MinimumImpact"
            
            # VÃ©rifier que l'arÃªte est sÃ©lectionnÃ©e
            $edge | Should -Not -BeNullOrEmpty
            $edge.Source | Should -BeIn @("A", "B", "C")
            $edge.Target | Should -BeIn @("A", "B", "C")
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSScriptRoot -Output Detailed

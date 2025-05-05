# Tests unitaires pour le module CycleDetector
# Utilise Pester 5.x

BeforeAll {
    # Importer le module Ã  tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "../modules/CycleDetector.psm1"
    Import-Module $modulePath -Force

    # Fonction utilitaire pour crÃ©er un graphe de test
    function New-TestGraph {
        param (
            [Parameter(Mandatory = $false)]
            [switch]$WithCycle,

            [Parameter(Mandatory = $false)]
            [switch]$WithSelfLoop,

            [Parameter(Mandatory = $false)]
            [int]$Size = 5
        )

        $graph = @{}

        # CrÃ©er un graphe linÃ©aire (sans cycle)
        for ($i = 1; $i -lt $Size; $i++) {
            $graph["Node$i"] = @("Node$($i+1)")
        }
        $graph["Node$Size"] = @()

        # Ajouter un cycle si demandÃ©
        if ($WithCycle) {
            $graph["Node$Size"] = @("Node1")
        }

        # Ajouter une boucle sur soi-mÃªme si demandÃ©
        if ($WithSelfLoop) {
            $graph["Node1"] = @("Node2", "Node1")
        }

        return $graph
    }
}

Describe "Initialize-CycleDetector" {
    It "Initialise le dÃ©tecteur avec les valeurs par dÃ©faut" {
        $result = Initialize-CycleDetector

        $result.Enabled | Should -BeTrue
        $result.MaxDepth | Should -Be 1000
        $result.CacheEnabled | Should -BeTrue
    }

    It "Initialise le dÃ©tecteur avec des valeurs personnalisÃ©es" {
        $result = Initialize-CycleDetector -Enabled $false -MaxDepth 500 -CacheEnabled $false

        $result.Enabled | Should -BeFalse
        $result.MaxDepth | Should -Be 500
        $result.CacheEnabled | Should -BeFalse
    }
}

Describe "Find-Cycle" {
    BeforeEach {
        # RÃ©initialiser le dÃ©tecteur avant chaque test
        Initialize-CycleDetector -Enabled $true -MaxDepth 1000 -CacheEnabled $true
        Clear-CycleDetectionCache
    }

    It "DÃ©tecte l'absence de cycle dans un graphe linÃ©aire" {
        $graph = New-TestGraph

        $result = Find-Cycle -Graph $graph

        $result.HasCycle | Should -BeFalse
        $result.CyclePath | Should -BeNullOrEmpty
    }

    It "DÃ©tecte un cycle dans un graphe cyclique" {
        $graph = New-TestGraph -WithCycle

        $result = Find-Cycle -Graph $graph

        $result.HasCycle | Should -BeTrue
        $result.CyclePath | Should -Not -BeNullOrEmpty
    }

    It "DÃ©tecte une boucle sur soi-mÃªme" {
        $graph = New-TestGraph -WithSelfLoop

        $result = Find-Cycle -Graph $graph

        $result.HasCycle | Should -BeTrue
        $result.CyclePath.Count | Should -Be 2
        $result.CyclePath[0] | Should -Be "Node1"
        $result.CyclePath[1] | Should -Be "Node1"
    }

    It "Retourne false quand le dÃ©tecteur est dÃ©sactivÃ©" {
        Initialize-CycleDetector -Enabled $false
        $graph = New-TestGraph -WithCycle

        $result = Find-Cycle -Graph $graph

        $result.HasCycle | Should -BeFalse
    }

    It "Utilise le cache pour les appels rÃ©pÃ©tÃ©s" {
        $graph = New-TestGraph -WithCycle

        # Premier appel
        $result1 = Find-Cycle -Graph $graph

        # DeuxiÃ¨me appel
        $result2 = Find-Cycle -Graph $graph

        $result1.HasCycle | Should -BeTrue
        $result2.HasCycle | Should -BeTrue

        # VÃ©rifier que les rÃ©sultats sont identiques
        $result1.CyclePath.Count | Should -Be $result2.CyclePath.Count
    }

    It "Ignore le cache quand SkipCache est spÃ©cifiÃ©" {
        $graph = New-TestGraph -WithCycle

        # RÃ©initialiser les statistiques
        $Global:CycleDetectorStats.CacheHits = 0
        $Global:CycleDetectorStats.CacheMisses = 0
        $Global:CycleDetectorStats.TotalCalls = 0

        # Premier appel
        $result1 = Find-Cycle -Graph $graph

        # DeuxiÃ¨me appel avec SkipCache
        $result2 = Find-Cycle -Graph $graph -SkipCache

        $result1.HasCycle | Should -BeTrue
        $result2.HasCycle | Should -BeTrue

        # VÃ©rifier que les statistiques sont cohÃ©rentes
        $stats = Get-CycleDetectionStatistics
        $stats.TotalCalls | Should -BeGreaterOrEqual 2
    }
}

Describe "Find-GraphCycle" {
    It "DÃ©tecte l'absence de cycle dans un graphe linÃ©aire" {
        $graph = New-TestGraph

        $result = Find-GraphCycle -Graph $graph

        $result.HasCycle | Should -BeFalse
        $result.CyclePath | Should -BeNullOrEmpty
    }

    It "DÃ©tecte un cycle dans un graphe cyclique" {
        $graph = New-TestGraph -WithCycle

        $result = Find-GraphCycle -Graph $graph

        $result.HasCycle | Should -BeTrue
        $result.CyclePath | Should -Not -BeNullOrEmpty
    }

    It "DÃ©tecte une boucle sur soi-mÃªme" {
        $graph = New-TestGraph -WithSelfLoop

        $result = Find-GraphCycle -Graph $graph

        $result.HasCycle | Should -BeTrue
        $result.CyclePath.Count | Should -Be 2
        $result.CyclePath[0] | Should -Be "Node1"
        $result.CyclePath[1] | Should -Be "Node1"
    }

    It "Respecte la profondeur maximale" {
        $graph = @{}
        # CrÃ©er un graphe en chaÃ®ne de 20 nÅ“uds
        for ($i = 1; $i -lt 20; $i++) {
            $graph["Node$i"] = @("Node$($i+1)")
        }
        # Ajouter un cycle Ã  la fin
        $graph["Node20"] = @("Node10")

        # Limiter la profondeur Ã  5 (ne devrait pas dÃ©tecter le cycle)
        $result = Find-GraphCycle -Graph $graph -MaxDepth 5

        $result.HasCycle | Should -BeFalse

        # Avec une profondeur suffisante, devrait dÃ©tecter le cycle
        $result2 = Find-GraphCycle -Graph $graph -MaxDepth 20

        $result2.HasCycle | Should -BeTrue
    }
}

Describe "Get-CycleDetectionStatistics" {
    BeforeAll {
        # RÃ©initialiser les statistiques
        Initialize-CycleDetector
        Clear-CycleDetectionCache
    }

    It "Retourne les statistiques d'utilisation" {
        # RÃ©initialiser les statistiques
        $Global:CycleDetectorStats.TotalCalls = 0
        $Global:CycleDetectorStats.TotalCycles = 0

        # Effectuer quelques appels pour gÃ©nÃ©rer des statistiques
        $graph1 = New-TestGraph
        $graph2 = New-TestGraph -WithCycle

        Find-Cycle -Graph $graph1
        Find-Cycle -Graph $graph2

        $stats = Get-CycleDetectionStatistics

        $stats.TotalCalls | Should -BeGreaterThan 0
        $stats.TotalCycles | Should -BeGreaterThan 0
    }
}

Describe "Clear-CycleDetectionCache" {
    It "Vide le cache du dÃ©tecteur" {
        # Remplir le cache
        $graph = New-TestGraph -WithCycle
        Find-Cycle -Graph $graph

        # VÃ©rifier que le cache est vidÃ©
        Clear-CycleDetectionCache

        # VÃ©rifier que le cache est vide
        $Global:CycleDetectorCache.Count | Should -Be 0
    }
}

# Tests de performance
Describe "Performance" -Tag "Performance" {
    It "GÃ¨re efficacement les grands graphes" {
        # CrÃ©er un grand graphe (1000 nÅ“uds)
        $graph = @{}
        for ($i = 1; $i -lt 1000; $i++) {
            $graph["Node$i"] = @("Node$($i+1)")
        }
        $graph["Node1000"] = @()

        # Mesurer le temps d'exÃ©cution
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $result = Find-Cycle -Graph $graph
        $sw.Stop()

        $result.HasCycle | Should -BeFalse
        $sw.ElapsedMilliseconds | Should -BeLessThan 5000 # Moins de 5 secondes
    }
}

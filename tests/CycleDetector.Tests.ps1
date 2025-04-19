# Tests unitaires pour le module CycleDetector
# Utilise Pester 5.x

BeforeAll {
    # Importer le module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "../modules/CycleDetector.psm1"
    Import-Module $modulePath -Force

    # Fonction utilitaire pour créer un graphe de test
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

        # Créer un graphe linéaire (sans cycle)
        for ($i = 1; $i -lt $Size; $i++) {
            $graph["Node$i"] = @("Node$($i+1)")
        }
        $graph["Node$Size"] = @()

        # Ajouter un cycle si demandé
        if ($WithCycle) {
            $graph["Node$Size"] = @("Node1")
        }

        # Ajouter une boucle sur soi-même si demandé
        if ($WithSelfLoop) {
            $graph["Node1"] = @("Node2", "Node1")
        }

        return $graph
    }
}

Describe "Initialize-CycleDetector" {
    It "Initialise le détecteur avec les valeurs par défaut" {
        $result = Initialize-CycleDetector

        $result.Enabled | Should -BeTrue
        $result.MaxDepth | Should -Be 1000
        $result.CacheEnabled | Should -BeTrue
    }

    It "Initialise le détecteur avec des valeurs personnalisées" {
        $result = Initialize-CycleDetector -Enabled $false -MaxDepth 500 -CacheEnabled $false

        $result.Enabled | Should -BeFalse
        $result.MaxDepth | Should -Be 500
        $result.CacheEnabled | Should -BeFalse
    }
}

Describe "Find-Cycle" {
    BeforeEach {
        # Réinitialiser le détecteur avant chaque test
        Initialize-CycleDetector -Enabled $true -MaxDepth 1000 -CacheEnabled $true
        Clear-CycleDetectionCache
    }

    It "Détecte l'absence de cycle dans un graphe linéaire" {
        $graph = New-TestGraph

        $result = Find-Cycle -Graph $graph

        $result.HasCycle | Should -BeFalse
        $result.CyclePath | Should -BeNullOrEmpty
    }

    It "Détecte un cycle dans un graphe cyclique" {
        $graph = New-TestGraph -WithCycle

        $result = Find-Cycle -Graph $graph

        $result.HasCycle | Should -BeTrue
        $result.CyclePath | Should -Not -BeNullOrEmpty
    }

    It "Détecte une boucle sur soi-même" {
        $graph = New-TestGraph -WithSelfLoop

        $result = Find-Cycle -Graph $graph

        $result.HasCycle | Should -BeTrue
        $result.CyclePath.Count | Should -Be 2
        $result.CyclePath[0] | Should -Be "Node1"
        $result.CyclePath[1] | Should -Be "Node1"
    }

    It "Retourne false quand le détecteur est désactivé" {
        Initialize-CycleDetector -Enabled $false
        $graph = New-TestGraph -WithCycle

        $result = Find-Cycle -Graph $graph

        $result.HasCycle | Should -BeFalse
    }

    It "Utilise le cache pour les appels répétés" {
        $graph = New-TestGraph -WithCycle

        # Premier appel
        $result1 = Find-Cycle -Graph $graph

        # Deuxième appel
        $result2 = Find-Cycle -Graph $graph

        $result1.HasCycle | Should -BeTrue
        $result2.HasCycle | Should -BeTrue

        # Vérifier que les résultats sont identiques
        $result1.CyclePath.Count | Should -Be $result2.CyclePath.Count
    }

    It "Ignore le cache quand SkipCache est spécifié" {
        $graph = New-TestGraph -WithCycle

        # Réinitialiser les statistiques
        $Global:CycleDetectorStats.CacheHits = 0
        $Global:CycleDetectorStats.CacheMisses = 0
        $Global:CycleDetectorStats.TotalCalls = 0

        # Premier appel
        $result1 = Find-Cycle -Graph $graph

        # Deuxième appel avec SkipCache
        $result2 = Find-Cycle -Graph $graph -SkipCache

        $result1.HasCycle | Should -BeTrue
        $result2.HasCycle | Should -BeTrue

        # Vérifier que les statistiques sont cohérentes
        $stats = Get-CycleDetectionStatistics
        $stats.TotalCalls | Should -BeGreaterOrEqual 2
    }
}

Describe "Find-GraphCycle" {
    It "Détecte l'absence de cycle dans un graphe linéaire" {
        $graph = New-TestGraph

        $result = Find-GraphCycle -Graph $graph

        $result.HasCycle | Should -BeFalse
        $result.CyclePath | Should -BeNullOrEmpty
    }

    It "Détecte un cycle dans un graphe cyclique" {
        $graph = New-TestGraph -WithCycle

        $result = Find-GraphCycle -Graph $graph

        $result.HasCycle | Should -BeTrue
        $result.CyclePath | Should -Not -BeNullOrEmpty
    }

    It "Détecte une boucle sur soi-même" {
        $graph = New-TestGraph -WithSelfLoop

        $result = Find-GraphCycle -Graph $graph

        $result.HasCycle | Should -BeTrue
        $result.CyclePath.Count | Should -Be 2
        $result.CyclePath[0] | Should -Be "Node1"
        $result.CyclePath[1] | Should -Be "Node1"
    }

    It "Respecte la profondeur maximale" {
        $graph = @{}
        # Créer un graphe en chaîne de 20 nœuds
        for ($i = 1; $i -lt 20; $i++) {
            $graph["Node$i"] = @("Node$($i+1)")
        }
        # Ajouter un cycle à la fin
        $graph["Node20"] = @("Node10")

        # Limiter la profondeur à 5 (ne devrait pas détecter le cycle)
        $result = Find-GraphCycle -Graph $graph -MaxDepth 5

        $result.HasCycle | Should -BeFalse

        # Avec une profondeur suffisante, devrait détecter le cycle
        $result2 = Find-GraphCycle -Graph $graph -MaxDepth 20

        $result2.HasCycle | Should -BeTrue
    }
}

Describe "Get-CycleDetectionStatistics" {
    BeforeAll {
        # Réinitialiser les statistiques
        Initialize-CycleDetector
        Clear-CycleDetectionCache
    }

    It "Retourne les statistiques d'utilisation" {
        # Réinitialiser les statistiques
        $Global:CycleDetectorStats.TotalCalls = 0
        $Global:CycleDetectorStats.TotalCycles = 0

        # Effectuer quelques appels pour générer des statistiques
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
    It "Vide le cache du détecteur" {
        # Remplir le cache
        $graph = New-TestGraph -WithCycle
        Find-Cycle -Graph $graph

        # Vérifier que le cache est vidé
        Clear-CycleDetectionCache

        # Vérifier que le cache est vide
        $Global:CycleDetectorCache.Count | Should -Be 0
    }
}

# Tests de performance
Describe "Performance" -Tag "Performance" {
    It "Gère efficacement les grands graphes" {
        # Créer un grand graphe (1000 nœuds)
        $graph = @{}
        for ($i = 1; $i -lt 1000; $i++) {
            $graph["Node$i"] = @("Node$($i+1)")
        }
        $graph["Node1000"] = @()

        # Mesurer le temps d'exécution
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $result = Find-Cycle -Graph $graph
        $sw.Stop()

        $result.HasCycle | Should -BeFalse
        $sw.ElapsedMilliseconds | Should -BeLessThan 5000 # Moins de 5 secondes
    }
}

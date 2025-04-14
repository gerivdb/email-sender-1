BeforeAll {
    # Importer le module à tester
    $global:modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\maintenance\performance\PerformanceCounterManager.psm1"
    Import-Module $global:modulePath -Force

    # Définir des compteurs de test
    $global:testCounters = @(
        "\Processor(_Total)\% Processor Time",
        "\Memory\Available MBytes"
    )

    # Fonction pour créer un mock de Get-Counter
    # Utilisation d'une fonction interne pour éviter l'avertissement PSUseApprovedVerbs
    function New-MockCounter {
        param (
            [Parameter(Mandatory = $true)]
            [string]$CounterPath,

            [Parameter(Mandatory = $false)]
            [switch]$ThrowError
        )

        if ($ThrowError) {
            throw "Erreur simulée pour le test"
        }

        # Créer un objet CounterSample simulé
        $sample = New-Object PSObject
        $sample | Add-Member -MemberType NoteProperty -Name "Path" -Value $CounterPath
        $sample | Add-Member -MemberType NoteProperty -Name "CookedValue" -Value (Get-Random -Minimum 0 -Maximum 100)

        # Créer un objet CounterSamples simulé
        $samples = @($sample)

        # Créer un objet PerformanceCounterSampleSet simulé
        $result = New-Object PSObject
        $result | Add-Member -MemberType NoteProperty -Name "CounterSamples" -Value $samples

        return $result
    }
}

Describe "Get-SafeCounter" {
    BeforeEach {
        # Réinitialiser le cache avant chaque test
        Clear-CounterCache

        # Mock de Get-Counter
        Mock Get-Counter {
            $counterPath = $Counter[0]
            return New-MockCounter -CounterPath $counterPath
        } -ModuleName PerformanceCounterManager
    }

    It "Obtient les valeurs des compteurs de performance" {
        $result = Get-SafeCounter -CounterPath $global:testCounters[0]
        $result | Should -BeOfType [System.Double]
        $result | Should -BeGreaterOrEqual 0
        $result | Should -BeLessOrEqual 100
    }

    It "Utilise le cache lorsque spécifié" {
        # Première appel pour remplir le cache
        $result1 = Get-SafeCounter -CounterPath $global:testCounters[0]

        # Deuxième appel avec cache
        $result2 = Get-SafeCounter -CounterPath $global:testCounters[0] -UseCache

        # Les résultats devraient être identiques
        $result2 | Should -Be $result1
    }

    It "Gère les erreurs et utilise des valeurs par défaut" {
        # Mock de Get-Counter pour simuler une erreur
        Mock Get-Counter {
            throw "Erreur simulée pour le test"
        } -ModuleName PerformanceCounterManager

        # Mock de Get-AlternativeMetric pour simuler un échec
        Mock Get-AlternativeMetric {
            return $null
        } -ModuleName PerformanceCounterManager

        # Appel avec une valeur par défaut spécifiée
        $defaultValue = 42
        $result = Get-SafeCounter -CounterPath $global:testCounters[0] -DefaultValue $defaultValue

        # Le résultat devrait être la valeur par défaut
        $result | Should -Be $defaultValue
    }

    It "Utilise des méthodes alternatives en cas d'échec" {
        # Mock de Get-Counter pour simuler une erreur
        Mock Get-Counter {
            throw "Erreur simulée pour le test"
        } -ModuleName PerformanceCounterManager

        # Mock de Get-AlternativeMetric pour simuler une valeur alternative
        Mock Get-AlternativeMetric {
            return 75
        } -ModuleName PerformanceCounterManager

        # Appel avec utilisation de méthodes alternatives
        $result = Get-SafeCounter -CounterPath $global:testCounters[0] -UseAlternativeMethods

        # Le résultat devrait être la valeur alternative
        $result | Should -Be 75
    }
}

Describe "Get-AlternativeMetric" {
    It "Obtient des métriques alternatives pour l'utilisation du processeur" {
        # Mock de Get-CimInstance pour simuler l'utilisation du processeur
        Mock Get-CimInstance {
            $result = @()
            $cpu = New-Object PSObject
            $cpu | Add-Member -MemberType NoteProperty -name "LoadPercentage" -Value 50
            $result += $cpu
            return $result
        } -ModuleName PerformanceCounterManager

        $result = Get-AlternativeMetric -CounterPath "\Processor(_Total)\% Processor Time"
        $result | Should -Be 50
    }

    It "Obtient des métriques alternatives pour la mémoire disponible" {
        # Mock de Get-CimInstance pour simuler la mémoire disponible
        Mock Get-CimInstance {
            $memory = New-Object PSObject
            $memory | Add-Member -MemberType NoteProperty -name "FreePhysicalMemory" -Value 4194304 # 4 Go en Ko
            return $memory
        } -ModuleName PerformanceCounterManager

        $result = Get-AlternativeMetric -CounterPath "\Memory\Available MBytes"
        $result | Should -Be 4096 # 4 Go en Mo
    }

    It "Retourne null pour les compteurs non pris en charge" {
        $result = Get-AlternativeMetric -CounterPath "\Compteur\Inexistant"
        $result | Should -Be $null
    }
}

Describe "Get-IntelligentDefaultValue" {
    BeforeEach {
        # Réinitialiser le cache avant chaque test
        Clear-CounterCache
    }

    It "Retourne une valeur par défaut intelligente pour l'utilisation du processeur" {
        $result = Get-IntelligentDefaultValue -CounterPath "\Processor(_Total)\% Processor Time"
        $result | Should -Be 42 # Valeur typique pour l'utilisation du processeur
    }

    It "Retourne une valeur par défaut intelligente pour la mémoire disponible" {
        # Mock de Get-CimInstance pour simuler la mémoire totale
        Mock Get-CimInstance {
            $memory = New-Object PSObject
            $memory | Add-Member -MemberType NoteProperty -name "TotalVisibleMemorySize" -Value 8388608 # 8 Go en Ko
            return $memory
        } -ModuleName PerformanceCounterManager

        $result = Get-IntelligentDefaultValue -CounterPath "\Memory\Available MBytes"
        $result | Should -Be 2458 # Environ 30% de 8 Go
    }

    It "Utilise la valeur par défaut fournie pour les compteurs non reconnus" {
        $defaultValue = 42
        $result = Get-IntelligentDefaultValue -CounterPath "\Compteur\Inexistant" -DefaultValue $defaultValue
        $result | Should -Be $defaultValue
    }

    It "Utilise la dernière valeur connue si disponible" {
        # Remplir le cache avec une valeur
        $counterPath = "\Processor(_Total)\% Processor Time"
        $cachedValue = 45

        # Accéder aux variables de script du module
        $scriptModule = Get-Module PerformanceCounterManager
        $scriptModule.Invoke({ $script:CounterCache[$args[0]] = $args[1] }, $counterPath, $cachedValue)
        $scriptModule.Invoke({ $script:LastUpdateTime[$args[0]] = (Get-Date).AddMinutes(-30) }, $counterPath)

        # Obtenir une valeur par défaut intelligente
        $result = Get-IntelligentDefaultValue -CounterPath $counterPath

        # Le résultat devrait être la valeur en cache
        $result | Should -Be $cachedValue
    }
}

Describe "Clear-CounterCache" {
    BeforeEach {
        # Remplir le cache avec des valeurs
        $counterPath = "\Processor(_Total)\% Processor Time"
        $cachedValue = 45

        # Accéder aux variables de script du module
        $scriptModule = Get-Module PerformanceCounterManager
        $scriptModule.Invoke({ $script:CounterCache[$args[0]] = $args[1] }, $counterPath, $cachedValue)
        $scriptModule.Invoke({ $script:LastUpdateTime[$args[0]] = Get-Date }, $counterPath)
        $scriptModule.Invoke({ $script:FailureCount[$args[0]] = 2 }, $counterPath)
    }

    It "Efface un compteur spécifique du cache" {
        $counterPath = "\Processor(_Total)\% Processor Time"

        # Vérifier que le compteur est dans le cache
        $scriptModule = Get-Module PerformanceCounterManager
        $cacheContainsCounter = $scriptModule.Invoke({ $script:CounterCache.ContainsKey($args[0]) }, $counterPath)
        $cacheContainsCounter | Should -Be $true

        # Effacer le compteur du cache
        Clear-CounterCache -CounterPath $counterPath

        # Vérifier que le compteur n'est plus dans le cache
        $cacheContainsCounter = $scriptModule.Invoke({ $script:CounterCache.ContainsKey($args[0]) }, $counterPath)
        $cacheContainsCounter | Should -Be $false
    }

    It "Efface tout le cache" {
        # Vérifier que le cache n'est pas vide
        $scriptModule = Get-Module PerformanceCounterManager
        $cacheCount = $scriptModule.Invoke({ $script:CounterCache.Count })
        $cacheCount | Should -BeGreaterThan 0

        # Effacer tout le cache
        Clear-CounterCache

        # Vérifier que le cache est vide
        $cacheCount = $scriptModule.Invoke({ $script:CounterCache.Count })
        $cacheCount | Should -Be 0
    }
}

Describe "Get-CounterStatistics" {
    BeforeEach {
        # Réinitialiser le cache avant chaque test
        Clear-CounterCache

        # Remplir le cache avec des valeurs
        $counterPath1 = "\Processor(_Total)\% Processor Time"
        $counterPath2 = "\Memory\Available MBytes"

        # Accéder aux variables de script du module
        $scriptModule = Get-Module PerformanceCounterManager
        $scriptModule.Invoke({ $script:CounterCache[$args[0]] = 45 }, $counterPath1)
        $scriptModule.Invoke({ $script:LastUpdateTime[$args[0]] = Get-Date }, $counterPath1)
        $scriptModule.Invoke({ $script:FailureCount[$args[0]] = 2 }, $counterPath1)

        $scriptModule.Invoke({ $script:CounterCache[$args[0]] = 2048 }, $counterPath2)
        $scriptModule.Invoke({ $script:LastUpdateTime[$args[0]] = Get-Date }, $counterPath2)
        $scriptModule.Invoke({ $script:FailureCount[$args[0]] = 0 }, $counterPath2)
    }

    It "Obtient des statistiques pour un compteur spécifique" {
        $counterPath = "\Processor(_Total)\% Processor Time"
        $statistics = Get-CounterStatistics -CounterPath $counterPath

        $statistics.Keys | Should -Contain $counterPath
        $statistics[$counterPath].CounterPath | Should -Be $counterPath
        $statistics[$counterPath].CachedValue | Should -Be 45
        $statistics[$counterPath].FailureCount | Should -Be 2
    }

    It "Obtient des statistiques pour tous les compteurs" {
        $statistics = Get-CounterStatistics

        $statistics.Keys.Count | Should -Be 2
        $statistics.Keys | Should -Contain "\Processor(_Total)\% Processor Time"
        $statistics.Keys | Should -Contain "\Memory\Available MBytes"
    }
}

#Requires -Version 5.1
<#
.SYNOPSIS
    Tests de performance pour le système de cache d'analyse des pull requests.
.DESCRIPTION
    Ce fichier contient des tests de performance pour le système de cache d'analyse
    des pull requests, mesurant les temps d'exécution et l'utilisation des ressources.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Requires: Pester v5.0+, PRAnalysisCache.psm1
#>

# Importer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"

# Vérifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Module PRAnalysisCache.psm1 non trouvé à l'emplacement: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# Variables globales pour les tests
$script:testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCachePerformance"

# Créer des données de test
BeforeAll {
    # Créer le répertoire de cache de test
    New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null

    # Fonction pour mesurer le temps d'exécution
    function Measure-ExecutionTime {
        param(
            [Parameter(Mandatory = $true)]
            [scriptblock]$ScriptBlock
        )

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        & $ScriptBlock
        $stopwatch.Stop()

        return $stopwatch.Elapsed
    }

    # Fonction pour mesurer l'utilisation de la mémoire
    function Measure-MemoryUsage {
        param(
            [Parameter(Mandatory = $true)]
            [scriptblock]$ScriptBlock
        )

        # Collecter les déchets avant de commencer
        [System.GC]::Collect()

        # Mesurer la mémoire avant
        $processBegin = Get-Process -Id $PID
        $memoryBegin = $processBegin.WorkingSet64

        # Exécuter le script
        & $ScriptBlock

        # Collecter les déchets après
        [System.GC]::Collect()

        # Mesurer la mémoire après
        $processEnd = Get-Process -Id $PID
        $memoryEnd = $processEnd.WorkingSet64

        # Calculer la différence
        $memoryDiff = $memoryEnd - $memoryBegin

        return $memoryDiff
    }

    # Créer des données de test de différentes tailles
    $script:smallData = "Small test data"
    $script:mediumData = "A" * 10KB
    $script:largeData = "B" * 100KB
    $script:veryLargeData = "C" * 1MB

    # Créer un objet complexe
    $script:complexObject = @{
        Name          = "Complex Object"
        Properties    = @{
            StringProp = "Test String"
            IntProp    = 42
            BoolProp   = $true
            DateProp   = Get-Date
        }
        Items         = @(
            @{ Id = 1; Name = "Item 1" },
            @{ Id = 2; Name = "Item 2" },
            @{ Id = 3; Name = "Item 3" }
        )
        NestedObjects = @(
            @{
                Id       = 1
                SubItems = @(
                    @{ Id = 1.1; Name = "SubItem 1.1" },
                    @{ Id = 1.2; Name = "SubItem 1.2" }
                )
            },
            @{
                Id       = 2
                SubItems = @(
                    @{ Id = 2.1; Name = "SubItem 2.1" },
                    @{ Id = 2.2; Name = "SubItem 2.2" }
                )
            }
        )
    }
}

Describe "PRCache Performance Tests" {
    Context "Basic Operations Performance" {
        BeforeEach {
            # Créer un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache -MaxMemoryItems 1000
            # Rediriger le chemin du cache vers le répertoire de test
            $script:cache.DiskCachePath = $script:testCachePath
        }

        It "Mesure le temps d'ajout d'éléments" {
            # Mesurer le temps d'ajout d'un petit élément
            $smallTime = Measure-ExecutionTime { $script:cache.SetItem("SmallKey", $script:smallData, (New-TimeSpan -Hours 1)) }

            # Mesurer le temps d'ajout d'un élément moyen
            $mediumTime = Measure-ExecutionTime { $script:cache.SetItem("MediumKey", $script:mediumData, (New-TimeSpan -Hours 1)) }

            # Mesurer le temps d'ajout d'un grand élément
            $largeTime = Measure-ExecutionTime { $script:cache.SetItem("LargeKey", $script:largeData, (New-TimeSpan -Hours 1)) }

            # Mesurer le temps d'ajout d'un très grand élément
            $veryLargeTime = Measure-ExecutionTime { $script:cache.SetItem("VeryLargeKey", $script:veryLargeData, (New-TimeSpan -Hours 1)) }

            # Mesurer le temps d'ajout d'un objet complexe
            $complexTime = Measure-ExecutionTime { $script:cache.SetItem("ComplexKey", $script:complexObject, (New-TimeSpan -Hours 1)) }

            # Afficher les résultats
            Write-Host "Temps d'ajout d'un petit élément: $($smallTime.TotalMilliseconds) ms"
            Write-Host "Temps d'ajout d'un élément moyen: $($mediumTime.TotalMilliseconds) ms"
            Write-Host "Temps d'ajout d'un grand élément: $($largeTime.TotalMilliseconds) ms"
            Write-Host "Temps d'ajout d'un très grand élément: $($veryLargeTime.TotalMilliseconds) ms"
            Write-Host "Temps d'ajout d'un objet complexe: $($complexTime.TotalMilliseconds) ms"

            # Vérifier que les temps sont raisonnables
            $smallTime.TotalMilliseconds | Should -BeLessThan 100
            $veryLargeTime.TotalMilliseconds | Should -BeGreaterThan $smallTime.TotalMilliseconds
        }

        It "Mesure le temps de récupération d'éléments" {
            # Ajouter des éléments au cache
            $script:cache.SetItem("SmallKey", $script:smallData, (New-TimeSpan -Hours 1))
            $script:cache.SetItem("MediumKey", $script:mediumData, (New-TimeSpan -Hours 1))
            $script:cache.SetItem("LargeKey", $script:largeData, (New-TimeSpan -Hours 1))
            $script:cache.SetItem("VeryLargeKey", $script:veryLargeData, (New-TimeSpan -Hours 1))
            $script:cache.SetItem("ComplexKey", $script:complexObject, (New-TimeSpan -Hours 1))

            # Mesurer le temps de récupération d'un petit élément
            $smallTime = Measure-ExecutionTime { $script:cache.GetItem("SmallKey") }

            # Mesurer le temps de récupération d'un élément moyen
            $mediumTime = Measure-ExecutionTime { $script:cache.GetItem("MediumKey") }

            # Mesurer le temps de récupération d'un grand élément
            $largeTime = Measure-ExecutionTime { $script:cache.GetItem("LargeKey") }

            # Mesurer le temps de récupération d'un très grand élément
            $veryLargeTime = Measure-ExecutionTime { $script:cache.GetItem("VeryLargeKey") }

            # Mesurer le temps de récupération d'un objet complexe
            $complexTime = Measure-ExecutionTime { $script:cache.GetItem("ComplexKey") }

            # Afficher les résultats
            Write-Host "Temps de récupération d'un petit élément: $($smallTime.TotalMilliseconds) ms"
            Write-Host "Temps de récupération d'un élément moyen: $($mediumTime.TotalMilliseconds) ms"
            Write-Host "Temps de récupération d'un grand élément: $($largeTime.TotalMilliseconds) ms"
            Write-Host "Temps de récupération d'un très grand élément: $($veryLargeTime.TotalMilliseconds) ms"
            Write-Host "Temps de récupération d'un objet complexe: $($complexTime.TotalMilliseconds) ms"

            # Vérifier que les temps sont raisonnables
            $smallTime.TotalMilliseconds | Should -BeLessThan 50
            $veryLargeTime.TotalMilliseconds | Should -BeGreaterThan $smallTime.TotalMilliseconds
        }
    }

    Context "Memory Usage" {
        BeforeEach {
            # Créer un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache -MaxMemoryItems 1000
            # Rediriger le chemin du cache vers le répertoire de test
            $script:cache.DiskCachePath = $script:testCachePath
        }

        It "Mesure l'utilisation de la mémoire pour différentes tailles de données" {
            # Mesurer l'utilisation de la mémoire pour un petit élément
            $smallMemory = Measure-MemoryUsage { $script:cache.SetItem("SmallKey", $script:smallData, (New-TimeSpan -Hours 1)) }

            # Mesurer l'utilisation de la mémoire pour un élément moyen
            $mediumMemory = Measure-MemoryUsage { $script:cache.SetItem("MediumKey", $script:mediumData, (New-TimeSpan -Hours 1)) }

            # Mesurer l'utilisation de la mémoire pour un grand élément
            $largeMemory = Measure-MemoryUsage { $script:cache.SetItem("LargeKey", $script:largeData, (New-TimeSpan -Hours 1)) }

            # Mesurer l'utilisation de la mémoire pour un très grand élément
            $veryLargeMemory = Measure-MemoryUsage { $script:cache.SetItem("VeryLargeKey", $script:veryLargeData, (New-TimeSpan -Hours 1)) }

            # Afficher les résultats
            Write-Host "Utilisation de la mémoire pour un petit élément: $($smallMemory / 1KB) KB"
            Write-Host "Utilisation de la mémoire pour un élément moyen: $($mediumMemory / 1KB) KB"
            Write-Host "Utilisation de la mémoire pour un grand élément: $($largeMemory / 1KB) KB"
            Write-Host "Utilisation de la mémoire pour un très grand élément: $($veryLargeMemory / 1KB) KB"

            # Vérifier que l'utilisation de la mémoire est proportionnelle à la taille des données
            $veryLargeMemory | Should -BeGreaterThan $largeMemory
            $largeMemory | Should -BeGreaterThan $mediumMemory
        }

        It "Mesure l'utilisation de la mémoire lors de l'ajout de nombreux éléments" {
            # Mesurer l'utilisation de la mémoire pour l'ajout de 100 éléments
            $memory100 = Measure-MemoryUsage {
                for ($i = 1; $i -le 100; $i++) {
                    $script:cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
                }
            }

            # Mesurer l'utilisation de la mémoire pour l'ajout de 100 éléments supplémentaires
            $memory200 = Measure-MemoryUsage {
                for ($i = 101; $i -le 200; $i++) {
                    $script:cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
                }
            }

            # Afficher les résultats
            Write-Host "Utilisation de la mémoire pour 100 éléments: $($memory100 / 1KB) KB"
            Write-Host "Utilisation de la mémoire pour 200 éléments: $(($memory100 + $memory200) / 1KB) KB"

            # Vérifier que l'utilisation de la mémoire augmente avec le nombre d'éléments
            $memory100 | Should -BeGreaterThan 0
        }
    }

    Context "Scalability" {
        BeforeEach {
            # Créer un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache -MaxMemoryItems 10000
            # Rediriger le chemin du cache vers le répertoire de test
            $script:cache.DiskCachePath = $script:testCachePath
        }

        It "Mesure les performances avec un grand nombre d'éléments" {
            # Mesurer le temps d'ajout de 1000 éléments
            $addTime = Measure-ExecutionTime {
                for ($i = 1; $i -le 1000; $i++) {
                    $script:cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
                }
            }

            # Mesurer le temps de récupération de 1000 éléments
            $getTime = Measure-ExecutionTime {
                for ($i = 1; $i -le 1000; $i++) {
                    $value = $script:cache.GetItem("Key$i")
                }
            }

            # Mesurer le temps de récupération de 1000 éléments (deuxième passe - devrait être plus rapide)
            $getTime2 = Measure-ExecutionTime {
                for ($i = 1; $i -le 1000; $i++) {
                    $value = $script:cache.GetItem("Key$i")
                }
            }

            # Afficher les résultats
            Write-Host "Temps d'ajout de 1000 éléments: $($addTime.TotalSeconds) secondes"
            Write-Host "Temps de récupération de 1000 éléments (première passe): $($getTime.TotalSeconds) secondes"
            Write-Host "Temps de récupération de 1000 éléments (deuxième passe): $($getTime2.TotalSeconds) secondes"

            # Vérifier que les temps sont raisonnables
            $addTime.TotalSeconds | Should -BeLessThan 10
            $getTime.TotalSeconds | Should -BeLessThan 5
            $getTime2.TotalSeconds | Should -BeLessThan $getTime.TotalSeconds
        }

        It "Mesure les performances de nettoyage du cache" {
            # Ajouter plus d'éléments que la limite
            for ($i = 1; $i -le 12000; $i++) {
                $script:cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
            }

            # Mesurer le temps de nettoyage du cache
            $cleanTime = Measure-ExecutionTime {
                $script:cache.CleanMemoryCache()
            }

            # Afficher les résultats
            Write-Host "Temps de nettoyage du cache avec 12000 éléments: $($cleanTime.TotalMilliseconds) ms"

            # Vérifier que le temps est raisonnable
            $cleanTime.TotalSeconds | Should -BeLessThan 5

            # Vérifier que le cache a été nettoyé
            $script:cache.MemoryCache.Count | Should -Be 10000
        }
    }

    Context "Disk Cache Performance" {
        BeforeEach {
            # Créer un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache -MaxMemoryItems 100
            # Rediriger le chemin du cache vers le répertoire de test
            $script:cache.DiskCachePath = $script:testCachePath

            # Vider le répertoire de cache
            Get-ChildItem -Path $script:testCachePath -File | Remove-Item -Force
        }

        It "Mesure les performances du cache sur disque" {
            # Ajouter des éléments au cache
            for ($i = 1; $i -le 200; $i++) {
                $script:cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
            }

            # Vérifier que certains éléments sont sur disque uniquement
            $script:cache.MemoryCache.Count | Should -Be 100

            # Mesurer le temps de récupération d'un élément en mémoire
            $memoryTime = Measure-ExecutionTime {
                $value = $script:cache.GetItem("Key100")
            }

            # Mesurer le temps de récupération d'un élément sur disque
            $diskTime = Measure-ExecutionTime {
                $value = $script:cache.GetItem("Key200")
            }

            # Afficher les résultats
            Write-Host "Temps de récupération d'un élément en mémoire: $($memoryTime.TotalMilliseconds) ms"
            Write-Host "Temps de récupération d'un élément sur disque: $($diskTime.TotalMilliseconds) ms"

            # Vérifier que le temps de récupération sur disque est plus long
            $diskTime.TotalMilliseconds | Should -BeGreaterThan $memoryTime.TotalMilliseconds
        }

        It "Mesure les performances de sérialisation/désérialisation" {
            # Mesurer le temps de sérialisation d'un objet complexe
            $serializeTime = Measure-ExecutionTime {
                $script:cache.SetItem("ComplexKey", $script:complexObject, (New-TimeSpan -Hours 1))
            }

            # Vider le cache en mémoire pour forcer la désérialisation depuis le disque
            $script:cache.MemoryCache.Clear()

            # Mesurer le temps de désérialisation d'un objet complexe
            $deserializeTime = Measure-ExecutionTime {
                $value = $script:cache.GetItem("ComplexKey")
            }

            # Afficher les résultats
            Write-Host "Temps de sérialisation d'un objet complexe: $($serializeTime.TotalMilliseconds) ms"
            Write-Host "Temps de désérialisation d'un objet complexe: $($deserializeTime.TotalMilliseconds) ms"

            # Vérifier que les temps sont raisonnables
            $serializeTime.TotalSeconds | Should -BeLessThan 1
            $deserializeTime.TotalSeconds | Should -BeLessThan 1
        }
    }
}

#Requires -Version 5.1
<#
.SYNOPSIS
    Tests de performance pour le systÃ¨me de cache d'analyse des pull requests.
.DESCRIPTION
    Ce fichier contient des tests de performance pour le systÃ¨me de cache d'analyse
    des pull requests, mesurant les temps d'exÃ©cution et l'utilisation des ressources.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Requires: Pester v5.0+, PRAnalysisCache.psm1
#>

# Importer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du module Ã  tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\PRAnalysisCache.psm1"

# VÃ©rifier que le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Module PRAnalysisCache.psm1 non trouvÃ© Ã  l'emplacement: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# Variables globales pour les tests
$script:testCachePath = Join-Path -Path $env:TEMP -ChildPath "PRCachePerformance"

# CrÃ©er des donnÃ©es de test
BeforeAll {
    # CrÃ©er le rÃ©pertoire de cache de test
    New-Item -Path $script:testCachePath -ItemType Directory -Force | Out-Null

    # Fonction pour mesurer le temps d'exÃ©cution
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

    # Fonction pour mesurer l'utilisation de la mÃ©moire
    function Measure-MemoryUsage {
        param(
            [Parameter(Mandatory = $true)]
            [scriptblock]$ScriptBlock
        )

        # Collecter les dÃ©chets avant de commencer
        [System.GC]::Collect()

        # Mesurer la mÃ©moire avant
        $processBegin = Get-Process -Id $PID
        $memoryBegin = $processBegin.WorkingSet64

        # ExÃ©cuter le script
        & $ScriptBlock

        # Collecter les dÃ©chets aprÃ¨s
        [System.GC]::Collect()

        # Mesurer la mÃ©moire aprÃ¨s
        $processEnd = Get-Process -Id $PID
        $memoryEnd = $processEnd.WorkingSet64

        # Calculer la diffÃ©rence
        $memoryDiff = $memoryEnd - $memoryBegin

        return $memoryDiff
    }

    # CrÃ©er des donnÃ©es de test de diffÃ©rentes tailles
    $script:smallData = "Small test data"
    $script:mediumData = "A" * 10KB
    $script:largeData = "B" * 100KB
    $script:veryLargeData = "C" * 1MB

    # CrÃ©er un objet complexe
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
            # CrÃ©er un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache -MaxMemoryItems 1000
            # Rediriger le chemin du cache vers le rÃ©pertoire de test
            $script:cache.DiskCachePath = $script:testCachePath
        }

        It "Mesure le temps d'ajout d'Ã©lÃ©ments" {
            # Mesurer le temps d'ajout d'un petit Ã©lÃ©ment
            $smallTime = Measure-ExecutionTime { $script:cache.SetItem("SmallKey", $script:smallData, (New-TimeSpan -Hours 1)) }

            # Mesurer le temps d'ajout d'un Ã©lÃ©ment moyen
            $mediumTime = Measure-ExecutionTime { $script:cache.SetItem("MediumKey", $script:mediumData, (New-TimeSpan -Hours 1)) }

            # Mesurer le temps d'ajout d'un grand Ã©lÃ©ment
            $largeTime = Measure-ExecutionTime { $script:cache.SetItem("LargeKey", $script:largeData, (New-TimeSpan -Hours 1)) }

            # Mesurer le temps d'ajout d'un trÃ¨s grand Ã©lÃ©ment
            $veryLargeTime = Measure-ExecutionTime { $script:cache.SetItem("VeryLargeKey", $script:veryLargeData, (New-TimeSpan -Hours 1)) }

            # Mesurer le temps d'ajout d'un objet complexe
            $complexTime = Measure-ExecutionTime { $script:cache.SetItem("ComplexKey", $script:complexObject, (New-TimeSpan -Hours 1)) }

            # Afficher les rÃ©sultats
            Write-Host "Temps d'ajout d'un petit Ã©lÃ©ment: $($smallTime.TotalMilliseconds) ms"
            Write-Host "Temps d'ajout d'un Ã©lÃ©ment moyen: $($mediumTime.TotalMilliseconds) ms"
            Write-Host "Temps d'ajout d'un grand Ã©lÃ©ment: $($largeTime.TotalMilliseconds) ms"
            Write-Host "Temps d'ajout d'un trÃ¨s grand Ã©lÃ©ment: $($veryLargeTime.TotalMilliseconds) ms"
            Write-Host "Temps d'ajout d'un objet complexe: $($complexTime.TotalMilliseconds) ms"

            # VÃ©rifier que les temps sont raisonnables
            $smallTime.TotalMilliseconds | Should -BeLessThan 100
            $veryLargeTime.TotalMilliseconds | Should -BeGreaterThan $smallTime.TotalMilliseconds
        }

        It "Mesure le temps de rÃ©cupÃ©ration d'Ã©lÃ©ments" {
            # Ajouter des Ã©lÃ©ments au cache
            $script:cache.SetItem("SmallKey", $script:smallData, (New-TimeSpan -Hours 1))
            $script:cache.SetItem("MediumKey", $script:mediumData, (New-TimeSpan -Hours 1))
            $script:cache.SetItem("LargeKey", $script:largeData, (New-TimeSpan -Hours 1))
            $script:cache.SetItem("VeryLargeKey", $script:veryLargeData, (New-TimeSpan -Hours 1))
            $script:cache.SetItem("ComplexKey", $script:complexObject, (New-TimeSpan -Hours 1))

            # Mesurer le temps de rÃ©cupÃ©ration d'un petit Ã©lÃ©ment
            $smallTime = Measure-ExecutionTime { $script:cache.GetItem("SmallKey") }

            # Mesurer le temps de rÃ©cupÃ©ration d'un Ã©lÃ©ment moyen
            $mediumTime = Measure-ExecutionTime { $script:cache.GetItem("MediumKey") }

            # Mesurer le temps de rÃ©cupÃ©ration d'un grand Ã©lÃ©ment
            $largeTime = Measure-ExecutionTime { $script:cache.GetItem("LargeKey") }

            # Mesurer le temps de rÃ©cupÃ©ration d'un trÃ¨s grand Ã©lÃ©ment
            $veryLargeTime = Measure-ExecutionTime { $script:cache.GetItem("VeryLargeKey") }

            # Mesurer le temps de rÃ©cupÃ©ration d'un objet complexe
            $complexTime = Measure-ExecutionTime { $script:cache.GetItem("ComplexKey") }

            # Afficher les rÃ©sultats
            Write-Host "Temps de rÃ©cupÃ©ration d'un petit Ã©lÃ©ment: $($smallTime.TotalMilliseconds) ms"
            Write-Host "Temps de rÃ©cupÃ©ration d'un Ã©lÃ©ment moyen: $($mediumTime.TotalMilliseconds) ms"
            Write-Host "Temps de rÃ©cupÃ©ration d'un grand Ã©lÃ©ment: $($largeTime.TotalMilliseconds) ms"
            Write-Host "Temps de rÃ©cupÃ©ration d'un trÃ¨s grand Ã©lÃ©ment: $($veryLargeTime.TotalMilliseconds) ms"
            Write-Host "Temps de rÃ©cupÃ©ration d'un objet complexe: $($complexTime.TotalMilliseconds) ms"

            # VÃ©rifier que les temps sont raisonnables
            $smallTime.TotalMilliseconds | Should -BeLessThan 50
            $veryLargeTime.TotalMilliseconds | Should -BeGreaterThan $smallTime.TotalMilliseconds
        }
    }

    Context "Memory Usage" {
        BeforeEach {
            # CrÃ©er un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache -MaxMemoryItems 1000
            # Rediriger le chemin du cache vers le rÃ©pertoire de test
            $script:cache.DiskCachePath = $script:testCachePath
        }

        It "Mesure l'utilisation de la mÃ©moire pour diffÃ©rentes tailles de donnÃ©es" {
            # Mesurer l'utilisation de la mÃ©moire pour un petit Ã©lÃ©ment
            $smallMemory = Measure-MemoryUsage { $script:cache.SetItem("SmallKey", $script:smallData, (New-TimeSpan -Hours 1)) }

            # Mesurer l'utilisation de la mÃ©moire pour un Ã©lÃ©ment moyen
            $mediumMemory = Measure-MemoryUsage { $script:cache.SetItem("MediumKey", $script:mediumData, (New-TimeSpan -Hours 1)) }

            # Mesurer l'utilisation de la mÃ©moire pour un grand Ã©lÃ©ment
            $largeMemory = Measure-MemoryUsage { $script:cache.SetItem("LargeKey", $script:largeData, (New-TimeSpan -Hours 1)) }

            # Mesurer l'utilisation de la mÃ©moire pour un trÃ¨s grand Ã©lÃ©ment
            $veryLargeMemory = Measure-MemoryUsage { $script:cache.SetItem("VeryLargeKey", $script:veryLargeData, (New-TimeSpan -Hours 1)) }

            # Afficher les rÃ©sultats
            Write-Host "Utilisation de la mÃ©moire pour un petit Ã©lÃ©ment: $($smallMemory / 1KB) KB"
            Write-Host "Utilisation de la mÃ©moire pour un Ã©lÃ©ment moyen: $($mediumMemory / 1KB) KB"
            Write-Host "Utilisation de la mÃ©moire pour un grand Ã©lÃ©ment: $($largeMemory / 1KB) KB"
            Write-Host "Utilisation de la mÃ©moire pour un trÃ¨s grand Ã©lÃ©ment: $($veryLargeMemory / 1KB) KB"

            # VÃ©rifier que l'utilisation de la mÃ©moire est proportionnelle Ã  la taille des donnÃ©es
            $veryLargeMemory | Should -BeGreaterThan $largeMemory
            $largeMemory | Should -BeGreaterThan $mediumMemory
        }

        It "Mesure l'utilisation de la mÃ©moire lors de l'ajout de nombreux Ã©lÃ©ments" {
            # Mesurer l'utilisation de la mÃ©moire pour l'ajout de 100 Ã©lÃ©ments
            $memory100 = Measure-MemoryUsage {
                for ($i = 1; $i -le 100; $i++) {
                    $script:cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
                }
            }

            # Mesurer l'utilisation de la mÃ©moire pour l'ajout de 100 Ã©lÃ©ments supplÃ©mentaires
            $memory200 = Measure-MemoryUsage {
                for ($i = 101; $i -le 200; $i++) {
                    $script:cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
                }
            }

            # Afficher les rÃ©sultats
            Write-Host "Utilisation de la mÃ©moire pour 100 Ã©lÃ©ments: $($memory100 / 1KB) KB"
            Write-Host "Utilisation de la mÃ©moire pour 200 Ã©lÃ©ments: $(($memory100 + $memory200) / 1KB) KB"

            # VÃ©rifier que l'utilisation de la mÃ©moire augmente avec le nombre d'Ã©lÃ©ments
            $memory100 | Should -BeGreaterThan 0
        }
    }

    Context "Scalability" {
        BeforeEach {
            # CrÃ©er un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache -MaxMemoryItems 10000
            # Rediriger le chemin du cache vers le rÃ©pertoire de test
            $script:cache.DiskCachePath = $script:testCachePath
        }

        It "Mesure les performances avec un grand nombre d'Ã©lÃ©ments" {
            # Mesurer le temps d'ajout de 1000 Ã©lÃ©ments
            $addTime = Measure-ExecutionTime {
                for ($i = 1; $i -le 1000; $i++) {
                    $script:cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
                }
            }

            # Mesurer le temps de rÃ©cupÃ©ration de 1000 Ã©lÃ©ments
            $getTime = Measure-ExecutionTime {
                for ($i = 1; $i -le 1000; $i++) {
                    $value = $script:cache.GetItem("Key$i")
                }
            }

            # Mesurer le temps de rÃ©cupÃ©ration de 1000 Ã©lÃ©ments (deuxiÃ¨me passe - devrait Ãªtre plus rapide)
            $getTime2 = Measure-ExecutionTime {
                for ($i = 1; $i -le 1000; $i++) {
                    $value = $script:cache.GetItem("Key$i")
                }
            }

            # Afficher les rÃ©sultats
            Write-Host "Temps d'ajout de 1000 Ã©lÃ©ments: $($addTime.TotalSeconds) secondes"
            Write-Host "Temps de rÃ©cupÃ©ration de 1000 Ã©lÃ©ments (premiÃ¨re passe): $($getTime.TotalSeconds) secondes"
            Write-Host "Temps de rÃ©cupÃ©ration de 1000 Ã©lÃ©ments (deuxiÃ¨me passe): $($getTime2.TotalSeconds) secondes"

            # VÃ©rifier que les temps sont raisonnables
            $addTime.TotalSeconds | Should -BeLessThan 10
            $getTime.TotalSeconds | Should -BeLessThan 5
            $getTime2.TotalSeconds | Should -BeLessThan $getTime.TotalSeconds
        }

        It "Mesure les performances de nettoyage du cache" {
            # Ajouter plus d'Ã©lÃ©ments que la limite
            for ($i = 1; $i -le 12000; $i++) {
                $script:cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
            }

            # Mesurer le temps de nettoyage du cache
            $cleanTime = Measure-ExecutionTime {
                $script:cache.CleanMemoryCache()
            }

            # Afficher les rÃ©sultats
            Write-Host "Temps de nettoyage du cache avec 12000 Ã©lÃ©ments: $($cleanTime.TotalMilliseconds) ms"

            # VÃ©rifier que le temps est raisonnable
            $cleanTime.TotalSeconds | Should -BeLessThan 5

            # VÃ©rifier que le cache a Ã©tÃ© nettoyÃ©
            $script:cache.MemoryCache.Count | Should -Be 10000
        }
    }

    Context "Disk Cache Performance" {
        BeforeEach {
            # CrÃ©er un nouveau cache pour chaque test
            $script:cache = New-PRAnalysisCache -MaxMemoryItems 100
            # Rediriger le chemin du cache vers le rÃ©pertoire de test
            $script:cache.DiskCachePath = $script:testCachePath

            # Vider le rÃ©pertoire de cache
            Get-ChildItem -Path $script:testCachePath -File | Remove-Item -Force
        }

        It "Mesure les performances du cache sur disque" {
            # Ajouter des Ã©lÃ©ments au cache
            for ($i = 1; $i -le 200; $i++) {
                $script:cache.SetItem("Key$i", "Value$i", (New-TimeSpan -Hours 1))
            }

            # VÃ©rifier que certains Ã©lÃ©ments sont sur disque uniquement
            $script:cache.MemoryCache.Count | Should -Be 100

            # Mesurer le temps de rÃ©cupÃ©ration d'un Ã©lÃ©ment en mÃ©moire
            $memoryTime = Measure-ExecutionTime {
                $value = $script:cache.GetItem("Key100")
            }

            # Mesurer le temps de rÃ©cupÃ©ration d'un Ã©lÃ©ment sur disque
            $diskTime = Measure-ExecutionTime {
                $value = $script:cache.GetItem("Key200")
            }

            # Afficher les rÃ©sultats
            Write-Host "Temps de rÃ©cupÃ©ration d'un Ã©lÃ©ment en mÃ©moire: $($memoryTime.TotalMilliseconds) ms"
            Write-Host "Temps de rÃ©cupÃ©ration d'un Ã©lÃ©ment sur disque: $($diskTime.TotalMilliseconds) ms"

            # VÃ©rifier que le temps de rÃ©cupÃ©ration sur disque est plus long
            $diskTime.TotalMilliseconds | Should -BeGreaterThan $memoryTime.TotalMilliseconds
        }

        It "Mesure les performances de sÃ©rialisation/dÃ©sÃ©rialisation" {
            # Mesurer le temps de sÃ©rialisation d'un objet complexe
            $serializeTime = Measure-ExecutionTime {
                $script:cache.SetItem("ComplexKey", $script:complexObject, (New-TimeSpan -Hours 1))
            }

            # Vider le cache en mÃ©moire pour forcer la dÃ©sÃ©rialisation depuis le disque
            $script:cache.MemoryCache.Clear()

            # Mesurer le temps de dÃ©sÃ©rialisation d'un objet complexe
            $deserializeTime = Measure-ExecutionTime {
                $value = $script:cache.GetItem("ComplexKey")
            }

            # Afficher les rÃ©sultats
            Write-Host "Temps de sÃ©rialisation d'un objet complexe: $($serializeTime.TotalMilliseconds) ms"
            Write-Host "Temps de dÃ©sÃ©rialisation d'un objet complexe: $($deserializeTime.TotalMilliseconds) ms"

            # VÃ©rifier que les temps sont raisonnables
            $serializeTime.TotalSeconds | Should -BeLessThan 1
            $deserializeTime.TotalSeconds | Should -BeLessThan 1
        }
    }
}

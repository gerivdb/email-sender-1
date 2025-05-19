# Test des performances de List<T> vs ArrayList
# Ce script compare les performances de System.Collections.Generic.List<T> et System.Collections.ArrayList
# dans le contexte du module UnifiedParallel

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force -Verbose

# Initialiser le module
Initialize-UnifiedParallel -Verbose

# Créer un pool de runspaces
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
$runspacePool.Open()

Write-Host "Test des performances de List<T> vs ArrayList" -ForegroundColor Cyan

# Fonction pour mesurer les performances
function Measure-CollectionPerformance {
    param(
        [string]$CollectionType,
        [int]$ItemCount = 1000,
        [int]$Iterations = 5
    )

    $results = @{
        CollectionType = $CollectionType
        AddTime        = [System.Collections.Generic.List[double]]::new()
        AccessTime     = [System.Collections.Generic.List[double]]::new()
        RemoveTime     = [System.Collections.Generic.List[double]]::new()
    }

    for ($iter = 1; $iter -le $Iterations; $iter++) {
        Write-Host "Itération $iter/$Iterations pour $CollectionType..." -ForegroundColor Gray

        # Créer la collection
        try {
            $collection = switch ($CollectionType) {
                "ArrayList" {
                    New-Object System.Collections.ArrayList
                }
                "List<T>" {
                    # Utiliser Add-Type pour s'assurer que le type est disponible
                    Add-Type -TypeDefinition @"
                    using System;
                    using System.Collections.Generic;

                    public class ListHelper
                    {
                        public static List<object> CreateList()
                        {
                            return new List<object>();
                        }
                    }
"@
                    [ListHelper]::CreateList()
                }
                "ConcurrentBag<T>" {
                    # Utiliser Add-Type pour s'assurer que le type est disponible
                    Add-Type -TypeDefinition @"
                    using System;
                    using System.Collections.Concurrent;

                    public class BagHelper
                    {
                        public static ConcurrentBag<object> CreateBag()
                        {
                            return new ConcurrentBag<object>();
                        }
                    }
"@
                    [BagHelper]::CreateBag()
                }
                default {
                    throw "Type de collection non supporté: $CollectionType"
                }
            }
        } catch {
            Write-Error "Erreur lors de la création de la collection de type $CollectionType : $_"
            throw
        }

        # Vérifier que la collection a été créée correctement
        if ($null -eq $collection) {
            throw "Erreur lors de la création de la collection de type $CollectionType"
        }

        # Mesurer le temps d'ajout
        $addTimer = [System.Diagnostics.Stopwatch]::StartNew()
        for ($i = 1; $i -le $ItemCount; $i++) {
            $item = [PSCustomObject]@{
                Id        = $i
                Value     = "Item $i"
                Timestamp = Get-Date
            }

            switch ($CollectionType) {
                "ArrayList" { [void]$collection.Add($item) }
                "List<T>" { $collection.Add($item) }
                "ConcurrentBag<T>" { $collection.Add($item) }
            }
        }
        $addTimer.Stop()
        $results.AddTime.Add($addTimer.Elapsed.TotalMilliseconds)

        # Mesurer le temps d'accès
        $accessTimer = [System.Diagnostics.Stopwatch]::StartNew()
        $tempValue = $null
        if ($CollectionType -eq "ConcurrentBag<T>") {
            # ConcurrentBag n'a pas d'accès indexé, on utilise foreach
            foreach ($item in $collection) {
                $tempValue = $item.Value
            }
        } else {
            for ($i = 0; $i -lt $collection.Count; $i++) {
                $tempValue = $collection[$i].Value
            }
        }
        $accessTimer.Stop()
        $results.AccessTime.Add($accessTimer.Elapsed.TotalMilliseconds)

        # Mesurer le temps de suppression
        $removeTimer = [System.Diagnostics.Stopwatch]::StartNew()
        if ($CollectionType -eq "ConcurrentBag<T>") {
            # ConcurrentBag n'a pas de méthode Remove, on le vide avec TryTake
            $tempItem = $null
            while ($collection.TryTake([ref]$tempItem)) {
                # Vider la collection
            }
        } else {
            for ($i = $collection.Count - 1; $i -ge 0; $i--) {
                $collection.RemoveAt($i)
            }
        }
        $removeTimer.Stop()
        $results.RemoveTime.Add($removeTimer.Elapsed.TotalMilliseconds)
    }

    # Calculer les moyennes
    $avgAddTime = ($results.AddTime | Measure-Object -Average).Average
    $avgAccessTime = ($results.AccessTime | Measure-Object -Average).Average
    $avgRemoveTime = ($results.RemoveTime | Measure-Object -Average).Average

    return [PSCustomObject]@{
        CollectionType = $CollectionType
        ItemCount      = $ItemCount
        Iterations     = $Iterations
        AvgAddTime     = $avgAddTime
        AvgAccessTime  = $avgAccessTime
        AvgRemoveTime  = $avgRemoveTime
        TotalTime      = $avgAddTime + $avgAccessTime + $avgRemoveTime
    }
}

# Exécuter les tests de performance
$itemCount = 10000
$iterations = 5

Write-Host "`nTest de performance avec $itemCount éléments et $iterations itérations" -ForegroundColor Yellow

$arrayListResult = Measure-CollectionPerformance -CollectionType "ArrayList" -ItemCount $itemCount -Iterations $iterations
$listResult = Measure-CollectionPerformance -CollectionType "List<T>" -ItemCount $itemCount -Iterations $iterations
$bagResult = Measure-CollectionPerformance -CollectionType "ConcurrentBag<T>" -ItemCount $itemCount -Iterations $iterations

# Afficher les résultats
Write-Host "`nRésultats des tests de performance:" -ForegroundColor Green
$results = @($arrayListResult, $listResult, $bagResult)
$results | Format-Table -Property CollectionType, AvgAddTime, AvgAccessTime, AvgRemoveTime, TotalTime -AutoSize

# Comparer les performances
$listVsArrayList = ($arrayListResult.TotalTime - $listResult.TotalTime) / $arrayListResult.TotalTime * 100
Write-Host "List<T> est $([Math]::Round($listVsArrayList, 2))% plus rapide que ArrayList" -ForegroundColor Cyan

# Nettoyer
$runspacePool.Close()
$runspacePool.Dispose()

Write-Host "`nTests terminés." -ForegroundColor Green

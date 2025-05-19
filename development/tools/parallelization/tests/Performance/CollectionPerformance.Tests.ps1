﻿# Chemins des scripts à tester
$wrapperPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\CollectionWrapper.ps1"
$extensionsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\CollectionExtensions.ps1"

# Importer les scripts
. $wrapperPath
. $extensionsPath

# Fonction pour mesurer les performances
function Measure-Performance {
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [int]$Iterations = 5
    )

    $results = @()
    for ($i = 0; $i -lt $Iterations; $i++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        & $ScriptBlock
        $stopwatch.Stop()
        $results += $stopwatch.ElapsedMilliseconds
    }

    $average = ($results | Measure-Object -Average).Average
    $min = ($results | Measure-Object -Minimum).Minimum
    $max = ($results | Measure-Object -Maximum).Maximum

    return [PSCustomObject]@{
        Average = $average
        Minimum = $min
        Maximum = $max
        Results = $results
    }
}

Describe "Tests de performance des collections" {
    Context "Ajout d'éléments" {
        It "Compare les performances d'ajout d'éléments" {
            # Arrange
            $itemCount = 10000
            $iterations = 3

            # Act - ArrayList
            $arrayListResult = Measure-Performance -ScriptBlock {
                $collection = [System.Collections.ArrayList]::new()
                for ($i = 0; $i -lt $itemCount; $i++) {
                    [void]$collection.Add([PSCustomObject]@{
                            Id    = $i
                            Value = "Item $i"
                        })
                }
            } -Iterations $iterations

            # Act - List<T>
            $listResult = Measure-Performance -ScriptBlock {
                $collection = [System.Collections.Generic.List[PSObject]]::new($itemCount)
                for ($i = 0; $i -lt $itemCount; $i++) {
                    $collection.Add([PSCustomObject]@{
                            Id    = $i
                            Value = "Item $i"
                        })
                }
            } -Iterations $iterations

            # Act - Array
            $arrayResult = Measure-Performance -ScriptBlock {
                $collection = @()
                for ($i = 0; $i -lt $itemCount; $i++) {
                    $collection += [PSCustomObject]@{
                        Id    = $i
                        Value = "Item $i"
                    }
                }
            } -Iterations $iterations

            # Act - ConcurrentBag<T>
            $bagResult = Measure-Performance -ScriptBlock {
                $collection = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()
                for ($i = 0; $i -lt $itemCount; $i++) {
                    $collection.Add([PSCustomObject]@{
                            Id    = $i
                            Value = "Item $i"
                        })
                }
            } -Iterations $iterations

            # Assert
            Write-Host "Performances d'ajout d'éléments ($itemCount éléments, $iterations itérations) :"
            Write-Host "ArrayList : $($arrayListResult.Average) ms (min: $($arrayListResult.Minimum) ms, max: $($arrayListResult.Maximum) ms)"
            Write-Host "List<T> : $($listResult.Average) ms (min: $($listResult.Minimum) ms, max: $($listResult.Maximum) ms)"
            Write-Host "Array : $($arrayResult.Average) ms (min: $($arrayResult.Minimum) ms, max: $($arrayResult.Maximum) ms)"
            Write-Host "ConcurrentBag<T> : $($bagResult.Average) ms (min: $($bagResult.Minimum) ms, max: $($bagResult.Maximum) ms)"

            # Les tableaux standard devraient être les plus lents
            $arrayResult.Average | Should -BeGreaterThan $listResult.Average
            $arrayResult.Average | Should -BeGreaterThan $arrayListResult.Average

            # List<T> devrait être plus rapide que ArrayList
            $listResult.Average | Should -BeLessThan $arrayListResult.Average
        }
    }

    Context "Accès aux éléments" {
        It "Compare les performances d'accès aux éléments" {
            # Arrange
            $itemCount = 10000
            $iterations = 3

            # Préparer les collections
            $arrayList = [System.Collections.ArrayList]::new()
            $list = [System.Collections.Generic.List[PSObject]]::new($itemCount)
            $array = @()
            $bag = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()

            for ($i = 0; $i -lt $itemCount; $i++) {
                $item = [PSCustomObject]@{
                    Id    = $i
                    Value = "Item $i"
                }
                [void]$arrayList.Add($item)
                $list.Add($item)
                $array += $item
                $bag.Add($item)
            }

            # Act - ArrayList
            $arrayListResult = Measure-Performance -ScriptBlock {
                $sum = 0
                for ($i = 0; $i -lt $itemCount; $i++) {
                    $sum += $arrayList[$i].Id
                }
            } -Iterations $iterations

            # Act - List<T>
            $listResult = Measure-Performance -ScriptBlock {
                $sum = 0
                for ($i = 0; $i -lt $itemCount; $i++) {
                    $sum += $list[$i].Id
                }
            } -Iterations $iterations

            # Act - Array
            $arrayResult = Measure-Performance -ScriptBlock {
                $sum = 0
                for ($i = 0; $i -lt $itemCount; $i++) {
                    $sum += $array[$i].Id
                }
            } -Iterations $iterations

            # Act - ConcurrentBag<T> (pas d'accès par index, donc on utilise foreach)
            $bagResult = Measure-Performance -ScriptBlock {
                $sum = 0
                foreach ($item in $bag) {
                    $sum += $item.Id
                }
            } -Iterations $iterations

            # Assert
            Write-Host "Performances d'accès aux éléments ($itemCount éléments, $iterations itérations) :"
            Write-Host "ArrayList : $($arrayListResult.Average) ms (min: $($arrayListResult.Minimum) ms, max: $($arrayListResult.Maximum) ms)"
            Write-Host "List<T> : $($listResult.Average) ms (min: $($listResult.Minimum) ms, max: $($listResult.Maximum) ms)"
            Write-Host "Array : $($arrayResult.Average) ms (min: $($arrayResult.Minimum) ms, max: $($arrayResult.Maximum) ms)"
            Write-Host "ConcurrentBag<T> : $($bagResult.Average) ms (min: $($bagResult.Minimum) ms, max: $($bagResult.Maximum) ms)"

            # ConcurrentBag devrait être le plus lent pour l'accès
            $bagResult.Average | Should -BeGreaterThan $arrayListResult.Average
            $bagResult.Average | Should -BeGreaterThan $listResult.Average
            $bagResult.Average | Should -BeGreaterThan $arrayResult.Average
        }
    }

    Context "Conversion entre types de collections" {
        It "Compare les performances de conversion entre types de collections" {
            # Arrange
            $itemCount = 10000
            $iterations = 3

            # Préparer les collections
            $arrayList = [System.Collections.ArrayList]::new()
            $list = [System.Collections.Generic.List[PSObject]]::new($itemCount)
            $array = @()
            $bag = [System.Collections.Concurrent.ConcurrentBag[PSObject]]::new()

            for ($i = 0; $i -lt $itemCount; $i++) {
                $item = [PSCustomObject]@{
                    Id    = $i
                    Value = "Item $i"
                }
                [void]$arrayList.Add($item)
                $list.Add($item)
                $array += $item
                $bag.Add($item)
            }

            # Act - ArrayList to List<T>
            $arrayListToListResult = Measure-Performance -ScriptBlock {
                $result = ConvertTo-List -Collection $arrayList
            } -Iterations $iterations

            # Act - List<T> to ArrayList
            $listToArrayListResult = Measure-Performance -ScriptBlock {
                $result = ConvertTo-ArrayList -Collection $list
            } -Iterations $iterations

            # Act - Array to List<T>
            $arrayToListResult = Measure-Performance -ScriptBlock {
                $result = ConvertTo-List -Collection $array
            } -Iterations $iterations

            # Act - ConcurrentBag<T> to List<T>
            $bagToListResult = Measure-Performance -ScriptBlock {
                $result = ConvertTo-List -Collection $bag
            } -Iterations $iterations

            # Assert
            Write-Host "Performances de conversion entre types de collections ($itemCount éléments, $iterations itérations) :"
            Write-Host "ArrayList to List<T> : $($arrayListToListResult.Average) ms (min: $($arrayListToListResult.Minimum) ms, max: $($arrayListToListResult.Maximum) ms)"
            Write-Host "List<T> to ArrayList : $($listToArrayListResult.Average) ms (min: $($listToArrayListResult.Minimum) ms, max: $($listToArrayListResult.Maximum) ms)"
            Write-Host "Array to List<T> : $($arrayToListResult.Average) ms (min: $($arrayToListResult.Minimum) ms, max: $($arrayToListResult.Maximum) ms)"
            Write-Host "ConcurrentBag<T> to List<T> : $($bagToListResult.Average) ms (min: $($bagToListResult.Minimum) ms, max: $($bagToListResult.Maximum) ms)"
        }
    }
}

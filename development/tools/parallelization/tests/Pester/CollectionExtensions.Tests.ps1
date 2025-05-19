﻿# Chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\CollectionExtensions.ps1"

# Importer le script
. $scriptPath

Describe "Invoke-CollectionMap" {
    Context "Transformation d'une collection" {
        It "Applique une fonction à chaque élément d'un tableau" {
            # Arrange
            $numbers = @(1, 2, 3, 4, 5)
            $scriptBlock = { param($x) $x * $x }

            # Act
            $result = Invoke-CollectionMap -Collection $numbers -ScriptBlock $scriptBlock

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 5
            $result[0] | Should -Be 1
            $result[1] | Should -Be 4
            $result[2] | Should -Be 9
            $result[3] | Should -Be 16
            $result[4] | Should -Be 25
        }

        It "Applique une fonction à chaque élément d'une liste" {
            # Arrange
            $list = [System.Collections.Generic.List[int]]::new()
            $list.Add(1)
            $list.Add(2)
            $list.Add(3)
            $scriptBlock = { param($x) $x * 2 }

            # Act
            $result = Invoke-CollectionMap -Collection $list -ScriptBlock $scriptBlock

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0] | Should -Be 2
            $result[1] | Should -Be 4
            $result[2] | Should -Be 6
        }

        It "Applique une fonction à chaque élément d'un ArrayList" {
            # Arrange
            $arrayList = [System.Collections.ArrayList]::new()
            [void]$arrayList.Add("a")
            [void]$arrayList.Add("b")
            [void]$arrayList.Add("c")
            $scriptBlock = { param($x) $x.ToUpper() }

            # Act
            $result = Invoke-CollectionMap -Collection $arrayList -ScriptBlock $scriptBlock

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 3
            $result[0] | Should -Be "A"
            $result[1] | Should -Be "B"
            $result[2] | Should -Be "C"
        }

        It "Applique une fonction avec type de sortie spécifié" {
            # Arrange
            $numbers = @(1, 2, 3, 4, 5)
            $scriptBlock = { param($x) "$x" }

            # Act
            $result = Invoke-CollectionMap -Collection $numbers -ScriptBlock $scriptBlock -OutputType ([string])

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 5
            $result[0] | Should -BeOfType [string]
            $result[0] | Should -Be "1"
            $result[1] | Should -Be "2"
            $result[2] | Should -Be "3"
            $result[3] | Should -Be "4"
            $result[4] | Should -Be "5"
        }
    }
}

Describe "Invoke-CollectionFilter" {
    Context "Filtrage d'une collection" {
        It "Filtre les éléments pairs d'un tableau" {
            # Arrange
            $numbers = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
            $scriptBlock = { param($x) $x % 2 -eq 0 }

            # Act
            $result = Invoke-CollectionFilter -Collection $numbers -ScriptBlock $scriptBlock

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 5
            $result[0] | Should -Be 2
            $result[1] | Should -Be 4
            $result[2] | Should -Be 6
            $result[3] | Should -Be 8
            $result[4] | Should -Be 10
        }

        It "Filtre les éléments d'une liste selon un critère" {
            # Arrange
            $list = [System.Collections.Generic.List[string]]::new()
            $list.Add("apple")
            $list.Add("banana")
            $list.Add("cherry")
            $list.Add("date")
            $scriptBlock = { param($x) $x.StartsWith("a") -or $x.StartsWith("c") }

            # Act
            $result = Invoke-CollectionFilter -Collection $list -ScriptBlock $scriptBlock

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0] | Should -Be "apple"
            $result[1] | Should -Be "cherry"
        }

        It "Filtre les éléments d'un ArrayList selon un critère" {
            # Arrange
            $arrayList = [System.Collections.ArrayList]::new()
            [void]$arrayList.Add(10)
            [void]$arrayList.Add(20)
            [void]$arrayList.Add(30)
            [void]$arrayList.Add(40)
            [void]$arrayList.Add(50)
            $scriptBlock = { param($x) $x -gt 30 }

            # Act
            $result = Invoke-CollectionFilter -Collection $arrayList -ScriptBlock $scriptBlock

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result[0] | Should -Be 40
            $result[1] | Should -Be 50
        }
    }
}

Describe "Invoke-CollectionForEach" {
    Context "Application d'une action à chaque élément" {
        It "Applique une action à chaque élément d'un tableau" {
            # Arrange
            $numbers = @(1, 2, 3, 4, 5)
            $results = @()
            $scriptBlock = { param($x) $results += $x * 2 }

            # Act
            Invoke-CollectionForEach -Collection $numbers -ScriptBlock $scriptBlock

            # Assert
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 5
            $results[0] | Should -Be 2
            $results[1] | Should -Be 4
            $results[2] | Should -Be 6
            $results[3] | Should -Be 8
            $results[4] | Should -Be 10
        }

        It "Applique une action à chaque élément d'une liste" {
            # Arrange
            $list = [System.Collections.Generic.List[string]]::new()
            $list.Add("a")
            $list.Add("b")
            $list.Add("c")
            $results = @()
            $scriptBlock = { param($x) $results += $x.ToUpper() }

            # Act
            Invoke-CollectionForEach -Collection $list -ScriptBlock $scriptBlock

            # Assert
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 3
            $results[0] | Should -Be "A"
            $results[1] | Should -Be "B"
            $results[2] | Should -Be "C"
        }
    }
}

Describe "Invoke-CollectionPartition" {
    Context "Partitionnement d'une collection" {
        It "Partitionne un tableau en sous-collections de taille spécifiée" {
            # Arrange
            $numbers = @(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

            # Act
            $result = Invoke-CollectionPartition -Collection $numbers -Size 3

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 4
            $result[0].Count | Should -Be 3
            $result[1].Count | Should -Be 3
            $result[2].Count | Should -Be 3
            $result[3].Count | Should -Be 1
            $result[0][0] | Should -Be 1
            $result[0][1] | Should -Be 2
            $result[0][2] | Should -Be 3
            $result[1][0] | Should -Be 4
            $result[1][1] | Should -Be 5
            $result[1][2] | Should -Be 6
            $result[2][0] | Should -Be 7
            $result[2][1] | Should -Be 8
            $result[2][2] | Should -Be 9
            $result[3][0] | Should -Be 10
        }

        It "Partitionne une liste en sous-collections de taille spécifiée" {
            # Arrange
            $list = [System.Collections.Generic.List[int]]::new()
            1..7 | ForEach-Object { $list.Add($_) }

            # Act
            $result = Invoke-CollectionPartition -Collection $list -Size 2

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 4
            $result[0].Count | Should -Be 2
            $result[1].Count | Should -Be 2
            $result[2].Count | Should -Be 2
            $result[3].Count | Should -Be 1
            $result[0][0] | Should -Be 1
            $result[0][1] | Should -Be 2
            $result[1][0] | Should -Be 3
            $result[1][1] | Should -Be 4
            $result[2][0] | Should -Be 5
            $result[2][1] | Should -Be 6
            $result[3][0] | Should -Be 7
        }
    }
}

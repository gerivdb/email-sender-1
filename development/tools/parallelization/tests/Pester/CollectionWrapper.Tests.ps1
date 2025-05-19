﻿# Chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\CollectionWrapper.ps1"

# Importer le script
. $scriptPath

Describe "New-CollectionWrapper" {
    Context "Création d'un wrapper pour une nouvelle collection" {
        It "Crée un wrapper pour une nouvelle List<object>" {
            # Act
            $wrapper = New-CollectionWrapper -CollectionType List

            # Assert
            $wrapper | Should -Not -BeNullOrEmpty
            $wrapper.Type | Should -Be ([UnifiedParallel.Collections.CollectionType]::List)
            $wrapper.Count | Should -Be 0
            $wrapper.IsThreadSafe | Should -Be $false
            $wrapper.IsReadOnly | Should -Be $false
        }

        It "Crée un wrapper pour une nouvelle ArrayList" {
            # Act
            $wrapper = New-CollectionWrapper -CollectionType ArrayList

            # Assert
            $wrapper | Should -Not -BeNullOrEmpty
            $wrapper.Type | Should -Be ([UnifiedParallel.Collections.CollectionType]::ArrayList)
            $wrapper.Count | Should -Be 0
            $wrapper.IsThreadSafe | Should -Be $false
            $wrapper.IsReadOnly | Should -Be $false
        }

        It "Crée un wrapper pour une nouvelle ConcurrentBag<string>" {
            # Act
            $wrapper = New-CollectionWrapper -CollectionType ConcurrentBag -ElementType ([string])

            # Assert
            $wrapper | Should -Not -BeNullOrEmpty
            $wrapper.Type | Should -Be ([UnifiedParallel.Collections.CollectionType]::ConcurrentBag)
            $wrapper.Count | Should -Be 0
            $wrapper.IsThreadSafe | Should -Be $true
            $wrapper.IsReadOnly | Should -Be $false
        }

        It "Crée un wrapper pour un nouveau tableau avec capacité spécifiée" {
            # Act
            $wrapper = New-CollectionWrapper -CollectionType Array -Capacity 10 -ElementType ([int])

            # Assert
            $wrapper | Should -Not -BeNullOrEmpty
            $wrapper.Type | Should -Be ([UnifiedParallel.Collections.CollectionType]::Array)
            $wrapper.Count | Should -Be 10
            $wrapper.IsThreadSafe | Should -Be $false
            $wrapper.IsReadOnly | Should -Be $false
        }
    }

    Context "Création d'un wrapper pour une collection existante" {
        It "Crée un wrapper pour une List<int> existante" {
            # Arrange
            $list = [System.Collections.Generic.List[int]]::new()
            $list.Add(1)
            $list.Add(2)
            $list.Add(3)

            # Act
            $wrapper = New-CollectionWrapper -Collection $list -ElementType ([int])

            # Assert
            $wrapper | Should -Not -BeNullOrEmpty
            $wrapper.Type | Should -Be ([UnifiedParallel.Collections.CollectionType]::List)
            $wrapper.Count | Should -Be 3
            $wrapper.IsThreadSafe | Should -Be $false
            $wrapper.IsReadOnly | Should -Be $false
        }

        It "Crée un wrapper pour un ArrayList existant" {
            # Arrange
            $arrayList = [System.Collections.ArrayList]::new()
            [void]$arrayList.Add("Item1")
            [void]$arrayList.Add("Item2")

            # Act
            $wrapper = New-CollectionWrapper -Collection $arrayList -ElementType ([string])

            # Assert
            $wrapper | Should -Not -BeNullOrEmpty
            $wrapper.Type | Should -Be ([UnifiedParallel.Collections.CollectionType]::ArrayList)
            $wrapper.Count | Should -Be 2
            $wrapper.IsThreadSafe | Should -Be $false
            $wrapper.IsReadOnly | Should -Be $false
        }
    }
}

Describe "CollectionWrapper<T>" {
    Context "Méthodes de base" {
        It "Ajoute un élément à la collection" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType List -ElementType ([int])

            # Act
            $wrapper.Add(1)
            $wrapper.Add(2)
            $wrapper.Add(3)

            # Assert
            $wrapper.Count | Should -Be 3
        }

        It "Ajoute une plage d'éléments à la collection" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType List -ElementType ([int])
            $items = @(1, 2, 3, 4, 5)

            # Act
            $wrapper.AddRange($items)

            # Assert
            $wrapper.Count | Should -Be 5
        }

        It "Efface tous les éléments de la collection" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType List -ElementType ([int])
            $wrapper.Add(1)
            $wrapper.Add(2)
            $wrapper.Add(3)

            # Act
            $wrapper.Clear()

            # Assert
            $wrapper.Count | Should -Be 0
        }
    }

    Context "Méthodes de conversion" {
        It "Convertit la collection en ArrayList" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType List -ElementType ([int])
            $wrapper.Add(1)
            $wrapper.Add(2)
            $wrapper.Add(3)

            # Act
            $arrayList = $wrapper.ToArrayList()

            # Assert
            $arrayList | Should -BeOfType [System.Collections.ArrayList]
            $arrayList.Count | Should -Be 3
            $arrayList[0] | Should -Be 1
            $arrayList[1] | Should -Be 2
            $arrayList[2] | Should -Be 3
        }

        It "Convertit la collection en tableau" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType List -ElementType ([int])
            $wrapper.Add(1)
            $wrapper.Add(2)
            $wrapper.Add(3)

            # Act
            $array = $wrapper.ToArray()

            # Assert
            $array | Should -BeOfType [System.Array]
            $array.Length | Should -Be 3
            $array[0] | Should -Be 1
            $array[1] | Should -Be 2
            $array[2] | Should -Be 3
        }

        It "Convertit la collection en List<T>" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType ArrayList -ElementType ([string])
            $wrapper.Add("Item1")
            $wrapper.Add("Item2")

            # Act
            $list = $wrapper.ToList()

            # Assert
            $list | Should -BeOfType [System.Collections.Generic.List`1]
            $list.Count | Should -Be 2
            $list[0] | Should -Be "Item1"
            $list[1] | Should -Be "Item2"
        }

        It "Convertit la collection en ConcurrentBag<T>" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType List -ElementType ([int])
            $wrapper.Add(1)
            $wrapper.Add(2)
            $wrapper.Add(3)

            # Act
            $bag = $wrapper.ToConcurrentBag()

            # Assert
            $bag | Should -BeOfType [System.Collections.Concurrent.ConcurrentBag`1]
            $bag.Count | Should -Be 3
            $bag | Should -Contain 1
            $bag | Should -Contain 2
            $bag | Should -Contain 3
        }
    }
}

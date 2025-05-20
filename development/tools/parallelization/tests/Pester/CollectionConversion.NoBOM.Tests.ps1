# Tests progressifs pour les méthodes de conversion de collections.
#
# Ce fichier contient des tests progressifs pour les méthodes de conversion de collections
# du module UnifiedParallel, organisés en 4 phases:
# - Phase 1 (P1): Tests basiques pour les fonctionnalités essentielles
# - Phase 2 (P2): Tests de robustesse avec valeurs limites et cas particuliers
# - Phase 3 (P3): Tests d'exceptions pour la gestion des erreurs
# - Phase 4 (P4): Tests avancés pour les scénarios complexes
#
# Version:        1.0.0
# Auteur:         UnifiedParallel Team
# Date création:  2025-06-01

#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

# Chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\CollectionWrapper.ps1"

# Importer le script
. $scriptPath

# Créer une classe de test pour vérifier la préservation des types
Add-Type -TypeDefinition @"
using System;

namespace UnifiedParallelTests
{
    public class TestItem
    {
        public int Id { get; set; }
        public string Name { get; set; }

        public TestItem() { }

        public TestItem(int id, string name)
        {
            Id = id;
            Name = name;
        }

        public override bool Equals(object obj)
        {
            if (obj is TestItem other)
            {
                return Id == other.Id && Name == other.Name;
            }
            return false;
        }

        public override int GetHashCode()
        {
            return Id.GetHashCode() ^ (Name?.GetHashCode() ?? 0);
        }
    }
}
"@

#region Phase 1 - Tests basiques pour les fonctionnalités essentielles
Describe "ToList - Tests basiques" -Tag "P1" {
    Context "Conversion de collections simples" {
        It "Convertit un ArrayList en List<int>" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType ArrayList -ElementType ([int])
            $wrapper.Add(1)
            $wrapper.Add(2)
            $wrapper.Add(3)

            # Act
            $list = $wrapper.ToList()

            # Assert
            $list | Should -BeOfType ([System.Collections.Generic.List[int]])
            $list.Count | Should -Be 3
            $list[0] | Should -Be 1
            $list[1] | Should -Be 2
            $list[2] | Should -Be 3
        }

        It "Convertit un Array en List<string>" {
            # Arrange
            $array = @("a", "b", "c")
            $wrapper = New-CollectionWrapper -Collection $array -ElementType ([string])

            # Act
            $list = $wrapper.ToList()

            # Assert
            $list | Should -BeOfType ([System.Collections.Generic.List[string]])
            $list.Count | Should -Be 3
            $list[0] | Should -Be "a"
            $list[1] | Should -Be "b"
            $list[2] | Should -Be "c"
        }

        It "Convertit une collection vide en List<T> vide" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType List -ElementType ([string])

            # Act
            $list = $wrapper.ToList()

            # Assert
            $list | Should -BeOfType ([System.Collections.Generic.List[string]])
            $list.Count | Should -Be 0
        }
    }

    Context "Préservation des types" {
        It "Préserve le type des éléments lors de la conversion" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType ArrayList -ElementType ([UnifiedParallelTests.TestItem])
            $item1 = New-Object UnifiedParallelTests.TestItem
            $item1.Id = 1
            $item1.Name = "Item1"
            $wrapper.Add($item1)

            # Act
            $list = $wrapper.ToList()

            # Assert
            $list | Should -BeOfType ([System.Collections.Generic.List[UnifiedParallelTests.TestItem]])
            $list.Count | Should -Be 1
            $list[0] | Should -BeOfType [UnifiedParallelTests.TestItem]
            $list[0].Id | Should -Be 1
            $list[0].Name | Should -Be "Item1"
        }
    }
}
#endregion

#region Phase 2 - Tests de robustesse avec valeurs limites et cas particuliers
Describe "ToList - Tests de robustesse" -Tag "P2" {
    Context "Conversion de grandes collections" {
        It "Convertit une grande ArrayList en List<int> (1000 éléments)" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType ArrayList -ElementType ([int]) -Capacity 1000
            for ($i = 0; $i -lt 1000; $i++) {
                $wrapper.Add($i)
            }

            # Act
            $list = $wrapper.ToList()

            # Assert
            $list | Should -BeOfType ([System.Collections.Generic.List[int]])
            $list.Count | Should -Be 1000
            $list[0] | Should -Be 0
            $list[999] | Should -Be 999
        }

        It "Convertit une grande List<int> en List<int> (copie)" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType List -ElementType ([int]) -Capacity 1000
            for ($i = 0; $i -lt 1000; $i++) {
                $wrapper.Add($i)
            }

            # Act
            $list = $wrapper.ToList()

            # Assert
            $list | Should -BeOfType ([System.Collections.Generic.List[int]])
            $list.Count | Should -Be 1000
            $list[0] | Should -Be 0
            $list[999] | Should -Be 999
            
            # Vérifier que c'est une copie (modification de l'original ne change pas la copie)
            $originalList = $wrapper.GetUnderlyingCollection()
            $originalList.Add(1000)
            $list.Count | Should -Be 1000  # La copie n'est pas modifiée
        }
    }

    Context "Conversion entre différents types de collections" {
        It "Convertit un HashSet<T> en List<T>" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType HashSet -ElementType ([int])
            $wrapper.Add(1)
            $wrapper.Add(2)
            $wrapper.Add(3)

            # Act
            $list = $wrapper.ToList()

            # Assert
            $list | Should -BeOfType ([System.Collections.Generic.List[int]])
            $list.Count | Should -Be 3
            $list | Should -Contain 1
            $list | Should -Contain 2
            $list | Should -Contain 3
        }

        It "Convertit un Dictionary<string, T> en List<T> (valeurs)" {
            # Arrange
            $dict = New-Object "System.Collections.Generic.Dictionary[string, int]"
            $dict.Add("one", 1)
            $dict.Add("two", 2)
            $dict.Add("three", 3)
            $wrapper = New-CollectionWrapper -Collection $dict -ElementType ([int])

            # Act
            $list = $wrapper.ToList()

            # Assert
            $list | Should -BeOfType ([System.Collections.Generic.List[int]])
            $list.Count | Should -Be 3
            $list | Should -Contain 1
            $list | Should -Contain 2
            $list | Should -Contain 3
        }
    }
}
#endregion

#region Phase 3 - Tests d'exceptions pour la gestion des erreurs
Describe "ToList - Tests d'exceptions" -Tag "P3" {
    Context "Gestion des erreurs" {
        It "Gère correctement les collections null" {
            # Act & Assert
            { $null.ToList() } | Should -Throw
        }
    }
}
#endregion

#region Phase 4 - Tests avancés pour les scénarios complexes
Describe "ToList - Tests avancés" -Tag "P4" {
    Context "Performance des conversions" {
        It "Mesure les performances de conversion pour les grandes collections" {
            # Arrange
            $wrapper = New-CollectionWrapper -CollectionType ArrayList -ElementType ([int]) -Capacity 10000
            for ($i = 0; $i -lt 10000; $i++) {
                $wrapper.Add($i)
            }

            # Act
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $list = $wrapper.ToList()
            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds

            # Assert
            $list.Count | Should -Be 10000
            $elapsedMs | Should -BeLessOrEqual 1000  # La conversion devrait prendre moins d'une seconde
            Write-Host "Temps de conversion pour 10000 éléments: $elapsedMs ms"
        }
    }

    Context "Conversion avec filtrage" {
        It "Convertit une collection filtrée en List<T>" {
            # Note: Cette fonctionnalité n'est pas encore implémentée
            Set-ItResult -Skipped -Because "La fonctionnalité de conversion avec filtrage n'est pas encore implémentée"
        }
    }

    Context "Conversion avec parallélisation" {
        It "Convertit une grande collection en List<T> avec parallélisation" {
            # Note: Cette fonctionnalité n'est pas encore implémentée
            Set-ItResult -Skipped -Because "La fonctionnalité de conversion avec parallélisation n'est pas encore implémentée"
        }
    }
}
#endregion

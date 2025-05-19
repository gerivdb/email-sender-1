<#
.SYNOPSIS
    Tests progressifs pour les fonctionnalités de clonage profond (TestDeepClone).

.DESCRIPTION
    Ce fichier contient des tests progressifs pour les fonctionnalités de clonage profond
    du module TestDeepClone, organisés en 4 phases:
    - Phase 1 (P1): Tests basiques pour les fonctionnalités essentielles
    - Phase 2 (P2): Tests de robustesse avec valeurs limites et cas particuliers
    - Phase 3 (P3): Tests d'exceptions pour la gestion des erreurs
    - Phase 4 (P4): Tests avancés pour les scénarios complexes

.NOTES
    Version:        1.0.0
    Auteur:         UnifiedParallel Team
    Date création:  2025-05-26
#>

#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du script à tester
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "TestDeepClone.ps1"

    # Importer le script
    . $scriptPath

    # Définir des classes de test
    Add-Type -TypeDefinition @"
    using System;
    using System.Collections.Generic;

    namespace UnifiedParallel.Tests {
        [Serializable]
        public class TestPerson {
            public string Name { get; set; }
            public int Age { get; set; }
            public List<string> Hobbies { get; set; }
            public TestAddress Address { get; set; }

            public TestPerson() {
                Hobbies = new List<string>();
            }
        }

        [Serializable]
        public class TestAddress {
            public string Street { get; set; }
            public string City { get; set; }
            public string Country { get; set; }
        }

        public class NonSerializableClass {
            public string Data { get; set; }
            public System.Threading.Thread Thread { get; set; }

            public NonSerializableClass() {
                Thread = new System.Threading.Thread(() => { });
            }
        }
    }
"@
}

#region Phase 1 - Tests basiques pour les fonctionnalités essentielles
Describe "Test-DeepClone - Tests basiques" -Tag "P1" {
    Context "Clonage d'objets simples" {
        It "Clone correctement un objet simple" {
            # Arrange
            $original = [PSCustomObject]@{
                Name  = "Test"
                Value = 42
            }

            # Act
            $clone = Test-DeepClone -InputObject $original

            # Assert
            $clone | Should -Not -BeNullOrEmpty
            $clone.Name | Should -Be "Test"
            $clone.Value | Should -Be 42

            # Vérifier que c'est une copie profonde
            $clone.Name = "Modified"
            $original.Name | Should -Be "Test"
        }

        It "Retourne null pour un input null" {
            # Act
            $result = Test-DeepClone -InputObject $null

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It "Clone correctement un tableau simple" {
            # Arrange
            $original = @(1, 2, 3, 4, 5)

            # Act
            $clone = Test-DeepClone -InputObject $original

            # Assert
            $clone | Should -Not -BeNullOrEmpty
            $clone.Count | Should -Be 5
            $clone[0] | Should -Be 1
            $clone[4] | Should -Be 5

            # Vérifier que c'est une copie profonde
            $clone[0] = 99
            $original[0] | Should -Be 1
        }

        It "Clone correctement un dictionnaire simple" {
            # Arrange
            $original = @{
                "Key1" = "Value1"
                "Key2" = "Value2"
            }

            # Act
            $clone = Test-DeepClone -InputObject $original

            # Assert
            $clone | Should -Not -BeNullOrEmpty
            $clone.Count | Should -Be 2
            $clone["Key1"] | Should -Be "Value1"
            $clone["Key2"] | Should -Be "Value2"

            # Vérifier que c'est une copie profonde
            $clone["Key1"] = "Modified"
            $original["Key1"] | Should -Be "Value1"
        }
    }
}

Describe "Test-PSObjectDeepClone - Tests basiques" -Tag "P1" {
    Context "Clonage d'objets PSObject" {
        It "Clone correctement un objet PSObject simple" {
            # Arrange
            $original = [PSCustomObject]@{
                Name  = "Test"
                Value = 42
            }

            # Act
            $clone = Test-PSObjectDeepClone -InputObject $original

            # Assert
            $clone | Should -Not -BeNullOrEmpty
            $clone.Name | Should -Be "Test"
            $clone.Value | Should -Be 42

            # Vérifier que c'est une copie profonde
            $clone.Name = "Modified"
            $original.Name | Should -Be "Test"
        }

        It "Retourne null pour un input null" {
            # Act
            $result = Test-PSObjectDeepClone -InputObject $null

            # Assert
            $result | Should -BeNullOrEmpty
        }
    }
}
#endregion

#region Phase 2 - Tests de robustesse avec valeurs limites et cas particuliers
Describe "Test-DeepClone - Tests de robustesse" -Tag "P2" {
    Context "Clonage d'objets complexes" {
        It "Clone correctement un dictionnaire imbriqué" {
            # Arrange
            $original = @{
                "Key1" = "Value1"
                "Key2" = @{
                    "NestedKey" = "NestedValue"
                }
                "Key3" = @(1, 2, 3)
            }

            # Act
            $clone = Test-DeepClone -InputObject $original

            # Assert
            $clone | Should -Not -BeNullOrEmpty
            $clone.Count | Should -Be 3
            $clone["Key1"] | Should -Be "Value1"
            $clone["Key2"]["NestedKey"] | Should -Be "NestedValue"
            $clone["Key3"][0] | Should -Be 1

            # Vérifier que c'est une copie profonde
            $clone["Key1"] = "Modified"
            $clone["Key2"]["NestedKey"] = "ModifiedNested"
            $clone["Key3"][0] = 99

            $original["Key1"] | Should -Be "Value1"
            $original["Key2"]["NestedKey"] | Should -Be "NestedValue"
            $original["Key3"][0] | Should -Be 1
        }

        It "Clone correctement un ArrayList" {
            # Arrange
            $original = New-Object System.Collections.ArrayList
            [void]$original.Add("Item1")
            [void]$original.Add("Item2")
            [void]$original.Add(@{
                    "NestedKey" = "NestedValue"
                })

            # Act
            $clone = Test-DeepClone -InputObject $original

            # Assert
            $clone | Should -Not -BeNullOrEmpty
            $clone.Count | Should -Be 3
            $clone[0] | Should -Be "Item1"
            $clone[2]["NestedKey"] | Should -Be "NestedValue"

            # Vérifier que c'est une copie profonde
            $clone[0] = "Modified"
            $clone[2]["NestedKey"] = "ModifiedNested"

            $original[0] | Should -Be "Item1"
            $original[2]["NestedKey"] | Should -Be "NestedValue"
        }
    }
}

Describe "Test-PSObjectDeepClone - Tests de robustesse" -Tag "P2" {
    Context "Clonage d'objets PSObject complexes" {
        It "Clone correctement un objet PSObject avec propriétés imbriquées" {
            # Arrange
            $original = [PSCustomObject]@{
                Name  = "Parent"
                Child = [PSCustomObject]@{
                    Name  = "Child"
                    Value = 42
                }
            }

            # Act
            $clone = Test-PSObjectDeepClone -InputObject $original

            # Assert
            $clone | Should -Not -BeNullOrEmpty
            $clone.Name | Should -Be "Parent"
            $clone.Child.Name | Should -Be "Child"
            $clone.Child.Value | Should -Be 42

            # Vérifier que c'est une copie profonde
            $clone.Child.Name = "ModifiedChild"
            $original.Child.Name | Should -Be "Child"
        }
    }
}
#endregion

#region Phase 3 - Tests d'exceptions pour la gestion des erreurs
Describe "Test-DeepClone - Tests d'exceptions" -Tag "P3" {
    Context "Gestion des erreurs" {
        It "Lève une exception pour un type non sérialisable" {
            # Arrange
            $nonSerializable = New-Object UnifiedParallel.Tests.NonSerializableClass
            $nonSerializable.Data = "Test"

            # Act & Assert
            { Test-DeepClone -InputObject $nonSerializable } | Should -Throw
        }

        It "Gère correctement les références circulaires" {
            # Arrange
            $obj1 = [PSCustomObject]@{
                Name = "Object1"
                Ref  = $null
            }

            $obj2 = [PSCustomObject]@{
                Name = "Object2"
                Ref  = $obj1
            }

            # Créer une référence circulaire
            $obj1.Ref = $obj2

            # Act & Assert
            { Test-DeepClone -InputObject $obj1 } | Should -Throw
        }
    }
}

Describe "Test-PSObjectDeepClone - Tests d'exceptions" -Tag "P3" {
    Context "Gestion des erreurs" {
        It "Gère correctement les propriétés non sérialisables" {
            # Arrange
            $obj = [PSCustomObject]@{
                Name            = "Test"
                NonSerializable = New-Object UnifiedParallel.Tests.NonSerializableClass
            }

            # Act & Assert
            { Test-PSObjectDeepClone -InputObject $obj } | Should -Throw
        }
    }
}
#endregion

#region Phase 4 - Tests avancés pour les scénarios complexes
Describe "Test-DeepClone - Tests avancés" -Tag "P4" {
    Context "Compatibilité avec le pipeline" {
        It "Fonctionne correctement avec le pipeline" {
            # Arrange
            $original = [PSCustomObject]@{
                Name  = "Test"
                Value = 42
            }

            # Act
            $clone = $original | Test-DeepClone

            # Assert
            $clone | Should -Not -BeNullOrEmpty
            $clone.Name | Should -Be "Test"
            $clone.Value | Should -Be 42

            # Vérifier que c'est une copie profonde
            $clone.Name = "Modified"
            $original.Name | Should -Be "Test"
        }
    }

    Context "Performance et optimisation" {
        It "Clone efficacement un grand tableau" {
            # Arrange
            $size = 1000
            $original = 1..$size

            # Act
            $startTime = Get-Date
            $clone = Test-DeepClone -InputObject $original
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalMilliseconds

            # Assert
            $clone.Count | Should -Be $size
            $clone[0] | Should -Be 1
            $clone[$size - 1] | Should -Be $size

            # Vérifier que le temps d'exécution est raisonnable (moins de 5 secondes)
            $duration | Should -BeLessThan 5000
        }

        It "Clone efficacement un grand dictionnaire" {
            # Arrange
            $size = 100
            $original = @{}
            for ($i = 1; $i -le $size; $i++) {
                $original["Key$i"] = "Value$i"
            }

            # Act
            $startTime = Get-Date
            $clone = Test-DeepClone -InputObject $original
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalMilliseconds

            # Assert
            $clone.Count | Should -Be $size
            $clone["Key1"] | Should -Be "Value1"
            $clone["Key$size"] | Should -Be "Value$size"

            # Vérifier que le temps d'exécution est raisonnable (moins de 5 secondes)
            $duration | Should -BeLessThan 5000
        }
    }
}

Describe "Test-PSObjectDeepClone - Tests avancés" -Tag "P4" {
    Context "Préservation des types" {
        It "Préserve les types de données spécifiques" {
            # Arrange
            $original = [PSCustomObject]@{
                StringValue = "Test"
                IntValue    = 42
                DoubleValue = 3.14
                DateValue   = [DateTime]::Now
                GuidValue   = [Guid]::NewGuid()
                BoolValue   = $true
            }

            # Act
            $clone = Test-PSObjectDeepClone -InputObject $original

            # Assert
            $clone.StringValue | Should -BeOfType [string]
            $clone.IntValue | Should -BeOfType [int]
            $clone.DoubleValue | Should -BeOfType [double]
            $clone.DateValue | Should -BeOfType [DateTime]
            $clone.GuidValue | Should -BeOfType [Guid]
            $clone.BoolValue | Should -BeOfType [bool]
        }
    }
}
#endregion

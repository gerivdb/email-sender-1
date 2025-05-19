# Chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\DeepCloneExtensions.ps1"

# Importer le script
. $scriptPath

# Définir une classe sérialisable pour les tests
Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;

namespace UnifiedParallel.Tests
{
    [Serializable]
    public class TestPerson
    {
        public string Name { get; set; }
        public int Age { get; set; }
        public List<string> Hobbies { get; set; }
        public TestAddress Address { get; set; }

        public TestPerson()
        {
            Hobbies = new List<string>();
        }
    }

    [Serializable]
    public class TestAddress
    {
        public string Street { get; set; }
        public string City { get; set; }
        public string Country { get; set; }
    }

    // Classe non sérialisable pour tester les erreurs
    public class NonSerializableClass
    {
        public string Data { get; set; }
    }
}
"@

Describe "Invoke-DeepClone" {
    Context "Clonage d'objets simples" {
        It "Clone correctement un objet simple" {
            # Arrange
            $original = [PSCustomObject]@{
                Name  = "Test"
                Value = 42
            }

            # Act
            $clone = Invoke-DeepClone -InputObject $original

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
            $result = Invoke-DeepClone -InputObject $null

            # Assert
            $result | Should -BeNullOrEmpty
        }

        It "Clone correctement un tableau" {
            # Arrange
            $original = @(1, 2, 3, 4, 5)

            # Act
            $clone = Invoke-DeepClone -InputObject $original

            # Assert
            $clone | Should -Not -BeNullOrEmpty
            $clone.Count | Should -Be 5
            $clone[0] | Should -Be 1

            # Vérifier que c'est une copie profonde
            $clone[0] = 99
            $original[0] | Should -Be 1
        }
    }

    Context "Clonage d'objets complexes" {
        It "Clone correctement un objet avec références imbriquées" {
            # Arrange
            $person = New-Object UnifiedParallel.Tests.TestPerson
            $person.Name = "John Doe"
            $person.Age = 30
            $person.Hobbies.Add("Reading")
            $person.Hobbies.Add("Hiking")

            $address = New-Object UnifiedParallel.Tests.TestAddress
            $address.Street = "123 Main St"
            $address.City = "Anytown"
            $address.Country = "USA"

            $person.Address = $address

            # Act
            $clone = Invoke-DeepClone -InputObject $person

            # Assert
            $clone | Should -Not -BeNullOrEmpty
            $clone.Name | Should -Be "John Doe"
            $clone.Age | Should -Be 30
            $clone.Hobbies.Count | Should -Be 2
            $clone.Hobbies[0] | Should -Be "Reading"
            $clone.Address.Street | Should -Be "123 Main St"

            # Vérifier que c'est une copie profonde
            $clone.Name = "Jane Doe"
            $clone.Address.Street = "456 Oak Ave"
            $clone.Hobbies.Add("Swimming")

            $person.Name | Should -Be "John Doe"
            $person.Address.Street | Should -Be "123 Main St"
            $person.Hobbies.Count | Should -Be 2
        }

        It "Clone correctement un dictionnaire" {
            # Arrange
            $original = @{
                "Key1" = "Value1"
                "Key2" = @{
                    "NestedKey" = "NestedValue"
                }
                "Key3" = @(1, 2, 3)
            }

            # Act
            $clone = Invoke-DeepClone -InputObject $original

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
    }

    Context "Gestion des erreurs" {
        It "Lève une exception pour un type non sérialisable" {
            # Arrange
            $nonSerializable = New-Object UnifiedParallel.Tests.NonSerializableClass
            $nonSerializable.Data = "Test"

            # Act & Assert
            { Invoke-DeepClone -InputObject $nonSerializable } | Should -Throw
        }
    }

    Context "Compatibilité avec le pipeline" {
        It "Fonctionne correctement avec le pipeline" {
            # Arrange
            $original = [PSCustomObject]@{
                Name  = "Test"
                Value = 42
            }

            # Act
            $clone = $original | Invoke-DeepClone

            # Assert
            $clone | Should -Not -BeNullOrEmpty
            $clone.Name | Should -Be "Test"
            $clone.Value | Should -Be 42

            # Vérifier que c'est une copie profonde
            $clone.Name = "Modified"
            $original.Name | Should -Be "Test"
        }
    }
}

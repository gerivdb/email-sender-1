# Chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\DeepCloneExtensions.ps1"

# Importer le script
. $scriptPath

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

        It "Clone correctement un ArrayList" {
            # Arrange
            $original = [System.Collections.ArrayList]::new()
            [void]$original.Add("Item1")
            [void]$original.Add("Item2")

            # Act
            $clone = Invoke-DeepClone -InputObject $original

            # Assert
            $clone | Should -Not -BeNullOrEmpty
            $clone.Count | Should -Be 2
            $clone[0] | Should -Be "Item1"

            # Vérifier que c'est une copie profonde et qu'on peut ajouter des éléments
            [void]$clone.Add("Item3")
            $clone.Count | Should -Be 3
            $original.Count | Should -Be 2
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

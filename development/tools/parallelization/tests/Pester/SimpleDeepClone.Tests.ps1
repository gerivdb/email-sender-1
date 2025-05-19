<#
.SYNOPSIS
    Tests simples pour les fonctions de clonage profond.

.DESCRIPTION
    Ce script implémente des tests simples pour les fonctions
    Invoke-DeepClone et Invoke-PSObjectDeepClone du module UnifiedParallel.

.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-26
#>

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\DeepCloneExtensions.ps1"
. $scriptPath

Describe "Invoke-DeepClone" {
    It "Devrait cloner un objet simple" {
        # Arrange
        $original = [PSCustomObject]@{
            Name = "Test"
            Value = 42
        }

        # Act
        $clone = Invoke-DeepClone -InputObject $original

        # Assert
        $clone | Should -Not -BeNullOrEmpty
        $clone.Name | Should -Be "Test"
        $clone.Value | Should -Be 42
    }

    It "Devrait créer une copie indépendante (deep clone)" {
        # Arrange
        $original = [PSCustomObject]@{
            Name = "Test"
            Value = 42
        }

        # Act
        $clone = Invoke-DeepClone -InputObject $original
        $clone.Name = "Modified"
        $clone.Value = 99

        # Assert
        $original.Name | Should -Be "Test"
        $original.Value | Should -Be 42
    }

    It "Devrait cloner un tableau simple" {
        # Arrange
        $original = @(1, 2, 3, 4, 5)

        # Act
        $clone = Invoke-DeepClone -InputObject $original

        # Assert
        $clone | Should -Not -BeNullOrEmpty
        $clone.Count | Should -Be 5
        $clone[0] | Should -Be 1
        $clone[4] | Should -Be 5
    }

    It "Devrait cloner un dictionnaire simple" {
        # Arrange
        $original = @{
            "Key1" = "Value1"
            "Key2" = "Value2"
        }

        # Act
        $clone = Invoke-DeepClone -InputObject $original

        # Assert
        $clone | Should -Not -BeNullOrEmpty
        $clone.Count | Should -Be 2
        $clone["Key1"] | Should -Be "Value1"
        $clone["Key2"] | Should -Be "Value2"
    }
}

Describe "Invoke-PSObjectDeepClone" {
    It "Devrait cloner un objet PSObject simple" {
        # Arrange
        $original = [PSCustomObject]@{
            Name = "Test"
            Value = 42
        }

        # Act
        $clone = Invoke-PSObjectDeepClone -InputObject $original

        # Assert
        $clone | Should -Not -BeNullOrEmpty
        $clone.Name | Should -Be "Test"
        $clone.Value | Should -Be 42
    }

    It "Devrait créer une copie indépendante (deep clone) d'un PSObject" {
        # Arrange
        $original = [PSCustomObject]@{
            Name = "Test"
            Value = 42
        }

        # Act
        $clone = Invoke-PSObjectDeepClone -InputObject $original
        $clone.Name = "Modified"
        $clone.Value = 99

        # Assert
        $original.Name | Should -Be "Test"
        $original.Value | Should -Be 42
    }

    It "Devrait cloner un PSObject avec des propriétés imbriquées" {
        # Arrange
        $original = [PSCustomObject]@{
            Name = "Parent"
            Child = [PSCustomObject]@{
                Name = "Child"
                Value = 42
            }
        }

        # Act
        $clone = Invoke-PSObjectDeepClone -InputObject $original

        # Assert
        $clone | Should -Not -BeNullOrEmpty
        $clone.Name | Should -Be "Parent"
        $clone.Child.Name | Should -Be "Child"
        $clone.Child.Value | Should -Be 42
    }
}

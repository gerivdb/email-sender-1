<#
.SYNOPSIS
    Tests progressifs pour les fonctions de clonage profond.

.DESCRIPTION
    Ce script implémente des tests progressifs (P1 à P4) pour les fonctions
    Invoke-DeepClone et Invoke-PSObjectDeepClone du module UnifiedParallel.

.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-26
#>

# Importer le framework de test progressif
$frameworkPath = Join-Path -Path $PSScriptRoot -ChildPath "..\ProgressiveTestFramework.ps1"
. $frameworkPath

# Importer le script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\DeepCloneExtensions.ps1"
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le fichier DeepCloneExtensions.ps1 n'existe pas à l'emplacement: $scriptPath"
}

# Importer le script
. $scriptPath

# Vérifier que les fonctions sont disponibles
if (-not (Get-Command -Name Invoke-DeepClone -ErrorAction SilentlyContinue)) {
    throw "La fonction Invoke-DeepClone n'a pas été correctement importée."
}

if (-not (Get-Command -Name Invoke-PSObjectDeepClone -ErrorAction SilentlyContinue)) {
    throw "La fonction Invoke-PSObjectDeepClone n'a pas été correctement importée."
}

# Initialiser le framework de test progressif
# Par défaut, exécuter toutes les phases disponibles
$maxPhaseStr = $env:TEST_MAX_PHASE
if (-not $maxPhaseStr) {
    $maxPhaseStr = "P4"
}

$maxPhase = [TestPhase]::$maxPhaseStr
Initialize-ProgressiveTest -MaxPhase $maxPhase

#region Phase 1 - Tests basiques
New-PhaseTest -Phase P1 -Name "Tests basiques pour Invoke-DeepClone" -ScriptBlock {
    It "Devrait cloner un objet simple" {
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
    }

    It "Devrait créer une copie indépendante (deep clone)" {
        # Arrange
        $original = [PSCustomObject]@{
            Name  = "Test"
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

New-PhaseTest -Phase P1 -Name "Tests basiques pour Invoke-PSObjectDeepClone" -ScriptBlock {
    It "Devrait cloner un objet PSObject simple" {
        # Arrange
        $original = [PSCustomObject]@{
            Name  = "Test"
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
            Name  = "Test"
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
            Name  = "Parent"
            Child = [PSCustomObject]@{
                Name  = "Child"
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
#endregion

# Générer un rapport des résultats
Get-TestPhaseReport

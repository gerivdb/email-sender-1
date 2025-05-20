# Test simple pour vérifier l'implémentation de ToArrayList avec Pester

# Importer le module Pester
Import-Module Pester

# Importer le module CollectionWrapper
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\CollectionWrapper.ps1"
. $scriptPath

Describe "ToArrayList - Tests simples" {
    It "Convertit une List<int> en ArrayList" {
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
}

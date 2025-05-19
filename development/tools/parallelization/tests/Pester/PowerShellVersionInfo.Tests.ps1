# Tests unitaires pour la fonction Get-PowerShellVersionInfo
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force
}

Describe "Get-PowerShellVersionInfo" {
    Context "Récupération des informations sur la version de PowerShell" {
        It "Retourne un objet avec les propriétés attendues" {
            # Act
            $result = Get-PowerShellVersionInfo
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Version | Should -Not -BeNullOrEmpty
            $result.Major | Should -BeGreaterOrEqual 5
            $result.Minor | Should -BeGreaterOrEqual 0
            $result.Edition | Should -Not -BeNullOrEmpty
            $result.IsCore | Should -BeOfType [bool]
            $result.IsDesktop | Should -BeOfType [bool]
            $result.IsWindows | Should -BeOfType [bool]
            $result.IsLinux | Should -BeOfType [bool]
            $result.IsMacOS | Should -BeOfType [bool]
            $result.Is64Bit | Should -BeOfType [bool]
            $result.CLRVersion | Should -Not -BeNullOrEmpty
            $result.HasForEachParallel | Should -BeOfType [bool]
            $result.HasRunspaces | Should -BeOfType [bool]
            $result.HasThreadJobs | Should -BeOfType [bool]
            $result.SupportsUTF8NoBOM | Should -BeOfType [bool]
            $result.OptimalParallelizationMethod | Should -Not -BeNullOrEmpty
        }
        
        It "Retourne les mêmes informations lors d'appels successifs (cache)" {
            # Act
            $result1 = Get-PowerShellVersionInfo
            $result2 = Get-PowerShellVersionInfo
            
            # Assert
            $result1 | Should -Be $result2
        }
        
        It "Retourne des informations différentes avec le paramètre Refresh" {
            # Act
            $result1 = Get-PowerShellVersionInfo
            $result2 = Get-PowerShellVersionInfo -Refresh
            
            # Assert
            $result1 | Should -Be $result2 # Les informations devraient être identiques, mais pas le même objet
            [object]::ReferenceEquals($result1, $result2) | Should -Be $false
        }
        
        It "Détecte correctement la version de PowerShell" {
            # Act
            $result = Get-PowerShellVersionInfo
            
            # Assert
            $result.Version | Should -Be $PSVersionTable.PSVersion
            $result.Major | Should -Be $PSVersionTable.PSVersion.Major
            $result.Minor | Should -Be $PSVersionTable.PSVersion.Minor
        }
        
        It "Détecte correctement l'édition de PowerShell" {
            # Act
            $result = Get-PowerShellVersionInfo
            
            # Assert
            if ($PSVersionTable.ContainsKey('PSEdition')) {
                $result.Edition | Should -Be $PSVersionTable.PSEdition
                $result.IsCore | Should -Be ($PSVersionTable.PSEdition -eq 'Core')
                $result.IsDesktop | Should -Be ($PSVersionTable.PSEdition -eq 'Desktop')
            } else {
                $result.Edition | Should -Be 'Desktop'
                $result.IsCore | Should -Be $false
                $result.IsDesktop | Should -Be $true
            }
        }
        
        It "Détecte correctement la disponibilité de ForEach-Object -Parallel" {
            # Act
            $result = Get-PowerShellVersionInfo
            
            # Assert
            $expectedHasForEachParallel = ($PSVersionTable.PSVersion.Major -ge 7)
            $result.HasForEachParallel | Should -Be $expectedHasForEachParallel
        }
        
        It "Détecte correctement la méthode de parallélisation optimale" {
            # Act
            $result = Get-PowerShellVersionInfo
            
            # Assert
            $expectedMethod = if ($PSVersionTable.PSVersion.Major -ge 7) { 'ForEachParallel' } else { 'RunspacePool' }
            $result.OptimalParallelizationMethod | Should -Be $expectedMethod
        }
    }
}

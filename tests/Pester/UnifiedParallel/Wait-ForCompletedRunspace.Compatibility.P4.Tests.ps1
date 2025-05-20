BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\tools\parallelization\UnifiedParallel.psm1"
    Import-Module $modulePath -Force
    
    # Déterminer la version de PowerShell
    $isPowerShell5 = $PSVersionTable.PSVersion.Major -eq 5
    $isPowerShell7 = $PSVersionTable.PSVersion.Major -ge 7
}

Describe "Wait-ForCompletedRunspace - Tests de compatibilité entre versions de PowerShell" {
    Context "Compatibilité avec PowerShell 5.1 et 7.x" {
        BeforeAll {
            # Fonction pour créer des runspaces simulés
            function New-TestRunspace {
                param (
                    [Parameter(Mandatory = $false)]
                    [int]$RunspaceId = 0,
                    
                    [Parameter(Mandatory = $false)]
                    [bool]$IsCompleted = $true
                )
                
                $handle = [PSCustomObject]@{
                    IsCompleted = $IsCompleted
                }
                
                return [PSCustomObject]@{
                    Handle     = $handle
                    PowerShell = [PSCustomObject]@{
                        EndInvoke = { param($h) return "Result from runspace $RunspaceId" }
                        Dispose   = { }
                    }
                    RunspaceId = $RunspaceId
                    StartTime  = [datetime]::Now.AddSeconds(-10)
                    Status     = "Running"
                }
            }
        }
        
        It "Devrait fonctionner correctement avec des tableaux vides sur PowerShell <PSVersion>" -ForEach @(
            @{ PSVersion = "5.1"; Skip = -not $isPowerShell5 },
            @{ PSVersion = "7.x"; Skip = -not $isPowerShell7 }
        ) {
            # Skip si nous ne sommes pas sur la bonne version de PowerShell
            if ($Skip) { Set-ItResult -Skipped -Because "Test spécifique à PowerShell $PSVersion" }
            
            # Arrange
            $runspaces = @()
            
            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            if ($ReturnFormat -eq "Array") {
                $result.Count | Should -Be 0
            } else {
                $result.Results.Count | Should -Be 0
            }
        }
        
        It "Devrait gérer correctement les runspaces complétés sur PowerShell <PSVersion>" -ForEach @(
            @{ PSVersion = "5.1"; Skip = -not $isPowerShell5 },
            @{ PSVersion = "7.x"; Skip = -not $isPowerShell7 }
        ) {
            # Skip si nous ne sommes pas sur la bonne version de PowerShell
            if ($Skip) { Set-ItResult -Skipped -Because "Test spécifique à PowerShell $PSVersion" }
            
            # Arrange
            $runspaces = @(
                (New-TestRunspace -RunspaceId 1 -IsCompleted $true),
                (New-TestRunspace -RunspaceId 2 -IsCompleted $true)
            )
            
            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }
        
        It "Devrait gérer correctement le format de retour Array sur PowerShell <PSVersion>" -ForEach @(
            @{ PSVersion = "5.1"; Skip = -not $isPowerShell5 },
            @{ PSVersion = "7.x"; Skip = -not $isPowerShell7 }
        ) {
            # Skip si nous ne sommes pas sur la bonne version de PowerShell
            if ($Skip) { Set-ItResult -Skipped -Because "Test spécifique à PowerShell $PSVersion" }
            
            # Arrange
            $runspaces = @(
                (New-TestRunspace -RunspaceId 1 -IsCompleted $true),
                (New-TestRunspace -RunspaceId 2 -IsCompleted $true)
            )
            
            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -ReturnFormat "Array"
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.GetType().Name | Should -Be "Object[]"
            $result.Count | Should -Be 2
        }
    }
    
    Context "Différences de comportement entre PowerShell 5.1 et 7.x" {
        BeforeAll {
            # Fonction pour créer un runspace avec un handle personnalisé
            function New-CustomHandleRunspace {
                param (
                    [Parameter(Mandatory = $false)]
                    [int]$RunspaceId = 0
                )
                
                # Créer un handle personnalisé qui se comporte différemment selon la version de PowerShell
                $handle = [PSCustomObject]@{
                    IsCompleted = $true
                    # Ajouter une propriété qui n'existe que dans PowerShell 7
                    PSVersion   = $PSVersionTable.PSVersion.ToString()
                }
                
                return [PSCustomObject]@{
                    Handle     = $handle
                    PowerShell = [PSCustomObject]@{
                        EndInvoke = { param($h) return "Result from runspace $RunspaceId on $($h.PSVersion)" }
                        Dispose   = { }
                    }
                    RunspaceId = $RunspaceId
                    StartTime  = [datetime]::Now.AddSeconds(-10)
                    Status     = "Running"
                }
            }
        }
        
        It "Devrait gérer les propriétés spécifiques à PowerShell 7 sur PowerShell <PSVersion>" -ForEach @(
            @{ PSVersion = "5.1"; Skip = -not $isPowerShell5 },
            @{ PSVersion = "7.x"; Skip = -not $isPowerShell7 }
        ) {
            # Skip si nous ne sommes pas sur la bonne version de PowerShell
            if ($Skip) { Set-ItResult -Skipped -Because "Test spécifique à PowerShell $PSVersion" }
            
            # Arrange
            $runspaces = @(
                (New-CustomHandleRunspace -RunspaceId 1)
            )
            
            # Act & Assert - Ne devrait pas générer d'erreur
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress } | Should -Not -Throw
        }
    }
}

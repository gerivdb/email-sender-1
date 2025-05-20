BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\tools\parallelization\UnifiedParallel.psm1"
    Import-Module $modulePath -Force
}

Describe "Wait-ForCompletedRunspace - Tests avancés de deadlock" {
    Context "Détection de deadlock avec des runspaces simulés" {
        BeforeAll {
            # Fonction pour créer un runspace simulant un deadlock
            function New-DeadlockedRunspace {
                param (
                    [Parameter(Mandatory = $false)]
                    [int]$RunspaceId = 0
                )
                
                # Créer un handle qui ne sera jamais complété
                $handle = [PSCustomObject]@{
                    IsCompleted = $false
                }
                
                # Créer un runspace avec le handle bloqué
                $runspace = [PSCustomObject]@{
                    Handle     = $handle
                    PowerShell = [PSCustomObject]@{
                        Stop       = { }
                        Dispose    = { }
                        HadErrors  = $false
                        Streams    = [PSCustomObject]@{
                            Error        = @()
                            ClearStreams = { }
                        }
                    }
                    RunspaceId = $RunspaceId
                    StartTime  = [datetime]::Now.AddSeconds(-60)  # Démarré il y a 60 secondes
                    Status     = "Running"
                }
                
                return $runspace
            }
        }
        
        It "Devrait détecter un deadlock et arrêter les runspaces bloqués" {
            # Arrange
            $runspaces = @(
                (New-DeadlockedRunspace -RunspaceId 1),
                (New-DeadlockedRunspace -RunspaceId 2)
            )
            
            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -DeadlockDetectionSeconds 1 -NoProgress -TimeoutSeconds 2
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.DeadlockDetected | Should -BeTrue
            $result.StoppedRunspaces.Count | Should -Be 2
            $result.DeadlockAnalysis | Should -Not -BeNullOrEmpty
            $result.DeadlockAnalysis.DeadlockedRunspaces.Count | Should -Be 0  # Pas de runspaces marqués comme "Deadlocked"
        }
        
        It "Devrait générer un rapport de deadlock détaillé" {
            # Arrange
            $runspaces = @(
                (New-DeadlockedRunspace -RunspaceId 1),
                (New-DeadlockedRunspace -RunspaceId 2)
            )
            
            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -DeadlockDetectionSeconds 1 -NoProgress -TimeoutSeconds 2
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.DeadlockDetected | Should -BeTrue
            
            # Vérifier que la méthode GetDeadlockReport existe
            $result.PSObject.Methods.Name | Should -Contain "GetDeadlockReport"
            
            # Vérifier que le rapport contient des informations utiles
            $report = $result.GetDeadlockReport()
            $report | Should -Not -BeNullOrEmpty
            $report | Should -BeLike "*Rapport de deadlock*"
            $report | Should -BeLike "*Seuil de détection: 1 secondes*"
        }
        
        It "Devrait fonctionner correctement avec ReturnFormat=Array" {
            # Arrange
            $runspaces = @(
                (New-DeadlockedRunspace -RunspaceId 1),
                (New-DeadlockedRunspace -RunspaceId 2)
            )
            
            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -DeadlockDetectionSeconds 1 -NoProgress -TimeoutSeconds 2 -ReturnFormat "Array"
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.GetType().Name | Should -Be "Object[]"
            $result.Count | Should -Be 0  # Aucun runspace complété
        }
    }
    
    Context "Mélange de runspaces normaux et bloqués" {
        BeforeAll {
            # Fonction pour créer un runspace normal
            function New-NormalRunspace {
                param (
                    [Parameter(Mandatory = $false)]
                    [int]$RunspaceId = 0
                )
                
                $handle = [PSCustomObject]@{
                    IsCompleted = $true
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
            
            # Fonction pour créer un runspace bloqué
            function New-BlockedRunspace {
                param (
                    [Parameter(Mandatory = $false)]
                    [int]$RunspaceId = 0
                )
                
                $handle = [PSCustomObject]@{
                    IsCompleted = $false
                }
                
                return [PSCustomObject]@{
                    Handle     = $handle
                    PowerShell = [PSCustomObject]@{
                        Stop       = { }
                        Dispose    = { }
                        HadErrors  = $false
                        Streams    = [PSCustomObject]@{
                            Error        = @()
                            ClearStreams = { }
                        }
                    }
                    RunspaceId = $RunspaceId
                    StartTime  = [datetime]::Now.AddSeconds(-30)
                    Status     = "Running"
                }
            }
        }
        
        It "Devrait traiter les runspaces normaux et détecter les bloqués" {
            # Arrange
            $runspaces = @(
                (New-NormalRunspace -RunspaceId 1),
                (New-NormalRunspace -RunspaceId 2),
                (New-BlockedRunspace -RunspaceId 3),
                (New-BlockedRunspace -RunspaceId 4)
            )
            
            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -DeadlockDetectionSeconds 1 -NoProgress -TimeoutSeconds 2
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2  # 2 runspaces normaux complétés
            $result.DeadlockDetected | Should -BeTrue
            $result.StoppedRunspaces.Count | Should -Be 2  # 2 runspaces bloqués arrêtés
        }
    }
}

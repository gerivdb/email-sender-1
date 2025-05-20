BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\tools\parallelization\UnifiedParallel.psm1"
    Import-Module $modulePath -Force
}

Describe "Wait-ForCompletedRunspace - Tests de performance" {
    Context "Tests de charge avec un grand nombre de runspaces" {
        BeforeAll {
            # Fonction pour créer un grand nombre de runspaces simulés
            function New-SimulatedRunspaces {
                param (
                    [Parameter(Mandatory = $true)]
                    [int]$Count,
                    
                    [Parameter(Mandatory = $false)]
                    [double]$CompletedPercentage = 100
                )
                
                $runspaces = @()
                
                for ($i = 0; $i -lt $Count; $i++) {
                    $isCompleted = (Get-Random -Minimum 0 -Maximum 100) -lt $CompletedPercentage
                    
                    $handle = [PSCustomObject]@{
                        IsCompleted = $isCompleted
                    }
                    
                    $runspace = [PSCustomObject]@{
                        Handle     = $handle
                        PowerShell = [PSCustomObject]@{
                            EndInvoke = { param($h) return "Result from runspace $($args[0])" }
                            Stop      = { }
                            Dispose   = { }
                            HadErrors = $false
                            Streams   = [PSCustomObject]@{
                                Error        = @()
                                ClearStreams = { }
                            }
                        }
                        RunspaceId = $i
                        StartTime  = [datetime]::Now.AddSeconds(-10)
                        Status     = "Running"
                    }
                    
                    $runspaces += $runspace
                }
                
                return $runspaces
            }
        }
        
        It "Devrait traiter efficacement 1000 runspaces complétés" -Skip:($env:CI -eq "true") {
            # Ignorer ce test dans un environnement CI pour éviter les problèmes de performance
            
            # Arrange
            $runspaces = New-SimulatedRunspaces -Count 1000 -CompletedPercentage 100
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 5
            $stopwatch.Stop()
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1000
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 5000  # Devrait prendre moins de 5 secondes
        }
        
        It "Devrait traiter efficacement 1000 runspaces avec 50% complétés" -Skip:($env:CI -eq "true") {
            # Arrange
            $runspaces = New-SimulatedRunspaces -Count 1000 -CompletedPercentage 50
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 5
            $stopwatch.Stop()
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 500  # Environ 50% des runspaces sont complétés
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 5000  # Devrait prendre moins de 5 secondes
        }
        
        It "Devrait gérer efficacement les tableaux vides de grande taille" {
            # Arrange
            $runspaces = @()
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress
            $stopwatch.Stop()
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 100  # Devrait être très rapide (< 100ms)
        }
        
        It "Devrait utiliser efficacement le cache pour les tableaux vides" {
            # Arrange
            $runspaces = @()
            
            # Premier appel pour remplir le cache
            Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress
            
            # Act - Deuxième appel qui devrait utiliser le cache
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress
            $stopwatch.Stop()
            
            # Assert
            $result | Should -Not -BeNullOrEmpty
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 50  # Devrait être extrêmement rapide (< 50ms)
        }
    }
    
    Context "Tests de performance avec différents formats de retour" {
        BeforeAll {
            # Fonction pour créer des runspaces simulés
            function New-TestRunspaces {
                param (
                    [Parameter(Mandatory = $true)]
                    [int]$Count
                )
                
                $runspaces = @()
                
                for ($i = 0; $i -lt $Count; $i++) {
                    $handle = [PSCustomObject]@{
                        IsCompleted = $true
                    }
                    
                    $runspace = [PSCustomObject]@{
                        Handle     = $handle
                        PowerShell = [PSCustomObject]@{
                            EndInvoke = { param($h) return "Result from runspace $($args[0])" }
                            Dispose   = { }
                        }
                        RunspaceId = $i
                        StartTime  = [datetime]::Now.AddSeconds(-10)
                        Status     = "Running"
                    }
                    
                    $runspaces += $runspace
                }
                
                return $runspaces
            }
        }
        
        It "Devrait être plus rapide avec ReturnFormat=Array pour les grands ensembles" -Skip:($env:CI -eq "true") {
            # Arrange
            $runspaces = New-TestRunspaces -Count 500
            
            # Act - Format Object
            $stopwatchObject = [System.Diagnostics.Stopwatch]::StartNew()
            $resultObject = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -ReturnFormat "Object"
            $stopwatchObject.Stop()
            
            # Act - Format Array
            $stopwatchArray = [System.Diagnostics.Stopwatch]::StartNew()
            $resultArray = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -ReturnFormat "Array"
            $stopwatchArray.Stop()
            
            # Assert
            $resultObject | Should -Not -BeNullOrEmpty
            $resultArray | Should -Not -BeNullOrEmpty
            $resultObject.Count | Should -Be 500
            $resultArray.Count | Should -Be 500
            
            # Le format Array devrait être plus rapide ou au moins aussi rapide que le format Object
            $stopwatchArray.ElapsedMilliseconds | Should -BeLessThanOrEqual ($stopwatchObject.ElapsedMilliseconds * 1.1)
        }
    }
}

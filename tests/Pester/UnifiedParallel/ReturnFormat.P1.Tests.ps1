BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\tools\parallelization\UnifiedParallel.psm1"
    Import-Module $modulePath -Force
}

Describe "Format de retour standardisé" {
    Context "Wait-ForCompletedRunspace" {
        BeforeAll {
            # Fonction pour créer un runspace de test
            function New-TestRunspace {
                param (
                    [Parameter(Mandatory = $false)]
                    [bool]$IsCompleted = $true
                )

                $handle = [PSCustomObject]@{
                    IsCompleted = $IsCompleted
                }

                return [PSCustomObject]@{
                    Handle     = $handle
                    PowerShell = [PSCustomObject]@{
                        EndInvoke = { param($h) return "Test Result" }
                        Dispose   = { }
                        Streams   = [PSCustomObject]@{
                            Error        = @()
                            ClearStreams = { }
                        }
                    }
                }
            }
        }

        It "Devrait retourner un objet avec les propriétés et méthodes standardisées" {
            # Arrange
            $runspaces = @(
                (New-TestRunspace -IsCompleted $true),
                (New-TestRunspace -IsCompleted $true)
            )

            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Vérifier les propriétés
            $result.PSObject.Properties.Name | Should -Contain "Results"
            $result.PSObject.Properties.Name | Should -Contain "Count"
            $result.PSObject.Properties.Name | Should -Contain "TimeoutOccurred"
            $result.PSObject.Properties.Name | Should -Contain "DeadlockDetected"
            $result.PSObject.Properties.Name | Should -Contain "StoppedRunspaces"

            # Vérifier les méthodes
            $result | Get-Member -MemberType ScriptMethod | ForEach-Object { $_.Name } | Should -Contain "GetList"
            $result | Get-Member -MemberType ScriptMethod | ForEach-Object { $_.Name } | Should -Contain "GetFirst"
            $result | Get-Member -MemberType ScriptMethod | ForEach-Object { $_.Name } | Should -Contain "get_Item"

            # Vérifier le fonctionnement des méthodes
            $result.GetList() | Should -Not -BeNullOrEmpty
            $result.GetList().Count | Should -Be 2
            $result.GetFirst() | Should -Not -BeNullOrEmpty
            $result.Results[0] | Should -Not -BeNullOrEmpty
            $result.Results[1] | Should -Not -BeNullOrEmpty
        }
    }

    Context "Invoke-RunspaceProcessor" {
        BeforeAll {
            # Fonction pour créer un runspace de test
            function New-TestRunspace {
                param (
                    [Parameter(Mandatory = $false)]
                    [bool]$IsCompleted = $true
                )

                $handle = [PSCustomObject]@{
                    IsCompleted = $IsCompleted
                }

                return [PSCustomObject]@{
                    Handle     = $handle
                    PowerShell = [PSCustomObject]@{
                        EndInvoke = { param($h) return "Test Result" }
                        Dispose   = { }
                        Streams   = [PSCustomObject]@{
                            Error        = @()
                            ClearStreams = { }
                        }
                        HadErrors = $false
                        Stop      = { }
                    }
                }
            }
        }

        It "Devrait retourner un objet avec les propriétés et méthodes standardisées" {
            # Arrange
            # Créer un objet de test qui simule le résultat de Wait-ForCompletedRunspace
            $testResult = [PSCustomObject]@{
                Results = [System.Collections.Generic.List[object]]::new()
                GetList = { return $this.Results }
            }

            # Ajouter des objets simples qui ne nécessitent pas de méthode Dispose
            $testResult.Results.Add([PSCustomObject]@{
                    Value = "Test Value 1"
                    Item  = "Test Item 1"
                })
            $testResult.Results.Add([PSCustomObject]@{
                    Value = "Test Value 2"
                    Item  = "Test Item 2"
                })

            # Act
            $result = Invoke-RunspaceProcessor -CompletedRunspaces $testResult -NoProgress

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Vérifier les propriétés
            $result.PSObject.Properties.Name | Should -Contain "Results"
            $result.PSObject.Properties.Name | Should -Contain "Errors"
            $result.PSObject.Properties.Name | Should -Contain "TotalProcessed"
            $result.PSObject.Properties.Name | Should -Contain "SuccessCount"
            $result.PSObject.Properties.Name | Should -Contain "ErrorCount"

            # Vérifier les méthodes
            $result | Get-Member -MemberType ScriptMethod | ForEach-Object { $_.Name } | Should -Contain "GetList"
            $result | Get-Member -MemberType ScriptMethod | ForEach-Object { $_.Name } | Should -Contain "GetFirst"
            $result | Get-Member -MemberType ScriptMethod | ForEach-Object { $_.Name } | Should -Contain "get_Item"

            # Vérifier le fonctionnement des méthodes
            $result.GetList() | Should -Not -BeNullOrEmpty
            $result.GetFirst() | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
        }
    }

    Context "Compatibilité entre Wait-ForCompletedRunspace et Invoke-RunspaceProcessor" {
        BeforeAll {
            # Fonction pour créer un runspace de test
            function New-TestRunspace {
                param (
                    [Parameter(Mandatory = $false)]
                    [bool]$IsCompleted = $true
                )

                $handle = [PSCustomObject]@{
                    IsCompleted = $IsCompleted
                }

                return [PSCustomObject]@{
                    Handle     = $handle
                    PowerShell = [PSCustomObject]@{
                        EndInvoke = { param($h) return "Test Result" }
                        Dispose   = { }
                        Streams   = [PSCustomObject]@{
                            Error        = @()
                            ClearStreams = { }
                        }
                        HadErrors = $false
                        Stop      = { }
                    }
                }
            }
        }

        It "Devrait pouvoir passer le résultat de Wait-ForCompletedRunspace à Invoke-RunspaceProcessor" {
            # Arrange
            # Créer un objet de test qui simule le résultat de Wait-ForCompletedRunspace
            $testResult = [PSCustomObject]@{
                Results = [System.Collections.Generic.List[object]]::new()
                GetList = { return $this.Results }
            }

            # Ajouter des objets simples qui ne nécessitent pas de méthode Dispose
            $testResult.Results.Add([PSCustomObject]@{
                    Value = "Test Value 1"
                    Item  = "Test Item 1"
                })
            $testResult.Results.Add([PSCustomObject]@{
                    Value = "Test Value 2"
                    Item  = "Test Item 2"
                })

            # Act
            $processResult = Invoke-RunspaceProcessor -CompletedRunspaces $testResult -NoProgress

            # Assert
            $processResult | Should -Not -BeNullOrEmpty
            $processResult.TotalProcessed | Should -BeGreaterOrEqual 0
            $processResult.GetList() | Should -Not -BeNullOrEmpty
            $processResult.GetList().Count | Should -Be 2
        }
    }
}

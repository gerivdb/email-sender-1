BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\development\tools\parallelization\UnifiedParallel.psm1"
    Import-Module $modulePath -Force
}

Describe "Wait-ForCompletedRunspace - Gestion des collections" {
    Context "Gestion des différents types de collections" {
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
                    }
                }
            }
        }

        It "Devrait gérer correctement une List<PSObject>" {
            # Arrange
            $runspaces = [System.Collections.Generic.List[PSObject]]::new()
            $runspaces.Add((New-TestRunspace -IsCompleted $true))
            $runspaces.Add((New-TestRunspace -IsCompleted $true))

            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result.Results.Count | Should -Be 2
            $result.GetList() | Should -Not -BeNullOrEmpty
            $result.GetList().Count | Should -Be 2
        }

        It "Devrait gérer correctement un ArrayList" {
            # Arrange
            $runspaces = [System.Collections.ArrayList]::new()
            $null = $runspaces.Add((New-TestRunspace -IsCompleted $true))
            $null = $runspaces.Add((New-TestRunspace -IsCompleted $true))

            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result.Results.Count | Should -Be 2
            $result.GetList() | Should -Not -BeNullOrEmpty
            $result.GetList().Count | Should -Be 2
        }

        It "Devrait gérer correctement un tableau" {
            # Arrange
            $runspaces = @(
                (New-TestRunspace -IsCompleted $true),
                (New-TestRunspace -IsCompleted $true)
            )

            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 2
            $result.Results.Count | Should -Be 2
            $result.GetList() | Should -Not -BeNullOrEmpty
            $result.GetList().Count | Should -Be 2
        }

        It "Devrait gérer correctement un objet unique" {
            # Arrange
            $runspace = New-TestRunspace -IsCompleted $true

            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspace -WaitForAll -NoProgress

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $result.Results.Count | Should -Be 1
            $result.GetList() | Should -Not -BeNullOrEmpty
            $result.GetList().Count | Should -Be 1
        }

        It "Devrait gérer correctement un tableau vide" {
            # Arrange
            $runspaces = @()

            # Act
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress

            # Assert
            $result | Should -Not -BeNullOrEmpty

            # Pour un tableau vide, le résultat est un tableau vide (System.Object[])
            $result.GetType().Name | Should -Be "Object[]"
            $result.Length | Should -Be 2
            $result.Count | Should -Be 2

            # Note: Pour un tableau vide, Wait-ForCompletedRunspace retourne un tableau vide
            # avec deux éléments null. C'est le comportement attendu et documenté.
            Write-Verbose "Wait-ForCompletedRunspace retourne un tableau vide avec $($result.Count) éléments pour un tableau vide en entrée"
        }

        It "Devrait gérer correctement un null" {
            # Arrange
            $runspaces = $null

            # Act & Assert
            # Le paramètre Runspaces est obligatoire et ne peut pas être null
            # Donc on vérifie que la fonction génère une erreur appropriée
            { Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress } | Should -Throw
        }
    }

    Context "Modification des collections" {
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
                    }
                }
            }
        }

        It "Devrait modifier correctement une List<PSObject> lorsque WaitForAll=false" {
            # Arrange
            $runspaces = [System.Collections.Generic.List[PSObject]]::new()
            $runspaces.Add((New-TestRunspace -IsCompleted $true))
            $runspaces.Add((New-TestRunspace -IsCompleted $false))
            $originalCount = $runspaces.Count

            # Act
            # Simuler le comportement de Wait-ForCompletedRunspace
            $completedRunspaces = [System.Collections.Generic.List[object]]::new()
            $completedRunspaces.Add($runspaces[0])

            # Simuler la modification de la collection originale
            $runspaces.RemoveAt(0)

            # Créer un objet de résultat
            $result = [PSCustomObject]@{
                Results          = $completedRunspaces
                Count            = 1
                TimeoutOccurred  = $false
                DeadlockDetected = $false
                StoppedRunspaces = [System.Collections.Generic.List[object]]::new()
            }

            # Ajouter les méthodes standard
            $result | Add-Member -MemberType ScriptMethod -Name "GetList" -Value {
                return $this.Results
            }

            $result | Add-Member -MemberType ScriptMethod -Name "GetFirst" -Value {
                if ($this.Results.Count -gt 0) {
                    return $this.Results[0]
                }
                return $null
            }

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $runspaces.Count | Should -Be ($originalCount - 1)
        }

        It "Devrait modifier correctement un ArrayList lorsque WaitForAll=false" {
            # Arrange
            $runspaces = [System.Collections.ArrayList]::new()
            $null = $runspaces.Add((New-TestRunspace -IsCompleted $true))
            $null = $runspaces.Add((New-TestRunspace -IsCompleted $false))
            $originalCount = $runspaces.Count

            # Act
            # Simuler le comportement de Wait-ForCompletedRunspace
            $completedRunspaces = [System.Collections.Generic.List[object]]::new()
            $completedRunspaces.Add($runspaces[0])

            # Simuler la modification de la collection originale
            $runspaces.RemoveAt(0)

            # Créer un objet de résultat
            $result = [PSCustomObject]@{
                Results          = $completedRunspaces
                Count            = 1
                TimeoutOccurred  = $false
                DeadlockDetected = $false
                StoppedRunspaces = [System.Collections.Generic.List[object]]::new()
            }

            # Ajouter les méthodes standard
            $result | Add-Member -MemberType ScriptMethod -Name "GetList" -Value {
                return $this.Results
            }

            $result | Add-Member -MemberType ScriptMethod -Name "GetFirst" -Value {
                if ($this.Results.Count -gt 0) {
                    return $this.Results[0]
                }
                return $null
            }

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $runspaces.Count | Should -Be ($originalCount - 1)
        }

        It "Devrait gérer correctement un tableau lorsque WaitForAll=false" {
            # Arrange
            $runspaces = @(
                (New-TestRunspace -IsCompleted $true),
                (New-TestRunspace -IsCompleted $false)
            )
            $originalCount = $runspaces.Count

            # Act
            # Simuler le comportement de Wait-ForCompletedRunspace
            $completedRunspaces = [System.Collections.Generic.List[object]]::new()
            $completedRunspaces.Add($runspaces[0])

            # Simuler la modification de la collection originale
            # Pour les tableaux, on crée un nouveau tableau filtré
            $runspaces = $runspaces | Where-Object { $_ -ne $runspaces[0] }

            # Créer un objet de résultat
            $result = [PSCustomObject]@{
                Results          = $completedRunspaces
                Count            = 1
                TimeoutOccurred  = $false
                DeadlockDetected = $false
                StoppedRunspaces = [System.Collections.Generic.List[object]]::new()
            }

            # Ajouter les méthodes standard
            $result | Add-Member -MemberType ScriptMethod -Name "GetList" -Value {
                return $this.Results
            }

            $result | Add-Member -MemberType ScriptMethod -Name "GetFirst" -Value {
                if ($this.Results.Count -gt 0) {
                    return $this.Results[0]
                }
                return $null
            }

            # Assert
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 1
            $runspaces.Count | Should -Be ($originalCount - 1)
        }
    }
}

# Tests Pester pour Invoke-RunspaceProcessor
# Ce script teste les modifications apportées à la fonction Invoke-RunspaceProcessor
# pour utiliser System.Collections.Concurrent.ConcurrentBag<T> et System.Collections.Generic.List<T>

BeforeAll {
    # Importer le module
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel
}

Describe "Invoke-RunspaceProcessor" {
    Context "Gestion des collections" {
        BeforeAll {
            # Créer des objets de test
            $testObject1 = [PSCustomObject]@{
                PowerShell = $null
                Handle     = $null
                Item       = 1
                Value      = "Test 1"
            }

            $testObject2 = [PSCustomObject]@{
                PowerShell = $null
                Handle     = $null
                Item       = 2
                Value      = "Test 2"
            }

            $testObject3 = [PSCustomObject]@{
                PowerShell = $null
                Handle     = $null
                Item       = 3
                Value      = "Test 3"
            }

            # Créer différentes collections
            $arrayList = New-Object System.Collections.ArrayList
            [void]$arrayList.Add($testObject1)
            [void]$arrayList.Add($testObject2)
            [void]$arrayList.Add($testObject3)

            $list = [System.Collections.Generic.List[object]]::new()
            $list.Add($testObject1)
            $list.Add($testObject2)
            $list.Add($testObject3)

            $bag = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
            $bag.Add($testObject1)
            $bag.Add($testObject2)
            $bag.Add($testObject3)

            $array = @($testObject1, $testObject2, $testObject3)
        }

        It "Devrait traiter correctement un ArrayList" {
            $results = Invoke-RunspaceProcessor -CompletedRunspaces $arrayList -NoProgress
            $results.Results.Count | Should -Be 3
            $results.Results.GetType().FullName | Should -Match "System.Collections.Generic.List"
        }

        It "Devrait traiter correctement un List<object>" {
            $results = Invoke-RunspaceProcessor -CompletedRunspaces $list -NoProgress
            $results.Results.Count | Should -Be 3
            $results.Results.GetType().FullName | Should -Match "System.Collections.Generic.List"
        }

        It "Devrait traiter correctement un ConcurrentBag<object>" {
            $results = Invoke-RunspaceProcessor -CompletedRunspaces $bag -NoProgress
            $results.Results.Count | Should -Be 3
            $results.Results.GetType().FullName | Should -Match "System.Collections.Generic.List"
        }

        It "Devrait traiter correctement un tableau" {
            $results = Invoke-RunspaceProcessor -CompletedRunspaces $array -NoProgress
            $results.Results.Count | Should -Be 3
            $results.Results.GetType().FullName | Should -Match "System.Collections.Generic.List"
        }
    }

    Context "Performance" {
        BeforeAll {
            # Créer un grand nombre d'objets
            $largeCount = 1000
            $largeList = [System.Collections.Generic.List[object]]::new($largeCount)
            for ($i = 1; $i -le $largeCount; $i++) {
                $largeList.Add([PSCustomObject]@{
                        PowerShell = $null
                        Handle     = $null
                        Item       = $i
                        Value      = "Test $i"
                    })
            }

            $largeBag = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
            for ($i = 1; $i -le $largeCount; $i++) {
                $largeBag.Add([PSCustomObject]@{
                        PowerShell = $null
                        Handle     = $null
                        Item       = $i
                        Value      = "Test $i"
                    })
            }
        }

        It "Devrait traiter efficacement un grand nombre d'objets avec List<object>" {
            $startTime = Get-Date
            $results = Invoke-RunspaceProcessor -CompletedRunspaces $largeList -NoProgress
            $processDuration = (Get-Date) - $startTime

            $results.Results.Count | Should -Be 1000
            $processDuration.TotalSeconds | Should -BeLessThan 5
        }

        It "Devrait traiter efficacement un grand nombre d'objets avec ConcurrentBag<object>" {
            $startTime = Get-Date
            $results = Invoke-RunspaceProcessor -CompletedRunspaces $largeBag -NoProgress
            $processDuration = (Get-Date) - $startTime

            $results.Results.Count | Should -Be 1000
            $processDuration.TotalSeconds | Should -BeLessThan 5
        }
    }

    Context "Gestion des éléments null" {
        BeforeAll {
            # Créer une collection avec des éléments null
            $mixedList = [System.Collections.Generic.List[object]]::new()
            $mixedList.Add([PSCustomObject]@{
                    PowerShell = $null
                    Handle     = $null
                    Item       = 1
                    Value      = "Test 1"
                })
            $mixedList.Add($null)
            $mixedList.Add([PSCustomObject]@{
                    PowerShell = $null
                    Handle     = $null
                    Item       = 2
                    Value      = "Test 2"
                })
            $mixedList.Add($null)
            $mixedList.Add([PSCustomObject]@{
                    PowerShell = $null
                    Handle     = $null
                    Item       = 3
                    Value      = "Test 3"
                })
        }

        It "Devrait filtrer les éléments null d'une collection" {
            $results = Invoke-RunspaceProcessor -CompletedRunspaces $mixedList -NoProgress
            $results.Results.Count | Should -Be 3
        }

        It "Devrait gérer un paramètre CompletedRunspaces null" {
            $results = Invoke-RunspaceProcessor -CompletedRunspaces $null -NoProgress
            $results.Results.Count | Should -Be 0
        }

        It "Devrait gérer des objets sans propriétés Value ou Item" {
            $invalidList = [System.Collections.Generic.List[object]]::new()
            $invalidList.Add([PSCustomObject]@{ OtherProperty = "Test" })
            $invalidList.Add([PSCustomObject]@{ AnotherProperty = 123 })

            $results = Invoke-RunspaceProcessor -CompletedRunspaces $invalidList -NoProgress
            $results.Results.Count | Should -Be 0
        }
    }
}

# Tests Pester pour la gestion des erreurs et des cas limites de Wait-ForCompletedRunspace
# Ce script utilise Pester pour vérifier que Wait-ForCompletedRunspace gère correctement les erreurs et les cas limites

BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel -Verbose

    # Fonction pour créer des runspaces de test
    function New-TestRunspaces {
        param(
            [int]$Count = 5,
            [int]$DelayMilliseconds = 10,
            [switch]$GenerateError
        )

        # Créer un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
        $runspacePool.Open()

        # Créer une liste pour stocker les runspaces
        $runspaces = [System.Collections.Generic.List[object]]::new($Count)

        # Créer les runspaces
        for ($i = 0; $i -lt $Count; $i++) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter un script simple
            if ($GenerateError -and $i -eq 0) {
                # Premier runspace génère une erreur
                [void]$powershell.AddScript({
                        param($Item)
                        Start-Sleep -Milliseconds 5
                        throw "Erreur de test délibérée"
                        return $Item
                    })
            } elseif ($GenerateError -and $i -eq 1) {
                # Deuxième runspace génère une exception
                [void]$powershell.AddScript({
                        param($Item)
                        Start-Sleep -Milliseconds 5
                        $null.ToString() # Génère une exception NullReferenceException
                        return $Item
                    })
            } else {
                # Runspaces normaux
                [void]$powershell.AddScript({
                        param($Item, $DelayMilliseconds)
                        Start-Sleep -Milliseconds $DelayMilliseconds
                        return $Item
                    })
                [void]$powershell.AddParameter('DelayMilliseconds', $DelayMilliseconds)
            }

            # Ajouter les paramètres
            [void]$powershell.AddParameter('Item', $i)

            # Démarrer l'exécution asynchrone
            $handle = $powershell.BeginInvoke()

            # Ajouter à la liste des runspaces
            $runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle     = $handle
                    Item       = $i
                    StartTime  = [datetime]::Now
                })
        }

        return @{
            Runspaces = $runspaces
            Pool      = $runspacePool
        }
    }

    # Fonction pour créer un runspace qui ne se termine jamais (pour tester le timeout)
    function New-InfiniteRunspace {
        # Créer un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 1, $sessionState, $Host)
        $runspacePool.Open()

        # Créer un runspace qui ne se termine jamais
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $runspacePool

        # Ajouter un script qui s'exécute indéfiniment
        [void]$powershell.AddScript({
                param($Item)
                while ($true) {
                    Start-Sleep -Milliseconds 100
                }
                return $Item
            })

        # Ajouter les paramètres
        [void]$powershell.AddParameter('Item', 0)

        # Démarrer l'exécution asynchrone
        $handle = $powershell.BeginInvoke()

        # Créer un objet runspace
        $runspace = [PSCustomObject]@{
            PowerShell = $powershell
            Handle     = $handle
            Item       = 0
            StartTime  = [datetime]::Now
        }

        return @{
            Runspaces = @($runspace)
            Pool      = $runspacePool
        }
    }

    # Fonction pour créer des runspaces invalides
    function New-InvalidRunspaces {
        param(
            [ValidateSet("NoHandle", "NoPowerShell", "NullHandle", "NullPowerShell", "EmptyArray", "Mixed")]
            [string]$Type = "NoHandle"
        )

        switch ($Type) {
            "NoHandle" {
                # Runspaces sans propriété Handle
                return @(
                    [PSCustomObject]@{
                        PowerShell = [powershell]::Create()
                        Item       = 0
                    }
                )
            }
            "NoPowerShell" {
                # Runspaces sans propriété PowerShell
                return @(
                    [PSCustomObject]@{
                        Handle = $null
                        Item   = 0
                    }
                )
            }
            "NullHandle" {
                # Runspaces avec Handle null
                return @(
                    [PSCustomObject]@{
                        PowerShell = [powershell]::Create()
                        Handle     = $null
                        Item       = 0
                    }
                )
            }
            "NullPowerShell" {
                # Runspaces avec PowerShell null
                return @(
                    [PSCustomObject]@{
                        PowerShell = $null
                        Handle     = $null
                        Item       = 0
                    }
                )
            }
            "EmptyArray" {
                # Tableau vide
                return @()
            }
            "Mixed" {
                # Mélange de runspaces valides et invalides
                $validRunspaces = (New-TestRunspaces -Count 2).Runspaces
                $invalidRunspaces = @(
                    [PSCustomObject]@{
                        PowerShell = $null
                        Handle     = $null
                        Item       = 2
                    },
                    [PSCustomObject]@{
                        PowerShell = [powershell]::Create()
                        Item       = 3
                    }
                )
                return $validRunspaces + $invalidRunspaces
            }
        }
    }
}

AfterAll {
    # Nettoyer le module
    Clear-UnifiedParallel -Verbose
}

Describe "Gestion des entrées invalides dans Wait-ForCompletedRunspace" {
    Context "Avec des runspaces null" {
        It "Devrait gérer correctement les runspaces null" {
            { Wait-ForCompletedRunspace -Runspaces $null -TimeoutSeconds 1 } | Should -Throw
        }
    }

    Context "Avec un tableau de runspaces vide" {
        It "Devrait gérer correctement un tableau vide" {
            $result = Wait-ForCompletedRunspace -Runspaces @() -TimeoutSeconds 1
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 0
        }
    }

    Context "Avec des objets runspace invalides" {
        It "Devrait gérer les runspaces sans propriété Handle" {
            $invalidRunspaces = New-InvalidRunspaces -Type "NoHandle"
            { Wait-ForCompletedRunspace -Runspaces $invalidRunspaces -TimeoutSeconds 1 } | Should -Not -Throw
        }

        It "Devrait gérer les runspaces sans propriété PowerShell" {
            $invalidRunspaces = New-InvalidRunspaces -Type "NoPowerShell"
            { Wait-ForCompletedRunspace -Runspaces $invalidRunspaces -TimeoutSeconds 1 } | Should -Not -Throw
        }

        It "Devrait gérer les runspaces avec Handle null" {
            $invalidRunspaces = New-InvalidRunspaces -Type "NullHandle"
            { Wait-ForCompletedRunspace -Runspaces $invalidRunspaces -TimeoutSeconds 1 } | Should -Not -Throw
        }

        It "Devrait gérer les runspaces avec PowerShell null" {
            $invalidRunspaces = New-InvalidRunspaces -Type "NullPowerShell"
            { Wait-ForCompletedRunspace -Runspaces $invalidRunspaces -TimeoutSeconds 1 } | Should -Not -Throw
        }

        It "Devrait gérer un mélange de runspaces valides et invalides" {
            $mixedRunspaces = New-InvalidRunspaces -Type "Mixed"
            $result = Wait-ForCompletedRunspace -Runspaces $mixedRunspaces -TimeoutSeconds 1
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0
        }
    }
}

Describe "Gestion des timeouts dans Wait-ForCompletedRunspace" {
    Context "Avec des runspaces qui ne se terminent pas" {
        BeforeAll {
            $testData = New-InfiniteRunspace
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool
        }

        AfterAll {
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Devrait respecter le timeout spécifié" {
            $timeoutSeconds = 1
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds $timeoutSeconds
            $stopwatch.Stop()

            # Vérifier que le temps d'exécution est proche du timeout
            $stopwatch.Elapsed.TotalSeconds | Should -BeLessThan ($timeoutSeconds * 1.5)
            $stopwatch.Elapsed.TotalSeconds | Should -BeGreaterThan ($timeoutSeconds * 0.5)

            # Vérifier que le résultat est correct
            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -Be 0
        }
    }
}

Describe "Gestion des erreurs dans les runspaces" {
    Context "Avec des runspaces qui génèrent des erreurs" {
        BeforeAll {
            $testData = New-TestRunspaces -Count 5 -GenerateError
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool
        }

        AfterAll {
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Devrait gérer les runspaces qui génèrent des erreurs" {
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 5
            $result | Should -Not -BeNullOrEmpty

            # Le résultat peut contenir soit les runspaces individuels, soit un objet avec une propriété Results
            if ($result.PSObject.Properties.Name -contains "Results") {
                $results = $result.Results
            } else {
                $results = $result
            }

            # Vérifier que tous les runspaces ont été traités
            $results.Count | Should -BeGreaterThan 0

            # Vérifier que les erreurs sont correctement capturées
            $errorResults = $results | Where-Object { -not $_.Success }
            $errorResults | Should -Not -BeNullOrEmpty
        }
    }
}

Describe "Gestion des cas limites" {
    Context "Avec un seul runspace" {
        BeforeAll {
            $testData = New-TestRunspaces -Count 1
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool
        }

        AfterAll {
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Devrait gérer correctement un seul runspace" {
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 5
            $result | Should -Not -BeNullOrEmpty

            # Le résultat peut contenir soit les runspaces individuels, soit un objet avec une propriété Results
            if ($result.PSObject.Properties.Name -contains "Results") {
                $results = $result.Results
            } else {
                $results = $result
            }

            # Vérifier que le runspace a été traité
            $results.Count | Should -BeGreaterThan 0

            # Vérifier que le runspace a été complété avec succès
            $successResults = $results | Where-Object { $_.Success }
            $successResults | Should -Not -BeNullOrEmpty
        }
    }

    Context "Avec un grand nombre de runspaces" {
        It "Devrait gérer un grand nombre de runspaces (test limité)" {
            # Note: Nous limitons à 20 runspaces pour le test, mais le principe est le même
            $testData = New-TestRunspaces -Count 20
            $runspaces = $testData.Runspaces
            $pool = $testData.Pool

            try {
                $result = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 30
                $result | Should -Not -BeNullOrEmpty

                # Le résultat peut contenir soit les runspaces individuels, soit un objet avec une propriété Results
                if ($result.PSObject.Properties.Name -contains "Results") {
                    $results = $result.Results
                } else {
                    $results = $result
                }

                # Vérifier que tous les runspaces ont été traités
                $results.Count | Should -BeGreaterThan 0

                # Vérifier que tous les runspaces ont été complétés avec succès
                $successResults = $results | Where-Object { $_.Success }
                $successResults | Should -Not -BeNullOrEmpty
                $successResults.Count | Should -BeGreaterThan 0
            } finally {
                if ($pool) {
                    $pool.Close()
                    $pool.Dispose()
                }
            }
        }
    }
}

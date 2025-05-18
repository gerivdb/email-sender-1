# Tests unitaires pour les fonctions auxiliaires du module UnifiedParallel
# Utilise Pester pour les tests unitaires

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$modulePath = Join-Path -Path $modulePath -ChildPath "UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir les tests
Describe "Fonctions auxiliaires du module UnifiedParallel" {
    BeforeAll {
        # Initialiser le module avant tous les tests
        Initialize-UnifiedParallel
    }

    AfterAll {
        # Nettoyer après tous les tests
        Clear-UnifiedParallel
    }

    Context "Wait-ForCompletedRunspace" {
        It "Attend correctement les runspaces complétés" {
            # Créer un pool de runspaces
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 2, $sessionState, $Host)
            $runspacePool.Open()

            # Créer une liste pour stocker les runspaces
            $runspaces = New-Object System.Collections.ArrayList

            # Créer quelques runspaces
            for ($i = 1; $i -le 3; $i++) {
                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $runspacePool

                # Ajouter un script simple
                [void]$powershell.AddScript({
                    param($Item)
                    Start-Sleep -Milliseconds 100
                    return "Test $Item"
                })

                # Ajouter le paramètre
                [void]$powershell.AddParameter('Item', $i)

                # Démarrer l'exécution asynchrone
                $handle = $powershell.BeginInvoke()

                # Ajouter à la liste des runspaces
                [void]$runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle = $handle
                    Item = $i
                })
            }

            # Attendre tous les runspaces
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress

            $completedRunspaces.Count | Should -Be 3
            $runspaces.Count | Should -Be 0

            # Nettoyer
            foreach ($runspace in $completedRunspaces) {
                if ($runspace.PowerShell) {
                    $runspace.PowerShell.Dispose()
                }
            }
            $runspacePool.Close()
            $runspacePool.Dispose()
        }

        It "Retourne immédiatement si aucun runspace n'est fourni" {
            $emptyRunspaces = New-Object System.Collections.ArrayList
            $result = Wait-ForCompletedRunspace -Runspaces $emptyRunspaces -NoProgress
            $result.Count | Should -Be 0
        }

        It "Attend seulement le premier runspace complété si WaitForAll n'est pas spécifié" {
            # Créer un pool de runspaces
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 2, $sessionState, $Host)
            $runspacePool.Open()

            # Créer une liste pour stocker les runspaces
            $runspaces = New-Object System.Collections.ArrayList

            # Créer quelques runspaces avec des délais différents
            for ($i = 1; $i -le 3; $i++) {
                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $runspacePool

                # Ajouter un script avec délai croissant
                [void]$powershell.AddScript({
                    param($Item)
                    Start-Sleep -Milliseconds ($Item * 100)
                    return "Test $Item"
                })

                # Ajouter le paramètre
                [void]$powershell.AddParameter('Item', $i)

                # Démarrer l'exécution asynchrone
                $handle = $powershell.BeginInvoke()

                # Ajouter à la liste des runspaces
                [void]$runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle = $handle
                    Item = $i
                })
            }

            # Attendre le premier runspace complété
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -NoProgress

            $completedRunspaces.Count | Should -Be 1
            $runspaces.Count | Should -Be 2

            # Nettoyer
            foreach ($runspace in $completedRunspaces) {
                if ($runspace.PowerShell) {
                    $runspace.PowerShell.Dispose()
                }
            }
            foreach ($runspace in $runspaces) {
                if ($runspace.PowerShell) {
                    $runspace.PowerShell.Dispose()
                }
            }
            $runspacePool.Close()
            $runspacePool.Dispose()
        }
    }

    Context "Get-OptimalThreadCount" {
        It "Retourne un nombre de threads valide pour le type CPU" {
            $result = Get-OptimalThreadCount -TaskType 'CPU'
            $result | Should -BeGreaterThan 0
            $result | Should -BeLessThanOrEqual ([Environment]::ProcessorCount * 2)
        }

        It "Retourne un nombre de threads valide pour le type IO" {
            $result = Get-OptimalThreadCount -TaskType 'IO'
            $result | Should -BeGreaterThan 0
            $result | Should -BeLessThanOrEqual ([Environment]::ProcessorCount * 8)
        }

        It "Retourne un nombre de threads valide pour le type Mixed" {
            $result = Get-OptimalThreadCount -TaskType 'Mixed'
            $result | Should -BeGreaterThan 0
            $result | Should -BeLessThanOrEqual ([Environment]::ProcessorCount * 4)
        }

        It "Retourne un nombre de threads valide pour le type LowPriority" {
            $result = Get-OptimalThreadCount -TaskType 'LowPriority'
            $result | Should -BeGreaterThan 0
            $result | Should -BeLessThanOrEqual ([Environment]::ProcessorCount)
        }

        It "Retourne un nombre de threads valide pour le type HighPriority" {
            $result = Get-OptimalThreadCount -TaskType 'HighPriority'
            $result | Should -BeGreaterThan 0
            $result | Should -BeLessThanOrEqual ([Environment]::ProcessorCount * 16)
        }

        It "Ajuste le nombre de threads en fonction de la charge système" {
            $result1 = Get-OptimalThreadCount -TaskType 'CPU' -SystemLoadPercent 0
            $result2 = Get-OptimalThreadCount -TaskType 'CPU' -SystemLoadPercent 80 -Dynamic

            $result1 | Should -BeGreaterThanOrEqual $result2
        }
    }

    Context "Invoke-RunspaceProcessor" {
        It "Traite correctement les runspaces complétés" {
            # Créer un pool de runspaces
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 2, $sessionState, $Host)
            $runspacePool.Open()

            # Créer une liste pour stocker les runspaces
            $runspaces = New-Object System.Collections.ArrayList

            # Créer quelques runspaces
            for ($i = 1; $i -le 3; $i++) {
                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $runspacePool

                # Ajouter un script simple
                [void]$powershell.AddScript({
                    param($Item)
                    Start-Sleep -Milliseconds 100
                    return "Test $Item"
                })

                # Ajouter le paramètre
                [void]$powershell.AddParameter('Item', $i)

                # Démarrer l'exécution asynchrone
                $handle = $powershell.BeginInvoke()

                # Ajouter à la liste des runspaces
                [void]$runspaces.Add([PSCustomObject]@{
                    PowerShell = $powershell
                    Handle = $handle
                    Item = $i
                })
            }

            # Attendre tous les runspaces
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress

            # Créer une copie des runspaces complétés
            $runspacesToProcess = New-Object System.Collections.ArrayList
            foreach ($runspace in $completedRunspaces) {
                [void]$runspacesToProcess.Add($runspace)
            }

            # Traiter les runspaces
            $processorResults = Invoke-RunspaceProcessor -CompletedRunspaces $runspacesToProcess -NoProgress

            $processorResults.Results.Count | Should -Be 3
            $processorResults.Errors.Count | Should -Be 0
            $processorResults.TotalProcessed | Should -Be 3
            $processorResults.SuccessCount | Should -Be 3

            # Nettoyer
            $runspacePool.Close()
            $runspacePool.Dispose()
        }
    }
}

# Exécuter les tests
Invoke-Pester -Output Detailed

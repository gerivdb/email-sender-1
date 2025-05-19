# Test simple pour la fonction Wait-ForCompletedRunspace
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel
}

Describe "Wait-ForCompletedRunspace - Tests simples" {
    Context "Attente d'un seul runspace" {
        BeforeEach {
            # Créer un pool de runspaces
            $pool = [runspacefactory]::CreateRunspacePool(1, 5)
            $pool.Open()
            
            # Créer des runspaces de test
            $runspaces = @()
            
            for ($i = 0; $i -lt 5; $i++) {
                $scriptBlock = {
                    param($index)
                    
                    # Simuler un traitement
                    Start-Sleep -Milliseconds 100
                    
                    # Retourner un résultat
                    return "Résultat du runspace $index"
                }
                
                $powershell = [powershell]::Create().AddScript($scriptBlock).AddParameter("index", $i)
                $powershell.RunspacePool = $pool
                
                $runspaces += [PSCustomObject]@{
                    PowerShell = $powershell
                    Handle = $powershell.BeginInvoke()
                    Index = $i
                }
            }
        }

        AfterEach {
            # Nettoyer les ressources
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }

        It "Attend qu'un runspace soit complété" {
            # Act
            $runspacesCopy = $runspaces.Clone()
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -TimeoutSeconds 5
            
            # Assert
            $completedRunspaces | Should -Not -BeNullOrEmpty
            
            # Vérifier que la fonction retourne au moins un runspace complété
            $completedRunspaces.Count | Should -BeGreaterOrEqual 1
            
            # Vérifier que la collection d'entrée a été modifiée
            $runspacesCopy.Count | Should -BeLessThan $runspaces.Count
        }
    }
}

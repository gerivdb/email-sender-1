# Tests pour la détection de deadlock dans Wait-ForCompletedRunspace

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

Describe "Wait-ForCompletedRunspace - Détection de deadlock" {
    BeforeAll {
        # Fonction utilitaire pour créer des runspaces qui simulent un deadlock
        function New-DeadlockRunspaces {
            param (
                [int]$Count = 4,
                [int]$BlockedCount = 2
            )
            
            # Créer un pool de runspaces
            $pool = [runspacefactory]::CreateRunspacePool(1, $Count)
            $pool.Open()
            
            $runspaces = [System.Collections.Generic.List[PSObject]]::new()
            
            # Créer des runspaces normaux
            for ($i = 0; $i -lt ($Count - $BlockedCount); $i++) {
                $ps = [powershell]::Create()
                $ps.RunspacePool = $pool
                
                [void]$ps.AddScript({
                    param($id)
                    
                    # Simuler un traitement normal
                    Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200)
                    
                    return "Résultat du runspace $id"
                }).AddParameter("id", $i)
                
                $handle = $ps.BeginInvoke()
                
                $runspaces.Add([PSCustomObject]@{
                    PowerShell = $ps
                    Handle = $handle
                    RunspaceId = $i
                    Pool = $pool
                })
            }
            
            # Créer des runspaces qui simulent un deadlock
            for ($i = ($Count - $BlockedCount); $i -lt $Count; $i++) {
                $ps = [powershell]::Create()
                $ps.RunspacePool = $pool
                
                [void]$ps.AddScript({
                    param($id)
                    
                    # Simuler un traitement initial
                    Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 100)
                    
                    # Simuler un deadlock
                    $resource1 = [System.Object]::new()
                    $resource2 = [System.Object]::new()
                    
                    # Créer une situation où le runspace attend indéfiniment
                    while ($true) {
                        Start-Sleep -Milliseconds 100
                    }
                    
                    return "Ce code ne sera jamais atteint"
                }).AddParameter("id", $i)
                
                $handle = $ps.BeginInvoke()
                
                $runspaces.Add([PSCustomObject]@{
                    PowerShell = $ps
                    Handle = $handle
                    RunspaceId = $i
                    Pool = $pool
                })
            }
            
            return $runspaces
        }
    }
    
    Context "Avec détection de deadlock activée" {
        BeforeEach {
            # Créer des runspaces qui simulent un deadlock
            $script:runspaces = New-DeadlockRunspaces -Count 6 -BlockedCount 3
        }
        
        AfterEach {
            # Nettoyer les ressources
            foreach ($runspace in $script:runspaces) {
                if ($null -ne $runspace.PowerShell) {
                    try { $runspace.PowerShell.Stop() } catch {}
                    try { $runspace.PowerShell.Dispose() } catch {}
                }
            }
            
            if ($null -ne $script:runspaces[0].Pool) {
                try { $script:runspaces[0].Pool.Close() } catch {}
                try { $script:runspaces[0].Pool.Dispose() } catch {}
            }
        }
        
        It "Détecte correctement les deadlocks" {
            # Créer une copie de la liste des runspaces
            $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new($script:runspaces)
            
            # Attendre avec détection de deadlock activée
            $result = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -DeadlockDetectionSeconds 3 -NoProgress
            
            # Vérifier que la fonction a détecté un deadlock
            $result.DeadlockDetected | Should -BeTrue
            
            # Vérifier que des runspaces ont été arrêtés
            $result.StoppedRunspaces.Count | Should -BeGreaterThan 0
            
            # Vérifier que les runspaces arrêtés ont le statut "Deadlocked"
            $result.StoppedRunspaces | Where-Object { $_.Status -eq "Deadlocked" } | Should -Not -BeNullOrEmpty
        }
        
        It "Fournit une analyse détaillée des deadlocks" {
            # Créer une copie de la liste des runspaces
            $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new($script:runspaces)
            
            # Attendre avec détection de deadlock activée
            $result = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -DeadlockDetectionSeconds 3 -NoProgress
            
            # Vérifier que l'analyse des deadlocks est disponible
            $result.DeadlockAnalysis | Should -Not -BeNullOrEmpty
            
            # Vérifier les propriétés de l'analyse
            $result.DeadlockAnalysis.DetectionThreshold | Should -Be 3
            $result.DeadlockAnalysis.StoppedCount | Should -BeGreaterThan 0
            $result.DeadlockAnalysis.DeadlockedRunspaces | Should -Not -BeNullOrEmpty
            
            # Vérifier que la méthode GetDeadlockReport fonctionne
            $report = $result.GetDeadlockReport()
            $report | Should -Not -BeNullOrEmpty
            $report | Should -Match "Rapport de deadlock"
        }
    }
    
    Context "Avec libération automatique des ressources" {
        BeforeEach {
            # Créer des runspaces qui simulent un deadlock
            $script:runspaces = New-DeadlockRunspaces -Count 4 -BlockedCount 2
        }
        
        AfterEach {
            # Nettoyer les ressources
            foreach ($runspace in $script:runspaces) {
                if ($null -ne $runspace.PowerShell) {
                    try { $runspace.PowerShell.Stop() } catch {}
                    try { $runspace.PowerShell.Dispose() } catch {}
                }
            }
            
            if ($null -ne $script:runspaces[0].Pool) {
                try { $script:runspaces[0].Pool.Close() } catch {}
                try { $script:runspaces[0].Pool.Dispose() } catch {}
            }
        }
        
        It "Libère correctement les ressources des runspaces en deadlock" {
            # Créer une copie de la liste des runspaces
            $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new($script:runspaces)
            
            # Attendre avec détection de deadlock activée
            $result = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -DeadlockDetectionSeconds 3 -NoProgress
            
            # Vérifier que la fonction a détecté un deadlock
            $result.DeadlockDetected | Should -BeTrue
            
            # Vérifier que les runspaces en deadlock ont été arrêtés
            $deadlockedRunspaces = $result.StoppedRunspaces | Where-Object { $_.Status -eq "Deadlocked" }
            $deadlockedRunspaces | Should -Not -BeNullOrEmpty
            
            # Vérifier que les runspaces normaux ont été complétés
            $result.Results.Count | Should -BeGreaterThan 0
            
            # Vérifier que tous les runspaces ont été traités
            $runspacesCopy.Count | Should -Be 0
        }
    }
}

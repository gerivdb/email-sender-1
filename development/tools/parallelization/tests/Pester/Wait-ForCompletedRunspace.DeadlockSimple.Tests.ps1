# Tests simples pour la détection de deadlock dans Wait-ForCompletedRunspace

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

Describe "Wait-ForCompletedRunspace - Détection de deadlock simple" {
    Context "Vérification des propriétés de deadlock" {
        It "Retourne un objet avec les propriétés DeadlockDetected et DeadlockAnalysis" {
            # Créer un pool de runspaces simple
            $pool = [runspacefactory]::CreateRunspacePool(1, 2)
            $pool.Open()
            
            # Créer un runspace qui s'exécute rapidement
            $ps = [powershell]::Create()
            $ps.RunspacePool = $pool
            [void]$ps.AddScript({
                Start-Sleep -Milliseconds 100
                return "Test réussi"
            })
            
            # Démarrer le runspace
            $handle = $ps.BeginInvoke()
            
            # Créer une liste de runspaces
            $runspaces = [System.Collections.Generic.List[PSObject]]::new()
            $runspaces.Add([PSCustomObject]@{
                PowerShell = $ps
                Handle = $handle
            })
            
            # Attendre que le runspace soit complété
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -NoProgress -DeadlockDetectionSeconds 5
            
            # Vérifier que le résultat contient les propriétés attendues
            $result | Should -Not -BeNullOrEmpty
            $result.PSObject.Properties.Name | Should -Contain 'DeadlockDetected'
            $result.PSObject.Properties.Name | Should -Contain 'DeadlockAnalysis'
            
            # Vérifier que les méthodes sont disponibles
            $result | Get-Member -MemberType ScriptMethod -Name "GetDeadlockAnalysis" | Should -Not -BeNullOrEmpty
            $result | Get-Member -MemberType ScriptMethod -Name "GetDeadlockReport" | Should -Not -BeNullOrEmpty
            
            # Nettoyer
            $pool.Close()
            $pool.Dispose()
        }
        
        It "Retourne DeadlockDetected = false pour un runspace normal" {
            # Créer un pool de runspaces simple
            $pool = [runspacefactory]::CreateRunspacePool(1, 2)
            $pool.Open()
            
            # Créer un runspace qui s'exécute rapidement
            $ps = [powershell]::Create()
            $ps.RunspacePool = $pool
            [void]$ps.AddScript({
                Start-Sleep -Milliseconds 100
                return "Test réussi"
            })
            
            # Démarrer le runspace
            $handle = $ps.BeginInvoke()
            
            # Créer une liste de runspaces
            $runspaces = [System.Collections.Generic.List[PSObject]]::new()
            $runspaces.Add([PSCustomObject]@{
                PowerShell = $ps
                Handle = $handle
            })
            
            # Attendre que le runspace soit complété
            $result = Wait-ForCompletedRunspace -Runspaces $runspaces -NoProgress -DeadlockDetectionSeconds 5
            
            # Vérifier que DeadlockDetected est false
            $result.DeadlockDetected | Should -BeFalse
            
            # Vérifier que DeadlockAnalysis est null
            $result.DeadlockAnalysis | Should -BeNullOrEmpty
            
            # Nettoyer
            $pool.Close()
            $pool.Dispose()
        }
    }
}

# Tests simples pour la fonction Wait-ForCompletedRunspace avec focus sur le mécanisme de timeout interne

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Test simple pour vérifier que les nouveaux paramètres sont bien pris en compte
Describe "Wait-ForCompletedRunspace - Nouveaux paramètres" {
    It "Accepte le paramètre RunspaceTimeoutSeconds" {
        # Vérifier que la fonction accepte le paramètre RunspaceTimeoutSeconds
        (Get-Command Wait-ForCompletedRunspace).Parameters.ContainsKey('RunspaceTimeoutSeconds') | Should -BeTrue
    }

    It "Accepte le paramètre DeadlockDetectionSeconds" {
        # Vérifier que la fonction accepte le paramètre DeadlockDetectionSeconds
        (Get-Command Wait-ForCompletedRunspace).Parameters.ContainsKey('DeadlockDetectionSeconds') | Should -BeTrue
    }
}

# Test de base pour vérifier le comportement avec un runspace simple
Describe "Wait-ForCompletedRunspace - Comportement de base" {
    BeforeEach {
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
        $script:runspaces = [System.Collections.Generic.List[PSObject]]::new()
        $script:runspaces.Add([PSCustomObject]@{
            PowerShell = $ps
            Handle = $handle
        })
    }
    
    AfterEach {
        # Nettoyer les ressources
        if ($pool) {
            $pool.Close()
            $pool.Dispose()
        }
    }
    
    It "Retourne un objet avec les propriétés TimeoutOccurred et DeadlockDetected" {
        # Créer une copie de la liste des runspaces
        $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new($script:runspaces)
        
        # Attendre que le runspace soit complété
        $result = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -NoProgress
        
        # Vérifier que le résultat contient les propriétés attendues
        $result | Should -Not -BeNullOrEmpty
        $result.PSObject.Properties.Name | Should -Contain 'TimeoutOccurred'
        $result.PSObject.Properties.Name | Should -Contain 'DeadlockDetected'
        $result.PSObject.Properties.Name | Should -Contain 'StoppedRunspaces'
        
        # Vérifier que le runspace a été complété normalement
        $result.Results.Count | Should -Be 1
        $result.TimeoutOccurred | Should -BeFalse
        $result.DeadlockDetected | Should -BeFalse
        $result.StoppedRunspaces.Count | Should -Be 0
    }
}

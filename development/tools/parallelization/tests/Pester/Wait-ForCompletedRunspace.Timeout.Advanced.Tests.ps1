# Tests avancés pour la fonction Wait-ForCompletedRunspace avec focus sur le mécanisme de timeout interne

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Test pour vérifier le mécanisme de timeout interne
Describe "Wait-ForCompletedRunspace - Timeout interne" {
    BeforeAll {
        # Fonction utilitaire pour créer un runspace qui se bloque
        function New-BlockingRunspace {
            param (
                [int]$DelayMilliseconds = 100
            )
            
            # Créer un pool de runspaces
            $pool = [runspacefactory]::CreateRunspacePool(1, 1)
            $pool.Open()
            
            # Créer un runspace qui se bloque indéfiniment
            $ps = [powershell]::Create()
            $ps.RunspacePool = $pool
            
            [void]$ps.AddScript({
                param($delay)
                
                # Simuler un traitement initial
                Start-Sleep -Milliseconds $delay
                
                # Puis se bloquer indéfiniment
                while ($true) {
                    Start-Sleep -Milliseconds 100
                }
                
                return "Ce code ne sera jamais atteint"
            }).AddParameter("delay", $DelayMilliseconds)
            
            # Démarrer le runspace
            $handle = $ps.BeginInvoke()
            
            # Créer une liste de runspaces
            $runspaces = [System.Collections.Generic.List[PSObject]]::new()
            $runspaces.Add([PSCustomObject]@{
                PowerShell = $ps
                Handle = $handle
                Pool = $pool
            })
            
            return $runspaces
        }
        
        # Fonction utilitaire pour créer un runspace qui se termine normalement
        function New-NormalRunspace {
            param (
                [int]$DelayMilliseconds = 100
            )
            
            # Créer un pool de runspaces
            $pool = [runspacefactory]::CreateRunspacePool(1, 1)
            $pool.Open()
            
            # Créer un runspace qui se termine normalement
            $ps = [powershell]::Create()
            $ps.RunspacePool = $pool
            
            [void]$ps.AddScript({
                param($delay)
                
                # Simuler un traitement
                Start-Sleep -Milliseconds $delay
                
                return "Traitement terminé avec succès"
            }).AddParameter("delay", $DelayMilliseconds)
            
            # Démarrer le runspace
            $handle = $ps.BeginInvoke()
            
            # Créer une liste de runspaces
            $runspaces = [System.Collections.Generic.List[PSObject]]::new()
            $runspaces.Add([PSCustomObject]@{
                PowerShell = $ps
                Handle = $handle
                Pool = $pool
            })
            
            return $runspaces
        }
    }
    
    Context "Avec un runspace bloqué" {
        BeforeEach {
            # Créer un runspace qui se bloque
            $script:blockingRunspaces = New-BlockingRunspace -DelayMilliseconds 100
        }
        
        AfterEach {
            # Nettoyer les ressources
            foreach ($runspace in $script:blockingRunspaces) {
                if ($null -ne $runspace.PowerShell) {
                    try { $runspace.PowerShell.Stop() } catch {}
                    try { $runspace.PowerShell.Dispose() } catch {}
                }
                
                if ($null -ne $runspace.Pool) {
                    try { $runspace.Pool.Close() } catch {}
                    try { $runspace.Pool.Dispose() } catch {}
                }
            }
        }
        
        It "Détecte et arrête un runspace bloqué avec RunspaceTimeoutSeconds" {
            # Créer une copie de la liste des runspaces
            $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new($script:blockingRunspaces)
            
            # Attendre avec un timeout individuel court
            $result = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -RunspaceTimeoutSeconds 2 -NoProgress
            
            # Vérifier que la fonction a détecté un timeout
            $result.TimeoutOccurred | Should -BeTrue
            
            # Vérifier que le runspace a été arrêté
            $result.StoppedRunspaces.Count | Should -Be 1
        }
    }
    
    Context "Avec un mélange de runspaces normaux et bloqués" {
        BeforeEach {
            # Créer un runspace normal et un runspace bloqué
            $script:normalRunspaces = New-NormalRunspace -DelayMilliseconds 100
            $script:blockingRunspaces = New-BlockingRunspace -DelayMilliseconds 200
            
            # Combiner les deux types de runspaces
            $script:mixedRunspaces = [System.Collections.Generic.List[PSObject]]::new()
            foreach ($runspace in $script:normalRunspaces) {
                $script:mixedRunspaces.Add($runspace)
            }
            foreach ($runspace in $script:blockingRunspaces) {
                $script:mixedRunspaces.Add($runspace)
            }
        }
        
        AfterEach {
            # Nettoyer les ressources
            foreach ($runspace in $script:mixedRunspaces) {
                if ($null -ne $runspace.PowerShell) {
                    try { $runspace.PowerShell.Stop() } catch {}
                    try { $runspace.PowerShell.Dispose() } catch {}
                }
                
                if ($null -ne $runspace.Pool) {
                    try { $runspace.Pool.Close() } catch {}
                    try { $runspace.Pool.Dispose() } catch {}
                }
            }
        }
        
        It "Complète les runspaces normaux et arrête les runspaces bloqués" {
            # Créer une copie de la liste des runspaces
            $runspacesCopy = [System.Collections.Generic.List[PSObject]]::new($script:mixedRunspaces)
            
            # Attendre avec un timeout individuel et WaitForAll
            $result = Wait-ForCompletedRunspace -Runspaces $runspacesCopy -WaitForAll -RunspaceTimeoutSeconds 3 -NoProgress
            
            # Vérifier que la fonction a détecté un timeout
            $result.TimeoutOccurred | Should -BeTrue
            
            # Vérifier que certains runspaces ont été complétés normalement
            $result.Results.Count | Should -Be 1
            
            # Vérifier que certains runspaces ont été arrêtés
            $result.StoppedRunspaces.Count | Should -Be 1
        }
    }
}

# Script de test pour les fonctions auxiliaires du module UnifiedParallel
Write-Host "Test des fonctions auxiliaires du module UnifiedParallel"

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "UnifiedParallel.psm1"
Import-Module $modulePath -Force -Verbose

# Initialiser le module
Initialize-UnifiedParallel -Verbose

# Tester Get-OptimalThreadCount
Write-Host "`nTest de Get-OptimalThreadCount..."
$cpuThreads = Get-OptimalThreadCount -TaskType 'CPU' -Verbose
$ioThreads = Get-OptimalThreadCount -TaskType 'IO' -Verbose
$mixedThreads = Get-OptimalThreadCount -TaskType 'Mixed' -Verbose
$lowPriorityThreads = Get-OptimalThreadCount -TaskType 'LowPriority' -Verbose
$highPriorityThreads = Get-OptimalThreadCount -TaskType 'HighPriority' -Verbose

Write-Host "Nombre optimal de threads pour CPU: $cpuThreads"
Write-Host "Nombre optimal de threads pour IO: $ioThreads"
Write-Host "Nombre optimal de threads pour Mixed: $mixedThreads"
Write-Host "Nombre optimal de threads pour LowPriority: $lowPriorityThreads"
Write-Host "Nombre optimal de threads pour HighPriority: $highPriorityThreads"

# Tester Wait-ForCompletedRunspace
Write-Host "`nTest de Wait-ForCompletedRunspace..."

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
            Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
            return "Traitement de l'élément $Item terminé"
        })

    # Ajouter le paramètre
    [void]$powershell.AddParameter('Item', $i)

    # Démarrer l'exécution asynchrone
    $handle = $powershell.BeginInvoke()

    # Ajouter à la liste des runspaces
    [void]$runspaces.Add([PSCustomObject]@{
            PowerShell = $powershell
            Handle     = $handle
            Item       = $i
        })

    Write-Host "Runspace $i créé et démarré"
}

# Attendre le premier runspace complété
Write-Host "Attente du premier runspace complété..."
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -Verbose
Write-Host "Nombre de runspaces complétés: $($completedRunspaces.Count)"

# Attendre tous les runspaces restants
Write-Host "Attente de tous les runspaces restants..."
$allCompletedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -Verbose
Write-Host "Nombre de runspaces restants complétés: $($allCompletedRunspaces.Count)"

# Tester Invoke-RunspaceProcessor
Write-Host "`nTest de Invoke-RunspaceProcessor..."

# Créer de nouveaux runspaces pour le test
$runspaces = New-Object System.Collections.ArrayList

for ($i = 1; $i -le 3; $i++) {
    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    # Ajouter un script simple
    [void]$powershell.AddScript({
            param($Item)
            Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
            if ($Item -eq 2) {
                throw "Erreur simulée pour l'élément $Item"
            }
            return "Traitement de l'élément $Item terminé"
        })

    # Ajouter le paramètre
    [void]$powershell.AddParameter('Item', $i)

    # Démarrer l'exécution asynchrone
    $handle = $powershell.BeginInvoke()

    # Ajouter à la liste des runspaces
    [void]$runspaces.Add([PSCustomObject]@{
            PowerShell = $powershell
            Handle     = $handle
            Item       = $i
        })

    Write-Host "Runspace $i créé et démarré"
}

# Attendre tous les runspaces
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -Verbose

# Traiter les résultats manuellement
Write-Host "Traitement manuel des runspaces complétés..."
$results = New-Object System.Collections.ArrayList
$errors = New-Object System.Collections.ArrayList

foreach ($runspace in $completedRunspaces) {
    try {
        Write-Host "Traitement du runspace pour l'élément $($runspace.Item)..."

        # Récupérer le résultat
        $result = $runspace.PowerShell.EndInvoke($runspace.Handle)

        # Ajouter le résultat à la liste
        [void]$results.Add($result)

        # Afficher le résultat
        if ($result.Success) {
            Write-Host "Résultat: $($result.Output)" -ForegroundColor Green
        } else {
            Write-Host "Erreur: $($result.Error.Exception.Message)" -ForegroundColor Red
            [void]$errors.Add($result.Error)
        }
    } catch {
        Write-Host "Erreur lors du traitement du runspace: $_" -ForegroundColor Red
        [void]$errors.Add($_)
    } finally {
        # Nettoyer le runspace
        if ($runspace.PowerShell) {
            $runspace.PowerShell.Dispose()
        }
    }
}

Write-Host "Nombre de résultats: $($results.Count)"
Write-Host "Nombre d'erreurs: $($errors.Count)"

# Fermer le pool de runspaces
$runspacePool.Close()
$runspacePool.Dispose()

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "`nTest des fonctions auxiliaires terminé."

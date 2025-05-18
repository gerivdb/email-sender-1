# Script de test final pour le module UnifiedParallel
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$VerbosePreference = 'Continue'

# Définir le chemin absolu du module
$modulePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\tools\parallelization\UnifiedParallel.psm1"

# Vérifier que le module existe
Write-Host "Vérification du chemin du module: $modulePath"
if (Test-Path -Path $modulePath) {
    Write-Host "Le module existe." -ForegroundColor Green
} else {
    Write-Host "Le module n'existe pas!" -ForegroundColor Red
    exit 1
}

# Importer le module
try {
    Write-Host "Importation du module..."
    Import-Module $modulePath -Force -Verbose
    Write-Host "Module importé avec succès." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'importation du module: $_" -ForegroundColor Red
    exit 1
}

# Tester Initialize-UnifiedParallel
try {
    Write-Host "`nTest de Initialize-UnifiedParallel"
    $result = Initialize-UnifiedParallel -Verbose
    Write-Host "Initialize-UnifiedParallel exécuté avec succès." -ForegroundColor Green
    $result | Format-List
} catch {
    Write-Host "Erreur lors de l'exécution de Initialize-UnifiedParallel: $_" -ForegroundColor Red
}

# Tester Get-OptimalThreadCount
try {
    Write-Host "`nTest de Get-OptimalThreadCount"
    $cpuThreads = Get-OptimalThreadCount -TaskType 'CPU' -Verbose
    $ioThreads = Get-OptimalThreadCount -TaskType 'IO' -Verbose
    Write-Host "Get-OptimalThreadCount exécuté avec succès." -ForegroundColor Green
    Write-Host "Threads optimaux pour CPU: $cpuThreads"
    Write-Host "Threads optimaux pour IO: $ioThreads"
} catch {
    Write-Host "Erreur lors de l'exécution de Get-OptimalThreadCount: $_" -ForegroundColor Red
}

# Tester Invoke-UnifiedParallel
try {
    Write-Host "`nTest de Invoke-UnifiedParallel"
    $testData = 1..3
    $results = Invoke-UnifiedParallel -ScriptBlock {
        param($item)
        return "Test $item"
    } -InputObject $testData -MaxThreads 2 -UseRunspacePool -NoProgress -Verbose

    Write-Host "Invoke-UnifiedParallel exécuté avec succès." -ForegroundColor Green
    Write-Host "Nombre de résultats: $($results.Count)"
    foreach ($result in $results) {
        Write-Host "Résultat: $($result.Value)"
    }
} catch {
    Write-Host "Erreur lors de l'exécution de Invoke-UnifiedParallel: $_" -ForegroundColor Red
}

# Tester Wait-ForCompletedRunspace et Invoke-RunspaceProcessor
try {
    Write-Host "`nTest de Wait-ForCompletedRunspace et Invoke-RunspaceProcessor"

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
                Handle     = $handle
                Item       = $i
            })

        Write-Host "Runspace $i créé et démarré"
    }

    # Attendre tous les runspaces
    Write-Host "Attente des runspaces..."
    $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -Verbose

    Write-Host "Nombre de runspaces complétés: $($completedRunspaces.Count)"

    # Créer une copie des runspaces complétés
    $runspacesToProcess = New-Object System.Collections.ArrayList
    foreach ($runspace in $completedRunspaces) {
        [void]$runspacesToProcess.Add($runspace)
    }

    # Traiter les runspaces
    Write-Host "Traitement des runspaces..."
    $processorResults = Invoke-RunspaceProcessor -CompletedRunspaces $runspacesToProcess -NoProgress -Verbose

    Write-Host "Nombre de résultats: $($processorResults.Results.Count)"
    Write-Host "Nombre d'erreurs: $($processorResults.Errors.Count)"
    Write-Host "Nombre total traité: $($processorResults.TotalProcessed)"
    Write-Host "Nombre de succès: $($processorResults.SuccessCount)"

    foreach ($result in $processorResults.Results) {
        Write-Host "Résultat pour l'élément $($result.Item): $($result.Value)"
    }

    # Nettoyer
    $runspacePool.Close()
    $runspacePool.Dispose()
} catch {
    Write-Host "Erreur lors de l'exécution de Wait-ForCompletedRunspace ou Invoke-RunspaceProcessor: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}

# Nettoyer
try {
    Write-Host "`nNettoyage"
    Clear-UnifiedParallel -Verbose
    Write-Host "Clear-UnifiedParallel exécuté avec succès." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'exécution de Clear-UnifiedParallel: $_" -ForegroundColor Red
}

Write-Host "`nTests terminés." -ForegroundColor Cyan

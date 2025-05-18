# Test des optimisations de collections dans Invoke-RunspaceProcessor
# Ce script teste les modifications apportées à la fonction Invoke-RunspaceProcessor
# pour utiliser System.Collections.Concurrent.ConcurrentBag<T> et System.Collections.Generic.List<T>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force -Verbose

# Initialiser le module
Initialize-UnifiedParallel -Verbose

# Créer un pool de runspaces
$sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
$runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
$runspacePool.Open()

Write-Host "Test des optimisations de collections dans Invoke-RunspaceProcessor" -ForegroundColor Cyan

# Test 1: Utilisation de différents types de collections en entrée
Write-Host "`nTest 1: Utilisation de différents types de collections en entrée" -ForegroundColor Yellow

# Créer des runspaces de test
function Create-TestRunspaces {
    param(
        [int]$Count = 3
    )

    $runspaces = New-Object System.Collections.ArrayList

    for ($i = 1; $i -le $Count; $i++) {
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
    }

    # Attendre un peu pour s'assurer que les runspaces ont commencé à s'exécuter
    Start-Sleep -Milliseconds 200

    return $runspaces
}

# Test avec ArrayList
Write-Host "Test avec ArrayList" -ForegroundColor White
$runspaces = Create-TestRunspaces -Count 3
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10
Write-Host "Type de completedRunspaces: $($completedRunspaces.GetType().FullName)"
$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces -NoProgress
Write-Host "Nombre de résultats: $($results.Results.Count)"
Write-Host "Type de results.Results: $($results.Results.GetType().FullName)"
foreach ($result in $results.Results) {
    Write-Host "Résultat: $($result.Value)"
}

# Test avec List<object>
Write-Host "`nTest avec List<object>" -ForegroundColor White
$runspaces = Create-TestRunspaces -Count 3
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10
$listRunspaces = [System.Collections.Generic.List[object]]::new()
foreach ($runspace in $completedRunspaces) {
    $listRunspaces.Add($runspace)
}
Write-Host "Type de listRunspaces: $($listRunspaces.GetType().FullName)"
$results = Invoke-RunspaceProcessor -CompletedRunspaces $listRunspaces -NoProgress
Write-Host "Nombre de résultats: $($results.Results.Count)"
Write-Host "Type de results.Results: $($results.Results.GetType().FullName)"
foreach ($result in $results.Results) {
    Write-Host "Résultat: $($result.Value)"
}

# Test avec ConcurrentBag<object>
Write-Host "`nTest avec ConcurrentBag<object>" -ForegroundColor White
$runspaces = Create-TestRunspaces -Count 3
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10
$bagRunspaces = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
foreach ($runspace in $completedRunspaces) {
    $bagRunspaces.Add($runspace)
}
Write-Host "Type de bagRunspaces: $($bagRunspaces.GetType().FullName)"
$results = Invoke-RunspaceProcessor -CompletedRunspaces $bagRunspaces -NoProgress
Write-Host "Nombre de résultats: $($results.Results.Count)"
Write-Host "Type de results.Results: $($results.Results.GetType().FullName)"
foreach ($result in $results.Results) {
    Write-Host "Résultat: $($result.Value)"
}

# Test avec tableau
Write-Host "`nTest avec tableau" -ForegroundColor White
$runspaces = Create-TestRunspaces -Count 3
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10
$arrayRunspaces = @($completedRunspaces)
Write-Host "Type de arrayRunspaces: $($arrayRunspaces.GetType().FullName)"
$results = Invoke-RunspaceProcessor -CompletedRunspaces $arrayRunspaces -NoProgress
Write-Host "Nombre de résultats: $($results.Results.Count)"
Write-Host "Type de results.Results: $($results.Results.GetType().FullName)"
foreach ($result in $results.Results) {
    Write-Host "Résultat: $($result.Value)"
}

# Test 2: Vérification des performances
Write-Host "`nTest 2: Vérification des performances" -ForegroundColor Yellow

# Créer un grand nombre de runspaces
$largeCount = 100
Write-Host "Création de $largeCount runspaces..." -ForegroundColor White
$runspaces = Create-TestRunspaces -Count $largeCount

# Attendre tous les runspaces
Write-Host "Attente des runspaces..." -ForegroundColor White
$startTime = Get-Date
$completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 10
$waitDuration = (Get-Date) - $startTime
Write-Host "Durée d'attente: $($waitDuration.TotalSeconds) secondes" -ForegroundColor White

# Traiter les runspaces
Write-Host "Traitement des runspaces..." -ForegroundColor White
$startTime = Get-Date
$results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces -NoProgress
$processDuration = (Get-Date) - $startTime
Write-Host "Durée de traitement: $($processDuration.TotalSeconds) secondes" -ForegroundColor White
Write-Host "Nombre de résultats: $($results.Results.Count)" -ForegroundColor White

# Nettoyer
$runspacePool.Close()
$runspacePool.Dispose()

Write-Host "`nTests terminés." -ForegroundColor Green

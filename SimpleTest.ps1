# Script de test simple pour le module UnifiedParallel
Write-Host "Test simple du module UnifiedParallel" -ForegroundColor Cyan

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Write-Host "Chemin du module: $modulePath" -ForegroundColor Yellow

try {
    Import-Module $modulePath -Force -Verbose
    Write-Host "Module importé avec succès" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de l'importation du module: $_" -ForegroundColor Red
    exit 1
}

# Tester Initialize-UnifiedParallel
Write-Host "`nTest de Initialize-UnifiedParallel" -ForegroundColor Yellow
try {
    $result = Initialize-UnifiedParallel -Verbose
    Write-Host "Initialize-UnifiedParallel exécuté avec succès" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de l'exécution de Initialize-UnifiedParallel: $_" -ForegroundColor Red
}

# Tester Invoke-UnifiedParallel
Write-Host "`nTest de Invoke-UnifiedParallel" -ForegroundColor Yellow
try {
    $testData = 1..3
    $results = Invoke-UnifiedParallel -ScriptBlock {
        param($item)
        return "Test $item"
    } -InputObject $testData -MaxThreads 2 -UseRunspacePool -NoProgress -Verbose
    
    Write-Host "Invoke-UnifiedParallel exécuté avec succès" -ForegroundColor Green
    Write-Host "Nombre de résultats: $($results.Count)" -ForegroundColor White
    foreach ($result in $results) {
        Write-Host "Résultat: $($result.Value)" -ForegroundColor White
    }
}
catch {
    Write-Host "Erreur lors de l'exécution de Invoke-UnifiedParallel: $_" -ForegroundColor Red
}

# Tester Get-OptimalThreadCount
Write-Host "`nTest de Get-OptimalThreadCount" -ForegroundColor Yellow
try {
    $threads = Get-OptimalThreadCount -TaskType 'CPU' -Verbose
    Write-Host "Get-OptimalThreadCount exécuté avec succès" -ForegroundColor Green
    Write-Host "Nombre optimal de threads pour CPU: $threads" -ForegroundColor White
}
catch {
    Write-Host "Erreur lors de l'exécution de Get-OptimalThreadCount: $_" -ForegroundColor Red
}

# Tester Wait-ForCompletedRunspace
Write-Host "`nTest de Wait-ForCompletedRunspace" -ForegroundColor Yellow
try {
    # Créer un pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 2, $sessionState, $Host)
    $runspacePool.Open()
    
    # Créer une liste pour stocker les runspaces
    $runspaces = New-Object System.Collections.ArrayList
    
    # Créer un runspace
    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool
    [void]$powershell.AddScript({
        Start-Sleep -Milliseconds 100
        return "Test réussi"
    })
    $handle = $powershell.BeginInvoke()
    [void]$runspaces.Add([PSCustomObject]@{
        PowerShell = $powershell
        Handle = $handle
        Item = 1
    })
    
    # Attendre le runspace
    $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -Verbose
    
    Write-Host "Wait-ForCompletedRunspace exécuté avec succès" -ForegroundColor Green
    Write-Host "Nombre de runspaces complétés: $($completedRunspaces.Count)" -ForegroundColor White
    
    # Nettoyer
    $runspacePool.Close()
    $runspacePool.Dispose()
}
catch {
    Write-Host "Erreur lors de l'exécution de Wait-ForCompletedRunspace: $_" -ForegroundColor Red
}

# Nettoyer
Write-Host "`nNettoyage" -ForegroundColor Yellow
try {
    Clear-UnifiedParallel -Verbose
    Write-Host "Clear-UnifiedParallel exécuté avec succès" -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors de l'exécution de Clear-UnifiedParallel: $_" -ForegroundColor Red
}

Write-Host "`nTest terminé" -ForegroundColor Cyan

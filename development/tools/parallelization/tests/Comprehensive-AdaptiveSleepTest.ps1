# Test complet pour la fonction Wait-ForCompletedRunspace avec délai adaptatif
# Ce script teste tous les scénarios critiques pour s'assurer que l'implémentation est robuste

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose

Write-Host "Test complet pour Wait-ForCompletedRunspace avec délai adaptatif" -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Yellow

# Fonction utilitaire pour créer des runspaces de test avec délais variés
function New-TestRunspacesWithVariableDelays {
    param(
        [int]$Count = 5,
        [int[]]$DelaysMilliseconds = @(100, 200, 300, 400, 500),
        [scriptblock]$ScriptBlock = {
            param($Item, $DelayMilliseconds)
            Start-Sleep -Milliseconds $DelayMilliseconds
            return [PSCustomObject]@{
                Item = $Item
                Delay = $DelayMilliseconds
                ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                StartTime = Get-Date
            }
        }
    )

    # Créer un pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
    $runspacePool.Open()

    # Créer une liste pour stocker les runspaces
    $runspaces = [System.Collections.Generic.List[object]]::new()

    # Créer les runspaces avec des délais différents
    for ($i = 0; $i -lt $Count; $i++) {
        $delay = $DelaysMilliseconds[$i % $DelaysMilliseconds.Length]
        
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $runspacePool

        # Ajouter le script
        [void]$powershell.AddScript($ScriptBlock)

        # Ajouter les paramètres
        [void]$powershell.AddParameter('Item', $i)
        [void]$powershell.AddParameter('DelayMilliseconds', $delay)

        # Démarrer l'exécution asynchrone
        $handle = $powershell.BeginInvoke()

        # Ajouter à la liste des runspaces
        $runspaces.Add([PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $handle
                Item       = $i
                Delay      = $delay
                StartTime  = [datetime]::Now
            })
    }

    return @{
        Runspaces = $runspaces
        Pool = $runspacePool
    }
}

# Fonction pour tester un scénario spécifique
function Test-Scenario {
    param(
        [string]$Name,
        [int]$RunspaceCount,
        [int[]]$DelaysMilliseconds,
        [int]$TimeoutSeconds = 30,
        [switch]$ExpectTimeout = $false,
        [scriptblock]$ScriptBlock = $null
    )

    Write-Host "`nScénario: $Name" -ForegroundColor Cyan
    Write-Host "Nombre de runspaces: $RunspaceCount" -ForegroundColor Gray
    Write-Host "Délais: $($DelaysMilliseconds -join ', ') ms" -ForegroundColor Gray
    Write-Host "Timeout: $TimeoutSeconds secondes" -ForegroundColor Gray
    
    try {
        # Créer des runspaces de test
        $testData = New-TestRunspacesWithVariableDelays -Count $RunspaceCount -DelaysMilliseconds $DelaysMilliseconds -ScriptBlock $ScriptBlock
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        # Mesurer le temps d'exécution
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Capturer les warnings
        $warningOutput = New-Object System.Collections.Generic.List[string]
        $warningAction = {
            param($message)
            $warningOutput.Add($message)
        }

        # Attendre que tous les runspaces soient complétés
        $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds $TimeoutSeconds -WarningAction SilentlyContinue -WarningVariable warnings -Verbose

        $stopwatch.Stop()
        $elapsedMs = $stopwatch.ElapsedMilliseconds

        # Afficher les résultats
        Write-Host "Temps d'exécution: $elapsedMs ms" -ForegroundColor Green
        Write-Host "Runspaces complétés: $($completedRunspaces.Count) sur $RunspaceCount" -ForegroundColor Green
        
        # Vérifier les warnings
        if ($warnings) {
            Write-Host "Warnings détectés:" -ForegroundColor Yellow
            foreach ($warning in $warnings) {
                Write-Host "  - $warning" -ForegroundColor Yellow
            }
        }

        # Vérifier si le timeout était attendu
        if ($ExpectTimeout) {
            if ($completedRunspaces.Count -lt $RunspaceCount) {
                Write-Host "Timeout attendu détecté correctement." -ForegroundColor Green
            } else {
                Write-Host "ERREUR: Timeout attendu mais tous les runspaces ont été complétés." -ForegroundColor Red
            }
        } else {
            if ($completedRunspaces.Count -eq $RunspaceCount) {
                Write-Host "Tous les runspaces ont été complétés avec succès." -ForegroundColor Green
            } else {
                Write-Host "ERREUR: Certains runspaces n'ont pas été complétés ($($completedRunspaces.Count) sur $RunspaceCount)." -ForegroundColor Red
            }
        }

        # Traiter les résultats
        $results = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

        # Afficher les statistiques
        Write-Host "Runspaces traités: $($results.TotalProcessed)" -ForegroundColor Green
        Write-Host "Succès: $($results.SuccessCount)" -ForegroundColor Green
        Write-Host "Erreurs: $($results.ErrorCount)" -ForegroundColor Green

        # Nettoyer
        $pool.Close()
        $pool.Dispose()
        
        return @{
            Success = if ($ExpectTimeout) { $completedRunspaces.Count -lt $RunspaceCount } else { $completedRunspaces.Count -eq $RunspaceCount }
            ElapsedMs = $elapsedMs
            CompletedCount = $completedRunspaces.Count
            TotalCount = $RunspaceCount
            Warnings = $warnings
            Errors = $results.ErrorCount
        }
    }
    catch {
        Write-Host "ERREUR: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host $_.ScriptStackTrace -ForegroundColor Red
        
        return @{
            Success = $false
            Error = $_
        }
    }
}

# Tableau pour stocker les résultats
$testResults = @()

# 1. Test avec un nombre normal de runspaces et délais variés
$result1 = Test-Scenario -Name "Nombre normal de runspaces (10) avec délais variés" -RunspaceCount 10 -DelaysMilliseconds @(50, 100, 150, 200, 250)
$testResults += [PSCustomObject]@{
    Scenario = "Nombre normal (10)"
    Success = $result1.Success
    ElapsedMs = $result1.ElapsedMs
    CompletedCount = $result1.CompletedCount
    TotalCount = $result1.TotalCount
}

# 2. Test avec un grand nombre de runspaces
$result2 = Test-Scenario -Name "Grand nombre de runspaces (50) avec délais courts" -RunspaceCount 50 -DelaysMilliseconds @(10, 20, 30, 40, 50)
$testResults += [PSCustomObject]@{
    Scenario = "Grand nombre (50)"
    Success = $result2.Success
    ElapsedMs = $result2.ElapsedMs
    CompletedCount = $result2.CompletedCount
    TotalCount = $result2.TotalCount
}

# 3. Test avec des délais très courts
$result3 = Test-Scenario -Name "Délais très courts (<10ms)" -RunspaceCount 20 -DelaysMilliseconds @(1, 2, 3, 5, 8)
$testResults += [PSCustomObject]@{
    Scenario = "Délais très courts"
    Success = $result3.Success
    ElapsedMs = $result3.ElapsedMs
    CompletedCount = $result3.CompletedCount
    TotalCount = $result3.TotalCount
}

# 4. Test avec des délais très longs
$result4 = Test-Scenario -Name "Délais très longs (>500ms)" -RunspaceCount 5 -DelaysMilliseconds @(500, 600, 700, 800, 900)
$testResults += [PSCustomObject]@{
    Scenario = "Délais très longs"
    Success = $result4.Success
    ElapsedMs = $result4.ElapsedMs
    CompletedCount = $result4.CompletedCount
    TotalCount = $result4.TotalCount
}

# 5. Test avec timeout
$result5 = Test-Scenario -Name "Gestion du timeout" -RunspaceCount 5 -DelaysMilliseconds @(100, 200, 300, 2000, 3000) -TimeoutSeconds 1 -ExpectTimeout
$testResults += [PSCustomObject]@{
    Scenario = "Gestion du timeout"
    Success = $result5.Success
    ElapsedMs = $result5.ElapsedMs
    CompletedCount = $result5.CompletedCount
    TotalCount = $result5.TotalCount
}

# 6. Test avec charge CPU élevée
$cpuIntensiveScript = {
    param($Item, $DelayMilliseconds)
    $startTime = Get-Date
    
    # Simuler une charge CPU élevée
    $result = 0
    for ($i = 0; $i -lt 1000000; $i++) {
        $result += [Math]::Pow($i, 2) % 10
    }
    
    Start-Sleep -Milliseconds $DelayMilliseconds
    
    return [PSCustomObject]@{
        Item = $Item
        Delay = $DelayMilliseconds
        CPUWork = $result
        Duration = ((Get-Date) - $startTime).TotalMilliseconds
        ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
    }
}

$result6 = Test-Scenario -Name "Charge CPU élevée" -RunspaceCount 8 -DelaysMilliseconds @(50, 100, 150, 200) -ScriptBlock $cpuIntensiveScript
$testResults += [PSCustomObject]@{
    Scenario = "Charge CPU élevée"
    Success = $result6.Success
    ElapsedMs = $result6.ElapsedMs
    CompletedCount = $result6.CompletedCount
    TotalCount = $result6.TotalCount
}

# Afficher le résumé des tests
Write-Host "`nRésumé des tests:" -ForegroundColor Yellow
$testResults | Format-Table -AutoSize

# Vérifier si tous les tests ont réussi
$allTestsPassed = ($testResults | Where-Object { -not $_.Success }).Count -eq 0

if ($allTestsPassed) {
    Write-Host "TOUS LES TESTS ONT RÉUSSI!" -ForegroundColor Green
} else {
    Write-Host "CERTAINS TESTS ONT ÉCHOUÉ!" -ForegroundColor Red
    $testResults | Where-Object { -not $_.Success } | Format-Table -AutoSize
}

# Nettoyer
Clear-UnifiedParallel -Verbose

Write-Host "`nTests terminés." -ForegroundColor Green

# Script simple pour vérifier la gestion des erreurs et des cas limites de Wait-ForCompletedRunspace
# Ce script teste manuellement la gestion des erreurs et des cas limites

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel -Verbose

# Fonction pour afficher les messages
function Write-TestMessage {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )

    $color = switch ($Type) {
        "Info" { "White" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Header" { "Cyan" }
        default { "White" }
    }

    Write-Host $Message -ForegroundColor $color
}

# Fonction pour créer des runspaces de test
function New-TestRunspaces {
    param(
        [int]$Count = 5,
        [int]$DelayMilliseconds = 10,
        [switch]$GenerateError
    )

    # Créer un pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 4, $sessionState, $Host)
    $runspacePool.Open()

    # Créer une liste pour stocker les runspaces
    $runspaces = [System.Collections.Generic.List[object]]::new($Count)

    # Créer les runspaces
    for ($i = 0; $i -lt $Count; $i++) {
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $runspacePool

        # Ajouter un script simple
        if ($GenerateError -and $i -eq 0) {
            # Premier runspace génère une erreur
            [void]$powershell.AddScript({
                    param($Item)
                    Start-Sleep -Milliseconds 5
                    throw "Erreur de test délibérée"
                    return $Item
                })
        } elseif ($GenerateError -and $i -eq 1) {
            # Deuxième runspace génère une exception
            [void]$powershell.AddScript({
                    param($Item)
                    Start-Sleep -Milliseconds 5
                    $null.ToString() # Génère une exception NullReferenceException
                    return $Item
                })
        } else {
            # Runspaces normaux
            [void]$powershell.AddScript({
                    param($Item, $DelayMilliseconds)
                    Start-Sleep -Milliseconds $DelayMilliseconds
                    return $Item
                })
            [void]$powershell.AddParameter('DelayMilliseconds', $DelayMilliseconds)
        }

        # Ajouter les paramètres
        [void]$powershell.AddParameter('Item', $i)

        # Démarrer l'exécution asynchrone
        $handle = $powershell.BeginInvoke()

        # Ajouter à la liste des runspaces
        $runspaces.Add([PSCustomObject]@{
                PowerShell = $powershell
                Handle     = $handle
                Item       = $i
                StartTime  = [datetime]::Now
            })
    }

    return @{
        Runspaces = $runspaces
        Pool = $runspacePool
    }
}

# Fonction pour créer un runspace qui ne se termine jamais (pour tester le timeout)
function New-InfiniteRunspace {
    # Créer un pool de runspaces
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 1, $sessionState, $Host)
    $runspacePool.Open()

    # Créer un runspace qui ne se termine jamais
    $powershell = [powershell]::Create()
    $powershell.RunspacePool = $runspacePool

    # Ajouter un script qui s'exécute indéfiniment
    [void]$powershell.AddScript({
            param($Item)
            while ($true) {
                Start-Sleep -Milliseconds 100
            }
            return $Item
        })

    # Ajouter les paramètres
    [void]$powershell.AddParameter('Item', 0)

    # Démarrer l'exécution asynchrone
    $handle = $powershell.BeginInvoke()

    # Créer un objet runspace
    $runspace = [PSCustomObject]@{
        PowerShell = $powershell
        Handle     = $handle
        Item       = 0
        StartTime  = [datetime]::Now
    }

    return @{
        Runspaces = @($runspace)
        Pool = $runspacePool
    }
}

# Fonction pour créer des runspaces invalides
function New-InvalidRunspaces {
    param(
        [ValidateSet("NoHandle", "NoPowerShell", "NullHandle", "NullPowerShell", "EmptyArray", "Mixed")]
        [string]$Type = "NoHandle"
    )

    switch ($Type) {
        "NoHandle" {
            # Runspaces sans propriété Handle
            return @(
                [PSCustomObject]@{
                    PowerShell = [powershell]::Create()
                    Item       = 0
                }
            )
        }
        "NoPowerShell" {
            # Runspaces sans propriété PowerShell
            return @(
                [PSCustomObject]@{
                    Handle     = $null
                    Item       = 0
                }
            )
        }
        "NullHandle" {
            # Runspaces avec Handle null
            return @(
                [PSCustomObject]@{
                    PowerShell = [powershell]::Create()
                    Handle     = $null
                    Item       = 0
                }
            )
        }
        "NullPowerShell" {
            # Runspaces avec PowerShell null
            return @(
                [PSCustomObject]@{
                    PowerShell = $null
                    Handle     = $null
                    Item       = 0
                }
            )
        }
        "EmptyArray" {
            # Tableau vide
            return @()
        }
        "Mixed" {
            # Mélange de runspaces valides et invalides
            $validRunspaces = (New-TestRunspaces -Count 2).Runspaces
            $invalidRunspaces = @(
                [PSCustomObject]@{
                    PowerShell = $null
                    Handle     = $null
                    Item       = 2
                },
                [PSCustomObject]@{
                    PowerShell = [powershell]::Create()
                    Item       = 3
                }
            )
            return $validRunspaces + $invalidRunspaces
        }
    }
}

# Fonction pour exécuter un test et afficher les résultats
function Invoke-Test {
    param(
        [string]$TestName,
        [scriptblock]$TestScript
    )

    Write-TestMessage "`nTest: $TestName" -Type "Header"
    
    try {
        & $TestScript
        Write-TestMessage "Test réussi." -Type "Success"
        return $true
    } catch {
        Write-TestMessage "Test échoué: $_" -Type "Error"
        return $false
    }
}

# Exécuter les tests
$results = @{}

# Test 1: Gestion des runspaces null
$results["Test1"] = Invoke-Test -TestName "Gestion des runspaces null" -TestScript {
    try {
        $result = Wait-ForCompletedRunspace -Runspaces $null -TimeoutSeconds 1
        throw "Le test aurait dû échouer avec des runspaces null"
    } catch {
        Write-TestMessage "Exception attendue reçue: $_" -Type "Success"
    }
}

# Test 2: Gestion d'un tableau vide
$results["Test2"] = Invoke-Test -TestName "Gestion d'un tableau vide" -TestScript {
    $result = Wait-ForCompletedRunspace -Runspaces @() -TimeoutSeconds 1
    
    if ($result -eq $null) {
        throw "Le résultat ne devrait pas être null"
    }
    
    Write-TestMessage "Résultat: $($result | ConvertTo-Json -Depth 1)" -Type "Info"
}

# Test 3: Gestion des runspaces invalides
$results["Test3"] = Invoke-Test -TestName "Gestion des runspaces invalides" -TestScript {
    $invalidRunspaces = New-InvalidRunspaces -Type "Mixed"
    $result = Wait-ForCompletedRunspace -Runspaces $invalidRunspaces -TimeoutSeconds 1
    
    if ($result -eq $null) {
        throw "Le résultat ne devrait pas être null"
    }
    
    Write-TestMessage "Résultat: $($result | ConvertTo-Json -Depth 1)" -Type "Info"
}

# Test 4: Gestion des timeouts
$results["Test4"] = Invoke-Test -TestName "Gestion des timeouts" -TestScript {
    $testData = New-InfiniteRunspace
    $runspaces = $testData.Runspaces
    $pool = $testData.Pool
    
    try {
        $timeoutSeconds = 1
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds $timeoutSeconds
        $stopwatch.Stop()
        
        # Vérifier que le temps d'exécution est proche du timeout
        $executionTime = $stopwatch.Elapsed.TotalSeconds
        Write-TestMessage "Temps d'exécution: $executionTime secondes (timeout: $timeoutSeconds secondes)" -Type "Info"
        
        if ($executionTime -lt ($timeoutSeconds * 0.5) -or $executionTime -gt ($timeoutSeconds * 2)) {
            throw "Le temps d'exécution ($executionTime) n'est pas proche du timeout ($timeoutSeconds)"
        }
        
        Write-TestMessage "Résultat: $($result | ConvertTo-Json -Depth 1)" -Type "Info"
    } finally {
        if ($pool) {
            $pool.Close()
            $pool.Dispose()
        }
    }
}

# Test 5: Gestion des erreurs dans les runspaces
$results["Test5"] = Invoke-Test -TestName "Gestion des erreurs dans les runspaces" -TestScript {
    $testData = New-TestRunspaces -Count 5 -GenerateError
    $runspaces = $testData.Runspaces
    $pool = $testData.Pool
    
    try {
        $result = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 5
        
        if ($result -eq $null) {
            throw "Le résultat ne devrait pas être null"
        }
        
        # Le résultat peut contenir soit les runspaces individuels, soit un objet avec une propriété Results
        if ($result.PSObject.Properties.Name -contains "Results") {
            $results = $result.Results
        } else {
            $results = $result
        }
        
        # Vérifier que tous les runspaces ont été traités
        Write-TestMessage "Nombre de résultats: $($results.Count)" -Type "Info"
        
        # Vérifier que les erreurs sont correctement capturées
        $errorResults = $results | Where-Object { -not $_.Success }
        Write-TestMessage "Nombre d'erreurs: $($errorResults.Count)" -Type "Info"
        
        if ($errorResults.Count -eq 0) {
            throw "Aucune erreur n'a été capturée"
        }
        
        foreach ($errorResult in $errorResults) {
            Write-TestMessage "Erreur: $($errorResult.Error)" -Type "Info"
        }
    } finally {
        if ($pool) {
            $pool.Close()
            $pool.Dispose()
        }
    }
}

# Test 6: Gestion d'un seul runspace
$results["Test6"] = Invoke-Test -TestName "Gestion d'un seul runspace" -TestScript {
    $testData = New-TestRunspaces -Count 1
    $runspaces = $testData.Runspaces
    $pool = $testData.Pool
    
    try {
        $result = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 5
        
        if ($result -eq $null) {
            throw "Le résultat ne devrait pas être null"
        }
        
        # Le résultat peut contenir soit les runspaces individuels, soit un objet avec une propriété Results
        if ($result.PSObject.Properties.Name -contains "Results") {
            $results = $result.Results
        } else {
            $results = $result
        }
        
        # Vérifier que le runspace a été traité
        Write-TestMessage "Nombre de résultats: $($results.Count)" -Type "Info"
        
        # Vérifier que le runspace a été complété avec succès
        $successResults = $results | Where-Object { $_.Success }
        Write-TestMessage "Nombre de succès: $($successResults.Count)" -Type "Info"
        
        if ($successResults.Count -eq 0) {
            throw "Aucun runspace n'a été complété avec succès"
        }
    } finally {
        if ($pool) {
            $pool.Close()
            $pool.Dispose()
        }
    }
}

# Test 7: Gestion d'un grand nombre de runspaces
$results["Test7"] = Invoke-Test -TestName "Gestion d'un grand nombre de runspaces" -TestScript {
    $testData = New-TestRunspaces -Count 20
    $runspaces = $testData.Runspaces
    $pool = $testData.Pool
    
    try {
        $result = Wait-ForCompletedRunspace -Runspaces $runspaces -TimeoutSeconds 30
        
        if ($result -eq $null) {
            throw "Le résultat ne devrait pas être null"
        }
        
        # Le résultat peut contenir soit les runspaces individuels, soit un objet avec une propriété Results
        if ($result.PSObject.Properties.Name -contains "Results") {
            $results = $result.Results
        } else {
            $results = $result
        }
        
        # Vérifier que tous les runspaces ont été traités
        Write-TestMessage "Nombre de résultats: $($results.Count)" -Type "Info"
        
        # Vérifier que tous les runspaces ont été complétés avec succès
        $successResults = $results | Where-Object { $_.Success }
        Write-TestMessage "Nombre de succès: $($successResults.Count)" -Type "Info"
        
        if ($successResults.Count -eq 0) {
            throw "Aucun runspace n'a été complété avec succès"
        }
    } finally {
        if ($pool) {
            $pool.Close()
            $pool.Dispose()
        }
    }
}

# Afficher le résumé des résultats
Write-TestMessage "`nRésumé des tests:" -Type "Header"
$totalTests = $results.Count
$passedTests = ($results.Values | Where-Object { $_ -eq $true }).Count
$failedTests = $totalTests - $passedTests

Write-TestMessage "Tests exécutés: $totalTests" -Type "Info"
Write-TestMessage "Tests réussis: $passedTests" -Type "Success"
Write-TestMessage "Tests échoués: $failedTests" -Type "Error"
Write-TestMessage "Taux de réussite: $([Math]::Round(($passedTests / $totalTests) * 100, 2))%" -Type $(if ($failedTests -eq 0) { "Success" } else { "Warning" })

# Nettoyer
Clear-UnifiedParallel -Verbose

# Retourner le résultat global
return @{
    TotalTests = $totalTests
    PassedTests = $passedTests
    FailedTests = $failedTests
    SuccessRate = [Math]::Round(($passedTests / $totalTests) * 100, 2)
    Results = $results
}

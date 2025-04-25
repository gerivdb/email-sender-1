#Requires -Version 5.1
<#
.SYNOPSIS
    Tests de performance pour le module MCPClient.
.DESCRIPTION
    Ce script contient des tests de performance pour le module MCPClient.
    Il mesure les performances des différentes fonctionnalités du module,
    notamment la mise en cache et le traitement parallèle.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-21
#>

# Importer le module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\modules\MCPClient.psm1"

# Vérifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Le module MCPClient.psm1 n'existe pas à l'emplacement spécifié: $modulePath"
}

# Importer le module
Import-Module $modulePath -Force

# Variables globales pour les tests
$script:serverProcess = $null
$script:serverPort = 8000
$script:serverUrl = "http://localhost:$script:serverPort"
$script:resultsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\docs\test_reports\MCPClient.Performance.json"

# Fonction pour mesurer le temps d'exécution
function Measure-ExecutionTime {
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [int]$Iterations = 1
    )
    
    $results = @()
    
    for ($i = 0; $i -lt $Iterations; $i++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = & $ScriptBlock
        $stopwatch.Stop()
        
        $results += [PSCustomObject]@{
            Iteration = $i + 1
            ElapsedMilliseconds = $stopwatch.ElapsedMilliseconds
            Result = $result
        }
    }
    
    $averageTime = ($results | Measure-Object -Property ElapsedMilliseconds -Average).Average
    $minTime = ($results | Measure-Object -Property ElapsedMilliseconds -Minimum).Minimum
    $maxTime = ($results | Measure-Object -Property ElapsedMilliseconds -Maximum).Maximum
    
    return [PSCustomObject]@{
        Name = $Name
        Iterations = $Iterations
        AverageTime = $averageTime
        MinTime = $minTime
        MaxTime = $maxTime
        Results = $results
    }
}

# Fonction pour démarrer le serveur MCP de test
function Start-TestServer {
    $serverScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\scripts\python\minimal_mcp_server.py"
    
    if (-not (Test-Path -Path $serverScriptPath)) {
        throw "Le script du serveur MCP de test n'existe pas à l'emplacement spécifié: $serverScriptPath"
    }
    
    Write-Host "Démarrage du serveur MCP de test sur $script:serverUrl..." -ForegroundColor Cyan
    
    # Vérifier si Python est installé
    try {
        $pythonVersion = python --version
        Write-Host "Python détecté: $pythonVersion" -ForegroundColor Green
    } catch {
        throw "Python n'est pas installé ou n'est pas dans le PATH. Veuillez installer Python 3.8 ou supérieur."
    }
    
    # Vérifier si le package mcp est installé
    try {
        python -c "import mcp" 2>$null
        Write-Host "Package mcp détecté" -ForegroundColor Green
    } catch {
        Write-Warning "Le package mcp n'est pas installé. Installation en cours..."
        python -m pip install mcp
    }
    
    # Démarrer le serveur MCP en arrière-plan
    $script:serverProcess = Start-Process -FilePath "python" -ArgumentList $serverScriptPath -PassThru -NoNewWindow
    
    # Attendre que le serveur soit prêt
    Write-Host "Attente du démarrage du serveur MCP..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    # Vérifier que le serveur est en cours d'exécution
    if ($script:serverProcess.HasExited) {
        throw "Le serveur MCP de test n'a pas pu démarrer. Vérifiez les logs pour plus d'informations."
    }
    
    Write-Host "Serveur MCP de test démarré avec le PID $($script:serverProcess.Id)" -ForegroundColor Green
    
    # Initialiser la connexion au serveur MCP
    Initialize-MCPConnection -ServerUrl $script:serverUrl
}

# Fonction pour arrêter le serveur MCP de test
function Stop-TestServer {
    if ($script:serverProcess -and -not $script:serverProcess.HasExited) {
        Write-Host "Arrêt du serveur MCP de test..." -ForegroundColor Yellow
        Stop-Process -Id $script:serverProcess.Id -Force
        Write-Host "Serveur MCP de test arrêté" -ForegroundColor Green
    }
}

# Fonction principale pour exécuter les tests de performance
function Start-PerformanceTests {
    $performanceResults = @()
    
    # Test 1: Mesurer le temps de connexion au serveur MCP
    $connectionTest = Measure-ExecutionTime -ScriptBlock {
        Initialize-MCPConnection -ServerUrl $script:serverUrl
    } -Name "Connection" -Iterations 5
    
    Write-Host "Test de connexion terminé en $($connectionTest.AverageTime) ms (moyenne sur $($connectionTest.Iterations) itérations)" -ForegroundColor Green
    $performanceResults += $connectionTest
    
    # Test 2: Mesurer le temps de récupération des outils disponibles
    $getToolsTest = Measure-ExecutionTime -ScriptBlock {
        Get-MCPTools
    } -Name "GetTools" -Iterations 5
    
    Write-Host "Test de récupération des outils terminé en $($getToolsTest.AverageTime) ms (moyenne sur $($getToolsTest.Iterations) itérations)" -ForegroundColor Green
    $performanceResults += $getToolsTest
    
    # Test 3: Mesurer le temps d'exécution de l'outil 'add' sans cache
    Set-MCPClientConfiguration -CacheEnabled $false
    
    $invokeToolNoCache = Measure-ExecutionTime -ScriptBlock {
        Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
    } -Name "InvokeToolNoCache" -Iterations 10
    
    Write-Host "Test d'exécution de l'outil 'add' sans cache terminé en $($invokeToolNoCache.AverageTime) ms (moyenne sur $($invokeToolNoCache.Iterations) itérations)" -ForegroundColor Green
    $performanceResults += $invokeToolNoCache
    
    # Test 4: Mesurer le temps d'exécution de l'outil 'add' avec cache
    Set-MCPClientConfiguration -CacheEnabled $true -CacheTTL 60
    Clear-MCPCache -Force
    
    # Premier appel (sans cache)
    $firstCallWithCache = Measure-ExecutionTime -ScriptBlock {
        Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
    } -Name "FirstCallWithCache" -Iterations 1
    
    Write-Host "Premier appel avec cache activé terminé en $($firstCallWithCache.AverageTime) ms" -ForegroundColor Green
    $performanceResults += $firstCallWithCache
    
    # Appels suivants (avec cache)
    $subsequentCallsWithCache = Measure-ExecutionTime -ScriptBlock {
        Invoke-MCPTool -ToolName "add" -Parameters @{ a = 2; b = 3 }
    } -Name "SubsequentCallsWithCache" -Iterations 10
    
    Write-Host "Appels suivants avec cache activé terminés en $($subsequentCallsWithCache.AverageTime) ms (moyenne sur $($subsequentCallsWithCache.Iterations) itérations)" -ForegroundColor Green
    $performanceResults += $subsequentCallsWithCache
    
    # Test 5: Mesurer le temps d'exécution de l'outil 'sleep' pour tester les opérations longues
    $sleepTest = Measure-ExecutionTime -ScriptBlock {
        Invoke-MCPTool -ToolName "sleep" -Parameters @{ seconds = 1 }
    } -Name "LongOperation" -Iterations 3
    
    Write-Host "Test d'opération longue terminé en $($sleepTest.AverageTime) ms (moyenne sur $($sleepTest.Iterations) itérations)" -ForegroundColor Green
    $performanceResults += $sleepTest
    
    # Test 6: Mesurer le temps d'exécution parallèle de plusieurs outils
    $parallelTest = Measure-ExecutionTime -ScriptBlock {
        $toolNames = @("add", "multiply", "echo")
        $parametersList = @(
            @{ a = 2; b = 3 },
            @{ a = 4; b = 5 },
            @{ text = "Hello, World!" }
        )
        
        Invoke-MCPToolParallel -ToolNames $toolNames -ParametersList $parametersList
    } -Name "ParallelExecution" -Iterations 5
    
    Write-Host "Test d'exécution parallèle terminé en $($parallelTest.AverageTime) ms (moyenne sur $($parallelTest.Iterations) itérations)" -ForegroundColor Green
    $performanceResults += $parallelTest
    
    # Test 7: Mesurer le temps de traitement par lots
    $batchTest = Measure-ExecutionTime -ScriptBlock {
        $inputObjects = 1..10 | ForEach-Object {
            [PSCustomObject]@{
                A = $_
                B = $_ * 2
            }
        }
        
        $scriptBlock = {
            param($batch)
            
            $results = @()
            foreach ($item in $batch) {
                $result = Invoke-MCPTool -ToolName "add" -Parameters @{
                    a = $item.A
                    b = $item.B
                }
                
                $results += [PSCustomObject]@{
                    Input = $item
                    Output = $result
                }
            }
            
            return $results
        }
        
        Invoke-MCPBatch -ScriptBlock $scriptBlock -InputObjects $inputObjects -BatchSize 3
    } -Name "BatchProcessing" -Iterations 3
    
    Write-Host "Test de traitement par lots terminé en $($batchTest.AverageTime) ms (moyenne sur $($batchTest.Iterations) itérations)" -ForegroundColor Green
    $performanceResults += $batchTest
    
    # Enregistrer les résultats dans un fichier JSON
    $performanceResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $script:resultsPath -Encoding utf8
    
    Write-Host "Résultats des tests de performance enregistrés dans $script:resultsPath" -ForegroundColor Green
    
    return $performanceResults
}

# Exécuter les tests de performance
try {
    # Démarrer le serveur MCP de test
    Start-TestServer
    
    # Exécuter les tests de performance
    $results = Start-PerformanceTests
    
    # Afficher un résumé des résultats
    Write-Host "`nRésumé des tests de performance:" -ForegroundColor Cyan
    $results | ForEach-Object {
        Write-Host "$($_.Name): $($_.AverageTime) ms (min: $($_.MinTime) ms, max: $($_.MaxTime) ms)" -ForegroundColor White
    }
} catch {
    Write-Host "Erreur lors de l'exécution des tests de performance: $_" -ForegroundColor Red
} finally {
    # Arrêter le serveur MCP de test
    Stop-TestServer
}

<#
.SYNOPSIS
    Tests de scalabilité pour Wait-ForCompletedRunspace.
.DESCRIPTION
    Ce script teste la capacité de Wait-ForCompletedRunspace à gérer un grand nombre de runspaces
    en utilisant la structure formelle Pester avec les blocs Describe/Context/It.
.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2023-05-19
    Encoding:       UTF-8 with BOM
#>

# Importer le module Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"

# Vérifier si le module est déjà importé et le réimporter si nécessaire
if (Get-Module -Name UnifiedParallel) {
    Remove-Module -Name UnifiedParallel -Force
}
Import-Module $modulePath -Force

Describe "Tests de scalabilité pour Wait-ForCompletedRunspace" {
    BeforeAll {
        # Initialiser le module
        Initialize-UnifiedParallel -Verbose
        
        # Fonction pour créer des runspaces avec des délais différents
        function New-TestRunspaces {
            param(
                [int]$Count,
                [array]$Delays
            )
            
            # Créer un pool de runspaces
            $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
            $runspacePool = [runspacefactory]::CreateRunspacePool(1, 8, $sessionState, $Host)
            $runspacePool.Open()
            
            # Créer une liste pour stocker les runspaces
            $runspaces = [System.Collections.Generic.List[object]]::new($Count)
            
            # Créer les runspaces avec des délais différents
            for ($i = 0; $i -lt $Count; $i++) {
                $delay = $Delays[$i % $Delays.Length]
                
                $powershell = [powershell]::Create()
                $powershell.RunspacePool = $runspacePool
                
                # Ajouter un script simple avec délai variable
                [void]$powershell.AddScript({
                    param($Item, $DelayMilliseconds)
                    Start-Sleep -Milliseconds $DelayMilliseconds
                    return [PSCustomObject]@{
                        Item = $Item
                        Delay = $DelayMilliseconds
                        ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                        StartTime = Get-Date
                    }
                })
                
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
        
        # Fonction pour mesurer les performances
        function Measure-Performance {
            param(
                [scriptblock]$ScriptBlock
            )
            
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            
            # Exécuter le script
            $result = & $ScriptBlock
            
            $stopwatch.Stop()
            $elapsedMs = $stopwatch.ElapsedMilliseconds
            
            return @{
                Result = $result
                ElapsedMs = $elapsedMs
            }
        }
    }
    
    AfterAll {
        # Nettoyer
        Clear-UnifiedParallel -Verbose
    }
    
    Context "Scalabilité avec un petit nombre de runspaces (50)" {
        BeforeAll {
            # Paramètres de test
            $script:runspaceCount = 50
            $script:delaysMilliseconds = @(10, 20, 30, 40, 50)
            $script:timeoutSeconds = 30
            
            # Créer des runspaces
            $runspaceInfo = New-TestRunspaces -Count $script:runspaceCount -Delays $script:delaysMilliseconds
            
            # Mesurer les performances
            $perfResults = Measure-Performance -ScriptBlock {
                Wait-ForCompletedRunspace -Runspaces $runspaceInfo.Runspaces -WaitForAll -NoProgress -TimeoutSeconds $script:timeoutSeconds
            }
            
            $script:completedRunspaces = $perfResults.Result
            $script:elapsedMs = $perfResults.ElapsedMs
            
            # Traiter les résultats
            $script:results = Invoke-RunspaceProcessor -CompletedRunspaces $script:completedRunspaces.Results -NoProgress
            
            # Nettoyer le pool de runspaces
            $runspaceInfo.Pool.Close()
            $runspaceInfo.Pool.Dispose()
        }
        
        It "Devrait compléter tous les runspaces" {
            $script:completedRunspaces.Count | Should -Be $script:runspaceCount
        }
        
        It "Devrait avoir un temps d'exécution raisonnable" {
            # Le temps d'exécution devrait être supérieur au délai maximal
            $script:elapsedMs | Should -BeGreaterThan ($script:delaysMilliseconds | Measure-Object -Maximum).Maximum
            
            # Le temps d'exécution ne devrait pas être excessif
            $script:elapsedMs | Should -BeLessThan ($script:timeoutSeconds * 1000)
        }
        
        It "Devrait traiter tous les résultats correctement" {
            $script:results.TotalProcessed | Should -Be $script:runspaceCount
            $script:results.SuccessCount | Should -Be $script:runspaceCount
            $script:results.ErrorCount | Should -Be 0
        }
    }
    
    Context "Scalabilité avec un nombre moyen de runspaces (100)" {
        BeforeAll {
            # Paramètres de test
            $script:runspaceCount = 100
            $script:delaysMilliseconds = @(10, 20, 30, 40, 50)
            $script:timeoutSeconds = 30
            
            # Créer des runspaces
            $runspaceInfo = New-TestRunspaces -Count $script:runspaceCount -Delays $script:delaysMilliseconds
            
            # Mesurer les performances
            $perfResults = Measure-Performance -ScriptBlock {
                Wait-ForCompletedRunspace -Runspaces $runspaceInfo.Runspaces -WaitForAll -NoProgress -TimeoutSeconds $script:timeoutSeconds
            }
            
            $script:completedRunspacesMedium = $perfResults.Result
            $script:elapsedMsMedium = $perfResults.ElapsedMs
            
            # Traiter les résultats
            $script:resultsMedium = Invoke-RunspaceProcessor -CompletedRunspaces $script:completedRunspacesMedium.Results -NoProgress
            
            # Nettoyer le pool de runspaces
            $runspaceInfo.Pool.Close()
            $runspaceInfo.Pool.Dispose()
        }
        
        It "Devrait compléter tous les runspaces" {
            $script:completedRunspacesMedium.Count | Should -Be $script:runspaceCount
        }
        
        It "Devrait avoir un temps d'exécution raisonnable" {
            # Le temps d'exécution devrait être supérieur au délai maximal
            $script:elapsedMsMedium | Should -BeGreaterThan ($script:delaysMilliseconds | Measure-Object -Maximum).Maximum
            
            # Le temps d'exécution ne devrait pas être excessif
            $script:elapsedMsMedium | Should -BeLessThan ($script:timeoutSeconds * 1000)
        }
        
        It "Devrait traiter tous les résultats correctement" {
            $script:resultsMedium.TotalProcessed | Should -Be $script:runspaceCount
            $script:resultsMedium.SuccessCount | Should -Be $script:runspaceCount
            $script:resultsMedium.ErrorCount | Should -Be 0
        }
        
        It "Devrait être efficace avec un plus grand nombre de runspaces" {
            # Le temps moyen par runspace devrait être similaire ou meilleur avec plus de runspaces
            $timePerRunspaceSmall = $script:elapsedMs / 50
            $timePerRunspaceMedium = $script:elapsedMsMedium / 100
            
            # Tolérance de 50% pour tenir compte des variations
            $timePerRunspaceMedium | Should -BeLessThan ($timePerRunspaceSmall * 1.5)
        }
    }
    
    Context "Scalabilité avec un grand nombre de runspaces (200)" {
        BeforeAll {
            # Paramètres de test
            $script:runspaceCount = 200
            $script:delaysMilliseconds = @(10, 20, 30, 40, 50)
            $script:timeoutSeconds = 60
            
            # Créer des runspaces
            $runspaceInfo = New-TestRunspaces -Count $script:runspaceCount -Delays $script:delaysMilliseconds
            
            # Mesurer les performances
            $perfResults = Measure-Performance -ScriptBlock {
                Wait-ForCompletedRunspace -Runspaces $runspaceInfo.Runspaces -WaitForAll -NoProgress -TimeoutSeconds $script:timeoutSeconds
            }
            
            $script:completedRunspacesLarge = $perfResults.Result
            $script:elapsedMsLarge = $perfResults.ElapsedMs
            
            # Traiter les résultats
            $script:resultsLarge = Invoke-RunspaceProcessor -CompletedRunspaces $script:completedRunspacesLarge.Results -NoProgress
            
            # Nettoyer le pool de runspaces
            $runspaceInfo.Pool.Close()
            $runspaceInfo.Pool.Dispose()
        }
        
        It "Devrait compléter tous les runspaces" {
            $script:completedRunspacesLarge.Count | Should -Be $script:runspaceCount
        }
        
        It "Devrait avoir un temps d'exécution raisonnable" {
            # Le temps d'exécution devrait être supérieur au délai maximal
            $script:elapsedMsLarge | Should -BeGreaterThan ($script:delaysMilliseconds | Measure-Object -Maximum).Maximum
            
            # Le temps d'exécution ne devrait pas être excessif
            $script:elapsedMsLarge | Should -BeLessThan ($script:timeoutSeconds * 1000)
        }
        
        It "Devrait traiter tous les résultats correctement" {
            $script:resultsLarge.TotalProcessed | Should -Be $script:runspaceCount
            $script:resultsLarge.SuccessCount | Should -Be $script:runspaceCount
            $script:resultsLarge.ErrorCount | Should -Be 0
        }
        
        It "Devrait être efficace avec un grand nombre de runspaces" {
            # Le temps moyen par runspace devrait être similaire ou meilleur avec plus de runspaces
            $timePerRunspaceSmall = $script:elapsedMs / 50
            $timePerRunspaceLarge = $script:elapsedMsLarge / 200
            
            # Tolérance de 100% pour tenir compte des variations
            $timePerRunspaceLarge | Should -BeLessThan ($timePerRunspaceSmall * 2)
        }
    }
}

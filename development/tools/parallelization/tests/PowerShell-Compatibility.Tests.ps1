# Tests Pester pour la compatibilité avec différentes versions de PowerShell
# Ce script utilise Pester pour vérifier que Wait-ForCompletedRunspace fonctionne correctement sur PowerShell 5.1 et 7.x

BeforeAll {
    # Importer le module UnifiedParallel
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel -Verbose

    # Fonction pour créer des runspaces de test
    function New-TestRunspaces {
        param(
            [int]$Count = 10
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
            [void]$powershell.AddScript({
                    param($Item)
                    Start-Sleep -Milliseconds (10 * ($Item % 5 + 1))
                    return [PSCustomObject]@{
                        Item      = $Item
                        PSVersion = $PSVersionTable.PSVersion.ToString()
                        ThreadId  = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                        StartTime = Get-Date
                        EndTime   = Get-Date
                    }
                })

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
            Pool      = $runspacePool
        }
    }

    # Fonction pour exécuter un test sur la version actuelle de PowerShell
    function Test-CurrentPowerShellVersion {
        # Créer des runspaces de test
        $testData = New-TestRunspaces -Count 10
        $runspaces = $testData.Runspaces
        $pool = $testData.Pool

        try {
            # Exécuter Wait-ForCompletedRunspace
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 30

            # Traiter les résultats
            $processedResults = Invoke-RunspaceProcessor -CompletedRunspaces $completedRunspaces.Results -NoProgress

            # Retourner le résultat
            return @{
                Success        = $true
                CompletedCount = $completedRunspaces.Count
                PSVersion      = $PSVersionTable.PSVersion.ToString()
                Results        = $processedResults
            }
        } catch {
            return @{
                Success   = $false
                Error     = $_
                PSVersion = $PSVersionTable.PSVersion.ToString()
            }
        } finally {
            # Nettoyer
            if ($pool) {
                $pool.Close()
                $pool.Dispose()
            }
        }
    }

    # Fonction pour exécuter un test sur une version spécifique de PowerShell
    function Test-PowerShellVersion {
        param(
            [string]$Version,
            [string]$Command
        )

        try {
            # Créer un script de test temporaire
            $testScriptPath = Join-Path -Path $env:TEMP -ChildPath "PS-Compatibility-Test-$Version.ps1"

            $scriptContent = @'
# Script de test pour Wait-ForCompletedRunspace
# Ce script est exécuté par PowerShell-Compatibility.Tests.ps1 pour tester la compatibilité

# Importer le module UnifiedParallel
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Initialiser le module
Initialize-UnifiedParallel

# Fonction pour créer des runspaces de test
function New-TestRunspaces {
    param(
        [int]$Count = 10
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
        [void]$powershell.AddScript({
                param($Item)
                Start-Sleep -Milliseconds (10 * ($Item % 5 + 1))
                return [PSCustomObject]@{
                    Item = $Item
                    PSVersion = $PSVersionTable.PSVersion.ToString()
                    ThreadId = [System.Threading.Thread]::CurrentThread.ManagedThreadId
                    StartTime = Get-Date
                    EndTime = Get-Date
                }
            })

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

# Exécuter le test
try {
    # Créer des runspaces de test
    $testData = New-TestRunspaces -Count 10
    $runspaces = $testData.Runspaces
    $pool = $testData.Pool

    # Exécuter Wait-ForCompletedRunspace
    $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress -TimeoutSeconds 30

    # Vérifier que tous les runspaces ont été complétés
    if ($completedRunspaces.Count -eq 10) {
        Write-Host "SUCCESS: Tous les runspaces ont été complétés avec succès."
        exit 0
    } else {
        Write-Host "ERROR: Certains runspaces n'ont pas été complétés."
        exit 1
    }
} catch {
    Write-Host "ERROR: $_"
    exit 1
} finally {
    # Nettoyer
    if ($pool) {
        $pool.Close()
        $pool.Dispose()
    }

    Clear-UnifiedParallel
}
'@

            # Écrire le script dans un fichier temporaire
            $scriptContent | Out-File -FilePath $testScriptPath -Encoding utf8 -Force

            # Exécuter le test
            $output = & $Command -NoProfile -ExecutionPolicy Bypass -File $testScriptPath

            # Vérifier le résultat
            if ($LASTEXITCODE -eq 0) {
                return @{
                    Success   = $true
                    Output    = $output
                    PSVersion = $Version
                }
            } else {
                return @{
                    Success   = $false
                    Output    = $output
                    PSVersion = $Version
                }
            }
        } catch {
            return @{
                Success   = $false
                Error     = $_
                PSVersion = $Version
            }
        } finally {
            # Nettoyer
            if (Test-Path -Path $testScriptPath) {
                Remove-Item -Path $testScriptPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}

AfterAll {
    # Nettoyer le module
    Clear-UnifiedParallel -Verbose
}

Describe "Compatibilité de Wait-ForCompletedRunspace avec différentes versions de PowerShell" {
    Context "Avec la version actuelle de PowerShell ($($PSVersionTable.PSVersion))" {
        BeforeAll {
            $result = Test-CurrentPowerShellVersion
        }

        It "Devrait s'exécuter correctement sur la version actuelle de PowerShell" {
            $result.Success | Should -Be $true
        }

        It "Devrait traiter tous les runspaces correctement" {
            $result.CompletedCount | Should -Be 10
        }
    }

    Context "Vérification de la compatibilité du code" {
        BeforeAll {
            # Analyser le code source pour vérifier la compatibilité
            $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
            $moduleContent = Get-Content -Path $modulePath -Raw

            # Vérifier les fonctionnalités spécifiques à PowerShell 7.x
            $ps7Features = @(
                'ForEach-Object -Parallel',
                'ThrottleLimit',
                'using namespace System.Collections.Concurrent'
            )

            # Vérifier les fonctionnalités compatibles avec PowerShell 5.1
            $ps51Features = @(
                '[System.Collections.Generic.List',
                '[System.Collections.Concurrent.ConcurrentDictionary',
                '[System.Threading.Thread]',
                '[System.Threading.Tasks.Task]'
            )

            # Vérifier si des fonctionnalités incompatibles sont utilisées
            $ps7FeaturesFound = $ps7Features | Where-Object { $moduleContent -match [regex]::Escape($_) }
            $ps51FeaturesFound = $ps51Features | Where-Object { $moduleContent -match [regex]::Escape($_) }
        }

        It "Ne devrait pas utiliser de fonctionnalités spécifiques à PowerShell 7.x" {
            $ps7FeaturesFound | Should -BeNullOrEmpty
        }

        It "Devrait utiliser des fonctionnalités compatibles avec PowerShell 5.1" {
            $ps51FeaturesFound | Should -Not -BeNullOrEmpty
        }
    }
}

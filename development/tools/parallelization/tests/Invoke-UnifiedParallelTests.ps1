# Tests unitaires pour le module UnifiedParallel
# Utilise Pester pour les tests unitaires

# Créer le dossier de tests s'il n'existe pas
$testDir = Join-Path -Path $PSScriptRoot -ChildPath ".."
$testDir = Join-Path -Path $testDir -ChildPath "tests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath ".."
$modulePath = Join-Path -Path $modulePath -ChildPath "UnifiedParallel.psm1"
Import-Module $modulePath -Force

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir les tests
Describe "Module UnifiedParallel" {
    BeforeAll {
        # Initialiser le module avant tous les tests
        Initialize-UnifiedParallel
    }

    AfterAll {
        # Nettoyer après tous les tests
        Clear-UnifiedParallel
    }

    Context "Initialize-UnifiedParallel" {
        It "Initialise le module correctement" {
            # Réinitialiser pour tester l'initialisation
            Clear-UnifiedParallel
            $result = Initialize-UnifiedParallel
            $script:IsInitialized | Should -Be $true
            $script:Config | Should -Not -BeNullOrEmpty
            $script:Config.DefaultMaxThreads | Should -BeGreaterThan 0
        }

        It "Charge la configuration depuis un fichier" {
            # Créer un fichier de configuration temporaire
            $configPath = Join-Path -Path $TestDrive -ChildPath "test_config.json"
            @{
                DefaultMaxThreads = 16
                DefaultThrottleLimit = 20
                ResourceThresholds = @{
                    CPU = 90
                    Memory = 85
                }
            } | ConvertTo-Json | Out-File -FilePath $configPath

            # Initialiser avec le fichier de configuration
            Clear-UnifiedParallel
            $result = Initialize-UnifiedParallel -ConfigPath $configPath
            $script:Config.DefaultMaxThreads | Should -Be 16
            $script:Config.DefaultThrottleLimit | Should -Be 20
            $script:Config.ResourceThresholds.CPU | Should -Be 90
        }
    }

    Context "Clear-UnifiedParallel" {
        It "Nettoie correctement les ressources du module" {
            # Initialiser d'abord
            Initialize-UnifiedParallel
            $script:IsInitialized | Should -Be $true

            # Nettoyer
            Clear-UnifiedParallel
            $script:IsInitialized | Should -Be $false
        }
    }

    Context "Get-OptimalThreadCount" {
        It "Retourne le nombre correct de threads pour le type CPU" {
            $threads = Get-OptimalThreadCount -TaskType 'CPU'
            $threads | Should -Be ([Environment]::ProcessorCount)
        }

        It "Retourne le nombre correct de threads pour le type IO" {
            $threads = Get-OptimalThreadCount -TaskType 'IO'
            $threads | Should -BeGreaterThan ([Environment]::ProcessorCount)
        }

        It "Retourne le nombre correct de threads pour le type LowPriority" {
            $threads = Get-OptimalThreadCount -TaskType 'LowPriority'
            $threads | Should -BeLessOrEqual ([Environment]::ProcessorCount)
        }
    }

    Context "Wait-ForCompletedRunspace" {
        It "Attend correctement les runspaces complétés" {
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
            $completedRunspaces = Wait-ForCompletedRunspace -Runspaces $runspaces -WaitForAll -NoProgress
            $completedRunspaces.Count | Should -Be 1

            # Nettoyer
            $runspacePool.Close()
            $runspacePool.Dispose()
        }
    }

    Context "Invoke-UnifiedParallel" {
        It "Exécute correctement des tâches en parallèle" {
            $testData = 1..3
            $results = Invoke-UnifiedParallel -ScriptBlock {
                param($item)
                return "Test $item"
            } -InputObject $testData -MaxThreads 2 -UseRunspacePool -NoProgress

            $results.Count | Should -Be 3
            $results[0].Value | Should -Be "Test 1"
            $results[1].Value | Should -Be "Test 2"
            $results[2].Value | Should -Be "Test 3"
        }

        It "Gère correctement les erreurs" {
            $testData = 1..3
            $results = Invoke-UnifiedParallel -ScriptBlock {
                param($item)
                if ($item -eq 2) {
                    throw "Erreur test"
                }
                return "Test $item"
            } -InputObject $testData -MaxThreads 2 -UseRunspacePool -NoProgress -IgnoreErrors

            $successResults = $results | Where-Object { $_.Success }
            $errorResults = $results | Where-Object { -not $_.Success }

            $successResults.Count | Should -Be 2
            $errorResults.Count | Should -Be 1
            $errorResults[0].Error.Exception.Message | Should -Be "Erreur test"
        }

        It "Retourne les résultats détaillés avec PassThru" {
            $testData = 1..3
            $results = Invoke-UnifiedParallel -ScriptBlock {
                param($item)
                return "Test $item"
            } -InputObject $testData -MaxThreads 2 -UseRunspacePool -NoProgress -PassThru

            $results.Results.Count | Should -Be 3
            $results.TotalItems | Should -Be 3
            $results.ProcessedItems | Should -Be 3
            $results.Duration | Should -Not -BeNullOrEmpty
        }
    }
}

# Exécuter les tests
Invoke-Pester -Output Detailed

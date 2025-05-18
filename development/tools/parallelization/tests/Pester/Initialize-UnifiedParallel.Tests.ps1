# Tests unitaires pour la fonction Initialize-UnifiedParallel
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force
}

Describe "Initialize-UnifiedParallel" {
    BeforeEach {
        # Nettoyer avant chaque test
        if (Get-Command -Name Clear-UnifiedParallel -ErrorAction SilentlyContinue) {
            Clear-UnifiedParallel
        }
    }

    It "Initialise le module avec les valeurs par défaut" {
        $result = Initialize-UnifiedParallel
        $result | Should -Not -BeNullOrEmpty
        $result.DefaultMaxThreads | Should -BeGreaterThan 0
        $result.DefaultThrottleLimit | Should -BeGreaterThan 0
        $result.ResourceThresholds | Should -Not -BeNullOrEmpty
        $result.BackpressureSettings | Should -Not -BeNullOrEmpty
        $result.ErrorHandling | Should -Not -BeNullOrEmpty
        $result.AdvancedSettings | Should -Not -BeNullOrEmpty
        $result.ModuleVersion | Should -Be "1.0.0"
    }

    It "Charge la configuration depuis un fichier personnalisé" {
        # Créer un fichier de configuration temporaire
        $tempDir = [System.IO.Path]::GetTempPath()
        $tempConfigPath = Join-Path -Path $tempDir -ChildPath "temp_config.json"

        @{
            DefaultMaxThreads    = 16
            DefaultThrottleLimit = 20
            ResourceThresholds   = @{
                CPU    = 90
                Memory = 85
            }
        } | ConvertTo-Json | Out-File -FilePath $tempConfigPath -Encoding UTF8

        $result = Initialize-UnifiedParallel -ConfigPath $tempConfigPath
        $result.DefaultMaxThreads | Should -Be 16
        $result.DefaultThrottleLimit | Should -Be 20
        $result.ResourceThresholds.CPU | Should -Be 90

        # Nettoyer
        Remove-Item -Path $tempConfigPath -Force
    }

    It "Gère correctement les chemins de configuration invalides" {
        # Utiliser un chemin qui n'existe pas
        $invalidPath = "chemin/invalide.json"

        # Vérifier que la fonction ne lance pas d'erreur (elle devrait utiliser les valeurs par défaut)
        { Initialize-UnifiedParallel -ConfigPath $invalidPath } | Should -Not -Throw

        # Vérifier que le module est bien initialisé
        Get-ModuleInitialized | Should -Be $true

        # Vérifier que la configuration a été créée avec les valeurs par défaut
        $config = Get-ModuleConfig
        $config | Should -Not -BeNullOrEmpty
        $config.DefaultMaxThreads | Should -BeGreaterThan 0
    }

    It "Initialise le gestionnaire de backpressure" {
        $result = Initialize-UnifiedParallel
        $result.BackpressureSettings.Enabled | Should -Be $true
        $result.BackpressureSettings.QueueSizeWarning | Should -BeGreaterThan 0
        $result.BackpressureSettings.QueueSizeCritical | Should -BeGreaterThan 0
        $result.BackpressureSettings.RejectionThreshold | Should -BeGreaterThan 0
    }

    It "Initialise le gestionnaire de throttling" {
        $result = Initialize-UnifiedParallel
        $result.AdvancedSettings.EnableDynamicScaling | Should -Be $true
        $result.AdvancedSettings.MinThreads | Should -BeGreaterThan 0
        $result.AdvancedSettings.MaxThreads | Should -BeGreaterThan 0
        $result.AdvancedSettings.ThreadIdleTimeoutMs | Should -BeGreaterThan 0
    }

    It "Désactive le gestionnaire de backpressure si demandé" {
        # Réinitialiser avec backpressure désactivé
        $result = Initialize-UnifiedParallel -EnableBackpressure $false -Force

        # Vérifier que la configuration a été mise à jour
        if ($result.BackpressureSettings -is [PSCustomObject]) {
            $result.BackpressureSettings.Enabled | Should -Be $false
        } else {
            $result.BackpressureSettings['Enabled'] | Should -Be $false
        }
    }

    It "Désactive le gestionnaire de throttling si demandé" {
        # Réinitialiser avec throttling désactivé
        $result = Initialize-UnifiedParallel -EnableThrottling $false -Force

        # Vérifier que la configuration a été mise à jour
        if ($result.AdvancedSettings -is [PSCustomObject]) {
            $result.AdvancedSettings.EnableDynamicScaling | Should -Be $false
        } else {
            $result.AdvancedSettings['EnableDynamicScaling'] | Should -Be $false
        }
    }

    It "Permet d'activer/désactiver les deux gestionnaires simultanément" {
        # Réinitialiser avec les deux désactivés
        $result = Initialize-UnifiedParallel -EnableBackpressure $false -EnableThrottling $false -Force

        # Vérifier que la configuration a été mise à jour
        if ($result.BackpressureSettings -is [PSCustomObject]) {
            $result.BackpressureSettings.Enabled | Should -Be $false
        } else {
            $result.BackpressureSettings['Enabled'] | Should -Be $false
        }

        if ($result.AdvancedSettings -is [PSCustomObject]) {
            $result.AdvancedSettings.EnableDynamicScaling | Should -Be $false
        } else {
            $result.AdvancedSettings['EnableDynamicScaling'] | Should -Be $false
        }
    }

    It "Définit correctement le chemin des logs" {
        $tempDir = [System.IO.Path]::GetTempPath()
        $result = Initialize-UnifiedParallel -LogPath $tempDir
        $result.LogPath | Should -Be $tempDir
    }

    It "Définit correctement le timeout par défaut" {
        $result = Initialize-UnifiedParallel -DefaultTimeout 600
        $result.DefaultTimeout | Should -Be 600
    }

    AfterEach {
        # Nettoyer après chaque test
        Clear-UnifiedParallel
    }
}

AfterAll {
    # Nettoyer après tous les tests
    if (Get-Command -Name Clear-UnifiedParallel -ErrorAction SilentlyContinue) {
        Clear-UnifiedParallel
    }
}

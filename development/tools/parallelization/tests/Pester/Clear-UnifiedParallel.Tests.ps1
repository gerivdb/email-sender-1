# Tests unitaires pour la fonction Clear-UnifiedParallel
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force
}

Describe "Clear-UnifiedParallel" {
    BeforeEach {
        # Initialiser le module avant chaque test
        Initialize-UnifiedParallel

        # Vérifier que le module est bien initialisé
        Get-ModuleInitialized | Should -Be $true
        Get-ModuleConfig | Should -Not -BeNullOrEmpty
    }

    It "Nettoie correctement les ressources du module" {
        # Exécuter la fonction à tester
        Clear-UnifiedParallel

        # Vérifier que le module est bien nettoyé
        Get-ModuleInitialized | Should -Be $false
        Get-ModuleConfig | Should -BeNullOrEmpty
        $script:ResourceMonitor | Should -BeNullOrEmpty
        $script:BackpressureManager | Should -BeNullOrEmpty
        $script:ThrottlingManager | Should -BeNullOrEmpty
    }

    It "Peut être appelé plusieurs fois sans erreur" {
        # Appeler la fonction une première fois
        Clear-UnifiedParallel

        # Appeler la fonction une deuxième fois
        { Clear-UnifiedParallel } | Should -Not -Throw
    }

    It "Peut être appelé sans paramètres" {
        # Appeler la fonction sans paramètres
        { Clear-UnifiedParallel } | Should -Not -Throw

        # Vérifier que le module est bien nettoyé
        Get-ModuleInitialized | Should -Be $false
    }

    It "Peut être appelé avec le paramètre -WhatIf" {
        # Appeler la fonction avec -WhatIf
        Clear-UnifiedParallel -WhatIf

        # Vérifier que le module n'est pas nettoyé
        Get-ModuleInitialized | Should -Be $true
    }

    It "Peut être appelé avec le paramètre -Confirm:$false" {
        # Appeler la fonction avec -Confirm:$false
        Clear-UnifiedParallel -Confirm:$false

        # Vérifier que le module est bien nettoyé
        Get-ModuleInitialized | Should -Be $false
    }
}

AfterAll {
    # Nettoyer après tous les tests
    if (Get-Command -Name Clear-UnifiedParallel -ErrorAction SilentlyContinue) {
        Clear-UnifiedParallel
    }
}

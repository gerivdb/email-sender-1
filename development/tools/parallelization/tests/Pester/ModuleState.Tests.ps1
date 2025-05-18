BeforeAll {
    # Importer le module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\.." -Resolve
    $moduleName = "UnifiedParallel"
    
    # Supprimer le module s'il est déjà chargé
    if (Get-Module -Name $moduleName) {
        Remove-Module -Name $moduleName -Force
    }
    
    # Importer le module
    Import-Module -Name (Join-Path -Path $modulePath -ChildPath "$moduleName.psm1") -Force
}

Describe "Fonctions de gestion d'état du module" {
    BeforeEach {
        # Nettoyer avant chaque test
        if (Get-Command -Name Clear-UnifiedParallel -ErrorAction SilentlyContinue) {
            Clear-UnifiedParallel
        }
    }
    
    Context "Get-ModuleInitialized" {
        It "Retourne False quand le module n'est pas initialisé" {
            # Vérifier que le module n'est pas initialisé
            $result = Get-ModuleInitialized
            $result | Should -BeFalse
        }
        
        It "Retourne True après initialisation du module" {
            # Initialiser le module
            Initialize-UnifiedParallel
            
            # Vérifier que le module est initialisé
            $result = Get-ModuleInitialized
            $result | Should -BeTrue
        }
    }
    
    Context "Set-ModuleInitialized" {
        It "Définit l'état d'initialisation à True" {
            # Définir l'état d'initialisation à True
            $result = Set-ModuleInitialized -Value $true
            
            # Vérifier que l'état est bien défini
            $result | Should -BeTrue
            Get-ModuleInitialized | Should -BeTrue
        }
        
        It "Définit l'état d'initialisation à False" {
            # Initialiser d'abord le module
            Initialize-UnifiedParallel
            
            # Définir l'état d'initialisation à False
            $result = Set-ModuleInitialized -Value $false
            
            # Vérifier que l'état est bien défini
            $result | Should -BeFalse
            Get-ModuleInitialized | Should -BeFalse
        }
        
        It "Retourne la valeur définie" {
            # Définir l'état d'initialisation à True
            $result = Set-ModuleInitialized -Value $true
            $result | Should -BeTrue
            
            # Définir l'état d'initialisation à False
            $result = Set-ModuleInitialized -Value $false
            $result | Should -BeFalse
        }
    }
    
    Context "Get-ModuleConfig" {
        It "Retourne null quand le module n'est pas initialisé" {
            # Vérifier que le module n'est pas initialisé
            Set-ModuleInitialized -Value $false
            
            # Récupérer la configuration
            $result = Get-ModuleConfig
            $result | Should -BeNullOrEmpty
        }
        
        It "Retourne la configuration après initialisation du module" {
            # Initialiser le module
            Initialize-UnifiedParallel
            
            # Récupérer la configuration
            $result = Get-ModuleConfig
            $result | Should -Not -BeNullOrEmpty
            $result.DefaultMaxThreads | Should -BeGreaterThan 0
            $result.DefaultThrottleLimit | Should -BeGreaterThan 0
        }
    }
    
    Context "Set-ModuleConfig" {
        It "Retourne null quand le module n'est pas initialisé" {
            # Vérifier que le module n'est pas initialisé
            Set-ModuleInitialized -Value $false
            
            # Définir la configuration
            $config = [PSCustomObject]@{
                DefaultMaxThreads = 16
                DefaultThrottleLimit = 20
            }
            $result = Set-ModuleConfig -Value $config
            $result | Should -BeNullOrEmpty
        }
        
        It "Définit la configuration quand le module est initialisé" {
            # Initialiser le module
            Initialize-UnifiedParallel
            
            # Définir la configuration
            $config = [PSCustomObject]@{
                DefaultMaxThreads = 16
                DefaultThrottleLimit = 20
                TestProperty = "Test"
            }
            $result = Set-ModuleConfig -Value $config
            
            # Vérifier que la configuration est bien définie
            $result | Should -Not -BeNullOrEmpty
            $result.DefaultMaxThreads | Should -Be 16
            $result.DefaultThrottleLimit | Should -Be 20
            $result.TestProperty | Should -Be "Test"
            
            # Vérifier que Get-ModuleConfig retourne la même configuration
            $getResult = Get-ModuleConfig
            $getResult.DefaultMaxThreads | Should -Be 16
            $getResult.DefaultThrottleLimit | Should -Be 20
            $getResult.TestProperty | Should -Be "Test"
        }
        
        It "Retourne la configuration définie" {
            # Initialiser le module
            Initialize-UnifiedParallel
            
            # Définir la configuration
            $config = [PSCustomObject]@{
                DefaultMaxThreads = 16
                DefaultThrottleLimit = 20
                TestProperty = "Test"
            }
            $result = Set-ModuleConfig -Value $config
            
            # Vérifier que le résultat est la configuration définie
            $result | Should -Be $config
        }
    }
}

AfterAll {
    # Nettoyer après tous les tests
    if (Get-Command -Name Clear-UnifiedParallel -ErrorAction SilentlyContinue) {
        Clear-UnifiedParallel
    }
    
    # Supprimer le module
    if (Get-Module -Name $moduleName) {
        Remove-Module -Name $moduleName -Force
    }
}

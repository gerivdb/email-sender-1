# Tests unitaires pour la documentation du module UnifiedParallel
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force

    # Initialiser le module
    Initialize-UnifiedParallel
}

Describe "Documentation du module UnifiedParallel" {
    Context "Fonctions publiques" {
        It "Get-OptimalThreadCount a une documentation complète" {
            $help = Get-Help -Name Get-OptimalThreadCount -Full
            
            $help | Should -Not -BeNullOrEmpty
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Examples.Example.Count | Should -BeGreaterThan 0
            
            # Vérifier que tous les paramètres sont documentés
            $command = Get-Command -Name Get-OptimalThreadCount
            $commandParams = $command.Parameters.Keys | Where-Object { $_ -notin [System.Management.Automation.PSCmdlet]::CommonParameters }
            $helpParams = $help.Parameters.Parameter | ForEach-Object { $_.Name }
            
            foreach ($param in $commandParams) {
                $helpParams | Should -Contain $param
            }
        }
        
        It "Initialize-UnifiedParallel a une documentation complète" {
            $help = Get-Help -Name Initialize-UnifiedParallel -Full
            
            $help | Should -Not -BeNullOrEmpty
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Examples.Example.Count | Should -BeGreaterThan 0
            
            # Vérifier que tous les paramètres sont documentés
            $command = Get-Command -Name Initialize-UnifiedParallel
            $commandParams = $command.Parameters.Keys | Where-Object { $_ -notin [System.Management.Automation.PSCmdlet]::CommonParameters }
            $helpParams = $help.Parameters.Parameter | ForEach-Object { $_.Name }
            
            foreach ($param in $commandParams) {
                $helpParams | Should -Contain $param
            }
        }
        
        It "Invoke-UnifiedParallel a une documentation complète" {
            $help = Get-Help -Name Invoke-UnifiedParallel -Full
            
            $help | Should -Not -BeNullOrEmpty
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Examples.Example.Count | Should -BeGreaterThan 0
            
            # Vérifier que tous les paramètres sont documentés
            $command = Get-Command -Name Invoke-UnifiedParallel
            $commandParams = $command.Parameters.Keys | Where-Object { $_ -notin [System.Management.Automation.PSCmdlet]::CommonParameters }
            $helpParams = $help.Parameters.Parameter | ForEach-Object { $_.Name }
            
            foreach ($param in $commandParams) {
                $helpParams | Should -Contain $param
            }
        }
        
        It "Clear-UnifiedParallel a une documentation complète" {
            $help = Get-Help -Name Clear-UnifiedParallel -Full
            
            $help | Should -Not -BeNullOrEmpty
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Examples.Example.Count | Should -BeGreaterThan 0
            
            # Vérifier que tous les paramètres sont documentés
            $command = Get-Command -Name Clear-UnifiedParallel
            $commandParams = $command.Parameters.Keys | Where-Object { $_ -notin [System.Management.Automation.PSCmdlet]::CommonParameters }
            $helpParams = $help.Parameters.Parameter | ForEach-Object { $_.Name }
            
            foreach ($param in $commandParams) {
                $helpParams | Should -Contain $param
            }
        }
        
        It "New-UnifiedError a une documentation complète" {
            $help = Get-Help -Name New-UnifiedError -Full
            
            $help | Should -Not -BeNullOrEmpty
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Examples.Example.Count | Should -BeGreaterThan 0
            
            # Vérifier que tous les paramètres sont documentés
            $command = Get-Command -Name New-UnifiedError
            $commandParams = $command.Parameters.Keys | Where-Object { $_ -notin [System.Management.Automation.PSCmdlet]::CommonParameters }
            $helpParams = $help.Parameters.Parameter | ForEach-Object { $_.Name }
            
            foreach ($param in $commandParams) {
                $helpParams | Should -Contain $param
            }
        }
    }
    
    Context "Fonctions internes" {
        It "Wait-ForCompletedRunspace a une documentation complète" {
            $help = Get-Help -Name Wait-ForCompletedRunspace -Full
            
            $help | Should -Not -BeNullOrEmpty
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Examples.Example.Count | Should -BeGreaterThan 0
            
            # Vérifier que tous les paramètres sont documentés
            $command = Get-Command -Name Wait-ForCompletedRunspace
            $commandParams = $command.Parameters.Keys | Where-Object { $_ -notin [System.Management.Automation.PSCmdlet]::CommonParameters }
            $helpParams = $help.Parameters.Parameter | ForEach-Object { $_.Name }
            
            foreach ($param in $commandParams) {
                $helpParams | Should -Contain $param
            }
        }
        
        It "Invoke-RunspaceProcessor a une documentation complète" {
            $help = Get-Help -Name Invoke-RunspaceProcessor -Full
            
            $help | Should -Not -BeNullOrEmpty
            $help.Synopsis | Should -Not -BeNullOrEmpty
            $help.Description | Should -Not -BeNullOrEmpty
            $help.Examples.Example.Count | Should -BeGreaterThan 0
            
            # Vérifier que tous les paramètres sont documentés
            $command = Get-Command -Name Invoke-RunspaceProcessor
            $commandParams = $command.Parameters.Keys | Where-Object { $_ -notin [System.Management.Automation.PSCmdlet]::CommonParameters }
            $helpParams = $help.Parameters.Parameter | ForEach-Object { $_.Name }
            
            foreach ($param in $commandParams) {
                $helpParams | Should -Contain $param
            }
        }
    }
}

AfterAll {
    # Nettoyer après tous les tests
    Clear-UnifiedParallel
}

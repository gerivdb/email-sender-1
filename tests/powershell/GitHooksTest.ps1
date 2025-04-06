# Tests unitaires pour les hooks Git
# Exécuter avec Pester : Invoke-Pester -Path .\tests\powershell\GitHooksTest.ps1

Describe "Tests des hooks Git" {
    BeforeAll {
        # Obtenir le chemin racine du projet
        $projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
        
        # Définir les chemins des scripts
        $preCommitScript = Join-Path $projectRoot "scripts\utils\git\hooks\pre-commit.ps1"
        $prePushScript = Join-Path $projectRoot "scripts\utils\git\hooks\pre-push.ps1"
        $installScript = Join-Path $projectRoot "scripts\setup\install-git-hooks.ps1"
    }
    
    Context "Vérification de l'existence des scripts" {
        It "Le script pre-commit.ps1 existe" {
            Test-Path $preCommitScript | Should -Be $true
        }
        
        It "Le script pre-push.ps1 existe" {
            Test-Path $prePushScript | Should -Be $true
        }
        
        It "Le script install-git-hooks.ps1 existe" {
            Test-Path $installScript | Should -Be $true
        }
    }
    
    Context "Vérification de la syntaxe des scripts" {
        It "Le script pre-commit.ps1 ne contient pas d'erreurs de syntaxe" {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $preCommitScript -Raw), [ref]$errors)
            $errors.Count | Should -Be 0
        }
        
        It "Le script pre-push.ps1 ne contient pas d'erreurs de syntaxe" {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $prePushScript -Raw), [ref]$errors)
            $errors.Count | Should -Be 0
        }
        
        It "Le script install-git-hooks.ps1 ne contient pas d'erreurs de syntaxe" {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $installScript -Raw), [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
    
    Context "Vérification des fonctionnalités du script pre-commit" {
        It "Le script pre-commit.ps1 peut être exécuté avec -SkipOrganize" {
            # Mock des fonctions externes
            Mock Write-Host {}
            Mock git { return @() } -ParameterFilter { $args -contains "diff" }
            
            # Exécuter le script avec -SkipOrganize pour éviter les effets de bord
            { & $preCommitScript -SkipOrganize } | Should -Not -Throw
        }
    }
    
    Context "Vérification des fonctionnalités du script pre-push" {
        It "Le script pre-push.ps1 peut être exécuté avec -SkipTests" {
            # Mock des fonctions externes
            Mock Write-Host {}
            Mock git { return @() } -ParameterFilter { $args -contains "diff" }
            
            # Exécuter le script avec -SkipTests pour éviter les effets de bord
            { & $prePushScript -SkipTests } | Should -Not -Throw
        }
    }
}

# Tests unitaires pour les hooks Git
# ExÃƒÂ©cuter avec Pester : Invoke-Pester -Path .\development\testing\tests\powershell\GitHooksTest.ps1

Describe "Tests des hooks Git" {
    BeforeAll {
        # Obtenir le chemin racine du projet
        $projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
        
        # DÃƒÂ©finir les chemins des scripts
        $preCommitScript = Join-Path $projectRoot "..\..\D"
        $prePushScript = Join-Path $projectRoot "..\..\D"
        $installScript = Join-Path $projectRoot "..\..\D"
    }
    
    Context "VÃƒÂ©rification de l'existence des scripts" {
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
    
    Context "VÃƒÂ©rification de la syntaxe des scripts" {
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
    
    Context "VÃƒÂ©rification des fonctionnalitÃƒÂ©s du script pre-commit" {
        It "Le script pre-commit.ps1 peut ÃƒÂªtre exÃƒÂ©cutÃƒÂ© avec -SkipOrganize" {
            # Mock des fonctions externes
            Mock Write-Host {}
            Mock git { return @() } -ParameterFilter { $args -contains "diff" }
            
            # ExÃƒÂ©cuter le script avec -SkipOrganize pour ÃƒÂ©viter les effets de bord
            { & $preCommitScript -SkipOrganize } | Should -Not -Throw
        }
    }
    
    Context "VÃƒÂ©rification des fonctionnalitÃƒÂ©s du script pre-push" {
        It "Le script pre-push.ps1 peut ÃƒÂªtre exÃƒÂ©cutÃƒÂ© avec -SkipTests" {
            # Mock des fonctions externes
            Mock Write-Host {}
            Mock git { return @() } -ParameterFilter { $args -contains "diff" }
            
            # ExÃƒÂ©cuter le script avec -SkipTests pour ÃƒÂ©viter les effets de bord
            { & $prePushScript -SkipTests } | Should -Not -Throw
        }
    }
}


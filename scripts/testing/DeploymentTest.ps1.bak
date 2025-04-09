# Tests unitaires pour le script de déploiement
# Exécuter avec Pester : Invoke-Pester -Path .\tests\powershell\DeploymentTest.ps1

Describe "Tests du script de déploiement" {
    BeforeAll {
        # Obtenir le chemin racine du projet
        $projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
        
        # Définir le chemin du script de déploiement
        $deployScript = Join-Path $projectRoot "..\D"
    }
    
    Context "Vérification de l'existence du script" {
        It "Le script deploy.ps1 existe" {
            Test-Path $deployScript | Should -Be $true
        }
    }
    
    Context "Vérification de la syntaxe du script" {
        It "Le script deploy.ps1 ne contient pas d'erreurs de syntaxe" {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $deployScript -Raw), [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
    
    Context "Vérification des paramètres du script" {
        BeforeAll {
            # Analyser le script pour extraire les paramètres
            $scriptContent = Get-Content $deployScript -Raw
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$null, [ref]$null)
            $paramBlock = $ast.ParamBlock
            $parameters = $paramBlock.Parameters
        }
        
        It "Le script a un paramètre Environment obligatoire" {
            $envParam = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "Environment" }
            $envParam | Should -Not -BeNullOrEmpty
            $envParam.Attributes | Where-Object { $_.TypeName.Name -eq "Parameter" -and $_.NamedArguments | Where-Object { $_.ArgumentName -eq "Mandatory" -and $_.Argument.VariablePath.UserPath -eq "true" } } | Should -Not -BeNullOrEmpty
        }
        
        It "Le paramètre Environment a des valeurs valides" {
            $envParam = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "Environment" }
            $validateSet = $envParam.Attributes | Where-Object { $_.TypeName.Name -eq "ValidateSet" }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.PositionalArguments.Count | Should -BeGreaterThan 0
        }
        
        It "Le script a un paramètre Force optionnel" {
            $forceParam = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "Force" }
            $forceParam | Should -Not -BeNullOrEmpty
            $forceParam.Attributes | Where-Object { $_.TypeName.Name -eq "Parameter" -and $_.NamedArguments | Where-Object { $_.ArgumentName -eq "Mandatory" -and $_.Argument.VariablePath.UserPath -eq "false" } } | Should -Not -BeNullOrEmpty
        }
        
        It "Le script a un paramètre SkipTests optionnel" {
            $skipTestsParam = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "SkipTests" }
            $skipTestsParam | Should -Not -BeNullOrEmpty
            $skipTestsParam.Attributes | Where-Object { $_.TypeName.Name -eq "Parameter" -and $_.NamedArguments | Where-Object { $_.ArgumentName -eq "Mandatory" -and $_.Argument.VariablePath.UserPath -eq "false" } } | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Vérification des fonctionnalités du script" {
        BeforeAll {
            # Mock des fonctions externes
            Mock Write-Host {}
            Mock Compress-Archive {}
            Mock Test-Path { return $true }
            Mock Set-Content {}
            Mock New-Item {}
            Mock Remove-Item {}
            Mock Copy-Item {}
            Mock Join-Path { return "C:\Temp\test\$($args[1])" }
            Mock Get-Date { return "2023-01-01" }
            Mock Get-Item { return [PSCustomObject]@{ Parent = [PSCustomObject]@{ Parent = [PSCustomObject]@{ FullName = "C:\Temp\test" } } } }
            Mock git { return "C:\Temp\test" }
            Mock exit {}
        }
        
        It "Le script peut être exécuté avec le paramètre Environment" {
            # Exécuter le script avec le paramètre Environment
            { & $deployScript -Environment Development -SkipTests } | Should -Not -Throw
        }
        
        It "Le script vérifie l'existence du script CI" {
            # Mock de Test-Path pour simuler l'absence du script CI
            Mock Test-Path { return $false } -ParameterFilter { $Path -like "*run-ci-checks.ps1" }
            
            # Exécuter le script
            & $deployScript -Environment Development
            
            # Vérifier que Write-Host a été appelé avec un message d'avertissement
            Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Script CI non trouvé*" }
        }
    }
}


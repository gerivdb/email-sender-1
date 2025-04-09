# Tests unitaires pour le script de dÃ©ploiement
# ExÃ©cuter avec Pester : Invoke-Pester -Path .\tests\powershell\DeploymentTest.ps1

Describe "Tests du script de dÃ©ploiement" {
    BeforeAll {
        # Obtenir le chemin racine du projet
        $projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
        
        # DÃ©finir le chemin du script de dÃ©ploiement
        $deployScript = Join-Path $projectRoot "..\D"
    }
    
    Context "VÃ©rification de l'existence du script" {
        It "Le script deploy.ps1 existe" {
            Test-Path $deployScript | Should -Be $true
        }
    }
    
    Context "VÃ©rification de la syntaxe du script" {
        It "Le script deploy.ps1 ne contient pas d'erreurs de syntaxe" {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $deployScript -Raw), [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
    
    Context "VÃ©rification des 


# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
# Tests unitaires pour le script de dÃ©ploiement
# ExÃ©cuter avec Pester : Invoke-Pester -Path .\tests\powershell\DeploymentTest.ps1

Describe "Tests du script de dÃ©ploiement" {
    BeforeAll {
        # Obtenir le chemin racine du projet
        $projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
        
        # DÃ©finir le chemin du script de dÃ©ploiement
        $deployScript = Join-Path $projectRoot "..\D"
    }
    
    Context "VÃ©rification de l'existence du script" {
        It "Le script deploy.ps1 existe" {
            Test-Path $deployScript | Should -Be $true
        }
    }
    
    Context "VÃ©rification de la syntaxe du script" {
        It "Le script deploy.ps1 ne contient pas d'erreurs de syntaxe" {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $deployScript -Raw), [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
    
    Context "VÃ©rification des paramÃ¨tres du script" {
        BeforeAll {
            # Analyser le script pour extraire les paramÃ¨tres
            $scriptContent = Get-Content $deployScript -Raw
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$null, [ref]$null)
            $paramBlock = $ast.ParamBlock
            $parameters = $paramBlock.Parameters
        }
        
        It "Le script a un paramÃ¨tre Environment obligatoire" {
            $envParam = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "Environment" }
            $envParam | Should -Not -BeNullOrEmpty
            $envParam.Attributes | Where-Object { $_.TypeName.Name -eq "Parameter" -and $_.NamedArguments | Where-Object { $_.ArgumentName -eq "Mandatory" -and $_.Argument.VariablePath.UserPath -eq "true" } } | Should -Not -BeNullOrEmpty
        }
        
        It "Le paramÃ¨tre Environment a des valeurs valides" {
            $envParam = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "Environment" }
            $validateSet = $envParam.Attributes | Where-Object { $_.TypeName.Name -eq "ValidateSet" }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.PositionalArguments.Count | Should -BeGreaterThan 0
        }
        
        It "Le script a un paramÃ¨tre Force optionnel" {
            $forceParam = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "Force" }
            $forceParam | Should -Not -BeNullOrEmpty
            $forceParam.Attributes | Where-Object { $_.TypeName.Name -eq "Parameter" -and $_.NamedArguments | Where-Object { $_.ArgumentName -eq "Mandatory" -and $_.Argument.VariablePath.UserPath -eq "false" } } | Should -Not -BeNullOrEmpty
        }
        
        It "Le script a un paramÃ¨tre SkipTests optionnel" {
            $skipTestsParam = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "SkipTests" }
            $skipTestsParam | Should -Not -BeNullOrEmpty
            $skipTestsParam.Attributes | Where-Object { $_.TypeName.Name -eq "Parameter" -and $_.NamedArguments | Where-Object { $_.ArgumentName -eq "Mandatory" -and $_.Argument.VariablePath.UserPath -eq "false" } } | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "VÃ©rification des fonctionnalitÃ©s du script" {
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
        
        It "Le script peut Ãªtre exÃ©cutÃ© avec le paramÃ¨tre Environment" {
            # ExÃ©cuter le script avec le paramÃ¨tre Environment
            { & $deployScript -Environment Development -SkipTests } | Should -Not -Throw
        }
        
        It "Le script vÃ©rifie l'existence du script CI" {
            # Mock de Test-Path pour simuler l'absence du script CI
            Mock Test-Path { return $false } -ParameterFilter { $Path -like "*run-ci-checks.ps1" }
            
            # ExÃ©cuter le script
            & $deployScript -Environment Development
            
            # VÃ©rifier que Write-Host a Ã©tÃ© appelÃ© avec un message d'avertissement
            Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Script CI non trouvÃ©*" }
        }
    }
}


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}

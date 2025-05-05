# Tests unitaires pour le script de dÃƒÂ©ploiement
# ExÃƒÂ©cuter avec Pester : Invoke-Pester -Path .\development\testing\tests\powershell\DeploymentTest.ps1

Describe "Tests du script de dÃƒÂ©ploiement" {
    BeforeAll {
        # Obtenir le chemin racine du projet
        $projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
        
        # DÃƒÂ©finir le chemin du script de dÃƒÂ©ploiement
        $deployScript = Join-Path $projectRoot "..\D"
    }
    
    Context "VÃƒÂ©rification de l'existence du script" {
        It "Le script deploy.ps1 existe" {
            Test-Path $deployScript | Should -Be $true
        }
    }
    
    Context "VÃƒÂ©rification de la syntaxe du script" {
        It "Le script deploy.ps1 ne contient pas d'erreurs de syntaxe" {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $deployScript -Raw), [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
    
    Context "VÃƒÂ©rification des 


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
    
    # Ãƒâ€°crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃƒÂ©er le rÃƒÂ©pertoire de logs si nÃƒÂ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'ÃƒÂ©criture dans le journal
    }
}
try {
    # Script principal
# Tests unitaires pour le script de dÃƒÂ©ploiement
# ExÃƒÂ©cuter avec Pester : Invoke-Pester -Path .\development\testing\tests\powershell\DeploymentTest.ps1

Describe "Tests du script de dÃƒÂ©ploiement" {
    BeforeAll {
        # Obtenir le chemin racine du projet
        $projectRoot = (Get-Item $PSScriptRoot).Parent.Parent.FullName
        
        # DÃƒÂ©finir le chemin du script de dÃƒÂ©ploiement
        $deployScript = Join-Path $projectRoot "..\D"
    }
    
    Context "VÃƒÂ©rification de l'existence du script" {
        It "Le script deploy.ps1 existe" {
            Test-Path $deployScript | Should -Be $true
        }
    }
    
    Context "VÃƒÂ©rification de la syntaxe du script" {
        It "Le script deploy.ps1 ne contient pas d'erreurs de syntaxe" {
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $deployScript -Raw), [ref]$errors)
            $errors.Count | Should -Be 0
        }
    }
    
    Context "VÃƒÂ©rification des paramÃƒÂ¨tres du script" {
        BeforeAll {
            # Analyser le script pour extraire les paramÃƒÂ¨tres
            $scriptContent = Get-Content $deployScript -Raw
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($scriptContent, [ref]$null, [ref]$null)
            $paramBlock = $ast.ParamBlock
            $parameters = $paramBlock.Parameters
        }
        
        It "Le script a un paramÃƒÂ¨tre Environment obligatoire" {
            $envParam = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "Environment" }
            $envParam | Should -Not -BeNullOrEmpty
            $envParam.Attributes | Where-Object { $_.TypeName.Name -eq "Parameter" -and $_.NamedArguments | Where-Object { $_.ArgumentName -eq "Mandatory" -and $_.Argument.VariablePath.UserPath -eq "true" } } | Should -Not -BeNullOrEmpty
        }
        
        It "Le paramÃƒÂ¨tre Environment a des valeurs valides" {
            $envParam = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "Environment" }
            $validateSet = $envParam.Attributes | Where-Object { $_.TypeName.Name -eq "ValidateSet" }
            $validateSet | Should -Not -BeNullOrEmpty
            $validateSet.PositionalArguments.Count | Should -BeGreaterThan 0
        }
        
        It "Le script a un paramÃƒÂ¨tre Force optionnel" {
            $forceParam = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "Force" }
            $forceParam | Should -Not -BeNullOrEmpty
            $forceParam.Attributes | Where-Object { $_.TypeName.Name -eq "Parameter" -and $_.NamedArguments | Where-Object { $_.ArgumentName -eq "Mandatory" -and $_.Argument.VariablePath.UserPath -eq "false" } } | Should -Not -BeNullOrEmpty
        }
        
        It "Le script a un paramÃƒÂ¨tre SkipTests optionnel" {
            $skipTestsParam = $parameters | Where-Object { $_.Name.VariablePath.UserPath -eq "SkipTests" }
            $skipTestsParam | Should -Not -BeNullOrEmpty
            $skipTestsParam.Attributes | Where-Object { $_.TypeName.Name -eq "Parameter" -and $_.NamedArguments | Where-Object { $_.ArgumentName -eq "Mandatory" -and $_.Argument.VariablePath.UserPath -eq "false" } } | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "VÃƒÂ©rification des fonctionnalitÃƒÂ©s du script" {
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
        
        It "Le script peut ÃƒÂªtre exÃƒÂ©cutÃƒÂ© avec le paramÃƒÂ¨tre Environment" {
            # ExÃƒÂ©cuter le script avec le paramÃƒÂ¨tre Environment
            { & $deployScript -Environment Development -SkipTests } | Should -Not -Throw
        }
        
        It "Le script vÃƒÂ©rifie l'existence du script CI" {
            # Mock de Test-Path pour simuler l'absence du script CI
            Mock Test-Path { return $false } -ParameterFilter { $Path -like "*run-ci-checks.ps1" }
            
            # ExÃƒÂ©cuter le script
            & $deployScript -Environment Development
            
            # VÃƒÂ©rifier que Write-Host a ÃƒÂ©tÃƒÂ© appelÃƒÂ© avec un message d'avertissement
            Assert-MockCalled Write-Host -ParameterFilter { $Object -like "*Script CI non trouvÃƒÂ©*" }
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
    Write-Log -Level INFO -Message "ExÃƒÂ©cution du script terminÃƒÂ©e."
}

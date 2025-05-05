BeforeAll {
    # Importer le module Ã  tester
    $moduleRoot = Split-Path -Parent $PSScriptRoot
    $modulePath = Join-Path -Path $moduleRoot -ChildPath "ModuleDependencyAnalyzer.psm1"
    Import-Module -Name $modulePath -Force

    # CrÃ©er un script temporaire pour les tests
    $testScriptContent = @'
#Requires -Version 5.1
#Requires -Modules @{ModuleName="PSReadLine"; ModuleVersion="2.0.0"}

# Importer des modules
Import-Module -Name PSScriptAnalyzer
Import-Module -Name Pester -RequiredVersion 5.0.0
Import-Module -Name Microsoft.PowerShell.Utility

# Utiliser un module avec using
using module PSScriptAnalyzer

# Fonction qui utilise des commandes de modules
function Test-ModuleCommands {
    param (
        [string]$Path
    )

    # Commande de PSScriptAnalyzer
    $results = Invoke-ScriptAnalyzer -Path $Path

    # Commande de Pester
    Describe "Test" {
        It "Should pass" {
            $true | Should -Be $true
        }
    }

    # Commande de Microsoft.PowerShell.Utility
    $json = ConvertTo-Json -InputObject $results

    return $json
}

# Appel de fonction
Test-ModuleCommands -Path ".\script.ps1"
'@

    $testScriptPath = Join-Path -Path $TestDrive -ChildPath "TestModules.ps1"
    Set-Content -Path $testScriptPath -Value $testScriptContent
}

Describe "Get-ModuleImportAnalysis" {
    It "Devrait analyser les imports de modules dans un script" {
        $result = Get-ModuleImportAnalysis -ScriptPath $testScriptPath
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -BeGreaterThan 0
        $result | Where-Object { $_.ModuleName -eq "PSScriptAnalyzer" } | Should -Not -BeNullOrEmpty
        $result | Where-Object { $_.ModuleName -eq "Pester" } | Should -Not -BeNullOrEmpty
    }

    It "Devrait inclure les directives #Requires si demandÃ©" {
        $result = Get-ModuleImportAnalysis -ScriptPath $testScriptPath -IncludeRequires
        $result | Should -Not -BeNullOrEmpty
        $result | Where-Object { $_.Type -eq "#Requires -Modules" -and $_.ModuleName -eq "PSReadLine" } | Should -Not -BeNullOrEmpty
    }

    It "Devrait inclure les directives using module si demandÃ©" {
        $result = Get-ModuleImportAnalysis -ScriptPath $testScriptPath -IncludeUsingModule
        $result | Should -Not -BeNullOrEmpty
        $result | Where-Object { $_.Type -eq "using module" -and $_.ModuleName -eq "PSScriptAnalyzer" } | Should -Not -BeNullOrEmpty
    }

    It "Devrait analyser le contenu du script directement" {
        $result = Get-ModuleImportAnalysis -ScriptContent $testScriptContent
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -BeGreaterThan 0
    }
}

Describe "Get-ModuleCommandUsage" {
    It "Devrait analyser les utilisations de commandes de modules dans un script" {
        $result = Get-ModuleCommandUsage -ScriptPath $testScriptPath -IncludeAllCommands
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -BeGreaterThan 0
        $result | Where-Object { $_.CommandName -eq "Invoke-ScriptAnalyzer" } | Should -Not -BeNullOrEmpty
        $result | Where-Object { $_.CommandName -eq "Describe" } | Should -Not -BeNullOrEmpty
        $result | Where-Object { $_.CommandName -eq "ConvertTo-Json" } | Should -Not -BeNullOrEmpty
    }

    It "Devrait filtrer les commandes par module si spÃ©cifiÃ©" {
        $result = Get-ModuleCommandUsage -ScriptPath $testScriptPath -ModuleNames @("PSScriptAnalyzer")
        $result | Should -Not -BeNullOrEmpty
        $result | Where-Object { $_.CommandName -eq "Invoke-ScriptAnalyzer" } | Should -Not -BeNullOrEmpty
        $result | Where-Object { $_.CommandName -eq "Describe" } | Should -BeNullOrEmpty
    }

    It "Devrait analyser le contenu du script directement" {
        $result = Get-ModuleCommandUsage -ScriptContent $testScriptContent -IncludeAllCommands
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -BeGreaterThan 0
    }
}

Describe "Compare-ModuleImportsAndUsage" {
    It "Devrait comparer les imports et les utilisations de modules" {
        $result = Compare-ModuleImportsAndUsage -ScriptPath $testScriptPath
        $result | Should -Not -BeNullOrEmpty
        $result.ImportedModules | Should -Not -BeNullOrEmpty
        $result.UsedCommands | Should -Not -BeNullOrEmpty
    }

    It "Devrait identifier les modules importÃ©s mais non utilisÃ©s" {
        # CrÃ©er un script avec un module importÃ© mais non utilisÃ©
        $unusedModuleScript = @'
Import-Module -Name PSScriptAnalyzer
# Aucune commande de PSScriptAnalyzer n'est utilisÃ©e
'@
        $unusedModuleScriptPath = Join-Path -Path $TestDrive -ChildPath "UnusedModule.ps1"
        Set-Content -Path $unusedModuleScriptPath -Value $unusedModuleScript

        $result = Compare-ModuleImportsAndUsage -ScriptPath $unusedModuleScriptPath
        $result.ImportedButNotUsed | Should -Not -BeNullOrEmpty
        $result.ImportedButNotUsed[0].ModuleName | Should -Be "PSScriptAnalyzer"
    }

    It "Devrait identifier les commandes potentiellement manquantes" {
        # CrÃ©er un script avec une commande utilisÃ©e mais dont le module n'est pas importÃ©
        $missingImportScript = @'
# Utilisation d'une commande sans importer le module
Invoke-ScriptAnalyzer -Path ".\script.ps1"
'@
        $missingImportScriptPath = Join-Path -Path $TestDrive -ChildPath "MissingImport.ps1"
        Set-Content -Path $missingImportScriptPath -Value $missingImportScript

        $result = Compare-ModuleImportsAndUsage -ScriptPath $missingImportScriptPath
        $result.PotentiallyMissingImports | Should -Not -BeNullOrEmpty
        $result.PotentiallyMissingImports[0].CommandName | Should -Be "Invoke-ScriptAnalyzer"
    }
}

Describe "New-ModuleDependencyGraph" {
    It "Devrait crÃ©er un graphe de dÃ©pendances de modules" {
        $result = New-ModuleDependencyGraph -ScriptPath $testScriptPath
        $result | Should -Not -BeNullOrEmpty
        $result.Graph | Should -Not -BeNullOrEmpty
        $scriptName = Split-Path -Path $testScriptPath -Leaf
        $result.Graph[$scriptName] | Should -Contain "PSScriptAnalyzer"
        $result.Graph[$scriptName] | Should -Contain "Pester"
    }

    It "Devrait exporter le graphe au format texte" {
        $outputPath = Join-Path -Path $TestDrive -ChildPath "modules.txt"
        New-ModuleDependencyGraph -ScriptPath $testScriptPath -OutputPath $outputPath -OutputFormat "Text"
        Test-Path -Path $outputPath | Should -Be $true
        $content = Get-Content -Path $outputPath -Raw
        $content | Should -Match "TestModules.ps1 dÃ©pend de: PSScriptAnalyzer, Pester, Microsoft.PowerShell.Utility"
    }

    It "Devrait exporter le graphe au format JSON" {
        $outputPath = Join-Path -Path $TestDrive -ChildPath "modules.json"
        New-ModuleDependencyGraph -ScriptPath $testScriptPath -OutputPath $outputPath -OutputFormat "JSON"
        Test-Path -Path $outputPath | Should -Be $true
        $content = Get-Content -Path $outputPath -Raw
        $content | Should -Match "PSScriptAnalyzer"
        $content | Should -Match "Pester"
    }

    It "Devrait exporter le graphe au format DOT" {
        $outputPath = Join-Path -Path $TestDrive -ChildPath "modules.dot"
        New-ModuleDependencyGraph -ScriptPath $testScriptPath -OutputPath $outputPath -OutputFormat "DOT"
        Test-Path -Path $outputPath | Should -Be $true
        $content = Get-Content -Path $outputPath -Raw
        $content | Should -Match "digraph ModuleDependencies"
        $content | Should -Match '"TestModules.ps1" -> "PSScriptAnalyzer"'
    }

    It "Devrait exporter le graphe au format HTML" {
        $outputPath = Join-Path -Path $TestDrive -ChildPath "modules.html"
        New-ModuleDependencyGraph -ScriptPath $testScriptPath -OutputPath $outputPath -OutputFormat "HTML"
        Test-Path -Path $outputPath | Should -Be $true
        $content = Get-Content -Path $outputPath -Raw
        $content | Should -Match "<html>"
        $content | Should -Match "TestModules.ps1"
        $content | Should -Match "PSScriptAnalyzer"
    }
}

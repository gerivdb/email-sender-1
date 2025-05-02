BeforeAll {
    # Importer le module à tester
    $moduleRoot = Split-Path -Parent $PSScriptRoot
    $modulePath = Join-Path -Path $moduleRoot -ChildPath "VariableDependencyAnalyzer.psm1"
    Import-Module -Name $modulePath -Force
    
    # Créer un script temporaire pour les tests
    $testScriptContent = @'
# Définition de variables
$var1 = "Hello"
$var2 = 42
$var3 = $var1 + " World"
$var4 = $var2 * 2

# Utilisation de variables
Write-Output $var1
Write-Output $var3

# Variable définie mais non utilisée
$unusedVar = "Je ne suis pas utilisée"

# Variable utilisée mais non définie
Write-Output $undefinedVar

# Fonction avec variables locales
function Test-Variables {
    param (
        [string]$param1,
        [int]$param2
    )
    
    $localVar1 = $param1.ToUpper()
    $localVar2 = $param2 + 10
    
    return "$localVar1 - $localVar2"
}

# Appel de la fonction
$result = Test-Variables -param1 $var1 -param2 $var2
Write-Output $result
'@
    
    $testScriptPath = Join-Path -Path $TestDrive -ChildPath "TestVariables.ps1"
    Set-Content -Path $testScriptPath -Value $testScriptContent
}

Describe "Get-VariableUsageAnalysis" {
    It "Devrait analyser les utilisations de variables dans un script" {
        $result = Get-VariableUsageAnalysis -ScriptPath $testScriptPath
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -BeGreaterThan 0
        $result | Where-Object { $_.Name -eq "var1" -and $_.Type -eq "Assignment" } | Should -Not -BeNullOrEmpty
        $result | Where-Object { $_.Name -eq "var1" -and $_.Type -eq "Usage" } | Should -Not -BeNullOrEmpty
    }
    
    It "Devrait identifier les variables définies et utilisées" {
        $result = Get-VariableUsageAnalysis -ScriptPath $testScriptPath
        $var1Assignment = $result | Where-Object { $_.Name -eq "var1" -and $_.Type -eq "Assignment" } | Select-Object -First 1
        $var1Assignment.IsDefined | Should -Be $true
        $var1Assignment.IsUsed | Should -Be $true
        
        $unusedVarAssignment = $result | Where-Object { $_.Name -eq "unusedVar" -and $_.Type -eq "Assignment" } | Select-Object -First 1
        $unusedVarAssignment.IsDefined | Should -Be $true
        $unusedVarAssignment.IsUsed | Should -Be $false
    }
    
    It "Devrait analyser le contenu du script directement" {
        $result = Get-VariableUsageAnalysis -ScriptContent $testScriptContent
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -BeGreaterThan 0
    }
}

Describe "Compare-VariableDefinitionsAndUsages" {
    It "Devrait comparer les définitions et les utilisations de variables" {
        $result = Compare-VariableDefinitionsAndUsages -ScriptPath $testScriptPath
        $result | Should -Not -BeNullOrEmpty
        $result.DefinedVariables | Should -Not -BeNullOrEmpty
        $result.UsedVariables | Should -Not -BeNullOrEmpty
    }
    
    It "Devrait identifier les variables définies mais non utilisées" {
        $result = Compare-VariableDefinitionsAndUsages -ScriptPath $testScriptPath
        $result.DefinedButNotUsed | Should -Not -BeNullOrEmpty
        $result.DefinedButNotUsed | Where-Object { $_.Name -eq "unusedVar" } | Should -Not -BeNullOrEmpty
    }
    
    It "Devrait identifier les variables utilisées mais non définies" {
        $result = Compare-VariableDefinitionsAndUsages -ScriptPath $testScriptPath
        $result.UsedButNotDefined | Should -Not -BeNullOrEmpty
        $result.UsedButNotDefined | Where-Object { $_.Name -eq "undefinedVar" } | Should -Not -BeNullOrEmpty
    }
}

Describe "New-VariableDependencyGraph" {
    It "Devrait créer un graphe de dépendances de variables" {
        $result = New-VariableDependencyGraph -ScriptPath $testScriptPath
        $result | Should -Not -BeNullOrEmpty
        $result.Graph | Should -Not -BeNullOrEmpty
        $result.Graph["var3"] | Should -Contain "var1"
    }
    
    It "Devrait exporter le graphe au format texte" {
        $outputPath = Join-Path -Path $TestDrive -ChildPath "variables.txt"
        $result = New-VariableDependencyGraph -ScriptPath $testScriptPath -OutputPath $outputPath -OutputFormat "Text"
        Test-Path -Path $outputPath | Should -Be $true
        $content = Get-Content -Path $outputPath -Raw
        $content | Should -Match "var3 dépend de: var1"
    }
    
    It "Devrait exporter le graphe au format JSON" {
        $outputPath = Join-Path -Path $TestDrive -ChildPath "variables.json"
        $result = New-VariableDependencyGraph -ScriptPath $testScriptPath -OutputPath $outputPath -OutputFormat "JSON"
        Test-Path -Path $outputPath | Should -Be $true
        $content = Get-Content -Path $outputPath -Raw
        $content | Should -Match "var3"
        $content | Should -Match "var1"
    }
    
    It "Devrait exporter le graphe au format DOT" {
        $outputPath = Join-Path -Path $TestDrive -ChildPath "variables.dot"
        $result = New-VariableDependencyGraph -ScriptPath $testScriptPath -OutputPath $outputPath -OutputFormat "DOT"
        Test-Path -Path $outputPath | Should -Be $true
        $content = Get-Content -Path $outputPath -Raw
        $content | Should -Match "digraph VariableDependencies"
        $content | Should -Match '"var3" -> "var1"'
    }
    
    It "Devrait exporter le graphe au format HTML" {
        $outputPath = Join-Path -Path $TestDrive -ChildPath "variables.html"
        $result = New-VariableDependencyGraph -ScriptPath $testScriptPath -OutputPath $outputPath -OutputFormat "HTML"
        Test-Path -Path $outputPath | Should -Be $true
        $content = Get-Content -Path $outputPath -Raw
        $content | Should -Match "<html>"
        $content | Should -Match "var3"
        $content | Should -Match "var1"
    }
}

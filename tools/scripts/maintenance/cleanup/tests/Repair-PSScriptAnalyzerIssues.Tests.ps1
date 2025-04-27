#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Repair-PSScriptAnalyzerIssues.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement
    des fonctions de correction du script Repair-PSScriptAnalyzerIssues.ps1.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

# Chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Repair-PSScriptAnalyzerIssues.ps1"

# VÃ©rifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Ã  tester n'existe pas: $scriptPath"
}

# Importer le script Ã  tester
. $scriptPath

# Importer Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installÃ©. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSScriptAnalyzerTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Tests unitaires
Describe "Repair-PSScriptAnalyzerIssues" {
    BeforeAll {
        # CrÃ©er des fichiers de test
        $nullComparisonScript = @'
function Test-NullComparison {
    param($value)

    if ($value -eq $null) {
        return $true
    }

    return $false
}
'@
        $nullComparisonPath = Join-Path -Path $testDir -ChildPath "NullComparison.ps1"
        Set-Content -Path $nullComparisonPath -Value $nullComparisonScript -Force

        $unapprovedVerbScript = @'
function Fix-Problem {
    param($issue)

    # Corriger le problÃ¨me
    return "Fixed: $issue"
}

function Analyze-Data {
    param($data)

    # Analyser les donnÃ©es
    return "Analyzed: $data"
}
'@
        $unapprovedVerbPath = Join-Path -Path $testDir -ChildPath "UnapprovedVerb.ps1"
        Set-Content -Path $unapprovedVerbPath -Value $unapprovedVerbScript -Force

        $switchDefaultValueScript = @'
function Test-SwitchDefault {
    param(
        [switch]$Force = $true,
        [switch]$Verbose = $true
    )

    # Faire quelque chose
    return "Force: $Force, Verbose: $Verbose"
}
'@
        $switchDefaultValuePath = Join-Path -Path $testDir -ChildPath "SwitchDefaultValue.ps1"
        Set-Content -Path $switchDefaultValuePath -Value $switchDefaultValueScript -Force

        $unusedVariableScript = @'
function Test-UnusedVariable {
    # Variable non utilisÃ©e
    $unused = "Cette variable n'est jamais utilisÃ©e"

    # Variable utilisÃ©e
    $used = "Cette variable est utilisÃ©e"
    return $used
}
'@
        $unusedVariablePath = Join-Path -Path $testDir -ChildPath "UnusedVariable.ps1"
        Set-Content -Path $unusedVariablePath -Value $unusedVariableScript -Force

        $automaticVariableScript = @'
function Test-AutomaticVariable {
    # Assignation Ã  une variable automatique
    $matches = @{
        "Key1" = "Value1"
        "Key2" = "Value2"
    }

    # Utilisation de la variable
    return $matches["Key1"]
}
'@
        $automaticVariablePath = Join-Path -Path $testDir -ChildPath "AutomaticVariable.ps1"
        Set-Content -Path $automaticVariablePath -Value $automaticVariableScript -Force
    }

    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }

    Context "Test-ScriptIssues Function" {
        It "Devrait analyser un script et retourner des rÃ©sultats" {
            $results = Test-ScriptIssues -Path $nullComparisonPath
            $results | Should -Not -BeNullOrEmpty
            $results.PSScriptAnalyzerResults | Should -Not -BeNullOrEmpty
            $results.Ast | Should -Not -BeNullOrEmpty
            $results.Tokens | Should -Not -BeNullOrEmpty
            $results.Content | Should -Not -BeNullOrEmpty
        }

        It "Devrait retourner null pour un chemin invalide" {
            $results = Test-ScriptIssues -Path "CheminInvalide.ps1" -ErrorAction SilentlyContinue
            $results | Should -BeNullOrEmpty
        }
    }

    Context "Repair-NullComparison Function" {
        It "Devrait corriger les comparaisons incorrectes avec `$null" {
            $content = Get-Content -Path $nullComparisonPath -Raw
            $correctedContent = Repair-NullComparison -Content $content

            # VÃ©rifier que la correction a Ã©tÃ© appliquÃ©e
            $correctedContent | Should -Match '\$null -eq \$value'
            $correctedContent | Should -Not -Match '\$value -eq \$null'
        }
    }

    Context "Repair-UnapprovedVerbs Function" {
        It "Devrait corriger les verbes non approuvÃ©s" {
            $content = Get-Content -Path $unapprovedVerbPath -Raw
            $correctedContent = Repair-UnapprovedVerbs -Content $content

            # VÃ©rifier que les corrections ont Ã©tÃ© appliquÃ©es
            $correctedContent | Should -Match 'function Repair-Problem'
            $correctedContent | Should -Match 'function Test-Data'
            $correctedContent | Should -Not -Match 'function Fix-Problem'
            $correctedContent | Should -Not -Match 'function Analyze-Data'
        }
    }

    Context "Repair-SwitchDefaultValue Function" {
        It "Devrait corriger les valeurs par dÃ©faut des paramÃ¨tres de type switch" {
            $content = Get-Content -Path $switchDefaultValuePath -Raw
            $correctedContent = Repair-SwitchDefaultValue -Content $content

            # VÃ©rifier que les corrections ont Ã©tÃ© appliquÃ©es
            $correctedContent | Should -Match '\[switch\]\$Force'
            $correctedContent | Should -Match '\[switch\]\$Verbose'
            $correctedContent | Should -Not -Match '\[switch\]\$Force = \$true'
            $correctedContent | Should -Not -Match '\[switch\]\$Verbose = \$true'
        }
    }

    Context "Repair-UnusedVariables Function" {
        It "Devrait corriger les variables non utilisÃ©es" {
            $content = Get-Content -Path $unusedVariablePath -Raw
            $analysisResults = Test-ScriptIssues -Path $unusedVariablePath
            $correctedContent = Repair-UnusedVariables -Content $content -Ast $analysisResults.Ast -Tokens $analysisResults.Tokens

            # VÃ©rifier que les corrections ont Ã©tÃ© appliquÃ©es
            $correctedContent | Should -Not -Match '\$unused = "Cette variable n''est jamais utilisÃ©e"'
            $correctedContent | Should -Match '"Cette variable n''est jamais utilisÃ©e" \| Out-Null'
            $correctedContent | Should -Match '\$used = "Cette variable est utilisÃ©e"'
        }
    }

    Context "Repair-AutomaticVariableAssignment Function" {
        It "Devrait corriger les assignations aux variables automatiques" {
            $content = Get-Content -Path $automaticVariablePath -Raw
            $correctedContent = Repair-AutomaticVariableAssignment -Content $content

            # VÃ©rifier que les corrections ont Ã©tÃ© appliquÃ©es
            $correctedContent | Should -Match '\$custom_matches = @{'
            $correctedContent | Should -Match 'return \$custom_matches\["Key1"\]'
            $correctedContent | Should -Not -Match '\$matches = @{'
            $correctedContent | Should -Not -Match 'return \$matches\["Key1"\]'
        }
    }

    Context "Repair-PSScriptAnalyzerIssues Function" {
        It "Devrait analyser et corriger les problÃ¨mes dans un script" {
            # CrÃ©er une copie du script pour le test
            $testScriptPath = Join-Path -Path $testDir -ChildPath "TestScript.ps1"
            Copy-Item -Path $nullComparisonPath -Destination $testScriptPath -Force

            # ExÃ©cuter la fonction principale
            $results = Repair-PSScriptAnalyzerIssues -ScriptPath $testScriptPath -Fix

            # VÃ©rifier les rÃ©sultats
            $results | Should -Not -BeNullOrEmpty
            $results.Path | Should -Be $testScriptPath
            $results.Fixed | Should -BeTrue

            # VÃ©rifier que le contenu a Ã©tÃ© corrigÃ©
            $correctedContent = Get-Content -Path $testScriptPath -Raw
            $correctedContent | Should -Match '\$null -eq \$value'
            $correctedContent | Should -Not -Match '\$value -eq \$null'
        }

        It "Devrait analyser sans corriger si Fix n'est pas spÃ©cifiÃ©" {
            # CrÃ©er une copie du script pour le test
            $testScriptPath = Join-Path -Path $testDir -ChildPath "TestScriptNoFix.ps1"
            Copy-Item -Path $nullComparisonPath -Destination $testScriptPath -Force

            # ExÃ©cuter la fonction principale sans Fix
            $results = Repair-PSScriptAnalyzerIssues -ScriptPath $testScriptPath

            # VÃ©rifier les rÃ©sultats
            $results | Should -Not -BeNullOrEmpty
            $results.Path | Should -Be $testScriptPath
            $results.Fixed | Should -BeFalse

            # VÃ©rifier que le contenu n'a pas Ã©tÃ© corrigÃ©
            $content = Get-Content -Path $testScriptPath -Raw
            $content | Should -Match '\$value -eq \$null'
            $content | Should -Not -Match '\$null -eq \$value'
        }

        It "Devrait crÃ©er une sauvegarde si CreateBackup est spÃ©cifiÃ©" {
            # CrÃ©er une copie du script pour le test
            $testScriptPath = Join-Path -Path $testDir -ChildPath "TestScriptWithBackup.ps1"
            Copy-Item -Path $nullComparisonPath -Destination $testScriptPath -Force

            # ExÃ©cuter la fonction principale avec CreateBackup
            $results = Repair-PSScriptAnalyzerIssues -ScriptPath $testScriptPath -Fix -CreateBackup

            # VÃ©rifier les rÃ©sultats
            $results | Should -Not -BeNullOrEmpty
            $results.Fixed | Should -BeTrue

            # VÃ©rifier que la sauvegarde a Ã©tÃ© crÃ©Ã©e
            $backupPath = "$testScriptPath.bak"
            Test-Path -Path $backupPath | Should -BeTrue

            # VÃ©rifier que le contenu de la sauvegarde est l'original
            $backupContent = Get-Content -Path $backupPath -Raw
            $backupContent | Should -Match '\$value -eq \$null'
            $backupContent | Should -Not -Match '\$null -eq \$value'
        }
    }
}

# ExÃ©cuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed

#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Repair-PSScriptAnalyzerIssues.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    des fonctions de correction du script Repair-PSScriptAnalyzerIssues.ps1.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

# Chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Repair-PSScriptAnalyzerIssues.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script à tester n'existe pas: $scriptPath"
}

# Importer le script à tester
. $scriptPath

# Importer Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "PSScriptAnalyzerTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Tests unitaires
Describe "Repair-PSScriptAnalyzerIssues" {
    BeforeAll {
        # Créer des fichiers de test
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

    # Corriger le problème
    return "Fixed: $issue"
}

function Analyze-Data {
    param($data)

    # Analyser les données
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
    # Variable non utilisée
    $unused = "Cette variable n'est jamais utilisée"

    # Variable utilisée
    $used = "Cette variable est utilisée"
    return $used
}
'@
        $unusedVariablePath = Join-Path -Path $testDir -ChildPath "UnusedVariable.ps1"
        Set-Content -Path $unusedVariablePath -Value $unusedVariableScript -Force

        $automaticVariableScript = @'
function Test-AutomaticVariable {
    # Assignation à une variable automatique
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
        It "Devrait analyser un script et retourner des résultats" {
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

            # Vérifier que la correction a été appliquée
            $correctedContent | Should -Match '\$null -eq \$value'
            $correctedContent | Should -Not -Match '\$value -eq \$null'
        }
    }

    Context "Repair-UnapprovedVerbs Function" {
        It "Devrait corriger les verbes non approuvés" {
            $content = Get-Content -Path $unapprovedVerbPath -Raw
            $correctedContent = Repair-UnapprovedVerbs -Content $content

            # Vérifier que les corrections ont été appliquées
            $correctedContent | Should -Match 'function Repair-Problem'
            $correctedContent | Should -Match 'function Test-Data'
            $correctedContent | Should -Not -Match 'function Fix-Problem'
            $correctedContent | Should -Not -Match 'function Analyze-Data'
        }
    }

    Context "Repair-SwitchDefaultValue Function" {
        It "Devrait corriger les valeurs par défaut des paramètres de type switch" {
            $content = Get-Content -Path $switchDefaultValuePath -Raw
            $correctedContent = Repair-SwitchDefaultValue -Content $content

            # Vérifier que les corrections ont été appliquées
            $correctedContent | Should -Match '\[switch\]\$Force'
            $correctedContent | Should -Match '\[switch\]\$Verbose'
            $correctedContent | Should -Not -Match '\[switch\]\$Force = \$true'
            $correctedContent | Should -Not -Match '\[switch\]\$Verbose = \$true'
        }
    }

    Context "Repair-UnusedVariables Function" {
        It "Devrait corriger les variables non utilisées" {
            $content = Get-Content -Path $unusedVariablePath -Raw
            $analysisResults = Test-ScriptIssues -Path $unusedVariablePath
            $correctedContent = Repair-UnusedVariables -Content $content -Ast $analysisResults.Ast -Tokens $analysisResults.Tokens

            # Vérifier que les corrections ont été appliquées
            $correctedContent | Should -Not -Match '\$unused = "Cette variable n''est jamais utilisée"'
            $correctedContent | Should -Match '"Cette variable n''est jamais utilisée" \| Out-Null'
            $correctedContent | Should -Match '\$used = "Cette variable est utilisée"'
        }
    }

    Context "Repair-AutomaticVariableAssignment Function" {
        It "Devrait corriger les assignations aux variables automatiques" {
            $content = Get-Content -Path $automaticVariablePath -Raw
            $correctedContent = Repair-AutomaticVariableAssignment -Content $content

            # Vérifier que les corrections ont été appliquées
            $correctedContent | Should -Match '\$custom_matches = @{'
            $correctedContent | Should -Match 'return \$custom_matches\["Key1"\]'
            $correctedContent | Should -Not -Match '\$matches = @{'
            $correctedContent | Should -Not -Match 'return \$matches\["Key1"\]'
        }
    }

    Context "Repair-PSScriptAnalyzerIssues Function" {
        It "Devrait analyser et corriger les problèmes dans un script" {
            # Créer une copie du script pour le test
            $testScriptPath = Join-Path -Path $testDir -ChildPath "TestScript.ps1"
            Copy-Item -Path $nullComparisonPath -Destination $testScriptPath -Force

            # Exécuter la fonction principale
            $results = Repair-PSScriptAnalyzerIssues -ScriptPath $testScriptPath -Fix

            # Vérifier les résultats
            $results | Should -Not -BeNullOrEmpty
            $results.Path | Should -Be $testScriptPath
            $results.Fixed | Should -BeTrue

            # Vérifier que le contenu a été corrigé
            $correctedContent = Get-Content -Path $testScriptPath -Raw
            $correctedContent | Should -Match '\$null -eq \$value'
            $correctedContent | Should -Not -Match '\$value -eq \$null'
        }

        It "Devrait analyser sans corriger si Fix n'est pas spécifié" {
            # Créer une copie du script pour le test
            $testScriptPath = Join-Path -Path $testDir -ChildPath "TestScriptNoFix.ps1"
            Copy-Item -Path $nullComparisonPath -Destination $testScriptPath -Force

            # Exécuter la fonction principale sans Fix
            $results = Repair-PSScriptAnalyzerIssues -ScriptPath $testScriptPath

            # Vérifier les résultats
            $results | Should -Not -BeNullOrEmpty
            $results.Path | Should -Be $testScriptPath
            $results.Fixed | Should -BeFalse

            # Vérifier que le contenu n'a pas été corrigé
            $content = Get-Content -Path $testScriptPath -Raw
            $content | Should -Match '\$value -eq \$null'
            $content | Should -Not -Match '\$null -eq \$value'
        }

        It "Devrait créer une sauvegarde si CreateBackup est spécifié" {
            # Créer une copie du script pour le test
            $testScriptPath = Join-Path -Path $testDir -ChildPath "TestScriptWithBackup.ps1"
            Copy-Item -Path $nullComparisonPath -Destination $testScriptPath -Force

            # Exécuter la fonction principale avec CreateBackup
            $results = Repair-PSScriptAnalyzerIssues -ScriptPath $testScriptPath -Fix -CreateBackup

            # Vérifier les résultats
            $results | Should -Not -BeNullOrEmpty
            $results.Fixed | Should -BeTrue

            # Vérifier que la sauvegarde a été créée
            $backupPath = "$testScriptPath.bak"
            Test-Path -Path $backupPath | Should -BeTrue

            # Vérifier que le contenu de la sauvegarde est l'original
            $backupContent = Get-Content -Path $backupPath -Raw
            $backupContent | Should -Match '\$value -eq \$null'
            $backupContent | Should -Not -Match '\$null -eq \$value'
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed

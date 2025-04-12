#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Inspect-ScriptPreventively.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    du script Inspect-ScriptPreventively.ps1 qui analyse et corrige les problèmes
    dans les scripts PowerShell.
.NOTES
    Author: Augment Agent
    Version: 1.0
    Date: 12/04/2025
#>

# Chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\Inspect-ScriptPreventively.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script à tester n'existe pas: $scriptPath"
}

# Importer Pester
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $env:TEMP -ChildPath "ScriptPreventivelyTests"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Tests unitaires
Describe "Inspect-ScriptPreventively" {
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
        
        $writeHostScript = @'
function Test-WriteHost {
    param($message)
    
    # Utilisation de Write-Host
    Write-Host "Message: $message" -ForegroundColor Green
    
    return "Message traité: $message"
}
'@
        $writeHostPath = Join-Path -Path $testDir -ChildPath "WriteHost.ps1"
        Set-Content -Path $writeHostPath -Value $writeHostScript -Force
        
        $pluralNounScript = @'
function Get-Users {
    # Fonction avec un nom pluriel
    return @("User1", "User2", "User3")
}
'@
        $pluralNounPath = Join-Path -Path $testDir -ChildPath "PluralNoun.ps1"
        Set-Content -Path $pluralNounPath -Value $pluralNounScript -Force
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }
    
    Context "Analyse de scripts" {
        It "Devrait détecter les comparaisons incorrectes avec `$null" {
            $results = & $scriptPath -Path $nullComparisonPath
            $nullComparisonIssues = $results | Where-Object { $_.RuleName -eq "PSPossibleIncorrectComparisonWithNull" }
            $nullComparisonIssues | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait détecter les variables non utilisées" {
            $results = & $scriptPath -Path $unusedVariablePath
            $unusedVarIssues = $results | Where-Object { $_.RuleName -eq "PSUseDeclaredVarsMoreThanAssignments" }
            $unusedVarIssues | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait détecter l'utilisation de Write-Host" {
            $results = & $scriptPath -Path $writeHostPath
            $writeHostIssues = $results | Where-Object { $_.RuleName -eq "PSAvoidUsingWriteHost" }
            $writeHostIssues | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait détecter les noms pluriels" {
            $results = & $scriptPath -Path $pluralNounPath
            $pluralNounIssues = $results | Where-Object { $_.RuleName -eq "PSUseSingularNouns" }
            $pluralNounIssues | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Correction de scripts" {
        It "Devrait corriger les comparaisons incorrectes avec `$null" {
            # Créer une copie du script pour le test
            $testScriptPath = Join-Path -Path $testDir -ChildPath "NullComparisonFix.ps1"
            Copy-Item -Path $nullComparisonPath -Destination $testScriptPath -Force
            
            # Exécuter le script avec l'option Fix
            & $scriptPath -Path $testScriptPath -Fix
            
            # Vérifier que le contenu a été corrigé
            $content = Get-Content -Path $testScriptPath -Raw
            $content | Should -Match '\$null -eq \$value'
            $content | Should -Not -Match '\$value -eq \$null'
        }
        
        It "Devrait corriger les variables non utilisées" {
            # Créer une copie du script pour le test
            $testScriptPath = Join-Path -Path $testDir -ChildPath "UnusedVariableFix.ps1"
            Copy-Item -Path $unusedVariablePath -Destination $testScriptPath -Force
            
            # Exécuter le script avec l'option Fix
            & $scriptPath -Path $testScriptPath -Fix
            
            # Vérifier que le contenu a été corrigé
            $content = Get-Content -Path $testScriptPath -Raw
            $content | Should -Not -Match '\$unused = "Cette variable n''est jamais utilisée"'
            $content | Should -Match '"Cette variable n''est jamais utilisée" \| Out-Null'
        }
        
        It "Devrait créer une sauvegarde du fichier original" {
            # Créer une copie du script pour le test
            $testScriptPath = Join-Path -Path $testDir -ChildPath "BackupTest.ps1"
            Copy-Item -Path $nullComparisonPath -Destination $testScriptPath -Force
            
            # Exécuter le script avec l'option Fix
            & $scriptPath -Path $testScriptPath -Fix
            
            # Vérifier que la sauvegarde a été créée
            $backupPath = "$testScriptPath.bak"
            Test-Path -Path $backupPath | Should -BeTrue
            
            # Vérifier que le contenu de la sauvegarde est l'original
            $backupContent = Get-Content -Path $backupPath -Raw
            $backupContent | Should -Match '\$value -eq \$null'
            $backupContent | Should -Not -Match '\$null -eq \$value'
        }
    }
    
    Context "Options de filtrage" {
        It "Devrait filtrer par sévérité" {
            $results = & $scriptPath -Path $nullComparisonPath -Severity Error
            $results | Should -BeNullOrEmpty
            
            $results = & $scriptPath -Path $nullComparisonPath -Severity Warning
            $results | Should -Not -BeNullOrEmpty
        }
        
        It "Devrait filtrer par règle incluse" {
            $results = & $scriptPath -Path $nullComparisonPath -IncludeRule PSPossibleIncorrectComparisonWithNull
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -Be 1
            $results[0].RuleName | Should -Be "PSPossibleIncorrectComparisonWithNull"
        }
        
        It "Devrait filtrer par règle exclue" {
            $results = & $scriptPath -Path $nullComparisonPath -ExcludeRule PSPossibleIncorrectComparisonWithNull
            $results | Where-Object { $_.RuleName -eq "PSPossibleIncorrectComparisonWithNull" } | Should -BeNullOrEmpty
        }
    }
    
    Context "Analyse récursive" {
        It "Devrait analyser récursivement les scripts dans un dossier" {
            $results = & $scriptPath -Path $testDir -Recurse
            $results | Should -Not -BeNullOrEmpty
            $results.Count | Should -BeGreaterThan 3
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed

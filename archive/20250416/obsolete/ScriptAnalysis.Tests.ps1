<#
.SYNOPSIS
    Tests unitaires pour les scripts d'analyse et de correction des erreurs.
.DESCRIPTION
    Ce script contient des tests unitaires pour les scripts d'analyse et de correction des erreurs.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Définir les tests Pester
Describe "Tests des scripts d'analyse et de correction des erreurs" {
    BeforeAll {
        # Définir le chemin des scripts à tester
        $script:moduleRoot = Split-Path -Path $PSScriptRoot -Parent
        $script:analyzeScriptPath = Join-Path -Path $script:moduleRoot -ChildPath "Analyze-ScriptForErrors.Simplified.ps1"
        $script:autoCorrectPath = Join-Path -Path $script:moduleRoot -ChildPath "Auto-CorrectErrors.Simplified.ps1"

        # Créer un répertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "ScriptAnalysisTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null

        # Créer un script de test avec des erreurs
        $script:testScriptPath = Join-Path -Path $script:testRoot -ChildPath "TestScript.ps1"
        $testScriptContent = @"
# Script de test avec plusieurs problèmes
`$logPath = "D:\Logs\app.log"
Write-Host "Log Path: `$logPath"

# Absence de gestion d'erreurs
`$content = Get-Content -Path "C:\config.txt"

# Utilisation de cmdlet obsolète
`$processes = Get-WmiObject -Class Win32_Process
"@
        Set-Content -Path $script:testScriptPath -Value $testScriptContent -Force
    }

    Context "Analyse de script" {
        It "Devrait détecter les erreurs dans un script" {
            # Exécuter le script d'analyse
            $output = & $script:analyzeScriptPath -ScriptPath $script:testScriptPath -ErrorAction SilentlyContinue 6>&1
            $outputString = $output -join "`n"

            # Vérifier que des erreurs sont détectées
            $outputString | Should -Match "Analyse du script"
            $outputString | Should -Match "Erreurs détectées"
            $outputString | Should -Match "HardcodedPath"
            $outputString | Should -Match "WriteHostUsage"
            $outputString | Should -Match "NoErrorHandling"
            $outputString | Should -Match "ObsoleteCmdlet"
        }
    }

    Context "Correction automatique des erreurs" {
        It "Devrait corriger les erreurs dans un script" {
            # Créer une copie du script de test
            $scriptToFix = Join-Path -Path $script:testRoot -ChildPath "TestScript_ToFix.ps1"
            Copy-Item -Path $script:testScriptPath -Destination $scriptToFix -Force

            # Exécuter le script de correction
            $output = & $script:autoCorrectPath -ScriptPath $scriptToFix -ApplyCorrections -ErrorAction SilentlyContinue 6>&1
            $outputString = $output -join "`n"

            # Vérifier que des corrections sont appliquées
            $outputString | Should -Match "Analyse du script"
            $outputString | Should -Match "Erreurs détectées"

            # Vérifier que le script est corrigé
            $fixedContent = Get-Content -Path $scriptToFix -Raw
            $fixedContent | Should -Not -Match "D:\\Logs\\app.log"
            $fixedContent | Should -Match "Join-Path"
            $fixedContent | Should -Not -Match "Write-Host"
            $fixedContent | Should -Match "Write-Output"
            $fixedContent | Should -Match "Get-Content.*-ErrorAction Stop"
            $fixedContent | Should -Not -Match "Get-WmiObject"
            $fixedContent | Should -Match "Get-CimInstance"
        }
    }

    AfterAll {
        # Supprimer le répertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }
}

<#
.SYNOPSIS
    Tests unitaires pour les scripts de traitement avec Jobs PowerShell.
.DESCRIPTION
    Ce script contient des tests unitaires pour les scripts de traitement avec Jobs PowerShell.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Définir les tests Pester
Describe "Tests des scripts de traitement avec Jobs PowerShell" {
    BeforeAll {
        # Définir le chemin des scripts à tester
        $script:moduleRoot = Split-Path -Path $PSScriptRoot -Parent
        $script:analyzeJobsPath = Join-Path -Path $script:moduleRoot -ChildPath "Analyze-ScriptsWithJobs.ps1"
        $script:correctJobsPath = Join-Path -Path $script:moduleRoot -ChildPath "Auto-CorrectErrorsWithJobs.ps1"
        
        # Créer un répertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "JobsProcessingTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        
        # Créer plusieurs scripts de test avec des erreurs
        $script:testScripts = @()
        
        for ($i = 1; $i -le 5; $i++) {
            $scriptPath = Join-Path -Path $script:testRoot -ChildPath "TestScript$i.ps1"
            $testScriptContent = @"
# Script de test $i avec plusieurs problèmes
`$logPath = "D:\Logs\app$i.log"
Write-Host "Log Path: `$logPath"

# Absence de gestion d'erreurs
`$content = Get-Content -Path "C:\config$i.txt"

# Utilisation de cmdlet obsolète
`$processes = Get-WmiObject -Class Win32_Process
"@
            Set-Content -Path $scriptPath -Value $testScriptContent -Force
            $script:testScripts += $scriptPath
        }
    }
    
    Context "Analyse avec Jobs" {
        It "Devrait analyser plusieurs scripts avec des Jobs PowerShell" {
            # Exécuter le script d'analyse avec Jobs
            $output = & $script:analyzeJobsPath -ScriptPaths $script:testScripts -MaxJobs 3 -ErrorAction SilentlyContinue 6>&1
            $outputString = $output -join "`n"
            
            # Vérifier que l'analyse a été effectuée
            $outputString | Should -Match "Analyse de 5 scripts en parallèle"
            $outputString | Should -Match "Scripts analysés : 5"
            $outputString | Should -Match "Total des problèmes détectés"
            
            # Vérifier que les types de problèmes sont détectés
            $outputString | Should -Match "HardcodedPath"
            $outputString | Should -Match "WriteHostUsage"
            $outputString | Should -Match "NoErrorHandling"
            $outputString | Should -Match "ObsoleteCmdlet"
        }
    }
    
    Context "Correction avec Jobs" {
        It "Devrait corriger plusieurs scripts avec des Jobs PowerShell en mode WhatIf" {
            # Exécuter le script de correction avec Jobs en mode WhatIf
            $output = & $script:correctJobsPath -ScriptPaths $script:testScripts -MaxJobs 3 -WhatIf -ErrorAction SilentlyContinue 6>&1
            $outputString = $output -join "`n"
            
            # Vérifier que la simulation a été effectuée
            $outputString | Should -Match "Correction de 5 scripts en parallèle"
            $outputString | Should -Match "Scripts traités : 5"
            $outputString | Should -Match "Total des problèmes détectés"
            $outputString | Should -Match "WhatIf:"
            
            # Vérifier que les fichiers originaux n'ont pas été modifiés
            $originalContent = Get-Content -Path $script:testScripts[0] -Raw
            $originalContent | Should -Match "D:\\Logs\\app1.log"
            $originalContent | Should -Match "Write-Host"
            $originalContent | Should -Match "Get-Content -Path"
            $originalContent | Should -Match "Get-WmiObject"
        }
        
        It "Devrait corriger plusieurs scripts avec des Jobs PowerShell" {
            # Exécuter le script de correction avec Jobs
            $output = & $script:correctJobsPath -ScriptPaths $script:testScripts -MaxJobs 3 -ErrorAction SilentlyContinue 6>&1
            $outputString = $output -join "`n"
            
            # Vérifier que la correction a été effectuée
            $outputString | Should -Match "Correction de 5 scripts en parallèle"
            $outputString | Should -Match "Scripts traités : 5"
            $outputString | Should -Match "Total des problèmes détectés"
            $outputString | Should -Match "Total des corrections appliquées"
            
            # Vérifier que les fichiers ont été modifiés
            $correctedContent = Get-Content -Path $script:testScripts[0] -Raw
            $correctedContent | Should -Not -Match "D:\\Logs\\app1.log"
            $correctedContent | Should -Match "Join-Path"
            $correctedContent | Should -Not -Match "Write-Host"
            $correctedContent | Should -Match "Write-Output"
            $correctedContent | Should -Match "Get-Content -Path.*-ErrorAction Stop"
            $correctedContent | Should -Not -Match "Get-WmiObject"
            $correctedContent | Should -Match "Get-CimInstance"
        }
    }
    
    AfterAll {
        # Supprimer le répertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }
}

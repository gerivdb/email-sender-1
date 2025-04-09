<#
.SYNOPSIS
    Tests unitaires pour le script Auto-CorrectErrors.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Auto-CorrectErrors
    en utilisant le framework Pester.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Vérifier si Pester est installé
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Importer Pester
Import-Module Pester -Force

# Définir le chemin du script à tester
$scriptRoot = Split-Path -Path $PSScriptRoot -Parent
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "Auto-CorrectErrors.ps1"
$modulePath = Join-Path -Path $scriptRoot -ChildPath "ErrorLearningSystem.psm1"

# Créer un répertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "AutoCorrectErrorsTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# Définir les tests Pester
Describe "Script Auto-CorrectErrors" {
    BeforeAll {
        # Importer le module ErrorLearningSystem
        Import-Module $modulePath -Force
        
        # Initialiser le module
        Initialize-ErrorLearningSystem
        
        # Créer des scripts de test avec différents problèmes
        $testScripts = @{
            "SyntaxError" = @{
                Path = Join-Path -Path $testRoot -ChildPath "SyntaxError.ps1"
                Content = @"
# Script avec une erreur de syntaxe
if (`$true) {
    Write-Output "Test"
# Accolade fermante manquante
"@
            }
            "HardcodedPath" = @{
                Path = Join-Path -Path $testRoot -ChildPath "HardcodedPath.ps1"
                Content = @"
# Script avec un chemin codé en dur
`$logPath = "D:\Logs\app.log"
Write-Output "Log Path: `$logPath"
"@
            }
            "UndeclaredVariable" = @{
                Path = Join-Path -Path $testRoot -ChildPath "UndeclaredVariable.ps1"
                Content = @"
# Script avec une variable non déclarée
`$undeclaredVar = "Test"
Write-Output "Variable: `$undeclaredVar"
"@
            }
            "NoErrorHandling" = @{
                Path = Join-Path -Path $testRoot -ChildPath "NoErrorHandling.ps1"
                Content = @"
# Script sans gestion d'erreurs
`$content = Get-Content -Path "C:\config.txt"
Write-Output "Content: `$content"
"@
            }
            "WriteHostUsage" = @{
                Path = Join-Path -Path $testRoot -ChildPath "WriteHostUsage.ps1"
                Content = @"
# Script utilisant Write-Host
Write-Host "Message de test"
"@
            }
            "ObsoleteCmdlet" = @{
                Path = Join-Path -Path $testRoot -ChildPath "ObsoleteCmdlet.ps1"
                Content = @"
# Script utilisant une cmdlet obsolète
`$processes = Get-WmiObject -Class Win32_Process
Write-Output "Processes: `$(`$processes.Count)"
"@
            }
            "MultipleIssues" = @{
                Path = Join-Path -Path $testRoot -ChildPath "MultipleIssues.ps1"
                Content = @"
# Script avec plusieurs problèmes
`$logPath = "D:\Logs\app.log"
Write-Host "Log Path: `$logPath"
`$processes = Get-WmiObject -Class Win32_Process
`$content = Get-Content -Path "C:\config.txt"
"@
            }
        }
        
        # Créer les fichiers de test
        foreach ($script in $testScripts.GetEnumerator()) {
            Set-Content -Path $script.Value.Path -Value $script.Value.Content -Force
        }
        
        # Créer des erreurs dans la base de données pour les tests
        # Erreur de syntaxe
        $exception = New-Object System.Exception("Accolade fermante manquante")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "SyntaxError",
            [System.Management.Automation.ErrorCategory]::SyntaxError,
            $null
        )
        Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "SyntaxError" -Solution "Ajouter l'accolade fermante manquante"
        
        # Chemin codé en dur
        $exception = New-Object System.Exception("Chemin codé en dur détecté")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "HardcodedPath",
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )
        Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "HardcodedPath" -Solution "Remplacer le chemin codé en dur par un chemin relatif"
        
        # Variable non déclarée
        $exception = New-Object System.Exception("Variable non déclarée")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "UndeclaredVariable",
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )
        Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "UndeclaredVariable" -Solution "Déclarer la variable avec un type"
        
        # Absence de gestion d'erreurs
        $exception = New-Object System.Exception("Absence de gestion d'erreurs")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "NoErrorHandling",
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )
        Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "NoErrorHandling" -Solution "Ajouter un bloc try/catch ou utiliser -ErrorAction Stop"
        
        # Utilisation de Write-Host
        $exception = New-Object System.Exception("Utilisation de Write-Host")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "WriteHostUsage",
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )
        Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "WriteHostUsage" -Solution "Remplacer Write-Host par Write-Output"
        
        # Utilisation de cmdlet obsolète
        $exception = New-Object System.Exception("Utilisation de cmdlet obsolète")
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "ObsoleteCmdlet",
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $null
        )
        Register-PowerShellError -ErrorRecord $errorRecord -Source "UnitTest" -Category "ObsoleteCmdlet" -Solution "Remplacer Get-WmiObject par Get-CimInstance"
    }
    
    Context "Détection des erreurs" {
        It "Devrait détecter une erreur de syntaxe" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["SyntaxError"].Path -ErrorAction SilentlyContinue 6>&1
            
            # Vérifier que l'erreur de syntaxe est détectée
            $output | Should -Match "SyntaxError"
        }
        
        It "Devrait détecter un chemin codé en dur" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["HardcodedPath"].Path -ErrorAction SilentlyContinue 6>&1
            
            # Vérifier que le chemin codé en dur est détecté
            $output | Should -Match "HardcodedPath"
            $output | Should -Match "D:\\Logs\\app.log"
        }
        
        It "Devrait détecter une variable non déclarée" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["UndeclaredVariable"].Path -ErrorAction SilentlyContinue 6>&1
            
            # Vérifier que la variable non déclarée est détectée
            $output | Should -Match "UndeclaredVariable"
            $output | Should -Match "`$undeclaredVar"
        }
        
        It "Devrait détecter l'absence de gestion d'erreurs" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["NoErrorHandling"].Path -ErrorAction SilentlyContinue 6>&1
            
            # Vérifier que l'absence de gestion d'erreurs est détectée
            $output | Should -Match "NoErrorHandling"
            $output | Should -Match "Get-Content"
        }
        
        It "Devrait détecter l'utilisation de Write-Host" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["WriteHostUsage"].Path -ErrorAction SilentlyContinue 6>&1
            
            # Vérifier que l'utilisation de Write-Host est détectée
            $output | Should -Match "WriteHostUsage"
            $output | Should -Match "Write-Host"
        }
        
        It "Devrait détecter l'utilisation d'une cmdlet obsolète" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["ObsoleteCmdlet"].Path -ErrorAction SilentlyContinue 6>&1
            
            # Vérifier que l'utilisation d'une cmdlet obsolète est détectée
            $output | Should -Match "ObsoleteCmdlet"
            $output | Should -Match "Get-WmiObject"
        }
        
        It "Devrait détecter plusieurs problèmes dans un même script" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["MultipleIssues"].Path -ErrorAction SilentlyContinue 6>&1
            
            # Vérifier que plusieurs problèmes sont détectés
            $output | Should -Match "HardcodedPath"
            $output | Should -Match "WriteHostUsage"
            $output | Should -Match "ObsoleteCmdlet"
            $output | Should -Match "NoErrorHandling"
        }
    }
    
    Context "Suggestions de correction" {
        It "Devrait suggérer des corrections pour une erreur de syntaxe" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["SyntaxError"].Path -ErrorAction SilentlyContinue 6>&1
            
            # Vérifier que des suggestions sont proposées
            $output | Should -Match "Suggestions de correction"
            $output | Should -Match "Ajouter l'accolade fermante manquante"
        }
        
        It "Devrait suggérer des corrections pour un chemin codé en dur" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["HardcodedPath"].Path -ErrorAction SilentlyContinue 6>&1
            
            # Vérifier que des suggestions sont proposées
            $output | Should -Match "Suggestions de correction"
            $output | Should -Match "Remplacer le chemin codé en dur par un chemin relatif"
        }
    }
    
    Context "Application des corrections" {
        It "Devrait corriger un chemin codé en dur" {
            # Copier le script de test
            $scriptToCopy = $testScripts["HardcodedPath"].Path
            $scriptToFix = Join-Path -Path $testRoot -ChildPath "HardcodedPath_ToFix.ps1"
            Copy-Item -Path $scriptToCopy -Destination $scriptToFix -Force
            
            # Exécuter le script d'analyse avec correction
            & $scriptPath -ScriptPath $scriptToFix -ApplyCorrections -ErrorAction SilentlyContinue
            
            # Vérifier que le script est corrigé
            $fixedContent = Get-Content -Path $scriptToFix -Raw
            $fixedContent | Should -Not -Match "D:\\Logs\\app.log"
            $fixedContent | Should -Match "Join-Path"
        }
        
        It "Devrait corriger l'utilisation de Write-Host" {
            # Copier le script de test
            $scriptToCopy = $testScripts["WriteHostUsage"].Path
            $scriptToFix = Join-Path -Path $testRoot -ChildPath "WriteHostUsage_ToFix.ps1"
            Copy-Item -Path $scriptToCopy -Destination $scriptToFix -Force
            
            # Exécuter le script d'analyse avec correction
            & $scriptPath -ScriptPath $scriptToFix -ApplyCorrections -ErrorAction SilentlyContinue
            
            # Vérifier que le script est corrigé
            $fixedContent = Get-Content -Path $scriptToFix -Raw
            $fixedContent | Should -Match "Write-Output"
            $fixedContent | Should -Not -Match "Write-Host"
        }
        
        It "Devrait corriger l'utilisation d'une cmdlet obsolète" {
            # Copier le script de test
            $scriptToCopy = $testScripts["ObsoleteCmdlet"].Path
            $scriptToFix = Join-Path -Path $testRoot -ChildPath "ObsoleteCmdlet_ToFix.ps1"
            Copy-Item -Path $scriptToCopy -Destination $scriptToFix -Force
            
            # Exécuter le script d'analyse avec correction
            & $scriptPath -ScriptPath $scriptToFix -ApplyCorrections -ErrorAction SilentlyContinue
            
            # Vérifier que le script est corrigé
            $fixedContent = Get-Content -Path $scriptToFix -Raw
            $fixedContent | Should -Match "Get-CimInstance"
            $fixedContent | Should -Not -Match "Get-WmiObject"
        }
        
        It "Devrait corriger l'absence de gestion d'erreurs" {
            # Copier le script de test
            $scriptToCopy = $testScripts["NoErrorHandling"].Path
            $scriptToFix = Join-Path -Path $testRoot -ChildPath "NoErrorHandling_ToFix.ps1"
            Copy-Item -Path $scriptToCopy -Destination $scriptToFix -Force
            
            # Exécuter le script d'analyse avec correction
            & $scriptPath -ScriptPath $scriptToFix -ApplyCorrections -ErrorAction SilentlyContinue
            
            # Vérifier que le script est corrigé
            $fixedContent = Get-Content -Path $scriptToFix -Raw
            $fixedContent | Should -Match "Get-Content.*-ErrorAction Stop"
        }
    }
    
    Context "Génération de rapport" {
        It "Devrait générer un rapport pour un script avec des problèmes" {
            # Définir le chemin du rapport
            $reportPath = Join-Path -Path $testRoot -ChildPath "corrections.md"
            
            # Exécuter le script d'analyse avec génération de rapport
            & $scriptPath -ScriptPath $testScripts["MultipleIssues"].Path -GenerateReport -ReportPath $reportPath -ErrorAction SilentlyContinue
            
            # Vérifier que le rapport est généré
            Test-Path -Path $reportPath | Should -BeTrue
            
            # Vérifier le contenu du rapport
            $reportContent = Get-Content -Path $reportPath -Raw
            $reportContent | Should -Match "Rapport de corrections automatiques"
            $reportContent | Should -Match "HardcodedPath"
            $reportContent | Should -Match "WriteHostUsage"
            $reportContent | Should -Match "ObsoleteCmdlet"
            $reportContent | Should -Match "NoErrorHandling"
        }
    }
    
    AfterAll {
        # Nettoyer
        Remove-Module -Name ErrorLearningSystem -Force -ErrorAction SilentlyContinue
        
        # Supprimer le répertoire de test
        if (Test-Path -Path $testRoot) {
            Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Exécuter les tests
Invoke-Pester -Path $PSCommandPath -Output Detailed

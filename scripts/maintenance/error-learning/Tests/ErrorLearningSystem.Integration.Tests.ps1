<#
.SYNOPSIS
    Tests d'intégration pour le système d'apprentissage des erreurs PowerShell.
.DESCRIPTION
    Ce script contient des tests d'intégration pour le système d'apprentissage des erreurs PowerShell.
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

# Définir le chemin du module à tester
$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
$modulePath = Join-Path -Path $moduleRoot -ChildPath "ErrorLearningSystem.psm1"
$analyzeScriptPath = Join-Path -Path $moduleRoot -ChildPath "Analyze-ScriptForErrors.ps1"
$autoCorrectPath = Join-Path -Path $moduleRoot -ChildPath "Auto-CorrectErrors.ps1"
$adaptiveErrorCorrectionPath = Join-Path -Path $moduleRoot -ChildPath "Adaptive-ErrorCorrection.ps1"
$validateErrorCorrectionsPath = Join-Path -Path $moduleRoot -ChildPath "Validate-ErrorCorrections.ps1"

# Créer un répertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "ErrorLearningSystemIntegrationTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# Définir les tests Pester
Describe "Tests d'intégration du système d'apprentissage des erreurs" {
    BeforeAll {
        # Importer le module à tester
        Import-Module $modulePath -Force
        
        # Initialiser le module avec un chemin personnalisé pour les tests
        $script:ErrorDatabasePath = Join-Path -Path $testRoot -ChildPath "error-database.json"
        $script:ErrorLogsPath = Join-Path -Path $testRoot -ChildPath "logs"
        $script:ErrorPatternsPath = Join-Path -Path $testRoot -ChildPath "patterns"
        
        # Initialiser le système
        Initialize-ErrorLearningSystem -Force
        
        # Créer un script de test avec des erreurs
        $testScriptPath = Join-Path -Path $testRoot -ChildPath "TestScript.ps1"
        $testScriptContent = @"
# Script de test avec plusieurs problèmes
`$logPath = "D:\Logs\app.log"
Write-Host "Log Path: `$logPath"

# Absence de gestion d'erreurs
`$content = Get-Content -Path "C:\config.txt"

# Utilisation de cmdlet obsolète
`$processes = Get-WmiObject -Class Win32_Process

# Erreur de syntaxe
if (`$true) {
    Write-Output "Test"
# Accolade fermante manquante
"@
        Set-Content -Path $testScriptPath -Value $testScriptContent -Force
    }
    
    Context "Enregistrement et analyse des erreurs" {
        It "Devrait enregistrer une erreur avec succès" {
            # Créer une erreur factice
            $exception = New-Object System.Exception("Erreur de test")
            $errorRecord = New-Object System.Management.Automation.ErrorRecord(
                $exception,
                "TestError",
                [System.Management.Automation.ErrorCategory]::NotSpecified,
                $null
            )
            
            # Enregistrer l'erreur
            $errorId = Register-PowerShellError -ErrorRecord $errorRecord -Source "IntegrationTest" -Category "TestCategory"
            
            # Vérifier que l'erreur a été enregistrée
            $errorId | Should -Not -BeNullOrEmpty
            
            # Analyser les erreurs
            $analysisResult = Get-PowerShellErrorAnalysis -IncludeStatistics
            
            # Vérifier le résultat
            $analysisResult | Should -Not -BeNullOrEmpty
            $analysisResult.Errors | Should -Not -BeNullOrEmpty
            $analysisResult.Errors.Count | Should -BeGreaterOrEqual 1
            $analysisResult.Statistics | Should -Not -BeNullOrEmpty
            $analysisResult.Statistics.TotalErrors | Should -BeGreaterOrEqual 1
        }
    }
    
    Context "Analyse de script et correction d'erreurs" {
        It "Devrait analyser un script et détecter des problèmes" {
            # Vérifier que le script d'analyse existe
            Test-Path -Path $analyzeScriptPath | Should -BeTrue
            
            # Exécuter le script d'analyse (si le script existe)
            if (Test-Path -Path $analyzeScriptPath) {
                $output = & $analyzeScriptPath -ScriptPath $testScriptPath -ErrorAction SilentlyContinue 6>&1
                
                # Vérifier que des problèmes sont détectés
                $output | Should -Match "Chemin codé en dur"
                $output | Should -Match "Utilisation de Write-Host"
                $output | Should -Match "Absence de gestion d'erreurs"
                $output | Should -Match "Utilisation de cmdlets obsolètes"
            }
        }
        
        It "Devrait corriger automatiquement les erreurs dans un script" {
            # Vérifier que le script de correction existe
            Test-Path -Path $autoCorrectPath | Should -BeTrue
            
            # Copier le script de test
            $scriptToFix = Join-Path -Path $testRoot -ChildPath "TestScript_ToFix.ps1"
            Copy-Item -Path $testScriptPath -Destination $scriptToFix -Force
            
            # Exécuter le script de correction (si le script existe)
            if (Test-Path -Path $autoCorrectPath) {
                & $autoCorrectPath -ScriptPath $scriptToFix -ApplyCorrections -ErrorAction SilentlyContinue
                
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
    }
    
    Context "Apprentissage adaptatif et validation des corrections" {
        It "Devrait générer un modèle de correction" {
            # Vérifier que le script d'apprentissage adaptatif existe
            Test-Path -Path $adaptiveErrorCorrectionPath | Should -BeTrue
            
            # Définir le chemin du modèle
            $modelPath = Join-Path -Path $testRoot -ChildPath "correction-model.json"
            
            # Exécuter le script d'apprentissage adaptatif (si le script existe)
            if (Test-Path -Path $adaptiveErrorCorrectionPath) {
                & $adaptiveErrorCorrectionPath -TrainingMode -ModelPath $modelPath -ErrorAction SilentlyContinue
                
                # Vérifier que le modèle est généré
                Test-Path -Path $modelPath | Should -BeTrue
                
                # Vérifier le contenu du modèle
                $modelContent = Get-Content -Path $modelPath -Raw | ConvertFrom-Json
                $modelContent.Metadata | Should -Not -BeNullOrEmpty
                $modelContent.Patterns | Should -Not -BeNullOrEmpty
            }
        }
        
        It "Devrait valider les corrections d'un script" {
            # Vérifier que le script de validation existe
            Test-Path -Path $validateErrorCorrectionsPath | Should -BeTrue
            
            # Créer un script valide
            $validScriptPath = Join-Path -Path $testRoot -ChildPath "ValidScript.ps1"
            $validScriptContent = @"
# Script valide
function Get-TestData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Path
    )
    
    try {
        `$content = Get-Content -Path `$Path -ErrorAction Stop
        return `$content
    }
    catch {
        Write-Error "Erreur lors de la lecture du fichier: `$_"
        return `$null
    }
}

# Appeler la fonction
`$logPath = Join-Path -Path `$PSScriptRoot -ChildPath "logs\app.log"
`$data = Get-TestData -Path `$logPath
Write-Output "Données chargées: `$(`$data.Count) lignes"
"@
            Set-Content -Path $validScriptPath -Value $validScriptContent -Force
            
            # Exécuter le script de validation (si le script existe)
            if (Test-Path -Path $validateErrorCorrectionsPath) {
                $output = & $validateErrorCorrectionsPath -ScriptPath $validScriptPath -ErrorAction SilentlyContinue 6>&1
                
                # Vérifier que la syntaxe est validée
                $output | Should -Match "La syntaxe du script est valide"
            }
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

# Ne pas exécuter les tests automatiquement pour éviter la récursion infinie
# # # # # Invoke-Pester -Path $PSCommandPath -Output Detailed # Commenté pour éviter la récursion infinie # Commenté pour éviter la récursion infinie # Commenté pour éviter la récursion infinie # Commenté pour éviter la récursion infinie




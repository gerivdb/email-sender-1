<#
.SYNOPSIS
    Tests unitaires pour le script Analyze-ScriptForErrors.
.DESCRIPTION
    Ce script contient des tests unitaires pour le script Analyze-ScriptForErrors
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
$scriptPath = Join-Path -Path $scriptRoot -ChildPath "Analyze-ScriptForErrors.ps1"
$modulePath = Join-Path -Path $scriptRoot -ChildPath "ErrorLearningSystem.psm1"

# Créer un répertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "AnalyzeScriptTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# Définir les tests Pester
Describe "Script Analyze-ScriptForErrors" {
    BeforeAll {
        # Importer le module ErrorLearningSystem
        Import-Module $modulePath -Force

        # Initialiser le module
        Initialize-ErrorLearningSystem

        # Créer des scripts de test avec différents problèmes
        $testScripts = @{
            "HardcodedPaths" = @{
                Path = Join-Path -Path $testRoot -ChildPath "HardcodedPaths.ps1"
                Content = @"
# Script avec des chemins codés en dur
`$logPath = "D:\Logs\app.log"
`$configPath = "C:\Program Files\App\config.xml"
Write-Host "Log Path: `$logPath"
Write-Host "Config Path: `$configPath"
"@
            }
            "NoErrorHandling" = @{
                Path = Join-Path -Path $testRoot -ChildPath "NoErrorHandling.ps1"
                Content = @"
# Script sans gestion d'erreurs
`$content = Get-Content -Path "C:\config.txt"
`$result = Invoke-RestMethod -Uri "https://api.example.com"
New-Item -Path "C:\temp\test.txt" -ItemType File
"@
            }
            "WriteHostUsage" = @{
                Path = Join-Path -Path $testRoot -ChildPath "WriteHostUsage.ps1"
                Content = @"
# Script utilisant Write-Host
Write-Host "Message 1"
Write-Host "Message 2" -ForegroundColor Red
Write-Host "Message 3" -BackgroundColor Blue
"@
            }
            "ObsoleteCmdlets" = @{
                Path = Join-Path -Path $testRoot -ChildPath "ObsoleteCmdlets.ps1"
                Content = @"
# Script utilisant des cmdlets obsolètes
`$processes = Get-WmiObject -Class Win32_Process
`$result = Invoke-Expression "Get-Process"
"@
            }
            "CleanScript" = @{
                Path = Join-Path -Path $testRoot -ChildPath "CleanScript.ps1"
                Content = @"
# Script propre sans problèmes
function Get-CleanData {
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
`$data = Get-CleanData -Path "`$PSScriptRoot\data.txt"
Write-Output "Données chargées: `$(`$data.Count) lignes"
"@
            }
        }

        # Créer les fichiers de test
        foreach ($script in $testScripts.GetEnumerator()) {
            Set-Content -Path $script.Value.Path -Value $script.Value.Content -Force
        }
    }

    Context "Détection des problèmes" {
        It "Devrait détecter les chemins codés en dur" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["HardcodedPaths"].Path -ErrorAction SilentlyContinue 6>&1

            # Vérifier que les chemins codés en dur sont détectés
            $output | Should -Match "Chemin codé en dur"
            $output | Should -Match "D:\\Logs\\app.log"
            $output | Should -Match "C:\\Program Files\\App\\config.xml"
        }

        It "Devrait détecter l'absence de gestion d'erreurs" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["NoErrorHandling"].Path -ErrorAction SilentlyContinue 6>&1

            # Vérifier que l'absence de gestion d'erreurs est détectée
            $output | Should -Match "Absence de gestion d'erreurs"
            $output | Should -Match "Get-Content"
            $output | Should -Match "Invoke-RestMethod"
            $output | Should -Match "New-Item"
        }

        It "Devrait détecter l'utilisation de Write-Host" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["WriteHostUsage"].Path -ErrorAction SilentlyContinue 6>&1

            # Vérifier que l'utilisation de Write-Host est détectée
            $output | Should -Match "Utilisation de Write-Host"
            $output | Should -Match "Write-Host"
        }

        It "Devrait détecter l'utilisation de cmdlets obsolètes" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["ObsoleteCmdlets"].Path -ErrorAction SilentlyContinue 6>&1

            # Vérifier que l'utilisation de cmdlets obsolètes est détectée
            $output | Should -Match "Utilisation de cmdlets obsolètes"
            $output | Should -Match "Get-WmiObject"
            $output | Should -Match "Invoke-Expression"
        }

        It "Ne devrait pas détecter de problèmes dans un script propre" {
            # Exécuter le script d'analyse
            $output = & $scriptPath -ScriptPath $testScripts["CleanScript"].Path -ErrorAction SilentlyContinue 6>&1

            # Vérifier qu'aucun problème n'est détecté
            $output | Should -Match "Aucun problème potentiel détecté"
        }
    }

    Context "Génération de rapport" {
        It "Devrait générer un rapport pour un script avec des problèmes" {
            # Définir le chemin du rapport
            $reportPath = Join-Path -Path $testRoot -ChildPath "report.md"

            # Exécuter le script d'analyse avec génération de rapport
            & $scriptPath -ScriptPath $testScripts["HardcodedPaths"].Path -GenerateReport -ReportPath $reportPath -ErrorAction SilentlyContinue

            # Vérifier que le rapport est généré
            Test-Path -Path $reportPath | Should -BeTrue

            # Vérifier le contenu du rapport
            $reportContent = Get-Content -Path $reportPath -Raw
            $reportContent | Should -Match "Rapport d'analyse de script"
            $reportContent | Should -Match "Chemin codé en dur"
        }
    }

    Context "Correction des erreurs" {
        It "Devrait corriger les chemins codés en dur" {
            # Copier le script de test
            $scriptToCopy = $testScripts["HardcodedPaths"].Path
            $scriptToFix = Join-Path -Path $testRoot -ChildPath "HardcodedPaths_ToFix.ps1"
            Copy-Item -Path $scriptToCopy -Destination $scriptToFix -Force

            # Exécuter le script d'analyse avec correction
            & $scriptPath -ScriptPath $scriptToFix -FixErrors -ErrorAction SilentlyContinue

            # Vérifier que le script est corrigé
            $fixedContent = Get-Content -Path $scriptToFix -Raw
            $fixedContent | Should -Not -Match "D:\\Logs\\app.log"
            $fixedContent | Should -Match "Join-Path"
        }

        It "Devrait corriger l'absence de gestion d'erreurs" {
            # Copier le script de test
            $scriptToCopy = $testScripts["NoErrorHandling"].Path
            $scriptToFix = Join-Path -Path $testRoot -ChildPath "NoErrorHandling_ToFix.ps1"
            Copy-Item -Path $scriptToCopy -Destination $scriptToFix -Force

            # Exécuter le script d'analyse avec correction
            & $scriptPath -ScriptPath $scriptToFix -FixErrors -ErrorAction SilentlyContinue

            # Vérifier que le script est corrigé
            $fixedContent = Get-Content -Path $scriptToFix -Raw
            $fixedContent | Should -Match "Get-Content.*-ErrorAction Stop"
            $fixedContent | Should -Match "Invoke-RestMethod.*-ErrorAction Stop"
            $fixedContent | Should -Match "New-Item.*-ErrorAction Stop"
        }

        It "Devrait corriger l'utilisation de Write-Host" {
            # Copier le script de test
            $scriptToCopy = $testScripts["WriteHostUsage"].Path
            $scriptToFix = Join-Path -Path $testRoot -ChildPath "WriteHostUsage_ToFix.ps1"
            Copy-Item -Path $scriptToCopy -Destination $scriptToFix -Force

            # Exécuter le script d'analyse avec correction
            & $scriptPath -ScriptPath $scriptToFix -FixErrors -ErrorAction SilentlyContinue

            # Vérifier que le script est corrigé
            $fixedContent = Get-Content -Path $scriptToFix -Raw
            $fixedContent | Should -Match "Write-Output"
            $fixedContent | Should -Not -Match "Write-Host"
        }

        It "Devrait corriger l'utilisation de cmdlets obsolètes" {
            # Copier le script de test
            $scriptToCopy = $testScripts["ObsoleteCmdlets"].Path
            $scriptToFix = Join-Path -Path $testRoot -ChildPath "ObsoleteCmdlets_ToFix.ps1"
            Copy-Item -Path $scriptToCopy -Destination $scriptToFix -Force

            # Exécuter le script d'analyse avec correction
            & $scriptPath -ScriptPath $scriptToFix -FixErrors -ErrorAction SilentlyContinue

            # Vérifier que le script est corrigé
            $fixedContent = Get-Content -Path $scriptToFix -Raw
            $fixedContent | Should -Match "Get-CimInstance"
            $fixedContent | Should -Not -Match "Get-WmiObject"
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
# Invoke-Pester -Path $PSCommandPath -Output Detailed

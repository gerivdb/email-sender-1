<#
.SYNOPSIS
    Tests pour le script debug-mode.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires et d'intégration pour le script debug-mode.ps1
    qui implémente le mode DEBUG pour isoler, comprendre et corriger les anomalies dans le code.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

# Importer Pester si disponible
if (Get-Module -ListAvailable -Name Pester) {
    Import-Module Pester
} else {
    Write-Warning "Le module Pester n'est pas installé. Les tests ne seront pas exécutés avec le framework Pester."
}

# Chemin vers le script à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent (Split-Path -Parent $scriptPath)
$projectRoot = Split-Path -Parent (Split-Path -Parent $modulePath)
$debugModePath = Join-Path -Path $projectRoot -ChildPath "debug-mode.ps1"

# Chemin vers les fonctions à tester
$invokeDebugPath = Join-Path -Path $modulePath -ChildPath "Functions\Public\Invoke-RoadmapDebug.ps1"

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $debugModePath)) {
    Write-Warning "Le script debug-mode.ps1 est introuvable à l'emplacement : $debugModePath"
}

if (-not (Test-Path -Path $invokeDebugPath)) {
    Write-Warning "Le fichier Invoke-RoadmapDebug.ps1 est introuvable à l'emplacement : $invokeDebugPath"
}

# Importer les fonctions si elles existent
if (Test-Path -Path $invokeDebugPath) {
    . $invokeDebugPath
    Write-Host "Fonction Invoke-RoadmapDebug importée." -ForegroundColor Green
}

# Créer un fichier temporaire pour les tests
$testFilePath = Join-Path -Path $env:TEMP -ChildPath "TestRoadmap_$(Get-Random).md"

# Créer un fichier de test avec une structure de roadmap simple
@"
# Roadmap de test

## Section 1

- [ ] **1.1** Correction de bugs
  - [ ] **1.1.1** Corriger le bug de référence nulle
  - [ ] **1.1.2** Résoudre le problème de performance
- [ ] **1.2** Améliorations
  - [ ] **1.2.1** Optimiser l'algorithme
  - [ ] **1.2.2** Améliorer l'interface utilisateur

## Section 2

- [ ] **2.1** Tests de régression
"@ | Set-Content -Path $testFilePath -Encoding UTF8

Write-Host "Fichier de roadmap créé : $testFilePath" -ForegroundColor Green

# Créer des répertoires temporaires pour les tests
$testModulePath = Join-Path -Path $env:TEMP -ChildPath "TestModule_$(Get-Random)"
$testOutputPath = Join-Path -Path $env:TEMP -ChildPath "TestOutput_$(Get-Random)"
$testErrorLogPath = Join-Path -Path $env:TEMP -ChildPath "TestErrorLog_$(Get-Random).log"

# Créer la structure du module de test
New-Item -Path $testModulePath -ItemType Directory -Force | Out-Null
New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null

# Créer un fichier de code avec un bug pour les tests
@"
function Process-Data {
    param (
        [Parameter(Mandatory = `$true)]
        [object]`$Data
    )
    
    # Bug: Accès à une propriété sans vérifier si l'objet est null
    `$result = `$Data.Value.ToString()
    
    return `$result
}
"@ | Set-Content -Path (Join-Path -Path $testModulePath -ChildPath "BuggyFunction.ps1") -Encoding UTF8

# Créer un fichier de log d'erreur
@"
[ERROR] 2023-08-15T10:15:30 - NullReferenceException in Process-Data: Object reference not set to an instance of an object.
   at Process-Data, D:\Path\To\BuggyFunction.ps1: line 8
   at CallSite.Target(Closure , CallSite , Object )
Stack trace:
   at Process-Data(`$Data = null)
   at Invoke-ProcessData(`$InputData = null)
   at Main()
"@ | Set-Content -Path $testErrorLogPath -Encoding UTF8

Write-Host "Module de test créé : $testModulePath" -ForegroundColor Green
Write-Host "Fichier de log d'erreur créé : $testErrorLogPath" -ForegroundColor Green
Write-Host "Répertoire de sortie créé : $testOutputPath" -ForegroundColor Green

# Tests unitaires avec Pester
Describe "Invoke-RoadmapDebug" {
    BeforeEach {
        # Préparation avant chaque test
    }

    AfterEach {
        # Nettoyage après chaque test
    }

    It "Devrait exécuter correctement avec des paramètres valides" {
        # Appeler la fonction
        if (Get-Command -Name Invoke-RoadmapDebug -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDebug -ErrorLog $testErrorLogPath -ModulePath $testModulePath -OutputPath $testOutputPath
            $result | Should -Not -BeNullOrEmpty
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDebug n'est pas disponible"
        }
    }

    It "Devrait lever une exception si le fichier de log n'existe pas" {
        # Appeler la fonction avec un fichier inexistant
        if (Get-Command -Name Invoke-RoadmapDebug -ErrorAction SilentlyContinue) {
            { Invoke-RoadmapDebug -ErrorLog "FichierInexistant.log" -ModulePath $testModulePath -OutputPath $testOutputPath } | Should -Throw
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDebug n'est pas disponible"
        }
    }

    It "Devrait identifier correctement l'origine de l'erreur" {
        # Appeler la fonction et vérifier l'identification de l'erreur
        if (Get-Command -Name Invoke-RoadmapDebug -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDebug -ErrorLog $testErrorLogPath -ModulePath $testModulePath -OutputPath $testOutputPath
            
            # Vérifier que l'origine de l'erreur est correctement identifiée
            $result.ErrorOrigin | Should -Be "Process-Data"
            $result.ErrorType | Should -Be "NullReferenceException"
            $result.ErrorLine | Should -Be 8
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDebug n'est pas disponible"
        }
    }

    It "Devrait générer un rapport de débogage" {
        # Appeler la fonction et vérifier la génération du rapport
        if (Get-Command -Name Invoke-RoadmapDebug -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDebug -ErrorLog $testErrorLogPath -ModulePath $testModulePath -OutputPath $testOutputPath -GeneratePatch $true
            
            # Vérifier que le rapport est généré
            $debugReportPath = Join-Path -Path $testOutputPath -ChildPath "debug_report.md"
            Test-Path -Path $debugReportPath | Should -Be $true
            
            # Vérifier que le contenu du rapport contient les informations attendues
            $reportContent = Get-Content -Path $debugReportPath -Raw
            $reportContent | Should -Match "NullReferenceException"
            $reportContent | Should -Match "Process-Data"
            $reportContent | Should -Match "BuggyFunction.ps1"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDebug n'est pas disponible"
        }
    }

    It "Devrait générer un patch correctif" {
        # Appeler la fonction et vérifier la génération du patch
        if (Get-Command -Name Invoke-RoadmapDebug -ErrorAction SilentlyContinue) {
            $result = Invoke-RoadmapDebug -ErrorLog $testErrorLogPath -ModulePath $testModulePath -OutputPath $testOutputPath -GeneratePatch $true
            
            # Vérifier que le patch est généré
            $patchPath = Join-Path -Path $testOutputPath -ChildPath "fix_patch.ps1"
            Test-Path -Path $patchPath | Should -Be $true
            
            # Vérifier que le contenu du patch contient la correction attendue
            $patchContent = Get-Content -Path $patchPath -Raw
            $patchContent | Should -Match "if \(`\$null -ne `\$Data\.Value\)"
        } else {
            Set-ItResult -Skipped -Because "La fonction Invoke-RoadmapDebug n'est pas disponible"
        }
    }
}

# Test d'intégration du script debug-mode.ps1
Describe "debug-mode.ps1 Integration" {
    It "Devrait s'exécuter correctement avec des paramètres valides" {
        if (Test-Path -Path $debugModePath) {
            # Exécuter le script
            $output = & $debugModePath -ErrorLog $testErrorLogPath -ModulePath $testModulePath -OutputPath $testOutputPath -GeneratePatch $true
            
            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0
            
            # Vérifier que les fichiers attendus existent
            $debugReportPath = Join-Path -Path $testOutputPath -ChildPath "debug_report.md"
            Test-Path -Path $debugReportPath | Should -Be $true
            
            $patchPath = Join-Path -Path $testOutputPath -ChildPath "fix_patch.ps1"
            Test-Path -Path $patchPath | Should -Be $true
        } else {
            Set-ItResult -Skipped -Because "Le script debug-mode.ps1 n'est pas disponible"
        }
    }
}

# Nettoyage
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de roadmap supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testModulePath) {
    Remove-Item -Path $testModulePath -Recurse -Force
    Write-Host "Module de test supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testErrorLogPath) {
    Remove-Item -Path $testErrorLogPath -Force
    Write-Host "Fichier de log d'erreur supprimé." -ForegroundColor Gray
}

if (Test-Path -Path $testOutputPath) {
    Remove-Item -Path $testOutputPath -Recurse -Force
    Write-Host "Répertoire de sortie supprimé." -ForegroundColor Gray
}

# Exécuter les tests si Pester est disponible
if (Get-Command -Name Invoke-Pester -ErrorAction SilentlyContinue) {
    Invoke-Pester -Path $MyInvocation.MyCommand.Path
} else {
    Write-Host "Tests terminés. Utilisez Invoke-Pester pour exécuter les tests avec le framework Pester." -ForegroundColor Yellow
}

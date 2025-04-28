#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Test-RepoStructure.ps1
.DESCRIPTION
    Ce script contient des tests unitaires pour valider le bon fonctionnement
    du script Test-RepoStructure.ps1 qui vérifie la conformité de la structure
    du dépôt avec le standard défini.
.EXAMPLE
    Invoke-Pester -Path .\Test-RepoStructureUnit.ps1
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-26
#>

# Importer le module Pester s'il n'est pas déjà chargé
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\maintenance\repo\Test-RepoStructure.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Test-RepoStructure.ps1 n'existe pas à l'emplacement spécifié: $scriptPath"
}

Describe "Test-RepoStructure" {
    BeforeAll {
        # Créer un dossier temporaire pour les tests
        $testRoot = Join-Path -Path $TestDrive -ChildPath "TestRepo"
        New-Item -Path $testRoot -ItemType Directory -Force | Out-Null
        
        # Créer quelques dossiers et fichiers pour les tests
        $validFolders = @(
            "scripts",
            "modules",
            "docs",
            "tests"
        )
        
        foreach ($folder in $validFolders) {
            New-Item -Path (Join-Path -Path $testRoot -ChildPath $folder) -ItemType Directory -Force | Out-Null
        }
        
        # Créer des fichiers avec différentes conventions de nommage
        $validFiles = @(
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\Get-Data.ps1"
                Content = "# Valid PowerShell script"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\utils\script_utils.py"
                Content = "# Valid Python script"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\setup\setup-environment.cmd"
                Content = "REM Valid Batch script"
            }
        )
        
        foreach ($file in $validFiles) {
            $fileDir = Split-Path -Path $file.Path -Parent
            if (-not (Test-Path -Path $fileDir)) {
                New-Item -Path $fileDir -ItemType Directory -Force | Out-Null
            }
            
            Set-Content -Path $file.Path -Value $file.Content -Encoding UTF8
        }
        
        # Créer des fichiers non conformes
        $invalidFiles = @(
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\invalidScript.ps1"
                Content = "# Invalid PowerShell script name"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\InvalidPython.py"
                Content = "# Invalid Python script name"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\Setup File.cmd"
                Content = "REM Invalid Batch script name"
            }
        )
        
        foreach ($file in $invalidFiles) {
            $fileDir = Split-Path -Path $file.Path -Parent
            if (-not (Test-Path -Path $fileDir)) {
                New-Item -Path $fileDir -ItemType Directory -Force | Out-Null
            }
            
            Set-Content -Path $file.Path -Value $file.Content -Encoding UTF8
        }
    }
    
    Context "Validation de la structure des dossiers" {
        It "Détecte les dossiers principaux manquants" {
            # Exécuter le script avec le dossier de test
            $result = & $scriptPath -Path $testRoot -ReportPath "report.md"
            
            # Vérifier que les dossiers manquants sont détectés
            $result.MissingMainFolders | Should -Not -BeNullOrEmpty
            $result.MissingMainFolders | Should -Contain "config"
            $result.MissingMainFolders | Should -Contain "assets"
            $result.MissingMainFolders | Should -Contain "tools"
        }
        
        It "Détecte les sous-dossiers manquants" {
            # Exécuter le script avec le dossier de test
            $result = & $scriptPath -Path $testRoot -ReportPath "report.md"
            
            # Vérifier que les sous-dossiers manquants sont détectés
            $result.MissingSubFolders | Should -Not -BeNullOrEmpty
            $result.MissingSubFolders | Should -Contain "scripts\analysis"
            $result.MissingSubFolders | Should -Contain "modules\PowerShell"
            $result.MissingSubFolders | Should -Contain "docs\guides"
        }
        
        It "Crée les dossiers manquants avec le paramètre Fix" {
            # Exécuter le script avec le paramètre Fix
            $result = & $scriptPath -Path $testRoot -ReportPath "report.md" -Fix
            
            # Vérifier que les dossiers ont été créés
            $result.CreatedFolders | Should -Not -BeNullOrEmpty
            
            # Vérifier que les dossiers existent maintenant
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "config") -PathType Container | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\analysis") -PathType Container | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "modules\PowerShell") -PathType Container | Should -Be $true
        }
    }
    
    Context "Validation des conventions de nommage" {
        It "Détecte les fichiers PowerShell non conformes" {
            # Exécuter le script avec le dossier de test
            $result = & $scriptPath -Path $testRoot -ReportPath "report.md"
            
            # Vérifier que les fichiers PowerShell non conformes sont détectés
            $result.NonCompliantPowerShellFiles | Should -Not -BeNullOrEmpty
            $result.NonCompliantPowerShellFiles.FullName | Should -Contain (Join-Path -Path $testRoot -ChildPath "scripts\invalidScript.ps1")
        }
        
        It "Détecte les fichiers Python non conformes" {
            # Exécuter le script avec le dossier de test
            $result = & $scriptPath -Path $testRoot -ReportPath "report.md"
            
            # Vérifier que les fichiers Python non conformes sont détectés
            $result.NonCompliantPythonFiles | Should -Not -BeNullOrEmpty
            $result.NonCompliantPythonFiles.FullName | Should -Contain (Join-Path -Path $testRoot -ChildPath "scripts\InvalidPython.py")
        }
        
        It "Détecte les fichiers Batch non conformes" {
            # Exécuter le script avec le dossier de test
            $result = & $scriptPath -Path $testRoot -ReportPath "report.md"
            
            # Vérifier que les fichiers Batch non conformes sont détectés
            $result.NonCompliantBatchFiles | Should -Not -BeNullOrEmpty
            $result.NonCompliantBatchFiles.FullName | Should -Contain (Join-Path -Path $testRoot -ChildPath "scripts\Setup File.cmd")
        }
    }
    
    Context "Génération de rapport" {
        It "Génère un rapport de validation" {
            # Définir le chemin du rapport
            $reportPath = Join-Path -Path $testRoot -ChildPath "report.md"
            
            # Exécuter le script avec le dossier de test
            & $scriptPath -Path $testRoot -ReportPath $reportPath
            
            # Vérifier que le rapport a été généré
            Test-Path -Path $reportPath -PathType Leaf | Should -Be $true
            
            # Vérifier le contenu du rapport
            $reportContent = Get-Content -Path $reportPath -Raw
            $reportContent | Should -Match "Rapport de Validation de Structure du Dépôt"
            $reportContent | Should -Match "Dossiers principaux manquants"
            $reportContent | Should -Match "Fichiers PowerShell non conformes"
        }
    }
}

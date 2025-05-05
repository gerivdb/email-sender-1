#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Test-RepoStructure.ps1
.DESCRIPTION
    Ce script contient des tests unitaires pour valider le bon fonctionnement
    du script Test-RepoStructure.ps1 qui vÃ©rifie la conformitÃ© de la structure
    du dÃ©pÃ´t avec le standard dÃ©fini.
.EXAMPLE
    Invoke-Pester -Path .\Test-RepoStructureUnit.ps1
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-26
#>

# Importer le module Pester s'il n'est pas dÃ©jÃ  chargÃ©
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\maintenance\repo\Test-RepoStructure.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Test-RepoStructure.ps1 n'existe pas Ã  l'emplacement spÃ©cifiÃ©: $scriptPath"
}

Describe "Test-RepoStructure" {
    BeforeAll {
        # CrÃ©er un dossier temporaire pour les tests
        $testRoot = Join-Path -Path $TestDrive -ChildPath "TestRepo"
        New-Item -Path $testRoot -ItemType Directory -Force | Out-Null
        
        # CrÃ©er quelques dossiers et fichiers pour les tests
        $validFolders = @(
            "scripts",
            "modules",
            "docs",
            "tests"
        )
        
        foreach ($folder in $validFolders) {
            New-Item -Path (Join-Path -Path $testRoot -ChildPath $folder) -ItemType Directory -Force | Out-Null
        }
        
        # CrÃ©er des fichiers avec diffÃ©rentes conventions de nommage
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
        
        # CrÃ©er des fichiers non conformes
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
        It "DÃ©tecte les dossiers principaux manquants" {
            # ExÃ©cuter le script avec le dossier de test
            $result = & $scriptPath -Path $testRoot -ReportPath "report.md"
            
            # VÃ©rifier que les dossiers manquants sont dÃ©tectÃ©s
            $result.MissingMainFolders | Should -Not -BeNullOrEmpty
            $result.MissingMainFolders | Should -Contain "config"
            $result.MissingMainFolders | Should -Contain "assets"
            $result.MissingMainFolders | Should -Contain "tools"
        }
        
        It "DÃ©tecte les sous-dossiers manquants" {
            # ExÃ©cuter le script avec le dossier de test
            $result = & $scriptPath -Path $testRoot -ReportPath "report.md"
            
            # VÃ©rifier que les sous-dossiers manquants sont dÃ©tectÃ©s
            $result.MissingSubFolders | Should -Not -BeNullOrEmpty
            $result.MissingSubFolders | Should -Contain "scripts\analysis"
            $result.MissingSubFolders | Should -Contain "modules\PowerShell"
            $result.MissingSubFolders | Should -Contain "docs\guides"
        }
        
        It "CrÃ©e les dossiers manquants avec le paramÃ¨tre Fix" {
            # ExÃ©cuter le script avec le paramÃ¨tre Fix
            $result = & $scriptPath -Path $testRoot -ReportPath "report.md" -Fix
            
            # VÃ©rifier que les dossiers ont Ã©tÃ© crÃ©Ã©s
            $result.CreatedFolders | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier que les dossiers existent maintenant
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "config") -PathType Container | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\analysis") -PathType Container | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "modules\PowerShell") -PathType Container | Should -Be $true
        }
    }
    
    Context "Validation des conventions de nommage" {
        It "DÃ©tecte les fichiers PowerShell non conformes" {
            # ExÃ©cuter le script avec le dossier de test
            $result = & $scriptPath -Path $testRoot -ReportPath "report.md"
            
            # VÃ©rifier que les fichiers PowerShell non conformes sont dÃ©tectÃ©s
            $result.NonCompliantPowerShellFiles | Should -Not -BeNullOrEmpty
            $result.NonCompliantPowerShellFiles.FullName | Should -Contain (Join-Path -Path $testRoot -ChildPath "scripts\invalidScript.ps1")
        }
        
        It "DÃ©tecte les fichiers Python non conformes" {
            # ExÃ©cuter le script avec le dossier de test
            $result = & $scriptPath -Path $testRoot -ReportPath "report.md"
            
            # VÃ©rifier que les fichiers Python non conformes sont dÃ©tectÃ©s
            $result.NonCompliantPythonFiles | Should -Not -BeNullOrEmpty
            $result.NonCompliantPythonFiles.FullName | Should -Contain (Join-Path -Path $testRoot -ChildPath "scripts\InvalidPython.py")
        }
        
        It "DÃ©tecte les fichiers Batch non conformes" {
            # ExÃ©cuter le script avec le dossier de test
            $result = & $scriptPath -Path $testRoot -ReportPath "report.md"
            
            # VÃ©rifier que les fichiers Batch non conformes sont dÃ©tectÃ©s
            $result.NonCompliantBatchFiles | Should -Not -BeNullOrEmpty
            $result.NonCompliantBatchFiles.FullName | Should -Contain (Join-Path -Path $testRoot -ChildPath "scripts\Setup File.cmd")
        }
    }
    
    Context "GÃ©nÃ©ration de rapport" {
        It "GÃ©nÃ¨re un rapport de validation" {
            # DÃ©finir le chemin du rapport
            $reportPath = Join-Path -Path $testRoot -ChildPath "report.md"
            
            # ExÃ©cuter le script avec le dossier de test
            & $scriptPath -Path $testRoot -ReportPath $reportPath
            
            # VÃ©rifier que le rapport a Ã©tÃ© gÃ©nÃ©rÃ©
            Test-Path -Path $reportPath -PathType Leaf | Should -Be $true
            
            # VÃ©rifier le contenu du rapport
            $reportContent = Get-Content -Path $reportPath -Raw
            $reportContent | Should -Match "Rapport de Validation de Structure du DÃ©pÃ´t"
            $reportContent | Should -Match "Dossiers principaux manquants"
            $reportContent | Should -Match "Fichiers PowerShell non conformes"
        }
    }
}

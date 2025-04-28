#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Reorganize-Repository.ps1
.DESCRIPTION
    Ce script contient des tests unitaires pour valider le bon fonctionnement
    du script Reorganize-Repository.ps1 qui réorganise les fichiers du dépôt
    selon la structure standardisée.
.EXAMPLE
    Invoke-Pester -Path .\Test-RepositoryMigration.ps1
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\maintenance\repo\Reorganize-Repository.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Reorganize-Repository.ps1 n'existe pas à l'emplacement spécifié: $scriptPath"
}

Describe "Reorganize-Repository" {
    BeforeAll {
        # Créer un dossier temporaire pour les tests
        $testRoot = Join-Path -Path $TestDrive -ChildPath "TestRepo"
        New-Item -Path $testRoot -ItemType Directory -Force | Out-Null
        
        # Créer une structure de dossiers non standard
        $nonStandardFolders = @(
            "old-scripts",
            "python-scripts",
            "powershell-scripts",
            "batch-files",
            "documentation"
        )
        
        foreach ($folder in $nonStandardFolders) {
            New-Item -Path (Join-Path -Path $testRoot -ChildPath $folder) -ItemType Directory -Force | Out-Null
        }
        
        # Créer des fichiers à réorganiser
        $filesToReorganize = @(
            # Scripts PowerShell
            @{
                Path = Join-Path -Path $testRoot -ChildPath "powershell-scripts\Get-Data.ps1"
                Content = "# PowerShell script for analysis"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "powershell-scripts\Start-Service.ps1"
                Content = "# PowerShell script for automation"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "powershell-scripts\Show-Form.ps1"
                Content = "# PowerShell script for GUI"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "powershell-scripts\Connect-Database.ps1"
                Content = "# PowerShell script for integration"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "powershell-scripts\Update-System.ps1"
                Content = "# PowerShell script for maintenance"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "powershell-scripts\Install-Application.ps1"
                Content = "# PowerShell script for setup"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "powershell-scripts\ConvertTo-Json.ps1"
                Content = "# PowerShell script for utilities"
            },
            
            # Scripts Python
            @{
                Path = Join-Path -Path $testRoot -ChildPath "python-scripts\analyze_data.py"
                Content = "# Python script for analysis"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "python-scripts\start_service.py"
                Content = "# Python script for automation"
            },
            
            # Scripts Batch
            @{
                Path = Join-Path -Path $testRoot -ChildPath "batch-files\install-app.cmd"
                Content = "REM Batch script for setup"
            },
            
            # Documentation
            @{
                Path = Join-Path -Path $testRoot -ChildPath "documentation\Guide.md"
                Content = "# User Guide"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "documentation\API.md"
                Content = "# API Reference"
            }
        )
        
        foreach ($file in $filesToReorganize) {
            $fileDir = Split-Path -Path $file.Path -Parent
            if (-not (Test-Path -Path $fileDir)) {
                New-Item -Path $fileDir -ItemType Directory -Force | Out-Null
            }
            
            Set-Content -Path $file.Path -Value $file.Content -Encoding UTF8
        }
    }
    
    Context "Création de la structure de dossiers" {
        It "Crée la structure de dossiers standard" {
            # Exécuter le script en mode simulation
            & $scriptPath -Path $testRoot -DryRun
            
            # Exécuter le script réellement
            & $scriptPath -Path $testRoot
            
            # Vérifier que les dossiers standard ont été créés
            $standardFolders = @(
                "scripts",
                "scripts\analysis",
                "scripts\automation",
                "scripts\gui",
                "scripts\integration",
                "scripts\maintenance",
                "scripts\setup",
                "scripts\utils",
                "modules",
                "modules\PowerShell",
                "modules\Python",
                "docs",
                "docs\guides",
                "docs\api",
                "tests"
            )
            
            foreach ($folder in $standardFolders) {
                Test-Path -Path (Join-Path -Path $testRoot -ChildPath $folder) -PathType Container | Should -Be $true
            }
        }
    }
    
    Context "Migration des fichiers" {
        It "Migre les scripts PowerShell vers les dossiers appropriés" {
            # Vérifier que les scripts PowerShell ont été migrés vers les bons dossiers
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\analysis\Get-Data.ps1") -PathType Leaf | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\automation\Start-Service.ps1") -PathType Leaf | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\gui\Show-Form.ps1") -PathType Leaf | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\integration\Connect-Database.ps1") -PathType Leaf | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\maintenance\Update-System.ps1") -PathType Leaf | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\setup\Install-Application.ps1") -PathType Leaf | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\utils\ConvertTo-Json.ps1") -PathType Leaf | Should -Be $true
        }
        
        It "Migre les scripts Python vers les dossiers appropriés" {
            # Vérifier que les scripts Python ont été migrés vers les bons dossiers
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\analysis\analyze_data.py") -PathType Leaf | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\automation\start_service.py") -PathType Leaf | Should -Be $true
        }
        
        It "Migre les scripts Batch vers les dossiers appropriés" {
            # Vérifier que les scripts Batch ont été migrés vers les bons dossiers
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\setup\install-app.cmd") -PathType Leaf | Should -Be $true
        }
        
        It "Migre la documentation vers les dossiers appropriés" {
            # Vérifier que la documentation a été migrée vers les bons dossiers
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "docs\guides\Guide.md") -PathType Leaf | Should -Be $true
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "docs\api\API.md") -PathType Leaf | Should -Be $true
        }
    }
    
    Context "Nettoyage des dossiers vides" {
        It "Supprime les dossiers vides après la migration" {
            # Vérifier que les dossiers non standard sont vides ou ont été supprimés
            foreach ($folder in @("old-scripts", "python-scripts", "powershell-scripts", "batch-files", "documentation")) {
                $folderPath = Join-Path -Path $testRoot -ChildPath $folder
                (Test-Path -Path $folderPath -PathType Container) -and ((Get-ChildItem -Path $folderPath).Count -gt 0) | Should -Be $false
            }
        }
    }
    
    Context "Journalisation" {
        It "Génère un journal des opérations" {
            # Vérifier que le journal a été créé
            $logFiles = Get-ChildItem -Path (Join-Path -Path $testRoot -ChildPath "logs") -Filter "reorganization-*.log" -File
            $logFiles | Should -Not -BeNullOrEmpty
            
            # Vérifier le contenu du journal
            $logContent = Get-Content -Path $logFiles[0].FullName -Raw
            $logContent | Should -Match "Création de la structure de dossiers"
            $logContent | Should -Match "Migration des fichiers"
            $logContent | Should -Match "Réorganisation du dépôt terminée"
        }
    }
}

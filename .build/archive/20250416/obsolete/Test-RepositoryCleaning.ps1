#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Clean-Repository.ps1
.DESCRIPTION
    Ce script contient des tests unitaires pour valider le bon fonctionnement
    du script Clean-Repository.ps1 qui nettoie le dépôt en identifiant et
    traitant les scripts obsolètes et redondants.
.EXAMPLE
    Invoke-Pester -Path .\Test-RepositoryCleaning.ps1
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
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\maintenance\repo\Clean-Repository.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    throw "Le script Clean-Repository.ps1 n'existe pas à l'emplacement spécifié: $scriptPath"
}

Describe "Clean-Repository" {
    BeforeAll {
        # Créer un dossier temporaire pour les tests
        $testRoot = Join-Path -Path $TestDrive -ChildPath "TestRepo"
        New-Item -Path $testRoot -ItemType Directory -Force | Out-Null
        
        # Créer des dossiers pour les scripts
        $scriptFolders = @(
            "scripts",
            "scripts\analysis",
            "scripts\automation",
            "scripts\utils"
        )
        
        foreach ($folder in $scriptFolders) {
            New-Item -Path (Join-Path -Path $testRoot -ChildPath $folder) -ItemType Directory -Force | Out-Null
        }
        
        # Créer des scripts obsolètes
        $obsoleteScripts = @(
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\analysis\old_analyzer.py"
                Content = "# This script is obsolete and should be replaced by new_analyzer.py"
                LastWriteTime = (Get-Date).AddYears(-2)
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\utils\deprecated_util.ps1"
                Content = "# This script is deprecated and should no longer be used"
                LastWriteTime = (Get-Date).AddYears(-1)
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\backup_script.ps1"
                Content = "# Backup script"
                LastWriteTime = (Get-Date).AddMonths(-6)
            }
        )
        
        foreach ($script in $obsoleteScripts) {
            Set-Content -Path $script.Path -Value $script.Content -Encoding UTF8
            Set-ItemProperty -Path $script.Path -Name LastWriteTime -Value $script.LastWriteTime
        }
        
        # Créer des scripts redondants
        $redundantScripts = @(
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\analysis\data_analyzer_v1.ps1"
                Content = "# Script to analyze data
function Analyze-Data {
    param($data)
    return $data | Measure-Object -Sum -Average
}
Analyze-Data"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\analysis\data_analyzer_v2.ps1"
                Content = "# Script to analyze data
function Analyze-Data {
    param($data)
    return $data | Measure-Object -Sum -Average
}
Analyze-Data"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\automation\process_data.ps1"
                Content = "# Script to process data
function Process-Data {
    param($data)
    return $data | Where-Object { $_ -gt 0 }
}
Process-Data"
            },
            @{
                Path = Join-Path -Path $testRoot -ChildPath "scripts\utils\data_processor.ps1"
                Content = "# Script to process data
function Process-Data {
    param($data)
    return $data | Where-Object { $_ -gt 0 }
}
Process-Data"
            }
        )
        
        foreach ($script in $redundantScripts) {
            Set-Content -Path $script.Path -Value $script.Content -Encoding UTF8
        }
        
        # Créer des dossiers pour les rapports et l'archive
        New-Item -Path (Join-Path -Path $testRoot -ChildPath "reports") -ItemType Directory -Force | Out-Null
        New-Item -Path (Join-Path -Path $testRoot -ChildPath "archive") -ItemType Directory -Force | Out-Null
    }
    
    Context "Détection des scripts obsolètes" {
        It "Détecte les scripts obsolètes par leur nom" {
            # Exécuter le script en mode simulation
            $result = & $scriptPath -Path $testRoot -DryRun
            
            # Vérifier que les scripts obsolètes sont détectés
            $obsoleteScripts = $result.ObsoleteScripts
            $obsoleteScripts | Should -Not -BeNullOrEmpty
            $obsoleteScripts.Count | Should -BeGreaterOrEqual 1
            
            # Vérifier que le script avec "old" dans le nom est détecté
            $obsoleteScripts | Where-Object { $_.File.Name -eq "old_analyzer.py" } | Should -Not -BeNullOrEmpty
            
            # Vérifier que le script avec "deprecated" dans le nom est détecté
            $obsoleteScripts | Where-Object { $_.File.Name -eq "deprecated_util.ps1" } | Should -Not -BeNullOrEmpty
            
            # Vérifier que le script avec "backup" dans le nom est détecté
            $obsoleteScripts | Where-Object { $_.File.Name -eq "backup_script.ps1" } | Should -Not -BeNullOrEmpty
        }
        
        It "Détecte les scripts obsolètes par leur date de modification" {
            # Exécuter le script en mode simulation
            $result = & $scriptPath -Path $testRoot -DryRun
            
            # Vérifier que les scripts obsolètes sont détectés
            $obsoleteScripts = $result.ObsoleteScripts
            
            # Vérifier que le script non modifié depuis plus d'un an est détecté
            $oldScripts = $obsoleteScripts | Where-Object { $_.Reasons -match "Non modifié depuis plus d'un an" }
            $oldScripts | Should -Not -BeNullOrEmpty
            $oldScripts.Count | Should -BeGreaterOrEqual 1
        }
        
        It "Détecte les scripts obsolètes par leur contenu" {
            # Exécuter le script en mode simulation
            $result = & $scriptPath -Path $testRoot -DryRun
            
            # Vérifier que les scripts obsolètes sont détectés
            $obsoleteScripts = $result.ObsoleteScripts
            
            # Vérifier que le script avec "deprecated" dans le contenu est détecté
            $deprecatedScripts = $obsoleteScripts | Where-Object { $_.Reasons -match "Contient des commentaires indiquant qu'il est obsolète" }
            $deprecatedScripts | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Détection des scripts redondants" {
        It "Détecte les scripts redondants par similarité de contenu" {
            # Exécuter le script en mode simulation
            $result = & $scriptPath -Path $testRoot -DryRun -SimilarityThreshold 90
            
            # Vérifier que les scripts redondants sont détectés
            $redundantGroups = $result.RedundantGroups
            $redundantGroups | Should -Not -BeNullOrEmpty
            $redundantGroups.Count | Should -BeGreaterOrEqual 1
            
            # Vérifier que les scripts data_analyzer_v1.ps1 et data_analyzer_v2.ps1 sont détectés comme redondants
            $analyzerGroup = $redundantGroups | Where-Object {
                $_.Scripts | Where-Object { $_.Name -eq "data_analyzer_v1.ps1" } -and
                $_.Scripts | Where-Object { $_.Name -eq "data_analyzer_v2.ps1" }
            }
            $analyzerGroup | Should -Not -BeNullOrEmpty
            
            # Vérifier que les scripts process_data.ps1 et data_processor.ps1 sont détectés comme redondants
            $processorGroup = $redundantGroups | Where-Object {
                $_.Scripts | Where-Object { $_.Name -eq "process_data.ps1" } -and
                $_.Scripts | Where-Object { $_.Name -eq "data_processor.ps1" }
            }
            $processorGroup | Should -Not -BeNullOrEmpty
        }
    }
    
    Context "Archivage des scripts" {
        It "Archive les scripts obsolètes" {
            # Exécuter le script réellement
            & $scriptPath -Path $testRoot -ArchivePath "archive\test" -SimilarityThreshold 90
            
            # Vérifier que les scripts obsolètes ont été archivés
            $archivePath = Join-Path -Path $testRoot -ChildPath "archive\test\obsolete"
            Test-Path -Path $archivePath -PathType Container | Should -Be $true
            
            # Vérifier que les scripts obsolètes sont dans l'archive
            $archivedScripts = Get-ChildItem -Path $archivePath -File
            $archivedScripts | Should -Not -BeNullOrEmpty
            $archivedScripts.Count | Should -BeGreaterOrEqual 3
            
            $archivedScripts.Name | Should -Contain "old_analyzer.py"
            $archivedScripts.Name | Should -Contain "deprecated_util.ps1"
            $archivedScripts.Name | Should -Contain "backup_script.ps1"
            
            # Vérifier que les scripts obsolètes ont été supprimés de leur emplacement d'origine
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\analysis\old_analyzer.py") -PathType Leaf | Should -Be $false
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\utils\deprecated_util.ps1") -PathType Leaf | Should -Be $false
            Test-Path -Path (Join-Path -Path $testRoot -ChildPath "scripts\backup_script.ps1") -PathType Leaf | Should -Be $false
        }
        
        It "Archive les scripts redondants" {
            # Vérifier que les scripts redondants ont été archivés
            $archivePath = Join-Path -Path $testRoot -ChildPath "archive\test\redundant"
            Test-Path -Path $archivePath -PathType Container | Should -Be $true
            
            # Vérifier que les scripts redondants sont dans l'archive
            $archivedScripts = Get-ChildItem -Path $archivePath -File
            $archivedScripts | Should -Not -BeNullOrEmpty
            
            # Vérifier que soit data_analyzer_v1.ps1 soit data_analyzer_v2.ps1 a été archivé (mais pas les deux)
            ($archivedScripts.Name -contains "data_analyzer_v1.ps1" -xor $archivedScripts.Name -contains "data_analyzer_v2.ps1") | Should -Be $true
            
            # Vérifier que soit process_data.ps1 soit data_processor.ps1 a été archivé (mais pas les deux)
            ($archivedScripts.Name -contains "process_data.ps1" -xor $archivedScripts.Name -contains "data_processor.ps1") | Should -Be $true
        }
    }
    
    Context "Génération de rapport" {
        It "Génère un rapport de nettoyage" {
            # Vérifier que le rapport a été généré
            $reportFiles = Get-ChildItem -Path (Join-Path -Path $testRoot -ChildPath "reports") -Filter "cleanup-*.md" -File
            $reportFiles | Should -Not -BeNullOrEmpty
            
            # Vérifier le contenu du rapport
            $reportContent = Get-Content -Path $reportFiles[0].FullName -Raw
            $reportContent | Should -Match "Rapport de Nettoyage du Dépôt"
            $reportContent | Should -Match "Scripts Obsolètes"
            $reportContent | Should -Match "Scripts Redondants"
        }
    }
}

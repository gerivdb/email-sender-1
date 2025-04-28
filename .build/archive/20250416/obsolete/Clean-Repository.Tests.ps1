#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le script Clean-Repository.ps1
.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que le script
    Clean-Repository.ps1 fonctionne correctement.
.EXAMPLE
    Invoke-Pester -Path .\Clean-Repository.Tests.ps1
.NOTES
    Auteur: Augment Agent
    Version: 1.0
#>

BeforeAll {
    # Chemin du script à tester
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\maintenance\repo\Clean-Repository.ps1"

    # Vérifier que le script existe
    if (-not (Test-Path -Path $scriptPath)) {
        throw "Le script Clean-Repository.ps1 n'existe pas: $scriptPath"
    }

    # Créer un dossier temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "CleanRepoTest-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null

    # Créer une structure de test
    $testFolders = @(
        "scripts",
        "scripts\old",
        "scripts\utils",
        "projet/documentation",
        "archive"
    )

    foreach ($folder in $testFolders) {
        New-Item -Path (Join-Path -Path $testDir -ChildPath $folder) -ItemType Directory -Force | Out-Null
    }

    # Créer des fichiers de test
    $testFiles = @(
        @{
            Path    = Join-Path -Path $testDir -ChildPath "scripts\Test-Script.ps1"
            Content = "# Test script`nWrite-Host 'Hello, World!'"
        },
        @{
            Path    = Join-Path -Path $testDir -ChildPath "scripts\old\Old-Script.ps1"
            Content = "# Old script`n# OBSOLETE: Ce script est obsolète`nWrite-Host 'This is an old script'"
        },
        @{
            Path    = Join-Path -Path $testDir -ChildPath "scripts\utils\Utility.ps1"
            Content = "# Utility script`nfunction Get-Utility { return 'Utility' }"
        },
        @{
            Path    = Join-Path -Path $testDir -ChildPath "scripts\utils\Utility-v2.ps1"
            Content = "# Utility script v2`nfunction Get-Utility { return 'Utility v2' }"
        },
        @{
            Path    = Join-Path -Path $testDir -ChildPath "projet/documentation\README.md"
            Content = "# Test Repository`nThis is a test repository."
        }
    )

    foreach ($file in $testFiles) {
        Set-Content -Path $file.Path -Value $file.Content -Encoding UTF8
    }

    # Fonction pour nettoyer le dossier de test
    function CleanupTestDir {
        if (Test-Path -Path $testDir) {
            Remove-Item -Path $testDir -Recurse -Force
        }
    }
}

AfterAll {
    # Nettoyer le dossier de test
    CleanupTestDir
}

Describe "Clean-Repository" {
    Context "Détection des scripts obsolètes" {
        It "Détecte les scripts obsolètes" {
            # Charger le script dans la portée actuelle
            . $scriptPath

            # Appeler la fonction Find-ObsoleteScripts avec le dossier de test
            $obsoleteScripts = Find-ObsoleteScripts -Path $testDir

            # Vérifier que le script obsolète a été détecté
            $obsoleteScripts.Count | Should -Be 1
            $obsoleteScripts[0].File.Name | Should -Be "Old-Script.ps1"
        }
    }

    Context "Archivage des scripts" {
        It "Archive les scripts correctement" {
            # Créer un script à archiver
            $scriptToArchive = Join-Path -Path $testDir -ChildPath "scripts\ToArchive.ps1"
            Set-Content -Path $scriptToArchive -Value "# Script to archive" -Encoding UTF8

            # Charger le script dans la portée actuelle
            . $scriptPath

            # Appeler la fonction Move-ScriptsToArchive avec le script à archiver
            $archiveDir = "archive"
            $archivedScripts = Move-ScriptsToArchive -Scripts @([System.IO.FileInfo]$scriptToArchive) -ArchiveDir $archiveDir -Category "test" -Path $testDir -DryRun $false

            # Vérifier que le script a été archivé
            $archivedScripts.Count | Should -Be 1
            $archivedScripts[0].OriginalPath | Should -Be "scripts\ToArchive.ps1"

            # Vérifier que le fichier a été déplacé vers le dossier d'archive
            $archivePath = Join-Path -Path $testDir -ChildPath "$archiveDir\test\ToArchive.ps1"
            Test-Path -Path $archivePath | Should -Be $true

            # Vérifier que le fichier original a été supprimé
            Test-Path -Path $scriptToArchive | Should -Be $false
        }
    }

    Context "Génération du rapport" {
        It "Génère un rapport de nettoyage" {
            # Charger le script dans la portée actuelle
            . $scriptPath

            # Créer des données de test
            $obsoleteScripts = @(
                [PSCustomObject]@{
                    File    = [System.IO.FileInfo](Join-Path -Path $testDir -ChildPath "scripts\old\Old-Script.ps1")
                    Reasons = "Contient des commentaires indiquant qu'il est obsolète"
                }
            )

            $consolidatedGroups = @(
                [PSCustomObject]@{
                    KeptScript      = "scripts\utils\Utility-v2.ps1"
                    ArchivedScripts = @(
                        [PSCustomObject]@{
                            OriginalPath = "scripts\utils\Utility.ps1"
                            ArchivePath  = "archive\redundant\Utility.ps1"
                        }
                    )
                    Similarity      = 85.5
                }
            )

            # Appeler la fonction New-CleanupReport
            $reportPath = "report.md"
            $fullReportPath = New-CleanupReport -ObsoleteScripts $obsoleteScripts -ConsolidatedGroups $consolidatedGroups -ReportPath $reportPath -Path $testDir

            # Vérifier que le rapport a été généré
            Test-Path -Path $fullReportPath | Should -Be $true

            # Vérifier le contenu du rapport
            $reportContent = Get-Content -Path $fullReportPath -Raw
            $reportContent | Should -Match "Scripts obsolètes: 1"
            $reportContent | Should -Match "Groupes de scripts redondants: 1"
            $reportContent | Should -Match "Old-Script.ps1"
            $reportContent | Should -Match "Utility-v2.ps1"
        }
    }

    Context "Exécution complète" {
        It "Exécute le script en mode simulation sans détection de scripts redondants" {
            # Exécuter le script avec le paramètre -DryRun et -SkipRedundantDetection
            $output = & $scriptPath -Path $testDir -ArchivePath "archive" -ReportPath "report.md" -DryRun -SkipRedundantDetection

            # Vérifier que le script s'est exécuté sans erreur
            $LASTEXITCODE | Should -Be 0

            # Vérifier que le rapport a été généré
            $reportPath = Join-Path -Path $testDir -ChildPath "report.md"
            Test-Path -Path $reportPath | Should -Be $true
        }
    }
}

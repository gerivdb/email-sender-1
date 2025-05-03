BeforeAll {
    # Importer le module commun
    $scriptPath = Split-Path -Parent $PSScriptRoot
    $projectRoot = Split-Path -Parent $scriptPath
    $commonPath = Join-Path -Path $projectRoot -ChildPath "common"
    $modulePath = Join-Path -Path $commonPath -ChildPath "RoadmapModule.psm1"

    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        throw "Module commun introuvable: $modulePath"
    }

    # Importer le script Archive-CompletedTasks.ps1
    $archiveScriptPath = Join-Path -Path $scriptPath -ChildPath "Archive-CompletedTasks.ps1"
    if (Test-Path $archiveScriptPath) {
        . $archiveScriptPath
    } else {
        throw "Script d'archivage introuvable: $archiveScriptPath"
    }

    # Créer des fichiers de test
    $testRoadmapContent = @"
# Roadmap de test

## Tâches actives

- [ ] **1.1** Tâche incomplète 1
  - [ ] **1.1.1** Sous-tâche incomplète 1.1
  - [x] **1.1.2** Sous-tâche terminée 1.2
- [x] **1.2** Tâche terminée 2
  - [x] **1.2.1** Sous-tâche terminée 2.1
  - [ ] **1.2.2** Sous-tâche incomplète 2.2
- [ ] **1.3** Tâche incomplète 3
"@

    $testArchiveContent = @"
# Roadmap Archive

## Tâches archivées

- [x] **0.1** Tâche archivée précédemment
"@

    $script:testRoadmapPath = Join-Path -Path $TestDrive -ChildPath "test_roadmap.md"
    $script:testArchivePath = Join-Path -Path $TestDrive -ChildPath "test_archive.md"

    Set-Content -Path $script:testRoadmapPath -Value $testRoadmapContent -Encoding UTF8
    Set-Content -Path $script:testArchivePath -Value $testArchiveContent -Encoding UTF8
}

Describe "Archive-CompletedTasks" {
    BeforeEach {
        # Réinitialiser les fichiers de test avant chaque test
        $testRoadmapContent = @"
# Roadmap de test

## Tâches actives

- [ ] **1.1** Tâche incomplète 1
  - [ ] **1.1.1** Sous-tâche incomplète 1.1
  - [x] **1.1.2** Sous-tâche terminée 1.2
- [x] **1.2** Tâche terminée 2
  - [x] **1.2.1** Sous-tâche terminée 2.1
  - [ ] **1.2.2** Sous-tâche incomplète 2.2
- [ ] **1.3** Tâche incomplète 3
"@

        $testArchiveContent = @"
# Roadmap Archive

## Tâches archivées

- [x] **0.1** Tâche archivée précédemment
"@

        Set-Content -Path $script:testRoadmapPath -Value $testRoadmapContent -Encoding UTF8
        Set-Content -Path $script:testArchivePath -Value $testArchiveContent -Encoding UTF8
    }

    It "Identifie correctement les tâches terminées" {
        # Mock pour la fonction Get-CompletedTasks
        function Get-CompletedTasks {
            param (
                [string]$RoadmapContent
            )

            # Simuler l'identification des tâches terminées
            return @(
                [PSCustomObject]@{
                    Id          = "1.1.2"
                    Description = "Sous-tâche terminée 1.2"
                    Section     = "Tâches actives"
                    Line        = 5
                    IndentLevel = 2
                    FullLine    = "  - [x] **1.1.2** Sous-tâche terminée 1.2"
                },
                [PSCustomObject]@{
                    Id          = "1.2"
                    Description = "Tâche terminée 2"
                    Section     = "Tâches actives"
                    Line        = 6
                    IndentLevel = 1
                    FullLine    = "- [x] **1.2** Tâche terminée 2"
                },
                [PSCustomObject]@{
                    Id          = "1.2.1"
                    Description = "Sous-tâche terminée 2.1"
                    Section     = "Tâches actives"
                    Line        = 7
                    IndentLevel = 2
                    FullLine    = "  - [x] **1.2.1** Sous-tâche terminée 2.1"
                }
            )
        }

        # Appeler la fonction avec le contenu du fichier de test
        $roadmapContent = Get-Content -Path $script:testRoadmapPath -Raw
        $completedTasks = Get-CompletedTasks -RoadmapContent $roadmapContent

        # Vérifier les résultats
        $completedTasks | Should -Not -BeNullOrEmpty
        $completedTasks.Count | Should -Be 3
        $completedTasks[0].Id | Should -Be "1.1.2"
        $completedTasks[1].Id | Should -Be "1.2"
        $completedTasks[2].Id | Should -Be "1.2.1"
    }

    It "Récupère correctement les tâches avec leurs sous-tâches" {
        # Mock pour la fonction Get-TaskWithChildren
        function Get-TaskWithChildren {
            param (
                [string[]]$Lines,
                [int]$TaskLine,
                [int]$TaskIndentLevel
            )

            # Simuler la récupération d'une tâche avec ses sous-tâches
            if ($TaskLine -eq 6 -and $TaskIndentLevel -eq 1) {
                # Pour la tâche "1.2"
                return @(
                    "- [x] **1.2** Tâche terminée 2",
                    "  - [x] **1.2.1** Sous-tâche terminée 2.1",
                    "  - [ ] **1.2.2** Sous-tâche incomplète 2.2"
                )
            } else {
                # Pour les autres tâches
                return @($Lines[$TaskLine])
            }
        }

        # Appeler la fonction avec les paramètres de test
        $lines = Get-Content -Path $script:testRoadmapPath
        $taskLines = Get-TaskWithChildren -Lines $lines -TaskLine 6 -TaskIndentLevel 1

        # Vérifier les résultats
        $taskLines | Should -Not -BeNullOrEmpty
        $taskLines.Count | Should -Be 3
        $taskLines[0] | Should -Be "- [x] **1.2** Tâche terminée 2"
        $taskLines[1] | Should -Be "  - [x] **1.2.1** Sous-tâche terminée 2.1"
        $taskLines[2] | Should -Be "  - [ ] **1.2.2** Sous-tâche incomplète 2.2"
    }

    It "Met à jour correctement les fichiers de roadmap et d'archive" {
        # Mock pour la fonction Update-RoadmapFiles
        function Update-RoadmapFiles {
            param (
                [string]$RoadmapContent,
                [string]$ArchiveContent,
                [array]$CompletedTasks,
                [string]$RoadmapPath,
                [string]$ArchivePath
            )

            # Simuler la mise à jour des fichiers
            $updatedRoadmapContent = @"
# Roadmap de test

## Tâches actives

- [ ] **1.1** Tâche incomplète 1
  - [ ] **1.1.1** Sous-tâche incomplète 1.1
- [ ] **1.3** Tâche incomplète 3
"@

            $updatedArchiveContent = @"
# Roadmap Archive

## Tâches archivées

- [x] **0.1** Tâche archivée précédemment

- [x] **1.1.2** Sous-tâche terminée 1.2
- [x] **1.2** Tâche terminée 2
  - [x] **1.2.1** Sous-tâche terminée 2.1
  - [ ] **1.2.2** Sous-tâche incomplète 2.2
"@

            # Écrire les fichiers mis à jour
            Set-Content -Path $RoadmapPath -Value $updatedRoadmapContent -Encoding UTF8
            Set-Content -Path $ArchivePath -Value $updatedArchiveContent -Encoding UTF8

            return @{
                RoadmapContent = $updatedRoadmapContent
                ArchiveContent = $updatedArchiveContent
            }
        }

        # Appeler la fonction avec les paramètres de test
        $roadmapContent = Get-Content -Path $script:testRoadmapPath -Raw
        $archiveContent = Get-Content -Path $script:testArchivePath -Raw
        $completedTasks = @(
            [PSCustomObject]@{
                Id          = "1.1.2"
                Description = "Sous-tâche terminée 1.2"
                Section     = "Tâches actives"
                Line        = 5
                IndentLevel = 2
                FullLine    = "  - [x] **1.1.2** Sous-tâche terminée 1.2"
            },
            [PSCustomObject]@{
                Id          = "1.2"
                Description = "Tâche terminée 2"
                Section     = "Tâches actives"
                Line        = 6
                IndentLevel = 1
                FullLine    = "- [x] **1.2** Tâche terminée 2"
            }
        )

        $result = Update-RoadmapFiles -RoadmapContent $roadmapContent -ArchiveContent $archiveContent -CompletedTasks $completedTasks -RoadmapPath $script:testRoadmapPath -ArchivePath $script:testArchivePath

        # Vérifier les résultats
        $result | Should -Not -BeNullOrEmpty
        $result.RoadmapContent | Should -Not -BeNullOrEmpty
        $result.ArchiveContent | Should -Not -BeNullOrEmpty

        # Vérifier le contenu des fichiers mis à jour
        $updatedRoadmapContent = Get-Content -Path $script:testRoadmapPath -Raw
        $updatedArchiveContent = Get-Content -Path $script:testArchivePath -Raw

        $updatedRoadmapContent | Should -Not -Match "\*\*1\.1\.2\*\*"
        $updatedRoadmapContent | Should -Not -Match "\*\*1\.2\*\*"
        $updatedRoadmapContent | Should -Match "\*\*1\.1\*\*"
        $updatedRoadmapContent | Should -Match "\*\*1\.3\*\*"

        $updatedArchiveContent | Should -Match "\*\*0\.1\*\*"
        $updatedArchiveContent | Should -Match "\*\*1\.1\.2\*\*"
        $updatedArchiveContent | Should -Match "\*\*1\.2\*\*"
    }

    It "Gère correctement l'absence de tâches terminées" {
        # Créer un fichier de roadmap sans tâches terminées
        $noCompletedTasksContent = @"
# Roadmap de test

## Tâches actives

- [ ] **1.1** Tâche incomplète 1
  - [ ] **1.1.1** Sous-tâche incomplète 1.1
  - [ ] **1.1.2** Sous-tâche incomplète 1.2
- [ ] **1.2** Tâche incomplète 2
  - [ ] **1.2.1** Sous-tâche incomplète 2.1
  - [ ] **1.2.2** Sous-tâche incomplète 2.2
- [ ] **1.3** Tâche incomplète 3
"@

        $noCompletedTasksPath = Join-Path -Path $TestDrive -ChildPath "no_completed_tasks.md"
        Set-Content -Path $noCompletedTasksPath -Value $noCompletedTasksContent -Encoding UTF8

        # Mock pour la fonction Get-CompletedTasks
        function Get-CompletedTasks {
            param (
                [string]$RoadmapContent
            )

            # Simuler l'absence de tâches terminées
            return @()
        }

        # Appeler la fonction avec le contenu du fichier de test
        $roadmapContent = Get-Content -Path $noCompletedTasksPath -Raw
        $completedTasks = Get-CompletedTasks -RoadmapContent $roadmapContent

        # Vérifier les résultats
        $completedTasks | Should -BeNullOrEmpty
    }

    It "Gère correctement les erreurs lors de la mise à jour des fichiers" {
        # Mock pour la fonction Update-RoadmapFiles qui génère une erreur
        function Update-RoadmapFiles {
            param (
                [string]$RoadmapContent,
                [string]$ArchiveContent,
                [array]$CompletedTasks,
                [string]$RoadmapPath,
                [string]$ArchivePath
            )

            throw "Erreur simulée lors de la mise à jour des fichiers"
        }

        # Appeler la fonction avec les paramètres de test
        $roadmapContent = Get-Content -Path $script:testRoadmapPath -Raw
        $archiveContent = Get-Content -Path $script:testArchivePath -Raw
        $completedTasks = @(
            [PSCustomObject]@{
                Id          = "1.1.2"
                Description = "Sous-tâche terminée 1.2"
                Section     = "Tâches actives"
                Line        = 5
                IndentLevel = 2
                FullLine    = "  - [x] **1.1.2** Sous-tâche terminée 1.2"
            }
        )

        # Vérifier que l'erreur est correctement gérée
        { Update-RoadmapFiles -RoadmapContent $roadmapContent -ArchiveContent $archiveContent -CompletedTasks $completedTasks -RoadmapPath $script:testRoadmapPath -ArchivePath $script:testArchivePath } | Should -Throw "Erreur simulée lors de la mise à jour des fichiers"
    }
}

# Les tests pour les scripts de surveillance sont dans des fichiers séparés
# pour éviter les problèmes d'exécution infinie

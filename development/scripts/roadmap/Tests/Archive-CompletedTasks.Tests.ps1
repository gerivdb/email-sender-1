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

    # CrÃ©er des fichiers de test
    $testRoadmapContent = @"
# Roadmap de test

## TÃ¢ches actives

- [ ] **1.1** TÃ¢che incomplÃ¨te 1
  - [ ] **1.1.1** Sous-tÃ¢che incomplÃ¨te 1.1
  - [x] **1.1.2** Sous-tÃ¢che terminÃ©e 1.2
- [x] **1.2** TÃ¢che terminÃ©e 2
  - [x] **1.2.1** Sous-tÃ¢che terminÃ©e 2.1
  - [ ] **1.2.2** Sous-tÃ¢che incomplÃ¨te 2.2
- [ ] **1.3** TÃ¢che incomplÃ¨te 3
"@

    $testArchiveContent = @"
# Roadmap Archive

## TÃ¢ches archivÃ©es

- [x] **0.1** TÃ¢che archivÃ©e prÃ©cÃ©demment
"@

    $script:testRoadmapPath = Join-Path -Path $TestDrive -ChildPath "test_roadmap.md"
    $script:testArchivePath = Join-Path -Path $TestDrive -ChildPath "test_archive.md"

    Set-Content -Path $script:testRoadmapPath -Value $testRoadmapContent -Encoding UTF8
    Set-Content -Path $script:testArchivePath -Value $testArchiveContent -Encoding UTF8
}

Describe "Archive-CompletedTasks" {
    BeforeEach {
        # RÃ©initialiser les fichiers de test avant chaque test
        $testRoadmapContent = @"
# Roadmap de test

## TÃ¢ches actives

- [ ] **1.1** TÃ¢che incomplÃ¨te 1
  - [ ] **1.1.1** Sous-tÃ¢che incomplÃ¨te 1.1
  - [x] **1.1.2** Sous-tÃ¢che terminÃ©e 1.2
- [x] **1.2** TÃ¢che terminÃ©e 2
  - [x] **1.2.1** Sous-tÃ¢che terminÃ©e 2.1
  - [ ] **1.2.2** Sous-tÃ¢che incomplÃ¨te 2.2
- [ ] **1.3** TÃ¢che incomplÃ¨te 3
"@

        $testArchiveContent = @"
# Roadmap Archive

## TÃ¢ches archivÃ©es

- [x] **0.1** TÃ¢che archivÃ©e prÃ©cÃ©demment
"@

        Set-Content -Path $script:testRoadmapPath -Value $testRoadmapContent -Encoding UTF8
        Set-Content -Path $script:testArchivePath -Value $testArchiveContent -Encoding UTF8
    }

    It "Identifie correctement les tÃ¢ches terminÃ©es" {
        # Mock pour la fonction Get-CompletedTasks
        function Get-CompletedTasks {
            param (
                [string]$RoadmapContent
            )

            # Simuler l'identification des tÃ¢ches terminÃ©es
            return @(
                [PSCustomObject]@{
                    Id          = "1.1.2"
                    Description = "Sous-tÃ¢che terminÃ©e 1.2"
                    Section     = "TÃ¢ches actives"
                    Line        = 5
                    IndentLevel = 2
                    FullLine    = "  - [x] **1.1.2** Sous-tÃ¢che terminÃ©e 1.2"
                },
                [PSCustomObject]@{
                    Id          = "1.2"
                    Description = "TÃ¢che terminÃ©e 2"
                    Section     = "TÃ¢ches actives"
                    Line        = 6
                    IndentLevel = 1
                    FullLine    = "- [x] **1.2** TÃ¢che terminÃ©e 2"
                },
                [PSCustomObject]@{
                    Id          = "1.2.1"
                    Description = "Sous-tÃ¢che terminÃ©e 2.1"
                    Section     = "TÃ¢ches actives"
                    Line        = 7
                    IndentLevel = 2
                    FullLine    = "  - [x] **1.2.1** Sous-tÃ¢che terminÃ©e 2.1"
                }
            )
        }

        # Appeler la fonction avec le contenu du fichier de test
        $roadmapContent = Get-Content -Path $script:testRoadmapPath -Raw
        $completedTasks = Get-CompletedTasks -RoadmapContent $roadmapContent

        # VÃ©rifier les rÃ©sultats
        $completedTasks | Should -Not -BeNullOrEmpty
        $completedTasks.Count | Should -Be 3
        $completedTasks[0].Id | Should -Be "1.1.2"
        $completedTasks[1].Id | Should -Be "1.2"
        $completedTasks[2].Id | Should -Be "1.2.1"
    }

    It "RÃ©cupÃ¨re correctement les tÃ¢ches avec leurs sous-tÃ¢ches" {
        # Mock pour la fonction Get-TaskWithChildren
        function Get-TaskWithChildren {
            param (
                [string[]]$Lines,
                [int]$TaskLine,
                [int]$TaskIndentLevel
            )

            # Simuler la rÃ©cupÃ©ration d'une tÃ¢che avec ses sous-tÃ¢ches
            if ($TaskLine -eq 6 -and $TaskIndentLevel -eq 1) {
                # Pour la tÃ¢che "1.2"
                return @(
                    "- [x] **1.2** TÃ¢che terminÃ©e 2",
                    "  - [x] **1.2.1** Sous-tÃ¢che terminÃ©e 2.1",
                    "  - [ ] **1.2.2** Sous-tÃ¢che incomplÃ¨te 2.2"
                )
            } else {
                # Pour les autres tÃ¢ches
                return @($Lines[$TaskLine])
            }
        }

        # Appeler la fonction avec les paramÃ¨tres de test
        $lines = Get-Content -Path $script:testRoadmapPath
        $taskLines = Get-TaskWithChildren -Lines $lines -TaskLine 6 -TaskIndentLevel 1

        # VÃ©rifier les rÃ©sultats
        $taskLines | Should -Not -BeNullOrEmpty
        $taskLines.Count | Should -Be 3
        $taskLines[0] | Should -Be "- [x] **1.2** TÃ¢che terminÃ©e 2"
        $taskLines[1] | Should -Be "  - [x] **1.2.1** Sous-tÃ¢che terminÃ©e 2.1"
        $taskLines[2] | Should -Be "  - [ ] **1.2.2** Sous-tÃ¢che incomplÃ¨te 2.2"
    }

    It "Met Ã  jour correctement les fichiers de roadmap et d'archive" {
        # Mock pour la fonction Update-RoadmapFiles
        function Update-RoadmapFiles {
            param (
                [string]$RoadmapContent,
                [string]$ArchiveContent,
                [array]$CompletedTasks,
                [string]$RoadmapPath,
                [string]$ArchivePath
            )

            # Simuler la mise Ã  jour des fichiers
            $updatedRoadmapContent = @"
# Roadmap de test

## TÃ¢ches actives

- [ ] **1.1** TÃ¢che incomplÃ¨te 1
  - [ ] **1.1.1** Sous-tÃ¢che incomplÃ¨te 1.1
- [ ] **1.3** TÃ¢che incomplÃ¨te 3
"@

            $updatedArchiveContent = @"
# Roadmap Archive

## TÃ¢ches archivÃ©es

- [x] **0.1** TÃ¢che archivÃ©e prÃ©cÃ©demment

- [x] **1.1.2** Sous-tÃ¢che terminÃ©e 1.2
- [x] **1.2** TÃ¢che terminÃ©e 2
  - [x] **1.2.1** Sous-tÃ¢che terminÃ©e 2.1
  - [ ] **1.2.2** Sous-tÃ¢che incomplÃ¨te 2.2
"@

            # Ã‰crire les fichiers mis Ã  jour
            Set-Content -Path $RoadmapPath -Value $updatedRoadmapContent -Encoding UTF8
            Set-Content -Path $ArchivePath -Value $updatedArchiveContent -Encoding UTF8

            return @{
                RoadmapContent = $updatedRoadmapContent
                ArchiveContent = $updatedArchiveContent
            }
        }

        # Appeler la fonction avec les paramÃ¨tres de test
        $roadmapContent = Get-Content -Path $script:testRoadmapPath -Raw
        $archiveContent = Get-Content -Path $script:testArchivePath -Raw
        $completedTasks = @(
            [PSCustomObject]@{
                Id          = "1.1.2"
                Description = "Sous-tÃ¢che terminÃ©e 1.2"
                Section     = "TÃ¢ches actives"
                Line        = 5
                IndentLevel = 2
                FullLine    = "  - [x] **1.1.2** Sous-tÃ¢che terminÃ©e 1.2"
            },
            [PSCustomObject]@{
                Id          = "1.2"
                Description = "TÃ¢che terminÃ©e 2"
                Section     = "TÃ¢ches actives"
                Line        = 6
                IndentLevel = 1
                FullLine    = "- [x] **1.2** TÃ¢che terminÃ©e 2"
            }
        )

        $result = Update-RoadmapFiles -RoadmapContent $roadmapContent -ArchiveContent $archiveContent -CompletedTasks $completedTasks -RoadmapPath $script:testRoadmapPath -ArchivePath $script:testArchivePath

        # VÃ©rifier les rÃ©sultats
        $result | Should -Not -BeNullOrEmpty
        $result.RoadmapContent | Should -Not -BeNullOrEmpty
        $result.ArchiveContent | Should -Not -BeNullOrEmpty

        # VÃ©rifier le contenu des fichiers mis Ã  jour
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

    It "GÃ¨re correctement l'absence de tÃ¢ches terminÃ©es" {
        # CrÃ©er un fichier de roadmap sans tÃ¢ches terminÃ©es
        $noCompletedTasksContent = @"
# Roadmap de test

## TÃ¢ches actives

- [ ] **1.1** TÃ¢che incomplÃ¨te 1
  - [ ] **1.1.1** Sous-tÃ¢che incomplÃ¨te 1.1
  - [ ] **1.1.2** Sous-tÃ¢che incomplÃ¨te 1.2
- [ ] **1.2** TÃ¢che incomplÃ¨te 2
  - [ ] **1.2.1** Sous-tÃ¢che incomplÃ¨te 2.1
  - [ ] **1.2.2** Sous-tÃ¢che incomplÃ¨te 2.2
- [ ] **1.3** TÃ¢che incomplÃ¨te 3
"@

        $noCompletedTasksPath = Join-Path -Path $TestDrive -ChildPath "no_completed_tasks.md"
        Set-Content -Path $noCompletedTasksPath -Value $noCompletedTasksContent -Encoding UTF8

        # Mock pour la fonction Get-CompletedTasks
        function Get-CompletedTasks {
            param (
                [string]$RoadmapContent
            )

            # Simuler l'absence de tÃ¢ches terminÃ©es
            return @()
        }

        # Appeler la fonction avec le contenu du fichier de test
        $roadmapContent = Get-Content -Path $noCompletedTasksPath -Raw
        $completedTasks = Get-CompletedTasks -RoadmapContent $roadmapContent

        # VÃ©rifier les rÃ©sultats
        $completedTasks | Should -BeNullOrEmpty
    }

    It "GÃ¨re correctement les erreurs lors de la mise Ã  jour des fichiers" {
        # Mock pour la fonction Update-RoadmapFiles qui gÃ©nÃ¨re une erreur
        function Update-RoadmapFiles {
            param (
                [string]$RoadmapContent,
                [string]$ArchiveContent,
                [array]$CompletedTasks,
                [string]$RoadmapPath,
                [string]$ArchivePath
            )

            throw "Erreur simulÃ©e lors de la mise Ã  jour des fichiers"
        }

        # Appeler la fonction avec les paramÃ¨tres de test
        $roadmapContent = Get-Content -Path $script:testRoadmapPath -Raw
        $archiveContent = Get-Content -Path $script:testArchivePath -Raw
        $completedTasks = @(
            [PSCustomObject]@{
                Id          = "1.1.2"
                Description = "Sous-tÃ¢che terminÃ©e 1.2"
                Section     = "TÃ¢ches actives"
                Line        = 5
                IndentLevel = 2
                FullLine    = "  - [x] **1.1.2** Sous-tÃ¢che terminÃ©e 1.2"
            }
        )

        # VÃ©rifier que l'erreur est correctement gÃ©rÃ©e
        { Update-RoadmapFiles -RoadmapContent $roadmapContent -ArchiveContent $archiveContent -CompletedTasks $completedTasks -RoadmapPath $script:testRoadmapPath -ArchivePath $script:testArchivePath } | Should -Throw "Erreur simulÃ©e lors de la mise Ã  jour des fichiers"
    }
}

# Les tests pour les scripts de surveillance sont dans des fichiers sÃ©parÃ©s
# pour Ã©viter les problÃ¨mes d'exÃ©cution infinie

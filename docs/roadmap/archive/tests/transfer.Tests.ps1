<#
.SYNOPSIS
Tests unitaires pour transfer.ps1
#>

BeforeAll {
    . $PSScriptRoot/../transfer.ps1
    $testDir = "TestDrive:/roadmap_test"
    New-Item -Path $testDir -ItemType Directory -Force
    New-Item -Path "$testDir/archive" -ItemType Directory -Force
    New-Item -Path "$testDir/logs" -ItemType Directory -Force
}

Describe "Tests de transfert" {
    Context "Détection sections" {
        BeforeEach {
            @"
# Roadmap
## Section 1
- [x] Tâche 1
- [ ] Tâche 2

## Section 2
Status: 100% Complete
"@ | Out-File "$testDir/roadmap.md"
        }

        It "Détecte 2 sections complètes" {
            $count = . "$PSScriptRoot/../transfer.ps1" -DryRun -RoadmapFile "$testDir/roadmap.md"
            $count | Should -Be 2
        }
    }

    Context "Transfert réel" {
        BeforeEach {
            @"
# Roadmap
## Section A
- [x] Tâche A

## Section B
Status: 100% Complete
"@ | Out-File "$testDir/roadmap.md"
        }

        It "Transfère correctement les sections" {
            . "$PSScriptRoot/../transfer.ps1" -RoadmapFile "$testDir/roadmap.md" -ArchiveFile "$testDir/archive/archive.md"

            $archive = Get-Content "$testDir/archive/archive.md" -Raw
            $archive | Should -Match "Section A" -Because "doit contenir Section A"
            $archive | Should -Match "Section B" -Because "doit contenir Section B"
            $archive | Should -Match "Archived" -Because "doit avoir la date"

            $roadmap = Get-Content "$testDir/roadmap.md" -Raw
            $roadmap | Should -Not -Match "Section A" -Because "doit supprimer Section A"
            $roadmap | Should -Not -Match "Section B" -Because "doit supprimer Section B"
            $roadmap | Should -Match "Tâches archivées" -Because "doit ajouter le lien"
        }
    }

    Context "Gestion erreurs" {
        It "Lève une exception si fichier inexistant" {
            { . "$PSScriptRoot/../transfer.ps1" -RoadmapFile "$testDir/inexistant.md" } |
                Should -Throw -ExceptionType ([System.IO.FileNotFoundException])
        }
    }
}

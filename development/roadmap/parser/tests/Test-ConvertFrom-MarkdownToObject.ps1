<#
.SYNOPSIS
    Tests pour la fonction ConvertFrom-MarkdownToObject.

.DESCRIPTION
    Ce script contient des tests pour valider le fonctionnement de la fonction ConvertFrom-MarkdownToObject.
    Il utilise le framework Pester pour exÃ©cuter les tests.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
#>

# Importer la fonction Ã  tester
$functionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToObject.ps1"
. $functionPath

# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\tests\temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

Describe "ConvertFrom-MarkdownToObject" {
    BeforeAll {
        # CrÃ©er un fichier markdown de test simple
        $simpleMarkdownPath = Join-Path -Path $testDir -ChildPath "simple.md"
        @"
# Roadmap Simple

Ceci est une roadmap simple pour les tests.

## Section 1

- [ ] TÃ¢che 1
  - [x] **1.1** TÃ¢che 1.1
  - [ ] **1.2** TÃ¢che 1.2
    - [~] **1.2.1** TÃ¢che 1.2.1 @john #important
    - [!] **1.2.2** TÃ¢che 1.2.2 P1

## Section 2

- [ ] **2** TÃ¢che 2
  - [ ] **2.1** TÃ¢che 2.1 @date:2023-12-31
"@ | Out-File -FilePath $simpleMarkdownPath -Encoding UTF8

        # CrÃ©er un fichier markdown avec diffÃ©rents encodages
        $utf8MarkdownPath = Join-Path -Path $testDir -ChildPath "utf8.md"
        $utf8WithBomMarkdownPath = Join-Path -Path $testDir -ChildPath "utf8-bom.md"
        $unicodeMarkdownPath = Join-Path -Path $testDir -ChildPath "unicode.md"

        $content = "# Test d'encodage`n`n- [ ] TÃ¢che avec caractÃ¨res accentuÃ©s"

        # UTF-8 sans BOM
        $content | Out-File -FilePath $utf8MarkdownPath -Encoding UTF8

        # UTF-8 avec BOM
        $utf8Bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
        $utf8WithBomBytes = [System.Text.Encoding]::UTF8.GetPreamble() + $utf8Bytes
        [System.IO.File]::WriteAllBytes($utf8WithBomMarkdownPath, $utf8WithBomBytes)

        # Unicode
        $content | Out-File -FilePath $unicodeMarkdownPath -Encoding Unicode
    }

    AfterAll {
        # Nettoyer les fichiers de test
        $tempDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\roadmap-parser\tests\temp"
        if (Test-Path -Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
    }

    Context "Validation des paramÃ¨tres" {
        It "Devrait lever une exception si le fichier n'existe pas" {
            { ConvertFrom-MarkdownToObject -FilePath "fichier_inexistant.md" } | Should -Throw
        }

        It "Devrait accepter un chemin de fichier valide" {
            $simpleMarkdownPath = Join-Path -Path $testDir -ChildPath "simple.md"
            { ConvertFrom-MarkdownToObject -FilePath $simpleMarkdownPath } | Should -Not -Throw
        }
    }

    Context "Parsing de base" {
        It "Devrait extraire le titre et la description" {
            $simpleMarkdownPath = Join-Path -Path $testDir -ChildPath "simple.md"
            $result = ConvertFrom-MarkdownToObject -FilePath $simpleMarkdownPath

            $result.Title | Should -Be "Roadmap Simple"
            $result.Description | Should -Be "Ceci est une roadmap simple pour les tests."
        }

        It "Devrait extraire les sections" {
            $simpleMarkdownPath = Join-Path -Path $testDir -ChildPath "simple.md"
            $result = ConvertFrom-MarkdownToObject -FilePath $simpleMarkdownPath

            $result.Items.Count | Should -BeGreaterThan 0
            $result.Items[0].Title | Should -Be "Section 1"
            $result.Items[1].Title | Should -Be "Section 2"
        }

        It "Devrait extraire les tÃ¢ches avec leurs statuts" {
            $simpleMarkdownPath = Join-Path -Path $testDir -ChildPath "simple.md"
            $result = ConvertFrom-MarkdownToObject -FilePath $simpleMarkdownPath

            $section1 = $result.Items[0]
            $section1.Items.Count | Should -BeGreaterThan 0
            $section1.Items[0].Status | Should -Be "Incomplete"

            $task1_1 = $section1.Items[0].Items[0]
            $task1_1.Status | Should -Be "Complete"
            $task1_1.Id | Should -Be "1.1"

            $task1_2_1 = $section1.Items[0].Items[1].Items[0]
            $task1_2_1.Status | Should -Be "InProgress"
            $task1_2_1.Id | Should -Be "1.2.1"

            $task1_2_2 = $section1.Items[0].Items[1].Items[1]
            $task1_2_2.Status | Should -Be "Blocked"
            $task1_2_2.Id | Should -Be "1.2.2"
        }
    }

    Context "Extraction des mÃ©tadonnÃ©es" {
        It "Devrait extraire les mÃ©tadonnÃ©es quand IncludeMetadata est spÃ©cifiÃ©" {
            $simpleMarkdownPath = Join-Path -Path $testDir -ChildPath "simple.md"
            $result = ConvertFrom-MarkdownToObject -FilePath $simpleMarkdownPath -IncludeMetadata

            $section1 = $result.Items[0]
            $task1_2_1 = $section1.Items[0].Items[1].Items[0]
            $task1_2_1.Metadata["Assignee"] | Should -Be "john"
            $task1_2_1.Metadata["Tags"] | Should -Contain "important"

            $task1_2_2 = $section1.Items[0].Items[1].Items[1]
            $task1_2_2.Metadata["Priority"] | Should -Be "P1"

            $section2 = $result.Items[1]
            $task2_1 = $section2.Items[0].Items[0]
            $task2_1.Metadata["Date"] | Should -Be ([datetime]"2023-12-31")
        }

        It "Ne devrait pas extraire les mÃ©tadonnÃ©es quand IncludeMetadata n'est pas spÃ©cifiÃ©" {
            $simpleMarkdownPath = Join-Path -Path $testDir -ChildPath "simple.md"
            $result = ConvertFrom-MarkdownToObject -FilePath $simpleMarkdownPath

            $section1 = $result.Items[0]
            $task1_2_1 = $section1.Items[0].Items[1].Items[0]
            $task1_2_1.Metadata.Count | Should -Be 0
        }
    }

    Context "Gestion des encodages" {
        It "Devrait traiter correctement un fichier UTF-8 sans BOM" {
            $utf8MarkdownPath = Join-Path -Path $testDir -ChildPath "utf8.md"
            $result = ConvertFrom-MarkdownToObject -FilePath $utf8MarkdownPath

            $result.Title | Should -Be "Test d'encodage"
            $result.Items[0].Title | Should -Match "caractÃ¨res accentuÃ©s"
        }

        It "Devrait traiter correctement un fichier UTF-8 avec BOM" {
            $utf8WithBomMarkdownPath = Join-Path -Path $testDir -ChildPath "utf8-bom.md"
            $result = ConvertFrom-MarkdownToObject -FilePath $utf8WithBomMarkdownPath

            $result.Title | Should -Be "Test d'encodage"
            $result.Items[0].Title | Should -Match "caractÃ¨res accentuÃ©s"
        }

        It "Devrait traiter correctement un fichier Unicode" {
            $unicodeMarkdownPath = Join-Path -Path $testDir -ChildPath "unicode.md"
            $result = ConvertFrom-MarkdownToObject -FilePath $unicodeMarkdownPath -Encoding Unicode

            $result.Title | Should -Be "Test d'encodage"
            $result.Items[0].Title | Should -Match "caractÃ¨res accentuÃ©s"
        }
    }

    Context "Marqueurs de statut personnalisÃ©s" {
        It "Devrait utiliser des marqueurs de statut personnalisÃ©s" {
            $simpleMarkdownPath = Join-Path -Path $testDir -ChildPath "simple.md"
            $customMarkers = @{
                "x" = "InProgress"; # Remplacer Complete par InProgress
                "~" = "Complete"     # Remplacer InProgress par Complete
            }

            $result = ConvertFrom-MarkdownToObject -FilePath $simpleMarkdownPath -CustomStatusMarkers $customMarkers

            $section1 = $result.Items[0]
            $task1_1 = $section1.Items[0].Items[0]
            $task1_1.Status | Should -Be "InProgress"  # Ã‰tait Complete, maintenant InProgress

            $task1_2_1 = $section1.Items[0].Items[1].Items[0]
            $task1_2_1.Status | Should -Be "Complete"  # Ã‰tait InProgress, maintenant Complete
        }
    }
}

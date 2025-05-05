using module Pester

# DÃ©finir l'encodage UTF-8 pour les caractÃ¨res accentuÃ©s
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

BeforeAll {
    # Charger le script Ã  tester
    . $PSScriptRoot\..\identify-document-sections.ps1
}

Describe 'Document Sections Tests' {
    Context 'Extraction des sections' {
        BeforeAll {
            $testContent = @"
# Titre Principal 1

Contenu du titre principal 1.

## Sous-titre 1.1

Contenu du sous-titre 1.1.

### Sous-sous-titre 1.1.1

Contenu du sous-sous-titre 1.1.1.

## Sous-titre 1.2

Contenu du sous-titre 1.2.

# Titre Principal 2

Contenu du titre principal 2.

## Sous-titre 2.1

Contenu du sous-titre 2.1.
"@
            $sections = Get-DocumentSections -Content $testContent
        }

        It 'Devrait extraire le bon nombre de sections' {
            $sections.Count | Should -Be 6
        }

        It 'Devrait extraire les titres principaux' {
            $sections[0].Title | Should -Be 'Titre Principal 1'
            $sections[0].Level | Should -Be 1
            $sections[4].Title | Should -Be 'Titre Principal 2'
            $sections[4].Level | Should -Be 1
        }

        It 'Devrait extraire les sous-titres' {
            $sections[1].Title | Should -Be 'Sous-titre 1.1'
            $sections[1].Level | Should -Be 2
            $sections[3].Title | Should -Be 'Sous-titre 1.2'
            $sections[3].Level | Should -Be 2
            $sections[5].Title | Should -Be 'Sous-titre 2.1'
            $sections[5].Level | Should -Be 2
        }

        It 'Devrait extraire les sous-sous-titres' {
            $sections[2].Title | Should -Be 'Sous-sous-titre 1.1.1'
            $sections[2].Level | Should -Be 3
        }

        It 'Devrait capturer le contenu des sections' {
            $sections[0].Content | Should -Match 'Contenu du titre principal 1.'
            $sections[1].Content | Should -Match 'Contenu du sous-titre 1.1.'
            $sections[2].Content | Should -Match 'Contenu du sous-sous-titre 1.1.1.'
        }
    }

    Context 'GÃ©nÃ©ration du rapport' {
        BeforeAll {
            $testSections = @(
                [PSCustomObject]@{
                    Title      = 'Titre Principal 1'
                    Level      = 1
                    Content    = 'Contenu du titre principal 1.'
                    LineNumber = 1
                },
                [PSCustomObject]@{
                    Title      = 'Sous-titre 1.1'
                    Level      = 2
                    Content    = 'Contenu du sous-titre 1.1.'
                    LineNumber = 3
                },
                [PSCustomObject]@{
                    Title      = 'Titre Principal 2'
                    Level      = 1
                    Content    = 'Contenu du titre principal 2.'
                    LineNumber = 5
                }
            )
            $report = New-SectionsReport -Sections $testSections -IncludeContent $false
        }

        It 'Devrait gÃ©nÃ©rer un rapport avec la structure hiÃ©rarchique' {
            $report | Should -Match 'Structure HiÃ©rarchique'
            $report | Should -Match 'Titre Principal 1'
            $report | Should -Match 'Sous-titre 1.1'
            $report | Should -Match 'Titre Principal 2'
        }

        It 'Devrait inclure l''analyse des sections' {
            $report | Should -Match 'Analyse des Sections'
            $report | Should -Match 'Distribution par Niveau'
            $report | Should -Match 'Sections Principales'
        }
    }


}

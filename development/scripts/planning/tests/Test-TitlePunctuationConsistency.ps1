# Importer Pester
Import-Module Pester -ErrorAction Stop

# DÃ©finir le chemin du script Ã  tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\analyze-title-punctuation-consistency.ps1"

Describe "Analyse de la cohÃ©rence de la ponctuation entre niveaux de titres" {
    BeforeAll {
        # CrÃ©er un fichier markdown temporaire pour les tests
        $testContent = @"
# Titre Principal: Introduction

Contenu du titre principal.

## Sous-titre 1.1

Contenu du sous-titre 1.1.

### Sous-sous-titre 1.1.1: DÃ©tails

Contenu du sous-sous-titre 1.1.1.

## Sous-titre 1.2: Contexte

Contenu du sous-titre 1.2.

# Titre Principal 2

Contenu du titre principal 2.

## Sous-titre 2.1: Analyse

Contenu du sous-titre 2.1.

### Sous-sous-titre 2.1.1

Contenu du sous-sous-titre 2.1.1.

### Sous-sous-titre 2.1.2: RÃ©sultats

Contenu du sous-sous-titre 2.1.2.

## Sous-titre 2.2

Contenu du sous-titre 2.2.

### Sous-sous-titre 2.2.1: Conclusion

Contenu du sous-sous-titre 2.2.1.
"@

        $testFilePath = Join-Path -Path $TestDrive -ChildPath "test-document.md"
        $testOutputPath = Join-Path -Path $TestDrive -ChildPath "test-output.md"

        Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8
    }

    Context "GÃ©nÃ©ration du rapport" {
        BeforeAll {
            # ExÃ©cuter le script une seule fois pour tous les tests
            & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeExamples $true

            # VÃ©rifier que le rapport a Ã©tÃ© gÃ©nÃ©rÃ©
            $script:reportExists = Test-Path -Path $testOutputPath

            if ($script:reportExists) {
                $script:reportContent = Get-Content -Path $testOutputPath -Raw
            }
        }

        It "Devrait gÃ©nÃ©rer un rapport d'analyse" {
            # VÃ©rifier que le rapport a Ã©tÃ© gÃ©nÃ©rÃ©
            $script:reportExists | Should -Be $true

            # VÃ©rifier le contenu du rapport
            $script:reportContent | Should -Match "Analyse de la CohÃ©rence de la Ponctuation entre Niveaux de Titres"
            $script:reportContent | Should -Match "Analyse par Niveau de Titre"
            $script:reportContent | Should -Match "Analyse de CohÃ©rence entre Niveaux"
            $script:reportContent | Should -Match "Recommandations"
        }

        It "Devrait contenir des informations sur les niveaux de titres" {
            # VÃ©rifier que le rapport contient des informations sur les niveaux
            $script:reportContent | Should -Match "Niveau 1"
            $script:reportContent | Should -Match "Niveau 2"
            $script:reportContent | Should -Match "Niveau 3"
        }

        It "Devrait contenir des informations sur la ponctuation" {
            # VÃ©rifier que le rapport contient des informations sur la ponctuation
            $script:reportContent | Should -Match "Marques de ponctuation"
            $script:reportContent | Should -Match ":"  # VÃ©rifier que les deux-points sont mentionnÃ©s
        }
    }
}

# Importer Pester
Import-Module Pester -ErrorAction Stop

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\analyze-title-hierarchy.ps1"

Describe "Analyse de la hiérarchie des titres" {
    BeforeAll {
        # Créer un fichier markdown temporaire pour les tests
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

Titre avec soulignement
======================

Contenu du titre avec soulignement.

Sous-titre avec soulignement
---------------------------

Contenu du sous-titre avec soulignement.
"@

        $testFilePath = Join-Path -Path $TestDrive -ChildPath "test-document.md"
        $testOutputPath = Join-Path -Path $TestDrive -ChildPath "test-output.md"
        
        Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8
    }

    Context "Extraction des sections" {
        It "Devrait extraire toutes les sections du document" {
            # Exécuter le script avec les paramètres de test
            $result = & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeFormatAnalysis $true
            
            # Vérifier que le résultat contient les sections attendues
            $result.Sections.Count | Should -Be 8
        }

        It "Devrait identifier correctement les niveaux des titres" {
            $result = & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeFormatAnalysis $true
            
            # Vérifier les niveaux des titres
            $level1Count = ($result.Sections | Where-Object { $_.Level -eq 1 }).Count
            $level2Count = ($result.Sections | Where-Object { $_.Level -eq 2 }).Count
            $level3Count = ($result.Sections | Where-Object { $_.Level -eq 3 }).Count
            
            $level1Count | Should -Be 3  # 2 avec # et 1 avec soulignement =
            $level2Count | Should -Be 4  # 3 avec ## et 1 avec soulignement -
            $level3Count | Should -Be 1  # 1 avec ###
        }
    }

    Context "Analyse de la hiérarchie" {
        It "Devrait calculer correctement la profondeur maximale" {
            $result = & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeFormatAnalysis $true
            
            $result.Hierarchy.MaxDepth | Should -Be 3
        }

        It "Devrait identifier correctement les relations parent-enfant" {
            $result = & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeFormatAnalysis $true
            
            # Vérifier que les titres principaux ont le bon nombre d'enfants
            $parentChildRelations = $result.Hierarchy.ParentChildRelations
            
            # Trouver les clés qui correspondent aux titres de niveau 1
            $level1Keys = $parentChildRelations.Keys | Where-Object { $_ -match "^1:" }
            
            # Vérifier que "Titre Principal 1" a 2 enfants directs
            $titlePrincipal1Key = $level1Keys | Where-Object { $_ -match "Titre Principal 1" }
            $parentChildRelations[$titlePrincipal1Key].Count | Should -Be 2
            
            # Vérifier que "Titre Principal 2" a 1 enfant direct
            $titlePrincipal2Key = $level1Keys | Where-Object { $_ -match "Titre Principal 2" }
            $parentChildRelations[$titlePrincipal2Key].Count | Should -Be 1
        }
    }

    Context "Analyse des formats de titres" {
        It "Devrait détecter les titres avec syntaxe #" {
            $result = & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeFormatAnalysis $true
            
            $result.TitleFormats.HashHeaders[1] | Should -Be 2  # 2 titres de niveau 1 avec #
            $result.TitleFormats.HashHeaders[2] | Should -Be 3  # 3 titres de niveau 2 avec ##
            $result.TitleFormats.HashHeaders[3] | Should -Be 1  # 1 titre de niveau 3 avec ###
        }

        It "Devrait détecter les titres avec syntaxe de soulignement" {
            $result = & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeFormatAnalysis $true
            
            $result.TitleFormats.UnderlineHeaders[1] | Should -Be 1  # 1 titre de niveau 1 avec =
            $result.TitleFormats.UnderlineHeaders[2] | Should -Be 1  # 1 titre de niveau 2 avec -
        }
    }

    Context "Génération du rapport" {
        It "Devrait générer un rapport d'analyse" {
            & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeFormatAnalysis $true
            
            Test-Path -Path $testOutputPath | Should -Be $true
            $reportContent = Get-Content -Path $testOutputPath -Raw
            
            $reportContent | Should -Match "Analyse de la Hiérarchie des Titres et Sous-titres"
            $reportContent | Should -Match "Structure Hiérarchique"
            $reportContent | Should -Match "Relations Parent-Enfant"
            $reportContent | Should -Match "Observations et Recommandations"
        }
    }
}

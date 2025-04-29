# Importer Pester
Import-Module Pester -ErrorAction Stop

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\analyze-title-casing.ps1"

Describe "Analyse des conventions de casse dans les titres" {
    BeforeAll {
        # Créer un fichier markdown temporaire pour les tests
        $testContent = @"
# Titre Principal en Title Case
Contenu du titre principal.

## Un Autre Titre en Title Case
Contenu du sous-titre.

### titre en minuscules
Contenu du sous-sous-titre.

#### TITRE EN MAJUSCULES
Contenu du sous-sous-sous-titre.

##### Titre en Sentence case avec des mots en minuscules
Contenu du sous-sous-sous-sous-titre.

###### camelCaseTitle
Contenu du sous-sous-sous-sous-sous-titre.

# PascalCaseTitle
Contenu d'un autre titre principal.

Titre avec soulignement
======================
Contenu du titre avec soulignement.

sous-titre avec soulignement
---------------------------
Contenu du sous-titre avec soulignement.
"@

        $testFilePath = Join-Path -Path $TestDrive -ChildPath "test-document.md"
        $testOutputPath = Join-Path -Path $TestDrive -ChildPath "test-output.md"
        
        Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8
    }

    Context "Extraction des titres" {
        It "Devrait extraire tous les titres du document" {
            # Exécuter le script avec les paramètres de test
            $result = & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeExamples $true
            
            # Vérifier que le résultat contient le bon nombre de titres
            $result.TotalTitles | Should -Be 9
        }
    }

    Context "Analyse des styles de casse" {
        It "Devrait identifier correctement les différents styles de casse" {
            $result = & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeExamples $true
            
            # Vérifier que tous les styles de casse sont détectés
            $result.CasingStyles.Keys | Should -Contain "Title Case"
            $result.CasingStyles.Keys | Should -Contain "all_lowercase"
            $result.CasingStyles.Keys | Should -Contain "ALL_CAPS"
            $result.CasingStyles.Keys | Should -Contain "Sentence case"
            $result.CasingStyles.Keys | Should -Contain "camelCase"
            $result.CasingStyles.Keys | Should -Contain "PascalCase"
        }

        It "Devrait calculer correctement les statistiques par style de casse" {
            $result = & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeExamples $true
            
            # Vérifier les comptages de styles
            $result.CasingStyles["Title Case"] | Should -Be 2
            $result.CasingStyles["all_lowercase"] | Should -Be 1
            $result.CasingStyles["ALL_CAPS"] | Should -Be 1
            $result.CasingStyles["Sentence case"] | Should -Be 1
            $result.CasingStyles["camelCase"] | Should -Be 1
            $result.CasingStyles["PascalCase"] | Should -Be 1
        }
    }

    Context "Analyse par niveau de titre" {
        It "Devrait analyser correctement les styles par niveau de titre" {
            $result = & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeExamples $true
            
            # Vérifier l'analyse du niveau 1
            $result.ByLevel[1] | Should -Not -BeNullOrEmpty
            $result.ByLevel[1]["Title Case"] | Should -Be 1
            $result.ByLevel[1]["PascalCase"] | Should -Be 1
            
            # Vérifier l'analyse du niveau 2
            $result.ByLevel[2] | Should -Not -BeNullOrEmpty
            $result.ByLevel[2]["Title Case"] | Should -Be 1
            
            # Vérifier l'analyse du niveau 3
            $result.ByLevel[3] | Should -Not -BeNullOrEmpty
            $result.ByLevel[3]["all_lowercase"] | Should -Be 1
        }
    }

    Context "Calcul de la cohérence" {
        It "Devrait calculer correctement la cohérence globale" {
            $result = & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeExamples $true
            
            # Vérifier que la cohérence globale est calculée
            $result.Consistency.OverallConsistency | Should -BeGreaterThan 0
            
            # Vérifier que le style dominant est identifié
            $result.Consistency.DominantStyle | Should -Not -BeNullOrEmpty
            $result.Consistency.DominantStylePercentage | Should -BeGreaterThan 0
        }

        It "Devrait calculer correctement la cohérence par niveau" {
            $result = & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeExamples $true
            
            # Vérifier la cohérence du niveau 1
            $result.Consistency.ConsistencyByLevel[1] | Should -Not -BeNullOrEmpty
            $result.Consistency.ConsistencyByLevel[1].Consistency | Should -BeGreaterThan 0
            
            # Vérifier la cohérence du niveau 2
            $result.Consistency.ConsistencyByLevel[2] | Should -Not -BeNullOrEmpty
            $result.Consistency.ConsistencyByLevel[2].Consistency | Should -Be 100
        }
    }

    Context "Génération du rapport" {
        It "Devrait générer un rapport d'analyse" {
            & $scriptPath -FilePath $testFilePath -OutputPath $testOutputPath -IncludeExamples $true
            
            Test-Path -Path $testOutputPath | Should -Be $true
            $reportContent = Get-Content -Path $testOutputPath -Raw
            
            $reportContent | Should -Match "Analyse des Conventions de Casse dans les Titres"
            $reportContent | Should -Match "Distribution des Styles de Casse"
            $reportContent | Should -Match "Analyse par Niveau de Titre"
            $reportContent | Should -Match "Recommandations"
        }

        It "Devrait inclure ou exclure les exemples selon le paramètre" {
            # Test avec exemples
            & $scriptPath -FilePath $testFilePath -OutputPath "$testOutputPath-with-examples.md" -IncludeExamples $true
            $withExamples = Get-Content -Path "$testOutputPath-with-examples.md" -Raw
            $withExamples | Should -Match "Exemples par Style de Casse"
            
            # Test sans exemples
            & $scriptPath -FilePath $testFilePath -OutputPath "$testOutputPath-without-examples.md" -IncludeExamples $false
            $withoutExamples = Get-Content -Path "$testOutputPath-without-examples.md" -Raw
            $withoutExamples | Should -Not -Match "Exemples par Style de Casse"
        }
    }
}

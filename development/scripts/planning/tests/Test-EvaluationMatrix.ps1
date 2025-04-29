using module Pester
BeforeAll {
    . $PSScriptRoot\..\apply-evaluation-matrix.ps1
}

Describe 'Matrice Evaluation Tests' {
    BeforeAll {
        $testDataPath = "TestDrive:\data"
        New-Item -ItemType Directory -Path $testDataPath -Force
    }

    Context 'Validation des fichiers' {
        It 'Vérifie la création du fichier de sortie' {
            $outputPath = Join-Path $testDataPath "skills-evaluation.md"
            New-EvaluationReport -EvaluatedSkills @() -OutputPath $outputPath
            Test-Path $outputPath | Should -Be $true
        }
    }

    Context 'Extraction des critères' {
        BeforeAll {
            $expertiseLevelsContent = @"
# Niveaux d'Expertise
## Critères
### Complexité Technique
- Niveau 1: Tâches simples
- Niveau 2: Complexité moyenne
- Niveau 3: Haute complexité
"@
            $expertiseLevelsPath = Join-Path $testDataPath "expertise-levels.md"
            Set-Content -Path $expertiseLevelsPath -Value $expertiseLevelsContent
        }

        It 'Extrait correctement les critères' {
            $criteria = Get-EvaluationCriteria -FilePath $expertiseLevelsPath
            $criteria.Count | Should -BeGreaterThan 0
            $criteria[0].Name | Should -Be 'Complexité Technique'
        }
    }

    Context 'Évaluation des compétences' {
        It 'Calcule correctement le score global' {
            $skill = "Test Skill"
            $criteria = @(
                @{
                    Name   = "Critère 1"
                    Weight = 1
                    Levels = @{ "Niveau 1" = 1; "Niveau 2" = 2 }
                }
            )
            $evaluation = Evaluate-Skill -Skill $skill -Criteria $criteria
            $evaluation | Should -Not -BeNullOrEmpty
            $evaluation.GlobalScore | Should -BeGreaterThanOrEqual 0
        }
    }

    Context 'Génération du rapport' {
        It 'Inclut tous les éléments requis' {
            $outputPath = Join-Path $testDataPath "skills-evaluation.md"
            $evaluatedSkills = @(
                @{
                    Name           = "Test Skill"
                    Category       = "Test Category"
                    Scores         = @{ "Critère 1" = 2 }
                    GlobalScore    = 2
                    ExpertiseLevel = "Intermédiaire"
                    Justification  = "Test justification"
                }
            )

            New-EvaluationReport -EvaluatedSkills $evaluatedSkills -OutputPath $outputPath
            $content = Get-Content $outputPath -Raw

            $content | Should -Match "# Évaluation des Compétences"
            $content | Should -Match "## Table des matières"
            $content | Should -Match "## Méthodologie"
            $content | Should -Match "## Résultats"
            $content | Should -Match "\| Compétence \| Catégorie \|"
        }
    }
}

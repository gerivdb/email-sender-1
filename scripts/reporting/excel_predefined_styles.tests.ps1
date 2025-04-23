# Tests pour le module excel_predefined_styles.ps1

# Importer Pester
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Importer le module à tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "excel_predefined_styles.ps1"
. $ModulePath

Describe "Excel Predefined Styles Module" {
    BeforeAll {
        # Réinitialiser le registre avant chaque test
        Reset-ExcelStyleRegistry

        # Initialiser les styles prédéfinis
        Initialize-ExcelPredefinedStyles -Force
    }

    Context "Initialize-ExcelLineStyleLibrary function" {
        It "Should initialize line styles in the registry" {
            # Réinitialiser le registre
            Reset-ExcelStyleRegistry

            # Initialiser les styles de lignes
            $Count = Initialize-ExcelLineStyleLibrary

            # Vérifier que des styles ont été ajoutés
            $Count | Should -BeGreaterThan 0

            # Vérifier que les styles sont dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Registry.LineStyles.Count | Should -Be $Count

            # Vérifier quelques styles spécifiques
            $Registry.GetByName("Ligne continue fine") | Should -Not -BeNullOrEmpty
            $Registry.GetByName("Ligne pointillée moyenne") | Should -Not -BeNullOrEmpty
            $Registry.GetByName("Ligne en tirets épaisse") | Should -Not -BeNullOrEmpty
            $Registry.GetByName("Ligne rouge") | Should -Not -BeNullOrEmpty
        }
    }

    Context "Get-ExcelPredefinedLineStyle function" {
        It "Should get a predefined line style by name" {
            # Obtenir un style par nom
            $Style = Get-ExcelPredefinedLineStyle -Name "Ligne continue fine"

            # Vérifier le style
            $Style | Should -Not -BeNullOrEmpty
            $Style.Name | Should -Be "Ligne continue fine"
            $Style.Category | Should -Be "Lignes continues"
            $Style.LineConfig.Width | Should -Be 1
            $Style.LineConfig.Style | Should -Be ([ExcelLineStyle]::Solid)
            $Style.LineConfig.Color | Should -Be "#000000"
        }

        It "Should return null for non-existent style" {
            # Obtenir un style inexistant
            $Style = Get-ExcelPredefinedLineStyle -Name "Style inexistant"

            # Vérifier que le style est null
            $Style | Should -BeNullOrEmpty
        }
    }

    Context "Get-ExcelPredefinedLineStyles function" {
        It "Should get all predefined line styles" {
            # Obtenir tous les styles de ligne
            $Styles = Get-ExcelPredefinedLineStyles

            # Vérifier que des styles ont été retournés
            $Styles.Count | Should -BeGreaterThan 0

            # Vérifier que tous les styles sont des styles de ligne
            foreach ($Style in $Styles) {
                $Style | Should -BeOfType [ExcelLineStyle]
            }
        }

        It "Should include advanced dotted styles" {
            # Obtenir les styles de pointillés avancés
            $Styles = Get-ExcelPredefinedLineStyles -Category "Pointillés avancés"

            # Vérifier que des styles ont été retournés
            $Styles.Count | Should -BeGreaterThan 0

            # Vérifier que tous les styles sont des styles de pointillés avancés
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Pointillés avancés"
                $Style.HasTag("Pointillé") | Should -Be $true
            }
        }

        It "Should include advanced dash styles" {
            # Obtenir les styles de tirets avancés
            $Styles = Get-ExcelPredefinedLineStyles -Category "Tirets avancés"

            # Vérifier que des styles ont été retournés
            $Styles.Count | Should -BeGreaterThan 0

            # Vérifier que tous les styles sont des styles de tirets avancés
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Tirets avancés"
                $Style.HasTag("Tiret") | Should -Be $true
            }
        }

        It "Should include advanced dash-dot combinations" {
            # Obtenir les styles de combinaisons tiret-point avancées
            $Styles = Get-ExcelPredefinedLineStyles -Category "Combinaisons tiret-point avancées"

            # Vérifier que des styles ont été retournés
            $Styles.Count | Should -BeGreaterThan 0

            # Vérifier que tous les styles sont des styles de combinaisons tiret-point avancées
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Combinaisons tiret-point avancées"
                $Style.HasTag("Tiret-point") -or $Style.HasTag("Tiret-point-point") | Should -Be $true
            }
        }

        It "Should include spacing variations" {
            # Obtenir les styles de variations d'espacement
            $Styles = Get-ExcelPredefinedLineStyles -Category "Variations d'espacement"

            # Vérifier que des styles ont été retournés
            $Styles.Count | Should -BeGreaterThan 0

            # Vérifier que tous les styles sont des styles de variations d'espacement
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Variations d'espacement"
                $Style.HasTag("Espacement") -or $Style.HasTag("Motif") | Should -Be $true
            }
        }

        It "Should filter styles by category" {
            # Obtenir les styles de la catégorie "Lignes continues"
            $Styles = Get-ExcelPredefinedLineStyles -Category "Lignes continues"

            # Vérifier que des styles ont été retournés
            $Styles.Count | Should -BeGreaterThan 0

            # Vérifier que tous les styles sont de la catégorie spécifiée
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Lignes continues"
            }
        }

        It "Should filter styles by tag" {
            # Obtenir les styles avec le tag "Pointillé"
            $Styles = Get-ExcelPredefinedLineStyles -Tag "Pointillé"

            # Vérifier que des styles ont été retournés
            $Styles.Count | Should -BeGreaterThan 0

            # Vérifier que tous les styles ont le tag spécifié
            foreach ($Style in $Styles) {
                $Style.HasTag("Pointillé") | Should -Be $true
            }
        }

        It "Should filter styles by category and tag" {
            # Obtenir les styles de la catégorie "Lignes colorées" avec le tag "Rouge"
            $Styles = Get-ExcelPredefinedLineStyles -Category "Lignes colorées" -Tag "Rouge"

            # Vérifier que des styles ont été retournés
            $Styles.Count | Should -BeGreaterThan 0

            # Vérifier que tous les styles sont de la catégorie et ont le tag spécifiés
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Lignes colorées"
                $Style.HasTag("Rouge") | Should -Be $true
            }
        }
    }

    Context "Initialize-ExcelPredefinedStyles function" {
        It "Should initialize all predefined styles" {
            # Réinitialiser le registre
            Reset-ExcelStyleRegistry

            # Initialiser tous les styles prédéfinis
            $Count = Initialize-ExcelPredefinedStyles

            # Vérifier que des styles ont été ajoutés
            $Count | Should -BeGreaterThan 0

            # Vérifier que les styles sont dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Registry.Styles.Count | Should -Be $Count

            # Vérifier que tous les styles sont marqués comme prédéfinis
            $BuiltInStyles = $Registry.Search(@{ IsBuiltIn = $true })
            $BuiltInStyles.Count | Should -Be $Count
        }

        It "Should include harmonious color combinations" {
            # Obtenir les styles harmonieux
            $Styles = Get-ExcelPredefinedLineStyles -Category "Combinaisons harmonieuses"

            # Vérifier que des styles ont été retournés
            $Styles.Count | Should -BeGreaterThan 0

            # Vérifier que tous les styles sont des styles harmonieux
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Combinaisons harmonieuses"
                $Style.HasTag("Harmonieux") | Should -Be $true
            }
        }

        It "Should include coordinated sets" {
            # Obtenir les styles d'ensembles coordonnés
            $Styles = Get-ExcelPredefinedLineStyles -Category "Ensembles coordonnés"

            # Vérifier que des styles ont été retournés
            $Styles.Count | Should -BeGreaterThan 0

            # Vérifier que tous les styles sont des styles d'ensembles coordonnés
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Ensembles coordonnés"
                $Style.HasTag("Ensemble") | Should -Be $true
            }

            # Vérifier qu'il y a des styles pour l'ensemble 1
            $Ensemble1Styles = $Styles | Where-Object { $_.HasTag("Ensemble1") }
            $Ensemble1Styles.Count | Should -BeGreaterThan 0

            # Vérifier qu'il y a des styles pour l'ensemble 2
            $Ensemble2Styles = $Styles | Where-Object { $_.HasTag("Ensemble2") }
            $Ensemble2Styles.Count | Should -BeGreaterThan 0
        }

        It "Should include color variations by line type" {
            # Obtenir les styles de variations par type
            $Styles = Get-ExcelPredefinedLineStyles -Category "Variations par type"

            # Vérifier que des styles ont été retournés
            $Styles.Count | Should -BeGreaterThan 0

            # Vérifier que tous les styles sont des styles de variations par type
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Variations par type"
                $Style.HasTag("Variable") -or $Style.HasTag("Dégradé") | Should -Be $true
            }
        }

        It "Should include special gradients" {
            # Obtenir les styles de dégradés spéciaux
            $Styles = Get-ExcelPredefinedLineStyles -Category "Dégradés spéciaux"

            # Vérifier que des styles ont été retournés
            $Styles.Count | Should -BeGreaterThan 0

            # Vérifier que tous les styles sont des styles de dégradés spéciaux
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Dégradés spéciaux"
                $Style.HasTag("Dégradé") | Should -Be $true
            }
        }

        It "Should not reinitialize styles without Force" {
            # Réinitialiser le registre
            Reset-ExcelStyleRegistry

            # Initialiser les styles une première fois
            $Count1 = Initialize-ExcelPredefinedStyles

            # Initialiser les styles une deuxième fois sans Force
            $Count2 = Initialize-ExcelPredefinedStyles

            # Vérifier que les styles n'ont pas été réinitialisés
            $Count2 | Should -Be $Count1

            # Vérifier que le nombre de styles dans le registre est correct
            $Registry = Get-ExcelStyleRegistry
            $Registry.Styles.Count | Should -Be $Count1
        }

        It "Should reinitialize styles with Force" {
            # Réinitialiser le registre
            Reset-ExcelStyleRegistry

            # Initialiser les styles une première fois
            $Count1 = Initialize-ExcelPredefinedStyles

            # Ajouter un style personnalisé
            $CustomStyle = [ExcelLineStyle]::new()
            $CustomStyle.Name = "Style personnalisé"
            $CustomStyle.IsBuiltIn = $false
            Add-ExcelStyle -Style $CustomStyle

            # Initialiser les styles une deuxième fois avec Force
            $Count2 = Initialize-ExcelPredefinedStyles -Force

            # Vérifier que les styles ont été réinitialisés
            $Count2 | Should -Be $Count1

            # Vérifier que le nombre de styles dans le registre est correct (styles prédéfinis + style personnalisé)
            $Registry = Get-ExcelStyleRegistry
            $Registry.Styles.Count | Should -Be ($Count1 + 1)

            # Vérifier que le style personnalisé est toujours présent
            $Registry.GetByName("Style personnalisé") | Should -Not -BeNullOrEmpty
        }
    }
}

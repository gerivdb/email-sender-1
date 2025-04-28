# Tests pour le module excel_predefined_styles.ps1

# Importer Pester
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Importer le module Ã  tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "excel_predefined_styles.ps1"
. $ModulePath

Describe "Excel Predefined Styles Module" {
    BeforeAll {
        # RÃ©initialiser le registre avant chaque test
        Reset-ExcelStyleRegistry

        # Initialiser les styles prÃ©dÃ©finis
        Initialize-ExcelPredefinedStyles -Force
    }

    Context "Initialize-ExcelLineStyleLibrary function" {
        It "Should initialize line styles in the registry" {
            # RÃ©initialiser le registre
            Reset-ExcelStyleRegistry

            # Initialiser les styles de lignes
            $Count = Initialize-ExcelLineStyleLibrary

            # VÃ©rifier que des styles ont Ã©tÃ© ajoutÃ©s
            $Count | Should -BeGreaterThan 0

            # VÃ©rifier que les styles sont dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Registry.LineStyles.Count | Should -Be $Count

            # VÃ©rifier quelques styles spÃ©cifiques
            $Registry.GetByName("Ligne continue fine") | Should -Not -BeNullOrEmpty
            $Registry.GetByName("Ligne pointillÃ©e moyenne") | Should -Not -BeNullOrEmpty
            $Registry.GetByName("Ligne en tirets Ã©paisse") | Should -Not -BeNullOrEmpty
            $Registry.GetByName("Ligne rouge") | Should -Not -BeNullOrEmpty
        }
    }

    Context "Get-ExcelPredefinedLineStyle function" {
        It "Should get a predefined line style by name" {
            # Obtenir un style par nom
            $Style = Get-ExcelPredefinedLineStyle -Name "Ligne continue fine"

            # VÃ©rifier le style
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

            # VÃ©rifier que le style est null
            $Style | Should -BeNullOrEmpty
        }
    }

    Context "Get-ExcelPredefinedLineStyles function" {
        It "Should get all predefined line styles" {
            # Obtenir tous les styles de ligne
            $Styles = Get-ExcelPredefinedLineStyles

            # VÃ©rifier que des styles ont Ã©tÃ© retournÃ©s
            $Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier que tous les styles sont des styles de ligne
            foreach ($Style in $Styles) {
                $Style | Should -BeOfType [ExcelLineStyle]
            }
        }

        It "Should include advanced dotted styles" {
            # Obtenir les styles de pointillÃ©s avancÃ©s
            $Styles = Get-ExcelPredefinedLineStyles -Category "PointillÃ©s avancÃ©s"

            # VÃ©rifier que des styles ont Ã©tÃ© retournÃ©s
            $Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier que tous les styles sont des styles de pointillÃ©s avancÃ©s
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "PointillÃ©s avancÃ©s"
                $Style.HasTag("PointillÃ©") | Should -Be $true
            }
        }

        It "Should include advanced dash styles" {
            # Obtenir les styles de tirets avancÃ©s
            $Styles = Get-ExcelPredefinedLineStyles -Category "Tirets avancÃ©s"

            # VÃ©rifier que des styles ont Ã©tÃ© retournÃ©s
            $Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier que tous les styles sont des styles de tirets avancÃ©s
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Tirets avancÃ©s"
                $Style.HasTag("Tiret") | Should -Be $true
            }
        }

        It "Should include advanced dash-dot combinations" {
            # Obtenir les styles de combinaisons tiret-point avancÃ©es
            $Styles = Get-ExcelPredefinedLineStyles -Category "Combinaisons tiret-point avancÃ©es"

            # VÃ©rifier que des styles ont Ã©tÃ© retournÃ©s
            $Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier que tous les styles sont des styles de combinaisons tiret-point avancÃ©es
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Combinaisons tiret-point avancÃ©es"
                $Style.HasTag("Tiret-point") -or $Style.HasTag("Tiret-point-point") | Should -Be $true
            }
        }

        It "Should include spacing variations" {
            # Obtenir les styles de variations d'espacement
            $Styles = Get-ExcelPredefinedLineStyles -Category "Variations d'espacement"

            # VÃ©rifier que des styles ont Ã©tÃ© retournÃ©s
            $Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier que tous les styles sont des styles de variations d'espacement
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Variations d'espacement"
                $Style.HasTag("Espacement") -or $Style.HasTag("Motif") | Should -Be $true
            }
        }

        It "Should filter styles by category" {
            # Obtenir les styles de la catÃ©gorie "Lignes continues"
            $Styles = Get-ExcelPredefinedLineStyles -Category "Lignes continues"

            # VÃ©rifier que des styles ont Ã©tÃ© retournÃ©s
            $Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier que tous les styles sont de la catÃ©gorie spÃ©cifiÃ©e
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Lignes continues"
            }
        }

        It "Should filter styles by tag" {
            # Obtenir les styles avec le tag "PointillÃ©"
            $Styles = Get-ExcelPredefinedLineStyles -Tag "PointillÃ©"

            # VÃ©rifier que des styles ont Ã©tÃ© retournÃ©s
            $Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier que tous les styles ont le tag spÃ©cifiÃ©
            foreach ($Style in $Styles) {
                $Style.HasTag("PointillÃ©") | Should -Be $true
            }
        }

        It "Should filter styles by category and tag" {
            # Obtenir les styles de la catÃ©gorie "Lignes colorÃ©es" avec le tag "Rouge"
            $Styles = Get-ExcelPredefinedLineStyles -Category "Lignes colorÃ©es" -Tag "Rouge"

            # VÃ©rifier que des styles ont Ã©tÃ© retournÃ©s
            $Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier que tous les styles sont de la catÃ©gorie et ont le tag spÃ©cifiÃ©s
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Lignes colorÃ©es"
                $Style.HasTag("Rouge") | Should -Be $true
            }
        }
    }

    Context "Initialize-ExcelPredefinedStyles function" {
        It "Should initialize all predefined styles" {
            # RÃ©initialiser le registre
            Reset-ExcelStyleRegistry

            # Initialiser tous les styles prÃ©dÃ©finis
            $Count = Initialize-ExcelPredefinedStyles

            # VÃ©rifier que des styles ont Ã©tÃ© ajoutÃ©s
            $Count | Should -BeGreaterThan 0

            # VÃ©rifier que les styles sont dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Registry.Styles.Count | Should -Be $Count

            # VÃ©rifier que tous les styles sont marquÃ©s comme prÃ©dÃ©finis
            $BuiltInStyles = $Registry.Search(@{ IsBuiltIn = $true })
            $BuiltInStyles.Count | Should -Be $Count
        }

        It "Should include harmonious color combinations" {
            # Obtenir les styles harmonieux
            $Styles = Get-ExcelPredefinedLineStyles -Category "Combinaisons harmonieuses"

            # VÃ©rifier que des styles ont Ã©tÃ© retournÃ©s
            $Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier que tous les styles sont des styles harmonieux
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Combinaisons harmonieuses"
                $Style.HasTag("Harmonieux") | Should -Be $true
            }
        }

        It "Should include coordinated sets" {
            # Obtenir les styles d'ensembles coordonnÃ©s
            $Styles = Get-ExcelPredefinedLineStyles -Category "Ensembles coordonnÃ©s"

            # VÃ©rifier que des styles ont Ã©tÃ© retournÃ©s
            $Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier que tous les styles sont des styles d'ensembles coordonnÃ©s
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Ensembles coordonnÃ©s"
                $Style.HasTag("Ensemble") | Should -Be $true
            }

            # VÃ©rifier qu'il y a des styles pour l'ensemble 1
            $Ensemble1Styles = $Styles | Where-Object { $_.HasTag("Ensemble1") }
            $Ensemble1Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier qu'il y a des styles pour l'ensemble 2
            $Ensemble2Styles = $Styles | Where-Object { $_.HasTag("Ensemble2") }
            $Ensemble2Styles.Count | Should -BeGreaterThan 0
        }

        It "Should include color variations by line type" {
            # Obtenir les styles de variations par type
            $Styles = Get-ExcelPredefinedLineStyles -Category "Variations par type"

            # VÃ©rifier que des styles ont Ã©tÃ© retournÃ©s
            $Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier que tous les styles sont des styles de variations par type
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "Variations par type"
                $Style.HasTag("Variable") -or $Style.HasTag("DÃ©gradÃ©") | Should -Be $true
            }
        }

        It "Should include special gradients" {
            # Obtenir les styles de dÃ©gradÃ©s spÃ©ciaux
            $Styles = Get-ExcelPredefinedLineStyles -Category "DÃ©gradÃ©s spÃ©ciaux"

            # VÃ©rifier que des styles ont Ã©tÃ© retournÃ©s
            $Styles.Count | Should -BeGreaterThan 0

            # VÃ©rifier que tous les styles sont des styles de dÃ©gradÃ©s spÃ©ciaux
            foreach ($Style in $Styles) {
                $Style.Category | Should -Be "DÃ©gradÃ©s spÃ©ciaux"
                $Style.HasTag("DÃ©gradÃ©") | Should -Be $true
            }
        }

        It "Should not reinitialize styles without Force" {
            # RÃ©initialiser le registre
            Reset-ExcelStyleRegistry

            # Initialiser les styles une premiÃ¨re fois
            $Count1 = Initialize-ExcelPredefinedStyles

            # Initialiser les styles une deuxiÃ¨me fois sans Force
            $Count2 = Initialize-ExcelPredefinedStyles

            # VÃ©rifier que les styles n'ont pas Ã©tÃ© rÃ©initialisÃ©s
            $Count2 | Should -Be $Count1

            # VÃ©rifier que le nombre de styles dans le registre est correct
            $Registry = Get-ExcelStyleRegistry
            $Registry.Styles.Count | Should -Be $Count1
        }

        It "Should reinitialize styles with Force" {
            # RÃ©initialiser le registre
            Reset-ExcelStyleRegistry

            # Initialiser les styles une premiÃ¨re fois
            $Count1 = Initialize-ExcelPredefinedStyles

            # Ajouter un style personnalisÃ©
            $CustomStyle = [ExcelLineStyle]::new()
            $CustomStyle.Name = "Style personnalisÃ©"
            $CustomStyle.IsBuiltIn = $false
            Add-ExcelStyle -Style $CustomStyle

            # Initialiser les styles une deuxiÃ¨me fois avec Force
            $Count2 = Initialize-ExcelPredefinedStyles -Force

            # VÃ©rifier que les styles ont Ã©tÃ© rÃ©initialisÃ©s
            $Count2 | Should -Be $Count1

            # VÃ©rifier que le nombre de styles dans le registre est correct (styles prÃ©dÃ©finis + style personnalisÃ©)
            $Registry = Get-ExcelStyleRegistry
            $Registry.Styles.Count | Should -Be ($Count1 + 1)

            # VÃ©rifier que le style personnalisÃ© est toujours prÃ©sent
            $Registry.GetByName("Style personnalisÃ©") | Should -Not -BeNullOrEmpty
        }
    }
}

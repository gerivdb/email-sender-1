# Tests pour les fonctionnalités de fusion des styles Excel

# Importer Pester
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Importer les modules à tester
$StyleRegistryPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_style_registry.ps1"
$PredefinedStylesPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_predefined_styles.ps1"
. $StyleRegistryPath
. $PredefinedStylesPath

Describe "Excel Style Merge" {
    BeforeAll {
        # Réinitialiser le registre avant chaque test
        Reset-ExcelStyleRegistry

        # Initialiser les styles prédéfinis
        Initialize-ExcelPredefinedStyles -Force
    }

    Context "Intelligent merge functions" {
        It "Should detect empty values" {
            # Tester des valeurs nulles
            Test-ExcelStyleValueEmpty -Value $null -Type "String" | Should -Be $true
            Test-ExcelStyleValueEmpty -Value $null -Type "Number" | Should -Be $true
            Test-ExcelStyleValueEmpty -Value $null -Type "Array" | Should -Be $true
            Test-ExcelStyleValueEmpty -Value $null -Type "Object" | Should -Be $true

            # Tester des valeurs vides
            Test-ExcelStyleValueEmpty -Value "" -Type "String" | Should -Be $true
            Test-ExcelStyleValueEmpty -Value 0 -Type "Number" | Should -Be $true
            Test-ExcelStyleValueEmpty -Value @() -Type "Array" | Should -Be $true

            # Tester des valeurs non vides
            Test-ExcelStyleValueEmpty -Value "Test" -Type "String" | Should -Be $false
            Test-ExcelStyleValueEmpty -Value 42 -Type "Number" | Should -Be $false
            Test-ExcelStyleValueEmpty -Value @(1, 2, 3) -Type "Array" | Should -Be $false
            Test-ExcelStyleValueEmpty -Value (New-Object -TypeName PSObject) -Type "Object" | Should -Be $false
        }

        It "Should merge collections" {
            # Fusionner des collections vides
            $Result = Merge-ExcelStyleCollections -SourceCollection $null -TargetCollection $null
            $Result | Should -BeOfType [array]
            $Result.Count | Should -Be 0

            # Fusionner avec une collection vide
            $Result = Merge-ExcelStyleCollections -SourceCollection @(1, 2, 3) -TargetCollection $null
            $Result | Should -BeOfType [array]
            $Result.Count | Should -Be 3
            $Result | Should -Contain 1
            $Result | Should -Contain 2
            $Result | Should -Contain 3

            # Fusionner avec stratégie SourceWins
            $Result = Merge-ExcelStyleCollections -SourceCollection @(1, 2, 3) -TargetCollection @(3, 4, 5) -Strategy "SourceWins"
            $Result | Should -BeOfType [array]
            $Result.Count | Should -Be 3
            $Result | Should -Contain 1
            $Result | Should -Contain 2
            $Result | Should -Contain 3
            $Result | Should -Not -Contain 4
            $Result | Should -Not -Contain 5

            # Fusionner avec stratégie TargetWins
            $Result = Merge-ExcelStyleCollections -SourceCollection @(1, 2, 3) -TargetCollection @(3, 4, 5) -Strategy "TargetWins"
            $Result | Should -BeOfType [array]
            $Result.Count | Should -Be 3
            $Result | Should -Not -Contain 1
            $Result | Should -Not -Contain 2
            $Result | Should -Contain 3
            $Result | Should -Contain 4
            $Result | Should -Contain 5

            # Fusionner avec stratégie MergeAll
            $Result = Merge-ExcelStyleCollections -SourceCollection @(1, 2, 3) -TargetCollection @(3, 4, 5) -Strategy "MergeAll"
            $Result | Should -BeOfType [array]
            $Result.Count | Should -Be 5
            $Result | Should -Contain 1
            $Result | Should -Contain 2
            $Result | Should -Contain 3
            $Result | Should -Contain 4
            $Result | Should -Contain 5
        }

        It "Should merge values" {
            # Fusionner des valeurs nulles
            $Result = Merge-ExcelStyleValues -SourceValue $null -TargetValue $null -Type "String"
            $Result | Should -Be ""

            # Fusionner avec stratégie SourceWins
            $Result = Merge-ExcelStyleValues -SourceValue "Source" -TargetValue "Target" -Type "String" -Strategy "SourceWins"
            $Result | Should -Be "Source"

            # Fusionner avec stratégie TargetWins
            $Result = Merge-ExcelStyleValues -SourceValue "Source" -TargetValue "Target" -Type "String" -Strategy "TargetWins"
            $Result | Should -Be "Target"

            # Fusionner avec stratégie MergeNonNull (Target non vide)
            $Result = Merge-ExcelStyleValues -SourceValue "Source" -TargetValue "Target" -Type "String" -Strategy "MergeNonNull"
            $Result | Should -Be "Target"

            # Fusionner avec stratégie MergeNonNull (Target vide)
            $Result = Merge-ExcelStyleValues -SourceValue "Source" -TargetValue "" -Type "String" -Strategy "MergeNonNull"
            $Result | Should -Be "Source"

            # Fusionner des tableaux avec stratégie MergeAll
            $Result = Merge-ExcelStyleValues -SourceValue @(1, 2, 3) -TargetValue @(3, 4, 5) -Type "Array" -Strategy "MergeAll"
            $Result | Should -BeOfType [array]
            $Result.Count | Should -Be 5
            $Result | Should -Contain 1
            $Result | Should -Contain 2
            $Result | Should -Contain 3
            $Result | Should -Contain 4
            $Result | Should -Contain 5
        }
    }

    Context "Default merge strategy functions" {
        It "Should get the default merge strategy" {
            # Obtenir la stratégie par défaut
            $DefaultStrategy = Get-ExcelStyleMergeDefaultStrategy

            # Vérifier que la stratégie par défaut est "MergeNonNull"
            $DefaultStrategy | Should -Be "MergeNonNull"
        }

        It "Should set the default merge strategy" {
            # Obtenir la stratégie par défaut actuelle
            $OldStrategy = Get-ExcelStyleMergeDefaultStrategy

            # Définir une nouvelle stratégie par défaut
            $ReturnedStrategy = Set-ExcelStyleMergeDefaultStrategy -Strategy "SourceWins"

            # Vérifier que la fonction a retourné l'ancienne stratégie
            $ReturnedStrategy | Should -Be $OldStrategy

            # Vérifier que la stratégie par défaut a été changée
            $NewStrategy = Get-ExcelStyleMergeDefaultStrategy
            $NewStrategy | Should -Be "SourceWins"

            # Restaurer la stratégie par défaut
            Set-ExcelStyleMergeDefaultStrategy -Strategy "MergeNonNull" | Out-Null
        }

        It "Should use the default merge strategy when none is specified" {
            # Définir une stratégie par défaut
            Set-ExcelStyleMergeDefaultStrategy -Strategy "TargetWins"

            # Obtenir deux styles prédéfinis
            $SourceStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"

            # Fusionner les styles sans spécifier de stratégie
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionné avec stratégie par défaut"

            # Vérifier que le style fusionné a été créé
            $MergedStyle | Should -Not -BeNullOrEmpty

            # Vérifier que la stratégie par défaut (TargetWins) a été utilisée
            $MergedStyle.LineConfig.Color | Should -Be $TargetStyle.LineConfig.Color

            # Restaurer la stratégie par défaut
            Set-ExcelStyleMergeDefaultStrategy -Strategy "MergeNonNull" | Out-Null
        }
    }

    Context "Merge-ExcelLineStyles function" {
        It "Should merge two styles with SourceWins strategy" {
            # Obtenir deux styles prédéfinis
            $SourceStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"

            # Fusionner les styles avec la stratégie SourceWins
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionné SourceWins" -MergeStrategy "SourceWins"

            # Vérifier que le style fusionné a été créé
            $MergedStyle | Should -Not -BeNullOrEmpty
            $MergedStyle.Name | Should -Be "Style fusionné SourceWins"

            # Vérifier que les propriétés du style source ont été utilisées
            $MergedStyle.LineConfig.Color | Should -Be $SourceStyle.LineConfig.Color
            $MergedStyle.LineConfig.Width | Should -Be $SourceStyle.LineConfig.Width
            $MergedStyle.LineConfig.Style | Should -Be $SourceStyle.LineConfig.Style

            # Vérifier que le style fusionné a le tag "Fusionné"
            $MergedStyle.HasTag("Fusionné") | Should -Be $true
        }

        It "Should merge two styles with TargetWins strategy" {
            # Obtenir deux styles prédéfinis
            $SourceStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"

            # Fusionner les styles avec la stratégie TargetWins
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionné TargetWins" -MergeStrategy "TargetWins"

            # Vérifier que le style fusionné a été créé
            $MergedStyle | Should -Not -BeNullOrEmpty
            $MergedStyle.Name | Should -Be "Style fusionné TargetWins"

            # Vérifier que les propriétés du style cible ont été utilisées
            $MergedStyle.LineConfig.Color | Should -Be $TargetStyle.LineConfig.Color
            $MergedStyle.LineConfig.Width | Should -Be $TargetStyle.LineConfig.Width
            $MergedStyle.LineConfig.Style | Should -Be $TargetStyle.LineConfig.Style

            # Vérifier que le style fusionné a le tag "Fusionné"
            $MergedStyle.HasTag("Fusionné") | Should -Be $true
        }

        It "Should merge two styles with MergeNonNull strategy" {
            # Créer deux styles personnalisés avec des propriétés différentes
            $SourceStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style source" -Color "#FF0000" -Width 3
            $TargetStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style cible"

            # Modifier certaines propriétés du style cible pour tester la fusion
            $TargetStyle.LineConfig.Color = "#0000FF"
            $TargetStyle.LineConfig.Width = 0  # Valeur nulle pour tester la fusion

            # Fusionner les styles avec la stratégie MergeNonNull
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionné MergeNonNull" -MergeStrategy "MergeNonNull"

            # Vérifier que le style fusionné a été créé
            $MergedStyle | Should -Not -BeNullOrEmpty
            $MergedStyle.Name | Should -Be "Style fusionné MergeNonNull"

            # Vérifier que les propriétés non nulles du style cible ont été utilisées
            $MergedStyle.LineConfig.Color | Should -Be $TargetStyle.LineConfig.Color

            # Vérifier que les propriétés nulles du style cible ont été remplacées par celles du style source
            $MergedStyle.LineConfig.Width | Should -Be $SourceStyle.LineConfig.Width

            # Vérifier que le style fusionné a le tag "Fusionné"
            $MergedStyle.HasTag("Fusionné") | Should -Be $true
        }

        It "Should merge tags when MergeTags is specified" {
            # Créer deux styles personnalisés avec des tags différents
            $SourceStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style source" -Tags @("Tag1", "Tag2")
            $TargetStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style cible" -Tags @("Tag3", "Tag4")

            # Fusionner les styles avec l'option MergeTags
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionné avec tags" -MergeTags

            # Vérifier que le style fusionné a été créé
            $MergedStyle | Should -Not -BeNullOrEmpty

            # Vérifier que tous les tags ont été fusionnés
            $MergedStyle.HasTag("Tag1") | Should -Be $true
            $MergedStyle.HasTag("Tag2") | Should -Be $true
            $MergedStyle.HasTag("Tag3") | Should -Be $true
            $MergedStyle.HasTag("Tag4") | Should -Be $true
            $MergedStyle.HasTag("Fusionné") | Should -Be $true
        }

        It "Should use custom category when specified" {
            # Obtenir deux styles prédéfinis
            $SourceStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"

            # Fusionner les styles avec une catégorie personnalisée
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionné avec catégorie" -Category "Catégorie personnalisée"

            # Vérifier que le style fusionné a été créé
            $MergedStyle | Should -Not -BeNullOrEmpty

            # Vérifier que la catégorie personnalisée a été utilisée
            $MergedStyle.Category | Should -Be "Catégorie personnalisée"
        }

        It "Should use custom description when specified" {
            # Obtenir deux styles prédéfinis
            $SourceStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"

            # Fusionner les styles avec une description personnalisée
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionné avec description" -Description "Description personnalisée"

            # Vérifier que le style fusionné a été créé
            $MergedStyle | Should -Not -BeNullOrEmpty

            # Vérifier que la description personnalisée a été utilisée
            $MergedStyle.Description | Should -Be "Description personnalisée"
        }

        It "Should merge advanced properties" {
            # Créer deux styles personnalisés avec des propriétés avancées
            $SourceStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style source avancé"
            $SourceStyle.LineConfig.GradientEnabled = $true
            $SourceStyle.LineConfig.GradientEndColor = "#00FF00"

            $TargetStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style cible avancé"
            $TargetStyle.LineConfig.VariableColorEnabled = $true
            $TargetStyle.LineConfig.VariableColors = @("#FF0000", "#00FF00", "#0000FF")

            # Fusionner les styles
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionné avancé" -MergeStrategy "MergeNonNull"

            # Vérifier que le style fusionné a été créé
            $MergedStyle | Should -Not -BeNullOrEmpty

            # Vérifier que les propriétés avancées ont été fusionnées
            $MergedStyle.LineConfig.GradientEnabled | Should -Be $SourceStyle.LineConfig.GradientEnabled
            $MergedStyle.LineConfig.GradientEndColor | Should -Be $SourceStyle.LineConfig.GradientEndColor
            $MergedStyle.LineConfig.VariableColorEnabled | Should -Be $TargetStyle.LineConfig.VariableColorEnabled
            $MergedStyle.LineConfig.VariableColors | Should -Be $TargetStyle.LineConfig.VariableColors
        }
    }

    Context "Custom merge rules functions" {
        It "Should define and retrieve merge rules" {
            # Définir une règle de fusion
            $Result = Set-ExcelStyleMergeRule -RuleName "TestRule" -PropertyName "Color" -Strategy "SourceWins" -Priority 10
            $Result | Should -Be $true

            # Obtenir la règle de fusion
            $Rule = Get-ExcelStyleMergeRule -RuleName "TestRule"
            $Rule | Should -Not -BeNullOrEmpty
            $Rule.PropertyName | Should -Be "Color"
            $Rule.Strategy | Should -Be "SourceWins"
            $Rule.Priority | Should -Be 10

            # Obtenir toutes les règles de fusion
            $Rules = Get-ExcelStyleMergeRules
            $Rules.Count | Should -BeGreaterThan 0
            $Rules.ContainsKey("TestRule") | Should -Be $true

            # Filtrer les règles par nom de propriété
            $ColorRules = Get-ExcelStyleMergeRules -PropertyName "Color"
            $ColorRules.Count | Should -BeGreaterThan 0
            $ColorRules.ContainsKey("TestRule") | Should -Be $true

            # Supprimer la règle de fusion
            $Result = Remove-ExcelStyleMergeRule -RuleName "TestRule"
            $Result | Should -Be $true

            # Vérifier que la règle a été supprimée
            $Rule = Get-ExcelStyleMergeRule -RuleName "TestRule"
            $Rule | Should -BeNullOrEmpty
        }

        It "Should manage rule priorities" {
            # Définir deux règles de fusion avec des priorités différentes
            Set-ExcelStyleMergeRule -RuleName "LowPriorityRule" -PropertyName "Color" -Strategy "SourceWins" -Priority 5
            Set-ExcelStyleMergeRule -RuleName "HighPriorityRule" -PropertyName "Color" -Strategy "TargetWins" -Priority 10

            # Obtenir la stratégie pour la propriété Color
            $Strategy = Get-ExcelStyleMergeStrategyForProperty -PropertyName "Color"
            $Strategy | Should -Be "TargetWins"

            # Modifier la priorité de la règle
            $Result = Set-ExcelStyleMergeRulePriority -RuleName "LowPriorityRule" -Priority 15
            $Result | Should -Be $true

            # Vérifier que la priorité a été mise à jour
            $Priority = Get-ExcelStyleMergeRulePriority -RuleName "LowPriorityRule"
            $Priority | Should -Be 15

            # Vérifier que la stratégie a changé
            $Strategy = Get-ExcelStyleMergeStrategyForProperty -PropertyName "Color"
            $Strategy | Should -Be "SourceWins"

            # Définir une règle par défaut
            $Result = Set-ExcelStyleMergeDefaultRule -PropertyName "Width" -Strategy "MergeNonNull"
            $Result | Should -Be $true

            # Vérifier que la règle par défaut a été créée
            $Rule = Get-ExcelStyleMergeRule -RuleName "Default_Width"
            $Rule | Should -Not -BeNullOrEmpty
            $Rule.PropertyName | Should -Be "Width"
            $Rule.Strategy | Should -Be "MergeNonNull"

            # Nettoyer les règles de test
            Remove-ExcelStyleMergeRule -RuleName "LowPriorityRule"
            Remove-ExcelStyleMergeRule -RuleName "HighPriorityRule"
            Remove-ExcelStyleMergeRule -RuleName "Default_Width"
        }

        It "Should export and import rules" {
            # Définir quelques règles de fusion
            Set-ExcelStyleMergeRule -RuleName "ExportRule1" -PropertyName "Color" -Strategy "SourceWins" -Priority 5
            Set-ExcelStyleMergeRule -RuleName "ExportRule2" -PropertyName "Width" -Strategy "TargetWins" -Priority 10

            # Exporter les règles
            $TempFile = [System.IO.Path]::GetTempFileName()
            $ExportCount = Export-ExcelStyleMergeRules -Path $TempFile -Force
            $ExportCount | Should -BeGreaterThan 0

            # Supprimer les règles
            Remove-ExcelStyleMergeRule -RuleName "ExportRule1"
            Remove-ExcelStyleMergeRule -RuleName "ExportRule2"

            # Importer les règles
            $ImportCount = Import-ExcelStyleMergeRules -Path $TempFile
            $ImportCount | Should -BeGreaterThan 0

            # Vérifier que les règles ont été importées
            $Rule1 = Get-ExcelStyleMergeRule -RuleName "ExportRule1"
            $Rule1 | Should -Not -BeNullOrEmpty
            $Rule1.PropertyName | Should -Be "Color"
            $Rule1.Strategy | Should -Be "SourceWins"

            $Rule2 = Get-ExcelStyleMergeRule -RuleName "ExportRule2"
            $Rule2 | Should -Not -BeNullOrEmpty
            $Rule2.PropertyName | Should -Be "Width"
            $Rule2.Strategy | Should -Be "TargetWins"

            # Nettoyer les règles de test
            Remove-ExcelStyleMergeRule -RuleName "ExportRule1"
            Remove-ExcelStyleMergeRule -RuleName "ExportRule2"

            # Supprimer le fichier temporaire
            Remove-Item -Path $TempFile -Force
        }

        It "Should merge rule sets" {
            # Définir quelques règles de fusion
            Set-ExcelStyleMergeRule -RuleName "MergeRule1" -PropertyName "Color" -Strategy "SourceWins" -Priority 5

            # Exporter les règles
            $TempFile = [System.IO.Path]::GetTempFileName()
            Export-ExcelStyleMergeRules -Path $TempFile -Force

            # Modifier la règle existante et ajouter une nouvelle règle
            Set-ExcelStyleMergeRule -RuleName "MergeRule1" -PropertyName "Color" -Strategy "TargetWins" -Priority 10
            Set-ExcelStyleMergeRule -RuleName "MergeRule2" -PropertyName "Width" -Strategy "MergeNonNull" -Priority 15

            # Fusionner les règles avec la stratégie KeepExisting
            $MergeCount = Merge-ExcelStyleMergeRules -Path $TempFile -Strategy "KeepExisting"
            $MergeCount | Should -BeGreaterThan 0

            # Vérifier que la règle existante n'a pas été modifiée
            $Rule1 = Get-ExcelStyleMergeRule -RuleName "MergeRule1"
            $Rule1.Strategy | Should -Be "TargetWins"
            $Rule1.Priority | Should -Be 10

            # Nettoyer les règles de test
            Remove-ExcelStyleMergeRule -RuleName "MergeRule1"
            Remove-ExcelStyleMergeRule -RuleName "MergeRule2"

            # Supprimer le fichier temporaire
            Remove-Item -Path $TempFile -Force
        }
    }

    Context "Manual resolution functions" {
        It "Should handle Manual strategy without interactive mode" {
            # Fusionner deux styles avec la stratégie Manual mais sans mode interactif
            $MergedStyle = Merge-ExcelLineStylesByName -SourceStyleName "Ligne rouge" -TargetStyleName "Ligne bleue" -NewName "Style fusionné manuel non interactif" -MergeStrategy "Manual"

            # Vérifier que le style fusionné a été créé
            $MergedStyle | Should -Not -BeNullOrEmpty
            $MergedStyle.Name | Should -Be "Style fusionné manuel non interactif"

            # Vérifier que la stratégie Manual sans mode interactif se comporte comme MergeNonNull
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"
            $MergedStyle.LineConfig.Color | Should -Be $TargetStyle.LineConfig.Color
        }

        # Note: Les tests interactifs ne sont pas inclus car ils nécessitent une interaction utilisateur
        # Mais nous pouvons tester les fonctions auxiliaires

        It "Should correctly detect empty values" {
            # Tester la détection des valeurs vides pour différents types
            Test-ExcelStyleValueEmpty -Value $null -Type "String" | Should -Be $true
            Test-ExcelStyleValueEmpty -Value "" -Type "String" | Should -Be $true
            Test-ExcelStyleValueEmpty -Value "Test" -Type "String" | Should -Be $false

            Test-ExcelStyleValueEmpty -Value $null -Type "Number" | Should -Be $true
            Test-ExcelStyleValueEmpty -Value 0 -Type "Number" | Should -Be $true
            Test-ExcelStyleValueEmpty -Value 42 -Type "Number" | Should -Be $false

            Test-ExcelStyleValueEmpty -Value $null -Type "Array" | Should -Be $true
            Test-ExcelStyleValueEmpty -Value @() -Type "Array" | Should -Be $true
            Test-ExcelStyleValueEmpty -Value @(1, 2, 3) -Type "Array" | Should -Be $false
        }
    }

    Context "Merge-ExcelLineStylesByName function" {
        It "Should merge two styles by name" {
            # Fusionner deux styles par leur nom
            $MergedStyle = Merge-ExcelLineStylesByName -SourceStyleName "Ligne rouge" -TargetStyleName "Ligne bleue" -NewName "Style fusionné par nom"

            # Vérifier que le style fusionné a été créé
            $MergedStyle | Should -Not -BeNullOrEmpty
            $MergedStyle.Name | Should -Be "Style fusionné par nom"

            # Vérifier que le style fusionné a le tag "Fusionné"
            $MergedStyle.HasTag("Fusionné") | Should -Be $true
        }

        It "Should handle invalid style names" {
            # Essayer de fusionner avec un nom de style inexistant
            $MergedStyle = Merge-ExcelLineStylesByName -SourceStyleName "Style inexistant" -TargetStyleName "Ligne bleue" -NewName "Style fusionné invalide"

            # Vérifier que la fusion a échoué
            $MergedStyle | Should -BeNullOrEmpty
        }

        It "Should pass all parameters to Merge-ExcelLineStyles" {
            # Fusionner deux styles avec tous les paramètres
            $MergedStyle = Merge-ExcelLineStylesByName -SourceStyleName "Ligne rouge" -TargetStyleName "Ligne bleue" -NewName "Style fusionné complet" -Description "Description complète" -MergeStrategy "TargetWins" -MergeTags -Category "Catégorie complète"

            # Vérifier que le style fusionné a été créé
            $MergedStyle | Should -Not -BeNullOrEmpty
            $MergedStyle.Name | Should -Be "Style fusionné complet"
            $MergedStyle.Description | Should -Be "Description complète"
            $MergedStyle.Category | Should -Be "Catégorie complète"

            # Vérifier que les propriétés du style cible ont été utilisées (TargetWins)
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"
            $MergedStyle.LineConfig.Color | Should -Be $TargetStyle.LineConfig.Color

            # Vérifier que les tags ont été fusionnés
            $SourceStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            foreach ($Tag in $SourceStyle.Tags) {
                $MergedStyle.HasTag($Tag) | Should -Be $true
            }
            foreach ($Tag in $TargetStyle.Tags) {
                $MergedStyle.HasTag($Tag) | Should -Be $true
            }
            $MergedStyle.HasTag("Fusionné") | Should -Be $true
        }
    }
}

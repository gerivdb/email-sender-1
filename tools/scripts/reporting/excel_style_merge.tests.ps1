# Tests pour les fonctionnalitÃ©s de fusion des styles Excel

# Importer Pester
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Importer les modules Ã  tester
$StyleRegistryPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_style_registry.ps1"
$PredefinedStylesPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_predefined_styles.ps1"
. $StyleRegistryPath
. $PredefinedStylesPath

Describe "Excel Style Merge" {
    BeforeAll {
        # RÃ©initialiser le registre avant chaque test
        Reset-ExcelStyleRegistry

        # Initialiser les styles prÃ©dÃ©finis
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

            # Fusionner avec stratÃ©gie SourceWins
            $Result = Merge-ExcelStyleCollections -SourceCollection @(1, 2, 3) -TargetCollection @(3, 4, 5) -Strategy "SourceWins"
            $Result | Should -BeOfType [array]
            $Result.Count | Should -Be 3
            $Result | Should -Contain 1
            $Result | Should -Contain 2
            $Result | Should -Contain 3
            $Result | Should -Not -Contain 4
            $Result | Should -Not -Contain 5

            # Fusionner avec stratÃ©gie TargetWins
            $Result = Merge-ExcelStyleCollections -SourceCollection @(1, 2, 3) -TargetCollection @(3, 4, 5) -Strategy "TargetWins"
            $Result | Should -BeOfType [array]
            $Result.Count | Should -Be 3
            $Result | Should -Not -Contain 1
            $Result | Should -Not -Contain 2
            $Result | Should -Contain 3
            $Result | Should -Contain 4
            $Result | Should -Contain 5

            # Fusionner avec stratÃ©gie MergeAll
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

            # Fusionner avec stratÃ©gie SourceWins
            $Result = Merge-ExcelStyleValues -SourceValue "Source" -TargetValue "Target" -Type "String" -Strategy "SourceWins"
            $Result | Should -Be "Source"

            # Fusionner avec stratÃ©gie TargetWins
            $Result = Merge-ExcelStyleValues -SourceValue "Source" -TargetValue "Target" -Type "String" -Strategy "TargetWins"
            $Result | Should -Be "Target"

            # Fusionner avec stratÃ©gie MergeNonNull (Target non vide)
            $Result = Merge-ExcelStyleValues -SourceValue "Source" -TargetValue "Target" -Type "String" -Strategy "MergeNonNull"
            $Result | Should -Be "Target"

            # Fusionner avec stratÃ©gie MergeNonNull (Target vide)
            $Result = Merge-ExcelStyleValues -SourceValue "Source" -TargetValue "" -Type "String" -Strategy "MergeNonNull"
            $Result | Should -Be "Source"

            # Fusionner des tableaux avec stratÃ©gie MergeAll
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
            # Obtenir la stratÃ©gie par dÃ©faut
            $DefaultStrategy = Get-ExcelStyleMergeDefaultStrategy

            # VÃ©rifier que la stratÃ©gie par dÃ©faut est "MergeNonNull"
            $DefaultStrategy | Should -Be "MergeNonNull"
        }

        It "Should set the default merge strategy" {
            # Obtenir la stratÃ©gie par dÃ©faut actuelle
            $OldStrategy = Get-ExcelStyleMergeDefaultStrategy

            # DÃ©finir une nouvelle stratÃ©gie par dÃ©faut
            $ReturnedStrategy = Set-ExcelStyleMergeDefaultStrategy -Strategy "SourceWins"

            # VÃ©rifier que la fonction a retournÃ© l'ancienne stratÃ©gie
            $ReturnedStrategy | Should -Be $OldStrategy

            # VÃ©rifier que la stratÃ©gie par dÃ©faut a Ã©tÃ© changÃ©e
            $NewStrategy = Get-ExcelStyleMergeDefaultStrategy
            $NewStrategy | Should -Be "SourceWins"

            # Restaurer la stratÃ©gie par dÃ©faut
            Set-ExcelStyleMergeDefaultStrategy -Strategy "MergeNonNull" | Out-Null
        }

        It "Should use the default merge strategy when none is specified" {
            # DÃ©finir une stratÃ©gie par dÃ©faut
            Set-ExcelStyleMergeDefaultStrategy -Strategy "TargetWins"

            # Obtenir deux styles prÃ©dÃ©finis
            $SourceStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"

            # Fusionner les styles sans spÃ©cifier de stratÃ©gie
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionnÃ© avec stratÃ©gie par dÃ©faut"

            # VÃ©rifier que le style fusionnÃ© a Ã©tÃ© crÃ©Ã©
            $MergedStyle | Should -Not -BeNullOrEmpty

            # VÃ©rifier que la stratÃ©gie par dÃ©faut (TargetWins) a Ã©tÃ© utilisÃ©e
            $MergedStyle.LineConfig.Color | Should -Be $TargetStyle.LineConfig.Color

            # Restaurer la stratÃ©gie par dÃ©faut
            Set-ExcelStyleMergeDefaultStrategy -Strategy "MergeNonNull" | Out-Null
        }
    }

    Context "Merge-ExcelLineStyles function" {
        It "Should merge two styles with SourceWins strategy" {
            # Obtenir deux styles prÃ©dÃ©finis
            $SourceStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"

            # Fusionner les styles avec la stratÃ©gie SourceWins
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionnÃ© SourceWins" -MergeStrategy "SourceWins"

            # VÃ©rifier que le style fusionnÃ© a Ã©tÃ© crÃ©Ã©
            $MergedStyle | Should -Not -BeNullOrEmpty
            $MergedStyle.Name | Should -Be "Style fusionnÃ© SourceWins"

            # VÃ©rifier que les propriÃ©tÃ©s du style source ont Ã©tÃ© utilisÃ©es
            $MergedStyle.LineConfig.Color | Should -Be $SourceStyle.LineConfig.Color
            $MergedStyle.LineConfig.Width | Should -Be $SourceStyle.LineConfig.Width
            $MergedStyle.LineConfig.Style | Should -Be $SourceStyle.LineConfig.Style

            # VÃ©rifier que le style fusionnÃ© a le tag "FusionnÃ©"
            $MergedStyle.HasTag("FusionnÃ©") | Should -Be $true
        }

        It "Should merge two styles with TargetWins strategy" {
            # Obtenir deux styles prÃ©dÃ©finis
            $SourceStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"

            # Fusionner les styles avec la stratÃ©gie TargetWins
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionnÃ© TargetWins" -MergeStrategy "TargetWins"

            # VÃ©rifier que le style fusionnÃ© a Ã©tÃ© crÃ©Ã©
            $MergedStyle | Should -Not -BeNullOrEmpty
            $MergedStyle.Name | Should -Be "Style fusionnÃ© TargetWins"

            # VÃ©rifier que les propriÃ©tÃ©s du style cible ont Ã©tÃ© utilisÃ©es
            $MergedStyle.LineConfig.Color | Should -Be $TargetStyle.LineConfig.Color
            $MergedStyle.LineConfig.Width | Should -Be $TargetStyle.LineConfig.Width
            $MergedStyle.LineConfig.Style | Should -Be $TargetStyle.LineConfig.Style

            # VÃ©rifier que le style fusionnÃ© a le tag "FusionnÃ©"
            $MergedStyle.HasTag("FusionnÃ©") | Should -Be $true
        }

        It "Should merge two styles with MergeNonNull strategy" {
            # CrÃ©er deux styles personnalisÃ©s avec des propriÃ©tÃ©s diffÃ©rentes
            $SourceStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style source" -Color "#FF0000" -Width 3
            $TargetStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style cible"

            # Modifier certaines propriÃ©tÃ©s du style cible pour tester la fusion
            $TargetStyle.LineConfig.Color = "#0000FF"
            $TargetStyle.LineConfig.Width = 0  # Valeur nulle pour tester la fusion

            # Fusionner les styles avec la stratÃ©gie MergeNonNull
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionnÃ© MergeNonNull" -MergeStrategy "MergeNonNull"

            # VÃ©rifier que le style fusionnÃ© a Ã©tÃ© crÃ©Ã©
            $MergedStyle | Should -Not -BeNullOrEmpty
            $MergedStyle.Name | Should -Be "Style fusionnÃ© MergeNonNull"

            # VÃ©rifier que les propriÃ©tÃ©s non nulles du style cible ont Ã©tÃ© utilisÃ©es
            $MergedStyle.LineConfig.Color | Should -Be $TargetStyle.LineConfig.Color

            # VÃ©rifier que les propriÃ©tÃ©s nulles du style cible ont Ã©tÃ© remplacÃ©es par celles du style source
            $MergedStyle.LineConfig.Width | Should -Be $SourceStyle.LineConfig.Width

            # VÃ©rifier que le style fusionnÃ© a le tag "FusionnÃ©"
            $MergedStyle.HasTag("FusionnÃ©") | Should -Be $true
        }

        It "Should merge tags when MergeTags is specified" {
            # CrÃ©er deux styles personnalisÃ©s avec des tags diffÃ©rents
            $SourceStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style source" -Tags @("Tag1", "Tag2")
            $TargetStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style cible" -Tags @("Tag3", "Tag4")

            # Fusionner les styles avec l'option MergeTags
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionnÃ© avec tags" -MergeTags

            # VÃ©rifier que le style fusionnÃ© a Ã©tÃ© crÃ©Ã©
            $MergedStyle | Should -Not -BeNullOrEmpty

            # VÃ©rifier que tous les tags ont Ã©tÃ© fusionnÃ©s
            $MergedStyle.HasTag("Tag1") | Should -Be $true
            $MergedStyle.HasTag("Tag2") | Should -Be $true
            $MergedStyle.HasTag("Tag3") | Should -Be $true
            $MergedStyle.HasTag("Tag4") | Should -Be $true
            $MergedStyle.HasTag("FusionnÃ©") | Should -Be $true
        }

        It "Should use custom category when specified" {
            # Obtenir deux styles prÃ©dÃ©finis
            $SourceStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"

            # Fusionner les styles avec une catÃ©gorie personnalisÃ©e
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionnÃ© avec catÃ©gorie" -Category "CatÃ©gorie personnalisÃ©e"

            # VÃ©rifier que le style fusionnÃ© a Ã©tÃ© crÃ©Ã©
            $MergedStyle | Should -Not -BeNullOrEmpty

            # VÃ©rifier que la catÃ©gorie personnalisÃ©e a Ã©tÃ© utilisÃ©e
            $MergedStyle.Category | Should -Be "CatÃ©gorie personnalisÃ©e"
        }

        It "Should use custom description when specified" {
            # Obtenir deux styles prÃ©dÃ©finis
            $SourceStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"

            # Fusionner les styles avec une description personnalisÃ©e
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionnÃ© avec description" -Description "Description personnalisÃ©e"

            # VÃ©rifier que le style fusionnÃ© a Ã©tÃ© crÃ©Ã©
            $MergedStyle | Should -Not -BeNullOrEmpty

            # VÃ©rifier que la description personnalisÃ©e a Ã©tÃ© utilisÃ©e
            $MergedStyle.Description | Should -Be "Description personnalisÃ©e"
        }

        It "Should merge advanced properties" {
            # CrÃ©er deux styles personnalisÃ©s avec des propriÃ©tÃ©s avancÃ©es
            $SourceStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style source avancÃ©"
            $SourceStyle.LineConfig.GradientEnabled = $true
            $SourceStyle.LineConfig.GradientEndColor = "#00FF00"

            $TargetStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style cible avancÃ©"
            $TargetStyle.LineConfig.VariableColorEnabled = $true
            $TargetStyle.LineConfig.VariableColors = @("#FF0000", "#00FF00", "#0000FF")

            # Fusionner les styles
            $MergedStyle = Merge-ExcelLineStyles -SourceStyle $SourceStyle -TargetStyle $TargetStyle -NewName "Style fusionnÃ© avancÃ©" -MergeStrategy "MergeNonNull"

            # VÃ©rifier que le style fusionnÃ© a Ã©tÃ© crÃ©Ã©
            $MergedStyle | Should -Not -BeNullOrEmpty

            # VÃ©rifier que les propriÃ©tÃ©s avancÃ©es ont Ã©tÃ© fusionnÃ©es
            $MergedStyle.LineConfig.GradientEnabled | Should -Be $SourceStyle.LineConfig.GradientEnabled
            $MergedStyle.LineConfig.GradientEndColor | Should -Be $SourceStyle.LineConfig.GradientEndColor
            $MergedStyle.LineConfig.VariableColorEnabled | Should -Be $TargetStyle.LineConfig.VariableColorEnabled
            $MergedStyle.LineConfig.VariableColors | Should -Be $TargetStyle.LineConfig.VariableColors
        }
    }

    Context "Custom merge rules functions" {
        It "Should define and retrieve merge rules" {
            # DÃ©finir une rÃ¨gle de fusion
            $Result = Set-ExcelStyleMergeRule -RuleName "TestRule" -PropertyName "Color" -Strategy "SourceWins" -Priority 10
            $Result | Should -Be $true

            # Obtenir la rÃ¨gle de fusion
            $Rule = Get-ExcelStyleMergeRule -RuleName "TestRule"
            $Rule | Should -Not -BeNullOrEmpty
            $Rule.PropertyName | Should -Be "Color"
            $Rule.Strategy | Should -Be "SourceWins"
            $Rule.Priority | Should -Be 10

            # Obtenir toutes les rÃ¨gles de fusion
            $Rules = Get-ExcelStyleMergeRules
            $Rules.Count | Should -BeGreaterThan 0
            $Rules.ContainsKey("TestRule") | Should -Be $true

            # Filtrer les rÃ¨gles par nom de propriÃ©tÃ©
            $ColorRules = Get-ExcelStyleMergeRules -PropertyName "Color"
            $ColorRules.Count | Should -BeGreaterThan 0
            $ColorRules.ContainsKey("TestRule") | Should -Be $true

            # Supprimer la rÃ¨gle de fusion
            $Result = Remove-ExcelStyleMergeRule -RuleName "TestRule"
            $Result | Should -Be $true

            # VÃ©rifier que la rÃ¨gle a Ã©tÃ© supprimÃ©e
            $Rule = Get-ExcelStyleMergeRule -RuleName "TestRule"
            $Rule | Should -BeNullOrEmpty
        }

        It "Should manage rule priorities" {
            # DÃ©finir deux rÃ¨gles de fusion avec des prioritÃ©s diffÃ©rentes
            Set-ExcelStyleMergeRule -RuleName "LowPriorityRule" -PropertyName "Color" -Strategy "SourceWins" -Priority 5
            Set-ExcelStyleMergeRule -RuleName "HighPriorityRule" -PropertyName "Color" -Strategy "TargetWins" -Priority 10

            # Obtenir la stratÃ©gie pour la propriÃ©tÃ© Color
            $Strategy = Get-ExcelStyleMergeStrategyForProperty -PropertyName "Color"
            $Strategy | Should -Be "TargetWins"

            # Modifier la prioritÃ© de la rÃ¨gle
            $Result = Set-ExcelStyleMergeRulePriority -RuleName "LowPriorityRule" -Priority 15
            $Result | Should -Be $true

            # VÃ©rifier que la prioritÃ© a Ã©tÃ© mise Ã  jour
            $Priority = Get-ExcelStyleMergeRulePriority -RuleName "LowPriorityRule"
            $Priority | Should -Be 15

            # VÃ©rifier que la stratÃ©gie a changÃ©
            $Strategy = Get-ExcelStyleMergeStrategyForProperty -PropertyName "Color"
            $Strategy | Should -Be "SourceWins"

            # DÃ©finir une rÃ¨gle par dÃ©faut
            $Result = Set-ExcelStyleMergeDefaultRule -PropertyName "Width" -Strategy "MergeNonNull"
            $Result | Should -Be $true

            # VÃ©rifier que la rÃ¨gle par dÃ©faut a Ã©tÃ© crÃ©Ã©e
            $Rule = Get-ExcelStyleMergeRule -RuleName "Default_Width"
            $Rule | Should -Not -BeNullOrEmpty
            $Rule.PropertyName | Should -Be "Width"
            $Rule.Strategy | Should -Be "MergeNonNull"

            # Nettoyer les rÃ¨gles de test
            Remove-ExcelStyleMergeRule -RuleName "LowPriorityRule"
            Remove-ExcelStyleMergeRule -RuleName "HighPriorityRule"
            Remove-ExcelStyleMergeRule -RuleName "Default_Width"
        }

        It "Should export and import rules" {
            # DÃ©finir quelques rÃ¨gles de fusion
            Set-ExcelStyleMergeRule -RuleName "ExportRule1" -PropertyName "Color" -Strategy "SourceWins" -Priority 5
            Set-ExcelStyleMergeRule -RuleName "ExportRule2" -PropertyName "Width" -Strategy "TargetWins" -Priority 10

            # Exporter les rÃ¨gles
            $TempFile = [System.IO.Path]::GetTempFileName()
            $ExportCount = Export-ExcelStyleMergeRules -Path $TempFile -Force
            $ExportCount | Should -BeGreaterThan 0

            # Supprimer les rÃ¨gles
            Remove-ExcelStyleMergeRule -RuleName "ExportRule1"
            Remove-ExcelStyleMergeRule -RuleName "ExportRule2"

            # Importer les rÃ¨gles
            $ImportCount = Import-ExcelStyleMergeRules -Path $TempFile
            $ImportCount | Should -BeGreaterThan 0

            # VÃ©rifier que les rÃ¨gles ont Ã©tÃ© importÃ©es
            $Rule1 = Get-ExcelStyleMergeRule -RuleName "ExportRule1"
            $Rule1 | Should -Not -BeNullOrEmpty
            $Rule1.PropertyName | Should -Be "Color"
            $Rule1.Strategy | Should -Be "SourceWins"

            $Rule2 = Get-ExcelStyleMergeRule -RuleName "ExportRule2"
            $Rule2 | Should -Not -BeNullOrEmpty
            $Rule2.PropertyName | Should -Be "Width"
            $Rule2.Strategy | Should -Be "TargetWins"

            # Nettoyer les rÃ¨gles de test
            Remove-ExcelStyleMergeRule -RuleName "ExportRule1"
            Remove-ExcelStyleMergeRule -RuleName "ExportRule2"

            # Supprimer le fichier temporaire
            Remove-Item -Path $TempFile -Force
        }

        It "Should merge rule sets" {
            # DÃ©finir quelques rÃ¨gles de fusion
            Set-ExcelStyleMergeRule -RuleName "MergeRule1" -PropertyName "Color" -Strategy "SourceWins" -Priority 5

            # Exporter les rÃ¨gles
            $TempFile = [System.IO.Path]::GetTempFileName()
            Export-ExcelStyleMergeRules -Path $TempFile -Force

            # Modifier la rÃ¨gle existante et ajouter une nouvelle rÃ¨gle
            Set-ExcelStyleMergeRule -RuleName "MergeRule1" -PropertyName "Color" -Strategy "TargetWins" -Priority 10
            Set-ExcelStyleMergeRule -RuleName "MergeRule2" -PropertyName "Width" -Strategy "MergeNonNull" -Priority 15

            # Fusionner les rÃ¨gles avec la stratÃ©gie KeepExisting
            $MergeCount = Merge-ExcelStyleMergeRules -Path $TempFile -Strategy "KeepExisting"
            $MergeCount | Should -BeGreaterThan 0

            # VÃ©rifier que la rÃ¨gle existante n'a pas Ã©tÃ© modifiÃ©e
            $Rule1 = Get-ExcelStyleMergeRule -RuleName "MergeRule1"
            $Rule1.Strategy | Should -Be "TargetWins"
            $Rule1.Priority | Should -Be 10

            # Nettoyer les rÃ¨gles de test
            Remove-ExcelStyleMergeRule -RuleName "MergeRule1"
            Remove-ExcelStyleMergeRule -RuleName "MergeRule2"

            # Supprimer le fichier temporaire
            Remove-Item -Path $TempFile -Force
        }
    }

    Context "Manual resolution functions" {
        It "Should handle Manual strategy without interactive mode" {
            # Fusionner deux styles avec la stratÃ©gie Manual mais sans mode interactif
            $MergedStyle = Merge-ExcelLineStylesByName -SourceStyleName "Ligne rouge" -TargetStyleName "Ligne bleue" -NewName "Style fusionnÃ© manuel non interactif" -MergeStrategy "Manual"

            # VÃ©rifier que le style fusionnÃ© a Ã©tÃ© crÃ©Ã©
            $MergedStyle | Should -Not -BeNullOrEmpty
            $MergedStyle.Name | Should -Be "Style fusionnÃ© manuel non interactif"

            # VÃ©rifier que la stratÃ©gie Manual sans mode interactif se comporte comme MergeNonNull
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"
            $MergedStyle.LineConfig.Color | Should -Be $TargetStyle.LineConfig.Color
        }

        # Note: Les tests interactifs ne sont pas inclus car ils nÃ©cessitent une interaction utilisateur
        # Mais nous pouvons tester les fonctions auxiliaires

        It "Should correctly detect empty values" {
            # Tester la dÃ©tection des valeurs vides pour diffÃ©rents types
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
            $MergedStyle = Merge-ExcelLineStylesByName -SourceStyleName "Ligne rouge" -TargetStyleName "Ligne bleue" -NewName "Style fusionnÃ© par nom"

            # VÃ©rifier que le style fusionnÃ© a Ã©tÃ© crÃ©Ã©
            $MergedStyle | Should -Not -BeNullOrEmpty
            $MergedStyle.Name | Should -Be "Style fusionnÃ© par nom"

            # VÃ©rifier que le style fusionnÃ© a le tag "FusionnÃ©"
            $MergedStyle.HasTag("FusionnÃ©") | Should -Be $true
        }

        It "Should handle invalid style names" {
            # Essayer de fusionner avec un nom de style inexistant
            $MergedStyle = Merge-ExcelLineStylesByName -SourceStyleName "Style inexistant" -TargetStyleName "Ligne bleue" -NewName "Style fusionnÃ© invalide"

            # VÃ©rifier que la fusion a Ã©chouÃ©
            $MergedStyle | Should -BeNullOrEmpty
        }

        It "Should pass all parameters to Merge-ExcelLineStyles" {
            # Fusionner deux styles avec tous les paramÃ¨tres
            $MergedStyle = Merge-ExcelLineStylesByName -SourceStyleName "Ligne rouge" -TargetStyleName "Ligne bleue" -NewName "Style fusionnÃ© complet" -Description "Description complÃ¨te" -MergeStrategy "TargetWins" -MergeTags -Category "CatÃ©gorie complÃ¨te"

            # VÃ©rifier que le style fusionnÃ© a Ã©tÃ© crÃ©Ã©
            $MergedStyle | Should -Not -BeNullOrEmpty
            $MergedStyle.Name | Should -Be "Style fusionnÃ© complet"
            $MergedStyle.Description | Should -Be "Description complÃ¨te"
            $MergedStyle.Category | Should -Be "CatÃ©gorie complÃ¨te"

            # VÃ©rifier que les propriÃ©tÃ©s du style cible ont Ã©tÃ© utilisÃ©es (TargetWins)
            $TargetStyle = Get-ExcelPredefinedLineStyle -Name "Ligne bleue"
            $MergedStyle.LineConfig.Color | Should -Be $TargetStyle.LineConfig.Color

            # VÃ©rifier que les tags ont Ã©tÃ© fusionnÃ©s
            $SourceStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            foreach ($Tag in $SourceStyle.Tags) {
                $MergedStyle.HasTag($Tag) | Should -Be $true
            }
            foreach ($Tag in $TargetStyle.Tags) {
                $MergedStyle.HasTag($Tag) | Should -Be $true
            }
            $MergedStyle.HasTag("FusionnÃ©") | Should -Be $true
        }
    }
}

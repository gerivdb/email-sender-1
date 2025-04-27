# Tests pour les fonctionnalitÃ©s de personnalisation des styles Excel

# Importer Pester
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Importer les modules Ã  tester
$StyleRegistryPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_style_registry.ps1"
$PredefinedStylesPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_predefined_styles.ps1"
. $StyleRegistryPath
. $PredefinedStylesPath

Describe "Excel Style Customization" {
    BeforeAll {
        # RÃ©initialiser le registre avant chaque test
        Reset-ExcelStyleRegistry
        
        # Initialiser les styles prÃ©dÃ©finis
        Initialize-ExcelPredefinedStyles -Force
    }
    
    Context "Copy-ExcelLineStyleWithModifications function" {
        It "Should create a copy of a predefined style with modifications" {
            # Obtenir un style prÃ©dÃ©fini
            $OriginalStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            
            # CrÃ©er une copie modifiÃ©e
            $NewStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Ma ligne personnalisÃ©e" -Color "#00FF00" -Width 3
            
            # VÃ©rifier que la copie a Ã©tÃ© crÃ©Ã©e
            $NewStyle | Should -Not -BeNullOrEmpty
            $NewStyle.Name | Should -Be "Ma ligne personnalisÃ©e"
            $NewStyle.LineConfig.Color | Should -Be "#00FF00"
            $NewStyle.LineConfig.Width | Should -Be 3
            $NewStyle.IsBuiltIn | Should -Be $false
            $NewStyle.HasTag("PersonnalisÃ©") | Should -Be $true
            
            # VÃ©rifier que le style original n'a pas Ã©tÃ© modifiÃ©
            $OriginalStyle.LineConfig.Color | Should -Be "#FF0000"
            $OriginalStyle.IsBuiltIn | Should -Be $true
            
            # VÃ©rifier que le nouveau style est dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Registry.GetById($NewStyle.Id) | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle invalid style name" {
            # Essayer de copier un style inexistant
            $NewStyle = Copy-ExcelLineStyleWithModifications -Name "Style inexistant" -NewName "Ma ligne personnalisÃ©e"
            
            # VÃ©rifier que la copie n'a pas Ã©tÃ© crÃ©Ã©e
            $NewStyle | Should -BeNullOrEmpty
        }
        
        It "Should handle invalid color format" {
            # Essayer de copier un style avec un format de couleur invalide
            $NewStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Ma ligne personnalisÃ©e" -Color "Rouge"
            
            # VÃ©rifier que la copie a Ã©tÃ© crÃ©Ã©e mais avec la couleur d'origine
            $NewStyle | Should -Not -BeNullOrEmpty
            $NewStyle.LineConfig.Color | Should -Be "#FF0000"
        }
        
        It "Should set custom tags" {
            # CrÃ©er une copie avec des tags personnalisÃ©s
            $NewStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Ma ligne personnalisÃ©e" -Tags @("Tag1", "Tag2")
            
            # VÃ©rifier que les tags ont Ã©tÃ© dÃ©finis
            $NewStyle | Should -Not -BeNullOrEmpty
            $NewStyle.HasTag("Tag1") | Should -Be $true
            $NewStyle.HasTag("Tag2") | Should -Be $true
            $NewStyle.HasTag("PersonnalisÃ©") | Should -Be $true
        }
    }
    
    Context "Edit-ExcelLineStyle function" {
        It "Should modify an existing style" {
            # CrÃ©er un style personnalisÃ©
            $OriginalStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style Ã  modifier"
            
            # Modifier le style
            $Result = Edit-ExcelLineStyle -Id $OriginalStyle.Id -Name "Style modifiÃ©" -Color "#0000FF" -Width 4
            
            # VÃ©rifier que la modification a rÃ©ussi
            $Result | Should -Be $true
            
            # Obtenir le style modifiÃ©
            $Registry = Get-ExcelStyleRegistry
            $ModifiedStyle = $Registry.GetById($OriginalStyle.Id)
            
            # VÃ©rifier les modifications
            $ModifiedStyle | Should -Not -BeNullOrEmpty
            $ModifiedStyle.Name | Should -Be "Style modifiÃ©"
            $ModifiedStyle.LineConfig.Color | Should -Be "#0000FF"
            $ModifiedStyle.LineConfig.Width | Should -Be 4
        }
        
        It "Should handle invalid style ID" {
            # Essayer de modifier un style inexistant
            $Result = Edit-ExcelLineStyle -Id "00000000-0000-0000-0000-000000000000" -Name "Style modifiÃ©"
            
            # VÃ©rifier que la modification a Ã©chouÃ©
            $Result | Should -Be $false
        }
        
        It "Should handle non-line style" {
            # CrÃ©er un style de couleur
            $ColorStyle = [ExcelColorStyle]::new()
            $ColorStyle.Name = "Style de couleur"
            $Registry = Get-ExcelStyleRegistry
            $Registry.Add($ColorStyle) | Out-Null
            
            # Essayer de modifier le style de couleur avec Edit-ExcelLineStyle
            $Result = Edit-ExcelLineStyle -Id $ColorStyle.Id -Name "Style modifiÃ©"
            
            # VÃ©rifier que la modification a Ã©chouÃ©
            $Result | Should -Be $false
        }
        
        It "Should not modify if no changes are specified" {
            # CrÃ©er un style personnalisÃ©
            $OriginalStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style sans modifications"
            
            # Appeler Edit-ExcelLineStyle sans spÃ©cifier de modifications
            $Result = Edit-ExcelLineStyle -Id $OriginalStyle.Id
            
            # VÃ©rifier que la fonction a retournÃ© true (pas d'erreur)
            $Result | Should -Be $true
            
            # Obtenir le style
            $Registry = Get-ExcelStyleRegistry
            $Style = $Registry.GetById($OriginalStyle.Id)
            
            # VÃ©rifier que le style n'a pas Ã©tÃ© modifiÃ©
            $Style.Name | Should -Be "Style sans modifications"
        }
    }
    
    Context "Remove-ExcelLineStyle function" {
        It "Should remove a custom style" {
            # CrÃ©er un style personnalisÃ©
            $CustomStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style Ã  supprimer"
            
            # Supprimer le style
            $Result = Remove-ExcelLineStyle -Id $CustomStyle.Id
            
            # VÃ©rifier que la suppression a rÃ©ussi
            $Result | Should -Be $true
            
            # VÃ©rifier que le style n'est plus dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Registry.GetById($CustomStyle.Id) | Should -BeNullOrEmpty
        }
        
        It "Should not remove a built-in style" {
            # Obtenir un style prÃ©dÃ©fini
            $BuiltInStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            
            # Essayer de supprimer le style prÃ©dÃ©fini
            $Result = Remove-ExcelLineStyle -Id $BuiltInStyle.Id
            
            # VÃ©rifier que la suppression a Ã©chouÃ©
            $Result | Should -Be $false
            
            # VÃ©rifier que le style est toujours dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Registry.GetById($BuiltInStyle.Id) | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle invalid style ID" {
            # Essayer de supprimer un style inexistant
            $Result = Remove-ExcelLineStyle -Id "00000000-0000-0000-0000-000000000000"
            
            # VÃ©rifier que la suppression a Ã©chouÃ©
            $Result | Should -Be $false
        }
    }
    
    Context "Undo-ExcelLineStyleChanges function" {
        It "Should restore a previous version of a style" {
            # CrÃ©er un style personnalisÃ©
            $OriginalStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style original"
            
            # Modifier le style
            Edit-ExcelLineStyle -Id $OriginalStyle.Id -Name "Style modifiÃ©" -Color "#0000FF"
            
            # VÃ©rifier que le style a Ã©tÃ© modifiÃ©
            $Registry = Get-ExcelStyleRegistry
            $ModifiedStyle = $Registry.GetById($OriginalStyle.Id)
            $ModifiedStyle.Name | Should -Be "Style modifiÃ©"
            $ModifiedStyle.LineConfig.Color | Should -Be "#0000FF"
            
            # Annuler les modifications
            $Result = Undo-ExcelLineStyleChanges -Id $OriginalStyle.Id
            
            # VÃ©rifier que la restauration a rÃ©ussi
            $Result | Should -Be $true
            
            # VÃ©rifier que le style a Ã©tÃ© restaurÃ©
            $RestoredStyle = $Registry.GetById($OriginalStyle.Id)
            $RestoredStyle.Name | Should -Be "Style original"
            $RestoredStyle.LineConfig.Color | Should -Be "#FF0000"
        }
        
        It "Should handle styles without history" {
            # CrÃ©er un style personnalisÃ© sans historique
            $CustomStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style sans historique"
            
            # Essayer d'annuler les modifications
            $Result = Undo-ExcelLineStyleChanges -Id $CustomStyle.Id
            
            # VÃ©rifier que la restauration a Ã©chouÃ©
            $Result | Should -Be $false
        }
        
        It "Should handle built-in styles" {
            # Obtenir un style prÃ©dÃ©fini
            $BuiltInStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            
            # Essayer d'annuler les modifications
            $Result = Undo-ExcelLineStyleChanges -Id $BuiltInStyle.Id
            
            # VÃ©rifier que la restauration a Ã©chouÃ©
            $Result | Should -Be $false
        }
    }
    
    Context "History management in ExcelStyleRegistry" {
        It "Should track style modifications in history" {
            # CrÃ©er un style personnalisÃ©
            $CustomStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style avec historique"
            
            # VÃ©rifier qu'il n'y a pas d'historique initialement
            $Registry = Get-ExcelStyleRegistry
            $Registry.HasHistory($CustomStyle.Id) | Should -Be $false
            
            # Modifier le style plusieurs fois
            Edit-ExcelLineStyle -Id $CustomStyle.Id -Name "Style modifiÃ© 1"
            Edit-ExcelLineStyle -Id $CustomStyle.Id -Name "Style modifiÃ© 2"
            Edit-ExcelLineStyle -Id $CustomStyle.Id -Name "Style modifiÃ© 3"
            
            # VÃ©rifier qu'il y a un historique
            $Registry.HasHistory($CustomStyle.Id) | Should -Be $true
            
            # Annuler les modifications une par une
            Undo-ExcelLineStyleChanges -Id $CustomStyle.Id
            $Style1 = $Registry.GetById($CustomStyle.Id)
            $Style1.Name | Should -Be "Style modifiÃ© 2"
            
            Undo-ExcelLineStyleChanges -Id $CustomStyle.Id
            $Style2 = $Registry.GetById($CustomStyle.Id)
            $Style2.Name | Should -Be "Style modifiÃ© 1"
            
            Undo-ExcelLineStyleChanges -Id $CustomStyle.Id
            $Style3 = $Registry.GetById($CustomStyle.Id)
            $Style3.Name | Should -Be "Style avec historique"
            
            # VÃ©rifier qu'il n'y a plus d'historique
            $Registry.HasHistory($CustomStyle.Id) | Should -Be $false
        }
        
        It "Should clear history when registry is cleared" {
            # CrÃ©er un style personnalisÃ©
            $CustomStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style pour test de Clear"
            
            # Modifier le style pour crÃ©er un historique
            Edit-ExcelLineStyle -Id $CustomStyle.Id -Name "Style modifiÃ©"
            
            # VÃ©rifier qu'il y a un historique
            $Registry = Get-ExcelStyleRegistry
            $Registry.HasHistory($CustomStyle.Id) | Should -Be $true
            
            # Vider le registre
            $Registry.Clear()
            
            # VÃ©rifier que l'historique a Ã©tÃ© vidÃ©
            $Registry.HasHistory($CustomStyle.Id) | Should -Be $false
        }
    }
}

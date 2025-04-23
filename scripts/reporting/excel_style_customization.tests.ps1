# Tests pour les fonctionnalités de personnalisation des styles Excel

# Importer Pester
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Importer les modules à tester
$StyleRegistryPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_style_registry.ps1"
$PredefinedStylesPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_predefined_styles.ps1"
. $StyleRegistryPath
. $PredefinedStylesPath

Describe "Excel Style Customization" {
    BeforeAll {
        # Réinitialiser le registre avant chaque test
        Reset-ExcelStyleRegistry
        
        # Initialiser les styles prédéfinis
        Initialize-ExcelPredefinedStyles -Force
    }
    
    Context "Copy-ExcelLineStyleWithModifications function" {
        It "Should create a copy of a predefined style with modifications" {
            # Obtenir un style prédéfini
            $OriginalStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            
            # Créer une copie modifiée
            $NewStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Ma ligne personnalisée" -Color "#00FF00" -Width 3
            
            # Vérifier que la copie a été créée
            $NewStyle | Should -Not -BeNullOrEmpty
            $NewStyle.Name | Should -Be "Ma ligne personnalisée"
            $NewStyle.LineConfig.Color | Should -Be "#00FF00"
            $NewStyle.LineConfig.Width | Should -Be 3
            $NewStyle.IsBuiltIn | Should -Be $false
            $NewStyle.HasTag("Personnalisé") | Should -Be $true
            
            # Vérifier que le style original n'a pas été modifié
            $OriginalStyle.LineConfig.Color | Should -Be "#FF0000"
            $OriginalStyle.IsBuiltIn | Should -Be $true
            
            # Vérifier que le nouveau style est dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Registry.GetById($NewStyle.Id) | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle invalid style name" {
            # Essayer de copier un style inexistant
            $NewStyle = Copy-ExcelLineStyleWithModifications -Name "Style inexistant" -NewName "Ma ligne personnalisée"
            
            # Vérifier que la copie n'a pas été créée
            $NewStyle | Should -BeNullOrEmpty
        }
        
        It "Should handle invalid color format" {
            # Essayer de copier un style avec un format de couleur invalide
            $NewStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Ma ligne personnalisée" -Color "Rouge"
            
            # Vérifier que la copie a été créée mais avec la couleur d'origine
            $NewStyle | Should -Not -BeNullOrEmpty
            $NewStyle.LineConfig.Color | Should -Be "#FF0000"
        }
        
        It "Should set custom tags" {
            # Créer une copie avec des tags personnalisés
            $NewStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Ma ligne personnalisée" -Tags @("Tag1", "Tag2")
            
            # Vérifier que les tags ont été définis
            $NewStyle | Should -Not -BeNullOrEmpty
            $NewStyle.HasTag("Tag1") | Should -Be $true
            $NewStyle.HasTag("Tag2") | Should -Be $true
            $NewStyle.HasTag("Personnalisé") | Should -Be $true
        }
    }
    
    Context "Edit-ExcelLineStyle function" {
        It "Should modify an existing style" {
            # Créer un style personnalisé
            $OriginalStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style à modifier"
            
            # Modifier le style
            $Result = Edit-ExcelLineStyle -Id $OriginalStyle.Id -Name "Style modifié" -Color "#0000FF" -Width 4
            
            # Vérifier que la modification a réussi
            $Result | Should -Be $true
            
            # Obtenir le style modifié
            $Registry = Get-ExcelStyleRegistry
            $ModifiedStyle = $Registry.GetById($OriginalStyle.Id)
            
            # Vérifier les modifications
            $ModifiedStyle | Should -Not -BeNullOrEmpty
            $ModifiedStyle.Name | Should -Be "Style modifié"
            $ModifiedStyle.LineConfig.Color | Should -Be "#0000FF"
            $ModifiedStyle.LineConfig.Width | Should -Be 4
        }
        
        It "Should handle invalid style ID" {
            # Essayer de modifier un style inexistant
            $Result = Edit-ExcelLineStyle -Id "00000000-0000-0000-0000-000000000000" -Name "Style modifié"
            
            # Vérifier que la modification a échoué
            $Result | Should -Be $false
        }
        
        It "Should handle non-line style" {
            # Créer un style de couleur
            $ColorStyle = [ExcelColorStyle]::new()
            $ColorStyle.Name = "Style de couleur"
            $Registry = Get-ExcelStyleRegistry
            $Registry.Add($ColorStyle) | Out-Null
            
            # Essayer de modifier le style de couleur avec Edit-ExcelLineStyle
            $Result = Edit-ExcelLineStyle -Id $ColorStyle.Id -Name "Style modifié"
            
            # Vérifier que la modification a échoué
            $Result | Should -Be $false
        }
        
        It "Should not modify if no changes are specified" {
            # Créer un style personnalisé
            $OriginalStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style sans modifications"
            
            # Appeler Edit-ExcelLineStyle sans spécifier de modifications
            $Result = Edit-ExcelLineStyle -Id $OriginalStyle.Id
            
            # Vérifier que la fonction a retourné true (pas d'erreur)
            $Result | Should -Be $true
            
            # Obtenir le style
            $Registry = Get-ExcelStyleRegistry
            $Style = $Registry.GetById($OriginalStyle.Id)
            
            # Vérifier que le style n'a pas été modifié
            $Style.Name | Should -Be "Style sans modifications"
        }
    }
    
    Context "Remove-ExcelLineStyle function" {
        It "Should remove a custom style" {
            # Créer un style personnalisé
            $CustomStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style à supprimer"
            
            # Supprimer le style
            $Result = Remove-ExcelLineStyle -Id $CustomStyle.Id
            
            # Vérifier que la suppression a réussi
            $Result | Should -Be $true
            
            # Vérifier que le style n'est plus dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Registry.GetById($CustomStyle.Id) | Should -BeNullOrEmpty
        }
        
        It "Should not remove a built-in style" {
            # Obtenir un style prédéfini
            $BuiltInStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            
            # Essayer de supprimer le style prédéfini
            $Result = Remove-ExcelLineStyle -Id $BuiltInStyle.Id
            
            # Vérifier que la suppression a échoué
            $Result | Should -Be $false
            
            # Vérifier que le style est toujours dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Registry.GetById($BuiltInStyle.Id) | Should -Not -BeNullOrEmpty
        }
        
        It "Should handle invalid style ID" {
            # Essayer de supprimer un style inexistant
            $Result = Remove-ExcelLineStyle -Id "00000000-0000-0000-0000-000000000000"
            
            # Vérifier que la suppression a échoué
            $Result | Should -Be $false
        }
    }
    
    Context "Undo-ExcelLineStyleChanges function" {
        It "Should restore a previous version of a style" {
            # Créer un style personnalisé
            $OriginalStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style original"
            
            # Modifier le style
            Edit-ExcelLineStyle -Id $OriginalStyle.Id -Name "Style modifié" -Color "#0000FF"
            
            # Vérifier que le style a été modifié
            $Registry = Get-ExcelStyleRegistry
            $ModifiedStyle = $Registry.GetById($OriginalStyle.Id)
            $ModifiedStyle.Name | Should -Be "Style modifié"
            $ModifiedStyle.LineConfig.Color | Should -Be "#0000FF"
            
            # Annuler les modifications
            $Result = Undo-ExcelLineStyleChanges -Id $OriginalStyle.Id
            
            # Vérifier que la restauration a réussi
            $Result | Should -Be $true
            
            # Vérifier que le style a été restauré
            $RestoredStyle = $Registry.GetById($OriginalStyle.Id)
            $RestoredStyle.Name | Should -Be "Style original"
            $RestoredStyle.LineConfig.Color | Should -Be "#FF0000"
        }
        
        It "Should handle styles without history" {
            # Créer un style personnalisé sans historique
            $CustomStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style sans historique"
            
            # Essayer d'annuler les modifications
            $Result = Undo-ExcelLineStyleChanges -Id $CustomStyle.Id
            
            # Vérifier que la restauration a échoué
            $Result | Should -Be $false
        }
        
        It "Should handle built-in styles" {
            # Obtenir un style prédéfini
            $BuiltInStyle = Get-ExcelPredefinedLineStyle -Name "Ligne rouge"
            
            # Essayer d'annuler les modifications
            $Result = Undo-ExcelLineStyleChanges -Id $BuiltInStyle.Id
            
            # Vérifier que la restauration a échoué
            $Result | Should -Be $false
        }
    }
    
    Context "History management in ExcelStyleRegistry" {
        It "Should track style modifications in history" {
            # Créer un style personnalisé
            $CustomStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style avec historique"
            
            # Vérifier qu'il n'y a pas d'historique initialement
            $Registry = Get-ExcelStyleRegistry
            $Registry.HasHistory($CustomStyle.Id) | Should -Be $false
            
            # Modifier le style plusieurs fois
            Edit-ExcelLineStyle -Id $CustomStyle.Id -Name "Style modifié 1"
            Edit-ExcelLineStyle -Id $CustomStyle.Id -Name "Style modifié 2"
            Edit-ExcelLineStyle -Id $CustomStyle.Id -Name "Style modifié 3"
            
            # Vérifier qu'il y a un historique
            $Registry.HasHistory($CustomStyle.Id) | Should -Be $true
            
            # Annuler les modifications une par une
            Undo-ExcelLineStyleChanges -Id $CustomStyle.Id
            $Style1 = $Registry.GetById($CustomStyle.Id)
            $Style1.Name | Should -Be "Style modifié 2"
            
            Undo-ExcelLineStyleChanges -Id $CustomStyle.Id
            $Style2 = $Registry.GetById($CustomStyle.Id)
            $Style2.Name | Should -Be "Style modifié 1"
            
            Undo-ExcelLineStyleChanges -Id $CustomStyle.Id
            $Style3 = $Registry.GetById($CustomStyle.Id)
            $Style3.Name | Should -Be "Style avec historique"
            
            # Vérifier qu'il n'y a plus d'historique
            $Registry.HasHistory($CustomStyle.Id) | Should -Be $false
        }
        
        It "Should clear history when registry is cleared" {
            # Créer un style personnalisé
            $CustomStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style pour test de Clear"
            
            # Modifier le style pour créer un historique
            Edit-ExcelLineStyle -Id $CustomStyle.Id -Name "Style modifié"
            
            # Vérifier qu'il y a un historique
            $Registry = Get-ExcelStyleRegistry
            $Registry.HasHistory($CustomStyle.Id) | Should -Be $true
            
            # Vider le registre
            $Registry.Clear()
            
            # Vérifier que l'historique a été vidé
            $Registry.HasHistory($CustomStyle.Id) | Should -Be $false
        }
    }
}

# Tests pour le module excel_style_registry.ps1

# Importer Pester
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Importer le module Ã  tester
$ModulePath = Join-Path -Path $PSScriptRoot -ChildPath "excel_style_registry.ps1"
. $ModulePath

Describe "Excel Style Registry Module" {
    BeforeAll {
        # RÃ©initialiser le registre avant chaque test
        Reset-ExcelStyleRegistry
    }
    
    Context "IExcelStyle interface" {
        It "Should create a base style with default values" {
            $Style = [IExcelStyle]::new()
            $Style.Name | Should -Be "Default Style"
            $Style.Description | Should -Be "Style par dÃ©faut"
            $Style.Category | Should -Be "General"
            $Style.Tags.Count | Should -Be 0
            $Style.IsBuiltIn | Should -Be $false
            $Style.Id | Should -Not -BeNullOrEmpty
        }
        
        It "Should create a base style with custom name and description" {
            $Style = [IExcelStyle]::new("Test Style", "Test Description")
            $Style.Name | Should -Be "Test Style"
            $Style.Description | Should -Be "Test Description"
            $Style.Category | Should -Be "General"
        }
        
        It "Should create a base style with all custom properties" {
            $Id = [Guid]::NewGuid().ToString()
            $Tags = @("Tag1", "Tag2")
            $Style = [IExcelStyle]::new($Id, "Test Style", "Test Description", "Test Category", $Tags, $true)
            $Style.Id | Should -Be $Id
            $Style.Name | Should -Be "Test Style"
            $Style.Description | Should -Be "Test Description"
            $Style.Category | Should -Be "Test Category"
            $Style.Tags | Should -Be $Tags
            $Style.IsBuiltIn | Should -Be $true
        }
        
        It "Should validate a style" {
            $Style = [IExcelStyle]::new()
            $Style.Validate() | Should -Be $true
            
            $Style.Id = ""
            $Style.Validate() | Should -Be $false
        }
        
        It "Should add and remove tags" {
            $Style = [IExcelStyle]::new()
            $Style.AddTag("Tag1")
            $Style.Tags.Count | Should -Be 1
            $Style.Tags[0] | Should -Be "Tag1"
            
            $Style.AddTag("Tag2")
            $Style.Tags.Count | Should -Be 2
            
            $Style.HasTag("Tag1") | Should -Be $true
            $Style.HasTag("Tag3") | Should -Be $false
            
            $Style.RemoveTag("Tag1") | Should -Be $true
            $Style.Tags.Count | Should -Be 1
            $Style.Tags[0] | Should -Be "Tag2"
            
            $Style.RemoveTag("Tag3") | Should -Be $false
        }
        
        It "Should update metadata" {
            $Style = [IExcelStyle]::new()
            $Style.UpdateMetadata("New Name", "New Description", "New Category")
            $Style.Name | Should -Be "New Name"
            $Style.Description | Should -Be "New Description"
            $Style.Category | Should -Be "New Category"
        }
    }
    
    Context "ExcelLineStyle class" {
        It "Should create a line style with default values" {
            $Style = [ExcelLineStyle]::new()
            $Style.Name | Should -Be "Default Line Style"
            $Style.Description | Should -Be "Style de ligne par dÃ©faut"
            $Style.Category | Should -Be "Lines"
            $Style.LineConfig | Should -Not -BeNullOrEmpty
            $Style.Validate() | Should -Be $true
        }
        
        It "Should create a line style with custom line config" {
            $LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dash, "#FF0000")
            $Style = [ExcelLineStyle]::new($LineConfig)
            $Style.Name | Should -Be "Custom Line Style"
            $Style.LineConfig | Should -Be $LineConfig
            $Style.Validate() | Should -Be $true
        }
        
        It "Should clone a line style" {
            $LineConfig = [ExcelLineStyleConfig]::new(2, [ExcelLineStyle]::Dash, "#FF0000")
            $Style = [ExcelLineStyle]::new($LineConfig)
            $Style.Name = "Original Style"
            
            $Clone = $Style.Clone()
            $Clone.Name | Should -Be "Original Style"
            $Clone.Id | Should -Not -Be $Style.Id
            $Clone.LineConfig.Width | Should -Be 2
            $Clone.LineConfig.Style | Should -Be ([ExcelLineStyle]::Dash)
            $Clone.LineConfig.Color | Should -Be "#FF0000"
        }
    }
    
    Context "ExcelMarkerStyle class" {
        It "Should create a marker style with default values" {
            $Style = [ExcelMarkerStyle]::new()
            $Style.Name | Should -Be "Default Marker Style"
            $Style.Description | Should -Be "Style de marqueur par dÃ©faut"
            $Style.Category | Should -Be "Markers"
            $Style.MarkerConfig | Should -Not -BeNullOrEmpty
            $Style.Validate() | Should -Be $true
        }
        
        It "Should create a marker style with custom marker config" {
            $MarkerConfig = [ExcelMarkerConfig]::new([ExcelMarkerStyle]::Diamond, 10)
            $Style = [ExcelMarkerStyle]::new($MarkerConfig)
            $Style.Name | Should -Be "Custom Marker Style"
            $Style.MarkerConfig | Should -Be $MarkerConfig
            $Style.Validate() | Should -Be $true
        }
        
        It "Should clone a marker style" {
            $MarkerConfig = [ExcelMarkerConfig]::new([ExcelMarkerStyle]::Diamond, 10)
            $Style = [ExcelMarkerStyle]::new($MarkerConfig)
            $Style.Name = "Original Style"
            
            $Clone = $Style.Clone()
            $Clone.Name | Should -Be "Original Style"
            $Clone.Id | Should -Not -Be $Style.Id
            $Clone.MarkerConfig.Style | Should -Be ([ExcelMarkerStyle]::Diamond)
            $Clone.MarkerConfig.Size | Should -Be 10
        }
    }
    
    Context "ExcelBorderStyle class" {
        It "Should create a border style with default values" {
            $Style = [ExcelBorderStyle]::new()
            $Style.Name | Should -Be "Default Border Style"
            $Style.Description | Should -Be "Style de bordure par dÃ©faut"
            $Style.Category | Should -Be "Borders"
            $Style.BorderConfig | Should -Not -BeNullOrEmpty
            $Style.Validate() | Should -Be $true
        }
        
        It "Should create a border style with custom border config" {
            $BorderConfig = [ExcelBorderStyleConfig]::new([ExcelBorderStyle]::Medium, "#FF0000")
            $Style = [ExcelBorderStyle]::new($BorderConfig)
            $Style.Name | Should -Be "Custom Border Style"
            $Style.BorderConfig | Should -Be $BorderConfig
            $Style.Validate() | Should -Be $true
        }
        
        It "Should clone a border style" {
            $BorderConfig = [ExcelBorderStyleConfig]::new([ExcelBorderStyle]::Medium, "#FF0000")
            $Style = [ExcelBorderStyle]::new($BorderConfig)
            $Style.Name = "Original Style"
            
            $Clone = $Style.Clone()
            $Clone.Name | Should -Be "Original Style"
            $Clone.Id | Should -Not -Be $Style.Id
            $Clone.BorderConfig.Style | Should -Be ([ExcelBorderStyle]::Medium)
            $Clone.BorderConfig.Color | Should -Be "#FF0000"
        }
    }
    
    Context "ExcelColorStyle class" {
        It "Should create a color style with default values" {
            $Style = [ExcelColorStyle]::new()
            $Style.Name | Should -Be "Default Color Style"
            $Style.Description | Should -Be "Style de couleur par dÃ©faut"
            $Style.Category | Should -Be "Colors"
            $Style.Color | Should -Be "#000000"
            $Style.Transparency | Should -Be 0
            $Style.Validate() | Should -Be $true
        }
        
        It "Should create a color style with custom color" {
            $Style = [ExcelColorStyle]::new("#FF0000")
            $Style.Name | Should -Be "Custom Color Style"
            $Style.Color | Should -Be "#FF0000"
            $Style.Validate() | Should -Be $true
        }
        
        It "Should validate color format" {
            $Style = [ExcelColorStyle]::new("#FF0000")
            $Style.Validate() | Should -Be $true
            
            $Style.Color = "Red"
            $Style.Validate() | Should -Be $false
            
            $Style.Color = "#FF0000"
            $Style.Transparency = 101
            $Style.Validate() | Should -Be $false
        }
        
        It "Should clone a color style" {
            $Style = [ExcelColorStyle]::new("#FF0000")
            $Style.Transparency = 50
            $Style.Name = "Original Style"
            
            $Clone = $Style.Clone()
            $Clone.Name | Should -Be "Original Style"
            $Clone.Id | Should -Not -Be $Style.Id
            $Clone.Color | Should -Be "#FF0000"
            $Clone.Transparency | Should -Be 50
        }
    }
    
    Context "ExcelCombinedStyle class" {
        It "Should create a combined style with default values" {
            $Style = [ExcelCombinedStyle]::new()
            $Style.Name | Should -Be "Default Combined Style"
            $Style.Description | Should -Be "Style combinÃ© par dÃ©faut"
            $Style.Category | Should -Be "Combined"
            $Style.LineStyle | Should -BeNullOrEmpty
            $Style.MarkerStyle | Should -BeNullOrEmpty
            $Style.BorderStyle | Should -BeNullOrEmpty
            $Style.ColorStyle | Should -BeNullOrEmpty
            $Style.Validate() | Should -Be $false  # Au moins un style doit Ãªtre dÃ©fini
        }
        
        It "Should create a combined style with custom styles" {
            $LineStyle = [ExcelLineStyle]::new()
            $MarkerStyle = [ExcelMarkerStyle]::new()
            $Style = [ExcelCombinedStyle]::new($LineStyle, $MarkerStyle, $null, $null)
            $Style.Name | Should -Be "Custom Combined Style"
            $Style.LineStyle | Should -Be $LineStyle
            $Style.MarkerStyle | Should -Be $MarkerStyle
            $Style.Validate() | Should -Be $true
        }
        
        It "Should clone a combined style" {
            $LineStyle = [ExcelLineStyle]::new()
            $MarkerStyle = [ExcelMarkerStyle]::new()
            $Style = [ExcelCombinedStyle]::new($LineStyle, $MarkerStyle, $null, $null)
            $Style.Name = "Original Style"
            
            $Clone = $Style.Clone()
            $Clone.Name | Should -Be "Original Style"
            $Clone.Id | Should -Not -Be $Style.Id
            $Clone.LineStyle | Should -Not -BeNullOrEmpty
            $Clone.MarkerStyle | Should -Not -BeNullOrEmpty
            $Clone.BorderStyle | Should -BeNullOrEmpty
            $Clone.ColorStyle | Should -BeNullOrEmpty
        }
    }
    
    Context "ExcelStyleRegistry class" {
        It "Should create an empty registry" {
            $Registry = [ExcelStyleRegistry]::new()
            $Registry.Count | Should -Be 0
            $Registry.IsEmpty | Should -Be $true
            $Registry.Styles.Count | Should -Be 0
            $Registry.LineStyles.Count | Should -Be 0
            $Registry.MarkerStyles.Count | Should -Be 0
            $Registry.BorderStyles.Count | Should -Be 0
            $Registry.ColorStyles.Count | Should -Be 0
            $Registry.CombinedStyles.Count | Should -Be 0
            $Registry.Categories.Count | Should -Be 0
            $Registry.Tags.Count | Should -Be 0
        }
        
        It "Should add and remove styles" {
            $Registry = [ExcelStyleRegistry]::new()
            
            # Ajouter un style de ligne
            $LineStyle = [ExcelLineStyle]::new()
            $Registry.Add($LineStyle) | Should -Be $true
            $Registry.Count | Should -Be 1
            $Registry.IsEmpty | Should -Be $false
            $Registry.LineStyles.Count | Should -Be 1
            
            # Ajouter un style de marqueur
            $MarkerStyle = [ExcelMarkerStyle]::new()
            $Registry.Add($MarkerStyle) | Should -Be $true
            $Registry.Count | Should -Be 2
            $Registry.MarkerStyles.Count | Should -Be 1
            
            # Supprimer le style de ligne
            $Registry.Remove($LineStyle.Id) | Should -Be $true
            $Registry.Count | Should -Be 1
            $Registry.LineStyles.Count | Should -Be 0
            $Registry.MarkerStyles.Count | Should -Be 1
            
            # Supprimer le style de marqueur
            $Registry.Remove($MarkerStyle.Id) | Should -Be $true
            $Registry.Count | Should -Be 0
            $Registry.IsEmpty | Should -Be $true
        }
        
        It "Should add styles with categories and tags" {
            $Registry = [ExcelStyleRegistry]::new()
            
            # CrÃ©er un style avec catÃ©gorie et tags
            $Style = [ExcelLineStyle]::new()
            $Style.Category = "TestCategory"
            $Style.AddTag("Tag1")
            $Style.AddTag("Tag2")
            
            # Ajouter le style
            $Registry.Add($Style) | Should -Be $true
            $Registry.Count | Should -Be 1
            $Registry.Categories.Count | Should -Be 1
            $Registry.Categories["TestCategory"].Count | Should -Be 1
            $Registry.Tags.Count | Should -Be 2
            $Registry.Tags["Tag1"].Count | Should -Be 1
            $Registry.Tags["Tag2"].Count | Should -Be 1
            
            # Supprimer le style
            $Registry.Remove($Style.Id) | Should -Be $true
            $Registry.Count | Should -Be 0
            $Registry.Categories.Count | Should -Be 0
            $Registry.Tags.Count | Should -Be 0
        }
        
        It "Should get styles by various criteria" {
            $Registry = [ExcelStyleRegistry]::new()
            
            # CrÃ©er et ajouter des styles
            $LineStyle = [ExcelLineStyle]::new()
            $LineStyle.Name = "Test Line Style"
            $LineStyle.Category = "TestCategory"
            $LineStyle.AddTag("Tag1")
            $Registry.Add($LineStyle) | Should -Be $true
            
            $MarkerStyle = [ExcelMarkerStyle]::new()
            $MarkerStyle.Name = "Test Marker Style"
            $MarkerStyle.Category = "TestCategory"
            $MarkerStyle.AddTag("Tag2")
            $Registry.Add($MarkerStyle) | Should -Be $true
            
            # Obtenir par ID
            $Registry.GetById($LineStyle.Id) | Should -Be $LineStyle
            
            # Obtenir par nom
            $Registry.GetByName("Test Line Style") | Should -Be $LineStyle
            
            # Obtenir par catÃ©gorie
            $CategoryStyles = $Registry.GetByCategory("TestCategory")
            $CategoryStyles.Count | Should -Be 2
            $CategoryStyles | Should -Contain $LineStyle
            $CategoryStyles | Should -Contain $MarkerStyle
            
            # Obtenir par tag
            $Tag1Styles = $Registry.GetByTag("Tag1")
            $Tag1Styles.Count | Should -Be 1
            $Tag1Styles | Should -Contain $LineStyle
            
            $Tag2Styles = $Registry.GetByTag("Tag2")
            $Tag2Styles.Count | Should -Be 1
            $Tag2Styles | Should -Contain $MarkerStyle
            
            # Obtenir par type
            $LineStyles = $Registry.GetByType("line")
            $LineStyles.Count | Should -Be 1
            $LineStyles | Should -Contain $LineStyle
            
            $MarkerStyles = $Registry.GetByType("marker")
            $MarkerStyles.Count | Should -Be 1
            $MarkerStyles | Should -Contain $MarkerStyle
        }
        
        It "Should search styles by criteria" {
            $Registry = [ExcelStyleRegistry]::new()
            
            # CrÃ©er et ajouter des styles
            $LineStyle1 = [ExcelLineStyle]::new()
            $LineStyle1.Name = "Business Line Style"
            $LineStyle1.Category = "Business"
            $LineStyle1.AddTag("Professional")
            $LineStyle1.IsBuiltIn = $true
            $Registry.Add($LineStyle1) | Should -Be $true
            
            $LineStyle2 = [ExcelLineStyle]::new()
            $LineStyle2.Name = "Casual Line Style"
            $LineStyle2.Category = "Casual"
            $LineStyle2.AddTag("Colorful")
            $Registry.Add($LineStyle2) | Should -Be $true
            
            # Rechercher par nom
            $NameCriteria = @{ Name = "*Business*" }
            $NameResults = $Registry.Search($NameCriteria)
            $NameResults.Count | Should -Be 1
            $NameResults | Should -Contain $LineStyle1
            
            # Rechercher par catÃ©gorie
            $CategoryCriteria = @{ Category = "Business" }
            $CategoryResults = $Registry.Search($CategoryCriteria)
            $CategoryResults.Count | Should -Be 1
            $CategoryResults | Should -Contain $LineStyle1
            
            # Rechercher par tag
            $TagCriteria = @{ Tag = "Professional" }
            $TagResults = $Registry.Search($TagCriteria)
            $TagResults.Count | Should -Be 1
            $TagResults | Should -Contain $LineStyle1
            
            # Rechercher par type
            $TypeCriteria = @{ Type = "line" }
            $TypeResults = $Registry.Search($TypeCriteria)
            $TypeResults.Count | Should -Be 2
            $TypeResults | Should -Contain $LineStyle1
            $TypeResults | Should -Contain $LineStyle2
            
            # Rechercher par IsBuiltIn
            $BuiltInCriteria = @{ IsBuiltIn = $true }
            $BuiltInResults = $Registry.Search($BuiltInCriteria)
            $BuiltInResults.Count | Should -Be 1
            $BuiltInResults | Should -Contain $LineStyle1
            
            # Recherche combinÃ©e
            $CombinedCriteria = @{
                Type = "line"
                Category = "Business"
                IsBuiltIn = $true
            }
            $CombinedResults = $Registry.Search($CombinedCriteria)
            $CombinedResults.Count | Should -Be 1
            $CombinedResults | Should -Contain $LineStyle1
        }
        
        It "Should update styles" {
            $Registry = [ExcelStyleRegistry]::new()
            
            # CrÃ©er et ajouter un style
            $Style = [ExcelLineStyle]::new()
            $Style.Name = "Original Style"
            $Registry.Add($Style) | Should -Be $true
            
            # CrÃ©er un nouveau style pour la mise Ã  jour
            $UpdatedStyle = [ExcelLineStyle]::new()
            $UpdatedStyle.Name = "Updated Style"
            
            # Mettre Ã  jour le style
            $Registry.Update($Style.Id, $UpdatedStyle) | Should -Be $true
            
            # VÃ©rifier la mise Ã  jour
            $RetrievedStyle = $Registry.GetById($Style.Id)
            $RetrievedStyle | Should -Not -BeNullOrEmpty
            $RetrievedStyle.Name | Should -Be "Updated Style"
        }
        
        It "Should clear the registry" {
            $Registry = [ExcelStyleRegistry]::new()
            
            # Ajouter des styles
            $Registry.Add([ExcelLineStyle]::new()) | Should -Be $true
            $Registry.Add([ExcelMarkerStyle]::new()) | Should -Be $true
            $Registry.Count | Should -Be 2
            
            # Vider le registre
            $Registry.Clear()
            $Registry.Count | Should -Be 0
            $Registry.IsEmpty | Should -Be $true
            $Registry.LineStyles.Count | Should -Be 0
            $Registry.MarkerStyles.Count | Should -Be 0
            $Registry.Categories.Count | Should -Be 0
            $Registry.Tags.Count | Should -Be 0
        }
        
        It "Should get all styles" {
            $Registry = [ExcelStyleRegistry]::new()
            
            # Ajouter des styles
            $Style1 = [ExcelLineStyle]::new()
            $Style2 = [ExcelMarkerStyle]::new()
            $Registry.Add($Style1) | Should -Be $true
            $Registry.Add($Style2) | Should -Be $true
            
            # Obtenir tous les styles
            $AllStyles = $Registry.GetAll()
            $AllStyles.Count | Should -Be 2
            $AllStyles | Should -Contain $Style1
            $AllStyles | Should -Contain $Style2
        }
        
        It "Should get categories and tags" {
            $Registry = [ExcelStyleRegistry]::new()
            
            # CrÃ©er et ajouter des styles avec catÃ©gories et tags
            $Style1 = [ExcelLineStyle]::new()
            $Style1.Category = "Category1"
            $Style1.AddTag("Tag1")
            $Style1.AddTag("Tag2")
            $Registry.Add($Style1) | Should -Be $true
            
            $Style2 = [ExcelMarkerStyle]::new()
            $Style2.Category = "Category2"
            $Style2.AddTag("Tag2")
            $Style2.AddTag("Tag3")
            $Registry.Add($Style2) | Should -Be $true
            
            # Obtenir les catÃ©gories
            $Categories = $Registry.GetCategories()
            $Categories.Count | Should -Be 2
            $Categories | Should -Contain "Category1"
            $Categories | Should -Contain "Category2"
            
            # Obtenir les tags
            $Tags = $Registry.GetTags()
            $Tags.Count | Should -Be 3
            $Tags | Should -Contain "Tag1"
            $Tags | Should -Contain "Tag2"
            $Tags | Should -Contain "Tag3"
        }
    }
    
    Context "ExcelStyleRegistrySingleton class" {
        It "Should provide a singleton instance" {
            $Instance1 = [ExcelStyleRegistrySingleton]::GetInstance()
            $Instance2 = [ExcelStyleRegistrySingleton]::GetInstance()
            
            $Instance1 | Should -Be $Instance2
            $Instance1 | Should -BeOfType [ExcelStyleRegistry]
        }
        
        It "Should reset the singleton instance" {
            $Instance = [ExcelStyleRegistrySingleton]::GetInstance()
            
            # Ajouter un style
            $Style = [ExcelLineStyle]::new()
            $Instance.Add($Style) | Should -Be $true
            $Instance.Count | Should -Be 1
            
            # RÃ©initialiser l'instance
            [ExcelStyleRegistrySingleton]::Reset()
            $Instance.Count | Should -Be 0
        }
        
        It "Should create an isolated instance" {
            $Singleton = [ExcelStyleRegistrySingleton]::GetInstance()
            $Isolated = [ExcelStyleRegistrySingleton]::CreateIsolatedInstance()
            
            $Isolated | Should -Not -Be $Singleton
            $Isolated | Should -BeOfType [ExcelStyleRegistry]
            
            # Ajouter un style Ã  l'instance isolÃ©e
            $Style = [ExcelLineStyle]::new()
            $Isolated.Add($Style) | Should -Be $true
            $Isolated.Count | Should -Be 1
            
            # VÃ©rifier que l'instance singleton n'est pas affectÃ©e
            $Singleton.Count | Should -Be 0
        }
    }
    
    Context "Registry access functions" {
        It "Should get the registry instance" {
            $Registry = Get-ExcelStyleRegistry
            $Registry | Should -BeOfType [ExcelStyleRegistry]
        }
        
        It "Should create a new isolated registry" {
            $Registry = New-ExcelStyleRegistry
            $Registry | Should -BeOfType [ExcelStyleRegistry]
            
            # VÃ©rifier que c'est une instance isolÃ©e
            $Singleton = Get-ExcelStyleRegistry
            $Registry | Should -Not -Be $Singleton
        }
        
        It "Should reset the registry" {
            $Registry = Get-ExcelStyleRegistry
            
            # Ajouter un style
            $Style = [ExcelLineStyle]::new()
            Add-ExcelStyle -Style $Style | Should -Be $true
            $Registry.Count | Should -Be 1
            
            # RÃ©initialiser le registre
            Reset-ExcelStyleRegistry
            $Registry.Count | Should -Be 0
        }
        
        It "Should add and remove styles" {
            # Ajouter un style
            $Style = [ExcelLineStyle]::new()
            Add-ExcelStyle -Style $Style | Should -Be $true
            
            # VÃ©rifier que le style a Ã©tÃ© ajoutÃ©
            $Registry = Get-ExcelStyleRegistry
            $Registry.Count | Should -Be 1
            
            # Supprimer le style
            Remove-ExcelStyle -Id $Style.Id | Should -Be $true
            
            # VÃ©rifier que le style a Ã©tÃ© supprimÃ©
            $Registry.Count | Should -Be 0
        }
        
        It "Should get styles by various criteria" {
            # CrÃ©er et ajouter des styles
            $LineStyle = [ExcelLineStyle]::new()
            $LineStyle.Name = "Test Line Style"
            $LineStyle.Category = "TestCategory"
            $LineStyle.AddTag("Tag1")
            Add-ExcelStyle -Style $LineStyle | Should -Be $true
            
            $MarkerStyle = [ExcelMarkerStyle]::new()
            $MarkerStyle.Name = "Test Marker Style"
            $MarkerStyle.Category = "TestCategory"
            $MarkerStyle.AddTag("Tag2")
            Add-ExcelStyle -Style $MarkerStyle | Should -Be $true
            
            # Obtenir par ID
            $StyleById = Get-ExcelStyleById -Id $LineStyle.Id
            $StyleById | Should -Be $LineStyle
            
            # Obtenir par nom
            $StyleByName = Get-ExcelStyleByName -Name "Test Line Style"
            $StyleByName | Should -Be $LineStyle
            
            # Obtenir par catÃ©gorie
            $StylesByCategory = Get-ExcelStyleByCategory -Category "TestCategory"
            $StylesByCategory.Count | Should -Be 2
            $StylesByCategory | Should -Contain $LineStyle
            $StylesByCategory | Should -Contain $MarkerStyle
            
            # Obtenir par tag
            $StylesByTag1 = Get-ExcelStyleByTag -Tag "Tag1"
            $StylesByTag1.Count | Should -Be 1
            $StylesByTag1 | Should -Contain $LineStyle
            
            $StylesByTag2 = Get-ExcelStyleByTag -Tag "Tag2"
            $StylesByTag2.Count | Should -Be 1
            $StylesByTag2 | Should -Contain $MarkerStyle
            
            # Obtenir par type
            $LineStyles = Get-ExcelStyleByType -Type "Line"
            $LineStyles.Count | Should -Be 1
            $LineStyles | Should -Contain $LineStyle
            
            $MarkerStyles = Get-ExcelStyleByType -Type "Marker"
            $MarkerStyles.Count | Should -Be 1
            $MarkerStyles | Should -Contain $MarkerStyle
            
            # Rechercher par critÃ¨res
            $Criteria = @{
                Category = "TestCategory"
                Type = "Line"
            }
            $SearchResults = Search-ExcelStyle -Criteria $Criteria
            $SearchResults.Count | Should -Be 1
            $SearchResults | Should -Contain $LineStyle
            
            # Obtenir tous les styles
            $AllStyles = Get-ExcelStyle
            $AllStyles.Count | Should -Be 2
            $AllStyles | Should -Contain $LineStyle
            $AllStyles | Should -Contain $MarkerStyle
            
            # Obtenir les catÃ©gories
            $Categories = Get-ExcelStyleCategory
            $Categories.Count | Should -Be 1
            $Categories | Should -Contain "TestCategory"
            
            # Obtenir les tags
            $Tags = Get-ExcelStyleTag
            $Tags.Count | Should -Be 2
            $Tags | Should -Contain "Tag1"
            $Tags | Should -Contain "Tag2"
            
            # Mettre Ã  jour un style
            $UpdatedStyle = [ExcelLineStyle]::new()
            $UpdatedStyle.Name = "Updated Style"
            Update-ExcelStyle -Id $LineStyle.Id -Style $UpdatedStyle | Should -Be $true
            
            $UpdatedStyleById = Get-ExcelStyleById -Id $LineStyle.Id
            $UpdatedStyleById.Name | Should -Be "Updated Style"
        }
    }
}

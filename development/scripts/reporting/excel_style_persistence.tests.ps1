# Tests pour les fonctionnalitÃ©s de persistance des styles Excel

# Importer Pester
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Importer les modules Ã  tester
$StyleRegistryPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_style_registry.ps1"
$PredefinedStylesPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_predefined_styles.ps1"
. $StyleRegistryPath
. $PredefinedStylesPath

Describe "Excel Style Persistence" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $TestDir = Join-Path -Path $env:TEMP -ChildPath "ExcelStyleTests"
        if (-not (Test-Path -Path $TestDir)) {
            New-Item -Path $TestDir -ItemType Directory -Force | Out-Null
        }
        
        # Chemin du fichier de test
        $TestFilePath = Join-Path -Path $TestDir -ChildPath "TestStyles.json"
        
        # RÃ©initialiser le registre avant chaque test
        Reset-ExcelStyleRegistry
        
        # Initialiser les styles prÃ©dÃ©finis
        Initialize-ExcelPredefinedStyles -Force
        
        # CrÃ©er quelques styles personnalisÃ©s pour les tests
        $CustomStyle1 = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style personnalisÃ© 1" -Color "#00FF00" -Width 3
        $CustomStyle2 = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style personnalisÃ© 2" -Color "#FF00FF" -Width 2
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $TestFilePath) {
            Remove-Item -Path $TestFilePath -Force
        }
    }
    
    Context "Export-ExcelStyles function" {
        It "Should export custom styles to a file" {
            # Exporter les styles personnalisÃ©s
            $ExportedCount = Export-ExcelStyles -Path $TestFilePath
            
            # VÃ©rifier que des styles ont Ã©tÃ© exportÃ©s
            $ExportedCount | Should -BeGreaterThan 0
            
            # VÃ©rifier que le fichier a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $TestFilePath | Should -Be $true
            
            # VÃ©rifier le contenu du fichier
            $Content = Get-Content -Path $TestFilePath -Raw
            $Content | Should -Not -BeNullOrEmpty
            
            # VÃ©rifier que le fichier contient les styles personnalisÃ©s
            $Content | Should -Match "Style personnalisÃ© 1"
            $Content | Should -Match "Style personnalisÃ© 2"
        }
        
        It "Should export built-in styles when IncludeBuiltIn is specified" {
            # Exporter tous les styles, y compris les styles prÃ©dÃ©finis
            $ExportedCount = Export-ExcelStyles -Path $TestFilePath -IncludeBuiltIn -Force
            
            # VÃ©rifier que des styles ont Ã©tÃ© exportÃ©s
            $ExportedCount | Should -BeGreaterThan 2  # Plus que juste les styles personnalisÃ©s
            
            # VÃ©rifier le contenu du fichier
            $Content = Get-Content -Path $TestFilePath -Raw
            $Content | Should -Match "Ligne rouge"
            $Content | Should -Match "Ligne bleue"
        }
        
        It "Should filter styles by category" {
            # CrÃ©er un style avec une catÃ©gorie spÃ©cifique
            $CategoryStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style catÃ©gorisÃ©" -Category "CatÃ©gorie de test"
            
            # Exporter les styles de cette catÃ©gorie
            $ExportedCount = Export-ExcelStyles -Path $TestFilePath -Category "CatÃ©gorie de test" -Force
            
            # VÃ©rifier que seul le style de la catÃ©gorie a Ã©tÃ© exportÃ©
            $ExportedCount | Should -Be 1
            
            # VÃ©rifier le contenu du fichier
            $Content = Get-Content -Path $TestFilePath -Raw
            $Content | Should -Match "Style catÃ©gorisÃ©"
            $Content | Should -Not -Match "Style personnalisÃ© 1"
        }
        
        It "Should filter styles by tag" {
            # CrÃ©er un style avec un tag spÃ©cifique
            $TaggedStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style taguÃ©" -Tags @("Tag de test")
            
            # Exporter les styles avec ce tag
            $ExportedCount = Export-ExcelStyles -Path $TestFilePath -Tag "Tag de test" -Force
            
            # VÃ©rifier que seul le style avec le tag a Ã©tÃ© exportÃ©
            $ExportedCount | Should -Be 1
            
            # VÃ©rifier le contenu du fichier
            $Content = Get-Content -Path $TestFilePath -Raw
            $Content | Should -Match "Style taguÃ©"
            $Content | Should -Not -Match "Style personnalisÃ© 1"
        }
        
        It "Should not overwrite existing file without Force" {
            # CrÃ©er un fichier de test
            Set-Content -Path $TestFilePath -Value "Test content"
            
            # Essayer d'exporter sans Force
            $ExportedCount = Export-ExcelStyles -Path $TestFilePath
            
            # VÃ©rifier que l'exportation a Ã©chouÃ©
            $ExportedCount | Should -Be 0
            
            # VÃ©rifier que le contenu du fichier n'a pas Ã©tÃ© modifiÃ©
            $Content = Get-Content -Path $TestFilePath -Raw
            $Content | Should -Be "Test content"
        }
    }
    
    Context "Import-ExcelStyles function" {
        BeforeEach {
            # RÃ©initialiser le registre avant chaque test
            Reset-ExcelStyleRegistry
            
            # Initialiser les styles prÃ©dÃ©finis
            Initialize-ExcelPredefinedStyles -Force
            
            # CrÃ©er quelques styles personnalisÃ©s pour les tests
            $CustomStyle1 = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style personnalisÃ© 1" -Color "#00FF00" -Width 3
            $CustomStyle2 = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style personnalisÃ© 2" -Color "#FF00FF" -Width 2
            
            # Exporter les styles
            Export-ExcelStyles -Path $TestFilePath -Force
            
            # RÃ©initialiser le registre pour les tests d'importation
            Reset-ExcelStyleRegistry
            Initialize-ExcelPredefinedStyles -Force
        }
        
        It "Should import styles from a file" {
            # Importer les styles
            $ImportedCount = Import-ExcelStyles -Path $TestFilePath
            
            # VÃ©rifier que des styles ont Ã©tÃ© importÃ©s
            $ImportedCount | Should -Be 2
            
            # VÃ©rifier que les styles sont dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Styles = $Registry.Search(@{ IsBuiltIn = $false })
            $Styles.Count | Should -Be 2
            
            # VÃ©rifier les propriÃ©tÃ©s des styles importÃ©s
            $Style1 = $Registry.Search(@{ Name = "Style personnalisÃ© 1" })
            $Style1.Count | Should -Be 1
            $Style1[0].LineConfig.Color | Should -Be "#00FF00"
            $Style1[0].LineConfig.Width | Should -Be 3
            
            $Style2 = $Registry.Search(@{ Name = "Style personnalisÃ© 2" })
            $Style2.Count | Should -Be 1
            $Style2[0].LineConfig.Color | Should -Be "#FF00FF"
            $Style2[0].LineConfig.Width | Should -Be 2
        }
        
        It "Should skip existing styles when SkipExisting is specified" {
            # CrÃ©er un style avec le mÃªme ID que l'un des styles exportÃ©s
            $ExistingStyles = Get-Content -Path $TestFilePath | ConvertFrom-Json
            $ExistingStyleId = $ExistingStyles.Styles[0].Id
            
            $ExistingStyle = [ExcelLineStyle]::new()
            $ExistingStyle.Id = $ExistingStyleId
            $ExistingStyle.Name = "Style existant"
            $ExistingStyle.LineConfig = [ExcelLineStyleConfig]::new()
            
            $Registry = Get-ExcelStyleRegistry
            $Registry.Add($ExistingStyle) | Out-Null
            
            # Importer les styles en ignorant les existants
            $ImportedCount = Import-ExcelStyles -Path $TestFilePath -SkipExisting
            
            # VÃ©rifier que seul un style a Ã©tÃ© importÃ©
            $ImportedCount | Should -Be 1
            
            # VÃ©rifier que le style existant n'a pas Ã©tÃ© remplacÃ©
            $Style = $Registry.GetById($ExistingStyleId)
            $Style.Name | Should -Be "Style existant"
        }
        
        It "Should filter imported styles by category" {
            # Exporter des styles avec diffÃ©rentes catÃ©gories
            Reset-ExcelStyleRegistry
            Initialize-ExcelPredefinedStyles -Force
            
            $CategoryStyle1 = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style catÃ©gorie 1" -Category "CatÃ©gorie 1"
            $CategoryStyle2 = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style catÃ©gorie 2" -Category "CatÃ©gorie 2"
            
            Export-ExcelStyles -Path $TestFilePath -Force
            
            # RÃ©initialiser le registre
            Reset-ExcelStyleRegistry
            Initialize-ExcelPredefinedStyles -Force
            
            # Importer uniquement les styles de la catÃ©gorie 1
            $ImportedCount = Import-ExcelStyles -Path $TestFilePath -Category "CatÃ©gorie 1"
            
            # VÃ©rifier que seul un style a Ã©tÃ© importÃ©
            $ImportedCount | Should -Be 1
            
            # VÃ©rifier que seul le style de la catÃ©gorie 1 est dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Styles = $Registry.Search(@{ IsBuiltIn = $false })
            $Styles.Count | Should -Be 1
            $Styles[0].Name | Should -Be "Style catÃ©gorie 1"
        }
        
        It "Should handle invalid file path" {
            # Essayer d'importer depuis un fichier inexistant
            $ImportedCount = Import-ExcelStyles -Path "C:\NonExistentFile.json"
            
            # VÃ©rifier que l'importation a Ã©chouÃ©
            $ImportedCount | Should -Be 0
        }
    }
    
    Context "Save-ExcelStylesConfiguration and Import-ExcelStylesConfiguration functions" {
        BeforeEach {
            # RÃ©initialiser le registre avant chaque test
            Reset-ExcelStyleRegistry
            
            # Initialiser les styles prÃ©dÃ©finis
            Initialize-ExcelPredefinedStyles -Force
            
            # CrÃ©er quelques styles personnalisÃ©s pour les tests
            $CustomStyle1 = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style config 1" -Color "#00FF00" -Width 3
            $CustomStyle2 = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style config 2" -Color "#FF00FF" -Width 2
        }
        
        It "Should save and load configuration" {
            # Sauvegarder la configuration
            $SavedCount = Save-ExcelStylesConfiguration -Path $TestFilePath -Force
            
            # VÃ©rifier que des styles ont Ã©tÃ© sauvegardÃ©s
            $SavedCount | Should -Be 2
            
            # RÃ©initialiser le registre
            Reset-ExcelStyleRegistry
            Initialize-ExcelPredefinedStyles -Force
            
            # Charger la configuration
            $LoadedCount = Import-ExcelStylesConfiguration -Path $TestFilePath
            
            # VÃ©rifier que des styles ont Ã©tÃ© chargÃ©s
            $LoadedCount | Should -Be 2
            
            # VÃ©rifier que les styles sont dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Styles = $Registry.Search(@{ IsBuiltIn = $false })
            $Styles.Count | Should -Be 2
            
            # VÃ©rifier les noms des styles chargÃ©s
            $StyleNames = $Styles | ForEach-Object { $_.Name }
            $StyleNames | Should -Contain "Style config 1"
            $StyleNames | Should -Contain "Style config 2"
        }
        
        It "Should use default configuration path when none is specified" {
            # Sauvegarder la configuration dans le chemin par dÃ©faut
            $ConfigDir = Join-Path -Path $env:APPDATA -ChildPath "ExcelStyles"
            $DefaultPath = Join-Path -Path $ConfigDir -ChildPath "UserStyles.json"
            
            # Supprimer le fichier s'il existe dÃ©jÃ 
            if (Test-Path -Path $DefaultPath) {
                Remove-Item -Path $DefaultPath -Force
            }
            
            # Sauvegarder la configuration
            $SavedCount = Save-ExcelStylesConfiguration -Force
            
            # VÃ©rifier que des styles ont Ã©tÃ© sauvegardÃ©s
            $SavedCount | Should -Be 2
            
            # VÃ©rifier que le fichier a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $DefaultPath | Should -Be $true
            
            # RÃ©initialiser le registre
            Reset-ExcelStyleRegistry
            Initialize-ExcelPredefinedStyles -Force
            
            # Charger la configuration
            $LoadedCount = Import-ExcelStylesConfiguration
            
            # VÃ©rifier que des styles ont Ã©tÃ© chargÃ©s
            $LoadedCount | Should -Be 2
            
            # Nettoyer
            if (Test-Path -Path $DefaultPath) {
                Remove-Item -Path $DefaultPath -Force
            }
        }
    }
}

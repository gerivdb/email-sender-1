# Tests pour les fonctionnalités de persistance des styles Excel

# Importer Pester
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Importer les modules à tester
$StyleRegistryPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_style_registry.ps1"
$PredefinedStylesPath = Join-Path -Path $PSScriptRoot -ChildPath "excel_predefined_styles.ps1"
. $StyleRegistryPath
. $PredefinedStylesPath

Describe "Excel Style Persistence" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $TestDir = Join-Path -Path $env:TEMP -ChildPath "ExcelStyleTests"
        if (-not (Test-Path -Path $TestDir)) {
            New-Item -Path $TestDir -ItemType Directory -Force | Out-Null
        }
        
        # Chemin du fichier de test
        $TestFilePath = Join-Path -Path $TestDir -ChildPath "TestStyles.json"
        
        # Réinitialiser le registre avant chaque test
        Reset-ExcelStyleRegistry
        
        # Initialiser les styles prédéfinis
        Initialize-ExcelPredefinedStyles -Force
        
        # Créer quelques styles personnalisés pour les tests
        $CustomStyle1 = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style personnalisé 1" -Color "#00FF00" -Width 3
        $CustomStyle2 = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style personnalisé 2" -Color "#FF00FF" -Width 2
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $TestFilePath) {
            Remove-Item -Path $TestFilePath -Force
        }
    }
    
    Context "Export-ExcelStyles function" {
        It "Should export custom styles to a file" {
            # Exporter les styles personnalisés
            $ExportedCount = Export-ExcelStyles -Path $TestFilePath
            
            # Vérifier que des styles ont été exportés
            $ExportedCount | Should -BeGreaterThan 0
            
            # Vérifier que le fichier a été créé
            Test-Path -Path $TestFilePath | Should -Be $true
            
            # Vérifier le contenu du fichier
            $Content = Get-Content -Path $TestFilePath -Raw
            $Content | Should -Not -BeNullOrEmpty
            
            # Vérifier que le fichier contient les styles personnalisés
            $Content | Should -Match "Style personnalisé 1"
            $Content | Should -Match "Style personnalisé 2"
        }
        
        It "Should export built-in styles when IncludeBuiltIn is specified" {
            # Exporter tous les styles, y compris les styles prédéfinis
            $ExportedCount = Export-ExcelStyles -Path $TestFilePath -IncludeBuiltIn -Force
            
            # Vérifier que des styles ont été exportés
            $ExportedCount | Should -BeGreaterThan 2  # Plus que juste les styles personnalisés
            
            # Vérifier le contenu du fichier
            $Content = Get-Content -Path $TestFilePath -Raw
            $Content | Should -Match "Ligne rouge"
            $Content | Should -Match "Ligne bleue"
        }
        
        It "Should filter styles by category" {
            # Créer un style avec une catégorie spécifique
            $CategoryStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style catégorisé" -Category "Catégorie de test"
            
            # Exporter les styles de cette catégorie
            $ExportedCount = Export-ExcelStyles -Path $TestFilePath -Category "Catégorie de test" -Force
            
            # Vérifier que seul le style de la catégorie a été exporté
            $ExportedCount | Should -Be 1
            
            # Vérifier le contenu du fichier
            $Content = Get-Content -Path $TestFilePath -Raw
            $Content | Should -Match "Style catégorisé"
            $Content | Should -Not -Match "Style personnalisé 1"
        }
        
        It "Should filter styles by tag" {
            # Créer un style avec un tag spécifique
            $TaggedStyle = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style tagué" -Tags @("Tag de test")
            
            # Exporter les styles avec ce tag
            $ExportedCount = Export-ExcelStyles -Path $TestFilePath -Tag "Tag de test" -Force
            
            # Vérifier que seul le style avec le tag a été exporté
            $ExportedCount | Should -Be 1
            
            # Vérifier le contenu du fichier
            $Content = Get-Content -Path $TestFilePath -Raw
            $Content | Should -Match "Style tagué"
            $Content | Should -Not -Match "Style personnalisé 1"
        }
        
        It "Should not overwrite existing file without Force" {
            # Créer un fichier de test
            Set-Content -Path $TestFilePath -Value "Test content"
            
            # Essayer d'exporter sans Force
            $ExportedCount = Export-ExcelStyles -Path $TestFilePath
            
            # Vérifier que l'exportation a échoué
            $ExportedCount | Should -Be 0
            
            # Vérifier que le contenu du fichier n'a pas été modifié
            $Content = Get-Content -Path $TestFilePath -Raw
            $Content | Should -Be "Test content"
        }
    }
    
    Context "Import-ExcelStyles function" {
        BeforeEach {
            # Réinitialiser le registre avant chaque test
            Reset-ExcelStyleRegistry
            
            # Initialiser les styles prédéfinis
            Initialize-ExcelPredefinedStyles -Force
            
            # Créer quelques styles personnalisés pour les tests
            $CustomStyle1 = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style personnalisé 1" -Color "#00FF00" -Width 3
            $CustomStyle2 = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style personnalisé 2" -Color "#FF00FF" -Width 2
            
            # Exporter les styles
            Export-ExcelStyles -Path $TestFilePath -Force
            
            # Réinitialiser le registre pour les tests d'importation
            Reset-ExcelStyleRegistry
            Initialize-ExcelPredefinedStyles -Force
        }
        
        It "Should import styles from a file" {
            # Importer les styles
            $ImportedCount = Import-ExcelStyles -Path $TestFilePath
            
            # Vérifier que des styles ont été importés
            $ImportedCount | Should -Be 2
            
            # Vérifier que les styles sont dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Styles = $Registry.Search(@{ IsBuiltIn = $false })
            $Styles.Count | Should -Be 2
            
            # Vérifier les propriétés des styles importés
            $Style1 = $Registry.Search(@{ Name = "Style personnalisé 1" })
            $Style1.Count | Should -Be 1
            $Style1[0].LineConfig.Color | Should -Be "#00FF00"
            $Style1[0].LineConfig.Width | Should -Be 3
            
            $Style2 = $Registry.Search(@{ Name = "Style personnalisé 2" })
            $Style2.Count | Should -Be 1
            $Style2[0].LineConfig.Color | Should -Be "#FF00FF"
            $Style2[0].LineConfig.Width | Should -Be 2
        }
        
        It "Should skip existing styles when SkipExisting is specified" {
            # Créer un style avec le même ID que l'un des styles exportés
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
            
            # Vérifier que seul un style a été importé
            $ImportedCount | Should -Be 1
            
            # Vérifier que le style existant n'a pas été remplacé
            $Style = $Registry.GetById($ExistingStyleId)
            $Style.Name | Should -Be "Style existant"
        }
        
        It "Should filter imported styles by category" {
            # Exporter des styles avec différentes catégories
            Reset-ExcelStyleRegistry
            Initialize-ExcelPredefinedStyles -Force
            
            $CategoryStyle1 = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style catégorie 1" -Category "Catégorie 1"
            $CategoryStyle2 = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style catégorie 2" -Category "Catégorie 2"
            
            Export-ExcelStyles -Path $TestFilePath -Force
            
            # Réinitialiser le registre
            Reset-ExcelStyleRegistry
            Initialize-ExcelPredefinedStyles -Force
            
            # Importer uniquement les styles de la catégorie 1
            $ImportedCount = Import-ExcelStyles -Path $TestFilePath -Category "Catégorie 1"
            
            # Vérifier que seul un style a été importé
            $ImportedCount | Should -Be 1
            
            # Vérifier que seul le style de la catégorie 1 est dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Styles = $Registry.Search(@{ IsBuiltIn = $false })
            $Styles.Count | Should -Be 1
            $Styles[0].Name | Should -Be "Style catégorie 1"
        }
        
        It "Should handle invalid file path" {
            # Essayer d'importer depuis un fichier inexistant
            $ImportedCount = Import-ExcelStyles -Path "C:\NonExistentFile.json"
            
            # Vérifier que l'importation a échoué
            $ImportedCount | Should -Be 0
        }
    }
    
    Context "Save-ExcelStylesConfiguration and Import-ExcelStylesConfiguration functions" {
        BeforeEach {
            # Réinitialiser le registre avant chaque test
            Reset-ExcelStyleRegistry
            
            # Initialiser les styles prédéfinis
            Initialize-ExcelPredefinedStyles -Force
            
            # Créer quelques styles personnalisés pour les tests
            $CustomStyle1 = Copy-ExcelLineStyleWithModifications -Name "Ligne rouge" -NewName "Style config 1" -Color "#00FF00" -Width 3
            $CustomStyle2 = Copy-ExcelLineStyleWithModifications -Name "Ligne bleue" -NewName "Style config 2" -Color "#FF00FF" -Width 2
        }
        
        It "Should save and load configuration" {
            # Sauvegarder la configuration
            $SavedCount = Save-ExcelStylesConfiguration -Path $TestFilePath -Force
            
            # Vérifier que des styles ont été sauvegardés
            $SavedCount | Should -Be 2
            
            # Réinitialiser le registre
            Reset-ExcelStyleRegistry
            Initialize-ExcelPredefinedStyles -Force
            
            # Charger la configuration
            $LoadedCount = Import-ExcelStylesConfiguration -Path $TestFilePath
            
            # Vérifier que des styles ont été chargés
            $LoadedCount | Should -Be 2
            
            # Vérifier que les styles sont dans le registre
            $Registry = Get-ExcelStyleRegistry
            $Styles = $Registry.Search(@{ IsBuiltIn = $false })
            $Styles.Count | Should -Be 2
            
            # Vérifier les noms des styles chargés
            $StyleNames = $Styles | ForEach-Object { $_.Name }
            $StyleNames | Should -Contain "Style config 1"
            $StyleNames | Should -Contain "Style config 2"
        }
        
        It "Should use default configuration path when none is specified" {
            # Sauvegarder la configuration dans le chemin par défaut
            $ConfigDir = Join-Path -Path $env:APPDATA -ChildPath "ExcelStyles"
            $DefaultPath = Join-Path -Path $ConfigDir -ChildPath "UserStyles.json"
            
            # Supprimer le fichier s'il existe déjà
            if (Test-Path -Path $DefaultPath) {
                Remove-Item -Path $DefaultPath -Force
            }
            
            # Sauvegarder la configuration
            $SavedCount = Save-ExcelStylesConfiguration -Force
            
            # Vérifier que des styles ont été sauvegardés
            $SavedCount | Should -Be 2
            
            # Vérifier que le fichier a été créé
            Test-Path -Path $DefaultPath | Should -Be $true
            
            # Réinitialiser le registre
            Reset-ExcelStyleRegistry
            Initialize-ExcelPredefinedStyles -Force
            
            # Charger la configuration
            $LoadedCount = Import-ExcelStylesConfiguration
            
            # Vérifier que des styles ont été chargés
            $LoadedCount | Should -Be 2
            
            # Nettoyer
            if (Test-Path -Path $DefaultPath) {
                Remove-Item -Path $DefaultPath -Force
            }
        }
    }
}

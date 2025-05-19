# Tests unitaires pour la fonction Write-ConversionLog
#Requires -Version 5.1
#Requires -Modules @{ ModuleName='Pester'; ModuleVersion='5.0.0' }

BeforeAll {
    # Chemin du module à tester
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\UnifiedParallel.psm1"

    # Importer le module
    Import-Module $modulePath -Force
    
    # Créer un dossier temporaire pour les logs
    $script:tempFolder = Join-Path -Path $env:TEMP -ChildPath "UnifiedParallelTests_$(Get-Random)"
    New-Item -Path $script:tempFolder -ItemType Directory -Force | Out-Null
    
    # Définir un chemin de log temporaire
    $script:tempLogPath = Join-Path -Path $script:tempFolder -ChildPath "ConversionLog.log"
    
    # Sauvegarder la configuration actuelle
    $script:originalConfig = Get-ModuleConfig
    
    # Créer une configuration de test
    $testConfig = $script:originalConfig.Clone()
    $testConfig.Logging = @{
        EnableFileLogging = $true
        EnableConsoleLogging = $false
        LogFilePath = $script:tempLogPath
        LogLevel = 'Info'
    }
    
    # Appliquer la configuration de test
    Set-ModuleConfig -Config $testConfig
}

AfterAll {
    # Restaurer la configuration d'origine
    Set-ModuleConfig -Config $script:originalConfig
    
    # Supprimer le dossier temporaire
    if (Test-Path -Path $script:tempFolder) {
        Remove-Item -Path $script:tempFolder -Recurse -Force
    }
}

Describe "Write-ConversionLog" {
    Context "Journalisation dans un fichier" {
        BeforeEach {
            # Supprimer le fichier de log s'il existe
            if (Test-Path -Path $script:tempLogPath) {
                Remove-Item -Path $script:tempLogPath -Force
            }
        }
        
        It "Crée un fichier de log avec le message spécifié" {
            # Arrange
            $message = "Test de journalisation"
            
            # Act
            Write-ConversionLog -Message $message -LogToFile $true -LogFilePath $script:tempLogPath
            
            # Assert
            Test-Path -Path $script:tempLogPath | Should -Be $true
            $logContent = Get-Content -Path $script:tempLogPath -Raw
            $logContent | Should -Match $message
        }
        
        It "Ajoute les informations sur l'énumération" {
            # Arrange
            $message = "Test avec énumération"
            $enumType = [System.Threading.ApartmentState]
            
            # Act
            Write-ConversionLog -Message $message -EnumType $enumType -LogToFile $true -LogFilePath $script:tempLogPath
            
            # Assert
            Test-Path -Path $script:tempLogPath | Should -Be $true
            $logContent = Get-Content -Path $script:tempLogPath -Raw
            $logContent | Should -Match $message
            $logContent | Should -Match "System.Threading.ApartmentState"
        }
        
        It "Ajoute les informations sur la valeur" {
            # Arrange
            $message = "Test avec valeur"
            $value = "TestValue"
            
            # Act
            Write-ConversionLog -Message $message -Value $value -LogToFile $true -LogFilePath $script:tempLogPath
            
            # Assert
            Test-Path -Path $script:tempLogPath | Should -Be $true
            $logContent = Get-Content -Path $script:tempLogPath -Raw
            $logContent | Should -Match $message
            $logContent | Should -Match $value
        }
        
        It "Ajoute les informations sur l'exception" {
            # Arrange
            $message = "Test avec exception"
            $exception = [System.ArgumentException]::new("Message d'erreur de test")
            
            # Act
            Write-ConversionLog -Message $message -Exception $exception -LogToFile $true -LogFilePath $script:tempLogPath
            
            # Assert
            Test-Path -Path $script:tempLogPath | Should -Be $true
            $logContent = Get-Content -Path $script:tempLogPath -Raw
            $logContent | Should -Match $message
            $logContent | Should -Match "ArgumentException"
            $logContent | Should -Match "Message d'erreur de test"
        }
        
        It "Utilise le niveau de journalisation spécifié" {
            # Arrange
            $message = "Test avec niveau Error"
            $level = "Error"
            
            # Act
            Write-ConversionLog -Message $message -Level $level -LogToFile $true -LogFilePath $script:tempLogPath
            
            # Assert
            Test-Path -Path $script:tempLogPath | Should -Be $true
            $logContent = Get-Content -Path $script:tempLogPath -Raw
            $logContent | Should -Match $message
            $logContent | Should -Match "\[$level\]"
        }
        
        It "Crée le dossier parent si nécessaire" {
            # Arrange
            $message = "Test avec création de dossier"
            $nestedLogPath = Join-Path -Path $script:tempFolder -ChildPath "Nested\DeepNested\ConversionLog.log"
            
            # Act
            Write-ConversionLog -Message $message -LogToFile $true -LogFilePath $nestedLogPath
            
            # Assert
            Test-Path -Path $nestedLogPath | Should -Be $true
            $logContent = Get-Content -Path $nestedLogPath -Raw
            $logContent | Should -Match $message
        }
    }
    
    Context "Utilisation de la configuration du module" {
        BeforeEach {
            # Supprimer le fichier de log s'il existe
            if (Test-Path -Path $script:tempLogPath) {
                Remove-Item -Path $script:tempLogPath -Force
            }
            
            # Créer une configuration de test
            $testConfig = $script:originalConfig.Clone()
            $testConfig.Logging = @{
                EnableFileLogging = $true
                EnableConsoleLogging = $false
                LogFilePath = $script:tempLogPath
                LogLevel = 'Info'
            }
            
            # Appliquer la configuration de test
            Set-ModuleConfig -Config $testConfig
        }
        
        It "Utilise la configuration du module si les paramètres ne sont pas spécifiés" {
            # Arrange
            $message = "Test avec configuration du module"
            
            # Act
            Write-ConversionLog -Message $message
            
            # Assert
            Test-Path -Path $script:tempLogPath | Should -Be $true
            $logContent = Get-Content -Path $script:tempLogPath -Raw
            $logContent | Should -Match $message
        }
    }
}

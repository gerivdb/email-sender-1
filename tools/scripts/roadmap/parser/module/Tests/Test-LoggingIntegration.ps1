<#
.SYNOPSIS
    Tests d'intÃ©gration pour les fonctions de journalisation.

.DESCRIPTION
    Ce script contient des tests d'intÃ©gration pour les fonctions de journalisation
    du module RoadmapParser, y compris la rotation des journaux et la verbositÃ© configurable.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-16
#>

# Importer le module Pester s'il n'est pas dÃ©jÃ  chargÃ©
if (-not (Get-Module -Name Pester)) {
    Import-Module Pester -ErrorAction Stop
}

# Chemin vers le module Ã  tester
$modulePath = (Split-Path -Parent $PSScriptRoot)
$loggingFunctionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\LoggingFunctions.ps1"

# Importer les fonctions Ã  tester
. $loggingFunctionsPath

Describe "Logging Integration" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "logs"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un fichier de journal de test
        $testLogFile = Join-Path -Path $testDir -ChildPath "integration_test.log"
        
        # Sauvegarder les configurations actuelles
        $originalLoggingConfig = $script:LoggingConfig
        $originalLogRotationConfig = Get-LogRotationConfig
        $originalVerbosityConfig = Get-VerbosityConfig
        $originalLoggingLevel = Get-LoggingLevel
    }
    
    AfterAll {
        # Restaurer les configurations originales
        $script:LoggingConfig = $originalLoggingConfig
        $script:LogRotationConfig = $originalLogRotationConfig
        $script:VerbosityConfig = $originalVerbosityConfig
        Set-LoggingLevel -Level $originalLoggingLevel
    }
    
    Context "Log Rotation Integration" {
        BeforeEach {
            # Configurer pour le test
            $script:LoggingConfig.EnableRotation = $true
            $script:LoggingConfig.EnableVerbosity = $false
            
            # Configurer la rotation des journaux
            Set-LogRotationConfig -SizeBasedEnabled $true -MaxSizeKB 1 -BackupCount 3
            
            # CrÃ©er un fichier de journal de test avec une taille connue
            Set-Content -Path $testLogFile -Value ("A" * 1024) -Force
        }
        
        It "Should rotate log file when using Write-Log" {
            # VÃ©rifier que le fichier existe
            Test-Path -Path $testLogFile | Should -Be $true
            
            # Journaliser un message
            Write-Log -Message "Test message" -Level "INFO" -LogFile $testLogFile
            
            # VÃ©rifier que le fichier de sauvegarde a Ã©tÃ© crÃ©Ã©
            $backupFiles = Get-ChildItem -Path $testDir -Filter "integration_test.log.*"
            $backupFiles.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que le message a Ã©tÃ© journalisÃ© dans le fichier original
            $content = Get-Content -Path $testLogFile -Raw
            $content | Should -Match "Test message"
        }
        
        It "Should not rotate log file when NoRotation is specified" {
            # VÃ©rifier que le fichier existe
            Test-Path -Path $testLogFile | Should -Be $true
            
            # Journaliser un message sans rotation
            Write-Log -Message "No rotation message" -Level "INFO" -LogFile $testLogFile -NoRotation
            
            # VÃ©rifier que le fichier de sauvegarde n'a pas Ã©tÃ© crÃ©Ã©
            $backupFiles = Get-ChildItem -Path $testDir -Filter "integration_test.log.*"
            $initialCount = $backupFiles.Count
            
            # Journaliser un autre message sans rotation
            Write-Log -Message "Another no rotation message" -Level "INFO" -LogFile $testLogFile -NoRotation
            
            # VÃ©rifier que le nombre de fichiers de sauvegarde n'a pas changÃ©
            $backupFiles = Get-ChildItem -Path $testDir -Filter "integration_test.log.*"
            $backupFiles.Count | Should -Be $initialCount
        }
    }
    
    Context "Verbosity Integration" {
        BeforeEach {
            # Configurer pour le test
            $script:LoggingConfig.EnableRotation = $false
            $script:LoggingConfig.EnableVerbosity = $true
            
            # Configurer la verbositÃ©
            Set-VerbosityLevel -Level "Detailed"
            Set-VerbosityCategories -Level "Detailed" -Categories @("Error", "Warning", "Info")
            
            # CrÃ©er un fichier de journal de test
            if (Test-Path -Path $testLogFile) {
                Remove-Item -Path $testLogFile -Force
            }
        }
        
        It "Should use verbosity formatting when using Write-Log" {
            # Journaliser un message
            Write-Log -Message "Test message" -Level "INFO" -LogFile $testLogFile -Category "TestCategory"
            
            # VÃ©rifier que le message a Ã©tÃ© journalisÃ© avec le format de verbositÃ©
            $content = Get-Content -Path $testLogFile -Raw
            $content | Should -Match "\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\].*\[TestCategory\].*Test message"
        }
        
        It "Should not log messages for disabled categories" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Minimal"
            Set-VerbosityCategories -Level "Minimal" -Categories @("Error")
            
            # Journaliser un message dans une catÃ©gorie dÃ©sactivÃ©e
            Write-Log -Message "Test message" -Level "INFO" -LogFile $testLogFile
            
            # VÃ©rifier que le message n'a pas Ã©tÃ© journalisÃ©
            if (Test-Path -Path $testLogFile) {
                $content = Get-Content -Path $testLogFile -Raw
                if ($content) {
                    $content | Should -Not -Match "Test message"
                }
                else {
                    $true | Should -Be $true
                }
            }
            else {
                # Le fichier n'a pas Ã©tÃ© crÃ©Ã©, ce qui est aussi valide
                $true | Should -Be $true
            }
        }
    }
    
    Context "Combined Features" {
        BeforeEach {
            # Configurer pour le test
            $script:LoggingConfig.EnableRotation = $true
            $script:LoggingConfig.EnableVerbosity = $true
            
            # Configurer la rotation des journaux
            Set-LogRotationConfig -SizeBasedEnabled $true -MaxSizeKB 1 -BackupCount 3
            
            # Configurer la verbositÃ©
            Set-VerbosityLevel -Level "Detailed"
            Set-VerbosityCategories -Level "Detailed" -Categories @("Error", "Warning", "Info")
            
            # CrÃ©er un fichier de journal de test avec une taille connue
            Set-Content -Path $testLogFile -Value ("A" * 1024) -Force
        }
        
        It "Should use both rotation and verbosity when using Write-Log" {
            # VÃ©rifier que le fichier existe
            Test-Path -Path $testLogFile | Should -Be $true
            
            # Journaliser un message
            Write-Log -Message "Combined features message" -Level "INFO" -LogFile $testLogFile -Category "TestCategory"
            
            # VÃ©rifier que le fichier de sauvegarde a Ã©tÃ© crÃ©Ã©
            $backupFiles = Get-ChildItem -Path $testDir -Filter "integration_test.log.*"
            $backupFiles.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que le message a Ã©tÃ© journalisÃ© avec le format de verbositÃ©
            $content = Get-Content -Path $testLogFile -Raw
            $content | Should -Match "\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\].*\[TestCategory\].*Combined features message"
        }
    }
    
    Context "Preset Integration" {
        BeforeEach {
            # Configurer pour le test
            $script:LoggingConfig.EnableRotation = $true
            $script:LoggingConfig.EnableVerbosity = $true
            
            # CrÃ©er un fichier de journal de test
            if (Test-Path -Path $testLogFile) {
                Remove-Item -Path $testLogFile -Force
            }
        }
        
        It "Should apply 'Production' preset correctly" {
            # Appliquer le prÃ©rÃ©glage
            Set-VerbosityPreset -PresetName "Production"
            
            # Journaliser des messages de diffÃ©rents niveaux
            Write-Log -Message "Error message" -Level "ERROR" -LogFile $testLogFile
            Write-Log -Message "Warning message" -Level "WARNING" -LogFile $testLogFile
            Write-Log -Message "Info message" -Level "INFO" -LogFile $testLogFile
            Write-Log -Message "Verbose message" -Level "VERBOSE" -LogFile $testLogFile
            
            # VÃ©rifier que seuls les messages des niveaux activÃ©s ont Ã©tÃ© journalisÃ©s
            $content = Get-Content -Path $testLogFile -Raw
            $content | Should -Match "Error message"
            $content | Should -Match "Warning message"
            $content | Should -Not -Match "Info message"
            $content | Should -Not -Match "Verbose message"
        }
        
        It "Should apply 'Development' preset correctly" {
            # Appliquer le prÃ©rÃ©glage
            Set-VerbosityPreset -PresetName "Development"
            
            # Journaliser des messages de diffÃ©rents niveaux
            Write-Log -Message "Error message" -Level "ERROR" -LogFile $testLogFile
            Write-Log -Message "Warning message" -Level "WARNING" -LogFile $testLogFile
            Write-Log -Message "Info message" -Level "INFO" -LogFile $testLogFile
            Write-Log -Message "Verbose message" -Level "VERBOSE" -LogFile $testLogFile
            Write-Log -Message "Debug message" -Level "DEBUG" -LogFile $testLogFile
            
            # VÃ©rifier que seuls les messages des niveaux activÃ©s ont Ã©tÃ© journalisÃ©s
            $content = Get-Content -Path $testLogFile -Raw
            $content | Should -Match "Error message"
            $content | Should -Match "Warning message"
            $content | Should -Match "Info message"
            $content | Should -Match "Verbose message"
            $content | Should -Not -Match "Debug message"
        }
    }
}

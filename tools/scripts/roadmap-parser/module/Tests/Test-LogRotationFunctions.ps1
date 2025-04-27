<#
.SYNOPSIS
    Tests unitaires pour les fonctions de rotation des journaux.

.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions de rotation des journaux
    du module RoadmapParser.

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
$functionsPath = Join-Path -Path $modulePath -ChildPath "Functions\Common\LogRotationFunctions.ps1"

# Importer les fonctions Ã  tester
. $functionsPath

Describe "Log Rotation Functions" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "logs"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un fichier de journal de test
        $testLogFile = Join-Path -Path $testDir -ChildPath "test.log"
        Set-Content -Path $testLogFile -Value "Test log content" -Force
        
        # Sauvegarder la configuration actuelle
        $originalConfig = Get-LogRotationConfig
    }
    
    AfterAll {
        # Restaurer la configuration originale
        $script:LogRotationConfig = $originalConfig
    }
    
    Context "Configuration Functions" {
        It "Should get the default log rotation configuration" {
            $config = Get-LogRotationConfig
            $config | Should -Not -BeNullOrEmpty
            $config.SizeBasedRotation | Should -Not -BeNullOrEmpty
            $config.DateBasedRotation | Should -Not -BeNullOrEmpty
            $config.Compression | Should -Not -BeNullOrEmpty
            $config.AutoPurge | Should -Not -BeNullOrEmpty
        }
        
        It "Should set the log rotation configuration" {
            # Modifier la configuration
            Set-LogRotationConfig -SizeBasedEnabled $true -MaxSizeKB 2048 -BackupCount 10
            
            # VÃ©rifier que la configuration a Ã©tÃ© mise Ã  jour
            $config = Get-LogRotationConfig
            $config.SizeBasedRotation.Enabled | Should -Be $true
            $config.SizeBasedRotation.MaxSizeKB | Should -Be 2048
            $config.SizeBasedRotation.BackupCount | Should -Be 10
        }
    }
    
    Context "Size-Based Rotation" {
        BeforeEach {
            # RÃ©initialiser la configuration pour les tests
            Set-LogRotationConfig -SizeBasedEnabled $true -MaxSizeKB 1 -BackupCount 3
            
            # CrÃ©er un fichier de journal de test avec une taille connue
            $testLogFile = Join-Path -Path $testDir -ChildPath "size_test.log"
            Set-Content -Path $testLogFile -Value ("A" * 1024) -Force
        }
        
        It "Should detect when a log file needs rotation by size" {
            $result = Test-LogRotationBySize -LogFile $testLogFile
            $result | Should -Be $true
        }
        
        It "Should not detect rotation need for small files" {
            # CrÃ©er un petit fichier
            $smallLogFile = Join-Path -Path $testDir -ChildPath "small_test.log"
            Set-Content -Path $smallLogFile -Value "Small file" -Force
            
            # Configurer une taille maximale plus grande
            Set-LogRotationConfig -MaxSizeKB 10
            
            $result = Test-LogRotationBySize -LogFile $smallLogFile
            $result | Should -Be $false
        }
        
        It "Should rotate a log file by size" {
            # VÃ©rifier que le fichier existe
            Test-Path -Path $testLogFile | Should -Be $true
            
            # Effectuer la rotation
            Invoke-LogRotationBySize -LogFile $testLogFile
            
            # VÃ©rifier que le fichier de sauvegarde a Ã©tÃ© crÃ©Ã©
            $backupFile = "$testLogFile.1"
            Test-Path -Path $backupFile | Should -Be $true
            
            # VÃ©rifier que le fichier original a Ã©tÃ© vidÃ©
            $content = Get-Content -Path $testLogFile -Raw
            $content | Should -BeNullOrEmpty
        }
    }
    
    Context "Date-Based Rotation" {
        BeforeEach {
            # RÃ©initialiser la configuration pour les tests
            Set-LogRotationConfig -DateBasedEnabled $true -Interval "Daily" -RetentionDays 7
            
            # CrÃ©er un fichier de journal de test avec une date modifiÃ©e
            $testLogFile = Join-Path -Path $testDir -ChildPath "date_test.log"
            Set-Content -Path $testLogFile -Value "Test log content" -Force
            
            # Modifier la date du fichier pour qu'il soit considÃ©rÃ© comme ancien
            $yesterday = (Get-Date).AddDays(-1)
            (Get-Item -Path $testLogFile).LastWriteTime = $yesterday
        }
        
        It "Should detect when a log file needs rotation by date" {
            $result = Test-LogRotationByDate -LogFile $testLogFile
            $result | Should -Be $true
        }
        
        It "Should not detect rotation need for recent files" {
            # CrÃ©er un fichier rÃ©cent
            $recentLogFile = Join-Path -Path $testDir -ChildPath "recent_test.log"
            Set-Content -Path $recentLogFile -Value "Recent file" -Force
            
            $result = Test-LogRotationByDate -LogFile $recentLogFile
            $result | Should -Be $false
        }
        
        It "Should rotate a log file by date" {
            # VÃ©rifier que le fichier existe
            Test-Path -Path $testLogFile | Should -Be $true
            
            # Effectuer la rotation
            Invoke-LogRotationByDate -LogFile $testLogFile
            
            # VÃ©rifier que le fichier de sauvegarde a Ã©tÃ© crÃ©Ã© (avec un horodatage)
            $backupFiles = Get-ChildItem -Path $testDir -Filter "date_test.log.*"
            $backupFiles.Count | Should -BeGreaterThan 0
            
            # VÃ©rifier que le fichier original a Ã©tÃ© vidÃ©
            $content = Get-Content -Path $testLogFile -Raw
            $content | Should -BeNullOrEmpty
        }
    }
    
    Context "Log Compression" {
        BeforeEach {
            # RÃ©initialiser la configuration pour les tests
            Set-LogRotationConfig -CompressionEnabled $true -CompressionFormat "Zip" -CompressAfterDays 0
            
            # CrÃ©er un fichier de journal de test
            $testLogFile = Join-Path -Path $testDir -ChildPath "compress_test.log"
            Set-Content -Path $testLogFile -Value ("Test log content " * 100) -Force
        }
        
        It "Should compress a log file" {
            # VÃ©rifier que le fichier existe
            Test-Path -Path $testLogFile | Should -Be $true
            
            # Compresser le fichier
            Compress-LogFile -LogFile $testLogFile
            
            # VÃ©rifier que le fichier compressÃ© a Ã©tÃ© crÃ©Ã©
            $compressedFile = "$testLogFile.zip"
            Test-Path -Path $compressedFile | Should -Be $true
            
            # VÃ©rifier que le fichier original a Ã©tÃ© supprimÃ©
            Test-Path -Path $testLogFile | Should -Be $false
        }
    }
    
    Context "Auto Purge" {
        BeforeEach {
            # RÃ©initialiser la configuration pour les tests
            Set-LogRotationConfig -AutoPurgeEnabled $true -MaxAge 1 -MaxCount 5
            
            # CrÃ©er plusieurs fichiers de journal de test
            $testLogDir = Join-Path -Path $testDir -ChildPath "purge"
            New-Item -Path $testLogDir -ItemType Directory -Force | Out-Null
            
            for ($i = 1; $i -le 10; $i++) {
                $testLogFile = Join-Path -Path $testLogDir -ChildPath "test$i.log"
                Set-Content -Path $testLogFile -Value "Test log content $i" -Force
                
                # Modifier la date des fichiers pour qu'ils soient considÃ©rÃ©s comme anciens
                if ($i -le 5) {
                    $oldDate = (Get-Date).AddDays(-2)
                    (Get-Item -Path $testLogFile).LastWriteTime = $oldDate
                }
            }
        }
        
        It "Should purge old log files based on age" {
            # VÃ©rifier que les fichiers existent
            $beforeFiles = Get-ChildItem -Path (Join-Path -Path $testDir -ChildPath "purge") -Filter "test*.log"
            $beforeFiles.Count | Should -Be 10
            
            # Effectuer la purge
            Invoke-LogAutoPurge -LogDirectory (Join-Path -Path $testDir -ChildPath "purge") -LogFilePattern "test*.log"
            
            # VÃ©rifier que les anciens fichiers ont Ã©tÃ© supprimÃ©s
            $afterFiles = Get-ChildItem -Path (Join-Path -Path $testDir -ChildPath "purge") -Filter "test*.log"
            $afterFiles.Count | Should -Be 5
        }
        
        It "Should purge log files based on count" {
            # RÃ©initialiser la configuration pour les tests
            Set-LogRotationConfig -AutoPurgeEnabled $true -MaxAge 30 -MaxCount 3
            
            # VÃ©rifier que les fichiers existent
            $beforeFiles = Get-ChildItem -Path (Join-Path -Path $testDir -ChildPath "purge") -Filter "test*.log"
            $beforeFiles.Count | Should -Be 5  # AprÃ¨s le test prÃ©cÃ©dent
            
            # Effectuer la purge
            Invoke-LogAutoPurge -LogDirectory (Join-Path -Path $testDir -ChildPath "purge") -LogFilePattern "test*.log"
            
            # VÃ©rifier que les fichiers excÃ©dentaires ont Ã©tÃ© supprimÃ©s
            $afterFiles = Get-ChildItem -Path (Join-Path -Path $testDir -ChildPath "purge") -Filter "test*.log"
            $afterFiles.Count | Should -Be 3
        }
    }
    
    Context "Complete Log Rotation" {
        BeforeEach {
            # RÃ©initialiser la configuration pour les tests
            Set-LogRotationConfig -SizeBasedEnabled $true -MaxSizeKB 1 -BackupCount 3 -DateBasedEnabled $true -Interval "Daily" -RetentionDays 7 -CompressionEnabled $true -CompressionFormat "Zip" -CompressAfterDays 0 -AutoPurgeEnabled $true -MaxAge 1 -MaxCount 5
            
            # CrÃ©er un fichier de journal de test
            $testLogFile = Join-Path -Path $testDir -ChildPath "complete_test.log"
            Set-Content -Path $testLogFile -Value ("A" * 1024) -Force
            
            # Modifier la date du fichier pour qu'il soit considÃ©rÃ© comme ancien
            $yesterday = (Get-Date).AddDays(-1)
            (Get-Item -Path $testLogFile).LastWriteTime = $yesterday
        }
        
        It "Should perform a complete log rotation" {
            # VÃ©rifier que le fichier existe
            Test-Path -Path $testLogFile | Should -Be $true
            
            # Effectuer la rotation complÃ¨te
            Invoke-LogRotation -LogFile $testLogFile
            
            # VÃ©rifier que le fichier original a Ã©tÃ© vidÃ©
            $content = Get-Content -Path $testLogFile -Raw
            $content | Should -BeNullOrEmpty
            
            # VÃ©rifier que des fichiers de sauvegarde ont Ã©tÃ© crÃ©Ã©s
            $backupFiles = Get-ChildItem -Path $testDir -Filter "complete_test.log.*"
            $backupFiles.Count | Should -BeGreaterThan 0
        }
    }
}

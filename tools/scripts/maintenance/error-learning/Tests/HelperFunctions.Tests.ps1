<#
.SYNOPSIS
    Tests unitaires pour les fonctions auxiliaires du systÃ¨me d'apprentissage des erreurs.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions auxiliaires du systÃ¨me d'apprentissage des erreurs.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# DÃ©finir les tests Pester
Describe "Tests des fonctions auxiliaires" {
    BeforeAll {
        # CrÃ©er un rÃ©pertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "HelperFunctionsTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        
        # CrÃ©er un fichier de log
        $script:logPath = Join-Path -Path $script:testRoot -ChildPath "test.log"
        Set-Content -Path $script:logPath -Value "Test log content"
        
        # CrÃ©er un fichier de configuration
        $script:configPath = Join-Path -Path $script:testRoot -ChildPath "config.json"
        $configContent = @"
{
    "LogPath": "$($script:logPath.Replace('\', '\\'))",
    "MaxLogSize": 1024,
    "ErrorCategories": [
        "Syntax",
        "Runtime",
        "Logic"
    ],
    "EnableVerboseLogging": true
}
"@
        Set-Content -Path $script:configPath -Value $configContent
        
        # DÃ©finir les fonctions auxiliaires
        function Get-ConfigValue {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [string]$ConfigPath,
                
                [Parameter(Mandatory = $true)]
                [string]$Key
            )
            
            try {
                $config = Get-Content -Path $ConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json
                if ($config.PSObject.Properties.Name -contains $Key) {
                    return $config.$Key
                }
                else {
                    Write-Warning "La clÃ© '$Key' n'existe pas dans le fichier de configuration."
                    return $null
                }
            }
            catch {
                Write-Error "Erreur lors de la lecture du fichier de configuration: $_"
                return $null
            }
        }
        
        function Write-LogMessage {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [string]$LogPath,
                
                [Parameter(Mandatory = $true)]
                [string]$Message,
                
                [Parameter(Mandatory = $false)]
                [ValidateSet("Information", "Warning", "Error")]
                [string]$Level = "Information"
            )
            
            try {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $logMessage = "[$timestamp] [$Level] $Message"
                Add-Content -Path $LogPath -Value $logMessage -ErrorAction Stop
                return $true
            }
            catch {
                Write-Error "Erreur lors de l'Ã©criture dans le fichier de log: $_"
                return $false
            }
        }
        
        function Test-FileSize {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [string]$FilePath,
                
                [Parameter(Mandatory = $true)]
                [int]$MaxSizeKB
            )
            
            try {
                $file = Get-Item -Path $FilePath -ErrorAction Stop
                $sizeKB = [math]::Round($file.Length / 1KB, 2)
                
                if ($sizeKB -gt $MaxSizeKB) {
                    Write-Warning "Le fichier '$FilePath' dÃ©passe la taille maximale autorisÃ©e ($sizeKB KB > $MaxSizeKB KB)."
                    return $false
                }
                else {
                    return $true
                }
            }
            catch {
                Write-Error "Erreur lors de la vÃ©rification de la taille du fichier: $_"
                return $false
            }
        }
        
        function Backup-File {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory = $true)]
                [string]$FilePath,
                
                [Parameter(Mandatory = $false)]
                [string]$BackupFolder = (Join-Path -Path (Split-Path -Path $FilePath -Parent) -ChildPath "Backup"),
                
                [Parameter(Mandatory = $false)]
                [switch]$CreateBackupFolder
            )
            
            try {
                # VÃ©rifier que le fichier existe
                if (-not (Test-Path -Path $FilePath -ErrorAction Stop)) {
                    Write-Error "Le fichier '$FilePath' n'existe pas."
                    return $false
                }
                
                # CrÃ©er le dossier de backup si nÃ©cessaire
                if (-not (Test-Path -Path $BackupFolder) -and $CreateBackupFolder) {
                    New-Item -Path $BackupFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }
                elseif (-not (Test-Path -Path $BackupFolder)) {
                    Write-Error "Le dossier de backup '$BackupFolder' n'existe pas."
                    return $false
                }
                
                # GÃ©nÃ©rer le nom du fichier de backup
                $fileName = Split-Path -Path $FilePath -Leaf
                $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $backupFileName = "$($fileName.Split('.')[0])_$timestamp.$($fileName.Split('.')[1])"
                $backupFilePath = Join-Path -Path $BackupFolder -ChildPath $backupFileName
                
                # Copier le fichier
                Copy-Item -Path $FilePath -Destination $backupFilePath -Force -ErrorAction Stop
                
                return $backupFilePath
            }
            catch {
                Write-Error "Erreur lors de la crÃ©ation du backup: $_"
                return $false
            }
        }
    }
    
    Context "Fonction Get-ConfigValue" {
        It "Devrait rÃ©cupÃ©rer une valeur de configuration" {
            # RÃ©cupÃ©rer une valeur de configuration
            $logPath = Get-ConfigValue -ConfigPath $script:configPath -Key "LogPath"
            
            # VÃ©rifier que la valeur a Ã©tÃ© rÃ©cupÃ©rÃ©e correctement
            $logPath | Should -Not -BeNullOrEmpty
            $logPath | Should -Be $script:logPath
        }
        
        It "Devrait rÃ©cupÃ©rer une valeur de configuration de type tableau" {
            # RÃ©cupÃ©rer une valeur de configuration de type tableau
            $errorCategories = Get-ConfigValue -ConfigPath $script:configPath -Key "ErrorCategories"
            
            # VÃ©rifier que la valeur a Ã©tÃ© rÃ©cupÃ©rÃ©e correctement
            $errorCategories | Should -Not -BeNullOrEmpty
            $errorCategories.Count | Should -Be 3
            $errorCategories | Should -Contain "Syntax"
            $errorCategories | Should -Contain "Runtime"
            $errorCategories | Should -Contain "Logic"
        }
        
        It "Devrait rÃ©cupÃ©rer une valeur de configuration de type boolÃ©en" {
            # RÃ©cupÃ©rer une valeur de configuration de type boolÃ©en
            $enableVerboseLogging = Get-ConfigValue -ConfigPath $script:configPath -Key "EnableVerboseLogging"
            
            # VÃ©rifier que la valeur a Ã©tÃ© rÃ©cupÃ©rÃ©e correctement
            $enableVerboseLogging | Should -Not -BeNullOrEmpty
            $enableVerboseLogging | Should -BeTrue
        }
        
        It "Devrait retourner null pour une clÃ© inexistante" {
            # RÃ©cupÃ©rer une valeur de configuration inexistante
            $value = Get-ConfigValue -ConfigPath $script:configPath -Key "NonExistentKey"
            
            # VÃ©rifier que la valeur est null
            $value | Should -BeNullOrEmpty
        }
    }
    
    Context "Fonction Write-LogMessage" {
        It "Devrait Ã©crire un message de log" {
            # Ã‰crire un message de log
            $result = Write-LogMessage -LogPath $script:logPath -Message "Test message" -Level "Information"
            
            # VÃ©rifier que le message a Ã©tÃ© Ã©crit correctement
            $result | Should -BeTrue
            
            # VÃ©rifier que le message est prÃ©sent dans le fichier de log
            $logContent = Get-Content -Path $script:logPath -Raw
            $logContent | Should -Match "Test message"
            $logContent | Should -Match "\[Information\]"
        }
        
        It "Devrait Ã©crire un message de log de niveau Warning" {
            # Ã‰crire un message de log de niveau Warning
            $result = Write-LogMessage -LogPath $script:logPath -Message "Test warning" -Level "Warning"
            
            # VÃ©rifier que le message a Ã©tÃ© Ã©crit correctement
            $result | Should -BeTrue
            
            # VÃ©rifier que le message est prÃ©sent dans le fichier de log
            $logContent = Get-Content -Path $script:logPath -Raw
            $logContent | Should -Match "Test warning"
            $logContent | Should -Match "\[Warning\]"
        }
        
        It "Devrait Ã©crire un message de log de niveau Error" {
            # Ã‰crire un message de log de niveau Error
            $result = Write-LogMessage -LogPath $script:logPath -Message "Test error" -Level "Error"
            
            # VÃ©rifier que le message a Ã©tÃ© Ã©crit correctement
            $result | Should -BeTrue
            
            # VÃ©rifier que le message est prÃ©sent dans le fichier de log
            $logContent = Get-Content -Path $script:logPath -Raw
            $logContent | Should -Match "Test error"
            $logContent | Should -Match "\[Error\]"
        }
    }
    
    Context "Fonction Test-FileSize" {
        It "Devrait retourner true pour un fichier de taille infÃ©rieure Ã  la limite" {
            # VÃ©rifier la taille du fichier
            $result = Test-FileSize -FilePath $script:logPath -MaxSizeKB 1024
            
            # VÃ©rifier que le rÃ©sultat est correct
            $result | Should -BeTrue
        }
        
        It "Devrait retourner false pour un fichier de taille supÃ©rieure Ã  la limite" {
            # CrÃ©er un fichier de grande taille
            $largeFilePath = Join-Path -Path $script:testRoot -ChildPath "large.txt"
            $largeContent = "X" * 1024 * 2 # 2 KB
            Set-Content -Path $largeFilePath -Value $largeContent
            
            # VÃ©rifier la taille du fichier
            $result = Test-FileSize -FilePath $largeFilePath -MaxSizeKB 1
            
            # VÃ©rifier que le rÃ©sultat est correct
            $result | Should -BeFalse
        }
    }
    
    Context "Fonction Backup-File" {
        It "Devrait crÃ©er un backup d'un fichier" {
            # CrÃ©er un dossier de backup
            $backupFolder = Join-Path -Path $script:testRoot -ChildPath "Backup"
            New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
            
            # CrÃ©er un backup du fichier
            $backupPath = Backup-File -FilePath $script:logPath -BackupFolder $backupFolder
            
            # VÃ©rifier que le backup a Ã©tÃ© crÃ©Ã© correctement
            $backupPath | Should -Not -BeNullOrEmpty
            Test-Path -Path $backupPath | Should -BeTrue
            
            # VÃ©rifier que le contenu du backup est identique Ã  l'original
            $originalContent = Get-Content -Path $script:logPath -Raw
            $backupContent = Get-Content -Path $backupPath -Raw
            $backupContent | Should -Be $originalContent
        }
        
        It "Devrait crÃ©er un dossier de backup si nÃ©cessaire" {
            # CrÃ©er un backup du fichier avec crÃ©ation du dossier
            $backupFolder = Join-Path -Path $script:testRoot -ChildPath "NewBackupFolder"
            $backupPath = Backup-File -FilePath $script:logPath -BackupFolder $backupFolder -CreateBackupFolder
            
            # VÃ©rifier que le backup a Ã©tÃ© crÃ©Ã© correctement
            $backupPath | Should -Not -BeNullOrEmpty
            Test-Path -Path $backupPath | Should -BeTrue
            
            # VÃ©rifier que le dossier de backup a Ã©tÃ© crÃ©Ã©
            Test-Path -Path $backupFolder | Should -BeTrue
        }
        
        It "Devrait retourner false pour un fichier inexistant" {
            # CrÃ©er un backup d'un fichier inexistant
            $backupPath = Backup-File -FilePath (Join-Path -Path $script:testRoot -ChildPath "nonexistent.txt") -BackupFolder (Join-Path -Path $script:testRoot -ChildPath "Backup")
            
            # VÃ©rifier que le rÃ©sultat est correct
            $backupPath | Should -BeFalse
        }
    }
    
    AfterAll {
        # Supprimer le rÃ©pertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }
}

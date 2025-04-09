<#
.SYNOPSIS
    Tests unitaires pour les fonctions auxiliaires du système d'apprentissage des erreurs.
.DESCRIPTION
    Ce script contient des tests unitaires pour les fonctions auxiliaires du système d'apprentissage des erreurs.
.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Définir les tests Pester
Describe "Tests des fonctions auxiliaires" {
    BeforeAll {
        # Créer un répertoire temporaire pour les tests
        $script:testRoot = Join-Path -Path $env:TEMP -ChildPath "HelperFunctionsTests"
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
        New-Item -Path $script:testRoot -ItemType Directory -Force | Out-Null
        
        # Créer un fichier de log
        $script:logPath = Join-Path -Path $script:testRoot -ChildPath "test.log"
        Set-Content -Path $script:logPath -Value "Test log content"
        
        # Créer un fichier de configuration
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
        
        # Définir les fonctions auxiliaires
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
                    Write-Warning "La clé '$Key' n'existe pas dans le fichier de configuration."
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
                Write-Error "Erreur lors de l'écriture dans le fichier de log: $_"
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
                    Write-Warning "Le fichier '$FilePath' dépasse la taille maximale autorisée ($sizeKB KB > $MaxSizeKB KB)."
                    return $false
                }
                else {
                    return $true
                }
            }
            catch {
                Write-Error "Erreur lors de la vérification de la taille du fichier: $_"
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
                # Vérifier que le fichier existe
                if (-not (Test-Path -Path $FilePath -ErrorAction Stop)) {
                    Write-Error "Le fichier '$FilePath' n'existe pas."
                    return $false
                }
                
                # Créer le dossier de backup si nécessaire
                if (-not (Test-Path -Path $BackupFolder) -and $CreateBackupFolder) {
                    New-Item -Path $BackupFolder -ItemType Directory -Force -ErrorAction Stop | Out-Null
                }
                elseif (-not (Test-Path -Path $BackupFolder)) {
                    Write-Error "Le dossier de backup '$BackupFolder' n'existe pas."
                    return $false
                }
                
                # Générer le nom du fichier de backup
                $fileName = Split-Path -Path $FilePath -Leaf
                $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
                $backupFileName = "$($fileName.Split('.')[0])_$timestamp.$($fileName.Split('.')[1])"
                $backupFilePath = Join-Path -Path $BackupFolder -ChildPath $backupFileName
                
                # Copier le fichier
                Copy-Item -Path $FilePath -Destination $backupFilePath -Force -ErrorAction Stop
                
                return $backupFilePath
            }
            catch {
                Write-Error "Erreur lors de la création du backup: $_"
                return $false
            }
        }
    }
    
    Context "Fonction Get-ConfigValue" {
        It "Devrait récupérer une valeur de configuration" {
            # Récupérer une valeur de configuration
            $logPath = Get-ConfigValue -ConfigPath $script:configPath -Key "LogPath"
            
            # Vérifier que la valeur a été récupérée correctement
            $logPath | Should -Not -BeNullOrEmpty
            $logPath | Should -Be $script:logPath
        }
        
        It "Devrait récupérer une valeur de configuration de type tableau" {
            # Récupérer une valeur de configuration de type tableau
            $errorCategories = Get-ConfigValue -ConfigPath $script:configPath -Key "ErrorCategories"
            
            # Vérifier que la valeur a été récupérée correctement
            $errorCategories | Should -Not -BeNullOrEmpty
            $errorCategories.Count | Should -Be 3
            $errorCategories | Should -Contain "Syntax"
            $errorCategories | Should -Contain "Runtime"
            $errorCategories | Should -Contain "Logic"
        }
        
        It "Devrait récupérer une valeur de configuration de type booléen" {
            # Récupérer une valeur de configuration de type booléen
            $enableVerboseLogging = Get-ConfigValue -ConfigPath $script:configPath -Key "EnableVerboseLogging"
            
            # Vérifier que la valeur a été récupérée correctement
            $enableVerboseLogging | Should -Not -BeNullOrEmpty
            $enableVerboseLogging | Should -BeTrue
        }
        
        It "Devrait retourner null pour une clé inexistante" {
            # Récupérer une valeur de configuration inexistante
            $value = Get-ConfigValue -ConfigPath $script:configPath -Key "NonExistentKey"
            
            # Vérifier que la valeur est null
            $value | Should -BeNullOrEmpty
        }
    }
    
    Context "Fonction Write-LogMessage" {
        It "Devrait écrire un message de log" {
            # Écrire un message de log
            $result = Write-LogMessage -LogPath $script:logPath -Message "Test message" -Level "Information"
            
            # Vérifier que le message a été écrit correctement
            $result | Should -BeTrue
            
            # Vérifier que le message est présent dans le fichier de log
            $logContent = Get-Content -Path $script:logPath -Raw
            $logContent | Should -Match "Test message"
            $logContent | Should -Match "\[Information\]"
        }
        
        It "Devrait écrire un message de log de niveau Warning" {
            # Écrire un message de log de niveau Warning
            $result = Write-LogMessage -LogPath $script:logPath -Message "Test warning" -Level "Warning"
            
            # Vérifier que le message a été écrit correctement
            $result | Should -BeTrue
            
            # Vérifier que le message est présent dans le fichier de log
            $logContent = Get-Content -Path $script:logPath -Raw
            $logContent | Should -Match "Test warning"
            $logContent | Should -Match "\[Warning\]"
        }
        
        It "Devrait écrire un message de log de niveau Error" {
            # Écrire un message de log de niveau Error
            $result = Write-LogMessage -LogPath $script:logPath -Message "Test error" -Level "Error"
            
            # Vérifier que le message a été écrit correctement
            $result | Should -BeTrue
            
            # Vérifier que le message est présent dans le fichier de log
            $logContent = Get-Content -Path $script:logPath -Raw
            $logContent | Should -Match "Test error"
            $logContent | Should -Match "\[Error\]"
        }
    }
    
    Context "Fonction Test-FileSize" {
        It "Devrait retourner true pour un fichier de taille inférieure à la limite" {
            # Vérifier la taille du fichier
            $result = Test-FileSize -FilePath $script:logPath -MaxSizeKB 1024
            
            # Vérifier que le résultat est correct
            $result | Should -BeTrue
        }
        
        It "Devrait retourner false pour un fichier de taille supérieure à la limite" {
            # Créer un fichier de grande taille
            $largeFilePath = Join-Path -Path $script:testRoot -ChildPath "large.txt"
            $largeContent = "X" * 1024 * 2 # 2 KB
            Set-Content -Path $largeFilePath -Value $largeContent
            
            # Vérifier la taille du fichier
            $result = Test-FileSize -FilePath $largeFilePath -MaxSizeKB 1
            
            # Vérifier que le résultat est correct
            $result | Should -BeFalse
        }
    }
    
    Context "Fonction Backup-File" {
        It "Devrait créer un backup d'un fichier" {
            # Créer un dossier de backup
            $backupFolder = Join-Path -Path $script:testRoot -ChildPath "Backup"
            New-Item -Path $backupFolder -ItemType Directory -Force | Out-Null
            
            # Créer un backup du fichier
            $backupPath = Backup-File -FilePath $script:logPath -BackupFolder $backupFolder
            
            # Vérifier que le backup a été créé correctement
            $backupPath | Should -Not -BeNullOrEmpty
            Test-Path -Path $backupPath | Should -BeTrue
            
            # Vérifier que le contenu du backup est identique à l'original
            $originalContent = Get-Content -Path $script:logPath -Raw
            $backupContent = Get-Content -Path $backupPath -Raw
            $backupContent | Should -Be $originalContent
        }
        
        It "Devrait créer un dossier de backup si nécessaire" {
            # Créer un backup du fichier avec création du dossier
            $backupFolder = Join-Path -Path $script:testRoot -ChildPath "NewBackupFolder"
            $backupPath = Backup-File -FilePath $script:logPath -BackupFolder $backupFolder -CreateBackupFolder
            
            # Vérifier que le backup a été créé correctement
            $backupPath | Should -Not -BeNullOrEmpty
            Test-Path -Path $backupPath | Should -BeTrue
            
            # Vérifier que le dossier de backup a été créé
            Test-Path -Path $backupFolder | Should -BeTrue
        }
        
        It "Devrait retourner false pour un fichier inexistant" {
            # Créer un backup d'un fichier inexistant
            $backupPath = Backup-File -FilePath (Join-Path -Path $script:testRoot -ChildPath "nonexistent.txt") -BackupFolder (Join-Path -Path $script:testRoot -ChildPath "Backup")
            
            # Vérifier que le résultat est correct
            $backupPath | Should -BeFalse
        }
    }
    
    AfterAll {
        # Supprimer le répertoire de test
        if (Test-Path -Path $script:testRoot) {
            Remove-Item -Path $script:testRoot -Recurse -Force
        }
    }
}

<#
.SYNOPSIS
    Tests unitaires avec Pester pour les fonctions de journalisation.

.DESCRIPTION
    Ce script contient des tests unitaires avec Pester pour les fonctions de journalisation,
    de rotation des journaux et de verbosite configurable.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de creation: 2023-08-16
#>

# Definir les configurations pour les tests
$script:LogRotationConfig = @{
    SizeBasedRotation = @{
        Enabled = $true
        MaxSizeKB = 1024
        BackupCount = 5
    }
    DateBasedRotation = @{
        Enabled = $true
        Interval = "Daily"
        RetentionDays = 30
    }
    Compression = @{
        Enabled = $false
        Format = "Zip"
        CompressAfterDays = 7
    }
    AutoPurge = @{
        Enabled = $true
        MaxAge = 90
        MaxCount = 100
        MinDiskSpaceGB = 1
    }
}

$script:VerbosityConfig = @{
    Level = "Normal"
    Formats = @{
        "Minimal" = "[{0}] {1}"
        "Normal" = "[{0}] [{1}] {2}"
        "Detailed" = "[{0}] [{1}] [{2}] {3}"
        "Debug" = "[{0}] [{1}] [{2}] [{3}] {4}"
        "Diagnostic" = "[{0}] [{1}] [{2}] [{3}] [{4}] {5}"
    }
    Categories = @{
        "Minimal" = @("Error", "Critical")
        "Normal" = @("Error", "Critical", "Warning", "Info")
        "Detailed" = @("Error", "Critical", "Warning", "Info", "Verbose")
        "Debug" = @("Error", "Critical", "Warning", "Info", "Verbose", "Debug")
        "Diagnostic" = @("Error", "Critical", "Warning", "Info", "Verbose", "Debug", "Trace")
    }
    Presets = @{
        "Silent" = @{
            Level = "Minimal"
            Categories = @("Critical")
            Format = "[{0}] {1}"
        }
        "Production" = @{
            Level = "Normal"
            Categories = @("Error", "Critical", "Warning")
            Format = "[{0}] [{1}] {2}"
        }
        "Development" = @{
            Level = "Detailed"
            Categories = @("Error", "Critical", "Warning", "Info", "Verbose")
            Format = "[{0}] [{1}] [{2}] {3}"
        }
        "Debugging" = @{
            Level = "Debug"
            Categories = @("Error", "Critical", "Warning", "Info", "Verbose", "Debug")
            Format = "[{0}] [{1}] [{2}] [{3}] {4}"
        }
        "Diagnostic" = @{
            Level = "Diagnostic"
            Categories = @("Error", "Critical", "Warning", "Info", "Verbose", "Debug", "Trace")
            Format = "[{0}] [{1}] [{2}] [{3}] [{4}] {5}"
        }
    }
}

# Definir les fonctions pour les tests
function Get-LogRotationConfig {
    return $script:LogRotationConfig
}

function Set-LogRotationConfig {
    param(
        [Parameter(Mandatory = $false)]
        [bool]$SizeBasedEnabled,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxSizeKB,
        
        [Parameter(Mandatory = $false)]
        [int]$BackupCount
    )
    
    if ($PSBoundParameters.ContainsKey('SizeBasedEnabled')) {
        $script:LogRotationConfig.SizeBasedRotation.Enabled = $SizeBasedEnabled
    }
    
    if ($PSBoundParameters.ContainsKey('MaxSizeKB')) {
        $script:LogRotationConfig.SizeBasedRotation.MaxSizeKB = $MaxSizeKB
    }
    
    if ($PSBoundParameters.ContainsKey('BackupCount')) {
        $script:LogRotationConfig.SizeBasedRotation.BackupCount = $BackupCount
    }
}

function Test-LogRotationBySize {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )
    
    if (-not $script:LogRotationConfig.SizeBasedRotation.Enabled) {
        return $false
    }
    
    if (-not (Test-Path -Path $LogFile)) {
        return $false
    }
    
    $fileInfo = Get-Item -Path $LogFile
    $fileSizeKB = $fileInfo.Length / 1KB
    
    return $fileSizeKB -ge $script:LogRotationConfig.SizeBasedRotation.MaxSizeKB
}

function Invoke-LogRotationBySize {
    param(
        [Parameter(Mandatory = $true)]
        [string]$LogFile
    )
    
    if (-not (Test-Path -Path $LogFile)) {
        Write-Warning "Le fichier de journal n'existe pas : $LogFile"
        return
    }
    
    $backupCount = $script:LogRotationConfig.SizeBasedRotation.BackupCount
    
    # Supprimer le fichier de sauvegarde le plus ancien s'il existe
    $oldestBackup = "$LogFile.$backupCount"
    if (Test-Path -Path $oldestBackup) {
        Remove-Item -Path $oldestBackup -Force
    }
    
    # Decaler les fichiers de sauvegarde existants
    for ($i = $backupCount - 1; $i -ge 1; $i--) {
        $currentBackup = "$LogFile.$i"
        $nextBackup = "$LogFile.$($i + 1)"
        
        if (Test-Path -Path $currentBackup) {
            Move-Item -Path $currentBackup -Destination $nextBackup -Force
        }
    }
    
    # Creer le premier fichier de sauvegarde
    Copy-Item -Path $LogFile -Destination "$LogFile.1" -Force
    
    # Vider le fichier de journal actuel
    Clear-Content -Path $LogFile
}

function Get-VerbosityConfig {
    return $script:VerbosityConfig
}

function Set-VerbosityLevel {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Minimal", "Normal", "Detailed", "Debug", "Diagnostic")]
        [string]$Level
    )
    
    $script:VerbosityConfig.Level = $Level
}

function Get-VerbosityLevel {
    return $script:VerbosityConfig.Level
}

function Set-VerbosityPreset {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Silent", "Production", "Development", "Debugging", "Diagnostic")]
        [string]$PresetName
    )
    
    $preset = $script:VerbosityConfig.Presets[$PresetName]
    
    $script:VerbosityConfig.Level = $preset.Level
    
    if ($preset.Categories) {
        $script:VerbosityConfig.Categories[$preset.Level] = $preset.Categories
    }
    
    if ($preset.Format) {
        $script:VerbosityConfig.Formats[$preset.Level] = $preset.Format
    }
}

function Test-VerbosityLogLevel {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category
    )
    
    $currentLevel = $script:VerbosityConfig.Level
    $enabledCategories = $script:VerbosityConfig.Categories[$currentLevel]
    
    return $enabledCategories -contains $Category
}

function Format-MessageByVerbosity {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $true)]
        [string]$Level,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "General",
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Id = ""
    )
    
    $currentLevel = $script:VerbosityConfig.Level
    $format = $script:VerbosityConfig.Formats[$currentLevel]
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($currentLevel) {
        "Minimal" {
            return $format -f $Level, $Message
        }
        "Normal" {
            return $format -f $timestamp, $Level, $Message
        }
        "Detailed" {
            return $format -f $timestamp, $Level, $Category, $Message
        }
        "Debug" {
            return $format -f $timestamp, $Level, $Category, $Source, $Message
        }
        "Diagnostic" {
            return $format -f $timestamp, $Level, $Category, $Source, $Id, $Message
        }
    }
}

# Tests Pester
Describe "Log Rotation Functions" {
    BeforeAll {
        # Creer un repertoire temporaire pour les tests
        $testDir = Join-Path -Path $TestDrive -ChildPath "logs"
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
        
        # Creer un fichier de journal de test
        $script:testLogFile = Join-Path -Path $testDir -ChildPath "test.log"
        Set-Content -Path $script:testLogFile -Value "Test log content" -Force
    }
    
    Context "Configuration Functions" {
        It "Should get the default log rotation configuration" {
            $config = Get-LogRotationConfig
            $config | Should -Not -BeNullOrEmpty
            $config.SizeBasedRotation | Should -Not -BeNullOrEmpty
            $config.DateBasedRotation | Should -Not -BeNullOrEmpty
        }
        
        It "Should set the log rotation configuration" {
            # Modifier la configuration
            Set-LogRotationConfig -SizeBasedEnabled $true -MaxSizeKB 2048 -BackupCount 10
            
            # Verifier que la configuration a ete mise a jour
            $config = Get-LogRotationConfig
            $config.SizeBasedRotation.Enabled | Should -Be $true
            $config.SizeBasedRotation.MaxSizeKB | Should -Be 2048
            $config.SizeBasedRotation.BackupCount | Should -Be 10
        }
    }
    
    Context "Size-Based Rotation" {
        BeforeEach {
            # Reinitialiser la configuration pour les tests
            Set-LogRotationConfig -SizeBasedEnabled $true -MaxSizeKB 1 -BackupCount 3
            
            # Creer un fichier de journal de test avec une taille connue
            Set-Content -Path $script:testLogFile -Value ("A" * 1024) -Force
        }
        
        It "Should detect when a log file needs rotation by size" {
            $result = Test-LogRotationBySize -LogFile $script:testLogFile
            $result | Should -Be $true
        }
        
        It "Should not detect rotation need for small files" {
            # Creer un petit fichier
            $smallLogFile = Join-Path -Path $TestDrive -ChildPath "small_test.log"
            Set-Content -Path $smallLogFile -Value "Small file" -Force
            
            # Configurer une taille maximale plus grande
            Set-LogRotationConfig -MaxSizeKB 10
            
            $result = Test-LogRotationBySize -LogFile $smallLogFile
            $result | Should -Be $false
        }
        
        It "Should rotate a log file by size" {
            # Verifier que le fichier existe
            Test-Path -Path $script:testLogFile | Should -Be $true
            
            # Effectuer la rotation
            Invoke-LogRotationBySize -LogFile $script:testLogFile
            
            # Verifier que le fichier de sauvegarde a ete cree
            $backupFile = "$script:testLogFile.1"
            Test-Path -Path $backupFile | Should -Be $true
            
            # Verifier que le fichier original a ete vide
            $content = Get-Content -Path $script:testLogFile -Raw
            $content | Should -BeNullOrEmpty
        }
    }
}

Describe "Verbosity Functions" {
    Context "Configuration Functions" {
        It "Should get the default verbosity configuration" {
            $config = Get-VerbosityConfig
            $config | Should -Not -BeNullOrEmpty
            $config.Level | Should -Not -BeNullOrEmpty
            $config.Formats | Should -Not -BeNullOrEmpty
            $config.Categories | Should -Not -BeNullOrEmpty
        }
        
        It "Should set and get the verbosity level" {
            # Definir le niveau de verbosite
            Set-VerbosityLevel -Level "Detailed"
            
            # Verifier que le niveau a ete mis a jour
            $level = Get-VerbosityLevel
            $level | Should -Be "Detailed"
        }
    }
    
    Context "Verbosity Presets" {
        It "Should apply the 'Development' preset" {
            # Appliquer le prereglage
            Set-VerbosityPreset -PresetName "Development"
            
            # Verifier que la configuration a ete mise a jour
            $config = Get-VerbosityConfig
            $config.Level | Should -Be $config.Presets["Development"].Level
        }
    }
    
    Context "Logging Decision" {
        It "Should log messages in enabled categories" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Normal"
            
            # Verifier que les messages des categories activees sont journalises
            Test-VerbosityLogLevel -Category "Error" | Should -Be $true
            Test-VerbosityLogLevel -Category "Warning" | Should -Be $true
            Test-VerbosityLogLevel -Category "Info" | Should -Be $true
        }
        
        It "Should not log messages in disabled categories" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Normal"
            
            # Verifier que les messages des categories desactivees ne sont pas journalises
            Test-VerbosityLogLevel -Category "Debug" | Should -Be $false
            Test-VerbosityLogLevel -Category "Trace" | Should -Be $false
        }
    }
    
    Context "Message Formatting" {
        It "Should format messages according to the 'Minimal' level" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Minimal"
            
            # Formater un message
            $message = Format-MessageByVerbosity -Message "Test message" -Level "Error"
            
            # Verifier le format
            $message | Should -Match "^\[Error\] Test message$"
        }
        
        It "Should format messages according to the 'Detailed' level" {
            # Configurer pour le test
            Set-VerbosityLevel -Level "Detailed"
            
            # Formater un message
            $message = Format-MessageByVerbosity -Message "Test message" -Level "Error" -Category "TestCategory"
            
            # Verifier le format (avec timestamp et categorie)
            $message | Should -Match "^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Error\] \[TestCategory\] Test message$"
        }
    }
}

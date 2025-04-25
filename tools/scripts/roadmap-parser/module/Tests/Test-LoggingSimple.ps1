<#
.SYNOPSIS
    Tests simplifiés pour les fonctions de journalisation.

.DESCRIPTION
    Ce script contient des tests simplifiés pour les fonctions de journalisation,
    de rotation des journaux et de verbosité configurable.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-16
#>

# Définir les fonctions de journalisation directement dans le script de test
# pour éviter les problèmes avec Export-ModuleMember

# Configuration de rotation des journaux
$script:LogRotationConfig = @{
    # Configuration de rotation par taille
    SizeBasedRotation = @{
        Enabled = $true
        MaxSizeKB = 1024  # Taille maximale du fichier de journal en KB (1 MB par défaut)
        BackupCount = 5   # Nombre de fichiers de sauvegarde à conserver
    }
    
    # Configuration de rotation par date
    DateBasedRotation = @{
        Enabled = $true
        Interval = "Daily"  # Valeurs possibles : "Hourly", "Daily", "Weekly", "Monthly"
        RetentionDays = 30  # Nombre de jours de conservation des journaux
    }
    
    # Configuration de compression
    Compression = @{
        Enabled = $false
        Format = "Zip"  # Valeurs possibles : "Zip", "GZip"
        CompressAfterDays = 7  # Compresser les fichiers plus anciens que X jours
    }
    
    # Configuration de purge automatique
    AutoPurge = @{
        Enabled = $true
        MaxAge = 90  # Âge maximal des fichiers en jours
        MaxCount = 100  # Nombre maximal de fichiers à conserver
        MinDiskSpaceGB = 1  # Espace disque minimal requis en GB
    }
}

# Configuration de verbosité
$script:VerbosityConfig = @{
    # Niveau de verbosité global
    Level = "Normal"  # Valeurs possibles : "Minimal", "Normal", "Detailed", "Debug", "Diagnostic"
    
    # Formats de message par niveau de verbosité
    Formats = @{
        "Minimal" = "[{0}] {1}"  # Niveau, Message
        "Normal" = "[{0}] [{1}] {2}"  # Timestamp, Niveau, Message
        "Detailed" = "[{0}] [{1}] [{2}] {3}"  # Timestamp, Niveau, Catégorie, Message
        "Debug" = "[{0}] [{1}] [{2}] [{3}] {4}"  # Timestamp, Niveau, Catégorie, Source, Message
        "Diagnostic" = "[{0}] [{1}] [{2}] [{3}] [{4}] {5}"  # Timestamp, Niveau, Catégorie, Source, ID, Message
    }
    
    # Catégories activées par niveau de verbosité
    Categories = @{
        "Minimal" = @("Error", "Critical")
        "Normal" = @("Error", "Critical", "Warning", "Info")
        "Detailed" = @("Error", "Critical", "Warning", "Info", "Verbose")
        "Debug" = @("Error", "Critical", "Warning", "Info", "Verbose", "Debug")
        "Diagnostic" = @("Error", "Critical", "Warning", "Info", "Verbose", "Debug", "Trace")
    }
    
    # Préréglages de verbosité
    Presets = @{
        "Silent" = @{
            Level = "Minimal"
            Categories = @("Critical")
            Format = "[{0}] {1}"  # Niveau, Message
        }
        "Production" = @{
            Level = "Normal"
            Categories = @("Error", "Critical", "Warning")
            Format = "[{0}] [{1}] {2}"  # Timestamp, Niveau, Message
        }
        "Development" = @{
            Level = "Detailed"
            Categories = @("Error", "Critical", "Warning", "Info", "Verbose")
            Format = "[{0}] [{1}] [{2}] {3}"  # Timestamp, Niveau, Catégorie, Message
        }
        "Debugging" = @{
            Level = "Debug"
            Categories = @("Error", "Critical", "Warning", "Info", "Verbose", "Debug")
            Format = "[{0}] [{1}] [{2}] [{3}] {4}"  # Timestamp, Niveau, Catégorie, Source, Message
        }
        "Diagnostic" = @{
            Level = "Diagnostic"
            Categories = @("Error", "Critical", "Warning", "Info", "Verbose", "Debug", "Trace")
            Format = "[{0}] [{1}] [{2}] [{3}] [{4}] {5}"  # Timestamp, Niveau, Catégorie, Source, ID, Message
        }
    }
}

# Configuration de journalisation
$script:LoggingConfig = @{
    # Fichier de journal par défaut
    DefaultLogFile = "logs\roadmap-parser.log"
    
    # Activer la rotation des journaux
    EnableRotation = $true
    
    # Activer la verbosité configurable
    EnableVerbosity = $true
}

# Fonctions de test pour la rotation des journaux
function Test-LogRotation {
    [CmdletBinding()]
    param()
    
    # Créer un répertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "LogRotationTest"
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    # Créer un fichier de journal de test
    $testLogFile = Join-Path -Path $testDir -ChildPath "test.log"
    Set-Content -Path $testLogFile -Value ("A" * 1024) -Force
    
    # Configurer la rotation par taille
    $script:LogRotationConfig.SizeBasedRotation.Enabled = $true
    $script:LogRotationConfig.SizeBasedRotation.MaxSizeKB = 1
    
    # Vérifier si le fichier doit être rotaté
    $shouldRotate = Test-LogRotationBySize -LogFile $testLogFile
    
    # Effectuer la rotation
    if ($shouldRotate) {
        Invoke-LogRotationBySize -LogFile $testLogFile
    }
    
    # Vérifier que le fichier de sauvegarde a été créé
    $backupFile = "$testLogFile.1"
    $backupExists = Test-Path -Path $backupFile
    
    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force
    
    return $backupExists
}

# Fonctions de test pour la verbosité configurable
function Test-VerbosityConfiguration {
    [CmdletBinding()]
    param()
    
    # Configurer la verbosité
    Set-VerbosityLevel -Level "Detailed"
    
    # Vérifier que le niveau a été mis à jour
    $level = Get-VerbosityLevel
    
    # Appliquer un préréglage
    Set-VerbosityPreset -PresetName "Development"
    
    # Vérifier que le préréglage a été appliqué
    $config = Get-VerbosityConfig
    $presetApplied = $config.Level -eq $config.Presets["Development"].Level
    
    return ($level -eq "Detailed") -and $presetApplied
}

# Fonctions de test pour l'intégration
function Test-LoggingIntegration {
    [CmdletBinding()]
    param()
    
    # Créer un répertoire temporaire pour les tests
    $testDir = Join-Path -Path $env:TEMP -ChildPath "LoggingIntegrationTest"
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    
    # Créer un fichier de journal de test
    $testLogFile = Join-Path -Path $testDir -ChildPath "integration.log"
    
    # Configurer la journalisation
    $script:LoggingConfig.EnableRotation = $true
    $script:LoggingConfig.EnableVerbosity = $true
    
    # Configurer la verbosité
    Set-VerbosityLevel -Level "Detailed"
    
    # Journaliser un message
    Write-LogWithVerbosity -Message "Test message" -Level "Info" -Category "TestCategory" -LogFile $testLogFile
    
    # Vérifier que le message a été journalisé
    $logExists = Test-Path -Path $testLogFile
    $logContent = if ($logExists) { Get-Content -Path $testLogFile -Raw } else { "" }
    $messageLogged = $logContent -match "Test message"
    
    # Nettoyer
    Remove-Item -Path $testDir -Recurse -Force
    
    return $logExists -and $messageLogged
}

# Exécuter les tests
Write-Host "Test de rotation des journaux : " -NoNewline
if (Test-LogRotation) {
    Write-Host "Réussi" -ForegroundColor Green
} else {
    Write-Host "Échoué" -ForegroundColor Red
}

Write-Host "Test de configuration de verbosité : " -NoNewline
if (Test-VerbosityConfiguration) {
    Write-Host "Réussi" -ForegroundColor Green
} else {
    Write-Host "Échoué" -ForegroundColor Red
}

Write-Host "Test d'intégration de journalisation : " -NoNewline
if (Test-LoggingIntegration) {
    Write-Host "Réussi" -ForegroundColor Green
} else {
    Write-Host "Échoué" -ForegroundColor Red
}

# Fonctions nécessaires pour les tests

function Test-LogRotationBySize {
    [CmdletBinding()]
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
    [CmdletBinding()]
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
    
    # Décaler les fichiers de sauvegarde existants
    for ($i = $backupCount - 1; $i -ge 1; $i--) {
        $currentBackup = "$LogFile.$i"
        $nextBackup = "$LogFile.$($i + 1)"
        
        if (Test-Path -Path $currentBackup) {
            Move-Item -Path $currentBackup -Destination $nextBackup -Force
        }
    }
    
    # Créer le premier fichier de sauvegarde
    Copy-Item -Path $LogFile -Destination "$LogFile.1" -Force
    
    # Vider le fichier de journal actuel
    Clear-Content -Path $LogFile
    
    Write-Verbose "Rotation par taille effectuée pour le fichier : $LogFile"
}

function Set-VerbosityLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("Minimal", "Normal", "Detailed", "Debug", "Diagnostic")]
        [string]$Level
    )
    
    $script:VerbosityConfig.Level = $Level
    Write-Verbose "Niveau de verbosité défini à : $Level"
}

function Get-VerbosityLevel {
    [CmdletBinding()]
    param()
    
    return $script:VerbosityConfig.Level
}

function Get-VerbosityConfig {
    [CmdletBinding()]
    param()
    
    return $script:VerbosityConfig
}

function Set-VerbosityPreset {
    [CmdletBinding()]
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
    
    Write-Verbose "Préréglage de verbosité appliqué : $PresetName"
}

function Test-VerbosityLogLevel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Category
    )
    
    $currentLevel = $script:VerbosityConfig.Level
    $enabledCategories = $script:VerbosityConfig.Categories[$currentLevel]
    
    return $enabledCategories -contains $Category
}

function Format-MessageByVerbosity {
    [CmdletBinding()]
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

function Write-LogWithVerbosity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Critical", "Error", "Warning", "Info", "Verbose", "Debug", "Trace")]
        [string]$Level,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "General",
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Id = "",
        
        [Parameter(Mandatory = $false)]
        [string]$LogFile
    )
    
    if (-not (Test-VerbosityLogLevel -Category $Level)) {
        return
    }
    
    $formattedMessage = Format-MessageByVerbosity -Message $Message -Level $Level -Category $Category -Source $Source -Id $Id
    
    # Afficher le message dans la console avec la couleur appropriée
    switch ($Level) {
        "Critical" { Write-Host $formattedMessage -ForegroundColor Red -BackgroundColor Black }
        "Error" { Write-Host $formattedMessage -ForegroundColor Red }
        "Warning" { Write-Host $formattedMessage -ForegroundColor Yellow }
        "Info" { Write-Host $formattedMessage -ForegroundColor White }
        "Verbose" { Write-Host $formattedMessage -ForegroundColor Gray }
        "Debug" { Write-Host $formattedMessage -ForegroundColor DarkGray }
        "Trace" { Write-Host $formattedMessage -ForegroundColor DarkCyan }
    }
    
    # Journaliser dans un fichier si spécifié
    if ($LogFile) {
        # Créer le répertoire parent s'il n'existe pas
        $parentDir = Split-Path -Parent $LogFile
        if (-not [string]::IsNullOrEmpty($parentDir) -and -not (Test-Path -Path $parentDir)) {
            New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $LogFile -Value $formattedMessage -Encoding UTF8
    }
}

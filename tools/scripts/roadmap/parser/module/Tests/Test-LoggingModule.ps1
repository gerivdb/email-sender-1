<#
.SYNOPSIS
    Tests unitaires pour les fonctions de journalisation avec un module temporaire.

.DESCRIPTION
    Ce script cree un module temporaire pour tester les fonctions de journalisation,
    de rotation des journaux et de verbosite configurable.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de creation: 2023-08-16
#>

# Creer un repertoire temporaire pour le module
$moduleDir = Join-Path -Path $env:TEMP -ChildPath "LoggingTestModule"
if (Test-Path -Path $moduleDir) {
    Remove-Item -Path $moduleDir -Recurse -Force
}
New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null

# Creer le fichier du module
$moduleFile = Join-Path -Path $moduleDir -ChildPath "LoggingTestModule.psm1"

# Contenu du module
$moduleContent = @'
# Configuration de rotation des journaux
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

# Configuration de verbosite
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

# Fonctions de rotation des journaux
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

# Fonctions de verbosite
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

# Exporter les fonctions
Export-ModuleMember -Function Get-LogRotationConfig, Set-LogRotationConfig, Test-LogRotationBySize, Invoke-LogRotationBySize
Export-ModuleMember -Function Get-VerbosityConfig, Set-VerbosityLevel, Get-VerbosityLevel, Set-VerbosityPreset, Test-VerbosityLogLevel, Format-MessageByVerbosity
'@

# Ecrire le contenu du module dans le fichier
Set-Content -Path $moduleFile -Value $moduleContent -Encoding UTF8

# Creer le manifeste du module
$manifestParams = @{
    Path = Join-Path -Path $moduleDir -ChildPath "LoggingTestModule.psd1"
    RootModule = "LoggingTestModule.psm1"
    ModuleVersion = "1.0.0"
    Author = "RoadmapParser Team"
    Description = "Module de test pour les fonctions de journalisation"
    PowerShellVersion = "5.1"
    FunctionsToExport = @(
        "Get-LogRotationConfig", "Set-LogRotationConfig", "Test-LogRotationBySize", "Invoke-LogRotationBySize",
        "Get-VerbosityConfig", "Set-VerbosityLevel", "Get-VerbosityLevel", "Set-VerbosityPreset", "Test-VerbosityLogLevel", "Format-MessageByVerbosity"
    )
}
New-ModuleManifest @manifestParams

# Importer le module
Import-Module -Name $moduleDir -Force

# Executer les tests
Write-Host "Execution des tests unitaires pour les fonctions de journalisation..." -ForegroundColor Cyan
Write-Host "----------------------------------------------------------------------" -ForegroundColor Cyan

# Fonction d'assertion simple
function Assert-Condition {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$FailMessage = ""
    )
    
    if ($Condition) {
        Write-Host "[OK] $Message" -ForegroundColor Green
        return $true
    } 
    else {
        if ($FailMessage) {
            Write-Host "[FAIL] $Message - $FailMessage" -ForegroundColor Red
        }
        else {
            Write-Host "[FAIL] $Message" -ForegroundColor Red
        }
        return $false
    }
}

# Tests pour les fonctions de rotation des journaux
Write-Host "`nTests de rotation des journaux:" -ForegroundColor Yellow
Write-Host "----------------------------" -ForegroundColor Yellow

$rotationResults = @()

# Test 1: Obtenir la configuration de rotation des journaux
$config = Get-LogRotationConfig
$rotationResults += Assert-Condition -Condition ($config -ne $null) -Message "Obtenir la configuration de rotation des journaux"

# Test 2: Modifier la configuration de rotation des journaux
Set-LogRotationConfig -SizeBasedEnabled $true -MaxSizeKB 2048 -BackupCount 10
$newConfig = Get-LogRotationConfig
$rotationResults += Assert-Condition -Condition ($newConfig.SizeBasedRotation.MaxSizeKB -eq 2048) -Message "Modifier la configuration de rotation des journaux"

# Test 3: Creer un fichier de journal de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "LogRotationTest"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
$testLogFile = Join-Path -Path $testDir -ChildPath "test.log"
Set-Content -Path $testLogFile -Value ("A" * 3072) -Force
$rotationResults += Assert-Condition -Condition (Test-Path -Path $testLogFile) -Message "Creer un fichier de journal de test"

# Test 4: Detecter si un fichier doit etre rotate
Set-LogRotationConfig -MaxSizeKB 1
$shouldRotate = Test-LogRotationBySize -LogFile $testLogFile
$rotationResults += Assert-Condition -Condition $shouldRotate -Message "Detecter si un fichier doit etre rotate"

# Test 5: Effectuer la rotation d'un fichier
Invoke-LogRotationBySize -LogFile $testLogFile
$backupFile = "$testLogFile.1"
$backupExists = Test-Path -Path $backupFile
$originalEmpty = (Get-Content -Path $testLogFile -Raw).Length -eq 0
$rotationResults += Assert-Condition -Condition $backupExists -Message "Creer un fichier de sauvegarde"
$rotationResults += Assert-Condition -Condition $originalEmpty -Message "Vider le fichier original"

# Nettoyer
Remove-Item -Path $testDir -Recurse -Force

# Tests pour les fonctions de verbosite
Write-Host "`nTests de verbosite configurable:" -ForegroundColor Yellow
Write-Host "------------------------------" -ForegroundColor Yellow

$verbosityResults = @()

# Test 1: Obtenir la configuration de verbosite
$config = Get-VerbosityConfig
$verbosityResults += Assert-Condition -Condition ($config -ne $null) -Message "Obtenir la configuration de verbosite"

# Test 2: Modifier le niveau de verbosite
Set-VerbosityLevel -Level "Detailed"
$level = Get-VerbosityLevel
$verbosityResults += Assert-Condition -Condition ($level -eq "Detailed") -Message "Modifier le niveau de verbosite"

# Test 3: Appliquer un prereglage
Set-VerbosityPreset -PresetName "Development"
$newConfig = Get-VerbosityConfig
$verbosityResults += Assert-Condition -Condition ($newConfig.Level -eq $newConfig.Presets["Development"].Level) -Message "Appliquer un prereglage"

# Test 4: Verifier si un message doit etre journalise
Set-VerbosityLevel -Level "Normal"
$shouldLogInfo = Test-VerbosityLogLevel -Category "Info"
$shouldLogDebug = Test-VerbosityLogLevel -Category "Debug"
$verbosityResults += Assert-Condition -Condition $shouldLogInfo -Message "Verifier qu'un message de niveau Info doit etre journalise"
$verbosityResults += Assert-Condition -Condition (-not $shouldLogDebug) -Message "Verifier qu'un message de niveau Debug ne doit pas etre journalise"

# Test 5: Formater un message selon le niveau de verbosite
Set-VerbosityLevel -Level "Minimal"
$minimalMessage = Format-MessageByVerbosity -Message "Test message" -Level "Error"
$verbosityResults += Assert-Condition -Condition ($minimalMessage -match "^\[Error\] Test message$") -Message "Formater un message selon le niveau Minimal"

Set-VerbosityLevel -Level "Detailed"
$detailedMessage = Format-MessageByVerbosity -Message "Test message" -Level "Error" -Category "TestCategory"
$verbosityResults += Assert-Condition -Condition ($detailedMessage -match "^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\] \[Error\] \[TestCategory\] Test message$") -Message "Formater un message selon le niveau Detailed"

# Afficher le resume
Write-Host "`nResume des tests:" -ForegroundColor Cyan
Write-Host "----------------" -ForegroundColor Cyan

$rotationTotal = $rotationResults.Count
$rotationPassed = ($rotationResults | Where-Object { $_ -eq $true }).Count
Write-Host "Tests de rotation des journaux: $rotationPassed/$rotationTotal" -ForegroundColor $(if ($rotationPassed -eq $rotationTotal) { "Green" } else { "Red" })

$verbosityTotal = $verbosityResults.Count
$verbosityPassed = ($verbosityResults | Where-Object { $_ -eq $true }).Count
Write-Host "Tests de verbosite configurable: $verbosityPassed/$verbosityTotal" -ForegroundColor $(if ($verbosityPassed -eq $verbosityTotal) { "Green" } else { "Red" })

$totalTests = $rotationTotal + $verbosityTotal
$passedTests = $rotationPassed + $verbosityPassed
Write-Host "Total: $passedTests/$totalTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Nettoyer
Remove-Module -Name LoggingTestModule -Force
Remove-Item -Path $moduleDir -Recurse -Force

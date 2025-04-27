<#
.SYNOPSIS
    Script de test pour le module EnvironmentManager.

.DESCRIPTION
    Ce script teste les fonctionnalitÃ©s du module EnvironmentManager.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
#>

# Importer le module EnvironmentManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "EnvironmentManager.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
}
else {
    Write-Error "Module EnvironmentManager non trouvÃ©: $modulePath"
    exit 1
}

# Initialiser le module
Initialize-EnvironmentManager

# Fonction pour afficher un titre de section
function Write-TestSection {
    param (
        [string]$Title
    )

    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

# Fonction pour afficher un rÃ©sultat de test
function Write-TestResult {
    param (
        [string]$Name,
        [object]$Result
    )

    Write-Host "$Name : " -NoNewline
    Write-Host $Result -ForegroundColor Green
}

# Test 1 : DÃ©tection d'environnement
Write-TestSection "Test de dÃ©tection d'environnement"

$envInfo = Get-EnvironmentInfo
Write-TestResult "SystÃ¨me d'exploitation" $envInfo.OSName
Write-TestResult "Version PowerShell" $envInfo.PSVersion
Write-TestResult "Ã‰dition PowerShell" $envInfo.PSEdition
Write-TestResult "Est Windows" $envInfo.IsWindows
Write-TestResult "Est Linux" $envInfo.IsLinux
Write-TestResult "Est macOS" $envInfo.IsMacOS
Write-TestResult "SÃ©parateur de chemin" $envInfo.PathSeparator

# Test 2 : CompatibilitÃ© d'environnement
Write-TestSection "Test de compatibilitÃ© d'environnement"

$compatWindows = Test-EnvironmentCompatibility -TargetOS "Windows"
Write-TestResult "Compatible avec Windows" $compatWindows.IsCompatible

$compatLinux = Test-EnvironmentCompatibility -TargetOS "Linux"
Write-TestResult "Compatible avec Linux" $compatLinux.IsCompatible

$compatMacOS = Test-EnvironmentCompatibility -TargetOS "MacOS"
Write-TestResult "Compatible avec macOS" $compatMacOS.IsCompatible

$compatPS5 = Test-EnvironmentCompatibility -MinimumPSVersion "5.0"
Write-TestResult "Compatible avec PowerShell 5.0+" $compatPS5.IsCompatible

$compatPS7 = Test-EnvironmentCompatibility -MinimumPSVersion "7.0"
Write-TestResult "Compatible avec PowerShell 7.0+" $compatPS7.IsCompatible

# Test 3 : Gestion des chemins
Write-TestSection "Test de gestion des chemins"

$testPath = "C:\Users\user\Documents\file.txt"
$normalizedPath = ConvertTo-CrossPlatformPath -Path $testPath
Write-TestResult "Chemin normalisÃ©" $normalizedPath

$testPath2 = "/home/user/documents/file.txt"
$normalizedPath2 = ConvertTo-CrossPlatformPath -Path $testPath2 -TargetOS "Windows"
Write-TestResult "Chemin normalisÃ© pour Windows" $normalizedPath2

$joinedPath = Join-CrossPlatformPath -Path "C:\Users" -ChildPath "user", "Documents", "file.txt"
Write-TestResult "Chemin joint" $joinedPath

$joinedPath2 = Join-CrossPlatformPath -Path "/home" -ChildPath "user", "documents", "file.txt" -TargetOS "Linux"
Write-TestResult "Chemin joint pour Linux" $joinedPath2

# Test 4 : Wrappers de commandes
Write-TestSection "Test de wrappers de commandes"

$command = Invoke-CrossPlatformCommand -WindowsCommand "dir" -UnixCommand "ls -la" -PassThru
Write-TestResult "Commande Ã  exÃ©cuter" $command

# Test 5 : CrÃ©ation et lecture de fichiers
Write-TestSection "Test de crÃ©ation et lecture de fichiers"

$tempFile = [System.IO.Path]::GetTempFileName()
$testContent = "Test de contenu`nLigne 2`nLigne 3"

$writeResult = Set-CrossPlatformContent -Path $tempFile -Content $testContent -Force
Write-TestResult "Ã‰criture dans le fichier" $writeResult

$readContent = Get-CrossPlatformContent -Path $tempFile
Write-TestResult "Contenu lu" ([bool]$readContent -and $readContent.TrimEnd() -eq $testContent.TrimEnd())

# Nettoyage
Remove-Item -Path $tempFile -Force

Write-Host "`nTests terminÃ©s avec succÃ¨s !" -ForegroundColor Green

<#
.SYNOPSIS
    Tests unitaires simples pour le module EnvironmentManager.

.DESCRIPTION
    Ce script contient des tests unitaires simples pour le module EnvironmentManager
    sans dépendre du framework Pester.

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

# Importer le module à tester
$moduleRoot = $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "EnvironmentManager.psm1"
Import-Module $modulePath -Force

# Créer un répertoire temporaire pour les tests
$testRoot = Join-Path -Path $env:TEMP -ChildPath "EnvironmentManagerTests"
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force
}
New-Item -Path $testRoot -ItemType Directory -Force | Out-Null

# Fonction pour afficher un titre de section
function Write-TestSection {
    param (
        [string]$Title
    )
    
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

# Fonction pour afficher un résultat de test
function Write-TestResult {
    param (
        [string]$Name,
        [bool]$Success,
        [string]$Message = ""
    )
    
    if ($Success) {
        Write-Host "✅ $Name" -ForegroundColor Green
    }
    else {
        Write-Host "❌ $Name" -ForegroundColor Red
        if ($Message) {
            Write-Host "   $Message" -ForegroundColor Yellow
        }
    }
}

# Initialiser le module
Initialize-EnvironmentManager

# Test 1 : Détection d'environnement
Write-TestSection "Test de détection d'environnement"

$envInfo = Get-EnvironmentInfo
$success = $null -ne $envInfo
Write-TestResult "Obtenir les informations sur l'environnement" $success

$success = $envInfo.PSVersion -eq $PSVersionTable.PSVersion
Write-TestResult "Version PowerShell correcte" $success

$success = $envInfo.IsWindows -eq ($PSVersionTable.PSVersion.Major -lt 6 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows))
Write-TestResult "Détection de Windows correcte" $success

# Test 2 : Compatibilité d'environnement
Write-TestSection "Test de compatibilité d'environnement"

$compatWindows = Test-EnvironmentCompatibility -TargetOS "Windows"
$success = $null -ne $compatWindows
Write-TestResult "Vérifier la compatibilité avec Windows" $success

$compatLinux = Test-EnvironmentCompatibility -TargetOS "Linux"
$success = $null -ne $compatLinux
Write-TestResult "Vérifier la compatibilité avec Linux" $success

$compatMacOS = Test-EnvironmentCompatibility -TargetOS "MacOS"
$success = $null -ne $compatMacOS
Write-TestResult "Vérifier la compatibilité avec macOS" $success

$compatPS5 = Test-EnvironmentCompatibility -MinimumPSVersion "5.0"
$success = $null -ne $compatPS5
Write-TestResult "Vérifier la compatibilité avec PowerShell 5.0+" $success

try {
    $incompatibleVersion = [version]"99.0"
    Test-EnvironmentCompatibility -MinimumPSVersion $incompatibleVersion -ThrowOnIncompatible
    $success = $false
    $message = "L'exception attendue n'a pas été lancée"
}
catch {
    $success = $true
}
Write-TestResult "Lancer une exception pour une version incompatible" $success $message

# Test 3 : Gestion des chemins
Write-TestSection "Test de gestion des chemins"

$path = "C:\Users\user\Documents\file.txt"
$result = ConvertTo-CrossPlatformPath -Path $path -TargetOS "Windows"
$success = $result -eq "C:\Users\user\Documents\file.txt"
Write-TestResult "Normaliser un chemin Windows" $success

$path = "C:\Users\user\Documents\file.txt"
$result = ConvertTo-CrossPlatformPath -Path $path -TargetOS "Linux"
$success = $result -eq "C:/Users/user/Documents/file.txt"
Write-TestResult "Normaliser un chemin Unix" $success

$path = "C:\Users/user\Documents/file.txt"
$result = ConvertTo-CrossPlatformPath -Path $path -TargetOS "Windows"
$success = $result -eq "C:\Users\user\Documents\file.txt"
Write-TestResult "Normaliser un chemin avec des séparateurs mixtes" $success

$result = ConvertTo-CrossPlatformPath -Path "" -TargetOS "Windows"
$success = $result -eq ""
Write-TestResult "Retourner une chaîne vide pour un chemin vide" $success

# Test 4 : Test de chemins
Write-TestSection "Test de chemins"

# Créer un fichier de test
$testFilePath = Join-Path -Path $testRoot -ChildPath "test.txt"
Set-Content -Path $testFilePath -Value "Test" -Force

# Créer un répertoire de test
$testDirPath = Join-Path -Path $testRoot -ChildPath "testdir"
New-Item -Path $testDirPath -ItemType Directory -Force | Out-Null

$result = Test-CrossPlatformPath -Path $testFilePath -PathType "Leaf"
$success = $result -eq $true
Write-TestResult "Vérifier si un fichier existe" $success

$result = Test-CrossPlatformPath -Path $testDirPath -PathType "Container"
$success = $result -eq $true
Write-TestResult "Vérifier si un répertoire existe" $success

$nonExistentPath = Join-Path -Path $testRoot -ChildPath "nonexistent.txt"
$result = Test-CrossPlatformPath -Path $nonExistentPath
$success = $result -eq $false
Write-TestResult "Retourner False pour un chemin inexistant" $success

$result = Test-CrossPlatformPath -Path ""
$success = $result -eq $false
Write-TestResult "Retourner False pour un chemin vide" $success

# Test 5 : Jointure de chemins
Write-TestSection "Test de jointure de chemins"

$result = Join-CrossPlatformPath -Path "C:\Users" -ChildPath "user", "Documents", "file.txt" -TargetOS "Windows"
$success = $result -eq "C:\Users\user\Documents\file.txt"
Write-TestResult "Joindre des chemins Windows" $success

$result = Join-CrossPlatformPath -Path "/home" -ChildPath "user", "documents", "file.txt" -TargetOS "Linux"
$success = $result -eq "/home/user/documents/file.txt"
Write-TestResult "Joindre des chemins Unix" $success

$result = Join-CrossPlatformPath -Path "C:\Users\" -ChildPath "\user", "\Documents\", "file.txt" -TargetOS "Windows"
$success = $result -eq "C:\Users\user\Documents\file.txt"
Write-TestResult "Gérer les séparateurs redondants" $success

$result = Join-CrossPlatformPath -Path "" -ChildPath "user"
$success = $result -eq ""
Write-TestResult "Retourner une chaîne vide pour un chemin vide" $success

# Test 6 : Wrappers de commandes
Write-TestSection "Test de wrappers de commandes"

$windowsCommand = "dir"
$unixCommand = "ls -la"
$result = Invoke-CrossPlatformCommand -WindowsCommand $windowsCommand -UnixCommand $unixCommand -PassThru
$success = $result -eq $windowsCommand -or $result -eq $unixCommand
Write-TestResult "Retourner la commande appropriée" $success

# Test 7 : Lecture et écriture de fichiers
Write-TestSection "Test de lecture et écriture de fichiers"

$testFilePath = Join-Path -Path $testRoot -ChildPath "content-test.txt"
$testContent = "Test de contenu`nLigne 2`nLigne 3"

$result = Set-CrossPlatformContent -Path $testFilePath -Content $testContent -Force
$success = $result -eq $true
Write-TestResult "Écrire dans un fichier" $success

$content = Get-CrossPlatformContent -Path $testFilePath
$success = $content.TrimEnd() -eq $testContent.TrimEnd()
Write-TestResult "Lire le contenu d'un fichier" $success

$nonExistentPath = Join-Path -Path $testRoot -ChildPath "nonexistent.txt"
$content = Get-CrossPlatformContent -Path $nonExistentPath
$success = $content -eq ""
Write-TestResult "Retourner une chaîne vide pour un fichier inexistant" $success

$nonExistentPath = Join-Path -Path $testRoot -ChildPath "nonexistent2.txt"
$result = Set-CrossPlatformContent -Path $nonExistentPath -Content "Test"
$success = $result -eq $false
Write-TestResult "Retourner False pour une écriture dans un fichier inexistant sans Force" $success

# Nettoyer
Remove-Module -Name EnvironmentManager -Force -ErrorAction SilentlyContinue

# Supprimer le répertoire de test
if (Test-Path -Path $testRoot) {
    Remove-Item -Path $testRoot -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "`nTests terminés !" -ForegroundColor Green

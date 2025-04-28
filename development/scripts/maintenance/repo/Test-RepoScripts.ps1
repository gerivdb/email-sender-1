#Requires -Version 5.1
<#
.SYNOPSIS
    Teste les scripts de rÃ©organisation et standardisation du dÃ©pÃ´t
.DESCRIPTION
    Ce script exÃ©cute les tests de base pour vÃ©rifier que les scripts de
    rÃ©organisation et standardisation du dÃ©pÃ´t fonctionnent correctement.
.EXAMPLE
    .\Test-RepoScripts.ps1
.NOTES
    Auteur: Augment Agent
    Version: 1.0
#>

[CmdletBinding()]
param()

# DÃ©finir les chemins des scripts
$testRepoStructurePath = Join-Path -Path $PSScriptRoot -ChildPath "Test-RepoStructure.ps1"
$reorganizeRepositoryPath = Join-Path -Path $PSScriptRoot -ChildPath "Reorganize-Repository.ps1"
$cleanRepositoryPath = Join-Path -Path $PSScriptRoot -ChildPath "Clean-Repository.ps1"

# VÃ©rifier que les scripts existent
Write-Host "VÃ©rification des scripts..." -ForegroundColor Cyan
$scriptsExist = $true

if (-not (Test-Path -Path $testRepoStructurePath)) {
    Write-Host "Le script Test-RepoStructure.ps1 n'existe pas: $testRepoStructurePath" -ForegroundColor Red
    $scriptsExist = $false
}

if (-not (Test-Path -Path $reorganizeRepositoryPath)) {
    Write-Host "Le script Reorganize-Repository.ps1 n'existe pas: $reorganizeRepositoryPath" -ForegroundColor Red
    $scriptsExist = $false
}

if (-not (Test-Path -Path $cleanRepositoryPath)) {
    Write-Host "Le script Clean-Repository.ps1 n'existe pas: $cleanRepositoryPath" -ForegroundColor Red
    $scriptsExist = $false
}

if (-not $scriptsExist) {
    Write-Host "Certains scripts n'existent pas. Veuillez les crÃ©er avant d'exÃ©cuter ce test." -ForegroundColor Red
    exit 1
}

Write-Host "Tous les scripts existent." -ForegroundColor Green

# CrÃ©er un dossier de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "RepoTest-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

Write-Host "Dossier de test crÃ©Ã©: $testDir" -ForegroundColor Cyan

# CrÃ©er une structure de test
$testFolders = @(
    "scripts",
    "scripts\old",
    "scripts\utils",
    "docs"
)

foreach ($folder in $testFolders) {
    New-Item -Path (Join-Path -Path $testDir -ChildPath $folder) -ItemType Directory -Force | Out-Null
}

# CrÃ©er des fichiers de test
$testFiles = @(
    @{
        Path = Join-Path -Path $testDir -ChildPath "scripts\Test-Script.ps1"
        Content = "# Test script`nWrite-Host 'Hello, World!'"
    },
    @{
        Path = Join-Path -Path $testDir -ChildPath "scripts\old\Old-Script.ps1"
        Content = "# Old script`nWrite-Host 'This is an old script'"
    },
    @{
        Path = Join-Path -Path $testDir -ChildPath "scripts\utils\Utility.ps1"
        Content = "# Utility script`nfunction Get-Utility { return 'Utility' }"
    },
    @{
        Path = Join-Path -Path $testDir -ChildPath "docs\README.md"
        Content = "# Test Repository`nThis is a test repository."
    }
)

foreach ($file in $testFiles) {
    Set-Content -Path $file.Path -Value $file.Content -Encoding UTF8
}

Write-Host "Fichiers de test crÃ©Ã©s." -ForegroundColor Green

# Tester Test-RepoStructure.ps1
Write-Host "`nTest 1: ExÃ©cution de Test-RepoStructure.ps1..." -ForegroundColor Cyan
try {
    & $testRepoStructurePath -Path $testDir -ReportPath "report.md"
    Write-Host "Test-RepoStructure.ps1 exÃ©cutÃ© avec succÃ¨s." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'exÃ©cution de Test-RepoStructure.ps1: $_" -ForegroundColor Red
}

# Tester Reorganize-Repository.ps1
Write-Host "`nTest 2: ExÃ©cution de Reorganize-Repository.ps1..." -ForegroundColor Cyan
try {
    & $reorganizeRepositoryPath -Path $testDir -LogPath "log.log" -DryRun
    Write-Host "Reorganize-Repository.ps1 exÃ©cutÃ© avec succÃ¨s en mode simulation." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'exÃ©cution de Reorganize-Repository.ps1: $_" -ForegroundColor Red
}

# Tester Clean-Repository.ps1
Write-Host "`nTest 3: ExÃ©cution de Clean-Repository.ps1..." -ForegroundColor Cyan
try {
    & $cleanRepositoryPath -Path $testDir -ArchivePath "archive" -ReportPath "cleanup.md" -DryRun
    Write-Host "Clean-Repository.ps1 exÃ©cutÃ© avec succÃ¨s en mode simulation." -ForegroundColor Green
} catch {
    Write-Host "Erreur lors de l'exÃ©cution de Clean-Repository.ps1: $_" -ForegroundColor Red
}

# Nettoyer le dossier de test
Write-Host "`nNettoyage du dossier de test..." -ForegroundColor Cyan
Remove-Item -Path $testDir -Recurse -Force

Write-Host "`nTests terminÃ©s." -ForegroundColor Green

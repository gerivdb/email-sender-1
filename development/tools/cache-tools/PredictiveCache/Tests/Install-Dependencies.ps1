<#
.SYNOPSIS
    Installe les dÃ©pendances nÃ©cessaires pour les tests du cache prÃ©dictif.
.DESCRIPTION
    Ce script installe les dÃ©pendances nÃ©cessaires pour exÃ©cuter les tests
    du systÃ¨me de cache prÃ©dictif, notamment SQLite et Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# VÃ©rifier si on est en mode administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Ce script doit Ãªtre exÃ©cutÃ© en tant qu'administrateur pour installer certaines dÃ©pendances."
    Write-Warning "Veuillez relancer PowerShell en tant qu'administrateur et rÃ©exÃ©cuter ce script."
    exit
}

# CrÃ©er un rÃ©pertoire pour les bibliothÃ¨ques
$libPath = Join-Path -Path $PSScriptRoot -ChildPath "..\lib"
if (-not (Test-Path -Path $libPath)) {
    New-Item -Path $libPath -ItemType Directory -Force | Out-Null
}

# Installer Pester si nÃ©cessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation de Pester..." -ForegroundColor Cyan
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# TÃ©lÃ©charger et installer SQLite
$sqliteUrl = "https://system.data.sqlite.org/blobs/1.0.118.0/sqlite-netFx-full-source-1.0.118.0.zip"
$sqliteZipPath = Join-Path -Path $env:TEMP -ChildPath "sqlite.zip"
$sqliteExtractPath = Join-Path -Path $env:TEMP -ChildPath "sqlite"

# CrÃ©er le rÃ©pertoire d'extraction si nÃ©cessaire
if (-not (Test-Path -Path $sqliteExtractPath)) {
    New-Item -Path $sqliteExtractPath -ItemType Directory -Force | Out-Null
}

# TÃ©lÃ©charger SQLite
Write-Host "TÃ©lÃ©chargement de SQLite..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $sqliteUrl -OutFile $sqliteZipPath

# Extraire SQLite
Write-Host "Extraction de SQLite..." -ForegroundColor Cyan
Expand-Archive -Path $sqliteZipPath -DestinationPath $sqliteExtractPath -Force

# Copier les DLL nÃ©cessaires
$sqliteDllPath = Get-ChildItem -Path $sqliteExtractPath -Filter "System.Data.SQLite.dll" -Recurse | Select-Object -First 1 -ExpandProperty FullName
if ($sqliteDllPath) {
    Write-Host "Copie de System.Data.SQLite.dll vers le rÃ©pertoire lib..." -ForegroundColor Cyan
    Copy-Item -Path $sqliteDllPath -Destination $libPath -Force
} else {
    Write-Warning "Impossible de trouver System.Data.SQLite.dll dans l'archive tÃ©lÃ©chargÃ©e."
    Write-Warning "Veuillez tÃ©lÃ©charger et installer SQLite manuellement."
}

# Nettoyer les fichiers temporaires
Remove-Item -Path $sqliteZipPath -Force -ErrorAction SilentlyContinue
Remove-Item -Path $sqliteExtractPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Installation des dÃ©pendances terminÃ©e." -ForegroundColor Green
Write-Host "Vous pouvez maintenant exÃ©cuter les tests avec Run-AllTests.ps1." -ForegroundColor Green

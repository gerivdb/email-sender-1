<#
.SYNOPSIS
    Installe les dépendances nécessaires pour les tests du cache prédictif.
.DESCRIPTION
    Ce script installe les dépendances nécessaires pour exécuter les tests
    du système de cache prédictif, notamment SQLite et Pester.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 12/04/2025
#>

# Vérifier si on est en mode administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Warning "Ce script doit être exécuté en tant qu'administrateur pour installer certaines dépendances."
    Write-Warning "Veuillez relancer PowerShell en tant qu'administrateur et réexécuter ce script."
    exit
}

# Créer un répertoire pour les bibliothèques
$libPath = Join-Path -Path $PSScriptRoot -ChildPath "..\lib"
if (-not (Test-Path -Path $libPath)) {
    New-Item -Path $libPath -ItemType Directory -Force | Out-Null
}

# Installer Pester si nécessaire
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Host "Installation de Pester..." -ForegroundColor Cyan
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

# Télécharger et installer SQLite
$sqliteUrl = "https://system.data.sqlite.org/blobs/1.0.118.0/sqlite-netFx-full-source-1.0.118.0.zip"
$sqliteZipPath = Join-Path -Path $env:TEMP -ChildPath "sqlite.zip"
$sqliteExtractPath = Join-Path -Path $env:TEMP -ChildPath "sqlite"

# Créer le répertoire d'extraction si nécessaire
if (-not (Test-Path -Path $sqliteExtractPath)) {
    New-Item -Path $sqliteExtractPath -ItemType Directory -Force | Out-Null
}

# Télécharger SQLite
Write-Host "Téléchargement de SQLite..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $sqliteUrl -OutFile $sqliteZipPath

# Extraire SQLite
Write-Host "Extraction de SQLite..." -ForegroundColor Cyan
Expand-Archive -Path $sqliteZipPath -DestinationPath $sqliteExtractPath -Force

# Copier les DLL nécessaires
$sqliteDllPath = Get-ChildItem -Path $sqliteExtractPath -Filter "System.Data.SQLite.dll" -Recurse | Select-Object -First 1 -ExpandProperty FullName
if ($sqliteDllPath) {
    Write-Host "Copie de System.Data.SQLite.dll vers le répertoire lib..." -ForegroundColor Cyan
    Copy-Item -Path $sqliteDllPath -Destination $libPath -Force
} else {
    Write-Warning "Impossible de trouver System.Data.SQLite.dll dans l'archive téléchargée."
    Write-Warning "Veuillez télécharger et installer SQLite manuellement."
}

# Nettoyer les fichiers temporaires
Remove-Item -Path $sqliteZipPath -Force -ErrorAction SilentlyContinue
Remove-Item -Path $sqliteExtractPath -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Installation des dépendances terminée." -ForegroundColor Green
Write-Host "Vous pouvez maintenant exécuter les tests avec Run-AllTests.ps1." -ForegroundColor Green

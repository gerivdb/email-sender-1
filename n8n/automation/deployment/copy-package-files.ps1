<#
.SYNOPSIS
    Script pour copier les fichiers package.json et package-lock.json dans la nouvelle structure.

.DESCRIPTION
    Ce script copie les fichiers package.json et package-lock.json de la racine du projet vers la nouvelle structure n8n.

.EXAMPLE
    .\copy-package-files.ps1
#>

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n-new"

# Copier le fichier package.json
$packageJsonPath = Join-Path -Path $rootPath -ChildPath "package.json"
$n8nPackageJsonPath = Join-Path -Path $n8nPath -ChildPath "package.json"

if (Test-Path -Path $packageJsonPath) {
    Copy-Item -Path $packageJsonPath -Destination $n8nPackageJsonPath -Force
    Write-Host "Fichier package.json copié: $packageJsonPath -> $n8nPackageJsonPath"
} else {
    Write-Warning "Le fichier package.json n'existe pas: $packageJsonPath"
}

# Copier le fichier package-lock.json
$packageLockJsonPath = Join-Path -Path $rootPath -ChildPath "package-lock.json"
$n8nPackageLockJsonPath = Join-Path -Path $n8nPath -ChildPath "package-lock.json"

if (Test-Path -Path $packageLockJsonPath) {
    Copy-Item -Path $packageLockJsonPath -Destination $n8nPackageLockJsonPath -Force
    Write-Host "Fichier package-lock.json copié: $packageLockJsonPath -> $n8nPackageLockJsonPath"
} else {
    Write-Warning "Le fichier package-lock.json n'existe pas: $packageLockJsonPath"
}

Write-Host ""
Write-Host "Copie des fichiers package terminée."

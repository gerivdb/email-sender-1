<#
.SYNOPSIS
    Script pour finaliser la consolidation des dossiers n8n.

.DESCRIPTION
    Ce script renomme les dossiers n8n et n8n-new, et nettoie les fichiers .cmd Ã  la racine.

.PARAMETER Force
    Force la suppression des fichiers .cmd Ã  la racine sans demander de confirmation.

.EXAMPLE
    .\finalize-n8n-consolidation.ps1
    .\finalize-n8n-consolidation.ps1 -Force
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# DÃ©finir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$n8nNewPath = Join-Path -Path $rootPath -ChildPath "n8n-new"
$n8nSourcePath = Join-Path -Path $rootPath -ChildPath "n8n-source"

# Ã‰tape 1: Renommer les dossiers
Write-Host ""
Write-Host "Ã‰tape 1: Renommage des dossiers..."
Write-Host "------------------------------------------------------------"

# VÃ©rifier si le dossier n8n-source existe dÃ©jÃ 
if (Test-Path -Path $n8nSourcePath) {
    Write-Host "Le dossier n8n-source existe dÃ©jÃ . Il sera supprimÃ©."
    Remove-Item -Path $n8nSourcePath -Recurse -Force
}

# Renommer n8n en n8n-source
if (Test-Path -Path $n8nPath) {
    try {
        Rename-Item -Path $n8nPath -NewName "n8n-source" -Force
        Write-Host "Dossier n8n renommÃ© en n8n-source."
    } catch {
        Write-Error "Erreur lors du renommage du dossier n8n en n8n-source : $_"
        Write-Host "Veuillez fermer toutes les applications qui pourraient utiliser ces dossiers et rÃ©essayer."
        exit 1
    }
}

# Renommer n8n-new en n8n
if (Test-Path -Path $n8nNewPath) {
    try {
        Rename-Item -Path $n8nNewPath -NewName "n8n" -Force
        Write-Host "Dossier n8n-new renommÃ© en n8n."
    } catch {
        Write-Error "Erreur lors du renommage du dossier n8n-new en n8n : $_"
        Write-Host "Veuillez fermer toutes les applications qui pourraient utiliser ces dossiers et rÃ©essayer."
        exit 1
    }
}

# Ã‰tape 2: Nettoyer les fichiers .cmd Ã  la racine
Write-Host ""
Write-Host "Ã‰tape 2: Nettoyage des fichiers .cmd Ã  la racine..."
Write-Host "------------------------------------------------------------"

# Obtenir la liste des fichiers .cmd Ã  la racine
$cmdFiles = Get-ChildItem -Path $rootPath -Filter "*.cmd" | Where-Object { $_.Name -ne "consolidate-n8n.cmd" -and $_.Name -ne "finalize-n8n-consolidation.cmd" }

if ($cmdFiles.Count -eq 0) {
    Write-Host "Aucun fichier .cmd Ã  nettoyer."
    exit 0
}

# Demander confirmation avant de supprimer les fichiers
if (-not $Force) {
    Write-Host "Les fichiers .cmd suivants seront supprimÃ©s :"
    foreach ($file in $cmdFiles) {
        Write-Host "- $($file.Name)"
    }
    
    $confirmation = Read-Host "ÃŠtes-vous sÃ»r de vouloir supprimer ces fichiers ? (O/N)"
    if ($confirmation -ne "O") {
        Write-Host "Suppression annulÃ©e."
        exit 0
    }
}

# Supprimer les fichiers .cmd
foreach ($file in $cmdFiles) {
    try {
        Remove-Item -Path $file.FullName -Force
        Write-Host "Fichier supprimÃ© : $($file.Name)"
    } catch {
        Write-Error "Erreur lors de la suppression du fichier '$($file.Name)' : $_"
    }
}

Write-Host ""
Write-Host "Consolidation finalisÃ©e."
Write-Host "Le dossier n8n contient maintenant la nouvelle structure organisÃ©e."
Write-Host "Le dossier n8n-source contient le code source original de n8n."
Write-Host "Pour utiliser n8n, exÃ©cutez : .\n8n\cmd\start\start-n8n-local.cmd"

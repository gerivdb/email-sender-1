<#
.SYNOPSIS
    Script pour finaliser la consolidation des dossiers n8n.

.DESCRIPTION
    Ce script renomme les dossiers n8n et n8n-new, et nettoie les fichiers .cmd à la racine.

.PARAMETER Force
    Force la suppression des fichiers .cmd à la racine sans demander de confirmation.

.EXAMPLE
    .\finalize-n8n-consolidation.ps1
    .\finalize-n8n-consolidation.ps1 -Force
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$n8nNewPath = Join-Path -Path $rootPath -ChildPath "n8n-new"
$n8nSourcePath = Join-Path -Path $rootPath -ChildPath "n8n-source"

# Étape 1: Renommer les dossiers
Write-Host ""
Write-Host "Étape 1: Renommage des dossiers..."
Write-Host "------------------------------------------------------------"

# Vérifier si le dossier n8n-source existe déjà
if (Test-Path -Path $n8nSourcePath) {
    Write-Host "Le dossier n8n-source existe déjà. Il sera supprimé."
    Remove-Item -Path $n8nSourcePath -Recurse -Force
}

# Renommer n8n en n8n-source
if (Test-Path -Path $n8nPath) {
    try {
        Rename-Item -Path $n8nPath -NewName "n8n-source" -Force
        Write-Host "Dossier n8n renommé en n8n-source."
    } catch {
        Write-Error "Erreur lors du renommage du dossier n8n en n8n-source : $_"
        Write-Host "Veuillez fermer toutes les applications qui pourraient utiliser ces dossiers et réessayer."
        exit 1
    }
}

# Renommer n8n-new en n8n
if (Test-Path -Path $n8nNewPath) {
    try {
        Rename-Item -Path $n8nNewPath -NewName "n8n" -Force
        Write-Host "Dossier n8n-new renommé en n8n."
    } catch {
        Write-Error "Erreur lors du renommage du dossier n8n-new en n8n : $_"
        Write-Host "Veuillez fermer toutes les applications qui pourraient utiliser ces dossiers et réessayer."
        exit 1
    }
}

# Étape 2: Nettoyer les fichiers .cmd à la racine
Write-Host ""
Write-Host "Étape 2: Nettoyage des fichiers .cmd à la racine..."
Write-Host "------------------------------------------------------------"

# Obtenir la liste des fichiers .cmd à la racine
$cmdFiles = Get-ChildItem -Path $rootPath -Filter "*.cmd" | Where-Object { $_.Name -ne "consolidate-n8n.cmd" -and $_.Name -ne "finalize-n8n-consolidation.cmd" }

if ($cmdFiles.Count -eq 0) {
    Write-Host "Aucun fichier .cmd à nettoyer."
    exit 0
}

# Demander confirmation avant de supprimer les fichiers
if (-not $Force) {
    Write-Host "Les fichiers .cmd suivants seront supprimés :"
    foreach ($file in $cmdFiles) {
        Write-Host "- $($file.Name)"
    }
    
    $confirmation = Read-Host "Êtes-vous sûr de vouloir supprimer ces fichiers ? (O/N)"
    if ($confirmation -ne "O") {
        Write-Host "Suppression annulée."
        exit 0
    }
}

# Supprimer les fichiers .cmd
foreach ($file in $cmdFiles) {
    try {
        Remove-Item -Path $file.FullName -Force
        Write-Host "Fichier supprimé : $($file.Name)"
    } catch {
        Write-Error "Erreur lors de la suppression du fichier '$($file.Name)' : $_"
    }
}

Write-Host ""
Write-Host "Consolidation finalisée."
Write-Host "Le dossier n8n contient maintenant la nouvelle structure organisée."
Write-Host "Le dossier n8n-source contient le code source original de n8n."
Write-Host "Pour utiliser n8n, exécutez : .\n8n\cmd\start\start-n8n-local.cmd"

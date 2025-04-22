<#
.SYNOPSIS
    Script pour finaliser la migration vers la nouvelle structure n8n.

.DESCRIPTION
    Ce script renomme le dossier n8n-new en n8n et supprime les anciens dossiers n8n.

.PARAMETER KeepOldFolders
    Conserve les anciens dossiers n8n au lieu de les supprimer.

.EXAMPLE
    .\finalize-migration.ps1
    .\finalize-migration.ps1 -KeepOldFolders
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$KeepOldFolders
)

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$newN8nPath = Join-Path -Path $rootPath -ChildPath "n8n-new"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$oldN8nIdePath = Join-Path -Path $rootPath -ChildPath "n8n-ide-integration"
$oldN8nUnifiedPath = Join-Path -Path $rootPath -ChildPath "n8n-unified"
$oldN8nDataPath = Join-Path -Path $rootPath -ChildPath "n8n-data"
$oldAllWorkflowsPath = Join-Path -Path $rootPath -ChildPath "all-workflows"

# Vérifier si le dossier n8n-new existe
if (-not (Test-Path -Path $newN8nPath)) {
    Write-Error "Le dossier n8n-new n'existe pas. Veuillez exécuter la migration d'abord."
    exit 1
}

# Vérifier si le dossier n8n existe déjà
if (Test-Path -Path $n8nPath) {
    Write-Warning "Le dossier n8n existe déjà. Il sera renommé en n8n-old."
    $oldN8nPath = Join-Path -Path $rootPath -ChildPath "n8n-old"
    
    # Supprimer l'ancien dossier n8n-old s'il existe
    if (Test-Path -Path $oldN8nPath) {
        Write-Host "Suppression de l'ancien dossier n8n-old..."
        Remove-Item -Path $oldN8nPath -Recurse -Force
    }
    
    # Renommer le dossier n8n en n8n-old
    Rename-Item -Path $n8nPath -NewName "n8n-old"
    Write-Host "Dossier n8n renommé en n8n-old."
}

# Renommer le dossier n8n-new en n8n
Write-Host "Renommage du dossier n8n-new en n8n..."
Rename-Item -Path $newN8nPath -NewName "n8n"
Write-Host "Dossier n8n-new renommé en n8n."

# Supprimer les anciens dossiers si demandé
if (-not $KeepOldFolders) {
    Write-Host "Suppression des anciens dossiers n8n..."
    
    $oldFolders = @(
        $oldN8nIdePath,
        $oldN8nUnifiedPath,
        $oldN8nDataPath,
        $oldAllWorkflowsPath
    )
    
    foreach ($folder in $oldFolders) {
        if (Test-Path -Path $folder) {
            Write-Host "Suppression du dossier $folder..."
            Remove-Item -Path $folder -Recurse -Force
            Write-Host "Dossier $folder supprimé."
        }
    }
} else {
    Write-Host "Les anciens dossiers n8n ont été conservés."
}

Write-Host ""
Write-Host "Migration finalisée."
Write-Host "La nouvelle structure n8n est prête à être utilisée."
Write-Host "Pour installer et configurer n8n, exécutez: .\n8n\scripts\setup\install-n8n.ps1"

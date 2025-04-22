<#
.SYNOPSIS
    Script pour renommer les dossiers n8n.

.DESCRIPTION
    Ce script renomme le dossier n8n-new en n8n et renomme l'ancien dossier n8n en n8n-old.
    Il doit être exécuté avec des privilèges d'administrateur.

.EXAMPLE
    .\rename-folders.ps1
#>

# Vérifier si le script est exécuté avec des privilèges d'administrateur
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "Ce script doit être exécuté avec des privilèges d'administrateur."
    Write-Host "Veuillez exécuter PowerShell en tant qu'administrateur et réessayer."
    exit 1
}

# Définir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$newN8nPath = Join-Path -Path $rootPath -ChildPath "n8n-new"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$oldN8nPath = Join-Path -Path $rootPath -ChildPath "n8n-old"

# Vérifier si le dossier n8n-new existe
if (-not (Test-Path -Path $newN8nPath)) {
    Write-Error "Le dossier n8n-new n'existe pas. Veuillez exécuter la migration d'abord."
    exit 1
}

# Vérifier si le dossier n8n existe déjà
if (Test-Path -Path $n8nPath) {
    Write-Host "Le dossier n8n existe déjà. Il sera renommé en n8n-old."
    
    # Supprimer l'ancien dossier n8n-old s'il existe
    if (Test-Path -Path $oldN8nPath) {
        Write-Host "Suppression de l'ancien dossier n8n-old..."
        Remove-Item -Path $oldN8nPath -Recurse -Force -ErrorAction SilentlyContinue
        
        if (Test-Path -Path $oldN8nPath) {
            Write-Error "Impossible de supprimer le dossier n8n-old. Veuillez le supprimer manuellement."
            exit 1
        }
    }
    
    # Renommer le dossier n8n en n8n-old
    try {
        Rename-Item -Path $n8nPath -NewName "n8n-old" -Force -ErrorAction Stop
        Write-Host "Dossier n8n renommé en n8n-old."
    } catch {
        Write-Error "Impossible de renommer le dossier n8n en n8n-old. Erreur: $_"
        Write-Host "Veuillez fermer toutes les applications qui pourraient utiliser ces dossiers et réessayer."
        exit 1
    }
}

# Renommer le dossier n8n-new en n8n
try {
    Rename-Item -Path $newN8nPath -NewName "n8n" -Force -ErrorAction Stop
    Write-Host "Dossier n8n-new renommé en n8n."
} catch {
    Write-Error "Impossible de renommer le dossier n8n-new en n8n. Erreur: $_"
    Write-Host "Veuillez fermer toutes les applications qui pourraient utiliser ces dossiers et réessayer."
    exit 1
}

Write-Host ""
Write-Host "Renommage des dossiers terminé."
Write-Host "La nouvelle structure n8n est prête à être utilisée."
Write-Host "Pour installer et configurer n8n, exécutez: .\n8n\scripts\setup\install-n8n.ps1"

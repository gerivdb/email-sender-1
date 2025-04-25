<#
---
to: D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/maintenance/cleanup/<%= name %>.ps1
---
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    Ce script nettoie <%= cleanupType === 'custom' ? 'les fichiers ' + customPattern : 'les fichiers ' + cleanupType %> 
    dans le répertoire <%= targetDir %><%= recursive ? ' et ses sous-répertoires' : '' %>.
<% if (createBackup) { %>
    Une sauvegarde est créée avant le nettoyage.
<% } %>

.PARAMETER DryRun
    Si spécifié, le script affiche les actions qui seraient effectuées sans les exécuter.

.PARAMETER Force
    Si spécifié, le script supprime les fichiers sans demander de confirmation.

.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuées.

.EXAMPLE
    .\<%= name %>.ps1 -DryRun

.EXAMPLE
    .\<%= name %>.ps1 -Force -LogFile "cleanup.log"

.NOTES
    Auteur: Maintenance Team
    Version: 1.0
    Date de création: <%= new Date().toISOString().split('T')[0] %>
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$LogFile
)

# Définir le répertoire cible
$targetDir = "<%= targetDir %>"
if (-not [System.IO.Path]::IsPathRooted($targetDir)) {
    $targetDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\$targetDir"
}
$targetDir = [System.IO.Path]::GetFullPath($targetDir)

# Vérifier que le répertoire cible existe
if (-not (Test-Path -Path $targetDir -PathType Container)) {
    throw "Le répertoire cible n'existe pas : $targetDir"
}

# Définir les motifs de fichiers à nettoyer
$filePatterns = @(
<% if (cleanupType === 'temp') { %>
    "*.tmp",
    "*.temp",
    "~*",
    "*.cache"
<% } else if (cleanupType === 'logs') { %>
    "*.log",
    "*.log.*",
    "*_log_*",
    "*.trace"
<% } else if (cleanupType === 'backups') { %>
    "*.bak",
    "*.backup",
    "*_backup_*",
    "*.old"
<% } else if (cleanupType === 'duplicates') { %>
    "*_copy*.*",
    "*_copie*.*",
    "*_copy_*.*",
    "*_copie_*.*",
    "* - Copy*.*",
    "* - Copie*.*"
<% } else if (cleanupType === 'empty') { %>
    # Pour les dossiers vides, nous utiliserons une logique spéciale
    "*"
<% } else if (cleanupType === 'custom') { %>
    "<%= customPattern %>"
<% } %>
)

Write-Host "Nettoyage du répertoire : $targetDir" -ForegroundColor Cyan

# Fonction pour journaliser les actions
function Write-Log {
    param (
        [string]$Message
    )
    
    Write-Host $Message
    
    if ($LogFile) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    }
}

# Initialiser le fichier de log
if ($LogFile) {
    if (-not [System.IO.Path]::IsPathRooted($LogFile)) {
        $LogFile = Join-Path -Path $PSScriptRoot -ChildPath $LogFile
    }
    
    $logDir = Split-Path -Path $LogFile -Parent
    if (-not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Nettoyage démarré le $timestamp ===" | Out-File -FilePath $LogFile -Encoding UTF8
    "Répertoire: $targetDir" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "Motifs: $($filePatterns -join ', ')" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "Récursif: <%= recursive ? 'Oui' : 'Non' %>" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

<% if (createBackup) { %>
# Créer une sauvegarde avant le nettoyage
$backupDir = Join-Path -Path $PSScriptRoot -ChildPath "backups"
$backupName = "backup_<%= name %>_$(Get-Date -Format 'yyyyMMdd_HHmmss').zip"
$backupPath = Join-Path -Path $backupDir -ChildPath $backupName

if (-not (Test-Path -Path $backupDir)) {
    New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
}

if ($DryRun) {
    Write-Log "[DRYRUN] Création d'une sauvegarde : $backupPath"
} else {
    if ($PSCmdlet.ShouldProcess($targetDir, "Créer une sauvegarde")) {
        try {
            Compress-Archive -Path $targetDir -DestinationPath $backupPath -Force
            Write-Log "Sauvegarde créée : $backupPath"
        } catch {
            Write-Log "Erreur lors de la création de la sauvegarde : $_"
            if (-not $Force) {
                $continue = $PSCmdlet.ShouldContinue("La sauvegarde a échoué. Voulez-vous continuer le nettoyage sans sauvegarde ?", "Confirmation")
                if (-not $continue) {
                    Write-Log "Nettoyage annulé par l'utilisateur."
                    return
                }
            }
        }
    }
}
<% } %>

# Fonction pour supprimer un fichier
function Remove-FileIfExists {
    param (
        [string]$FilePath
    )
    
    if (Test-Path -Path $FilePath) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Voulez-vous supprimer le fichier : $FilePath ?", "Confirmation")
        }
        
        if ($shouldContinue) {
            if ($DryRun) {
                Write-Log "[DRYRUN] Suppression du fichier : $FilePath"
                return $true
            } else {
                if ($PSCmdlet.ShouldProcess($FilePath, "Supprimer")) {
                    Remove-Item -Path $FilePath -Force
                    Write-Log "Fichier supprimé : $FilePath"
                    return $true
                }
            }
        } else {
            Write-Log "Suppression ignorée : $FilePath"
        }
    }
    
    return $false
}

# Fonction pour supprimer un dossier vide
function Remove-EmptyFolder {
    param (
        [string]$FolderPath
    )
    
    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        return $false
    }
    
    $items = Get-ChildItem -Path $FolderPath -Force
    
    if ($items.Count -eq 0) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Voulez-vous supprimer le dossier vide : $FolderPath ?", "Confirmation")
        }
        
        if ($shouldContinue) {
            if ($DryRun) {
                Write-Log "[DRYRUN] Suppression du dossier vide : $FolderPath"
                return $true
            } else {
                if ($PSCmdlet.ShouldProcess($FolderPath, "Supprimer le dossier vide")) {
                    Remove-Item -Path $FolderPath -Force
                    Write-Log "Dossier vide supprimé : $FolderPath"
                    return $true
                }
            }
        } else {
            Write-Log "Suppression ignorée : $FolderPath"
        }
    }
    
    return $false
}

# Nettoyer les fichiers
$totalFiles = 0
$removedFiles = 0
$removedFolders = 0

<% if (cleanupType === 'empty') { %>
# Récupérer tous les dossiers de manière récursive
$folders = Get-ChildItem -Path $targetDir -Directory -Recurse | Sort-Object -Property FullName -Descending

foreach ($folder in $folders) {
    if (Remove-EmptyFolder -FolderPath $folder.FullName) {
        $removedFolders++
    }
}

Write-Log "Nettoyage terminé. $removedFolders dossiers vides supprimés."
<% } else { %>
foreach ($pattern in $filePatterns) {
    $searchOption = "<%= recursive ? 'Recurse' : 'TopDirectoryOnly' %>"
    $files = Get-ChildItem -Path $targetDir -Filter $pattern -File -<%= recursive ? 'Recurse' : '' %>
    
    $totalFiles += $files.Count
    
    foreach ($file in $files) {
        if (Remove-FileIfExists -FilePath $file.FullName) {
            $removedFiles++
        }
    }
}

Write-Log "Nettoyage terminé. $removedFiles / $totalFiles fichiers supprimés."
<% } %>

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Nettoyage terminé le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
<% if (cleanupType === 'empty') { %>
    "Résultat: $removedFolders dossiers vides supprimés." | Out-File -FilePath $LogFile -Append -Encoding UTF8
<% } else { %>
    "Résultat: $removedFiles / $totalFiles fichiers supprimés." | Out-File -FilePath $LogFile -Append -Encoding UTF8
<% } %>
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "Log de nettoyage enregistré dans : $LogFile" -ForegroundColor Cyan
}

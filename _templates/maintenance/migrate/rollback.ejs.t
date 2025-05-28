<#
---
to: "<%= createRollback ? 'D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/maintenance/migrate/rollback-' + name + '.ps1' : null %>"
---
<#
.SYNOPSIS
    Script de rollback pour <%= description.toLowerCase() %>

.DESCRIPTION
    Ce script annule la migration des fichiers <%= fileType === 'custom' ? customPattern : '*.' + fileType %> 
    en les restaurant du répertoire <%= targetDir %> vers le répertoire <%= sourceDir %>.

.PARAMETER DryRun
    Si spécifié, le script affiche les actions qui seraient effectuées sans les exécuter.

.PARAMETER Force
    Si spécifié, le script écrase les fichiers existants sans demander de confirmation.

.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuées.

.EXAMPLE
    .\rollback-<%= name %>.ps1 -DryRun

.EXAMPLE
    .\rollback-<%= name %>.ps1 -Force -LogFile "rollback.log"

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

# Définir les répertoires source et cible (inversés pour le rollback)
$sourceDir = "<%= targetDir %>"
$targetDir = "<%= sourceDir %>"

if (-not [System.IO.Path]::IsPathRooted($sourceDir)) {
    $sourceDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\$sourceDir"
}
$sourceDir = [System.IO.Path]::GetFullPath($sourceDir)

if (-not [System.IO.Path]::IsPathRooted($targetDir)) {
    $targetDir = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\$targetDir"
}
$targetDir = [System.IO.Path]::GetFullPath($targetDir)

# Vérifier que les répertoires existent
if (-not (Test-Path -Path $sourceDir -PathType Container)) {
    throw "Le répertoire source n'existe pas : $sourceDir"
}

if (-not (Test-Path -Path $targetDir -PathType Container)) {
    if ($PSCmdlet.ShouldProcess($targetDir, "Créer le répertoire cible")) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
        Write-Host "Répertoire cible créé : $targetDir" -ForegroundColor Green
    }
}

# Définir le motif de fichiers à restaurer
$filePattern = "<%= fileType === 'custom' ? customPattern : '*.' + fileType %>"
if ($filePattern -eq "*.all") {
    $filePattern = "*"
}

Write-Host "Rollback des fichiers $filePattern de $sourceDir vers $targetDir" -ForegroundColor Cyan

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
    "=== Rollback démarré le $timestamp ===" | Out-File -FilePath $LogFile -Encoding UTF8
    "Source: $sourceDir" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "Cible: $targetDir" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "Motif: $filePattern" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# Récupérer les fichiers à restaurer
$files = Get-ChildItem -Path $sourceDir -Filter $filePattern -File -Recurse

# Restaurer les fichiers
$totalFiles = $files.Count
$restoredFiles = 0

Write-Host "Nombre total de fichiers à restaurer : $totalFiles" -ForegroundColor Cyan

foreach ($file in $files) {
    $relativePath = $file.FullName.Replace($sourceDir, "").TrimStart("\")
    $targetSubDir = Split-Path -Path $relativePath -Parent
    
    if ($targetSubDir) {
        $fullTargetSubDir = Join-Path -Path $targetDir -ChildPath $targetSubDir
        
        if (-not (Test-Path -Path $fullTargetSubDir)) {
            if ($DryRun) {
                Write-Log "[DRYRUN] Création du sous-répertoire : $fullTargetSubDir"
            } else {
                if ($PSCmdlet.ShouldProcess($fullTargetSubDir, "Créer le sous-répertoire")) {
                    New-Item -Path $fullTargetSubDir -ItemType Directory -Force | Out-Null
                    Write-Log "Sous-répertoire créé : $fullTargetSubDir"
                }
            }
        }
        
        $targetFilePath = Join-Path -Path $targetDir -ChildPath $relativePath
    } else {
        $targetFilePath = Join-Path -Path $targetDir -ChildPath $file.Name
    }
    
    if ($DryRun) {
        Write-Log "[DRYRUN] Restauration du fichier : $relativePath -> $targetFilePath"
        $restoredFiles++
    } else {
        if ($PSCmdlet.ShouldProcess($file.FullName, "Restaurer vers $targetFilePath")) {
            Copy-Item -Path $file.FullName -Destination $targetFilePath -Force
            Write-Log "Fichier restauré : $relativePath -> $targetFilePath"
            $restoredFiles++
        }
    }
    
    # Afficher la progression
    $percentComplete = [math]::Round(($restoredFiles / $totalFiles) * 100)
    Write-Progress -Activity "Restauration des fichiers" -Status "$restoredFiles / $totalFiles fichiers ($percentComplete%)" -PercentComplete $percentComplete
}

Write-Progress -Activity "Restauration des fichiers" -Completed

# Résumé du rollback
Write-Host "Rollback terminé. $restoredFiles / $totalFiles fichiers restaurés." -ForegroundColor Green

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Rollback terminé le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "Résultat: $restoredFiles / $totalFiles fichiers restaurés." | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "Log de rollback enregistré dans : $LogFile" -ForegroundColor Cyan
}

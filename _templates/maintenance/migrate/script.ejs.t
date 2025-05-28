<#
---
to: D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/maintenance/migrate/<%= name %>.ps1
---
<#
.SYNOPSIS
    <%= description %>

.DESCRIPTION
    Ce script migre les fichiers <%= fileType === 'custom' ? customPattern : '*.' + fileType %> du répertoire <%= sourceDir %> 
    vers le répertoire <%= targetDir %>.

.PARAMETER DryRun
    Si spécifié, le script affiche les actions qui seraient effectuées sans les exécuter.

.PARAMETER Force
    Si spécifié, le script écrase les fichiers existants sans demander de confirmation.

.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuées.

.EXAMPLE
    .\<%= name %>.ps1 -DryRun

.EXAMPLE
    .\<%= name %>.ps1 -Force -LogFile "migration.log"

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

# Définir les répertoires source et cible
$sourceDir = "<%= sourceDir %>"
$targetDir = "<%= targetDir %>"

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

# Définir le motif de fichiers à migrer
$filePattern = "<%= fileType === 'custom' ? customPattern : '*.' + fileType %>"
if ($filePattern -eq "*.all") {
    $filePattern = "*"
}

Write-Host "Migration des fichiers $filePattern de $sourceDir vers $targetDir" -ForegroundColor Cyan

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

# Fonction pour migrer un fichier
function Move-FileToTarget {
    param (
        [string]$SourceFile,
        [string]$TargetDir
    )
    
    $fileName = Split-Path -Path $SourceFile -Leaf
    $targetPath = Join-Path -Path $TargetDir -ChildPath $fileName
    $relativePath = $SourceFile.Replace($sourceDir, "").TrimStart("\")
    
    if (Test-Path -Path $targetPath) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Le fichier existe déjà : $targetPath. Voulez-vous le remplacer ?", "Confirmation")
        }
    } else {
        $shouldContinue = $true
    }
    
    if ($shouldContinue) {
        if ($DryRun) {
            Write-Log "[DRYRUN] Migration du fichier : $relativePath -> $targetPath"
        } else {
            if ($PSCmdlet.ShouldProcess($SourceFile, "Migrer vers $targetPath")) {
                Copy-Item -Path $SourceFile -Destination $targetPath -Force
                Write-Log "Fichier migré : $relativePath -> $targetPath"
            }
        }
    } else {
        Write-Log "Migration ignorée : $relativePath"
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
    "=== Migration démarrée le $timestamp ===" | Out-File -FilePath $LogFile -Encoding UTF8
    "Source: $sourceDir" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "Cible: $targetDir" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "Motif: $filePattern" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# Récupérer les fichiers à migrer
$files = Get-ChildItem -Path $sourceDir -Filter $filePattern -File -Recurse

# Migrer les fichiers
$totalFiles = $files.Count
$migratedFiles = 0

Write-Host "Nombre total de fichiers à migrer : $totalFiles" -ForegroundColor Cyan

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
        Write-Log "[DRYRUN] Migration du fichier : $relativePath -> $targetFilePath"
        $migratedFiles++
    } else {
        if ($PSCmdlet.ShouldProcess($file.FullName, "Migrer vers $targetFilePath")) {
            Copy-Item -Path $file.FullName -Destination $targetFilePath -Force
            Write-Log "Fichier migré : $relativePath -> $targetFilePath"
            $migratedFiles++
        }
    }
    
    # Afficher la progression
    $percentComplete = [math]::Round(($migratedFiles / $totalFiles) * 100)
    Write-Progress -Activity "Migration des fichiers" -Status "$migratedFiles / $totalFiles fichiers ($percentComplete%)" -PercentComplete $percentComplete
}

Write-Progress -Activity "Migration des fichiers" -Completed

# Résumé de la migration
Write-Host "Migration terminée. $migratedFiles / $totalFiles fichiers migrés." -ForegroundColor Green

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Migration terminée le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "Résultat: $migratedFiles / $totalFiles fichiers migrés." | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "Log de migration enregistré dans : $LogFile" -ForegroundColor Cyan
}
<% if (createRollback) { %>
Write-Host "Un script de rollback a également été créé : rollback-<%= name %>.ps1" -ForegroundColor Cyan
<% } %>

<#
.SYNOPSIS
    Script pour consolider tous les dossiers n8n en un seul.

.DESCRIPTION
    Ce script migre tous les workflows et donnÃ©es importantes des diffÃ©rents dossiers n8n
    vers une structure unifiÃ©e, puis supprime les dossiers obsolÃ¨tes.

.PARAMETER Force
    Force la suppression des dossiers obsolÃ¨tes sans demander de confirmation.

.EXAMPLE
    .\consolidate-n8n.ps1
    .\consolidate-n8n.ps1 -Force
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# DÃ©finir les chemins
$rootPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
$n8nNewPath = Join-Path -Path $rootPath -ChildPath "n8n-new"
$n8nPath = Join-Path -Path $rootPath -ChildPath "n8n"
$n8nOldPath = Join-Path -Path $rootPath -ChildPath "n8n-old"
$n8nDataPath = Join-Path -Path $rootPath -ChildPath "n8n-data"
$n8nIdePath = Join-Path -Path $rootPath -ChildPath "n8n-ide-integration"
$n8nUnifiedPath = Join-Path -Path $rootPath -ChildPath "n8n-unified"
$dotN8nPath = Join-Path -Path $rootPath -ChildPath ".n8n"
$allWorkflowsPath = Join-Path -Path $rootPath -ChildPath "all-workflows"

# Fonction pour copier les fichiers
function Copy-Files {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Filter = "*",
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    if (-not (Test-Path -Path $SourcePath)) {
        Write-Warning "Le dossier source '$SourcePath' n'existe pas."
        return
    }
    
    if (-not (Test-Path -Path $DestinationPath)) {
        New-Item -Path $DestinationPath -ItemType Directory -Force | Out-Null
        Write-Host "Dossier de destination crÃ©Ã©: $DestinationPath"
    }
    
    $files = Get-ChildItem -Path $SourcePath -Filter $Filter -File -Recurse:$Recurse
    
    if ($files.Count -eq 0) {
        Write-Host "Aucun fichier Ã  copier depuis '$SourcePath'."
        return
    }
    
    $copiedCount = 0
    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($SourcePath.Length)
        $destinationFile = Join-Path -Path $DestinationPath -ChildPath $relativePath
        $destinationDir = Split-Path -Path $destinationFile -Parent
        
        if (-not (Test-Path -Path $destinationDir)) {
            New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
        }
        
        if ((Test-Path -Path $destinationFile) -and -not $Force) {
            Write-Host "Le fichier '$relativePath' existe dÃ©jÃ  dans la destination. Utilisez -Force pour le remplacer."
            continue
        }
        
        try {
            Copy-Item -Path $file.FullName -Destination $destinationFile -Force:$Force
            Write-Host "CopiÃ©: $relativePath -> $destinationFile"
            $copiedCount++
        } catch {
            Write-Error "Erreur lors de la copie du fichier '$relativePath' : $_"
        }
    }
    
    Write-Host "$copiedCount fichiers copiÃ©s."
}

# Fonction pour crÃ©er un lien symbolique
function New-SymbolicLink {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceFile,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetFile
    )
    
    $sourcePath = Join-Path -Path $rootPath -ChildPath $SourceFile
    
    if (Test-Path -Path $sourcePath) {
        Write-Warning "Le fichier '$SourceFile' existe dÃ©jÃ . Il sera remplacÃ© par un lien symbolique."
        Remove-Item -Path $sourcePath -Force
    }
    
    try {
        New-Item -ItemType SymbolicLink -Path $sourcePath -Target $TargetFile -Force | Out-Null
        Write-Host "Lien symbolique crÃ©Ã©: $SourceFile -> $TargetFile"
        return $true
    } catch {
        Write-Error "Erreur lors de la crÃ©ation du lien symbolique '$SourceFile' : $_"
        return $false
    }
}

# Ã‰tape 1: Migrer les workflows manquants
Write-Host ""
Write-Host "Ã‰tape 1: Migration des workflows manquants..."
Write-Host "------------------------------------------------------------"

# Copier les workflows de all-workflows vers n8n-new/workflows/archive
if (Test-Path -Path $allWorkflowsPath) {
    $archiveWorkflowsPath = Join-Path -Path $n8nNewPath -ChildPath "workflows\archive"
    
    if (-not (Test-Path -Path $archiveWorkflowsPath)) {
        New-Item -Path $archiveWorkflowsPath -ItemType Directory -Force | Out-Null
        Write-Host "Dossier crÃ©Ã©: $archiveWorkflowsPath"
    }
    
    Copy-Files -SourcePath $allWorkflowsPath -DestinationPath $archiveWorkflowsPath -Filter "*.json" -Recurse -Force:$Force
} else {
    Write-Warning "Le dossier all-workflows n'existe pas."
}

# Ã‰tape 2: Migrer les donnÃ©es importantes
Write-Host ""
Write-Host "Ã‰tape 2: Migration des donnÃ©es importantes..."
Write-Host "------------------------------------------------------------"

# Copier les donnÃ©es de n8n-data vers n8n-new/data
if (Test-Path -Path $n8nDataPath) {
    $dataPath = Join-Path -Path $n8nNewPath -ChildPath "data"
    
    if (-not (Test-Path -Path $dataPath)) {
        New-Item -Path $dataPath -ItemType Directory -Force | Out-Null
        Write-Host "Dossier crÃ©Ã©: $dataPath"
    }
    
    # Copier les credentials
    $credentialsSourcePath = Join-Path -Path $n8nDataPath -ChildPath "credentials"
    $credentialsDestPath = Join-Path -Path $dataPath -ChildPath "credentials"
    
    if (Test-Path -Path $credentialsSourcePath) {
        Copy-Files -SourcePath $credentialsSourcePath -DestinationPath $credentialsDestPath -Recurse -Force:$Force
    }
    
    # Copier les donnÃ©es binaires
    $binaryDataSourcePath = Join-Path -Path $n8nDataPath -ChildPath "binaryData"
    $binaryDataDestPath = Join-Path -Path $dataPath -ChildPath "storage"
    
    if (Test-Path -Path $binaryDataSourcePath) {
        Copy-Files -SourcePath $binaryDataSourcePath -DestinationPath $binaryDataDestPath -Recurse -Force:$Force
    }
} else {
    Write-Warning "Le dossier n8n-data n'existe pas."
}

# Ã‰tape 3: Renommer les dossiers
Write-Host ""
Write-Host "Ã‰tape 3: Renommage des dossiers..."
Write-Host "------------------------------------------------------------"

# VÃ©rifier si le dossier n8n existe
if (Test-Path -Path $n8nPath) {
    # VÃ©rifier si n8n-old existe dÃ©jÃ 
    if (Test-Path -Path $n8nOldPath) {
        Write-Host "Le dossier n8n-old existe dÃ©jÃ . Il sera supprimÃ©."
        Remove-Item -Path $n8nOldPath -Recurse -Force
    }
    
    # Renommer n8n en n8n-old
    try {
        Rename-Item -Path $n8nPath -NewName "n8n-old" -Force
        Write-Host "Dossier n8n renommÃ© en n8n-old."
    } catch {
        Write-Error "Erreur lors du renommage du dossier n8n en n8n-old : $_"
        Write-Host "Veuillez fermer toutes les applications qui pourraient utiliser ces dossiers et rÃ©essayer."
        exit 1
    }
}

# Renommer n8n-new en n8n
try {
    Rename-Item -Path $n8nNewPath -NewName "n8n" -Force
    Write-Host "Dossier n8n-new renommÃ© en n8n."
} catch {
    Write-Error "Erreur lors du renommage du dossier n8n-new en n8n : $_"
    Write-Host "Veuillez fermer toutes les applications qui pourraient utiliser ces dossiers et rÃ©essayer."
    exit 1
}

# Ã‰tape 4: Nettoyer les fichiers .cmd Ã  la racine
Write-Host ""
Write-Host "Ã‰tape 4: Nettoyage des fichiers .cmd Ã  la racine..."
Write-Host "------------------------------------------------------------"

# CrÃ©er des liens symboliques pour les fichiers .cmd Ã  la racine
$cmdFiles = @{
    "install-n8n-local.cmd" = "n8n\cmd\install\install-n8n-local.cmd"
    "start-n8n-local.cmd" = "n8n\cmd\start\start-n8n-local.cmd"
    "stop-n8n.cmd" = "n8n\cmd\stop\stop-n8n.cmd"
    "reset-n8n.cmd" = "n8n\cmd\utils\reset-n8n.cmd"
}

foreach ($file in $cmdFiles.Keys) {
    $targetFile = Join-Path -Path $rootPath -ChildPath $cmdFiles[$file]
    New-SymbolicLink -SourceFile $file -TargetFile $targetFile
}

# Ã‰tape 5: Supprimer les dossiers obsolÃ¨tes
Write-Host ""
Write-Host "Ã‰tape 5: Suppression des dossiers obsolÃ¨tes..."
Write-Host "------------------------------------------------------------"

$obsoleteFolders = @(
    $n8nOldPath,
    $n8nDataPath,
    $n8nIdePath,
    $n8nUnifiedPath,
    $dotN8nPath,
    $allWorkflowsPath
)

if (-not $Force) {
    Write-Host "Les dossiers suivants seront supprimÃ©s :"
    foreach ($folder in $obsoleteFolders) {
        if (Test-Path -Path $folder) {
            Write-Host "- $folder"
        }
    }
    
    $confirmation = Read-Host "ÃŠtes-vous sÃ»r de vouloir supprimer ces dossiers ? (O/N)"
    if ($confirmation -ne "O") {
        Write-Host "Suppression annulÃ©e."
        exit 0
    }
}

foreach ($folder in $obsoleteFolders) {
    if (Test-Path -Path $folder) {
        try {
            Remove-Item -Path $folder -Recurse -Force
            Write-Host "Dossier supprimÃ© : $folder"
        } catch {
            Write-Error "Erreur lors de la suppression du dossier '$folder' : $_"
        }
    } else {
        Write-Host "Le dossier '$folder' n'existe pas."
    }
}

Write-Host ""
Write-Host "Consolidation terminÃ©e."
Write-Host "Tous les dossiers n8n ont Ã©tÃ© consolidÃ©s en un seul dossier : $n8nPath"
Write-Host "Pour utiliser n8n, exÃ©cutez : .\n8n\cmd\start\start-n8n-local.cmd"

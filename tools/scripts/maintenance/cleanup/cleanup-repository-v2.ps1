<#
.SYNOPSIS
    Nettoie les fichiers originaux après la réorganisation du dépôt.

.DESCRIPTION
    Ce script supprime les fichiers et dossiers originaux qui ont été déplacés
    lors de la réorganisation du dépôt avec organize-repository-v2.ps1.
    ATTENTION : Ce script est destructif et doit être utilisé avec précaution.

.PARAMETER DryRun
    Si spécifié, le script affiche les actions qui seraient effectuées sans les exécuter.

.PARAMETER Force
    Si spécifié, le script supprime les fichiers sans demander de confirmation.

.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuées.

.EXAMPLE
    .\cleanup-repository-v2.ps1 -DryRun

.EXAMPLE
    .\cleanup-repository-v2.ps1 -Force -LogFile "cleanup-v2.log"

.NOTES
    Auteur: Maintenance Team
    Version: 2.0
    Date de création: 2023-08-15
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

# Définir le répertoire racine du dépôt
$repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\"
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot)

# Vérifier que le répertoire racine existe
if (-not (Test-Path -Path $repoRoot -PathType Container)) {
    throw "Le répertoire racine n'existe pas : $repoRoot"
}

Write-Host "Nettoyage du dépôt : $repoRoot" -ForegroundColor Cyan

# Fonction pour journaliser les actions
function Write-Log {
    param (
        [string]$Message,
        [string]$Color = "White"
    )
    
    Write-Host $Message -ForegroundColor $Color
    
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
    "Répertoire racine: $repoRoot" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# Définir les dossiers à conserver à la racine
$keepRootFolders = @(
    "src",
    "tools",
    "docs",
    "tests",
    "config",
    "assets",
    ".build",
    # Dossiers système et spéciaux à conserver
    ".git",
    ".github",
    ".vscode",
    ".idea",
    "node_modules",
    "__pycache__",
    ".pytest_cache",
    ".augment"
)

# Fonction pour vérifier si un dossier doit être conservé
function Should-KeepFolder {
    param (
        [string]$FolderName
    )
    
    foreach ($keepFolder in $keepRootFolders) {
        if ($FolderName -eq $keepFolder) {
            return $true
        }
    }
    
    return $false
}

# Fonction pour supprimer un dossier
function Remove-FolderIfExists {
    param (
        [string]$FolderPath
    )
    
    if (Test-Path -Path $FolderPath -PathType Container) {
        $folderName = Split-Path -Path $FolderPath -Leaf
        
        # Vérifier si le dossier doit être conservé
        if (Should-KeepFolder -FolderName $folderName) {
            Write-Log "Dossier à conserver : $FolderPath" -Color Gray
            return
        }
        
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Voulez-vous supprimer le dossier : $FolderPath ?", "Confirmation")
        }
        
        if ($shouldContinue) {
            if ($DryRun) {
                Write-Log "[DRYRUN] Suppression du dossier : $FolderPath" -Color Yellow
            } else {
                if ($PSCmdlet.ShouldProcess($FolderPath, "Supprimer")) {
                    try {
                        Remove-Item -Path $FolderPath -Recurse -Force
                        Write-Log "Dossier supprimé : $FolderPath" -Color Green
                    } catch {
                        Write-Log "Erreur lors de la suppression du dossier $FolderPath : $_" -Color Red
                    }
                }
            }
        } else {
            Write-Log "Suppression ignorée : $FolderPath" -Color Gray
        }
    } else {
        Write-Log "Le dossier n'existe pas : $FolderPath" -Color Gray
    }
}

# Fonction pour supprimer un fichier
function Remove-FileIfExists {
    param (
        [string]$FilePath
    )
    
    if (Test-Path -Path $FilePath -PathType Leaf) {
        if ($Force) {
            $shouldContinue = $true
        } else {
            $shouldContinue = $PSCmdlet.ShouldContinue("Voulez-vous supprimer le fichier : $FilePath ?", "Confirmation")
        }
        
        if ($shouldContinue) {
            if ($DryRun) {
                Write-Log "[DRYRUN] Suppression du fichier : $FilePath" -Color Yellow
            } else {
                if ($PSCmdlet.ShouldProcess($FilePath, "Supprimer")) {
                    try {
                        Remove-Item -Path $FilePath -Force
                        Write-Log "Fichier supprimé : $FilePath" -Color Green
                    } catch {
                        Write-Log "Erreur lors de la suppression du fichier $FilePath : $_" -Color Red
                    }
                }
            }
        } else {
            Write-Log "Suppression ignorée : $FilePath" -Color Gray
        }
    } else {
        Write-Log "Le fichier n'existe pas : $FilePath" -Color Gray
    }
}

# Vérifier que les dossiers de la nouvelle structure existent
$newStructureExists = $true
$requiredFolders = @(
    "src",
    "tools",
    "docs",
    "tests",
    "config",
    "assets",
    ".build"
)

foreach ($folder in $requiredFolders) {
    $folderPath = Join-Path -Path $repoRoot -ChildPath $folder
    if (-not (Test-Path -Path $folderPath -PathType Container)) {
        $newStructureExists = $false
        Write-Log "Dossier requis manquant : $folderPath" -Color Red
    }
}

if (-not $newStructureExists) {
    Write-Log "La nouvelle structure n'existe pas complètement. Exécutez d'abord organize-repository-v2.ps1." -Color Red
    return
}

# Définir les mappages de dossiers (pour vérifier que les fichiers ont bien été copiés)
$directoryMappings = @{
    "scripts"                    = "tools/scripts"
    "scripts/roadmap"            = "tools/scripts/roadmap"
    "scripts/roadmap-parser"     = "tools/scripts/roadmap/parser"
    "scripts/maintenance"        = "tools/scripts/maintenance"
    "_templates"                 = "tools/_templates"
    "templates"                  = "tools/templates"
    "Roadmap"                    = "docs/roadmap"
    "Roadmap/mes-plans"          = "docs/roadmap/plans"
    "docs/guides"                = "docs/guides"
    "n8n"                        = "src/n8n"
    "frontend"                   = "src/frontend"
    "modules"                    = "src/modules"
    "tests"                      = "tests"
    "config"                     = "config"
    "assets"                     = "assets"
    "logs"                       = ".build/logs"
    "cache"                      = ".build/cache"
    "dashboards"                 = "tools/dashboards"
    "reports"                    = "tools/reports"
    "tools"                      = "tools"
    "mcp"                        = "src/mcp"
    "data"                       = "assets/data"
    "journal"                    = "docs/journal"
    "backups"                    = ".build/backups"
    "extensions"                 = "src/extensions"
    "git-hooks"                  = ".build/ci/git-hooks"
    "ProjectManagement"          = "docs/project-management"
    "ErrorManagement"            = "src/error-management"
    "FormatSupport"              = "src/format-support"
    "Insights"                   = "tools/insights"
    "output"                     = ".build/output"
    "SWE-bench"                  = "tools/swe-bench"
    "cmd"                        = "tools/cmd"
    "md"                         = "docs/md"
    "archive"                    = ".build/archive"
}

Write-Log "Vérification des dossiers à nettoyer..." -Color Cyan

# Vérifier que les dossiers ont bien été copiés avant de les supprimer
$foldersToRemove = @()

foreach ($sourceDir in $directoryMappings.Keys) {
    $sourcePath = Join-Path -Path $repoRoot -ChildPath $sourceDir
    $destinationPath = Join-Path -Path $repoRoot -ChildPath $directoryMappings[$sourceDir]
    
    if (Test-Path -Path $sourcePath -PathType Container) {
        if (Test-Path -Path $destinationPath -PathType Container) {
            # Vérifier que le contenu a bien été copié
            $sourceFiles = Get-ChildItem -Path $sourcePath -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count
            $destFiles = Get-ChildItem -Path $destinationPath -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count
            
            if ($destFiles -ge $sourceFiles) {
                $foldersToRemove += $sourcePath
                Write-Log "Dossier à supprimer : $sourcePath (contenu copié vers $destinationPath)" -Color Cyan
            } else {
                Write-Log "Attention : Le dossier $destinationPath ne contient pas tous les fichiers de $sourcePath ($destFiles/$sourceFiles)" -Color Yellow
            }
        } else {
            Write-Log "Attention : Le dossier de destination $destinationPath n'existe pas" -Color Yellow
        }
    }
}

# Supprimer les dossiers
Write-Log "Suppression des dossiers..." -Color Cyan

foreach ($folderPath in $foldersToRemove) {
    Remove-FolderIfExists -FolderPath $folderPath
}

# Supprimer les dossiers racine qui ne sont pas dans la liste à conserver
Write-Log "Nettoyage des dossiers racine..." -Color Cyan

$rootFolders = Get-ChildItem -Path $repoRoot -Directory

foreach ($folder in $rootFolders) {
    if (-not (Should-KeepFolder -FolderName $folder.Name)) {
        Remove-FolderIfExists -FolderPath $folder.FullName
    }
}

# Définir les fichiers à déplacer à la racine
$rootFileMappings = @{
    "*.md"                      = "docs/readme/{0}"
    "*.txt"                     = "docs/readme/{0}"
    "*.json"                    = "config/settings/{0}"
    "*.yaml"                    = "config/settings/{0}"
    "*.yml"                     = "config/settings/{0}"
    "*.ps1"                     = "tools/scripts/{0}"
    "*.py"                      = "tools/scripts/{0}"
    "*.js"                      = "src/scripts/{0}"
    "*.ts"                      = "src/scripts/{0}"
    "*.css"                     = "assets/styles/{0}"
    "*.scss"                    = "assets/styles/{0}"
    "*.html"                    = "src/frontend/{0}"
}

# Fichiers à conserver à la racine
$keepRootFiles = @(
    "README.md",
    ".gitignore",
    ".gitattributes",
    "LICENSE",
    "package.json",
    "package-lock.json",
    "requirements.txt",
    "setup.py",
    "pyproject.toml"
)

# Vérifier que les fichiers ont bien été copiés avant de les supprimer
Write-Log "Vérification des fichiers à nettoyer..." -Color Cyan

$filesToRemove = @()

foreach ($pattern in $rootFileMappings.Keys) {
    $files = Get-ChildItem -Path (Join-Path -Path $repoRoot -ChildPath $pattern) -File -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $fileName = $file.Name
        
        # Vérifier si le fichier doit être conservé à la racine
        $keepFile = $false
        foreach ($keepFileName in $keepRootFiles) {
            if ($fileName -eq $keepFileName) {
                $keepFile = $true
                break
            }
        }
        
        if ($keepFile) {
            Write-Log "Fichier à conserver à la racine : $($file.FullName)" -Color Gray
            continue
        }
        
        $destinationPath = Join-Path -Path $repoRoot -ChildPath ($rootFileMappings[$pattern] -f $fileName)
        
        if (Test-Path -Path $destinationPath) {
            $filesToRemove += $file.FullName
            Write-Log "Fichier à supprimer : $($file.FullName) (copié vers $destinationPath)" -Color Cyan
        } else {
            Write-Log "Attention : Le fichier de destination $destinationPath n'existe pas" -Color Yellow
        }
    }
}

# Supprimer les fichiers
Write-Log "Suppression des fichiers..." -Color Cyan

foreach ($filePath in $filesToRemove) {
    Remove-FileIfExists -FilePath $filePath
}

# Résumé du nettoyage
Write-Log "Nettoyage terminé." -Color Cyan
Write-Log "La structure du dépôt a été nettoyée." -Color Cyan

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Nettoyage terminé le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "Log de nettoyage enregistré dans : $LogFile" -ForegroundColor Cyan
}

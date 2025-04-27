<#
.SYNOPSIS
    Nettoie les fichiers originaux aprÃ¨s la rÃ©organisation du dÃ©pÃ´t.

.DESCRIPTION
    Ce script supprime les fichiers et dossiers originaux qui ont Ã©tÃ© dÃ©placÃ©s
    lors de la rÃ©organisation du dÃ©pÃ´t avec organize-repository-v2.ps1.
    ATTENTION : Ce script est destructif et doit Ãªtre utilisÃ© avec prÃ©caution.

.PARAMETER DryRun
    Si spÃ©cifiÃ©, le script affiche les actions qui seraient effectuÃ©es sans les exÃ©cuter.

.PARAMETER Force
    Si spÃ©cifiÃ©, le script supprime les fichiers sans demander de confirmation.

.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuÃ©es.

.EXAMPLE
    .\cleanup-repository-v2.ps1 -DryRun

.EXAMPLE
    .\cleanup-repository-v2.ps1 -Force -LogFile "cleanup-v2.log"

.NOTES
    Auteur: Maintenance Team
    Version: 2.0
    Date de crÃ©ation: 2023-08-15
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

# DÃ©finir le rÃ©pertoire racine du dÃ©pÃ´t
$repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\"
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot)

# VÃ©rifier que le rÃ©pertoire racine existe
if (-not (Test-Path -Path $repoRoot -PathType Container)) {
    throw "Le rÃ©pertoire racine n'existe pas : $repoRoot"
}

Write-Host "Nettoyage du dÃ©pÃ´t : $repoRoot" -ForegroundColor Cyan

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
    "=== Nettoyage dÃ©marrÃ© le $timestamp ===" | Out-File -FilePath $LogFile -Encoding UTF8
    "RÃ©pertoire racine: $repoRoot" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# DÃ©finir les dossiers Ã  conserver Ã  la racine
$keepRootFolders = @(
    "src",
    "tools",
    "docs",
    "tests",
    "config",
    "assets",
    ".build",
    # Dossiers systÃ¨me et spÃ©ciaux Ã  conserver
    ".git",
    ".github",
    ".vscode",
    ".idea",
    "node_modules",
    "__pycache__",
    ".pytest_cache",
    ".augment"
)

# Fonction pour vÃ©rifier si un dossier doit Ãªtre conservÃ©
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
        
        # VÃ©rifier si le dossier doit Ãªtre conservÃ©
        if (Should-KeepFolder -FolderName $folderName) {
            Write-Log "Dossier Ã  conserver : $FolderPath" -Color Gray
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
                        Write-Log "Dossier supprimÃ© : $FolderPath" -Color Green
                    } catch {
                        Write-Log "Erreur lors de la suppression du dossier $FolderPath : $_" -Color Red
                    }
                }
            }
        } else {
            Write-Log "Suppression ignorÃ©e : $FolderPath" -Color Gray
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
                        Write-Log "Fichier supprimÃ© : $FilePath" -Color Green
                    } catch {
                        Write-Log "Erreur lors de la suppression du fichier $FilePath : $_" -Color Red
                    }
                }
            }
        } else {
            Write-Log "Suppression ignorÃ©e : $FilePath" -Color Gray
        }
    } else {
        Write-Log "Le fichier n'existe pas : $FilePath" -Color Gray
    }
}

# VÃ©rifier que les dossiers de la nouvelle structure existent
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
    Write-Log "La nouvelle structure n'existe pas complÃ¨tement. ExÃ©cutez d'abord organize-repository-v2.ps1." -Color Red
    return
}

# DÃ©finir les mappages de dossiers (pour vÃ©rifier que les fichiers ont bien Ã©tÃ© copiÃ©s)
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

Write-Log "VÃ©rification des dossiers Ã  nettoyer..." -Color Cyan

# VÃ©rifier que les dossiers ont bien Ã©tÃ© copiÃ©s avant de les supprimer
$foldersToRemove = @()

foreach ($sourceDir in $directoryMappings.Keys) {
    $sourcePath = Join-Path -Path $repoRoot -ChildPath $sourceDir
    $destinationPath = Join-Path -Path $repoRoot -ChildPath $directoryMappings[$sourceDir]
    
    if (Test-Path -Path $sourcePath -PathType Container) {
        if (Test-Path -Path $destinationPath -PathType Container) {
            # VÃ©rifier que le contenu a bien Ã©tÃ© copiÃ©
            $sourceFiles = Get-ChildItem -Path $sourcePath -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count
            $destFiles = Get-ChildItem -Path $destinationPath -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count
            
            if ($destFiles -ge $sourceFiles) {
                $foldersToRemove += $sourcePath
                Write-Log "Dossier Ã  supprimer : $sourcePath (contenu copiÃ© vers $destinationPath)" -Color Cyan
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

# Supprimer les dossiers racine qui ne sont pas dans la liste Ã  conserver
Write-Log "Nettoyage des dossiers racine..." -Color Cyan

$rootFolders = Get-ChildItem -Path $repoRoot -Directory

foreach ($folder in $rootFolders) {
    if (-not (Should-KeepFolder -FolderName $folder.Name)) {
        Remove-FolderIfExists -FolderPath $folder.FullName
    }
}

# DÃ©finir les fichiers Ã  dÃ©placer Ã  la racine
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

# Fichiers Ã  conserver Ã  la racine
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

# VÃ©rifier que les fichiers ont bien Ã©tÃ© copiÃ©s avant de les supprimer
Write-Log "VÃ©rification des fichiers Ã  nettoyer..." -Color Cyan

$filesToRemove = @()

foreach ($pattern in $rootFileMappings.Keys) {
    $files = Get-ChildItem -Path (Join-Path -Path $repoRoot -ChildPath $pattern) -File -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $fileName = $file.Name
        
        # VÃ©rifier si le fichier doit Ãªtre conservÃ© Ã  la racine
        $keepFile = $false
        foreach ($keepFileName in $keepRootFiles) {
            if ($fileName -eq $keepFileName) {
                $keepFile = $true
                break
            }
        }
        
        if ($keepFile) {
            Write-Log "Fichier Ã  conserver Ã  la racine : $($file.FullName)" -Color Gray
            continue
        }
        
        $destinationPath = Join-Path -Path $repoRoot -ChildPath ($rootFileMappings[$pattern] -f $fileName)
        
        if (Test-Path -Path $destinationPath) {
            $filesToRemove += $file.FullName
            Write-Log "Fichier Ã  supprimer : $($file.FullName) (copiÃ© vers $destinationPath)" -Color Cyan
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

# RÃ©sumÃ© du nettoyage
Write-Log "Nettoyage terminÃ©." -Color Cyan
Write-Log "La structure du dÃ©pÃ´t a Ã©tÃ© nettoyÃ©e." -Color Cyan

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Nettoyage terminÃ© le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "Log de nettoyage enregistrÃ© dans : $LogFile" -ForegroundColor Cyan
}

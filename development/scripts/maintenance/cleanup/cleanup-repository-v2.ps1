<#
.SYNOPSIS
    Nettoie les fichiers originaux aprÃƒÂ¨s la rÃƒÂ©organisation du dÃƒÂ©pÃƒÂ´t.

.DESCRIPTION
    Ce script supprime les fichiers et dossiers originaux qui ont ÃƒÂ©tÃƒÂ© dÃƒÂ©placÃƒÂ©s
    lors de la rÃƒÂ©organisation du dÃƒÂ©pÃƒÂ´t avec organize-repository-v2.ps1.
    ATTENTION : Ce script est destructif et doit ÃƒÂªtre utilisÃƒÂ© avec prÃƒÂ©caution.

.PARAMETER DryRun
    Si spÃƒÂ©cifiÃƒÂ©, le script affiche les actions qui seraient effectuÃƒÂ©es sans les exÃƒÂ©cuter.

.PARAMETER Force
    Si spÃƒÂ©cifiÃƒÂ©, le script supprime les fichiers sans demander de confirmation.

.PARAMETER LogFile
    Chemin vers un fichier de log pour enregistrer les actions effectuÃƒÂ©es.

.EXAMPLE
    .\cleanup-repository-v2.ps1 -DryRun

.EXAMPLE
    .\cleanup-repository-v2.ps1 -Force -LogFile "cleanup-v2.log"

.NOTES
    Auteur: Maintenance Team
    Version: 2.0
    Date de crÃƒÂ©ation: 2023-08-15
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

# DÃƒÂ©finir le rÃƒÂ©pertoire racine du dÃƒÂ©pÃƒÂ´t
$repoRoot = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\"
$repoRoot = [System.IO.Path]::GetFullPath($repoRoot)

# VÃƒÂ©rifier que le rÃƒÂ©pertoire racine existe
if (-not (Test-Path -Path $repoRoot -PathType Container)) {
    throw "Le rÃƒÂ©pertoire racine n'existe pas : $repoRoot"
}

Write-Host "Nettoyage du dÃƒÂ©pÃƒÂ´t : $repoRoot" -ForegroundColor Cyan

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
    "=== Nettoyage dÃƒÂ©marrÃƒÂ© le $timestamp ===" | Out-File -FilePath $LogFile -Encoding UTF8
    "RÃƒÂ©pertoire racine: $repoRoot" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

# DÃƒÂ©finir les dossiers ÃƒÂ  conserver ÃƒÂ  la racine
$keepRootFolders = @(
    "src",
    "tools",
    "docs",
    "tests",
    "config",
    "assets",
    ".build",
    # Dossiers systÃƒÂ¨me et spÃƒÂ©ciaux ÃƒÂ  conserver
    ".git",
    ".github",
    ".vscode",
    ".idea",
    "node_modules",
    "__pycache__",
    ".pytest_cache",
    ".augment"
)

# Fonction pour vÃƒÂ©rifier si un dossier doit ÃƒÂªtre conservÃƒÂ©
function Test-KeepFolder {
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
        
        # VÃƒÂ©rifier si le dossier doit ÃƒÂªtre conservÃƒÂ©
        if (Test-KeepFolder -FolderName $folderName) {
            Write-Log "Dossier ÃƒÂ  conserver : $FolderPath" -Color Gray
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
                        Write-Log "Dossier supprimÃƒÂ© : $FolderPath" -Color Green
                    } catch {
                        Write-Log "Erreur lors de la suppression du dossier $FolderPath : $_" -Color Red
                    }
                }
            }
        } else {
            Write-Log "Suppression ignorÃƒÂ©e : $FolderPath" -Color Gray
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
                        Write-Log "Fichier supprimÃƒÂ© : $FilePath" -Color Green
                    } catch {
                        Write-Log "Erreur lors de la suppression du fichier $FilePath : $_" -Color Red
                    }
                }
            }
        } else {
            Write-Log "Suppression ignorÃƒÂ©e : $FilePath" -Color Gray
        }
    } else {
        Write-Log "Le fichier n'existe pas : $FilePath" -Color Gray
    }
}

# VÃƒÂ©rifier que les dossiers de la nouvelle structure existent
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
    Write-Log "La nouvelle structure n'existe pas complÃƒÂ¨tement. ExÃƒÂ©cutez d'abord organize-repository-v2.ps1." -Color Red
    return
}

# DÃƒÂ©finir les mappages de dossiers (pour vÃƒÂ©rifier que les fichiers ont bien ÃƒÂ©tÃƒÂ© copiÃƒÂ©s)
$directoryMappings = @{
    "scripts"                    = "development/scripts"
    "development/roadmap/scripts"            = "development/tools/development/roadmap/scripts"
    "development/roadmap/scripts-parser"     = "development/tools/development/roadmap/scripts/parser"
    "development/scripts/maintenance"        = "development/tools/development/scripts/maintenance"
    "development/templates"                 = "development/tools/development/templates"
    "templates"                  = "development/templates"
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
    "dashboards"                 = "development/tools/dashboards-tools"
    "reports"                    = "development/tools/reports-tools"
    "tools"                      = "tools"
    "mcp"                        = "src/mcp"
    "data"                       = "projet/assets/data"
    "journal"                    = "docs/journal"
    "backups"                    = ".build/backups"
    "extensions"                 = "src/extensions"
    "git-hooks"                  = ".build/ci/git-hooks"
    "ProjectManagement"          = "docs/project-management"
    "ErrorManagement"            = "src/error-management"
    "FormatSupport"              = "src/format-support"
    "Insights"                   = "development/tools/insights-tools"
    "output"                     = ".build/output"
    "SWE-bench"                  = "development/tools/swe-bench-tools"
    "cmd"                        = "development/tools/cmd-tools"
    "md"                         = "docs/md"
    "archive"                    = ".build/archive"
}

Write-Log "VÃƒÂ©rification des dossiers ÃƒÂ  nettoyer..." -Color Cyan

# VÃƒÂ©rifier que les dossiers ont bien ÃƒÂ©tÃƒÂ© copiÃƒÂ©s avant de les supprimer
$foldersToRemove = @()

foreach ($sourceDir in $directoryMappings.Keys) {
    $sourcePath = Join-Path -Path $repoRoot -ChildPath $sourceDir
    $destinationPath = Join-Path -Path $repoRoot -ChildPath $directoryMappings[$sourceDir]
    
    if (Test-Path -Path $sourcePath -PathType Container) {
        if (Test-Path -Path $destinationPath -PathType Container) {
            # VÃƒÂ©rifier que le contenu a bien ÃƒÂ©tÃƒÂ© copiÃƒÂ©
            $sourceFiles = Get-ChildItem -Path $sourcePath -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count
            $destFiles = Get-ChildItem -Path $destinationPath -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count
            
            if ($destFiles -ge $sourceFiles) {
                $foldersToRemove += $sourcePath
                Write-Log "Dossier ÃƒÂ  supprimer : $sourcePath (contenu copiÃƒÂ© vers $destinationPath)" -Color Cyan
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

# Supprimer les dossiers racine qui ne sont pas dans la liste ÃƒÂ  conserver
Write-Log "Nettoyage des dossiers racine..." -Color Cyan

$rootFolders = Get-ChildItem -Path $repoRoot -Directory

foreach ($folder in $rootFolders) {
    if (-not (Test-KeepFolder -FolderName $folder.Name)) {
        Remove-FolderIfExists -FolderPath $folder.FullName
    }
}

# DÃƒÂ©finir les fichiers ÃƒÂ  dÃƒÂ©placer ÃƒÂ  la racine
$rootFileMappings = @{
    "*.md"                      = "docs/readme/{0}"
    "*.txt"                     = "docs/readme/{0}"
    "*.json"                    = "projet/config/settings/{0}"
    "*.yaml"                    = "projet/config/settings/{0}"
    "*.yml"                     = "projet/config/settings/{0}"
    "*.ps1"                     = "development/tools/development/scripts/{0}"
    "*.py"                      = "development/tools/development/scripts/{0}"
    "*.js"                      = "src/development/scripts/{0}"
    "*.ts"                      = "src/development/scripts/{0}"
    "*.css"                     = "projet/assets/styles/{0}"
    "*.scss"                    = "projet/assets/styles/{0}"
    "*.html"                    = "src/frontend/{0}"
}

# Fichiers ÃƒÂ  conserver ÃƒÂ  la racine
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

# VÃƒÂ©rifier que les fichiers ont bien ÃƒÂ©tÃƒÂ© copiÃƒÂ©s avant de les supprimer
Write-Log "VÃƒÂ©rification des fichiers ÃƒÂ  nettoyer..." -Color Cyan

$filesToRemove = @()

foreach ($pattern in $rootFileMappings.Keys) {
    $files = Get-ChildItem -Path (Join-Path -Path $repoRoot -ChildPath $pattern) -File -ErrorAction SilentlyContinue
    
    foreach ($file in $files) {
        $fileName = $file.Name
        
        # VÃƒÂ©rifier si le fichier doit ÃƒÂªtre conservÃƒÂ© ÃƒÂ  la racine
        $keepFile = $false
        foreach ($keepFileName in $keepRootFiles) {
            if ($fileName -eq $keepFileName) {
                $keepFile = $true
                break
            }
        }
        
        if ($keepFile) {
            Write-Log "Fichier ÃƒÂ  conserver ÃƒÂ  la racine : $($file.FullName)" -Color Gray
            continue
        }
        
        $destinationPath = Join-Path -Path $repoRoot -ChildPath ($rootFileMappings[$pattern] -f $fileName)
        
        if (Test-Path -Path $destinationPath) {
            $filesToRemove += $file.FullName
            Write-Log "Fichier ÃƒÂ  supprimer : $($file.FullName) (copiÃƒÂ© vers $destinationPath)" -Color Cyan
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

# RÃƒÂ©sumÃƒÂ© du nettoyage
Write-Log "Nettoyage terminÃƒÂ©." -Color Cyan
Write-Log "La structure du dÃƒÂ©pÃƒÂ´t a ÃƒÂ©tÃƒÂ© nettoyÃƒÂ©e." -Color Cyan

if ($LogFile) {
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "=== Nettoyage terminÃƒÂ© le $timestamp ===" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    "===================================" | Out-File -FilePath $LogFile -Append -Encoding UTF8
    
    Write-Host "Log de nettoyage enregistrÃƒÂ© dans : $LogFile" -ForegroundColor Cyan
}






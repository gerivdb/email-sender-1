# Script pour organiser automatiquement les dossiers contenant trop de fichiers
# Ce script vÃ©rifie si un dossier contient trop de fichiers et les organise en sous-dossiers


# Script pour organiser automatiquement les dossiers contenant trop de fichiers
# Ce script vÃ©rifie si un dossier contient trop de fichiers et les organise en sous-dossiers

param (
    [string]$FolderPath = ".",
    [int]$MaxFilesPerFolder = 10,
    [string]$OrganizationMethod = "type"  # "type", "date", "alpha", "size"
)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal


# Fonction pour obtenir le type de fichier
function Get-FileType {
    param (
        [System.IO.FileInfo]$File
    )

    $extension = $File.Extension.ToLower()

    switch ($extension) {
        ".json" { return "json" }
        ".md" { return "markdown" }
        ".py" { return "python" }
        ".ps1" { return "powershell" }
        ".log" { return "logs" }
        ".txt" { return "text" }
        ".csv" { return "data" }
        ".xml" { return "xml" }
        ".html" { return "web" }
        ".css" { return "web" }
        ".js" { return "javascript" }
        ".jpg" { return "images" }
        ".jpeg" { return "images" }
        ".png" { return "images" }
        ".gif" { return "images" }
        ".pdf" { return "documents" }
        ".doc" { return "documents" }
        ".docx" { return "documents" }
        ".xls" { return "spreadsheets" }
        ".xlsx" { return "spreadsheets" }
        ".ppt" { return "presentations" }
        ".pptx" { return "presentations" }
        ".zip" { return "archives" }
        ".rar" { return "archives" }
        ".7z" { return "archives" }
        default { return "other" }
    }
}

# Fonction pour obtenir le dossier de destination basÃ© sur la date
function Get-DateFolder {
    param (
        [System.IO.FileInfo]$File
    )

    $year = $File.LastWriteTime.Year
    $month = $File.LastWriteTime.Month.ToString("00")

    return "$year-$month"
}

# Fonction pour obtenir le dossier alphabÃ©tique
function Get-AlphaFolder {
    param (
        [System.IO.FileInfo]$File
    )

    $firstChar = $File.Name.Substring(0, 1).ToUpper()

    if ($firstChar -match "[A-Z]") {
        return $firstChar
    } else if ($firstChar -match "[0-9]") {
        return "0-9"
    } else {
        return "Other"
    }
}

# Fonction pour obtenir le dossier basÃ© sur la taille
function Get-SizeFolder {
    param (
        [System.IO.FileInfo]$File
    )

    $sizeKB = [math]::Round($File.Length / 1KB)

    if ($sizeKB -lt 10) {
        return "Tiny (< 10KB)"
    } elseif ($sizeKB -lt 100) {
        return "Small (10-100KB)"
    } elseif ($sizeKB -lt 1000) {
        return "Medium (100KB-1MB)"
    } elseif ($sizeKB -lt 10000) {
        return "Large (1-10MB)"
    } else {
        return "Huge (> 10MB)"
    }
}

# Fonction pour organiser les fichiers dans un dossier
function Organize-Folder {
    param (
        [string]$FolderPath,
        [int]$MaxFilesPerFolder,
        [string]$OrganizationMethod
    )

    # VÃ©rifier si le dossier existe
    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Host "Le dossier '$FolderPath' n'existe pas." -ForegroundColor Red
        return
    }

    # Obtenir tous les fichiers dans le dossier (non rÃ©cursif)
    $files = Get-ChildItem -Path $FolderPath -File

    # VÃ©rifier s'il y a trop de fichiers
    if ($files.Count -le $MaxFilesPerFolder) {
        Write-Host "Le dossier '$FolderPath' contient $($files.Count) fichiers, ce qui est infÃ©rieur ou Ã©gal au maximum de $MaxFilesPerFolder." -ForegroundColor Green
        return
    }

    Write-Host "Le dossier '$FolderPath' contient $($files.Count) fichiers, ce qui dÃ©passe le maximum de $MaxFilesPerFolder." -ForegroundColor Yellow
    Write-Host "Organisation des fichiers par mÃ©thode: $OrganizationMethod" -ForegroundColor Cyan

    # Organiser les fichiers selon la mÃ©thode choisie
    foreach ($file in $files) {
        $subFolder = ""

        switch ($OrganizationMethod) {
            "type" {
                $subFolder = Get-FileType -File $file
            }
            "date" {
                $subFolder = Get-DateFolder -File $file
            }
            "alpha" {
                $subFolder = Get-AlphaFolder -File $file
            }
            "size" {
                $subFolder = Get-SizeFolder -File $file
            }
            default {
                $subFolder = Get-FileType -File $file
            }
        }

        $subFolderPath = Join-Path -Path $FolderPath -ChildPath $subFolder

        # CrÃ©er le sous-dossier s'il n'existe pas
        if (-not (Test-Path -Path $subFolderPath -PathType Container)) {
            Write-Host "CrÃ©ation du sous-dossier: $subFolderPath" -ForegroundColor Yellow
            New-Item -Path $subFolderPath -ItemType Directory -Force | Out-Null
        }

        # DÃ©placer le fichier dans le sous-dossier
        $destinationPath = Join-Path -Path $subFolderPath -ChildPath $file.Name

        if (-not (Test-Path -Path $destinationPath)) {
            Write-Host "DÃ©placement de $($file.Name) vers $subFolder/" -ForegroundColor Yellow
            Move-Item -Path $file.FullName -Destination $destinationPath -Force
        } else {
            Write-Host "Le fichier $($file.Name) existe dÃ©jÃ  dans $subFolder/" -ForegroundColor Red
        }
    }

    Write-Host "Organisation du dossier '$FolderPath' terminÃ©e." -ForegroundColor Green

    # VÃ©rifier rÃ©cursivement les sous-dossiers crÃ©Ã©s
    $subFolders = Get-ChildItem -Path $FolderPath -Directory
    foreach ($subFolder in $subFolders) {
        $subFiles = Get-ChildItem -Path $subFolder.FullName -File

        if ($subFiles.Count -gt $MaxFilesPerFolder) {
            Write-Host "`nLe sous-dossier '$($subFolder.FullName)' contient $($subFiles.Count) fichiers, ce qui dÃ©passe le maximum." -ForegroundColor Yellow

            # DÃ©terminer la mÃ©thode d'organisation pour les sous-dossiers
            $subMethod = if ($OrganizationMethod -eq "type") { "alpha" } else { "type" }

            Write-Host "Organisation rÃ©cursive avec la mÃ©thode: $subMethod" -ForegroundColor Cyan
            Organize-Folder -FolderPath $subFolder.FullName -MaxFilesPerFolder $MaxFilesPerFolder -OrganizationMethod $subMethod
        }
    }
}

# Fonction pour organiser tous les dossiers du projet
function Organize-AllFolders {
    param (
        [int]$MaxFilesPerFolder = 10
    )

    $foldersToCheck = @(
        "scripts",
        "workflows",
        "docs",
        "logs",
        "config",
        "mcp"
    )

    foreach ($folder in $foldersToCheck) {
        if (Test-Path -Path $folder -PathType Container) {
            Write-Host "`n=== VÃ©rification du dossier: $folder ===" -ForegroundColor Cyan

            # DÃ©terminer la mÃ©thode d'organisation en fonction du type de dossier
            $method = switch ($folder) {
                "scripts" { "type" }
                "workflows" { "type" }
                "docs" { "alpha" }
                "logs" { "date" }
                "config" { "type" }
                "mcp" { "type" }
                default { "type" }
            }

            Organize-Folder -FolderPath $folder -MaxFilesPerFolder $MaxFilesPerFolder -OrganizationMethod $method
        }
    }
}

# Fonction pour organiser les documents
function Organize-Documents {
    # Verifier si le script d'organisation des documents existe
    $organizeDocsScript = "..\..\D"

    if (Test-Path -Path $organizeDocsScript) {
        Write-Host "Organisation des documents..." -ForegroundColor Cyan
        & powershell -File $organizeDocsScript
    } else {
        Write-Host "Le script d'organisation des documents n'existe pas: $organizeDocsScript" -ForegroundColor Red
    }
}

# ExÃ©cution principale
if ($FolderPath -eq ".") {
    # Mode global: organiser tous les dossiers du projet
    Organize-AllFolders -MaxFilesPerFolder $MaxFilesPerFolder

    # Organiser les documents
    Organize-Documents
} else {
    # Mode spÃ©cifique: organiser un dossier particulier
    Organize-Folder -FolderPath $FolderPath -MaxFilesPerFolder $MaxFilesPerFolder -OrganizationMethod $OrganizationMethod

    # Si le dossier est docs, organiser les documents
    if ($FolderPath -eq "docs" -or $FolderPath -like "*\docs*") {
        Organize-Documents
    }
}


}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}

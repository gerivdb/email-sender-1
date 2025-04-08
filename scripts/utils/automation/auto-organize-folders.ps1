# Script pour organiser automatiquement les dossiers contenant trop de fichiers
# Ce script vérifie si un dossier contient trop de fichiers et les organise en sous-dossiers

param (
    [string]$FolderPath = ".",
    [int]$MaxFilesPerFolder = 10,
    [string]$OrganizationMethod = "type"  # "type", "date", "alpha", "size"
)

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

# Fonction pour obtenir le dossier de destination basé sur la date
function Get-DateFolder {
    param (
        [System.IO.FileInfo]$File
    )

    $year = $File.LastWriteTime.Year
    $month = $File.LastWriteTime.Month.ToString("00")

    return "$year-$month"
}

# Fonction pour obtenir le dossier alphabétique
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

# Fonction pour obtenir le dossier basé sur la taille
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

    # Vérifier si le dossier existe
    if (-not (Test-Path -Path $FolderPath -PathType Container)) {
        Write-Host "Le dossier '$FolderPath' n'existe pas." -ForegroundColor Red
        return
    }

    # Obtenir tous les fichiers dans le dossier (non récursif)
    $files = Get-ChildItem -Path $FolderPath -File

    # Vérifier s'il y a trop de fichiers
    if ($files.Count -le $MaxFilesPerFolder) {
        Write-Host "Le dossier '$FolderPath' contient $($files.Count) fichiers, ce qui est inférieur ou égal au maximum de $MaxFilesPerFolder." -ForegroundColor Green
        return
    }

    Write-Host "Le dossier '$FolderPath' contient $($files.Count) fichiers, ce qui dépasse le maximum de $MaxFilesPerFolder." -ForegroundColor Yellow
    Write-Host "Organisation des fichiers par méthode: $OrganizationMethod" -ForegroundColor Cyan

    # Organiser les fichiers selon la méthode choisie
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

        # Créer le sous-dossier s'il n'existe pas
        if (-not (Test-Path -Path $subFolderPath -PathType Container)) {
            Write-Host "Création du sous-dossier: $subFolderPath" -ForegroundColor Yellow
            New-Item -Path $subFolderPath -ItemType Directory -Force | Out-Null
        }

        # Déplacer le fichier dans le sous-dossier
        $destinationPath = Join-Path -Path $subFolderPath -ChildPath $file.Name

        if (-not (Test-Path -Path $destinationPath)) {
            Write-Host "Déplacement de $($file.Name) vers $subFolder/" -ForegroundColor Yellow
            Move-Item -Path $file.FullName -Destination $destinationPath -Force
        } else {
            Write-Host "Le fichier $($file.Name) existe déjà dans $subFolder/" -ForegroundColor Red
        }
    }

    Write-Host "Organisation du dossier '$FolderPath' terminée." -ForegroundColor Green

    # Vérifier récursivement les sous-dossiers créés
    $subFolders = Get-ChildItem -Path $FolderPath -Directory
    foreach ($subFolder in $subFolders) {
        $subFiles = Get-ChildItem -Path $subFolder.FullName -File

        if ($subFiles.Count -gt $MaxFilesPerFolder) {
            Write-Host "`nLe sous-dossier '$($subFolder.FullName)' contient $($subFiles.Count) fichiers, ce qui dépasse le maximum." -ForegroundColor Yellow

            # Déterminer la méthode d'organisation pour les sous-dossiers
            $subMethod = if ($OrganizationMethod -eq "type") { "alpha" } else { "type" }

            Write-Host "Organisation récursive avec la méthode: $subMethod" -ForegroundColor Cyan
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
            Write-Host "`n=== Vérification du dossier: $folder ===" -ForegroundColor Cyan

            # Déterminer la méthode d'organisation en fonction du type de dossier
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

# Exécution principale
if ($FolderPath -eq ".") {
    # Mode global: organiser tous les dossiers du projet
    Organize-AllFolders -MaxFilesPerFolder $MaxFilesPerFolder

    # Organiser les documents
    Organize-Documents
} else {
    # Mode spécifique: organiser un dossier particulier
    Organize-Folder -FolderPath $FolderPath -MaxFilesPerFolder $MaxFilesPerFolder -OrganizationMethod $OrganizationMethod

    # Si le dossier est docs, organiser les documents
    if ($FolderPath -eq "docs" -or $FolderPath -like "*\docs*") {
        Organize-Documents
    }
}


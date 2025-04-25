# find-project-files.ps1
# Script pour rechercher des fichiers dans le projet
# Ce script fournit des fonctionnalités avancées de recherche de fichiers

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "tools\path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouve: $PathManagerModule"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Parametres du script
param (
    [Parameter(Mandatory = $false)]
    [string]$Directory = ".",

    [Parameter(Mandatory = $false)]
    [string[]]$Pattern = @("*"),

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeDirectories = @(),

    [Parameter(Mandatory = $false)]
    [string[]]$ExcludeFiles = @(),

    [Parameter(Mandatory = $false)]
    [string]$IncludePattern = "",

    [Parameter(Mandatory = $false)]
    [switch]$RelativePaths,

    [Parameter(Mandatory = $false)]
    [switch]$ShowDetails,

    [Parameter(Mandatory = $false)]
    [switch]$ExportCsv,

    [Parameter(Mandatory = $false)]
    [string]$OutputFile = "found_files.csv"
)

# Fonction principale
function Main {
    # Afficher les parametres
    Write-Host "=== Recherche de fichiers ===" -ForegroundColor Cyan
    Write-Host "Repertoire: $Directory"
    Write-Host "Modele(s): $($Pattern -join ', ')"
    Write-Host "Recursif: $Recurse"
    Write-Host "Repertoires exclus: $($ExcludeDirectories -join ', ')"
    Write-Host "Fichiers exclus: $($ExcludeFiles -join ', ')"
    Write-Host "Modele d'inclusion: $IncludePattern"
    Write-Host "Chemins relatifs: $RelativePaths"
    Write-Host "Afficher les details: $ShowDetails"
    Write-Host "Exporter en CSV: $ExportCsv"
    Write-Host "Fichier de sortie: $OutputFile"
    Write-Host ""

    # Rechercher les fichiers
    $files = @()
    if ($Recurse) {
        $files = Get-ChildItem -Path $Directory -Include $Pattern -Recurse -File
    } else {
        $files = Get-ChildItem -Path $Directory -Include $Pattern -File
    }

    # Filtrer les resultats
    $results = @()
    foreach ($file in $files) {
        $exclude = $false
        
        # Verifier si le fichier est dans un repertoire exclu
        foreach ($dir in $ExcludeDirectories) {
            if ($file.FullName -like "*\$dir\*") {
                $exclude = $true
                break
            }
        }
        
        # Verifier si le fichier est exclu
        if (-not $exclude -and $ExcludeFiles -notcontains $file.Name) {
            # Verifier si le fichier correspond au modele d'inclusion
            if (-not $IncludePattern -or $file.Name -like "*$IncludePattern*") {
                $result = [PSCustomObject]@{
                    FullPath = $file.FullName
                    RelativePath = if ($RelativePaths) { Get-RelativePath -AbsolutePath $file.FullName } else { $file.FullName }
                    Name = $file.Name
                    Extension = $file.Extension
                    Size = $file.Length
                    LastModified = $file.LastWriteTime
                    IsReadOnly = $file.IsReadOnly
                }
                $results += $result
            }
        }
    }

    # Afficher le nombre de fichiers trouves
    Write-Host "Nombre de fichiers trouves: $($results.Count)"

    # Si aucun fichier n'est trouve, sortir
    if ($results.Count -eq 0) {
        Write-Host "Aucun fichier trouve correspondant aux criteres de recherche." -ForegroundColor Yellow
        return
    }

    # Afficher les resultats
    if ($ShowDetails) {
        $results | Format-Table -AutoSize
    } else {
        foreach ($result in $results) {
            if ($RelativePaths) {
                Write-Host $result.RelativePath
            } else {
                Write-Host $result.FullPath
            }
        }
    }

    # Exporter les resultats en CSV si demande
    if ($ExportCsv) {
        $results | Export-Csv -Path $OutputFile -NoTypeInformation
        Write-Host "Resultats exportes dans le fichier: $OutputFile" -ForegroundColor Green
    }
}

# Executer la fonction principale
Main

# Find-Files.ps1
# Script PowerShell pour rechercher des fichiers dans le projet
# Ce script fournit des fonctionnalités avancées de recherche de fichiers

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouvé: $PathManagerModule"
    exit 1
}

# Importer le script d'utilitaires pour les chemins
$PathUtilsScript = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "..\..\D"
if (Test-Path -Path $PathUtilsScript) {
    . $PathUtilsScript
} else {
    Write-Error "Script path-utils.ps1 non trouvé: $PathUtilsScript"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# Paramètres du script
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
    # Afficher les paramètres
    Write-Host "=== Recherche de fichiers ===" -ForegroundColor Cyan
    Write-Host "Répertoire: $Directory"
    Write-Host "Modèle(s): $($Pattern -join ', ')"
    Write-Host "Récursif: $Recurse"
    Write-Host "Répertoires exclus: $($ExcludeDirectories -join ', ')"
    Write-Host "Fichiers exclus: $($ExcludeFiles -join ', ')"
    Write-Host "Modèle d'inclusion: $IncludePattern"
    Write-Host "Chemins relatifs: $RelativePaths"
    Write-Host "Afficher les détails: $ShowDetails"
    Write-Host "Exporter en CSV: $ExportCsv"
    Write-Host "Fichier de sortie: $OutputFile"
    Write-Host ""

    # Rechercher les fichiers
    $files = Find-Files -Directory $Directory -Pattern $Pattern -Recurse:$Recurse -ExcludeDirectories $ExcludeDirectories -ExcludeFiles $ExcludeFiles -IncludePattern $IncludePattern

    # Afficher le nombre de fichiers trouvés
    Write-Host "Nombre de fichiers trouvés: $($files.Count)"

    # Si aucun fichier n'est trouvé, sortir
    if ($files.Count -eq 0) {
        Write-Host "Aucun fichier trouvé correspondant aux critères de recherche." -ForegroundColor Yellow
        return
    }

    # Préparer les résultats
    $results = @()
    foreach ($file in $files) {
        $fileInfo = Get-Item -Path $file
        $result = [PSCustomObject]@{
            FullPath = $file
            RelativePath = if ($RelativePaths) { Get-RelativePath -AbsolutePath $file } else { $file }
            Name = $fileInfo.Name
            Extension = $fileInfo.Extension
            Size = $fileInfo.Length
            LastModified = $fileInfo.LastWriteTime
            IsReadOnly = $fileInfo.IsReadOnly
        }
        $results += $result
    }

    # Afficher les résultats
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

    # Exporter les résultats en CSV si demandé
    if ($ExportCsv) {
        $results | Export-Csv -Path $OutputFile -NoTypeInformation
        Write-Host "Résultats exportés dans le fichier: $OutputFile" -ForegroundColor Green
    }
}

# Exécuter la fonction principale
Main


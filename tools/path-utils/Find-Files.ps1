# Find-Files.ps1
# Script PowerShell pour rechercher des fichiers dans le projet
# Ce script fournit des fonctionnalitÃ©s avancÃ©es de recherche de fichiers

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouvÃ©: $PathManagerModule"
    exit 1
}

# Importer le script d'utilitaires pour les chemins
$PathUtilsScript = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "scripts\utils\path-utils.ps1"
if (Test-Path -Path $PathUtilsScript) {
    . $PathUtilsScript
} else {
    Write-Error "Script path-utils.ps1 non trouvÃ©: $PathUtilsScript"
    exit 1
}

# Initialiser le gestionnaire de chemins
Initialize-PathManager

# ParamÃ¨tres du script
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
    # Afficher les paramÃ¨tres
    Write-Host "=== Recherche de fichiers ===" -ForegroundColor Cyan
    Write-Host "RÃ©pertoire: $Directory"
    Write-Host "ModÃ¨le(s): $($Pattern -join ', ')"
    Write-Host "RÃ©cursif: $Recurse"
    Write-Host "RÃ©pertoires exclus: $($ExcludeDirectories -join ', ')"
    Write-Host "Fichiers exclus: $($ExcludeFiles -join ', ')"
    Write-Host "ModÃ¨le d'inclusion: $IncludePattern"
    Write-Host "Chemins relatifs: $RelativePaths"
    Write-Host "Afficher les dÃ©tails: $ShowDetails"
    Write-Host "Exporter en CSV: $ExportCsv"
    Write-Host "Fichier de sortie: $OutputFile"
    Write-Host ""

    # Rechercher les fichiers
    $files = Find-Files -Directory $Directory -Pattern $Pattern -Recurse:$Recurse -ExcludeDirectories $ExcludeDirectories -ExcludeFiles $ExcludeFiles -IncludePattern $IncludePattern

    # Afficher le nombre de fichiers trouvÃ©s
    Write-Host "Nombre de fichiers trouvÃ©s: $($files.Count)"

    # Si aucun fichier n'est trouvÃ©, sortir
    if ($files.Count -eq 0) {
        Write-Host "Aucun fichier trouvÃ© correspondant aux critÃ¨res de recherche." -ForegroundColor Yellow
        return
    }

    # PrÃ©parer les rÃ©sultats
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

    # Afficher les rÃ©sultats
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

    # Exporter les rÃ©sultats en CSV si demandÃ©
    if ($ExportCsv) {
        $results | Export-Csv -Path $OutputFile -NoTypeInformation
        Write-Host "RÃ©sultats exportÃ©s dans le fichier: $OutputFile" -ForegroundColor Green
    }
}

# ExÃ©cuter la fonction principale
Main

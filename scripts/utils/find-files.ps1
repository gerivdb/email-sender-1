# find-files.ps1
# Script PowerShell pour rechercher des fichiers dans le projet
# Ce script est un wrapper autour du script Find-Files.ps1

# Importer le module Path-Manager
$PathManagerModule = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "tools\path-utils\Path-Manager.psm1"
if (Test-Path -Path $PathManagerModule) {
    Import-Module $PathManagerModule -Force
} else {
    Write-Error "Module Path-Manager non trouvÃ©: $PathManagerModule"
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

# Appeler le script Find-Files.ps1
$FindFilesScript = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "tools\path-utils\Find-Files.ps1"
if (Test-Path -Path $FindFilesScript) {
    & $FindFilesScript -Directory $Directory -Pattern $Pattern -Recurse:$Recurse -ExcludeDirectories $ExcludeDirectories -ExcludeFiles $ExcludeFiles -IncludePattern $IncludePattern -RelativePaths:$RelativePaths -ShowDetails:$ShowDetails -ExportCsv:$ExportCsv -OutputFile $OutputFile
} else {
    Write-Error "Script Find-Files.ps1 non trouvÃ©: $FindFilesScript"
    exit 1
}

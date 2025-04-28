# normalize-paths.ps1
# Script PowerShell pour normaliser les chemins dans les fichiers du projet
# Ce script est un wrapper autour du script Normalize-Path.ps1

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
    [string[]]$FileTypes = @("*.json", "*.cmd", "*.ps1", "*.yaml", "*.md"),

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [switch]$FixAccents,

    [Parameter(Mandatory = $false)]
    [switch]$FixSpaces,

    [Parameter(Mandatory = $false)]
    [switch]$FixPaths,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf
)

# Appeler le script Normalize-Path.ps1
$NormalizePathScript = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "tools\path-utils\Normalize-Path.ps1"
if (Test-Path -Path $NormalizePathScript) {
    & $NormalizePathScript -Directory $Directory -FileTypes $FileTypes -Recurse:$Recurse -FixAccents:$FixAccents -FixSpaces:$FixSpaces -FixPaths:$FixPaths -WhatIf:$WhatIf
} else {
    Write-Error "Script Normalize-Path.ps1 non trouvÃ©: $NormalizePathScript"
    exit 1
}

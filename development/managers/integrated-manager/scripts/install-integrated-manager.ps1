<#
.SYNOPSIS
    Script d'installation du gestionnaire intÃ©grÃ©.

.DESCRIPTION
    Ce script installe le gestionnaire intÃ©grÃ© en crÃ©ant les fichiers nÃ©cessaires et en configurant l'environnement.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par dÃ©faut, utilise le rÃ©pertoire courant.

.PARAMETER Force
    Indique si les fichiers existants doivent Ãªtre Ã©crasÃ©s.

.EXAMPLE
    .\install-integrated-manager.ps1
    Installe le gestionnaire intÃ©grÃ© dans le rÃ©pertoire courant.

.EXAMPLE
    .\install-integrated-manager.ps1 -ProjectRoot "D:\MonProjet" -Force
    Installe le gestionnaire intÃ©grÃ© dans le rÃ©pertoire D:\MonProjet et Ã©crase les fichiers existants.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = ".",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# DÃ©terminer le chemin du projet
if ($ProjectRoot -eq ".") {
    $ProjectRoot = $PWD.Path
    
    # Remonter jusqu'Ã  trouver le rÃ©pertoire .git
    while (-not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container) -and 
           -not [string]::IsNullOrEmpty($ProjectRoot)) {
        $ProjectRoot = Split-Path -Path $ProjectRoot -Parent
    }
    
    if ([string]::IsNullOrEmpty($ProjectRoot) -or -not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container)) {
        $ProjectRoot = $PWD.Path
    }
}

# VÃ©rifier que le rÃ©pertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le rÃ©pertoire du projet n'existe pas : $ProjectRoot"
    exit 1
}

# Chemins des fichiers source
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$integratedManagerScript = Join-Path -Path $scriptPath -ChildPath "integrated-manager.ps1"
$integratedManagerDoc = Join-Path -Path $ProjectRoot -ChildPath "development\docs\guides\methodologies\integrated_manager.md"
$unifiedConfigJson = Join-Path -Path $ProjectRoot -ChildPath "development\config\unified-config.json"

# VÃ©rifier que les fichiers source existent
if (-not (Test-Path -Path $integratedManagerScript)) {
    Write-Error "Le script du gestionnaire intÃ©grÃ© est introuvable : $integratedManagerScript"
    exit 1
}

if (-not (Test-Path -Path $integratedManagerDoc)) {
    Write-Warning "La documentation du gestionnaire intÃ©grÃ© est introuvable : $integratedManagerDoc"
}

if (-not (Test-Path -Path $unifiedConfigJson)) {
    Write-Warning "Le fichier de configuration unifiÃ© est introuvable : $unifiedConfigJson"
}

# Chemins des liens symboliques
$linkPaths = @{
    "tools\scripts\integrated-manager.ps1" = $integratedManagerScript
    "scripts\integrated-manager.ps1" = $integratedManagerScript
}

# CrÃ©er les rÃ©pertoires nÃ©cessaires
$directories = @(
    "development\config",
    "development\docs\guides\methodologies",
    "tools\scripts",
    "scripts"
)

foreach ($directory in $directories) {
    $dirPath = Join-Path -Path $ProjectRoot -ChildPath $directory
    if (-not (Test-Path -Path $dirPath -PathType Container)) {
        Write-Host "CrÃ©ation du rÃ©pertoire : $dirPath" -ForegroundColor Green
        New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
    }
}

# Copier les fichiers
$filesToCopy = @{
    $integratedManagerScript = Join-Path -Path $ProjectRoot -ChildPath "development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1"
    $integratedManagerDoc = Join-Path -Path $ProjectRoot -ChildPath "development\docs\guides\methodologies\integrated_manager.md"
    $unifiedConfigJson = Join-Path -Path $ProjectRoot -ChildPath "development\config\unified-config.json"
}

foreach ($source in $filesToCopy.Keys) {
    $destination = $filesToCopy[$source]
    
    if (Test-Path -Path $source) {
        if ((Test-Path -Path $destination) -and -not $Force) {
            Write-Warning "Le fichier existe dÃ©jÃ  et ne sera pas Ã©crasÃ© : $destination"
        } else {
            Write-Host "Copie du fichier : $source -> $destination" -ForegroundColor Green
            Copy-Item -Path $source -Destination $destination -Force
        }
    } else {
        Write-Warning "Le fichier source est introuvable : $source"
    }
}

# CrÃ©er les liens symboliques
foreach ($link in $linkPaths.Keys) {
    $linkPath = Join-Path -Path $ProjectRoot -ChildPath $link
    $targetPath = $linkPaths[$link]
    
    if ((Test-Path -Path $linkPath) -and -not $Force) {
        Write-Warning "Le lien existe dÃ©jÃ  et ne sera pas Ã©crasÃ© : $linkPath"
    } else {
        if (Test-Path -Path $linkPath) {
            Remove-Item -Path $linkPath -Force
        }
        
        try {
            # CrÃ©er un lien symbolique si possible
            if ($PSVersionTable.PSVersion.Major -ge 5) {
                Write-Host "CrÃ©ation du lien symbolique : $linkPath -> $targetPath" -ForegroundColor Green
                New-Item -Path $linkPath -ItemType SymbolicLink -Target $targetPath -Force | Out-Null
            } else {
                # Sinon, crÃ©er un fichier de redirection
                Write-Host "CrÃ©ation du fichier de redirection : $linkPath -> $targetPath" -ForegroundColor Green
                @"
# Ce fichier est une redirection vers le script du gestionnaire intÃ©grÃ©
# Le script rÃ©el se trouve Ã  l'emplacement : $targetPath

# Rediriger vers le script rÃ©el
& "$targetPath" @args
"@ | Set-Content -Path $linkPath -Encoding UTF8
            }
        } catch {
            Write-Warning "Impossible de crÃ©er le lien symbolique : $linkPath -> $targetPath"
            Write-Warning "Erreur : $_"
            
            # CrÃ©er un fichier de redirection en cas d'Ã©chec
            Write-Host "CrÃ©ation du fichier de redirection : $linkPath -> $targetPath" -ForegroundColor Green
            @"
# Ce fichier est une redirection vers le script du gestionnaire intÃ©grÃ©
# Le script rÃ©el se trouve Ã  l'emplacement : $targetPath

# Rediriger vers le script rÃ©el
& "$targetPath" @args
"@ | Set-Content -Path $linkPath -Encoding UTF8
        }
    }
}

# CrÃ©er un raccourci dans le dossier principal
$shortcutPath = Join-Path -Path $ProjectRoot -ChildPath "integrated-manager.ps1"
if ((Test-Path -Path $shortcutPath) -and -not $Force) {
    Write-Warning "Le raccourci existe dÃ©jÃ  et ne sera pas Ã©crasÃ© : $shortcutPath"
} else {
    Write-Host "CrÃ©ation du raccourci : $shortcutPath" -ForegroundColor Green
    @"
# Ce fichier est un raccourci vers le script du gestionnaire intÃ©grÃ©
# Le script rÃ©el se trouve Ã  l'emplacement : development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1

# Rediriger vers le script rÃ©el
& "development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1" @args
"@ | Set-Content -Path $shortcutPath -Encoding UTF8
}

# VÃ©rifier que les fichiers ont Ã©tÃ© correctement installÃ©s
$filesToCheck = @(
    "development\\managers\\integrated-manager\\scripts\\integrated-manager\.ps1",
    "development\docs\guides\methodologies\integrated_manager.md",
    "development\config\unified-config.json",
    "tools\scripts\integrated-manager.ps1",
    "scripts\integrated-manager.ps1",
    "integrated-manager.ps1"
)

$allFilesExist = $true
foreach ($file in $filesToCheck) {
    $filePath = Join-Path -Path $ProjectRoot -ChildPath $file
    if (-not (Test-Path -Path $filePath)) {
        Write-Warning "Le fichier n'a pas Ã©tÃ© correctement installÃ© : $filePath"
        $allFilesExist = $false
    }
}

if ($allFilesExist) {
    Write-Host "Le gestionnaire intÃ©grÃ© a Ã©tÃ© installÃ© avec succÃ¨s !" -ForegroundColor Green
    Write-Host "Pour l'utiliser, exÃ©cutez :" -ForegroundColor Cyan
    Write-Host "  - Depuis le dossier principal : .\integrated-manager.ps1" -ForegroundColor Cyan
    Write-Host "  - Depuis n'importe quel dossier : .\scripts\integrated-manager.ps1" -ForegroundColor Cyan
    Write-Host "  - Depuis n'importe quel dossier : .\tools\scripts\integrated-manager.ps1" -ForegroundColor Cyan
} else {
    Write-Warning "Le gestionnaire intÃ©grÃ© n'a pas Ã©tÃ© correctement installÃ©."
}


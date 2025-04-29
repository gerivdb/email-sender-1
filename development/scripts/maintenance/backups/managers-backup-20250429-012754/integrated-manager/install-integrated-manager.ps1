<#
.SYNOPSIS
    Script d'installation du gestionnaire intégré.

.DESCRIPTION
    Ce script installe le gestionnaire intégré en créant les fichiers nécessaires et en configurant l'environnement.

.PARAMETER ProjectRoot
    Chemin vers la racine du projet. Par défaut, utilise le répertoire courant.

.PARAMETER Force
    Indique si les fichiers existants doivent être écrasés.

.EXAMPLE
    .\install-integrated-manager.ps1
    Installe le gestionnaire intégré dans le répertoire courant.

.EXAMPLE
    .\install-integrated-manager.ps1 -ProjectRoot "D:\MonProjet" -Force
    Installe le gestionnaire intégré dans le répertoire D:\MonProjet et écrase les fichiers existants.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ProjectRoot = ".",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Déterminer le chemin du projet
if ($ProjectRoot -eq ".") {
    $ProjectRoot = $PWD.Path
    
    # Remonter jusqu'à trouver le répertoire .git
    while (-not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container) -and 
           -not [string]::IsNullOrEmpty($ProjectRoot)) {
        $ProjectRoot = Split-Path -Path $ProjectRoot -Parent
    }
    
    if ([string]::IsNullOrEmpty($ProjectRoot) -or -not (Test-Path -Path (Join-Path -Path $ProjectRoot -ChildPath ".git") -PathType Container)) {
        $ProjectRoot = $PWD.Path
    }
}

# Vérifier que le répertoire du projet existe
if (-not (Test-Path -Path $ProjectRoot -PathType Container)) {
    Write-Error "Le répertoire du projet n'existe pas : $ProjectRoot"
    exit 1
}

# Chemins des fichiers source
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$integratedManagerScript = Join-Path -Path $scriptPath -ChildPath "integrated-manager.ps1"
$integratedManagerDoc = Join-Path -Path $ProjectRoot -ChildPath "development\docs\guides\methodologies\integrated_manager.md"
$unifiedConfigJson = Join-Path -Path $ProjectRoot -ChildPath "development\config\unified-config.json"

# Vérifier que les fichiers source existent
if (-not (Test-Path -Path $integratedManagerScript)) {
    Write-Error "Le script du gestionnaire intégré est introuvable : $integratedManagerScript"
    exit 1
}

if (-not (Test-Path -Path $integratedManagerDoc)) {
    Write-Warning "La documentation du gestionnaire intégré est introuvable : $integratedManagerDoc"
}

if (-not (Test-Path -Path $unifiedConfigJson)) {
    Write-Warning "Le fichier de configuration unifié est introuvable : $unifiedConfigJson"
}

# Chemins des liens symboliques
$linkPaths = @{
    "tools\scripts\integrated-manager.ps1" = $integratedManagerScript
    "scripts\integrated-manager.ps1" = $integratedManagerScript
}

# Créer les répertoires nécessaires
$directories = @(
    "development\config",
    "development\docs\guides\methodologies",
    "tools\scripts",
    "scripts"
)

foreach ($directory in $directories) {
    $dirPath = Join-Path -Path $ProjectRoot -ChildPath $directory
    if (-not (Test-Path -Path $dirPath -PathType Container)) {
        Write-Host "Création du répertoire : $dirPath" -ForegroundColor Green
        New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
    }
}

# Copier les fichiers
$filesToCopy = @{
    $integratedManagerScript = Join-Path -Path $ProjectRoot -ChildPath "development\scripts\integrated-manager.ps1"
    $integratedManagerDoc = Join-Path -Path $ProjectRoot -ChildPath "development\docs\guides\methodologies\integrated_manager.md"
    $unifiedConfigJson = Join-Path -Path $ProjectRoot -ChildPath "development\config\unified-config.json"
}

foreach ($source in $filesToCopy.Keys) {
    $destination = $filesToCopy[$source]
    
    if (Test-Path -Path $source) {
        if ((Test-Path -Path $destination) -and -not $Force) {
            Write-Warning "Le fichier existe déjà et ne sera pas écrasé : $destination"
        } else {
            Write-Host "Copie du fichier : $source -> $destination" -ForegroundColor Green
            Copy-Item -Path $source -Destination $destination -Force
        }
    } else {
        Write-Warning "Le fichier source est introuvable : $source"
    }
}

# Créer les liens symboliques
foreach ($link in $linkPaths.Keys) {
    $linkPath = Join-Path -Path $ProjectRoot -ChildPath $link
    $targetPath = $linkPaths[$link]
    
    if ((Test-Path -Path $linkPath) -and -not $Force) {
        Write-Warning "Le lien existe déjà et ne sera pas écrasé : $linkPath"
    } else {
        if (Test-Path -Path $linkPath) {
            Remove-Item -Path $linkPath -Force
        }
        
        try {
            # Créer un lien symbolique si possible
            if ($PSVersionTable.PSVersion.Major -ge 5) {
                Write-Host "Création du lien symbolique : $linkPath -> $targetPath" -ForegroundColor Green
                New-Item -Path $linkPath -ItemType SymbolicLink -Target $targetPath -Force | Out-Null
            } else {
                # Sinon, créer un fichier de redirection
                Write-Host "Création du fichier de redirection : $linkPath -> $targetPath" -ForegroundColor Green
                @"
# Ce fichier est une redirection vers le script du gestionnaire intégré
# Le script réel se trouve à l'emplacement : $targetPath

# Rediriger vers le script réel
& "$targetPath" @args
"@ | Set-Content -Path $linkPath -Encoding UTF8
            }
        } catch {
            Write-Warning "Impossible de créer le lien symbolique : $linkPath -> $targetPath"
            Write-Warning "Erreur : $_"
            
            # Créer un fichier de redirection en cas d'échec
            Write-Host "Création du fichier de redirection : $linkPath -> $targetPath" -ForegroundColor Green
            @"
# Ce fichier est une redirection vers le script du gestionnaire intégré
# Le script réel se trouve à l'emplacement : $targetPath

# Rediriger vers le script réel
& "$targetPath" @args
"@ | Set-Content -Path $linkPath -Encoding UTF8
        }
    }
}

# Créer un raccourci dans le dossier principal
$shortcutPath = Join-Path -Path $ProjectRoot -ChildPath "integrated-manager.ps1"
if ((Test-Path -Path $shortcutPath) -and -not $Force) {
    Write-Warning "Le raccourci existe déjà et ne sera pas écrasé : $shortcutPath"
} else {
    Write-Host "Création du raccourci : $shortcutPath" -ForegroundColor Green
    @"
# Ce fichier est un raccourci vers le script du gestionnaire intégré
# Le script réel se trouve à l'emplacement : development\scripts\integrated-manager.ps1

# Rediriger vers le script réel
& "development\scripts\integrated-manager.ps1" @args
"@ | Set-Content -Path $shortcutPath -Encoding UTF8
}

# Vérifier que les fichiers ont été correctement installés
$filesToCheck = @(
    "development\scripts\integrated-manager.ps1",
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
        Write-Warning "Le fichier n'a pas été correctement installé : $filePath"
        $allFilesExist = $false
    }
}

if ($allFilesExist) {
    Write-Host "Le gestionnaire intégré a été installé avec succès !" -ForegroundColor Green
    Write-Host "Pour l'utiliser, exécutez :" -ForegroundColor Cyan
    Write-Host "  - Depuis le dossier principal : .\integrated-manager.ps1" -ForegroundColor Cyan
    Write-Host "  - Depuis n'importe quel dossier : .\scripts\integrated-manager.ps1" -ForegroundColor Cyan
    Write-Host "  - Depuis n'importe quel dossier : .\tools\scripts\integrated-manager.ps1" -ForegroundColor Cyan
} else {
    Write-Warning "Le gestionnaire intégré n'a pas été correctement installé."
}

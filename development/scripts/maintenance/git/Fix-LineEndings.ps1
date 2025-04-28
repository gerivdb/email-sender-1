#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige les fins de ligne dans les fichiers du dÃ©pÃ´t Git.

.DESCRIPTION
    Ce script corrige les fins de ligne dans les fichiers du dÃ©pÃ´t Git en fonction
    des rÃ¨gles dÃ©finies dans le fichier .gitattributes.

.PARAMETER Path
    Chemin vers le rÃ©pertoire Ã  traiter. Par dÃ©faut, le rÃ©pertoire courant.

.PARAMETER Force
    Force la normalisation des fins de ligne mÃªme si les fichiers n'ont pas Ã©tÃ© modifiÃ©s.

.EXAMPLE
    .\Fix-LineEndings.ps1

.EXAMPLE
    .\Fix-LineEndings.ps1 -Path "D:\MonProjet" -Force

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter()]
    [string]$Path = (Get-Location),
    
    [Parameter()]
    [switch]$Force
)

# VÃ©rifier si Git est installÃ©
try {
    $gitVersion = git --version
    Write-Host "Git dÃ©tectÃ© : $gitVersion" -ForegroundColor Green
}
catch {
    Write-Error "Git n'est pas installÃ© ou n'est pas accessible dans le PATH."
    return
}

# VÃ©rifier si le rÃ©pertoire est un dÃ©pÃ´t Git
$isGitRepo = $false
try {
    Push-Location $Path
    $isGitRepo = (git rev-parse --is-inside-work-tree) -eq "true"
    Pop-Location
}
catch {
    Write-Error "Le rÃ©pertoire spÃ©cifiÃ© n'est pas un dÃ©pÃ´t Git valide."
    return
}

if (-not $isGitRepo) {
    Write-Error "Le rÃ©pertoire spÃ©cifiÃ© n'est pas un dÃ©pÃ´t Git valide."
    return
}

# VÃ©rifier si le fichier .gitattributes existe
$gitAttributesPath = Join-Path -Path $Path -ChildPath ".gitattributes"
if (-not (Test-Path -Path $gitAttributesPath -PathType Leaf)) {
    Write-Error "Le fichier .gitattributes n'existe pas dans le dÃ©pÃ´t."
    return
}

# Configurer Git pour qu'il utilise les rÃ¨gles dÃ©finies dans .gitattributes
Write-Host "Configuration de Git pour utiliser les rÃ¨gles dÃ©finies dans .gitattributes..." -ForegroundColor Cyan
Push-Location $Path
git config --local core.autocrlf false
git config --local core.eol native

# Normaliser les fins de ligne
if ($Force) {
    Write-Host "Normalisation forcÃ©e des fins de ligne..." -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("Tous les fichiers", "Normaliser les fins de ligne")) {
        # RÃ©initialiser l'index
        git rm --cached -r .
        # Ajouter tous les fichiers Ã  l'index
        git add .
    }
}
else {
    Write-Host "Normalisation des fins de ligne pour les fichiers modifiÃ©s..." -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("Fichiers modifiÃ©s", "Normaliser les fins de ligne")) {
        # Obtenir la liste des fichiers modifiÃ©s
        $modifiedFiles = git diff --name-only
        
        # Normaliser les fins de ligne pour chaque fichier modifiÃ©
        foreach ($file in $modifiedFiles) {
            if (Test-Path -Path $file -PathType Leaf) {
                Write-Host "  Normalisation de $file..." -ForegroundColor White
                git add $file
            }
        }
    }
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© :" -ForegroundColor Cyan
Write-Host "  Les fins de ligne ont Ã©tÃ© normalisÃ©es selon les rÃ¨gles dÃ©finies dans .gitattributes." -ForegroundColor Green
Write-Host "  Vous pouvez maintenant effectuer un commit pour enregistrer les modifications." -ForegroundColor Green

Pop-Location

#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige les fins de ligne dans les fichiers du dépôt Git.

.DESCRIPTION
    Ce script corrige les fins de ligne dans les fichiers du dépôt Git en fonction
    des règles définies dans le fichier .gitattributes.

.PARAMETER Path
    Chemin vers le répertoire à traiter. Par défaut, le répertoire courant.

.PARAMETER Force
    Force la normalisation des fins de ligne même si les fichiers n'ont pas été modifiés.

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

# Vérifier si Git est installé
try {
    $gitVersion = git --version
    Write-Host "Git détecté : $gitVersion" -ForegroundColor Green
}
catch {
    Write-Error "Git n'est pas installé ou n'est pas accessible dans le PATH."
    return
}

# Vérifier si le répertoire est un dépôt Git
$isGitRepo = $false
try {
    Push-Location $Path
    $isGitRepo = (git rev-parse --is-inside-work-tree) -eq "true"
    Pop-Location
}
catch {
    Write-Error "Le répertoire spécifié n'est pas un dépôt Git valide."
    return
}

if (-not $isGitRepo) {
    Write-Error "Le répertoire spécifié n'est pas un dépôt Git valide."
    return
}

# Vérifier si le fichier .gitattributes existe
$gitAttributesPath = Join-Path -Path $Path -ChildPath ".gitattributes"
if (-not (Test-Path -Path $gitAttributesPath -PathType Leaf)) {
    Write-Error "Le fichier .gitattributes n'existe pas dans le dépôt."
    return
}

# Configurer Git pour qu'il utilise les règles définies dans .gitattributes
Write-Host "Configuration de Git pour utiliser les règles définies dans .gitattributes..." -ForegroundColor Cyan
Push-Location $Path
git config --local core.autocrlf false
git config --local core.eol native

# Normaliser les fins de ligne
if ($Force) {
    Write-Host "Normalisation forcée des fins de ligne..." -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("Tous les fichiers", "Normaliser les fins de ligne")) {
        # Réinitialiser l'index
        git rm --cached -r .
        # Ajouter tous les fichiers à l'index
        git add .
    }
}
else {
    Write-Host "Normalisation des fins de ligne pour les fichiers modifiés..." -ForegroundColor Cyan
    if ($PSCmdlet.ShouldProcess("Fichiers modifiés", "Normaliser les fins de ligne")) {
        # Obtenir la liste des fichiers modifiés
        $modifiedFiles = git diff --name-only
        
        # Normaliser les fins de ligne pour chaque fichier modifié
        foreach ($file in $modifiedFiles) {
            if (Test-Path -Path $file -PathType Leaf) {
                Write-Host "  Normalisation de $file..." -ForegroundColor White
                git add $file
            }
        }
    }
}

# Afficher un résumé
Write-Host "`nRésumé :" -ForegroundColor Cyan
Write-Host "  Les fins de ligne ont été normalisées selon les règles définies dans .gitattributes." -ForegroundColor Green
Write-Host "  Vous pouvez maintenant effectuer un commit pour enregistrer les modifications." -ForegroundColor Green

Pop-Location

<#
.SYNOPSIS
    Script d'installation de Hygen pour le projet n8n.

.DESCRIPTION
    Ce script installe Hygen, crée la structure de dossiers nécessaire et configure les générateurs.

.EXAMPLE
    .\install-hygen.ps1

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-01
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param ()

$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Installation de Hygen pour n8n" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host

# Vérifier si npm est installé
try {
    $npmVersion = npm --version
    Write-Host "npm version $npmVersion détecté." -ForegroundColor Green
}
catch {
    Write-Host "npm n'est pas installé ou n'est pas dans le PATH." -ForegroundColor Red
    Write-Host "Veuillez installer Node.js et npm avant de continuer." -ForegroundColor Red
    exit 1
}

# Installer Hygen
Write-Host "`nInstallation de Hygen..." -ForegroundColor Yellow
if ($PSCmdlet.ShouldProcess("Hygen", "Installer")) {
    try {
        Push-Location $projectRoot
        npm install --save-dev hygen
        Pop-Location
        Write-Host "Hygen installé avec succès." -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de l'installation de Hygen: $_" -ForegroundColor Red
        exit 1
    }
}

# Initialiser Hygen
Write-Host "`nInitialisation de Hygen..." -ForegroundColor Yellow
if ($PSCmdlet.ShouldProcess("Hygen", "Initialiser")) {
    try {
        Push-Location $projectRoot
        npx hygen init self
        Pop-Location
        Write-Host "Hygen initialisé avec succès." -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de l'initialisation de Hygen: $_" -ForegroundColor Red
        exit 1
    }
}

# Créer la structure de dossiers
Write-Host "`nCréation de la structure de dossiers..." -ForegroundColor Yellow
if ($PSCmdlet.ShouldProcess("Structure de dossiers", "Créer")) {
    try {
        & "$scriptPath\ensure-hygen-structure.ps1"
        Write-Host "Structure de dossiers créée avec succès." -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de la création de la structure de dossiers: $_" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nInstallation de Hygen terminée avec succès." -ForegroundColor Cyan
Write-Host "Vous pouvez maintenant utiliser les générateurs pour créer des composants n8n." -ForegroundColor Cyan
Write-Host "Consultez le guide d'utilisation: n8n/docs/hygen-guide.md" -ForegroundColor Cyan

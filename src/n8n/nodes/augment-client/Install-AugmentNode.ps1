<#
.SYNOPSIS
    Installe le node Augment Client pour n8n.

.DESCRIPTION
    Ce script installe le node Augment Client pour n8n en compilant le code TypeScript,
    en copiant les fichiers nécessaires dans le répertoire des custom nodes de n8n,
    et en installant le module AugmentIntegration si nécessaire.

.PARAMETER Force
    Force la réinstallation du node même s'il est déjà installé.

.EXAMPLE
    .\Install-AugmentNode.ps1
    .\Install-AugmentNode.ps1 -Force
#>

[CmdletBinding()]
param (
    [Parameter()]
    [switch]$Force
)

# Fonction pour vérifier si une commande existe
function Test-Command {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    $exists = $null -ne (Get-Command -Name $Command -ErrorAction SilentlyContinue)
    return $exists
}

# Vérifier si npm est installé
if (-not (Test-Command -Command "npm")) {
    Write-Error "npm n'est pas installé ou n'est pas dans le PATH. Veuillez installer Node.js et npm avant de continuer."
    exit 1
}

# Vérifier si n8n est installé
if (-not (Test-Command -Command "n8n")) {
    Write-Error "n8n n'est pas installé ou n'est pas dans le PATH. Veuillez installer n8n avant de continuer."
    exit 1
}

# Obtenir le chemin du répertoire courant
$currentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -Path $currentDir

# Installer les dépendances
Write-Host "Installation des dépendances..." -ForegroundColor Cyan
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Error "Erreur lors de l'installation des dépendances."
    exit 1
}

# Compiler le code TypeScript
Write-Host "Compilation du code TypeScript..." -ForegroundColor Cyan
npx tsc
if ($LASTEXITCODE -ne 0) {
    Write-Error "Erreur lors de la compilation du code TypeScript."
    exit 1
}

# Créer les répertoires dist/nodes et dist/credentials si nécessaires
if (-not (Test-Path -Path "dist\nodes")) {
    New-Item -Path "dist\nodes" -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -Path "dist\credentials")) {
    New-Item -Path "dist\credentials" -ItemType Directory -Force | Out-Null
}

# Copier l'icône SVG
Write-Host "Copie de l'icône SVG..." -ForegroundColor Cyan
Copy-Item -Path "augment.svg" -Destination "dist\nodes\augment.svg" -Force

# Obtenir le répertoire des custom nodes de n8n
$n8nCustomPath = ""
$helpText = n8n --help | Select-String "custom"
if ($helpText) {
    $match = $helpText -match "custom-extensions-path\s+([^\s]+)"
    if ($matches) {
        $n8nCustomPath = $matches[1]
    }
}

if (-not $n8nCustomPath) {
    # Chemin par défaut si non trouvé
    $n8nCustomPath = Join-Path -Path $env:APPDATA -ChildPath "n8n\custom"
}

# Créer le répertoire des custom nodes si nécessaire
if (-not (Test-Path -Path $n8nCustomPath)) {
    New-Item -Path $n8nCustomPath -ItemType Directory -Force | Out-Null
}

# Créer le répertoire pour le node
$nodePath = Join-Path -Path $n8nCustomPath -ChildPath "nodes\n8n-nodes-augment-client"
if (-not (Test-Path -Path $nodePath)) {
    New-Item -Path $nodePath -ItemType Directory -Force | Out-Null
}

# Copier les fichiers
Write-Host "Copie des fichiers vers $nodePath..." -ForegroundColor Cyan
Copy-Item -Path "dist\*" -Destination "$nodePath\dist\" -Recurse -Force
Copy-Item -Path "package.json" -Destination $nodePath -Force
Copy-Item -Path "index.js" -Destination $nodePath -Force

# Installer le module AugmentIntegration
Write-Host "Installation du module AugmentIntegration..." -ForegroundColor Cyan
$installScriptPath = Join-Path -Path $currentDir -ChildPath "install-augment-integration.ps1"
& $installScriptPath -Force:$Force
if ($LASTEXITCODE -ne 0) {
    Write-Warning "L'installation du module AugmentIntegration a échoué. Vous devrez peut-être l'installer manuellement."
}

Write-Host "`nInstallation terminée avec succès!" -ForegroundColor Green
Write-Host "`nPour utiliser le node Augment Client:" -ForegroundColor Yellow
Write-Host "1. Redémarrez n8n"
Write-Host "2. Recherchez 'Augment Client' dans la liste des nodes"
Write-Host "3. Configurez les credentials si nécessaire"
Write-Host "`nExemples de workflows disponibles dans:" -ForegroundColor Yellow
Write-Host "src/n8n/workflows/examples/"

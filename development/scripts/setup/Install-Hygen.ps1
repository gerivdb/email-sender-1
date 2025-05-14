#Requires -Version 5.1
<#
.SYNOPSIS
    Installe et configure Hygen pour les templates de modes opérationnels.

.DESCRIPTION
    Ce script installe Hygen via npm et configure les templates pour les modes opérationnels.
    Il crée également les liens symboliques nécessaires pour que Hygen puisse trouver les templates.

.EXAMPLE
    .\Install-Hygen.ps1

.NOTES
    Auteur: Généré automatiquement
    Date de création: 2025-05-25
#>

[CmdletBinding()]
param()

# Vérifier si Node.js est installé
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Error "Node.js n'est pas installé. Veuillez installer Node.js avant d'exécuter ce script."
    exit 1
}

# Vérifier si npm est installé
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Error "npm n'est pas installé. Veuillez installer npm avant d'exécuter ce script."
    exit 1
}

# Installer Hygen globalement
Write-Host "Installation de Hygen..." -ForegroundColor Cyan
npm install -g hygen

# Vérifier si l'installation a réussi
if (-not (Get-Command hygen -ErrorAction SilentlyContinue)) {
    Write-Error "L'installation de Hygen a échoué. Veuillez vérifier les erreurs npm."
    exit 1
}

# Définir les chemins
$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "../../..")
$templatesDir = Join-Path $projectRoot "development/templates/_templates"
$hygenConfigDir = Join-Path $projectRoot ".hygen.js"

# Créer le fichier de configuration Hygen
$hygenConfig = @"
module.exports = {
  templates: `"./development/templates/_templates`",
  helpers: {
    now: () => new Date().toISOString().split('T')[0],
    capitalize: (text) => text.charAt(0).toUpperCase() + text.slice(1).toLowerCase(),
    lowercase: (text) => text.toLowerCase(),
    uppercase: (text) => text.toUpperCase()
  }
}
"@

# Écrire le fichier de configuration
Write-Host "Création du fichier de configuration Hygen..." -ForegroundColor Cyan
Set-Content -Path $hygenConfigDir -Value $hygenConfig -Force

# Vérifier si les templates existent
if (-not (Test-Path $templatesDir)) {
    Write-Error "Le répertoire des templates n'existe pas: $templatesDir"
    exit 1
}

# Afficher les instructions d'utilisation
Write-Host @"

Hygen a été installé et configuré avec succès!

Pour utiliser les templates:

1. Créer un nouveau mode:
   hygen mode new --name MODE_NAME --description "Description du mode" --category "Catégorie"

2. Ajouter une commande à un mode existant:
   hygen mode add-command --mode MODE_NAME --name COMMAND_NAME --description "Description de la commande"

3. Créer un nouveau workflow:
   hygen mode add-workflow --name WORKFLOW_NAME --modes "MODE1,MODE2,MODE3" --description "Description du workflow"

Pour plus d'informations, consultez le fichier README.md dans le répertoire des templates.

"@ -ForegroundColor Green

# Fin du script
Write-Host "Installation terminée." -ForegroundColor Green

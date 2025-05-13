# Script pour créer un nouveau générateur de templates avec Hygen
param (
    [Parameter(Mandatory=$true)]
    [string]$TemplateName
)

# Chemin du répertoire des templates
$templatesDir = Join-Path $PSScriptRoot "_templates"

# Vérifier si le répertoire des templates existe
if (-not (Test-Path $templatesDir)) {
    Write-Host "Création du répertoire des templates..."
    New-Item -Path $templatesDir -ItemType Directory | Out-Null
}

# Définir la variable d'environnement HYGEN_TMPLS
$env:HYGEN_TMPLS = $templatesDir

# Exécuter la commande Hygen pour créer un nouveau générateur
$hygenCmd = "hygen init templates $TemplateName"
Write-Host "Exécution de la commande: $hygenCmd"
Invoke-Expression $hygenCmd

# Réinitialiser la variable d'environnement
Remove-Item Env:\HYGEN_TMPLS

Write-Host "Création du générateur '$TemplateName' terminée."

# Script pour générer des templates avec Hygen
param (
    [Parameter(Mandatory=$true)]
    [string]$Generator,
    
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [Parameter(Mandatory=$false)]
    [string]$Action = "new",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Chemin du répertoire des templates
$templatesDir = Join-Path $PSScriptRoot "_templates"

# Vérifier si le générateur existe
$generatorDir = Join-Path $templatesDir $Generator
if (-not (Test-Path $generatorDir)) {
    Write-Error "Le générateur '$Generator' n'existe pas dans le répertoire des templates."
    exit 1
}

# Construire la commande Hygen
$hygenCmd = "hygen $Generator $Action $Name"
if ($Force) {
    $hygenCmd += " --force"
}

# Définir la variable d'environnement HYGEN_TMPLS
$env:HYGEN_TMPLS = $templatesDir

# Exécuter la commande Hygen
Write-Host "Exécution de la commande: $hygenCmd"
Invoke-Expression $hygenCmd

# Réinitialiser la variable d'environnement
Remove-Item Env:\HYGEN_TMPLS

Write-Host "Génération terminée."

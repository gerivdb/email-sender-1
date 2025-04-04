# Modèle de script PowerShell avec encodage UTF-8 avec BOM
# Ce modèle garantit que les caractères français s'affichent correctement dans le terminal

<#
.SYNOPSIS
    Description courte du script.

.DESCRIPTION
    Description détaillée du script.

.PARAMETER Param1
    Description du paramètre 1.

.PARAMETER Param2
    Description du paramètre 2.

.EXAMPLE
    .\script-template.ps1 -Param1 "Valeur1" -Param2 "Valeur2"
    Explication de l'exemple.

.NOTES
    Nom du fichier    : script-template.ps1
    Auteur           : Votre nom
    Date de création : $(Get-Date -Format "dd/MM/yyyy")
    Version          : 1.0
#>

param (
    [Parameter(Mandatory=$false, HelpMessage="Description du paramètre 1")]
    [string]$Param1 = "Valeur par défaut",

    [Parameter(Mandatory=$false, HelpMessage="Description du paramètre 2")]
    [string]$Param2 = "Valeur par défaut"
)

# Afficher un en-tête avec des caractères français
Write-Host "=== Titre du script avec caractères français : é è ê ë à ç ù ===" -ForegroundColor Cyan

# Fonction d'exemple avec des caractères français
function Show-Example {
    param (
        [string]$Message = "Message par défaut avec caractères français : é è ê ë à ç ù"
    )
    
    Write-Host $Message -ForegroundColor Green
}

# Corps principal du script
Write-Host "Exécution du script avec les paramètres :" -ForegroundColor Yellow
Write-Host "Param1 : $Param1" -ForegroundColor Yellow
Write-Host "Param2 : $Param2" -ForegroundColor Yellow

# Appel de la fonction d'exemple
Show-Example

# Afficher un message de fin
Write-Host "`n=== Fin du script ===" -ForegroundColor Cyan



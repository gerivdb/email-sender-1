# ModÃ¨le de script PowerShell avec encodage UTF-8 avec BOM
# Ce modÃ¨le garantit que les caractÃ¨res franÃ§ais s'affichent correctement dans le terminal

<#
.SYNOPSIS
    Description courte du script.

.DESCRIPTION
    Description dÃ©taillÃ©e du script.

.PARAMETER Param1
    Description du paramÃ¨tre 1.

.PARAMETER Param2
    Description du paramÃ¨tre 2.

.EXAMPLE
    .\script-template.ps1 -Param1 "Valeur1" -Param2 "Valeur2"
    Explication de l'exemple.

.NOTES
    Nom du fichier    : script-template.ps1
    Auteur           : Votre nom
    Date de crÃ©ation : $(Get-Date -Format "dd/MM/yyyy")
    Version          : 1.0
#>

param (
    [Parameter(Mandatory=$false, HelpMessage="Description du paramÃ¨tre 1")]
    [string]$Param1 = "Valeur par dÃ©faut",

    [Parameter(Mandatory=$false, HelpMessage="Description du paramÃ¨tre 2")]
    [string]$Param2 = "Valeur par dÃ©faut"
)

# Afficher un en-tÃªte avec des caractÃ¨res franÃ§ais
Write-Host "=== Titre du script avec caractÃ¨res franÃ§ais : Ã© Ã¨ Ãª Ã« Ã  Ã§ Ã¹ ===" -ForegroundColor Cyan

# Fonction d'exemple avec des caractÃ¨res franÃ§ais
function Show-Example {
    param (
        [string]$Message = "Message par dÃ©faut avec caractÃ¨res franÃ§ais : Ã© Ã¨ Ãª Ã« Ã  Ã§ Ã¹"
    )
    
    Write-Host $Message -ForegroundColor Green
}

# Corps principal du script
Write-Host "ExÃ©cution du script avec les paramÃ¨tres :" -ForegroundColor Yellow
Write-Host "Param1 : $Param1" -ForegroundColor Yellow
Write-Host "Param2 : $Param2" -ForegroundColor Yellow

# Appel de la fonction d'exemple
Show-Example

# Afficher un message de fin
Write-Host "`n=== Fin du script ===" -ForegroundColor Cyan



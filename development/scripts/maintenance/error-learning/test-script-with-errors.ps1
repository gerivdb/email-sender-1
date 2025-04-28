<#
.SYNOPSIS
    Script de test avec des erreurs pour tester le systÃ¨me d'apprentissage des erreurs.
.DESCRIPTION
    Ce script contient intentionnellement des erreurs pour tester le systÃ¨me
    d'apprentissage des erreurs PowerShell.
#>

# Chemin codÃ© en dur
$logPath = "D:\Logs\app.log"

# Utilisation de sÃ©parateurs de chemin spÃ©cifiques Ã  Windows
$scriptPath = "scripts\\utils\\path-utils.ps1"

# Commande spÃ©cifique Ã  Windows
$result = cmd.exe /c "dir /b"

# Variable non dÃ©clarÃ©e
$undeclaredVar = "Test"

# Absence de gestion d'erreurs
$content = Get-Content -Path "C:\config.txt"

# Utilisation de Write-Host
Write-Host "Message de test"

# Utilisation de cmdlet obsolÃ¨te
$processes = Get-WmiObject -Class Win32_Process

# Fonction sans commentaires
function Test-Function {
    param (
        [string]$Param1,
        [int]$Param2
    )
    
    return $Param1 + $Param2
}

# Erreur de syntaxe (accolade manquante)
if ($true) {
    Write-Output "Test"
# }

# Appel de la fonction
$result = Test-Function -Param1 "Test" -Param2 123

# Afficher le rÃ©sultat
Write-Output $result

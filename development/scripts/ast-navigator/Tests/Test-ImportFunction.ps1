# Script pour tester l'importation de la fonction Get-AstFunctions

# Importer la fonction
Write-Host "Tentative d'importation de la fonction Get-AstFunctions..."
. "$PSScriptRoot\..\Public\Get-AstFunctions.ps1"

# VÃ©rifier si la fonction est disponible
if (Get-Command -Name Get-AstFunctions -ErrorAction SilentlyContinue) {
    Write-Host "La fonction Get-AstFunctions a Ã©tÃ© importÃ©e avec succÃ¨s!" -ForegroundColor Green
} else {
    Write-Host "Ã‰chec de l'importation de la fonction Get-AstFunctions." -ForegroundColor Red
}

# Afficher toutes les fonctions disponibles
Write-Host "`nFonctions disponibles dans la session :"
Get-Command -CommandType Function | Where-Object { $_.Name -like "*Ast*" } | Format-Table -Property Name, CommandType, Source

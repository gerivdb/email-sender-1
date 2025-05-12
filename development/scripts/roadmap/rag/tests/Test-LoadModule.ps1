# Test-LoadModule.ps1
# Script de test pour charger le module et afficher un message

# Définir le chemin du script à tester
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\metadata\Manage-TagFormats-Fixed.ps1"

# Vérifier que le fichier existe
if (Test-Path -Path $scriptPath) {
    Write-Host "Le fichier du module existe" -ForegroundColor Green
} else {
    Write-Host "Le fichier du module n'existe pas" -ForegroundColor Red
    exit 1
}

# Charger les fonctions du script
try {
    . $scriptPath
    Write-Host "Le module a été chargé avec succès" -ForegroundColor Green
} catch {
    Write-Host "Erreur lors du chargement du module: $_" -ForegroundColor Red
    exit 1
}

# Vérifier que les fonctions sont disponibles
$functions = @(
    "Get-TagFormatsConfig",
    "Save-TagFormatsConfig",
    "Get-TagFormat",
    "Add-TagFormat",
    "Update-TagFormat",
    "Remove-TagFormat",
    "Get-TagFormatsList",
    "Invoke-TagFormatsManager"
)

foreach ($function in $functions) {
    if (Get-Command -Name $function -ErrorAction SilentlyContinue) {
        Write-Host "La fonction '$function' est disponible" -ForegroundColor Green
    } else {
        Write-Host "La fonction '$function' n'est pas disponible" -ForegroundColor Red
    }
}

Write-Host "Test terminé" -ForegroundColor Cyan

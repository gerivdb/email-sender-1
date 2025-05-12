# Test-VerySimple.ps1
# Script de test très simple pour la création et la lecture d'un fichier JSON

# Définir le chemin du fichier de test
$testFilePath = Join-Path -Path $PSScriptRoot -ChildPath "TestVerySimple.json"

# Supprimer le fichier s'il existe déjà
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier existant supprimé" -ForegroundColor Yellow
}

# Créer un objet simple
$testObject = @{
    name = "Test Object"
    value = 123
    items = @(
        @{
            id = 1
            name = "Item 1"
        },
        @{
            id = 2
            name = "Item 2"
        }
    )
}

# Convertir en JSON et enregistrer
$testJson = ConvertTo-Json -InputObject $testObject -Depth 5
Set-Content -Path $testFilePath -Value $testJson -Encoding UTF8

# Vérifier que le fichier existe
if (Test-Path -Path $testFilePath) {
    Write-Host "Fichier créé avec succès" -ForegroundColor Green
} else {
    Write-Host "Échec de création du fichier" -ForegroundColor Red
    exit 1
}

# Lire le fichier
$loadedJson = Get-Content -Path $testFilePath -Raw
$loadedObject = ConvertFrom-Json -InputObject $loadedJson

# Vérifier la structure de l'objet chargé
Write-Host "Structure de l'objet chargé:" -ForegroundColor Cyan
$loadedObject | ConvertTo-Json | Write-Host

# Vérifier si la propriété items existe
if ($loadedObject.items) {
    Write-Host "La propriété items existe" -ForegroundColor Green
    Write-Host "Type de items: $($loadedObject.items.GetType().FullName)" -ForegroundColor Gray
    
    # Vérifier si items est un tableau
    if ($loadedObject.items -is [array]) {
        Write-Host "La propriété items est un tableau" -ForegroundColor Green
        Write-Host "Nombre d'items: $($loadedObject.items.Count)" -ForegroundColor Green
        
        # Afficher les items
        foreach ($item in $loadedObject.items) {
            Write-Host "Item: $($item.id) - $($item.name)" -ForegroundColor Gray
        }
    } else {
        Write-Host "La propriété items n'est pas un tableau" -ForegroundColor Red
        Write-Host "Valeur: $($loadedObject.items)" -ForegroundColor Gray
    }
} else {
    Write-Host "La propriété items n'existe pas" -ForegroundColor Red
}

# Nettoyer
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de test supprimé" -ForegroundColor Yellow
}

Write-Host "Test terminé" -ForegroundColor Cyan

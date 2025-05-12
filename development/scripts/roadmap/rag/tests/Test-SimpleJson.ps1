# Test-SimpleJson.ps1
# Script de test pour la création et la lecture d'un fichier JSON simple

# Définir le chemin du fichier de test
$testFilePath = Join-Path -Path $PSScriptRoot -ChildPath "TestSimpleJson.json"

# Supprimer le fichier s'il existe déjà
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier existant supprimé" -ForegroundColor Yellow
}

# Créer un contenu JSON simple
$testContent = @"
{
    "name": "Test Object",
    "value": 123,
    "items": [
        {
            "id": 1,
            "name": "Item 1"
        },
        {
            "id": 2,
            "name": "Item 2"
        }
    ]
}
"@

# Enregistrer le contenu
Set-Content -Path $testFilePath -Value $testContent -Encoding UTF8

# Vérifier que le fichier existe
if (Test-Path -Path $testFilePath) {
    Write-Host "Fichier créé avec succès" -ForegroundColor Green
} else {
    Write-Host "Échec de création du fichier" -ForegroundColor Red
    exit 1
}

# Lire le fichier
$loadedContent = Get-Content -Path $testFilePath -Raw

# Convertir le contenu en objet
try {
    $loadedObject = ConvertFrom-Json -InputObject $loadedContent
    Write-Host "Conversion JSON réussie" -ForegroundColor Green
    
    # Vérifier la structure de l'objet
    if ($loadedObject.name -eq "Test Object") {
        Write-Host "La propriété 'name' est correcte" -ForegroundColor Green
    } else {
        Write-Host "La propriété 'name' est incorrecte" -ForegroundColor Red
        Write-Host "Attendu: Test Object" -ForegroundColor Yellow
        Write-Host "Obtenu: $($loadedObject.name)" -ForegroundColor Yellow
    }
    
    if ($loadedObject.items -is [array]) {
        Write-Host "La propriété 'items' est un tableau" -ForegroundColor Green
        Write-Host "Nombre d'items: $($loadedObject.items.Count)" -ForegroundColor Green
        
        foreach ($item in $loadedObject.items) {
            Write-Host "Item: $($item.id) - $($item.name)" -ForegroundColor Gray
        }
    } else {
        Write-Host "La propriété 'items' n'est pas un tableau" -ForegroundColor Red
    }
} catch {
    Write-Host "Erreur lors de la conversion JSON: $_" -ForegroundColor Red
}

# Nettoyer
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de test supprimé" -ForegroundColor Yellow
}

Write-Host "Test terminé" -ForegroundColor Cyan

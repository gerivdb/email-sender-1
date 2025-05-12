# Test-Simple.ps1
# Script de test simple pour vérifier la création de fichiers

# Définir le chemin du fichier de test
$testFilePath = Join-Path -Path $PSScriptRoot -ChildPath "TestSimple.json"

# Supprimer le fichier s'il existe déjà
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier existant supprimé" -ForegroundColor Yellow
}

# Créer un objet de test
$testObject = @{
    name = "Test Simple"
    description = "Objet de test simple"
    created_at = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
}

# Convertir en JSON
$testJson = $testObject | ConvertTo-Json

# Écrire dans le fichier
try {
    Set-Content -Path $testFilePath -Value $testJson -Encoding UTF8 -Force
    Write-Host "Fichier créé avec succès" -ForegroundColor Green
    
    # Vérifier que le fichier existe
    if (Test-Path -Path $testFilePath) {
        Write-Host "Le fichier existe" -ForegroundColor Green
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $testFilePath -Raw
        Write-Host "Contenu du fichier:" -ForegroundColor Cyan
        Write-Host $content
    }
    else {
        Write-Host "Le fichier n'existe pas" -ForegroundColor Red
    }
}
catch {
    Write-Host "Erreur lors de la création du fichier: $_" -ForegroundColor Red
}

# Nettoyer
if (Test-Path -Path $testFilePath) {
    Remove-Item -Path $testFilePath -Force
    Write-Host "Fichier de test supprimé" -ForegroundColor Yellow
}

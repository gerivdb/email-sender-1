# Script pour mettre a jour les liens dans les fichiers de documentation

Write-Host "=== Mise a jour des liens dans les fichiers de documentation ===" -ForegroundColor Cyan

# Fonction pour mettre a jour les liens dans un fichier
function Update-Links {
    param (
        [string]$FilePath
    )
    
    if (Test-Path $FilePath) {
        $content = Get-Content -Path $FilePath -Raw
        
        # Remplacer les liens vers les fichiers de documentation
        $content = $content -replace '\[([^\]]+)\]\(GUIDE_([^\)]+)\)', '[${1}](../guides/GUIDE_${2})'
        $content = $content -replace '\[([^\]]+)\]\(CONFIGURATION_([^\)]+)\)', '[${1}](../guides/CONFIGURATION_${2})'
        
        # Enregistrer le fichier
        Set-Content -Path $FilePath -Value $content
        Write-Host "Liens mis a jour dans $FilePath" -ForegroundColor Green
    } else {
        Write-Host "Fichier $FilePath non trouve" -ForegroundColor Yellow
    }
}

# Mettre a jour les liens dans les fichiers de documentation
$docFiles = Get-ChildItem -Path ".\docs\guides" -Filter "*.md" -File

foreach ($file in $docFiles) {
    Update-Links -FilePath $file.FullName
}

Write-Host "`n=== Mise a jour des liens terminee ===" -ForegroundColor Cyan
